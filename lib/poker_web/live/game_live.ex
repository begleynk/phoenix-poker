defmodule PokerWeb.GameLive do
  use PokerWeb, :live_component

  alias Poker.Game

  def render(%{game: nil} = assigns) do
    ~L"""
    """
  end

  def render(%{game: %Game.State{}, current_user: user} = assigns) do
    ~L"""
    <p>Current Game: <%= @game.id %></p>
    """
  end
end
