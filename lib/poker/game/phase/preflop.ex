defmodule Poker.Game.Phase.Preflop do
  @behaviour Poker.Game.Phase

  alias Poker.Game.State
  alias Poker.Game.Action

  @impl true
  def transition(state, action) do
    state
    |> handle_call(action)
    |> State.push_action(action)
  end

  # Handle small blind
  defp handle_call(state, %Action {position: 1, type: :call, amount: 5}) do
    state
    |> State.place_bet(1, 5)
    |> State.advance_position
  end

  # Handle big blind
  defp handle_call(state, %Action {position: 2, type: :call, amount: 10}) do
    state
    |> State.place_bet(2, 10)
    |> State.advance_position
  end
end
