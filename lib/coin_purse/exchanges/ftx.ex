defmodule CoinPurse.Exchanges.Ftx do
  @moduledoc """
  Leverage the ftx.us websocket connection for real-time market data
  """
  use GenServer

  require Logger

  alias CoinPurseWeb.Endpoint

  def start_link(markets) do
    GenServer.start_link(__MODULE__, %{markets: markets})
  end

  def init(initial_state) do
    {:ok, initial_state, {:continue, :establish_connection}}
  end

  def handle_info({:gun_upgrade, _conn_pid, _stream_ref, ["websocket"], _headers}, state) do
    ping(state)
    ticker_subscriptions(state)
    {:noreply, state}
  end

  def handle_info(:ping, state) do
    ping(state)
    {:noreply, state}
  end

  def handle_info({:gun_ws, _conn_pid, _stream_ref, {:text, frame}}, state) do
    frame
    |> Jason.decode!()
    |> handle_message()

    {:noreply, state}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  def handle_continue(:establish_connection, state) do
    {:ok, conn_pid} = :gun.open('ftx.us', 443, %{protocols: [:http]})
    stream_ref = :gun.ws_upgrade(conn_pid, '/ws')

    {:noreply, Map.merge(state, %{conn_pid: conn_pid, stream_ref: stream_ref})}
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

  defp ping(%{conn_pid: conn_pid, stream_ref: stream_ref}) do
    :gun.ws_send(conn_pid, stream_ref, {:text, '{"op": "ping"}'})
    Process.send_after(self(), :ping, 15_000)
  end

  defp ticker_subscriptions(%{conn_pid: conn_pid, markets: markets, stream_ref: stream_ref}) do
    frames =
      Enum.map(markets, fn market ->
        json = Jason.encode!(%{op: "subscribe", channel: "ticker", market: "#{market}/USD"})
        {:text, String.to_charlist(json)}
      end)

    :gun.ws_send(conn_pid, stream_ref, frames)
  end
end
