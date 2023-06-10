defmodule YoutubeRadioWeb.PageController do
  use YoutubeRadioWeb, :controller

  def home(conn, _params) do
    render(conn, :room, layout: false)
  end
end
