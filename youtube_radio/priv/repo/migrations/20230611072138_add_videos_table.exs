defmodule YoutubeRadio.Repo.Migrations.AddVideosTable do
  use Ecto.Migration

  def change do
    create table("videos") do
      add :video_id, :string, null: false
      add :title, :string, null: false
      add :duration, :string, null: false
      add :played_status, :boolean, default: false, null: false
      add :room_id, references(:rooms, on_delete: :delete_all)

      timestamps()
    end
  end
end
