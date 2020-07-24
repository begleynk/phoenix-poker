defmodule Poker.Game.Phase.Turn do
  use Poker.Game.Phase

  alias Poker.Game.State
  alias Poker.Game.Phase
  alias Poker.Game.AvailableActions
  alias Poker.Deck

  @impl true
  def init(%State{} = state) do
    state
    |> Map.put(:phase, :turn)
    |> Map.put(:position, 0)
    |> deal_single_community_card
    |> State.reset_states
  end

  @impl true
  def transition(state, action) do
    state
    |> handle_action(action)
    |> move_to_river_if_ready
    |> State.push_action(action)
    |> AvailableActions.compute()
  end

  defp deal_single_community_card(state) do
    {:ok, card, deck} = Deck.draw_card(state.deck)

    state
    |> Map.update!(:community_cards, fn(cards) -> [card | cards] end)
    |> Map.put(:deck, deck)
  end

  defp move_to_river_if_ready(state) do
    if State.all_players_have_acted?(state) do
      state |> Phase.River.init
    else
      state
    end
  end
end
