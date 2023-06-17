defmodule YoutubeRadio.Room do
  use GenServer, restart: :transient

  alias YoutubeRadio.YoutubeRooms
  alias Phoenix.PubSub

  def start_link([room_name] = params) do
    GenServer.start_link(__MODULE__, params,
      name: {:via, Registry, {YoutubeRadio.Room.Registry, room_name}}
    )
  end

  @impl true
  def init([room_name]) do
    room = YoutubeRooms.get_room_by_room_name(room_name)
    next_to_play_video = YoutubeRooms.get_next_to_play_video(room.id)

    PubSub.broadcast(YoutubeRadio.PubSub, room_name, %{
      event: "start_playing",
      payload: next_to_play_video
    })

    ref = schedule_work(next_to_play_video)

    {:ok,
     %{
       "users_count" => 1,
       "worker_ref" => ref,
       "current_video" => next_to_play_video,
       "room" => room,
       "start_time" => System.os_time(:second)
     }}
  end

  @impl true
  def handle_info({:play_new_video, current_video_id}, state) do
    if current_video_id != nil do
      YoutubeRooms.set_video_to_played(current_video_id)
    end

    next_to_play_video = YoutubeRooms.get_next_to_play_video(state.room.id)

    PubSub.broadcast(YoutubeRadio.PubSub, state["room"].name, %{
      event: "start_playing",
      payload: next_to_play_video
    })

    ref = schedule_work(next_to_play_video)

    {:noreply,
     %{
       "users_count" => state["users_count"],
       "worker_ref" => ref,
       "current_video" => next_to_play_video,
       "room" => state["room"],
       "start_time" => System.os_time(:second)
     }}
  end

  @impl true
  def handle_cast({:add_user, pubsub_node_name}, state) do
    PubSub.direct_broadcast(pubsub_node_name, YoutubeRadio.PubSub, state["room"].name, %{
      event: "start_playing_from_timestamp",
      payload: %{
        video: state["current_video"],
        current_timestamp: System.os_time(:second) - state["start_time"]
      }
    })

    {:noreply,
     %{
       "users_count" => state["users_count"] + 1,
       "worker_ref" => state["worker_ref"],
       "current_video" => state["current_video"],
       "room" => state["room"],
       "start_time" => state["start_time"]
     }}
  end

  @impl true
  def handle_cast({:remove_user}, state) do
    new_user_count = state["users_count"] - 1

    case new_user_count do
      0 ->
        Process.cancel_timer(state["worker_ref"])
        Kernel.exit(:shutdown)

      _ ->
        {:noreply,
         %{
           "users_count" => state["users_count"] + 1,
           "worker_ref" => state["worker_ref"],
           "current_video" => state["current_video"],
           "room" => state["room"],
           "start_time" => state["start_time"]
         }}
    end
  end

  @impl true
  def terminate(reason, state) do
    Registry.unregister(YoutubeRadio.Room.Registry, state["room"].name)
    IO.puts("Process terminated with #{reason}")
  end

  defp time_converter_to_miliseconds(duration) do
    time =
      String.split(duration, ["PT", "M", "S"], trim: true)
      |> Enum.map(fn num -> String.to_integer(num) end)

    case String.match?(duration, ~r/PT\d+M\d+S/) do
      true ->
        [minutes, seconds | []] = time
        :timer.minutes(minutes) + :timer.seconds(seconds)

      false ->
        [seconds | []] = time
        :timer.seconds(seconds)
    end
  end

  defp schedule_work(nil) do
    Process.send_after(
      self(),
      {:play_new_video, nil},
      :timer.seconds(5)
    )
  end

  defp schedule_work(current_video) do
    Process.send_after(
      self(),
      {:play_new_video, current_video.id},
      time_converter_to_miliseconds(current_video.duration)
    )
  end
end
