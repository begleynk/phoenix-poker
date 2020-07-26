defmodule Poker.GameSupervisor do
  use DynamicSupervisor

  alias Poker.Game

  def start_link(), do: start_link([])

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_game(seats) do
    spec = %{
      id: Game,
      start: {Game, :start_link, [%{players: seats, id: generate_id()}]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def generate_id do
    UUID.uuid4(:hex) |> String.slice(0, 16)
  end
end
