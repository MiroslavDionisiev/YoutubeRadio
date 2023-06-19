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

  def join_room(room_name, current_user_id) do
    case Registry.lookup(YoutubeRadio.Room.Registry, room_name) do
      [{pid, _}] ->
        GenServer.cast(pid, {:add_user, current_user_id})

      [] ->
        child_spec = {YoutubeRadio.Room, [room_name]}
        DynamicSupervisor.start_child(__MODULE__, child_spec)
    end

    :ok
  end

  def remove_user(room_name) do
    case Registry.lookup(YoutubeRadio.Room.Registry, room_name) do
      [{pid, _}] ->
        GenServer.cast(pid, {:remove_user})
    end

    :ok
  end
end
