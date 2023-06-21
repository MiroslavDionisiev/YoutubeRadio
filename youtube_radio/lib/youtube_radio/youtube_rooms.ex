defmodule YoutubeRadio.YoutubeRooms do
  import Ecto.Query, warn: false
  alias YoutubeRadio.Repo

  alias YoutubeRadio.YoutubeRooms.{Room, Video}
  alias YoutubeRadio.Models.VideoData

  def get_room_by_id(room_id) when is_integer(room_id) do
    Repo.get_by(Room, id: room_id)
  end

  def get_room_by_room_name(room_name) when is_binary(room_name) do
    Repo.get_by(Room, name: room_name)
  end

  def get_all_rooms() do
    Repo.all(from(room in Room))
  end

  def create_room(room_name, user_id) do
    %Room{}
    |> Room.changeset(%{name: room_name, user_id: user_id})
    |> Repo.insert()
  end

  def change_room(%Room{} = room, attrs \\ %{}) do
    Room.changeset(room, attrs, validate_name: false)
  end

  def delete_room(room_id, user_id) when is_integer(room_id) and is_integer(user_id) do
    Repo.delete_all(from(room in Room, where: room.id == ^room_id and room.user_id == ^user_id))
  end

  def get_all_room_videos(room_id) when is_integer(room_id) do
    Repo.all(
      from(video in Video, where: video.room_id == ^room_id, order_by: [desc: video.inserted_at])
    )
    |> Repo.preload(:user)
  end

  def get_next_to_play_video(room_id) when is_integer(room_id) do
    query =
      from video in Video,
        where: video.room_id == ^room_id and video.played_status == false,
        order_by: [asc: video.inserted_at],
        limit: 1

    Repo.one(query)
  end

  def add_video_to_room(youtube_url, room_id, user_id) do
    api_response = get_video_data(youtube_url)

    case api_response do
      {:ok, %{title: title, video_id: video_id, duration_ms: duration} = _video_data} ->
        %Video{}
        |> Video.changeset(%{
          video_id: video_id,
          title: title,
          duration: duration,
          room_id: room_id,
          user_id: user_id
        })
        |> Repo.insert()
    end
  end

  def delete_video_from_room(room_id, video_id)
      when is_integer(room_id) and is_integer(video_id) do
    Repo.delete_all(
      from(video in Video, where: video.room_id == ^room_id and video.id == ^video_id)
    )
  end

  def set_video_to_played(video_id) when is_integer(video_id) do
    Repo.get_by(Video, id: video_id)
    |> Ecto.Changeset.change(played_status: true)
    |> Repo.update()
  end

  defp get_video_data(youtube_url) do
    case get_song_id(youtube_url) do
      {:ok, video_id} ->
        youtube_data = YoutubeRadio.Api.YoutubeApi.get_youtube_video_data(video_id)

        parse_api_response(youtube_data, video_id)
    end
  end

  defp parse_api_response({:ok, video_data}, video_id) do
    result = Jason.decode(video_data)

    case result do
      {:ok, video_data} -> handle_video_data(video_data, video_id)
      {:error, _} -> result
    end
  end

  defp parse_api_response({:error, _}, _video_id), do: nil

  defp handle_video_data(video_data, video_id) do
    if(video_data["items"]) do
      {:ok,
       %VideoData{
         title: List.first(video_data["items"])["snippet"]["title"],
         video_id: video_id,
         duration_ms: List.first(video_data["items"])["contentDetails"]["duration"]
       }}
    else
      {:error, video_data}
    end
  end

  defp get_song_id(youtube_url) do
    case String.match?(youtube_url, ~r/[?&]v=/) do
      false ->
        {:error, "Invalid url"}

      true ->
        {:ok, String.split(youtube_url, "v=") |> Enum.at(1) |> String.split("&") |> List.first()}
    end
  end
end
