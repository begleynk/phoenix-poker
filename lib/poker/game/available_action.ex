defmodule Poker.Game.AvailableActions do
  alias Poker.Game.State
  alias Poker.Game.AvailableActions

  def new() do
    []
  end

  def compute(%State{actions: []} = state) do
    Map.put(state, :available_actions, AvailableActions.new |> append_action({:call, 5}))
  end

  def compute(%State{actions: actions} = state) when length(actions) == 1 do
    Map.put(state, :available_actions, AvailableActions.new |> append_action({:call, 10}))
  end

  def compute(%State{} = state) do
    actions =
      AvailableActions.new
      |> fold(state)
      |> check(state)
      |> call(state)
      |> bet(state)

    Map.put(state, :available_actions, actions)
  end

  def check(actions, state) do
    if State.bet_matched?(state, state.position) do
      actions |> append_action(:check)
    else
      actions
    end
  end

  def fold(actions, _state) do
    actions |> append_action(:fold)
  end

  def call(actions, state) do
    if State.to_call(state, state.position) > 0 && !State.bet_matched?(state, state.position) do
      actions |> append_action({:call, State.to_call(state, state.position)})
    else
      actions
    end
  end

  def bet(actions, state) do
    if !State.is_all_in?(state, state.position) do
      actions |> append_action(:bet)
    else
      actions
    end
  end

  def append_action(actions, action) do
    [action | actions]
  end
end
