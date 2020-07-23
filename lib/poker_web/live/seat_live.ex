defmodule PokerWeb.SeatLive do
  use PokerWeb, :live_component

  def render(%{id: _, seat: nil} = assigns) do
    ~L"""
    <h3>Seat <%= @id %>: Empty</h3>
    <button phx-click='sit' value='<%= @id %>'>Sit</button>
    """
  end

  def render(%{id: _, seat: _} = assigns) do
    ~L"""
    <h3>Seat <%= @id %>: <%= @seat[:name] %>, <%= @seat[:chips] %> chips</h3>
    """
  end
end
