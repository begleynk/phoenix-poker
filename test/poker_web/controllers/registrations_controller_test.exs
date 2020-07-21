defmodule PokerWeb.RegistrationsControllerTest do
  use PokerWeb.ConnCase

  @create_attrs %{ name: "Phil" }
  @invalid_args %{ }

  describe "create user" do
    test "creates a user and redirects to the lobby", %{conn: conn} do
      user_count = length(Poker.Account.list_users)

      conn = post(conn, Routes.registrations_path(conn, :create), user: @create_attrs)

      assert redirected_to(conn) == Routes.lobby_path(conn, :index)
      assert length(Poker.Account.list_users) == user_count + 1
    end

    test "it reloads the page if the creation fails", %{conn: conn} do
      conn = post(conn, Routes.registrations_path(conn, :create), user: @invalid_args)

      assert html_response(conn, 200) =~ "can&#39;t be blank"
    end
  end
end
