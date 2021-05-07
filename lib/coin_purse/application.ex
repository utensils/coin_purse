defmodule CoinPurse.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      CoinPurseWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: CoinPurse.PubSub},
      # Start the Endpoint (http/https)
      CoinPurseWeb.Endpoint,
      # Start a worker by calling: CoinPurse.Worker.start_link(arg)
      {CoinPurse.Ftx.Supervisor, markets()}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CoinPurse.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CoinPurseWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp markets do
    :coin_purse
    |> Application.get_env(:exchanges)
    |> Keyword.get(:ftx)
    |> Keyword.fetch!(:markets)
  end
end
