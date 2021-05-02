defmodule CoinPurse.Ftx.Supervisor do
  @moduledoc """
  Leverage the FTX.us websocket connection for real-time market data
  """
  use Supervisor

  require Logger

  alias CoinPurse.WebSocket
  alias CoinPurse.Ftx.{Buffer, KeepAlive, Worker}

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {endpoint, markets} = ftx_config()

    children = [
      {KeepAlive, [ws_client: FtxConn]},
      {Worker, [markets: markets, ws_client: FtxConn]},
      #      {Buffer, [name: FtxBuffer, flush: &do_flush/1]},
      {WebSocket,
       [
         endpoint: endpoint,
         on_connection: &on_connection/0,
         on_frame: &on_frame/1,
         name: FtxConn
       ]}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  defp do_flush(entries) do
  end

  def on_connection do
    GenServer.cast(KeepAlive, :handle_connection)
    GenServer.cast(Worker, :handle_connection)
  end

  def on_frame(frame) do
    GenServer.cast(Worker, {:handle_frame, frame})
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
