defmodule Poker.Game.AvailableActions do
  defstruct [:description, :actions, :position]

  alias Poker.Game.State
  alias Poker.Game.AvailableActions

  def compute(%State{actions: []} = state) do
    Map.put(state, :available_actions, %AvailableActions{
      actions: [{:call, 5}]
    })
  end

  def compute(%State{actions: actions} = state) when length(actions) == 1 do
    Map.put(state, :available_actions, %AvailableActions{
      actions: [{:call, 10}]
    })
  end

  def compute(%State{} = state) do
    actions =
      %AvailableActions{actions: []}
      |> check(state)

    Map.put(state, :available_actions, actions)
  end

  def check(actions, state) do
    if State.bet_matched?(state, state.position) do
      Map.update!(actions, :actions, fn a -> [:check | a] end)
    else
      actions
    end
  end
end
