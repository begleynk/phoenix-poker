defmodule Poker.Game.Phase.Done do
  use Poker.Game.Phase

  alias Poker.Game.State

  @impl true
  def init(state) do
    state
    |> Map.put(:phase, :done)
    |> compute_winner
  end

  @impl true
  def transition(state, _action) do
    state
  end

  defp compute_winner(state) do
    if State.all_but_one_folded?(state) do
      state
      |> Map.put(:winner, State.last_player_standing(state))
    end
  end
end
