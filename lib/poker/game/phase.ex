defmodule Poker.Game.Phase do

  alias Poker.Game.State
  alias Poker.Game.Action

  @callback transition(state :: State.t, action :: Action.t) :: State.t
end
