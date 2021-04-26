defmodule CoinPurse.Ftx.Worker do
  @moduledoc """
  Our worker module does the heavy lifting subscribing to FTX.us markets and
  process their incoming messages.
  """
  use GenServer

  require Logger

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    markets = Keyword.fetch!(opts, :markets)
    ws_client = Keyword.fetch!(opts, :ws_client)

    Enum.each(markets, &subscribe(ws_client, &1))

    {:ok, {ws_client, markets}}
  end

  @impl true
  def handle_cast({:handle_message, message}, state) do
    handle_message(message)
    {:noreply, state}
  end

  defp handle_message(%{"channel" => "ticker", "type" => "update"} = message) do
    amount = get_in(message, ["data", "last"])
    market = Map.get(message, "market")
    Logger.info("#{market} #{amount}")
    # emit market update

    :ok
  end

  defp handle_message(_) do
    :ignored
  end

  defp subscribe(ws_client, market) do
    Logger.info("Subscribed to #{market}")
    websocket().send_json(ws_client, %{op: "subscribe", channel: "ticker", market: market})
  end

  defp websocket do
    Application.get_env(:coin_purse, :ws_module)
  end
end
