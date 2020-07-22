defmodule Poker.TableTest do
  use Poker.DataCase

  alias Poker.Account

  test "it has a name" do
    name = "the name"
    {:ok, pid} = Poker.Table.start_link(name)

    assert Poker.Table.name(pid) == name
  end

  test "it has 6 seats" do
    name = "the name"
    {:ok, pid} = Poker.Table.start_link(name)

    assert Poker.Table.seats(pid) == %{
             1 => nil,
             2 => nil,
             3 => nil,
             4 => nil,
             5 => nil,
             6 => nil
           }
  end

  test "it can give a copy of its state" do
    name = "the name"
    {:ok, pid} = Poker.Table.start_link(name)

    state = Poker.Table.state(pid)

    assert %Poker.Table{
             name: ^name,
             seats: %{
               1 => nil,
               2 => nil,
               3 => nil,
               4 => nil,
               5 => nil,
               6 => nil
             }
           } = state
  end

  test "a user can sit at a table" do
    table_name = "the_table"
    {:ok, user} = Account.create_user(%{name: "Joe"})
    user_id = user.id
    {:ok, pid} = Poker.Table.start_link(table_name)

    assert :ok = Poker.Table.sit(pid, user, index: 0, amount: 1000)

    assert [user_id: ^user_id, name: "Joe", chips: 1000] = Map.get(Poker.Table.seats(pid), 0)
    assert Account.balance(user.id) == user.chips - 1000
  end

  test "a user can leave the table and recover their balance" do
    table_name = "the_table"
    {:ok, user} = Account.create_user(%{name: "Joe"})
    {:ok, pid} = Poker.Table.start_link(table_name)

    assert :ok = Poker.Table.sit(pid, user, index: 0, amount: 1000)
    assert :ok = Poker.Table.leave(pid, user)

    assert Account.balance(user.id) == user.chips
  end

  test "a user cannot sit at a table if they are already sitting" do
    {:ok, user} = Account.create_user(%{name: "Joe"})
    {:ok, pid} = Poker.Table.start_link("the_table")

    assert :ok = Poker.Table.sit(pid, user, index: 0, amount: 1000)
    assert {:error, "already seated"} = Poker.Table.sit(pid, user, index: 1, amount: 1000)
  end

  test "a user cannot buy in for more than their account balance" do
    {:ok, user} = Account.create_user(%{name: "Joe", chips: 900})
    {:ok, pid} = Poker.Table.start_link("the_table")

    assert {:error, "not enough chips"} = Poker.Table.sit(pid, user, index: 1, amount: 1000)
  end
end
