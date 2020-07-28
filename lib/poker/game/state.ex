defmodule Poker.Game.State do
  @derive {Inspect, except: [:deck]}

  defstruct [
    :id,
    :players,
    :deck,
    :community_cards,
    :bets,
    :pot,
    :available_actions,
    :position, # NOTE: 0 == SB, 1 == BB, 5 == button in a 6 seater game
    :position_states,
    :actions,
    :phase,
    :winner,
  ]

  alias Poker.Deck
  alias Poker.Game.State
  alias Poker.Game.Action
  alias Poker.Game.Phase

  def new(%{players: players, id: id}) do
    Phase.Preflop.init(%State{players: build_players(players), id: id}) |> broadcast
  end

  def handle_action(%State{} = state, %Action{} = action) do
    case validate_action(state, action) do
      :ok -> {:ok, state |> transition(action) |> broadcast }
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
  end

  def call_bet(%State{} = state, position, amount) do
    state
    |> Map.update!(:bets, fn bets -> List.update_at(bets, position, &(&1 + amount)) end)
    |> Map.update!(:players, fn players ->
         List.update_at(players, position, fn(player) ->
           Map.update!(player, :chips, &(&1 - amount))
         end)
      end)
    |> mark_done(position)
  end

  def place_bet(%State{} = state, position, amount) do
    state
    |> Map.update!(:bets, fn bets -> List.update_at(bets, position, &(&1 + amount)) end)
    |> Map.update!(:players, fn players ->
         List.update_at(players, position, fn(player) ->
           Map.update!(player, :chips, &(&1 - amount))
         end)
      end)
    |> reset_others_states(position)
  end

  def mark_done(state, me) do
    Map.update!(state, :position_states, fn states ->
      List.update_at(states, me, fn(_) -> :done end)
    end)
  end

  def mark_active(state, me) do
    Map.update!(state, :position_states, fn states ->
      List.update_at(states, me, fn(_) -> :active end)
    end)
  end

  def reset_others_states(state, me) do
    Map.update!(state, :position_states, fn(states) -> 
      states
      |> Enum.with_index
      |> Enum.map(fn({state, index}) -> 
           if index == me do
             :done
           else
             if state != :folded do
               :active
             else
               state
             end
           end
         end)
    end)
  end

  def reset_states(state) do
    Map.update!(state, :position_states, fn(states) -> 
      states
      |> Enum.with_index |> Enum.map(fn({state, _index}) -> 
           if state != :folded do
             :active
           else
             state
           end
       end)
    end)
  end

  def fold_player(%State{} = state, position) do
    Map.update!(state, :position_states, fn players ->
      List.update_at(players, position, fn(_) -> :folded end)
    end)
  end

  def has_folded?(state, position) do
    Enum.at(state.position_states, position) == :folded
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

  @doc """
  Advances the position to the next player still in the game.
  NOTE: It's a nasty function...
  """
  def advance_position(%State{players: players, position: position} = state) do
    players =
      Enum.concat(players |> Enum.with_index, (players |> Enum.with_index))
      |> Enum.with_index

    {{_,_}, index} = Enum.find(players, fn({{_,_pos}, i}) ->
      i == position
    end)
    {{_, pos,}, _} = Enum.find(players, fn({{_, p}, i}) ->
      !has_folded?(state, p) && i > index
    end)

    Map.put(state, :position, pos)
  end

  def transition(%State{} = state, %Action{} = action) do
    case state.phase do
      :preflop -> Phase.Preflop.transition(state, action)
      :flop -> Phase.Flop.transition(state, action)
      :turn -> Phase.Turn.transition(state, action)
      :river -> Phase.River.transition(state, action)
      :done -> Phase.Done.transition(state, action)
      _ -> raise "Unimplemented phase '#{state.phase}'"
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
    active_player_positions(state) |> Enum.all?(fn(pos) -> bet_matched?(state, pos) end)
  end

  def all_players_have_acted?(state) do
    no_bets_to_match?(state) && everyone_acted?(state)
  end

  def everyone_acted?(state) do
    Enum.all?(state.position_states, fn(state) -> state in [:done, :folded] end)
  end

  def highest_bet(state) do
    Enum.max(state.bets)
  end

  def is_all_in?(state, position) do
    Enum.at(state.players, position).chips == 0
  end

  def all_but_one_folded?(state) do
    Enum.count(state.position_states, &(&1 != :folded)) == 1
  end

  def last_player_standing(state) do
    {_u, index} =
      state.position_states
      |> Enum.with_index
      |> Enum.find(fn({_s, i}) -> !has_folded?(state, i) end)

    index
  end

  def hand_ranks(state) do
    Enum.map(state.players, fn(%{cards: {l,r}}) ->
      Poker.HandRank.determine_best_hand([l, r | state.community_cards])
    end)
  end

  def compute_winner_based_on_hand_rank(state) do
    state
    |> hand_ranks
    |> Enum.with_index
    |> Enum.sort_by(fn({rank, _}) -> rank end, Poker.HandRank)
    |> Enum.map(fn({_, index}) -> index end)
    |> Enum.at(0)
  end

  def active_player_positions(state) do
    state.players
    |> Enum.with_index
    |> Enum.reject(fn({_, index}) -> has_folded?(state, index) end)
    |> Enum.map(fn({_, index}) -> index end)
  end

  defp build_players(players) do
    players |> Enum.map(fn player -> Map.put(player, :cards, {nil, nil}) end)
  end

  defp broadcast(state) do
    Phoenix.PubSub.broadcast(Poker.PubSub, "game_" <> state.id, {:game_state, state})
    state
  end
end
