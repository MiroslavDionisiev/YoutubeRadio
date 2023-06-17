defmodule YoutubeRadioWeb.Common.RoomTileComponent do
  use YoutubeRadioWeb, :live_component
  alias YoutubeRadio.YoutubeRooms
  alias YoutubeRadio.YoutubeRooms.Room
  alias Phoenix.PubSub

  @topic "live"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="view">
      <h1><%= @room.name %></h1>

      <.link href={~p"/rooms/#{@room.id}"}>
        Enter
      </.link>

      <%= if @current_user.id == @room.user_id do %>
        <button class="destroy" phx-click="delete" phx-value-id={@room.id} phx-target={@myself}>
          Delete
        </button>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("delete", data, socket) do
    current_user_id = Map.get(socket.assigns, :current_user).id
    YoutubeRooms.delete_room(Map.get(data, "id") |> String.to_integer(), current_user_id)
    socket = assign(socket, rooms: YoutubeRooms.get_all_rooms(), active: %Room{})
    PubSub.broadcast(YoutubeRadio.PubSub, @topic, %{event: "update", payload: socket.assigns})
    {:noreply, socket}
  end
end
