defmodule Poker.Game.Phase.Flop do
  @behaviour Poker.Game.Phase

  alias Poker.Game.State
  alias Poker.Deck

  @impl true
  def init(%State{} = state) do
    state
    |> Map.put(:phase, :flop)
    |> Map.put(:position, 0)
    |> deal_community_cards
    |> State.reset_states
  end

  @impl true
  def transition(state, _action) do
    state
  end

  defp deal_community_cards(state) do
    {:ok, cards, deck} = Deck.draw_cards(state.deck, 3)

    state
    |> Map.put(:community_cards, cards)
    |> Map.put(:deck, deck)
  end
end
