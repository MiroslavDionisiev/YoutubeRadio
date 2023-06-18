defmodule YoutubeRadioWeb.YoutubeRoom.YoutubeRoomLive do
  use YoutubeRadioWeb, :live_view
  alias YoutubeRadio.YoutubeRooms
  alias YoutubeRadio.YoutubeRadioRooms
  alias Phoenix.PubSub

  import YoutubeRadioWeb.CoreComponents


  @impl true
  def mount(%{"id" => room_id} = _params, _session, socket) do
    room = YoutubeRooms.get_room_by_id(String.to_integer(room_id))

    if connected?(socket) do
      current_user_id = Map.get(socket.assigns, :current_user).id
      PubSub.subscribe(YoutubeRadio.PubSub, "#{room.name}_#{current_user_id}")
      YoutubeRadioRooms.join_room(room.name, current_user_id)
      PubSub.subscribe(YoutubeRadio.PubSub, room.name)
    end

    {:ok,
     assign(socket,
       form: to_form(%{}),
       room: room,
       video: nil,
       current_timestamp: 0
     )}
  end

  @impl true
  def terminate(_reason, socket) do
    YoutubeRadioRooms.remove_user(socket.assigns.room.name)
  end

  @impl true
  def handle_event("save", %{"youtube_link" => youtube_link}, socket) do
    current_user_id = Map.get(socket.assigns, :current_user).id
    room_id = Map.get(socket.assigns, :room).id

    YoutubeRooms.add_video_to_room(youtube_link, room_id, current_user_id)

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "start_playing", payload: video}, socket) do
    {:noreply, assign(socket, video: video)}
  end

  @impl true
  def handle_info(%{event: "start_playing_from_timestamp", payload: %{video: video, current_timestamp: current_timestamp}}, socket) do
    {:noreply, assign(socket, video: video, current_timestamp: current_timestamp)}
  end
end
