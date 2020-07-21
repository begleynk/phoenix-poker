defmodule PokerWeb.RegistrationsController do
  use PokerWeb, :controller

  alias Poker.Account
  alias Poker.Account.User

  def new(conn, _params) do
    user = Account.change_user(%User{})
    render(conn, "new.html", changeset: user)
  end

  def create(conn, %{"user" => user}) do
    case Account.create_user(user) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> redirect(to: Routes.lobby_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
