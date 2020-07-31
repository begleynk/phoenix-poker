defmodule Poker.Lobby do
  use GenServer

  alias Poker.Lobby
  alias Poker.Table
  alias Poker.TableSupervisor
  alias Poker.GamePersistence
  alias Poker.GamePersistence.TableRecord

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_link() do
    Lobby.start_link([])
  end

  @impl true
  def init(_args) do
    GenServer.cast(__MODULE__, :start_tables)
    {:ok, nil}
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Poker.PubSub, "tables")
  end

  def create_table(name) do
    case GamePersistence.create_table_record(%{name: name}) do
      {:ok, record} -> start_table(record) |> broadcast
      error -> error
    end
  end

  def start_table(%TableRecord{} = record) do
    TableSupervisor.start_table(record)
  end

  def tables do
    TableSupervisor.table_pids |> Enum.map(fn {_, pid, _, _} -> pid end)
  end

  def table_states do
    Lobby.tables() |> Enum.map(fn p -> Table.state(p) end)
  end

  @impl true
  def handle_cast(:start_tables, state) do
    GamePersistence.list_table_records()
    |> Enum.each(&(start_table(&1)))

    {:noreply, state}
  end

  defp broadcast({:ok, pid}) do
    :ok = Phoenix.PubSub.broadcast(Poker.PubSub, "tables", {:created, Table.state(pid)})
    {:ok, pid}
  end
  defp broadcast(error), do: error
end
