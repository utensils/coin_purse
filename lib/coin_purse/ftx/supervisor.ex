defmodule CoinPurse.Ftx.Supervisor do
  @moduledoc """
  Leverage the FTX.us websocket connection for real-time market data
  """
  use Supervisor

  require Logger

  alias CoinPurse.WebSocket
  alias CoinPurse.Ftx.{KeepAlive, Worker}

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {endpoint, markets} = ftx_config()

    children = [
      {WebSocket, [endpoint: endpoint, worker: FtxWorker, name: FtxConn]},
      {KeepAlive, [ws_client: FtxConn]},
      {Worker, [markets: markets, ws_client: FtxConn, name: FtxWorker]}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  defp ftx_config do
    config =
      :coin_purse
      |> Application.get_env(:exchanges)
      |> Keyword.get(:ftx)

    endpoint = Keyword.fetch!(config, :endpoint)
    markets = Keyword.fetch!(config, :markets)

    {endpoint, markets}
  end
end
