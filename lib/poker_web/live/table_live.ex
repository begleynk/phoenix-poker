defmodule PokerWeb.TableLive do
  use PokerWeb, :live_view

  alias Poker.Account
  alias Poker.Table
  alias Poker.Game
  alias Poker.Game.Action
  alias PokerWeb.Presence

  @impl true
  def mount(params, %{"user_id" => id}, socket) do
    pid = Table.whereis(params["name"])
    Table.subscribe(pid)

    socket =
      socket
      |> assign(:user, Account.get_user!(id))
      |> assign(:pid, pid)
      |> assign(:this, Table.state(pid))
      |> fetch_current_game
      |> subscribe_to_game
      |> setup_presence

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
      <%= if @current_game do %>
        <%= for {seat, i} <- Enum.with_index(@this.seats) do %>
          <%= live_component(
            @socket,
            PokerWeb.SeatLive,
            id: i + 1,
            is_current_user: seat != nil && seat.user_id == @user.id,
            seat: sitting_player(@current_game.players, i),
            user_seated: current_user_sitting?(@this.seats, @user),
            can_leave: false,
            active_turn: action_on_player?(@current_game, i)
          )
          %>
        <% end %>

        <div class='game'>
          <%= live_component(
            @socket,
            PokerWeb.GameLive,
            id: @current_game.id,
            game: @current_game,
            current_user: @user)
          %>
        </div>
      <% else %>
        <%= for {seat, i} <- Enum.with_index(@this.seats) do %>
          <%= live_component(
            @socket,
            PokerWeb.SeatLive,
            id: i + 1,
            seat: seat,
            is_current_user: seat != nil && seat.user_id == @user.id,
            user_seated: current_user_sitting?(@this.seats, @user),
            can_leave: true,
            active_turn: false
          )
          %>
        <% end %>
      <% end %>
    </div>

    <hr />
    <br />
    <br />
    <%= for seat <- @viewers do %>
      <%= inspect seat %>
    <% end %>
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
      :ok ->
        Presence.update(
          self(),
          presence_topic(socket.assigns.this),
          socket.assigns.user.id,
          fn(m) -> %{ m | seat: String.to_integer(seat) } end
        )

        {:noreply, socket}
      {:error, msg} -> {:noreply, socket |> put_flash(:error, msg)}
    end
  end

  @impl true
  def handle_event("leave", _, socket) do
    case Table.leave(socket.assigns[:pid], socket.assigns.user) do
      :ok ->
        Presence.update(
          self(),
          presence_topic(socket.assigns.this),
          socket.assigns.user.id,
          fn(m) -> %{ m | seat: nil } end
        )

        {:noreply, socket}
      {:error, msg} -> {:noreply, socket |> put_flash(:error, msg)}
    end
  end

  def handle_event("call", %{"value" => amount}, socket) do
    pid = Game.whereis(socket.assigns[:current_game].id)
    action = Action.call(
      amount: String.to_integer(amount),
      position: socket.assigns[:current_game].position
    )
    {:ok, game} = Game.handle_action(pid, action)

    {:noreply, socket |> assign(:current_game, game)}
  end

  def handle_event("check", _, socket) do
    pid = Game.whereis(socket.assigns[:current_game].id)
    action = Action.check(
      position: socket.assigns[:current_game].position
    )
    {:ok, game} = Game.handle_action(pid, action)

    {:noreply, socket |> assign(:current_game, game)}
  end

  def handle_event("bet", %{"value" => amount}, socket) do
    pid = Game.whereis(socket.assigns[:current_game].id)
    action = Action.bet(
      amount: String.to_integer(amount),
      position: socket.assigns[:current_game].position
    )
    {:ok, game} = Game.handle_action(pid, action)

    {:noreply, socket |> assign(:current_game, game)}
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
  def handle_info({:new_game, game}, socket) do
    game_pid = Game.whereis(game.current_game)
    current_game = Game.state(game_pid)

    Game.subscribe(game_pid)

    {:noreply, socket |> assign(:current_game, current_game)}
  end

  @impl true
  def handle_info({:game_state, new_game_state}, socket) do
    {:noreply, socket |> assign(:current_game, new_game_state)}
  end

  @doc """
  This function gets invoked when a change has been detected in the player
  presence information by Phoenix Presence.
  """
  @impl true
  def handle_info(%{event: "presence_diff", payload: %{joins: _joins, leaves: _leaves}}, socket) do
    {:noreply, assign(socket, :viewers, Presence.list(presence_topic(socket.assigns.this)))}
  end

  def current_user_sitting?(seats, user) do
    seats
    |> Enum.reject(&(&1 == nil))
    |> Enum.map(&(&1.user_id))
    |> Enum.member?(user.id)
  end

  def sitting_player(seats, seat_index) do
    Enum.find(seats, fn(seat) -> 
      seat.seat == seat_index
    end)
  end

  def fetch_current_game(socket) do
    case Table.current_game(socket.assigns.pid) do
      nil -> assign(socket, :current_game, nil)
      id  -> assign(socket, :current_game, Game.whereis(id) |> Game.state)
    end
  end

  def setup_presence(socket) do
    {:ok, _} = Presence.track(
      self(), 
      presence_topic(socket.assigns.this),
      socket.assigns.user.id,
      current_user_presence(socket)
    )
    PokerWeb.Endpoint.subscribe(presence_topic(socket.assigns.this))

    assign(socket, :viewers, Presence.list(presence_topic(socket.assigns.this)))
  end

  def presence_topic(table) do
    Table.presence_topic(table)
  end

  def current_user_presence(socket) do
    case Enum.find_index(
      socket.assigns.this.seats,
      &(&1 != nil && &1.user_id == socket.assigns.user.id)) do
      nil -> %{ seat: nil }
      index -> %{ seat: index + 1}
    end
  end

  def subscribe_to_game(socket) do
    case socket.assigns.current_game do
      nil -> socket
      game ->
        Game.whereis(game.id) |> Game.subscribe
        socket
    end
  end

  def action_on_player?(game, seat_index) do
    case Enum.at(game.players, game.position) do
      nil -> false
      %{seat: seat} -> seat == seat_index
    end
  end
end
