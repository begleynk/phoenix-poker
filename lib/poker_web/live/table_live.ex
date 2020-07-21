defmodule PokerWeb.TableLive do
  use PokerWeb, :live_view

  alias Poker.Account

  @impl true
  def mount(params, %{"user_id" => id}, socket) do
    pid = Poker.Table.whereis(params["name"])
    Poker.Table.subscribe(pid)

    socket =
      socket
      |> assign(user: Account.get_user!(id))
      |> assign(:pid, pid)
      |> assign(:this, Poker.Table.state(pid))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <p>Playing as <strong><%= @user.name %></strong>. You have <strong><%= @user.chips %></strong> chips remaning.</p>
    <hr />
    <h1>The game: <%= @this.name %></h1>

    <%= for {i, seat} <- @this.seats do %>
      <%= live_component(@socket, PokerWeb.SeatLive, id: i, seat: seat) %>
    <% end %>
    """
  end

  @impl true
  def handle_event("sit", %{"value" => seat}, socket) do
    Poker.Table.sit(
      socket.assigns[:pid],
      socket.assigns[:user],
      index: String.to_integer(seat),
      amount: 1000
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:state_update, new_table_state}, socket) do
    {:noreply, socket |> assign(:this, new_table_state)}
  end
end
