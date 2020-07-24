defmodule Poker.Game.Phase.FlopTest do
  use Poker.GameCase

  alias Poker.Game
  alias Poker.Game.Action

  def preflop_game(name, players) do
    {:ok, pid} = Game.start_link(%{name: name, players: players })

    assert :ok = Game.handle_action(pid, Action.call(amount: 5, position: 0))
    assert :ok = Game.handle_action(pid, Action.call(amount: 10, position: 1))
    assert :ok = Game.handle_action(pid, Action.call(amount: 10, position: 2))
    assert :ok = Game.handle_action(pid, Action.call(amount: 10, position: 3))
    assert :ok = Game.handle_action(pid, Action.call(amount: 5, position: 0))
    assert :ok = Game.handle_action(pid, Action.check(position: 1))

    pid
  end

  @tag players: [{"Phil", 1000}, {"Jane", 1000}, {"Bob", 1000}, {"Eve", 1000}]
  test "deals community cards on transition", %{players: players} do
    pid = preflop_game("flop community cards", players)

    Game.state(pid)
    |> assert_community_card_count(3)
  end

  @tag players: [{"Phil", 1000}, {"Jane", 1000}, {"Bob", 1000}, {"Eve", 1000}]
  test "moves to turn when complete", %{players: players} do
    pid = preflop_game("flop community cards", players)

    assert :ok = Game.handle_action(pid, Action.bet(amount: 50, position: 0))
    assert :ok = Game.handle_action(pid, Action.bet(amount: 150, position: 1))
    assert :ok = Game.handle_action(pid, Action.call(amount: 150, position: 2))
    assert :ok = Game.handle_action(pid, Action.call(amount: 150, position: 3))
    assert :ok = Game.handle_action(pid, Action.call(amount: 100, position: 0))

    Game.state(pid)
    |> assert_phase(:turn)
  end
end