defmodule PokerWeb.LobbyLiveTest do
  use PokerWeb.ConnCase

  import Phoenix.LiveViewTest

  test "it renders the header", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "<h1>Tables</h1>"

    {:ok, _view, _html} = live(conn)
  end

  test "it renders a new table when one is created", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200)

    {:ok, view, _html} = live(conn)

    view
    |> form("#create_table", table: %{ name: "New Table" })
    |> render_submit()

     assert render(view) =~ "New Table"
  end
end
