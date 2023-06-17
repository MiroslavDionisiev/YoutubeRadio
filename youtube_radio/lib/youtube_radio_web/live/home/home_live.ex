defmodule YoutubeRadioWeb.Home.HomeLive do
  use YoutubeRadioWeb, :live_view
  alias YoutubeRadio.YoutubeRooms
  alias YoutubeRadio.YoutubeRooms.Room
  alias Phoenix.PubSub

  @topic "live"

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: PubSub.subscribe(YoutubeRadio.PubSub, @topic)
    {:ok, assign(socket, rooms: YoutubeRooms.get_all_rooms(), form: to_form(%{}))}
  end

  @impl true
  def handle_event("create", %{"name" => name}, socket) do
    current_user_id = Map.get(socket.assigns, :current_user).id
    YoutubeRooms.create_room(name, current_user_id)
    socket = assign(socket, rooms: YoutubeRooms.get_all_rooms(), active: %Room{})
    PubSub.broadcast(YoutubeRadio.PubSub, @topic, %{event: "update", payload: socket.assigns})
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "update", payload: %{rooms: rooms}}, socket) do
    {:noreply, assign(socket, rooms: rooms)}
  end
end
