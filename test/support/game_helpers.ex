defmodule Poker.GameHelpers do
  use ExUnit.CaseTemplate

  setup tags do
    if players = tags[:players] do
      players =
        players
        |> Enum.with_index
        |> Enum.map(fn {{name, chips}, seat} ->
          {:ok, user} = Poker.Account.create_user(%{name: name, chips: chips})
          %{user_id: user.id, name: name, chips: chips, seat: seat}
        end)

      {:ok, players: players}
    else
      :ok
    end
  end

  def assert_pot(%Poker.Game.State{pot: pot} = state, expected) do
    assert pot == expected #, "Pot did not match expected"
    state
  end

  def assert_bets(%Poker.Game.State{bets: bets} = state, expected) do
    assert bets == expected #, "Bets did not match expected"
    state
  end

  def assert_community_card_count(%Poker.Game.State{community_cards: cards} = state, count) do
    assert length(cards) == count
    state
  end

  def assert_available_actions(%Poker.Game.State{available_actions: actions} = state, match) do
    expected = Enum.sort(match)
    actual = Enum.sort(actions)

    assert ^expected = actual #, "Available actions did not match expected"
    state
  end

  def assert_next_to_act(%Poker.Game.State{position: pos} = state, expected) do
    assert pos == expected #, "Next to act did not match expected"
    state
  end

  def assert_player_stack(%Poker.Game.State{players: players} = state, position, amount) do
    assert Enum.at(players, position).chips == amount #, "Next to act did not match expected"
    state
  end

  def assert_phase(%Poker.Game.State{phase: phase} = state, expected) do
    assert phase == expected
    state
  end

  def assert_position_states(%Poker.Game.State{position_states: actual} = state, expected) do
    assert actual == expected
    state
  end

  def assert_winner(%Poker.Game.State{winner: winner_pos} = state, expected) do
    assert winner_pos == expected
    state
  end

  def assert_has_winner(%Poker.Game.State{winner: winner_pos} = state) do
    assert winner_pos != nil, "No winner was computed"
    state
  end
end
