defmodule Poker.AccountTest do
  use Poker.DataCase

  alias Poker.Account

  describe "users" do
    alias Poker.Account.User

    @valid_attrs %{chips: 42, name: "some name"}
    @update_attrs %{chips: 43, name: "some updated name"}
    @invalid_attrs %{chips: nil, name: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Account.create_user()

      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Account.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Account.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Account.create_user(@valid_attrs)
      assert user.chips == 42
      assert user.name == "some name"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Account.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Account.update_user(user, @update_attrs)
      assert user.chips == 43
      assert user.name == "some updated name"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Account.update_user(user, @invalid_attrs)
      assert user == Account.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Account.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Account.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Account.change_user(user)
    end

    test "name must be unique" do
      assert {:ok, _} = Account.create_user(%{name: "not unique"})

      assert {:error,
              %Ecto.Changeset{
                errors: [name: {"has already been taken", _}]
              }} = Account.create_user(%{name: "not unique"})
    end

    test "chips default to 10000" do
      assert {:ok, %User{chips: 10000, name: "chips"}} = Account.create_user(%{name: "chips"})
    end

    test "fetches the balance for a user" do
      {:ok, user} = Account.create_user(%{name: "chips fetch", chips: 1234})

      assert Account.balance(user.id) == 1234
    end

    test "subtracts from the balance of a user" do
      {:ok, user} = Account.create_user(%{name: "chips fetch", chips: 10000})

      assert :ok = Account.subtract_balance(user.id, 1000)
      assert Account.balance(user.id) == 9000
    end

    test "adds to the balance of a user" do
      {:ok, user} = Account.create_user(%{name: "chips fetch", chips: 10000})

      assert :ok = Account.add_balance(user.id, 1000)
      assert Account.balance(user.id) == 11000
    end
  end
end
