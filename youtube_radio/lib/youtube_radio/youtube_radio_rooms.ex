defmodule YoutubeRadio.YoutubeRadioRooms do
  use DynamicSupervisor

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :id, __MODULE__),
      start: {__MODULE__, :start_link, opts}
    }
  end

  def init(opts) do
    DynamicSupervisor.init(opts)
  end

  def add_song(room_name, youtube_url) do
    case Registry.lookup(YoutubeRadio.Room.Registry, room_name) do
      [{pid, _}] -> GenServer.call(pid, {:submit_song, youtube_url})
      [] -> {:error, "No such room"}
    end
  end

  def get_songs(room_name) do
    case Registry.lookup(YoutubeRadio.Room.Registry, room_name) do
      [{pid, _}] -> GenServer.call(pid, {:get_songs})
      [] -> {:error, "No such room"}
    end
  end

  def create_room(room_name) do
    child_spec = {YoutubeRadio.Room, [room_name]}
    DynamicSupervisor.start_child(__MODULE__, child_spec)

    :ok

    case Registry.lookup(YoutubeRadio.Room.Registry, room_name) do
      [{_pid, _}] ->
        {:error, "Room with this name already exists"}

      [] ->
        child_spec = {YoutubeRadio.Room, [room_name]}
        DynamicSupervisor.start_child(__MODULE__, child_spec)

        {:ok, "Room successfully created"}
    end
  end
end
