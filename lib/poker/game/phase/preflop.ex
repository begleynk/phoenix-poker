defmodule Poker.Game.Phase.Preflop do
  @behaviour Poker.Game.Phase

  alias Poker.Game.State
  alias Poker.Game.Action
  alias Poker.Game.AvailableActions
  alias Poker.Game.Phase
  alias Poker.Deck

  @impl true
  def init(%State{players: players, name: name}) do
    %State{
      players: build_players(players),
      name: name,
      community_cards: [],
      deck: Deck.new(),
      pot: 0,
      bets: List.duplicate(0, length(players)),
      phase: :preflop,
      position: 0, # Button is the last position. 0 == small blind, 1 == big blind, etc.
      position_states: List.duplicate(:active, length(players)),
      actions: [],
    } |> AvailableActions.compute
  end

  @impl true
  def transition(state, action) do
    state
    |> handle_action(action)
    |> move_to_flop_if_ready
    |> State.push_action(action)
    |> AvailableActions.compute()
  end

  # Handle small blind
  defp handle_action(%State{actions: []} = state, %Action{position: 0, type: :call, amount: 5}) do
    state
    |> State.call_bet(0, 5)
    |> State.mark_active(0)
    |> State.advance_position()
  end

  # Handle big blind
  defp handle_action(%State{actions: actions} = state, %Action{position: 1, type: :call, amount: 10})
  when length(actions) == 1
  do
    state
    |> State.call_bet(1, 10)
    |> State.mark_active(1)
    |> State.deal_pocket_cards()
    |> State.advance_position()
  end

  # Handle other calls
  defp handle_action(state, %Action{position: pos, type: :call, amount: amount}) do
    state
    |> State.call_bet(pos, amount)
    |> State.advance_position()
  end

  # Handle bets
  defp handle_action(state, %Action{position: pos, type: :bet, amount: amount}) do
    state
    |> State.place_bet(pos, amount)
    |> State.advance_position()
  end

  # Handle checks
  defp handle_action(state, %Action{type: :check, position: pos}) do
    state
    |> State.mark_done(pos)
    |> State.advance_position()
  end

  # Handle folds
  defp handle_action(state, %Action{type: :fold, position: pos}) do
    state
    |> State.fold_player(pos)
    |> State.advance_position()
  end

  defp move_to_flop_if_ready(state) do
    if State.all_players_have_acted?(state) do
      state |> Phase.Flop.init
    else
      state
    end
  end

  defp build_players(players) do
    Enum.map(players, fn player ->
      %{
        user_id: player[:user_id],
        name: player[:name],
        chips: player[:chips],
        cards: {nil, nil}
      }
    end)
  end
end
