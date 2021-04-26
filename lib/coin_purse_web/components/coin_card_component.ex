defmodule CoinPurseWeb.CoinCardComponent do
  @moduledoc false
  use CoinPurseWeb, :live_component

  @impl true
  def render(assigns) do
    color = if assigns.bid > assigns.last, do: "green", else: "red"

    ~L"""
    <div class="relative px-6 pt-5 pb-5 overflow-hidden bg-white rounded-lg shadow">
      <dt>
        <div class="absolute p-3 bg-<%= color %>-200 rounded-md">
          <img class="w-6 h-6" src="<%= icon_path(@socket, @market) %>">
        </div>
        <p class="ml-16 text-sm font-medium text-gray-500 truncate">Last Traded Value</p>
      </dt>
      <dd class="flex items-baseline ml-16">
        <p class="text-2xl font-semibold text-gray-900">
          <%= @last %>
        </p>
        <p class="flex items-baseline ml-2 text-sm font-semibold text-<%= color %>-600">
          <%= @bid %>
        </p>
      </dd>
    </div>
    """
  end

  defp icon_path(socket, market) do
    Routes.static_path(socket, "/images/#{market}.svg")
  end
end
