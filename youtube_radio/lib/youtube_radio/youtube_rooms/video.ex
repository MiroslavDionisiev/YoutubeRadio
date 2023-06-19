defmodule YoutubeRadio.YoutubeRooms.Video do
  use Ecto.Schema
  import Ecto.Changeset

  schema "videos" do
    field :video_id, :string
    field :title, :string
    field :duration, :string
    field :played_status, :boolean
    belongs_to :room, YoutubeRadio.YoutubeRooms.Room, foreign_key: :room_id
    belongs_to :user, YoutubeRadio.Accounts.User, foreign_key: :user_id

    timestamps()
  end

  def changeset(video, params \\ %{}) do
    video
    |> cast(params, [:video_id, :title, :duration, :room_id, :user_id])
    |> validate_required([:video_id, :title, :duration])
    |> validate_format(:duration, ~r/^PT(\d+[MS])+$/, message: "Video is too long")
    |> foreign_key_constraint(:room_id)
    |> foreign_key_constraint(:user_id)
  end
end
