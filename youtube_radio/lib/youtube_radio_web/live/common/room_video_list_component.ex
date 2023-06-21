defmodule YoutubeRadioWeb.Common.RoomVideoListComponent do
  use YoutubeRadioWeb, :live_component
  alias YoutubeRadio.YoutubeRooms
  alias Phoenix.PubSub

  @impl true
  def render(assigns) do
    ~H"""
    <section class="room-video-list">
      <section class="video-list">
        <%= for video <- @videos do %>
          <%= if @current_video != nil && @current_video.id == video.id do %>
            <div class="current-video"><%= video.title %></div>
          <% else %>
            <div><%= video.title %></div>
          <% end %>
        <% end %>
      </section>

      <.form
        for={@form}
        phx-submit="save"
        phx-target={@myself}
        method="post"
      >
        <.input type="text" field={@form[:youtube_link]} />

        <%= for key <- Keyword.keys(@form.errors) do %>
          <.error> <%= @form.errors[key] |> elem(0) %> </.error>
        <% end %>

        <button class="custom_button secondary">Save</button>
      </.form>
    </section>
    """
  end

  @impl true
  def handle_event("save", video, socket) do
    current_user_id = socket.assigns.current_user.id
    room_id = socket.assigns.room.id

    case YoutubeRooms.add_video_to_room(video["youtube_link"], room_id, current_user_id) do
      {:ok, video} ->
        socket = assign(socket, form: to_form(%{}))
        PubSub.broadcast(YoutubeRadio.PubSub, socket.assigns.room.name, %{event: "update", payload: video})
        {:noreply,  socket}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
