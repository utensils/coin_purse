defmodule CoinPurseWeb.CoinCardComponent do
  @moduledoc false
  use CoinPurseWeb, :live_component

  @impl true
  def render(assigns) do
    ~L"""
    <div class="relative px-6 pt-5 pb-5 overflow-hidden bg-white rounded-lg shadow">
      <%= if @data do %>
      <dt>
        <div class="absolute p-3 bg-blue-200 rounded-md">
          <img class="w-6 h-6" src="<%= icon_path(@socket, @data.market) %>">
        </div>
        <div class="flex items-baseline ml-16">
          <p class="flex ml-12 text-sm font-medium text-gray-500 truncate">Bid</p>
          <p class="flex ml-12 text-sm font-medium text-gray-500 truncate">Ask</p>
        </div>
      </dt>
      <dd class="mt-6 flex items-baseline">
        <p class="text-2xl font-semibold text-gray-900">
          <%= @data.last %>
        </p>
        <p class="flex items-baseline ml-2 text-sm font-semibold text-<%= color(@data.bid, @data.ask) %>-600">
          <%= @data.bid %>
        </p>
        <p class="flex items-baseline ml-2 text-sm font-semibold text-<%= color(@data.ask, @data.bid) %>-600">
          <%= @data.ask %>
        </p>
      </dd>
      <% end %>
    </div>
    """
  end

  defp color(one, two) when one > two, do: "green"
  defp color(one, two) when one < two, do: "red"
  defp color(_one, _two), do: "black"

  defp icon_path(socket, market) do
    Routes.static_path(socket, "/images/#{market}.svg")
  end
end
