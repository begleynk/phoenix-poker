defmodule PokerWeb.TableLiveTest do
  use Poker.GameCase
  use PokerWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Poker.Table
  alias Poker.Game
  alias Poker.Game.Action
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
    assert html =~ "Empty"

    view
    |> element("button[value='1']", "Sit")
    |> render_click()

    refute render(view) =~ "Seat 1: Empty"
    refute render(view) =~ "Sit"
  end

  @tag login_as: "Phil"
  test "receives a presence diff event when a user visits the table page", %{conn: conn, user: %{ id: user_id }} do
    {:ok, table} = Lobby.create_table("table_live_test3")
    state = Table.state(table)

    PokerWeb.Endpoint.subscribe(Table.presence_topic(state))

    {:ok, _view, _html} = live(conn, Routes.table_path(conn, :show, "table_live_test3"))

    user_id = "#{user_id}"
    assert_receive %{
      event: "presence_diff",
      payload: %{
        joins: %{
          ^user_id => _
        }
      }
    }
    refute_receive %{
      event: "presence_diff",
      payload: %{
        leaves: %{
          ^user_id => _
        }
      }
    }
  end

  @tag login_as: "Phil"
  test "it shows the 'leave' buttons which can be used to leave the table", %{conn: conn, user: %{id: user_id}} do
    {:ok, table} = Lobby.create_table("table_live_test4")

    {:ok, view, _html} = live(conn, Routes.table_path(conn, :show, "table_live_test4"))

    view
    |> element("button[value='1']", "Sit")
    |> render_click()

    assert [%{},nil,nil,nil,nil,nil] = Table.seats(table)
    assert render(view) =~ "Leave"

    view
    |> element("button", "Leave")
    |> render_click()

    assert Table.seats(table) == [nil,nil,nil,nil,nil,nil]
    assert render(view) =~ "Sit"
    assert render(view) =~ "Empty"
    user_id = "#{user_id}"
    assert_receive %{
      event: "presence_diff",
      payload: %{
        leaves: %{
          ^user_id => _
        }
      }
    }
  end

  @tag login_as: "Phil"
  @tag players: [{"Phil", 1000}, {"Jane", 1000}]
  test "starts a new game when one game ends", %{conn: conn, user: user1, players: players} do
    user2 = Account.get_user!(Enum.at(players, 1).user_id)

    {:ok, table} = Lobby.create_table("table_live_test5")

    assert :ok = Table.sit(table, user1, index: 0, amount: 1000)
    assert :ok = Table.sit(table, user2, index: 1, amount: 1000)

    state = Table.state(table)
    first_game = state.current_game
    game_pid = Game.whereis(first_game)
    Game.subscribe(game_pid)

    {:ok, view, html} = live(conn, Routes.table_path(conn, :show, "table_live_test5"))

    assert html =~ "Current Game: " <> first_game

    assert {:ok, _} = Game.handle_action(game_pid, Action.call(amount: 5, position: 0))
    assert {:ok, _} = Game.handle_action(game_pid, Action.call(amount: 10, position: 1))
    assert {:ok, _} = Game.handle_action(game_pid, Action.fold(position: 0))

    assert_receive {:game_complete, %Game.State{id: ^first_game}}, 400

    assert render(view) =~ "Current Game: " <> Table.state(table).current_game
    refute render(view) =~ "Current Game: " <> first_game
  end
end
