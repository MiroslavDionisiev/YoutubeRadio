defmodule YoutubeRadio.YoutubeRooms.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :name, :string
    has_many :videos, YoutubeRadio.YoutubeRooms.Video
    belongs_to :user, YoutubeRadio.Accounts.User, foreign_key: :user_id

    timestamps()
  end

  def changeset(room, params \\ %{}, opts \\ []) do
    room
    |> cast(params, [:name, :user_id])
    |> foreign_key_constraint(:user_id)
    |> validate_required([:name])
    |> validate_length(:name, min: 4, max: 160)
    |> maybe_validate_unique_name(opts)
  end

  defp maybe_validate_unique_name(changeset, opts) do
    if Keyword.get(opts, :validate_name, true) do
      changeset
      |> unsafe_validate_unique(:name, YoutubeRadio.Repo)
      |> unique_constraint(:name)
    else
      changeset
    end
  end
end
