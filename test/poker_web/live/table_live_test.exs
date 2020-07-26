defmodule PokerWeb.TableLiveTest do
  use Poker.GameCase
  use PokerWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Poker.Table
  alias Poker.Lobby
  alias Poker.Account

  @tag players: [{"Phil", 1000}, {"Jane", 1000}, {"Bob", 1000}, {"Eve", 1000}]
  @tag login_as: "Phil"
  test "it shows users sitting when visiting the table", %{players: players, conn: conn, user: _user} do
    user1 = Account.get_user!(Enum.at(players, 1).user_id)
    user2 = Account.get_user!(Enum.at(players, 2).user_id)
    user3 = Account.get_user!(Enum.at(players, 3).user_id)

    {:ok, table} = Lobby.create_table("my_table")
    :ok = Table.disable_auto_start(table)

    assert :ok = Table.sit(table, user1, index: 1, amount: 1000)
    assert :ok = Table.sit(table, user2, index: 2, amount: 1000)
    assert :ok = Table.sit(table, user3, index: 3, amount: 1000)

    {:ok, _view, html} = live(conn, Routes.table_path(conn, :show, "my_table"))

    assert html =~ "Table: my_table"
    assert html =~ "Jane"
    assert html =~ "Bob"
    assert html =~ "Jane"
  end

  @tag login_as: "Phil"
  test "it hides the 'sit' buttons when a user sits down", %{conn: conn, user: _user} do
    {:ok, _table} = Lobby.create_table("table_live_test2")

    {:ok, view, html} = live(conn, Routes.table_path(conn, :show, "table_live_test2"))

    assert html =~ "Sit"
    assert html =~ "Seat 1: Empty"

    view
    |> element("button[value='1']", "Sit")
    |> render_click()

    refute render(view) =~ "Seat 1: Empty"
    refute render(view) =~ "Sit"
  end
end
