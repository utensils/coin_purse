defmodule CoinPurse.Ftx.Worker do
  @moduledoc """
  Our worker module does the heavy lifting subscribing to FTX.us markets and
  process their incoming messages.
  """
  use GenServer

  require Logger

  alias CoinPurse.Ftx.Ticker

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    markets = Keyword.fetch!(opts, :markets)
    ws_client = Keyword.fetch!(opts, :ws_client)

    {:ok, {ws_client, markets}}
  end

  @impl true
  def handle_cast(:handle_connection, {ws_client, markets}) do
    Enum.each(markets, &subscribe(ws_client, &1))
    {:noreply, {ws_client, markets}}
  end

  @impl true
  def handle_cast({:handle_frame, frame}, state) do
    frame
    |> Jason.decode!()
    |> handle_message()

    {:noreply, state}
  end

  defp handle_message(%{"channel" => "ticker", "type" => "update"} = message) do
    %{"data" => %{"ask" => ask, "bid" => bid, "last" => last, "time" => time}, "market" => market} =
      message

    [market, _currency] =
      message
      |> Map.get("market")
      |> String.split("/")

    Logger.info("FTX.us #{market} #{last} @ #{time}")

    ticker = struct(Ticker, market: market, ask: ask, bid: bid, last: last, timestamp: time)

    CoinPurseWeb.Endpoint.broadcast!("markets:#{market}", "ticker_update", ticker)
    # |> FtxBuffer.insert()

    :ok
  end

  defp handle_message(_) do
    :ignored
  end

  defp subscribe(ws_client, market) do
    Logger.info("Subscribed to #{market}")

    websocket().send_json(ws_client, %{
      op: "subscribe",
      channel: "ticker",
      market: "#{market}/USD"
    })
  end

  defp websocket do
    Application.get_env(:coin_purse, :ws_module)
  end
end
