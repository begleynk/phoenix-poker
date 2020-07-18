defmodule Poker.Lobby do
  use DynamicSupervisor

  alias Poker.Table

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def create_room(name) do
    spec = %{id: Table, start: {Table, :start_link, [name]}, restart: :transient}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def rooms do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} -> pid end)
  end
end
