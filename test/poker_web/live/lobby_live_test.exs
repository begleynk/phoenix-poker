defmodule PokerWeb.LobbyLiveTest do
  use PokerWeb.ConnCase

  import Phoenix.LiveViewTest

  setup %{conn: conn} = config do
    if name = config[:login_as] do
      {:ok, user} = Poker.Account.create_user(%{name: name})
      {:ok, conn: init_test_session(conn, user_id: user.id), user: user}
    else
      :ok
    end
  end

  @tag login_as: "Phil"
  test "it renders the header", %{conn: conn} do
    conn = get(conn, Routes.lobby_path(conn, :index))
    assert html_response(conn, 200) =~ "<h1>Tables</h1>"

    {:ok, _view, _html} = live(conn)
  end

  @tag login_as: "Phil"
  test "it renders a new table when one is created", %{conn: conn} do
    conn = get(conn, Routes.lobby_path(conn, :index))
    assert html_response(conn, 200)

    {:ok, view, _html} = live(conn)

    view
    |> form("#create_table", table: %{name: "New Table"})
    |> render_submit()

    assert render(view) =~ "New Table"
  end

  @tag login_as: "Phil"
  test "it renders an error if there was one when a table is created", %{conn: conn} do
    conn = get(conn, Routes.lobby_path(conn, :index))
    assert html_response(conn, 200)

    {:ok, view, _html} = live(conn)

    view
    |> form("#create_table", table: %{name: "AA"})
    |> render_submit()

    assert render(view) =~ "should be at least"
  end
end
