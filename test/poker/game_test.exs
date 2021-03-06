defmodule Poker.GameTest do
  use Poker.GameCase

  alias Poker.Game
  alias Poker.Game.Action

  @tag players: [{"Phil", 1000}, {"Jane", 1000}, {"Bob", 1000}, {"Eve", 1000}]
  test "the game starts with players posting blinds", %{players: players} do
    {:ok, pid} =
      Game.start_link(%{
        id: "not_important",
        players: players,
      })

    assert length(Game.deck(pid)) == 52
    assert Game.community_cards(pid) == []
    assert Game.pot(pid) == 0

    assert Game.players(pid) == [
             %{
               user_id: Enum.at(players, 0).user_id,
               name: "Phil",
               chips: 1000,
               cards: {nil, nil},
               seat: 0,
             },
             %{
               user_id: Enum.at(players, 1).user_id,
               name: "Jane",
               chips: 1000,
               cards: {nil, nil},
               seat: 1,
             },
             %{
               user_id: Enum.at(players, 2).user_id,
               name: "Bob",
               chips: 1000,
               cards: {nil, nil},
               seat: 2,
             },
             %{
               user_id: Enum.at(players, 3).user_id,
               name: "Eve",
               chips: 1000,
               cards: {nil, nil},
               seat: 3,
             }
           ]
  end

  @tag players: [{"Phil", 1000}, {"Jane", 1000}, {"Bob", 1000}, {"Eve", 1000}]
  test "game moves on via actions", %{players: players} do
    {:ok, pid} =
      Game.start_link(%{
        id: "not_important",
        players: players,
        button: 0
      })

    assert Game.pot(pid) == 0
    assert Game.bets(pid) == [0, 0, 0, 0]
    assert Game.position(pid) == 0

    Enum.each(Game.players(pid), fn player ->
      assert {nil, nil} = player.cards
    end)

    assert Game.state(pid).available_actions == [{:call, 5}]

    assert {:ok, _} = Game.handle_action(pid, Game.Action.call(amount: 5, position: 0))

    assert Game.pot(pid) == 0
    assert Game.bets(pid) == [5, 0, 0, 0]
    assert Game.position(pid) == 1
    assert Game.state(pid).available_actions == [{:call, 10}]

    assert {:ok, _} = Game.handle_action(pid, Game.Action.call(amount: 10, position: 1))

    assert Game.pot(pid) == 0
    assert Game.bets(pid) == [5, 10, 0, 0]
    assert Game.position(pid) == 2

    Enum.each(Game.players(pid), fn player ->
      assert {%Poker.Card{}, %Poker.Card{}} = player.cards
    end)

    Game.state(pid) |> assert_available_actions([:bet, {:call, 10}, :fold])
  end

  @tag players: [{"Phil", 1000}, {"Jane", 1000}, {"Bob", 1000}, {"Eve", 1000}]
  test "game ends if all but one player folds", %{players: players} do
    {:ok, pid} = Game.start_link(%{id: "game_ends_on_folds", players: players })

    # Preflop
    assert {:ok, _} = Game.handle_action(pid, Action.call(amount: 5, position: 0))
    assert {:ok, _} = Game.handle_action(pid, Action.call(amount: 10, position: 1))
    assert {:ok, _} = Game.handle_action(pid, Action.call(amount: 10, position: 2))
    assert {:ok, _} = Game.handle_action(pid, Action.call(amount: 10, position: 3))
    assert {:ok, _} = Game.handle_action(pid, Action.call(amount: 5, position: 0))
    assert {:ok, _} = Game.handle_action(pid, Action.check(position: 1))

    # All but button fold on flop
    assert {:ok, _} = Game.handle_action(pid, Action.fold(position: 0))
    assert {:ok, _} = Game.handle_action(pid, Action.fold(position: 1))
    assert {:ok, _} = Game.handle_action(pid, Action.fold(position: 2))

    Game.state(pid)
    |> assert_phase(:done)
    |> assert_winner(3)
  end
end
