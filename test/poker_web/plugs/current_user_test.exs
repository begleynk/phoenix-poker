defmodule PokerWeb.Plugs.CurrentUserTest do
  use PokerWeb.ConnCase

  alias Poker.Account

  def connection(session \\ %{}) do
    build_conn() |> init_test_session(session)
  end

  test "no user is found if a sessin doesn't exist" do
    conn = connection() |> PokerWeb.Plugs.CurrentUser.call(%{})

    assert conn.assigns[:current_user] == nil
    assert redirected_to(conn) ==  Routes.registrations_path(conn, :new)
  end

  test "it finds the user if the user ID is set" do
    {:ok, user} = Account.create_user(%{name: "Gus" })

    conn =
      connection(user_id: user.id)
      |> PokerWeb.Plugs.CurrentUser.call(%{})

    assert conn.assigns[:current_user] == user
  end

  test "deletes the user_id key if the specified user does not exist" do
    conn =
      connection(user_id: 9919819323)
      |> PokerWeb.Plugs.CurrentUser.call(%{})

    assert conn.assigns[:user_id] == nil
  end
end
