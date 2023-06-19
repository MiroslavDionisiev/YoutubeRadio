defmodule YoutubeRadioWeb.Home.HomeLive do
  use YoutubeRadioWeb, :live_view
  alias YoutubeRadio.YoutubeRooms
  alias YoutubeRadio.YoutubeRooms.Room
  alias Phoenix.PubSub

  @topic "live"

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: PubSub.subscribe(YoutubeRadio.PubSub, @topic)

    changeset = YoutubeRooms.change_room(%Room{})

    socket =
      socket
      |> assign(rooms: YoutubeRooms.get_all_rooms(), form: to_form(changeset, as: "room"))

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("create", %{"room" => room}, socket) do
    current_user_id = socket.assigns.current_user.id

    case YoutubeRooms.create_room(room["name"], current_user_id) do
      {:ok, room} ->
        socket =
          assign(socket,
            rooms: [room | socket.assigns.rooms],
            active: %Room{}
          )

        PubSub.broadcast(YoutubeRadio.PubSub, @topic, %{event: "update", payload: socket.assigns})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "room"))}
    end
  end

  @impl true
  def handle_event("validate", %{"room" => room_params}, socket) do
    changeset =
      YoutubeRooms.change_room(%Room{}, room_params)

    if room_params["name"] != "" do
      changeset = Map.put(changeset, :action, :validate)
      {:noreply, assign(socket, form: to_form(changeset, as: "room"))}
    else
      {:noreply, assign(socket, form: to_form(changeset, as: "room"))}
    end
  end

  @impl true
  def handle_info(%{event: "update", payload: %{rooms: rooms}}, socket) do
    {:noreply, assign(socket, rooms: rooms)}
  end
end
