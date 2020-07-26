defmodule PokerWeb.TableLive do
  use PokerWeb, :live_view

  alias Poker.Account
  alias Poker.Table
  alias Poker.Game

  @impl true
  def mount(params, %{"user_id" => id}, socket) do
    pid = Table.whereis(params["name"])
    Table.subscribe(pid)

    socket =
      socket
      |> assign(:user, Account.get_user!(id))
      |> assign(:pid, pid)
      |> assign(:this, Table.state(pid))

    socket = case Table.current_game(pid) do
      nil -> assign(socket, :current_game, nil)
      id  -> assign(socket, :current_game, Game.whereis(id) |> Game.state)
    end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <p>
      Playing as <strong><%= @user.name %></strong>.
      You have <strong><%= @user.chips %></strong> chips remaning.
    </p>

    <hr />
    <h1>Table: <%= @this.name %></h1>


    <div class='table'>
      <%= for {seat, i} <- Enum.with_index(@this.seats) do %>
        <%= live_component(
          @socket,
          PokerWeb.SeatLive,
          id: i + 1,
          seat: seat,
          user_seated: current_user_sitting?(@this.seats, @user))
        %>
      <% end %>

      <div class='game'>
        <%= live_component(
          @socket,
          PokerWeb.GameLive,
          game: @current_game,
          current_user: @user)
        %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("sit", %{"value" => seat}, socket) do
    case Table.sit(
           socket.assigns[:pid],
           socket.assigns[:user],
           index: String.to_integer(seat) - 1,
           amount: 1000
         ) do
      :ok -> {:noreply, socket}
      {:error, msg} -> {:noreply, socket |> put_flash(:error, msg)}
    end
  end

  @impl true
  def handle_info({:user_left, new_table_state}, socket) do
    {:noreply, socket |> assign(:this, new_table_state)}
  end

  @impl true
  def handle_info({:user_joined, new_table_state}, socket) do
    {:noreply, socket |> assign(:this, new_table_state)}
  end

  @impl true
  def handle_info({:new_game, new_table_state}, socket) do
    current_game =
      Game.whereis(new_table_state.current_game)
      |> Game.state

    Game.subscribe(current_game)

    {:noreply, socket |> assign(:current_game, current_game)}
  end

  @impl true
  def handle_info({:game_state, new_game_state}, socket) do
    {:noreply, socket |> assign(:current_game, new_game_state)}
  end

  def current_user_sitting?(seats, user) do
    seats
    |> Enum.reject(&(&1 == nil))
    |> Enum.map(&(&1.user_id))
    |> Enum.member?(user.id)
  end
end
