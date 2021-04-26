defmodule CoinPurseWeb.PageLiveTest do
  use CoinPurseWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "A new era in market tracking"
    assert render(page_live) =~ "<div><dl"
  end
end
