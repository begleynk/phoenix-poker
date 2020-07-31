defmodule Poker.TableSupervisor do
  use DynamicSupervisor

  alias Poker.Table
  alias Poker.GamePersistence.TableRecord

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_table(%TableRecord{} = record) do
    DynamicSupervisor.start_child(
      __MODULE__,
      %{id: Table, start: {Table, :start_link, [record]}, restart: :transient}
    )
  end

  def table_pids do
    DynamicSupervisor.which_children(__MODULE__)
  end
end
