defmodule Poker.Game.Phase.PreflopTest do
  use Poker.GameCase

  alias Poker.Game
  alias Poker.Game.Action

  @tag players: [{"Phil", 1000}, {"Jane", 1000}, {"Bob", 1000}, {"Eve", 1000}]
  test "it deals cards when blinds are posted", %{players: players} do
    {:ok, pid} = Game.start_link(%{name: "preflop_dealing", players: players })

    Game.state(pid)
    |> assert_pot(0)
    |> assert_community_cards([])
    |> assert_next_to_act(1)
    |> assert_available_actions([{:call, 5}])

    assert :ok = Game.handle_action(pid, Action.call(amount: 5, position: 1))

    Game.state(pid)
    |> assert_pot(0)
    |> assert_community_cards([])
    |> assert_next_to_act(2)
    |> assert_player_stack(1, 995)
    |> assert_available_actions([{:call, 10}])

    assert :ok = Game.handle_action(pid, Action.call(amount: 10, position: 2))

    Game.state(pid)
    |> assert_pot(0)
    |> assert_community_cards([])
    |> assert_next_to_act(3)
    |> assert_available_actions([{:call, 10}, :bet, :fold])
    |> assert_player_stack(2, 990)

    assert :ok = Game.handle_action(pid, Action.call(amount: 10, position: 3))

    Game.state(pid)
    |> assert_pot(0)
    |> assert_community_cards([])
    |> assert_next_to_act(0)
    |> assert_available_actions([{:call, 10}, :bet, :fold])
    |> assert_player_stack(3, 990)

    assert :ok = Game.handle_action(pid, Action.call(amount: 10, position: 0))

    Game.state(pid)
    |> assert_pot(0)
    |> assert_community_cards([])
    |> assert_next_to_act(1)
    |> assert_available_actions([{:call, 5}, :bet, :fold])
    |> assert_player_stack(0, 990)

    assert :ok = Game.handle_action(pid, Action.call(amount: 5, position: 1))

    Game.state(pid)
    |> assert_pot(0)
    |> assert_community_cards([])
    |> assert_next_to_act(2)
    |> assert_available_actions([:check, :bet, :fold])
    |> assert_player_stack(1, 990)

    assert :ok = Game.handle_action(pid, Action.check(position: 2))

    Game.state(pid) |> assert_phase(:flop)
  end
end