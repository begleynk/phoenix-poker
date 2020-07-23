defmodule Poker.Game.Phase.Flop do
  @behaviour Poker.Game.Phase

  alias Poker.Game.State

  @impl true
  def init(%State{} = state) do
    Map.put(state, :phase, :flop)
  end

  @impl true
  def transition(state, _action) do
    state
  end
end
