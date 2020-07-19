defmodule Poker.Table do
  use GenServer

  defstruct [:name, seats: [nil, nil, nil, nil, nil, nil]]

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: {:global, {:table, name}})
  end

  def whereis(name) do
    :global.whereis_name({:table, name})
  end

  def state(pid) do
    GenServer.call(pid, :state)
  end

  def name(pid) do
    GenServer.call(pid, :name)
  end

  def seats(pid) do
    GenServer.call(pid, :seats)
  end

  @impl true
  def init(name) do
    state = %Poker.Table{name: name}

    {:ok, state}
  end

  @impl true
  def handle_call(:state, _from, %Poker.Table{} = state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:name, _from, %Poker.Table{name: name} = state) do
    {:reply, name, state}
  end

  @impl true
  def handle_call(:seats, _from, %Poker.Table{seats: seats} = state) do
    {:reply, seats, state}
  end
end
