defmodule PokerWeb.SeatLive do
  use PokerWeb, :live_component

  alias Poker.Card

  def render(%{id: _, seat: nil, user_seated: true} = assigns) do
    ~L"""
    <div class="seat">
      <h3>Empty</h3>
    </div>
    """
  end

  def render(%{id: _, seat: nil} = assigns) do
    ~L"""
    <div class="seat">
      <h3>Empty</h3>
      <button phx-click='sit' value='<%= @id %>'>Sit</button>
    </div>
    """
  end

  def render(%{id: _, seat: %{cards: {%Card{} = l, %Card{} = r}}} = assigns) do
    ~L"""
    <div class="seat <%= if @active_turn, do: 'active-turn', else: '' %>">
      <h3><%= @seat.name %><br /> <%= @seat.chips %> chips</h3>
      <%= if @is_current_user do %>
        <h1><%= Card.render(l) %><%= Card.render(r) %></h1>
      <% else %>
        <h1><%= Card.render_hidden %><%= Card.render_hidden %></h1>
      <% end %>
    </div>
    """
  end

  def render(%{id: _, seat: _} = assigns) do
    ~L"""
    <div class="seat <%= if @active_turn, do: 'active-turn', else: '' %>">
      <h3><%= @seat.name %>, <%= @seat.chips %> chips</h3>
      <%= if @can_leave do %>
        <button phx-click='leave' value='<%= @id %>'>Leave</button>
      <% end %>
    </div>
    """
  end
end
