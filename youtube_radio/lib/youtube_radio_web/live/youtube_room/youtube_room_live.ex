defmodule YoutubeRadioWeb.YoutubeRoom.YoutubeRoomLive do
  use YoutubeRadioWeb, :live_view
  alias YoutubeRadio.YoutubeRooms
  alias YoutubeRadio.YoutubeRadioRooms
  alias Phoenix.PubSub

  @impl true
  def mount(%{"id" => room_id} = _params, _session, socket) do
    room = YoutubeRooms.get_room_by_id(String.to_integer(room_id))

    if room == nil do
      raise YoutubeRadioWeb.YoutubeRoomLive.InvalidRoomIdError
    end

    if connected?(socket) do
      current_user_id = socket.assigns.current_user.id
      PubSub.subscribe(YoutubeRadio.PubSub, "#{room.name}_#{current_user_id}")
      PubSub.subscribe(YoutubeRadio.PubSub, room.name)
      YoutubeRadioRooms.join_room(room.name, current_user_id)
    end

    {:ok,
     assign(socket,
       form: to_form(%{}),
       room: room,
       video: nil,
       videos: YoutubeRooms.get_all_room_videos(room.id),
       current_timestamp: 0
     ), temporary_assigns: [form: nil]}
  end

  @impl true
  def terminate(_reason, socket) do
    YoutubeRadioRooms.remove_user(socket.assigns.room.name)
  end

  @impl true
  def handle_info(%{event: "update", payload: new_video}, socket) do
    {:noreply, assign(socket, videos: [new_video | socket.assigns.videos])}
  end

  @impl true
  def handle_info(%{event: "start_playing", payload: video}, socket) do
    {:noreply, assign(socket, video: video)}
  end

  @impl true
  def handle_info(
        %{
          event: "start_playing_from_timestamp",
          payload: %{video: video, current_timestamp: current_timestamp}
        },
        socket
      ) do
    {:noreply, assign(socket, video: video, current_timestamp: current_timestamp)}
  end
end

defmodule YoutubeRadioWeb.YoutubeRoomLive.InvalidRoomIdError do
  defexception message: "Invalid room id", plug_status: 404
end
