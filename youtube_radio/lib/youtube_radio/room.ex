defmodule YoutubeRadio.Room do
  use GenServer, restart: :transient

  alias YoutubeRadio.Models.VideoData, as: VideoData

  def start_link([room_name | _rest] = params) do
    GenServer.start_link(__MODULE__, params,
      name: {:via, Registry, {YoutubeRadio.Room.Registry, room_name}}
    )
  end

  @impl true
  def init(_params) do
    {:ok, %{"songs_to_play" => :queue.new()}}
  end

  @impl true
  def handle_call({:submit_song, youtube_url}, _from, state) do
    song_id = get_song_id(youtube_url)

    case song_id do
      {:error, _} -> {:reply, song_id, state}
      {:ok, song_id} -> add_song(state, song_id)
    end
  end

  @impl true
  def handle_call({:get_songs}, _from, state) do
    {:reply, :queue.to_list(state["songs_to_play"]), state}
  end

  defp get_song_id(youtube_url) do
    case String.match?(youtube_url, ~r/[?&]v=/) do
      false ->
        {:error, "Invalid url"}

      true ->
        {:ok, String.split(youtube_url, "v=") |> Enum.at(1) |> String.split("&") |> List.first()}
    end
  end

  defp add_song(state, song_id) do
    youtube_data = YoutubeRadio.Api.YoutubeApi.get_youtube_video_data(song_id)

    parsed_video_data = parse_api_response(youtube_data)

    case parsed_video_data do
      {:ok, video_data} ->
        new_state = Map.put(state, "songs_to_play", :queue.in(video_data, state["songs_to_play"]))
        {:reply, {:ok, "Successful update"}, new_state}

      {:error, _} ->
        {:reply, parsed_video_data, state}
    end
  end

  defp parse_api_response({:ok, video_data}) do
    result = Jason.decode(video_data)

    case result do
      {:ok, video_data} -> handle_video_data(video_data)
      {:error, _} -> result
    end
  end

  defp parse_api_response({:error, _}), do: nil

  defp handle_video_data(video_data) do
    if(video_data["items"]) do
      {:ok,
       %VideoData{
         title: List.first(video_data["items"])["snippet"]["title"],
         embed_html: List.first(video_data["items"])["player"]["embedHtml"],
         duration_ms: List.first(video_data["items"])["contentDetails"]["duration"]
       }}
    else
      {:error, video_data}
    end
  end
end
