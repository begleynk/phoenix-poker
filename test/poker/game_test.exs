defmodule Poker.GameTest do
  use Poker.DataCase

  alias Poker.Game
  alias Poker.Account

  setup config do
    if players = config[:players] do
      players =
        players
        |> Enum.map(fn {name, chips} ->
          {:ok, user} = Account.create_user(%{name: name, chips: chips})
          %{user_id: user.id, name: name, chips: chips}
        end)

      {:ok, players: players}
    else
      :ok
    end
  end

  @tag players: [{"Phil", 1000}, {"Jane", 1000}, {"Bob", 1000}, {"Eve", 1000}]
  test "the game starts with players posting blinds", %{players: players} do
    {:ok, pid} =
      Game.start_link(%{
        name: "not_important",
        players: players,
        button: 1
      })

    assert length(Game.deck(pid)) == 52
    assert Game.community_cards(pid) == []
    assert Game.pot(pid) == 0

    assert Game.players(pid) == [
             %{
               user_id: Enum.at(players, 0).user_id,
               name: "Phil",
               chips: 1000,
               cards: {nil, nil}
             },
             %{
               user_id: Enum.at(players, 1).user_id,
               name: "Jane",
               chips: 1000,
               cards: {nil, nil}
             },
             %{
               user_id: Enum.at(players, 2).user_id,
               name: "Bob",
               chips: 1000,
               cards: {nil, nil}
             },
             %{
               user_id: Enum.at(players, 3).user_id,
               name: "Eve",
               chips: 1000,
               cards: {nil, nil}
             }
           ]
  end

  @tag players: [{"Phil", 1000}, {"Jane", 1000}, {"Bob", 1000}, {"Eve", 1000}]
  test "blinds must be posted for cards to be dealt", %{players: players} do
    {:ok, pid} =
      Game.start_link(%{
        name: "not_important",
        players: players,
        button: 0
      })

    assert Game.pot(pid) == 0
    assert Game.bets(pid) == [0, 0, 0, 0, 0, 0]
    assert Game.position(pid) == 1

    Enum.each(Game.players(pid), fn player ->
      assert {nil, nil} = player.cards
    end)

    assert %Game.AvailableActions{
             actions: [{:call, 5}]
           } = Game.state(pid).available_actions

    assert :ok = Game.handle_action(pid, Game.Action.call(amount: 5, position: 1))

    assert Game.pot(pid) == 0
    assert Game.bets(pid) == [0, 5, 0, 0, 0, 0]
    assert Game.position(pid) == 2

    assert %Game.AvailableActions{
             actions: [{:call, 10}]
           } = Game.state(pid).available_actions

    assert :ok = Game.handle_action(pid, Game.Action.call(amount: 10, position: 2))

    assert Game.pot(pid) == 0
    assert Game.bets(pid) == [0, 5, 10, 0, 0, 0]
    assert Game.position(pid) == 3

    Enum.each(Game.players(pid), fn player ->
      assert {%Poker.Card{}, %Poker.Card{}} = player.cards
    end)
  end
end
