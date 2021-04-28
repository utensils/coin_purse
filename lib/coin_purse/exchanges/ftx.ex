defmodule CoinPurse.Exchanges.Ftx do
  @moduledoc """
  Leverage the ftx.us websocket connection for real-time market data
  """
  use WebSockex

  require Logger

  alias CoinPurseWeb.Endpoint

  @endpoint "wss://ftx.us/ws"

  def start_link(markets) do
    {:ok, pid} = WebSockex.start_link(@endpoint, __MODULE__, :ignored)
    GenServer.start_link(__MODULE__, client: pid, markets: markets)
  end

  def init(state) do
    {:ok, state, {:continue, :subscribe}}
  end

  @impl true
  def handle_info(:ping, state) do
    state
    |> Keyword.get(:client)
    |> ping()

    {:noreply, state}
  end

  def handle_continue(:subscribe, state) do
    client = Keyword.get(state, :client)
    markets = Keyword.get(state, :markets)

    ping(client)

    Enum.each(
      markets,
      &WebSockex.send_frame(
        client,
        {:text, Jason.encode!(%{op: "subscribe", channel: "ticker", market: "#{&1}/USD"})}
      )
    )

    {:noreply, state}
  end

  @impl true
  def handle_frame({_type, msg}, state) do
    msg
    |> Jason.decode!()
    |> handle_message()

    {:ok, state}
  end

  defp handle_message(%{"channel" => "ticker", "type" => "update"} = message) do
    bid = get_in(message, ["data", "bid"])
    last = get_in(message, ["data", "last"])

    [market, _currency] =
      message
      |> Map.get("market")
      |> String.split("/")

    Endpoint.broadcast!("markets:#{market}", "ticker_update", {market, last, bid})

    :ok
  end

  defp handle_message(_msg) do
    :ignored
  end

  defp ping(client) do
    WebSockex.send_frame(client, {:text, Jason.encode!(%{op: "ping"})})
    Process.send_after(self(), :ping, 15_000)
  end
end
