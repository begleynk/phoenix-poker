defmodule Poker.Game.Phase.Flop do
  use Poker.Game.Phase

  alias Poker.Game.State
  alias Poker.Game.Phase
  alias Poker.Game.AvailableActions
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
  def transition(state, action) do
    state
    |> handle_action(action)
    |> State.push_action(action)
    |> AvailableActions.compute()
    |> move_to_next_phase
  end

  defp deal_community_cards(state) do
    {:ok, cards, deck} = Deck.draw_cards(state.deck, 3)

    state
    |> Map.put(:community_cards, cards)
    |> Map.put(:deck, deck)
  end

  defp move_to_next_phase(state) do
    if State.all_but_one_folded?(state) do
      state |> Phase.Done.init
    else
      if State.all_players_have_acted?(state) do
        state |> Phase.Turn.init
      else
        state
      end
    end
  end
end
