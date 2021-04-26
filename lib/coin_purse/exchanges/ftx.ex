defmodule CoinPurse.Exchanges.Ftx do
  @moduledoc """
  Leverage the ftx.us websocket connection for real-time market data
  """
  use WebSockex

  require Logger

  @endpoint "wss://ftx.us/ws"

  def start_link(market) do
    {:ok, pid} = WebSockex.start_link(@endpoint, __MODULE__, :ignored)
    GenServer.start_link(__MODULE__, client: pid, market: market)
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
    market = Keyword.get(state, :market)

    ping(client)

    WebSockex.send_frame(
      client,
      {:text, Jason.encode!(%{op: "subscribe", channel: "ticker", market: market})}
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
    amount = get_in(message, ["data", "last"])
    market = Map.get(message, "market")
    Logger.info("#{market} #{amount}")
    # emit market update

    :ok
  end

  defp handle_message(_) do
    :ignored
  end

  defp ping(client) do
    WebSockex.send_frame(client, {:text, Jason.encode!(%{op: "ping"})})
    Process.send_after(self(), :ping, 15_000)
  end
end
