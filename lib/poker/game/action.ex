defmodule Poker.Game.Action do
  defstruct [:type, :amount, :position]

  alias Poker.Game.Action

  def call(amount: amount, position: pos) do
    %Action{
      type: :call,
      amount: amount,
      position: pos
    }
  end

  def bet(amount: amount, position: pos) do
    %Action{
      type: :bet,
      amount: amount,
      position: pos
    }
  end

  def check(position: pos) do
    %Action{
      type: :check,
      amount: 0,
      position: pos
    }
  end

  def fold(position: pos) do
    %Action{
      type: :fold,
      amount: 0,
      position: pos
    }
  end
end
