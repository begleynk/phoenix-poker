defmodule PokerWeb.GameLive do
  use PokerWeb, :live_component

  alias Poker.Game
  alias Poker.Card

  def render(%{game: %Game.State{}, current_user: _user} = assigns) do
    ~L"""
    <p>Current Game: <%= @game.id %></p>
    <p>
      Phase: <%= @game.phase %>
      &nbsp&nbsp
      Next to Act: <%= @game.position %>
      &nbsp&nbsp
      Pot: <%= @game.pot %>
    </p>

    <h1>
      <%= for card <- @game.community_cards do %>
        <%= Card.render(card) %>
      <% end %>
    </h1>

    <%= if my_turn?(@game, @current_user) do %>
      <%= action_buttons(assigns)  %>
    <% end %>
    """
  end

  def action_buttons(%{game: %Game.State{}} = assigns) do
    ~L"""
    <%= for action <- @game.available_actions do %>
      <%= case action do %>
        <% {:call, amount} -> %>
          <button phx-click="call" value="<%= amount %>">Call <%= amount %></button>
        <% :fold -> %>
          <button value="fold">Fold</button>
        <% :check -> %>
          <button phx-click="check">Check</button>
        <% :bet -> %>
          <button value="bet">Bet</button>
      <% end %>
    <% end %>
    """
  end

  def my_turn?(game, user) do
    Enum.at(game.players, game.position).user_id == user.id
  end
end
