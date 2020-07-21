defmodule Poker.LobbyTest do
  use ExUnit.Case

  test "can be used to start tables" do
    assert {:ok, pid} = Poker.Lobby.create_table("my table")

    assert Enum.member?(Poker.Lobby.tables(), pid)
    assert ^pid = Poker.Table.whereis("my table")
  end

  test "broadcasting on table creation" do
    Poker.Lobby.subscribe()

    assert {:ok, pid} = Poker.Lobby.create_table("das table")
    assert_receive {:created, %Poker.Table{name: "das table"}}
  end
end
