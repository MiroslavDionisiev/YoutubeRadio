defmodule YoutubeRadio.Repo do
  use Ecto.Repo,
    otp_app: :youtube_radio,
    adapter: Ecto.Adapters.Postgres
end
