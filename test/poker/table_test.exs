defmodule Poker.TableTest do
  use Poker.GameCase

  alias Poker.Account
  alias Poker.Game
  alias Poker.Game.Action

  test "it has a name" do
    name = "the name"
    {:ok, pid} = Poker.Table.start_link(%{name: name})

    assert Poker.Table.name(pid) == name
  end

  test "it has 6 seats" do
    name = "the name"
    {:ok, pid} = Poker.Table.start_link(%{name: name})
    assert Poker.Table.seats(pid) == [nil, nil, nil, nil, nil, nil]
  end

  test "it can give a copy of its state" do
    name = "the name"
    {:ok, pid} = Poker.Table.start_link(%{name: name})

    state = Poker.Table.state(pid)

    assert %Poker.Table{
             name: ^name,
             seats: [nil, nil, nil, nil, nil, nil]
           } = state
  end

  test "a user can sit at a table" do
    table_name = "the_table"
    {:ok, user} = Account.create_user(%{name: "Joe"})
    user_id = user.id
    {:ok, pid} = Poker.Table.start_link(%{name: table_name})

    assert :ok = Poker.Table.sit(pid, user, index: 0, amount: 1000)

    assert %{user_id: ^user_id, name: "Joe", chips: 1000} = Enum.at(Poker.Table.seats(pid), 0)
    assert Account.balance(user.id) == user.chips - 1000
  end

  test "a user can leave the table and recover their balance" do
    {:ok, user} = Account.create_user(%{name: "Joe"})
    {:ok, pid} = Poker.Table.start_link(%{name: "the_table"})

    assert :ok = Poker.Table.sit(pid, user, index: 0, amount: 1000)
    assert :ok = Poker.Table.leave(pid, user)

    assert Account.balance(user.id) == user.chips
  end

  test "a user cannot sit at a table if they are already sitting" do
    {:ok, user} = Account.create_user(%{name: "Joe"})
    {:ok, pid} = Poker.Table.start_link(%{name: "the_table"})

    assert :ok = Poker.Table.sit(pid, user, index: 0, amount: 1000)
    assert {:error, "already seated"} = Poker.Table.sit(pid, user, index: 1, amount: 1000)
  end

  test "a user cannot buy in for more than their account balance" do
    {:ok, user} = Account.create_user(%{name: "Joe", chips: 900})
    {:ok, pid} = Poker.Table.start_link(%{name: "the_table"})

    assert {:error, "not enough chips"} = Poker.Table.sit(pid, user, index: 1, amount: 1000)
  end

  test "it starts a game if 2 or more players have joined" do
    {:ok, user1} = Account.create_user(%{name: "Bob"})
    {:ok, user2} = Account.create_user(%{name: "Alice"})

    {:ok, pid} = Poker.Table.start_link(%{name: "the_table"})
    Poker.Table.subscribe(pid)

    assert :ok = Poker.Table.sit(pid, user1, index: 1, amount: 1000)

    refute_receive {:new_game, _}, 100

    assert :ok = Poker.Table.sit(pid, user2, index: 2, amount: 1000)

    refute :undefined == Poker.Game.whereis(Poker.Table.state(pid).current_game)
  end

  test "starts a game with the order of players based on the button" do
    {:ok, user1} = Account.create_user(%{name: "Bob"})
    {:ok, user2} = Account.create_user(%{name: "Alice"})
    {:ok, user3} = Account.create_user(%{name: "Jane"})

    {:ok, pid} = Poker.Table.start_link(%{name: "the_table"})
    :ok = Poker.Table.disable_auto_start(pid)
    :ok = Poker.Table.set_button(pid, 1) # This willl advance by one when the game starts

    assert :ok = Poker.Table.sit(pid, user1, index: 0, amount: 1000)
    assert :ok = Poker.Table.sit(pid, user2, index: 1, amount: 1000)
    assert :ok = Poker.Table.sit(pid, user3, index: 2, amount: 1000)

    Poker.Table.start_game(pid)
    state = Poker.Game.whereis(Poker.Table.state(pid).current_game) |> Poker.Game.state

    assert Poker.Table.state(pid).button == 2
    assert Enum.at(state.players, 0).user_id == user2.id
    assert Enum.at(state.players, 0).seat == 1
    assert Enum.at(state.players, 1).user_id == user3.id
    assert Enum.at(state.players, 1).seat == 2
    assert Enum.at(state.players, 2).user_id == user1.id
    assert Enum.at(state.players, 2).seat == 0
  end

  test "it reconciles the pots of players once the game finishes" do
    {:ok, user1} = Account.create_user(%{name: "Bob"})
    {:ok, user2} = Account.create_user(%{name: "Alice"})
    {:ok, user3} = Account.create_user(%{name: "Jane"})

    {:ok, pid} = Poker.Table.start_link(%{name: "reconciliation_table"})
    :ok = Poker.Table.disable_auto_start(pid)
    :ok = Poker.Table.set_button(pid, 2)

    assert :ok = Poker.Table.sit(pid, user1, index: 0, amount: 1000)
    assert :ok = Poker.Table.sit(pid, user2, index: 1, amount: 1000)
    assert :ok = Poker.Table.sit(pid, user3, index: 2, amount: 1000)

    Poker.Table.start_game(pid)
    game_pid = Poker.Game.whereis(Poker.Table.state(pid).current_game)

    # Preflop
    assert {:ok, _} = Game.handle_action(game_pid, Action.call(amount: 5, position: 0))
    assert {:ok, _} = Game.handle_action(game_pid, Action.call(amount: 10, position: 1))
    assert {:ok, _} = Game.handle_action(game_pid, Action.bet(amount: 50, position: 2))
    assert {:ok, _} = Game.handle_action(game_pid, Action.call(amount: 45, position: 0))
    assert {:ok, _} = Game.handle_action(game_pid, Action.call(amount: 40, position: 1))

    # All but button fold on flop
    assert {:ok, _} = Game.handle_action(game_pid, Action.check(position: 0))
    assert {:ok, _} = Game.handle_action(game_pid, Action.check(position: 1))
    assert {:ok, _} = Game.handle_action(game_pid, Action.bet(amount: 500, position: 2))
    assert {:ok, _} = Game.handle_action(game_pid, Action.fold(position: 0))
    assert {:ok, _} = Game.handle_action(game_pid, Action.fold(position: 1))

    Game.state(game_pid)
    |> assert_phase(:done)
    |> assert_winner(2)
    |> assert_pot(0)
    |> assert_bets([0,0,0])

    players = Poker.Table.state(pid).seats
    assert Enum.at(players, 0).chips == 950
    assert Enum.at(players, 1).chips == 950
    assert Enum.at(players, 2).chips == 1100
  end
end
