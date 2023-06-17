defmodule YoutubeRadio.YoutubeRooms.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :name, :string
    has_many :videos, YoutubeRadio.YoutubeRooms.Video
    belongs_to :user, YoutubeRadio.Accounts.User, foreign_key: :user_id

    timestamps()
  end

  def changeset(room, params \\ %{}) do
    room
    |> cast(params, [:name, :user_id])
    |> foreign_key_constraint(:user_id)
    |> validate_required([:name])
    |> validate_length(:name, min: 4, max: 160)
    |> unsafe_validate_unique(:name, YoutubeRadio.Repo)
    |> unique_constraint(:name)
  end
end
