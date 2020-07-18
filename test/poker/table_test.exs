defmodule Poker.TableTest do
  use ExUnit.Case

  test "it has a name" do
    name = "the name"
    {:ok, pid} = Poker.Table.start_link(name)

    assert Poker.Table.name(pid) == name
  end

  test "it has 6 seats" do
    name = "the name"
    {:ok, pid} = Poker.Table.start_link(name)

    assert Poker.Table.seats(pid) == [
      nil,nil,nil,
      nil,nil,nil,
    ]
  end

  test "it can give a copy of its state" do
    name = "the name"
    {:ok, pid} = Poker.Table.start_link(name)

    state = Poker.Table.state(pid)

    assert %Poker.Table {
      name: ^name, 
      seats: [
        nil,nil,nil,
        nil,nil,nil,
      ]
    } = state
  end
end
