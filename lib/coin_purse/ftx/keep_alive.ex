defmodule CoinPurse.Ftx.KeepAlive do
  @moduledoc """
  A separate process to handle the keep alive pings
  """
  use GenServer

  require Logger

  def start_link(opts) do
    ws_client = Keyword.fetch!(opts, :ws_client)
    GenServer.start_link(__MODULE__, ws_client, name: __MODULE__)
  end

  @impl true
  def init(ws_client) do
    {:ok, ws_client}
  end

  @impl true
  def handle_cast(:handle_connection, ws_client) do
    ping(ws_client)
    {:noreply, ws_client}
  end

  @impl true
  def handle_info(:perform_ping, ws_client) do
    ping(ws_client)
    {:noreply, ws_client}
  end

  defp keep_alive do
    :coin_purse
    |> Application.get_env(:exchanges)
    |> get_in([:ftx, :keep_alive])
  end

  defp ping(ws_client) do
    websocket().send_json(ws_client, %{op: "ping"})
    Process.send_after(self(), :perform_ping, keep_alive())
  end

  defp websocket do
    Application.get_env(:coin_purse, :ws_module)
  end
end
