defmodule PokerWeb.GameLiveTest do
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
  test "it starts a game when 2 or more people sit down", %{players: players, conn: conn, user: user0} do
    user1 = Account.get_user!(Enum.at(players, 1).user_id)
    user2 = Account.get_user!(Enum.at(players, 2).user_id)
    user3 = Account.get_user!(Enum.at(players, 3).user_id)

    {:ok, table} = Lobby.create_table("game_live_test2")
    Table.disable_auto_start(table)
    Table.set_button(table, 3)

    assert :ok = Table.sit(table, user0, index: 0, amount: 1000)
    assert :ok = Table.sit(table, user1, index: 1, amount: 1000)
    assert :ok = Table.sit(table, user2, index: 2, amount: 1000)
    assert :ok = Table.sit(table, user3, index: 3, amount: 1000)

    Table.start_game(table)

    {:ok, _view, html} = live(conn, Routes.table_path(conn, :show, "game_live_test2"))

    assert html =~ Table.current_game(table)
  end

  @tag players: [{"Phil", 1000}, {"Jane", 1000}, {"Bob", 1000}, {"Eve", 1000}]
  @tag login_as: "Phil"
  test "it only shows action buttons when it is the signed in player's turn", %{players: players, conn: conn, user: user0} do
    user1 = Account.get_user!(Enum.at(players, 1).user_id)
    user2 = Account.get_user!(Enum.at(players, 2).user_id)
    user3 = Account.get_user!(Enum.at(players, 3).user_id)

    {:ok, table} = Lobby.create_table("game_live_test3")
    Table.disable_auto_start(table)
    Table.set_button(table, 3)

    assert :ok = Table.sit(table, user0, index: 0, amount: 1000)
    assert :ok = Table.sit(table, user1, index: 1, amount: 1000)
    assert :ok = Table.sit(table, user2, index: 2, amount: 1000)
    assert :ok = Table.sit(table, user3, index: 3, amount: 1000)

    {:ok, view, _html} = live(conn, Routes.table_path(conn, :show, "game_live_test3"))

    :ok = Table.start_game(table)
    game = Game.whereis(Table.current_game(table))

    html = render(view)
    assert html =~ Table.current_game(table)
    assert html =~ "Call"

    # Call small blind
    view
    |> element("button", "Call")
    |> render_click()

    assert Game.state(game).position == 1

    html = render(view)
    assert html =~ "Next to Act: 1"
    refute html =~ "Call"

    {:ok, _} = Game.handle_action(game, Action.call(amount: 10, position: 1))
    {:ok, _} = Game.handle_action(game, Action.call(amount: 10, position: 2))
    {:ok, _} = Game.handle_action(game, Action.call(amount: 10, position: 3))

    assert :bet in Game.state(game).available_actions
    assert {:call, 5} in Game.state(game).available_actions
    assert :fold in Game.state(game).available_actions
    assert Game.state(game).position == 0

    html = render(view)
    assert html =~ "Call"
    assert html =~ "Bet"
    assert html =~ "Fold"
  end
end
