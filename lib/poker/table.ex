defmodule Poker.Table do
  use GenServer

  alias Poker.Account
  alias Poker.Account.User

  defstruct [
    :name,
    seats: %{1 => nil, 2 => nil, 3 => nil, 4 => nil, 5 => nil, 6 => nil},
  ]

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: {:global, {:table, name}})
  end

  def whereis(name) do
    :global.whereis_name({:table, name})
  end

  def subscribe(pid) do
    Phoenix.PubSub.subscribe(Poker.PubSub, "table_" <> name(pid))
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

  def sit(pid, %User{} = user, index: index, amount: amount) do
    GenServer.call(pid, {:sit, user, index, amount})
  end

  def leave(pid, index) do
    GenServer.call(pid, {:leave, index})
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

  @impl true
  def handle_call({:sit, user, index, amount}, _from, %Poker.Table{seats: seats} = state) do
    cond do
      player_seated(state, user) ->
        {:reply, {:error, "already seated"}, state}
      balance_too_low(user, amount) ->
        {:reply, {:error, "not enough chips"}, state}
      true ->
        seats = Map.put(seats, index, [user_id: user.id, name: user.name, chips: amount])

        :ok = Account.subtract_balance(user, amount)

        {:reply, :ok, %Poker.Table{state | seats: seats} |> broadcast}
    end
  end

  @impl true
  def handle_call({:leave, user}, _from, %Poker.Table{seats: seats} = state) do
    if player_seated(state, user) do
      index = state |> position_of(user)
      [user_id: _, name: _, chips: remaining_chips] = Map.get(seats, index)

      seats = Map.put(seats, index, nil)

      :ok = Account.add_balance(user, remaining_chips)

      {:reply, :ok, %Poker.Table{state | seats: seats} |> broadcast}
    else
      {:reply, :ok, state}
    end
  end

  defp position_of(%Poker.Table{seats: seats}, %User{id: id}) do
    case Enum.find(seats, fn {_pos, seat} -> seat[:user_id] == id end) do
      nil -> nil
      {matching_pos, _} -> matching_pos
    end
  end

  defp balance_too_low(user, amount) do
    Account.balance(user) < amount
  end

  defp player_seated(state, user) do
    position_of(state, user) != nil
  end

  defp broadcast(state) do
    Phoenix.PubSub.broadcast(Poker.PubSub, "table_" <> state.name, {:state_update, state})
    state
  end
end
