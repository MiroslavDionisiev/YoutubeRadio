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

  def join_room(room_name, pubsub_node_name) do
    child_spec = {YoutubeRadio.Room, [room_name]}
    DynamicSupervisor.start_child(__MODULE__, child_spec)

    case Registry.lookup(YoutubeRadio.Room.Registry, room_name) do
      [{pid, _}] ->
        GenServer.cast(pid, {:add_user, pubsub_node_name})

      [] ->
        child_spec = {YoutubeRadio.Room, [room_name]}
        DynamicSupervisor.start_child(__MODULE__, child_spec)
    end

    :ok
  end
end
