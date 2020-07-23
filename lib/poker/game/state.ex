defmodule Poker.Game.State do
  defstruct [
    :name,
    :players,
    :deck,
    :community_cards,
    :phase,
    :bets,
    :pot,
    :button,
    :stage,
    :available_actions,
    :actions,
    :position
  ]

  alias Poker.Deck
  alias Poker.Game.State
  alias Poker.Game.Action
  alias Poker.Game.Phase
  alias Poker.Game.AvailableActions

  def new(%{players: players, button: button, name: name}) do
    %State{
      players: build_players(players),
      button: button,
      name: name,
      community_cards: [],
      deck: Deck.new(),
      pot: 0,
      bets: [0, 0, 0, 0, 0, 0],
      phase: :preflop,
      position: 1,
      actions: []
    }
    |> AvailableActions.compute()
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

  def handle_action(%State{} = state, %Action{} = action) do
    case validate_action(state, action) do
      :ok ->
        {:ok,
         state
         |> transition(action)
         |> AvailableActions.compute()}

      error ->
        error
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
    state |> Map.update!(:actions, fn actions -> [action | actions] end)
  end

  def place_bet(%State{} = state, position, amount) do
    state |> Map.update!(:bets, fn bets -> List.update_at(bets, position, &(&1 + amount)) end)
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

  def advance_position(%State{} = state) do
    state |> Map.update!(:position, fn pos -> rem(pos + 1, 6) end)
  end

  def transition(%State{} = state, %Action{} = action) do
    case state.phase do
      :preflop -> Phase.Preflop.transition(state, action)
      _ -> raise "Unimplemented phase"
    end
  end

  def is_valid_action(state, action) do
    available_actions = state.available_actions.actions

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

  def highest_bet(state) do
    Enum.max(state.bets)
  end

  def player_at(state, :small_blind) do
    state.players
    |> Stream.cycle()
    |> Enum.at(state.button + 1)
  end

  def index_of(state, :small_blind) do
    [0, 1, 2, 3, 4, 5]
    |> Stream.cycle()
    |> Enum.at(state.button + 1)
  end
end
