defmodule CoinPurseWeb.PageLive do
  @moduledoc false
  use CoinPurseWeb, :live_view

  alias CoinPurseWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    markets = markets()

    Enum.each(markets, &Endpoint.subscribe("markets:#{&1}"))

    market_amounts = Enum.into(markets, %{}, &{&1, 0})

    {:ok, assign(socket, :markets, market_amounts)}
  end

  @impl true
  def handle_info(%{event: "ticker_update", payload: {market, last, bid}}, socket) do
    markets = 
      socket.assigns
      |> Map.get(:markets, %{})
      |> Map.put(market, {last, bid})

    {:noreply, assign(socket, :markets, markets)}
  end

  def handle_info(_env, socket) do
    {:noreply, socket}
  end

  defp markets do
    :coin_purse
    |> Application.get_env(:exchanges)
    |> Keyword.get(:ftx)
    |> Keyword.fetch!(:markets)
  end
end
