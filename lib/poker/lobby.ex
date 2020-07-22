defmodule Poker.Lobby do
  use DynamicSupervisor

  alias Poker.Table

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_link() do
    Poker.Lobby.start_link([])
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Poker.PubSub, "tables")
  end

  # TODO: Error handling?
  def create_table(name) do
    spec = %{id: Table, start: {Table, :start_link, [%{name: name}]}, restart: :transient}

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, pid} -> 
        :ok = Phoenix.PubSub.broadcast(Poker.PubSub, "tables", {:created, Table.state(pid)})
        {:ok, pid}
      error -> error
    end
  end

  def tables do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} -> pid end)
  end

  def table_states do
    Poker.Lobby.tables() |> Enum.map(fn p -> Poker.Table.state(p) end)
  end
end
