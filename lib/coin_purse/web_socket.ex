defmodule CoinPurse.WebSocket do
  @moduledoc """
  Encapsulate WebSockex so we can cleanly test our exchanges that interact with it.
  """
  use WebSockex

  require Logger

  @callback send_json(struct(), String.t()) :: :ok | {:error, String.t()}

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    endpoint = Keyword.fetch!(opts, :endpoint)
    worker = Keyword.fetch!(opts, :worker)

    with {:ok, ws_client} <- WebSockex.start_link(endpoint, __MODULE__, self()) do
      Logger.info("Starting WebSocket connection: #{endpoint}")
      {:ok, {ws_client, worker}}
    end
  end

  @impl true
  def handle_cast({:send_json, message}, {ws_client, worker}) do
    json = Jason.encode!(message)
    Logger.info("Sending JSON #{json}")
    WebSockex.send_frame(ws_client, {:text, json})

    {:noreply, {ws_client, worker}}
  end

  def handle_cast({:handle_frame, frame}, {ws_client, worker}) do
    decoded = Jason.decode!(frame)
    GenServer.cast(worker, {:handle_message, decoded})
    {:noreply, {ws_client, worker}}
  end

  @impl true
  def handle_frame({_type, frame}, pid) do
    GenServer.cast(pid, {:handle_frame, frame})

    {:ok, pid}
  end

  def send_json(ws_client, message) do
    GenServer.cast(ws_client, {:send_json, message})
  end
end
