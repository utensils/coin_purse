defmodule CoinPurse.WebSocket do
  @moduledoc """
  Encapsulate Gun so we can cleanly test our exchanges that interact with it.
  """
  use GenServer

  require Logger

  @callback send_frame(struct(), String.t()) :: :ok | {:error, String.t()}

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(initial_state) do
    {:ok, initial_state, {:continue, :establish_connection}}
  end

  def handle_info({:gun_upgrade, _conn_pid, _stream_ref, ["websocket"], _headers}, state) do
    Logger.debug("HTTP connection upgraded")

    state
    |> Keyword.get(:on_connection)
    |> apply([])

    {:noreply, state}
  end

  def handle_info({:gun_ws, _conn_pid, _stream_ref, {:text, frame}}, state) do
    Logger.debug("Received #{frame}")

    state
    |> Keyword.get(:on_frame)
    |> apply([frame])

    {:noreply, state}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  def handle_continue(:establish_connection, state) do
    {host, port, path} =
      state
      |> Keyword.get(:endpoint)
      |> parse_connection_url()

    Logger.info("Opening connection #{host}:#{port}#{path}")

    {:ok, conn_pid} =
      host
      |> String.to_charlist()
      |> :gun.open(port, %{protocols: [:http]})

    stream_ref = :gun.ws_upgrade(conn_pid, path)

    {:noreply, Keyword.merge(state, conn_pid: conn_pid, stream_ref: stream_ref)}
  end

  defp parse_connection_url(conn_url) do
    %{host: host, path: path, scheme: scheme} = URI.parse(conn_url)
    port = ws_scheme_port(scheme)

    {host, port, path}
  end

  defp ws_scheme_port("wss"), do: 443
  defp ws_scheme_port(_), do: 80

  @impl true
  def handle_cast({:send_frame, frame}, state) do
    Logger.debug("Sending frame #{frame}")

    conn_pid = Keyword.get(state, :conn_pid)
    stream_ref = Keyword.get(state, :stream_ref)

    :gun.ws_send(conn_pid, stream_ref, {:text, String.to_charlist(frame)})

    {:noreply, state}
  end

  def send_frame(ws_client, frame) do
    GenServer.cast(ws_client, {:send_frame, frame})
  end

  def send_json(ws_client, frame) do
    send_frame(ws_client, Jason.encode!(frame))
  end
end
