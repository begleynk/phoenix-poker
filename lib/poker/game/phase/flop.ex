defmodule Poker.Game.Phase.Flop do
  @behaviour Poker.Game.Phase

  alias Poker.Game.State

  @impl true
  def init(%State{} = state) do
    state
    |> Map.put(:phase, :flop)
    |> Map.put(:position, 0)
    |> State.reset_states
  end

  @impl true
  def transition(state, _action) do
    state
  end
end
