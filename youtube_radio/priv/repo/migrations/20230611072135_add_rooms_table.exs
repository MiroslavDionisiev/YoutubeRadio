defmodule YoutubeRadio.Repo.Migrations.AddRoomsTable do
  use Ecto.Migration

  def change do
    create table("rooms") do
      add :name, :string, null: false

      timestamps()
    end

    create index("rooms", [:name], unique: true)
  end
end
