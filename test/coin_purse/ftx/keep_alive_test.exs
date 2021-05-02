defmodule CoinPurse.Ftx.KeepAliveTest do
  use ExUnit.Case

  require Logger

  import ExUnit.CaptureLog
  import Mox

  alias CoinPurse.Ftx.KeepAlive
  alias CoinPurse.MockWebSocket

  describe "start_link/1" do
    setup :set_mox_from_context
    setup :verify_on_exit!

    test "sends a ping and schedules the next ping" do
      expect(MockWebSocket, :send_frame, 3, fn _ws_client, ~s({"op": "ping"}) ->
        Logger.info("pong")
      end)

      assert capture_log(fn ->
               {:ok, pid} = KeepAlive.start_link(ws_client: MockWebSocket)
               :timer.sleep(25)
               GenServer.stop(pid)
             end) =~ "pong"
    end
  end
end
