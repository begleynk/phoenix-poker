defmodule PokerWeb.TableLive do
  use PokerWeb, :live_view

  def mount(params, _session, socket) do
    pid = Poker.Table.whereis(params["name"])

    socket = socket
      |> assign(:pid, pid)
      |> assign(:this, Poker.Table.state(pid))

    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <h1>The game: <%= @this.name %></h1>

    <%= for {seat, i} <- Enum.with_index(@this.seats, 1) do %>
      <h3>Seat <%= i %>: <%= seat || "Empty" %></h3>
    <% end %>
    """
  end
end
