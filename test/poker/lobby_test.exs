defmodule Poker.LobbyTest do
  use ExUnit.Case

  test "starts with no rooms" do
    assert {:ok, _} = Poker.Lobby.start_link([])

    assert Poker.Lobby.rooms() == []
  end

  test "can be used to start rooms" do
    {:ok, _} = Poker.Lobby.start_link([])

    assert {:ok, pid} = Poker.Lobby.create_room("my room")

    assert [^pid] = Poker.Lobby.rooms()
    assert ^pid = Poker.Table.whereis("my room")
  end
end
