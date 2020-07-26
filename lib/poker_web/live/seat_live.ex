defmodule PokerWeb.SeatLive do
  use PokerWeb, :live_component

  def render(%{id: _, seat: nil, user_seated: true} = assigns) do
    ~L"""
    <div class="seat">
      <h3>Seat <%= @id %>: Empty</h3>
    </div>
    """
  end

  def render(%{id: _, seat: nil} = assigns) do
    ~L"""
    <div class="seat">
      <h3>Seat <%= @id %>: Empty</h3>
      <button phx-click='sit' value='<%= @id %>'>Sit</button>
    </div>
    """
  end

  def render(%{id: _, seat: _} = assigns) do
    ~L"""
    <div class="seat">
      <h3>Seat <%= @id %>: <%= @seat.name %>, <%= @seat.chips %> chips</h3>
    </div>
    """
  end
end
