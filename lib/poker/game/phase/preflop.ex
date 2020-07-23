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
      bets: [0, 0, 0, 0, 0, 0],
      phase: :preflop,
      position: 1,
      actions: [],
      actions_in_phase: 0,
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
  defp handle_action(state, %Action{position: 1, type: :call, amount: 5}) do
    state
    |> State.place_bet(1, 5)
    |> State.advance_position()
  end

  # Handle big blind
  defp handle_action(state, %Action{position: 2, type: :call, amount: 10}) do
    state
    |> State.place_bet(2, 10)
    |> State.deal_pocket_cards()
    |> State.advance_position()
  end

  # Handle others
  defp handle_action(state, %Action{position: pos, type: :call, amount: amount}) do
    state
    |> State.place_bet(pos, amount)
    |> State.advance_position()
  end

  # Handle others
  defp handle_action(state, %Action{type: :check}) do
    state
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
