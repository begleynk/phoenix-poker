defmodule Poker.Game.Phase.Done do
  use Poker.Game.Phase

  alias Poker.Game.State

  @impl true
  def init(state) do
    state
    |> Map.put(:phase, :done)
    |> move_bets_to_pot
    |> compute_winner
  end

  @impl true
  def transition(state, _action) do
    state
  end

  defp compute_winner(state) do
    if State.all_but_one_folded?(state) do
      Map.put(state, :winner, State.last_player_standing(state))
    else
      Map.put(state, :winner, State.compute_winner_based_on_hand_rank(state))
    end |> move_pot_to_winner
  end

  defp move_pot_to_winner(%State{ winner: winner, pot: pot} = state) do
    state 
    |> Map.update!(:players, fn(players) -> 
      List.update_at(players, winner, fn(player) -> 
        %{ player | chips: player.chips + pot }
      end)
    end)
    |> Map.put(:pot, 0)
  end
end
