# defmodule CoinPurse.Ftx.Buffer do
#  @moduledoc """
#  Borrowed from Plausible
#
#  See: https://github.com/plausible/analytics/blob/b724def948d51a0f07a46f5bd2568e84f708d5a2/lib/plausible/event/write_buffer.ex
#  """
#  use GenServer
#
#  require Logger
#
#  @flush_interval_ms 5_000
#  @max_buffer_size 10_000
#
#  def start_link(opts) do
#    name = Keyword.fetch!(opts, :name)
#    GenServer.start_link(__MODULE__, opts, name: name)
#  end
#
#  def init(_opts) do
#    Process.flag(:trap_exit, true)
#    timer = Process.send_after(self(), :tick, @flush_interval_ms)
#    {:ok, %{buffer: [], timer: timer}}
#  end
#
#  def insert(event) do
#    GenServer.cast(__MODULE__, {:insert, event})
#    {:ok, event}
#  end
#
#  def flush() do
#    GenServer.call(__MODULE__, :flush, :infinity)
#    :ok
#  end
#
#  def handle_cast({:insert, event}, %{buffer: buffer} = state) do
#    new_buffer = [event | buffer]
#
#    if length(new_buffer) >= @max_buffer_size do
#      Logger.info("Buffer full, flushing to disk")
#      Process.cancel_timer(state[:timer])
#      do_flush(new_buffer)
#      new_timer = Process.send_after(self(), :tick, @flush_interval_ms)
#      {:noreply, %{state | buffer: [], timer: new_timer}}
#    else
#      {:noreply, %{state | buffer: new_buffer}}
#    end
#  end
#
#  def handle_info(:tick, %{buffer: buffer}) do
#    do_flush(buffer)
#    timer = Process.send_after(self(), :tick, @flush_interval_ms)
#    {:noreply, %{buffer: [], timer: timer}}
#  end
#
#  def handle_call(:flush, _from, %{buffer: buffer} = state) do
#    Process.cancel_timer(state[:timer])
#    do_flush(buffer)
#    new_timer = Process.send_after(self(), :tick, @flush_interval_ms)
#    {:reply, nil, %{state | buffer: [], timer: new_timer}}
#  end
#
#  def terminate(_reason, state) do
#    Logger.info("Flushing event buffer before shutdown...")
#    do_flush(state)
#  end
#
#  defp do_flush(%{buffer: buffer, flush: flush}) do
#    case buffer do
#      [] ->
#        nil
#
#      events ->
#        Logger.info("Flushing #{length(events)} events")
#        apply(flush, [events])
#    end
#  end
# end
