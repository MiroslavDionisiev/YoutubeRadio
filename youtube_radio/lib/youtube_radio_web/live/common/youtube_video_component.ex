defmodule YoutubeRadioWeb.Common.YoutubeVideoComponent do
  use YoutubeRadioWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <%= if @video != nil do %>
        <iframe
          id="ytplayer"
          type="text/html"
          width="640"
          height="360"
          src={"https://www.youtube.com/embed/#{@video.video_id}?controls=0&showinfo=0&rel=0&autoplay=1&start=#{@current_timestamp}&loop=1&playlist=#{@video.video_id}"}
          allow="autoplay"
          frameborder="0"
        >
        </iframe>
        <p><%= @video.title %></p>
      <% end %>
    </div>
    """
  end
end
