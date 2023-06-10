defmodule YoutubeRadio.Api.YoutubeApi do
  @type video_id :: String.t()
  @type json_response :: String.t()

  @callback get_youtube_video_data(video_id) :: {:ok, json_response} | {:error, any()}

  def get_youtube_video_data(video_id) do
    requesr_body =
      Req.get!(
        "https://youtube.googleapis.com/youtube/v3/videos",
        params: [
          part: "snippet,player,contentDetails",
          id: video_id,
          key: "AIzaSyAnYIizCccXsSagg2xSn7w85OMH1_SrP3Q"
        ]
      ).body

    Jason.encode(requesr_body)
  end
end
