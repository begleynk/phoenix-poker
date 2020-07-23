defmodule Poker.Game.State do
  defstruct [
    :name,
    :players,
    :deck,
    :community_cards,
    :bets,
    :pot,
    :stage,
    :available_actions,
    :position,
    :actions,
    :phase,
    :actions_in_phase,
  ]

  alias Poker.Deck
  alias Poker.Game.State
  alias Poker.Game.Action
  alias Poker.Game.Phase
  alias Poker.Game.AvailableActions

  def new(%{players: players, name: name}) do
    Phase.Preflop.init(%State{players: players, name: name})
  end

  def handle_action(%State{} = state, %Action{} = action) do
    case validate_action(state, action) do
      :ok -> {:ok, state |> transition(action) }
      error -> error
    end
  end

  def validate_action(%State{} = state, %Action{} = action) do
    cond do
      state.position != action.position ->
        {:error, "action out of turn"}

      !is_valid_action(state, action) ->
        {:error, "invalid action"}

      true ->
        :ok
    end
  end

  def push_action(%State{} = state, %Action{} = action) do
    state
    |> Map.update!(:actions, fn actions -> [action | actions] end)
    |> Map.update!(:actions_in_phase, &(&1 + 1))
  end

  def place_bet(%State{} = state, position, amount) do
    state
    |> Map.update!(:bets, fn bets -> List.update_at(bets, position, &(&1 + amount)) end)
    |> Map.update!(:players, fn players ->
         List.update_at(players, position, fn(player) ->
           Map.update!(player, :chips, &(&1 - amount))
         end)
      end)
  end

  def deal_pocket_cards(%State{} = s) do
    Enum.reduce(0..5, s, fn seat, state ->
      {:ok, [left, right], deck} = Deck.draw_cards(state.deck, 2)

      state
      |> Map.update!(:players, fn players ->
        List.update_at(players, seat, fn player ->
          Map.put(player, :cards, {left, right})
        end)
      end)
      |> Map.put(:deck, deck)
    end)
  end

  def advance_position(%State{players: players} = state) do
    state |> Map.update!(:position, fn pos -> rem(pos + 1, length(players)) end)
  end

  def transition(%State{} = state, %Action{} = action) do
    case state.phase do
      :preflop -> Phase.Preflop.transition(state, action)
      :flop -> Phase.Flop.transition(state, action)
      _ -> raise "Unimplemented phase"
    end
  end

  def is_valid_action(state, action) do
    available_actions = state.available_actions

    case action.type do
      :call -> {:call, action.amount} in available_actions
      other -> other in available_actions
    end
  end

  def bet_matched?(state, position) do
    to_call(state, position) == 0
  end

  def to_call(state, position) do
    highest_bet(state) - Enum.at(state.bets, position)
  end

  def no_bets_to_match?(state) do
    0..(length(state.players) - 1)
    |> Enum.all?(fn(pos) -> to_call(state, pos) == 0 end)
  end

  def all_players_have_acted?(state) do
    no_bets_to_match?(state) && state.actions_in_phase > length(state.players)
  end

  def highest_bet(state) do
    Enum.max(state.bets)
  end

  def is_all_in?(state, position) do
    Enum.at(state.players, position).chips == 0
  end
end
