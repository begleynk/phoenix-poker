defmodule Poker.Game.Phase.River do
  use Poker.Game.Phase

  alias Poker.Game.State
  alias Poker.Game.AvailableActions
  alias Poker.Deck

  @impl true
  def init(%State{} = state) do
    state
    |> Map.put(:phase, :river)
    |> Map.put(:position, 0)
    |> deal_single_community_card
    |> State.reset_states
  end

  @impl true
  def transition(state, action) do
    state
    |> handle_action(action)
    |> State.push_action(action)
    |> AvailableActions.compute()
  end

  defp deal_single_community_card(state) do
    {:ok, card, deck} = Deck.draw_card(state.deck)

    state
    |> Map.update!(:community_cards, fn(cards) -> [card | cards] end)
    |> Map.put(:deck, deck)
  end
end
