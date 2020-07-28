defmodule Poker.Game.Phase do
  alias Poker.Game.State
  alias Poker.Game.Action

  @callback transition(state :: State.t(), action :: Action.t()) :: State.t()

  @callback init(state :: State.t()) :: State.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour Poker.Game.Phase
      @before_compile Poker.Game.Phase
    end
  end

  defmacro __before_compile__(_) do
    quote do
      # Default handling of calls
      defp handle_action(state, %Action{position: pos, type: :call, amount: amount}) do
        state
        |> State.call_bet(pos, amount)
        |> State.advance_position()
      end

      # Default handling of bets
      defp handle_action(state, %Action{position: pos, type: :bet, amount: amount}) do
        state
        |> State.place_bet(pos, amount)
        |> State.advance_position()
      end

      # Default handling of checks
      defp handle_action(state, %Action{type: :check, position: pos}) do
        state
        |> State.mark_done(pos)
        |> State.advance_position()
      end

      # Default handling of folds
      defp handle_action(state, %Action{type: :fold, position: pos}) do
        state
        |> State.fold_player(pos)
        |> State.advance_position()
      end

      def move_bets_to_pot(state) do
        state
        |> Map.update!(:pot, fn(pot) -> pot + Enum.sum(state.bets) end)
        |> Map.put(:bets, List.duplicate(0, length(state.players)))
      end
    end
  end
end
