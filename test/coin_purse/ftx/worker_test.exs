defmodule CoinPurse.Ftx.WorkerTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  import Mox

  alias CoinPurse.Ftx.Worker
  alias CoinPurse.MockWebSocket

  describe "init/1" do
    setup :set_mox_from_context
    setup :verify_on_exit!

    test "subscribes to all configured markets" do
      expect(MockWebSocket, :send_json, fn _ws_client, frame ->
        assert "subscribe" == Map.get(frame, :op)
        assert "ticker" == Map.get(frame, :channel)
        assert "BTC/USD" == Map.get(frame, :market)
      end)

      assert capture_log(fn ->
               assert {:ok, {MockWebSocket, ["BTC/USD"]}} =
                        Worker.init(markets: ["BTC/USD"], ws_client: MockWebSocket)
             end) =~ "Subscribed to BTC/USD"
    end
  end

  describe "handle_cast/2" do
    test "logs the ticker updates" do
      assert capture_log(fn ->
               Worker.handle_cast(
                 {:handle_message,
                  %{
                    "channel" => "ticker",
                    "type" => "update",
                    "market" => "BTC/USD",
                    "data" => %{"last" => "0.01"}
                  }},
                 :ignored
               )
             end) =~ "BTC/USD 0.01"
    end

    test "logs nothing for ignored messages" do
      assert capture_log(fn ->
               Worker.handle_cast({:handle_message, %{"channel" => "not_ticker"}}, :ignored)
             end) == ""
    end
  end
end
