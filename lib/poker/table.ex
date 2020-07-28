defmodule Poker.Table do
  use GenServer
  use Ecto.Schema

  import Ecto.Changeset

  alias Poker.Account
  alias Poker.Game
  alias Poker.GameSupervisor
  alias Poker.Account.User

  embedded_schema do
    field :name, :string
    field :seats, :map, default: [nil, nil, nil, nil, nil, nil]
    field :current_game, :string
    field :button, :integer, default: 0
    field :auto_start, :boolean, default: true
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

  def current_game(pid) do
    GenServer.call(pid, :current_game)
  end

  def sit(pid, %User{} = user, index: index, amount: amount) do
    GenServer.call(pid, {:sit, user, index, amount})
  end

  def leave(pid, index) do
    GenServer.call(pid, {:leave, index})
  end

  def start_game(pid) do
    GenServer.cast(pid, :start_game)
  end

  @doc """
  Only for testing purposes. Some tests want to handle starting and stopping
  of games themselves.
  """
  def disable_auto_start(pid) do
    GenServer.call(pid, :disable_auto_start)
  end

  def set_button(pid, position) do
    GenServer.call(pid, {:set_button, position})
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
  def handle_call(:current_game, _from, %Poker.Table{current_game: current_game} = state) do
    {:reply, current_game, state}
  end

  @impl true
  def handle_call({:set_button, pos}, _, %Poker.Table{} = state) do
    {:reply, :ok, Map.put(state, :button, pos)}
  end

  @impl true
  def handle_call({:sit, user, index, amount}, _from, %Poker.Table{seats: seats} = state) do
    cond do
      player_seated(state, user) ->
        {:reply, {:error, "already seated"}, state}

      balance_too_low(user, amount) ->
        {:reply, {:error, "not enough chips"}, state}

      true ->
        seats = List.update_at(seats, index, fn(_) ->
          %{user_id: user.id, name: user.name, chips: amount, seat: index}
        end)

        :ok = Account.subtract_balance(user, amount)

        if state.auto_start, do: GenServer.cast(self(), :start_game)

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
  def handle_call(:disable_auto_start, _, %Poker.Table{} = state) do
    {:reply, :ok, Map.put(state, :auto_start, false)}
  end

  @impl true
  def handle_cast(:start_game, %Poker.Table{} = state) do
    if number_of_players(state) >= 2 do
      {:noreply, state |> do_start_game |> broadcast(:new_game)}
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

  @impl true
  def handle_info({:game_state, %Game.State{id: game_id, phase: :done} = game_state}, %{current_game: game_id} = state) do
    # Resolve chips
    {:noreply, state |> update_chip_counts(game_state)}
  end

  @impl true
  def handle_info({:game_state, _}, state) do
    {:noreply, state}
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

  def do_start_game(state) do
    state = advance_button(state)

    {:ok, pid} = GameSupervisor.start_game(state.seats |> gather_players(state.button))
    Game.subscribe(pid)

    Map.put(state, :current_game, Game.id(pid))
  end

  defp update_chip_counts(table_state, %Game.State{phase: :done, players: players}) do
    Map.update!(table_state, :seats, fn(seats) ->
      seats
      |> Enum.with_index
      |> Enum.reject(fn({s,_}) -> s == nil end)
      |> Enum.map(fn({seat, index}) ->
          new_chips = case Enum.find_index(players, &(&1.seat == index)) do
            nil -> seat.chips
            some -> Enum.at(players, some).chips
          end

          %{seat | chips: new_chips}
        end)
      end)
  end

  defp advance_button(state) do
    state = Map.update!(state, :button, &(rem(&1 + 1, 5)))

    case Enum.at(state.seats, state.button) do
      nil -> advance_button(state)
      _players -> state
    end
  end

  def gather_players(players, button) do
    players
    |> Enum.reject(&(&1 == nil))
    |> Enum.reverse
    |> rotate(button)
    |> Enum.reverse
  end

  def rotate(list, times) when times == 0, do: list
  def rotate([head | list], times) do
    rotate(list ++ [head], times - 1)
  end

  defp broadcast(state, msg) do
    Phoenix.PubSub.broadcast(Poker.PubSub, "table_" <> state.name, {msg, state})
    state
  end
end
