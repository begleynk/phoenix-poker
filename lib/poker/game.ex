defmodule Poker.Game do
  use GenServer

  alias Poker.Game
  alias Poker.Game.Action
  alias Poker.Game.State

  def start_link(%{players: _p, button: _b, name: _n} = args) do
    GenServer.start_link(__MODULE__, args, name: {:global, {:game, args.name}})
  end

  @impl true
  def init(%{players: _p, button: _b, name: _n} = args) do
    {:ok, Game.State.new(args)}
  end

  def whereis(name) do
    :global.whereis_name({:game, name})
  end

  def handle_action(pid, %Action{} = action) do
    GenServer.call(pid, {:handle_action, action})
  end

  def deck(pid) do
    GenServer.call(pid, :deck)
  end

  def community_cards(pid) do
    GenServer.call(pid, :community_cards)
  end

  def pot(pid) do
    GenServer.call(pid, :pot)
  end

  def bets(pid) do
    GenServer.call(pid, :bets)
  end

  def players(pid) do
    GenServer.call(pid, :players)
  end

  def state(pid) do
    GenServer.call(pid, :state)
  end

  def phase(pid) do
    GenServer.call(pid, :phase)
  end

  def position(pid) do
    GenServer.call(pid, :position)
  end

  @impl true
  def handle_call(:community_cards, _, state) do
    {:reply, state.community_cards, state}
  end

  @impl true
  def handle_call(:deck, _, state) do
    {:reply, state.deck, state}
  end

  @impl true
  def handle_call(:pot, _, state) do
    {:reply, state.pot, state}
  end

  @impl true
  def handle_call(:bets, _, state) do
    {:reply, state.bets, state}
  end

  @impl true
  def handle_call(:players, _, state) do
    {:reply, state.players, state}
  end

  @impl true
  def handle_call(:phase, _, state) do
    {:reply, state.phase, state}
  end

  @impl true
  def handle_call(:position, _, state) do
    {:reply, state.position, state}
  end

  @impl true
  def handle_call(:state, _, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:handle_action, action}, _, state) do
    case state |> State.handle_action(action) do
      {:ok, new_state} -> {:reply, :ok, new_state}
      {:error, msg} -> {:reply, {:error, msg}, state}
    end
  end
end
