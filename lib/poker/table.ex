defmodule Poker.Table do
  use GenServer
  use Ecto.Schema

  import Ecto.Changeset

  alias Poker.Account
  alias Poker.Account.User

  embedded_schema do
    field :name, :string
    field :seats, :map, default: [nil, nil, nil, nil, nil, nil]
  end

  def changeset(table, params \\ %{}) do
    table
    |> cast(params, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 4)
  end

  def start_link(params) do
    case %Poker.Table{} |> changeset(params) |> apply_action(:update) do
      {:ok, table} ->
        GenServer.start_link(__MODULE__, table, name: {:global, {:table, table.name}})

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @impl true
  def init(state) do
    {:ok, state}
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
        seats = List.insert_at(seats, index, %{user_id: user.id, name: user.name, chips: amount})

        :ok = Account.subtract_balance(user, amount)

        GenServer.cast(self(), :start_game)

        {:reply, :ok, %Poker.Table{state | seats: seats} |> broadcast(:user_joined)}
    end
  end

  @impl true
  def handle_call({:leave, user}, _from, %Poker.Table{seats: seats} = state) do
    if player_seated(state, user) do
      index = state |> position_of(user)
      %{chips: remaining_chips} = Enum.at(seats, index)

      seats = List.insert_at(seats, index, nil)

      :ok = Account.add_balance(user, remaining_chips)

      {:reply, :ok, %Poker.Table{state | seats: seats} |> broadcast(:user_left)}
    else
      {:reply, :ok, state}
    end
  end

  @impl true
  def handle_cast(:start_game, %Poker.Table{} = state) do
    if number_of_players(state) >= 2 do
      {:noreply, state |> broadcast(:new_game)}
    else
      {:noreply, state}
    end
  end

  defp position_of(%Poker.Table{seats: seats}, %User{id: id}) do
    case seats
         |> Enum.with_index()
         |> Enum.find(fn seat ->
           case seat do
             {nil, _} -> false
             {%{user_id: user_id}, _} -> user_id == id
           end
         end) do
      nil -> nil
      {_, matching_pos} -> matching_pos
    end
  end

  defp balance_too_low(user, amount) do
    Account.balance(user) < amount
  end

  defp player_seated(state, user) do
    position_of(state, user) != nil
  end

  defp number_of_players(state) do
    state.seats |> Enum.count(&(&1 != nil))
  end

  defp broadcast(state, msg) do
    Phoenix.PubSub.broadcast(Poker.PubSub, "table_" <> state.name, {msg, state})
    state
  end
end
