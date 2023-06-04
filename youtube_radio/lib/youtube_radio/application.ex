defmodule YoutubeRadio.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      YoutubeRadioWeb.Telemetry,
      # Start the Ecto repository
      YoutubeRadio.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: YoutubeRadio.PubSub},
      # Start Finch
      {Finch, name: YoutubeRadio.Finch},
      # Start the Endpoint (http/https)
      YoutubeRadioWeb.Endpoint
      # Start a worker by calling: YoutubeRadio.Worker.start_link(arg)
      # {YoutubeRadio.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: YoutubeRadio.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    YoutubeRadioWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
