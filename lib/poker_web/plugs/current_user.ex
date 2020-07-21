defmodule PokerWeb.Plugs.CurrentUser do
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  alias PokerWeb.Router.Helpers, as: Routes
  alias Poker.Account
  alias Poker.Account.User

  def init(_) do
  end

  def call(conn, _) do
    case signed_in_user(conn) do
      %User{} = user ->
        conn |> assign_user(user)

      nil ->
        conn
        |> clear_session
        |> redirect(to: Routes.registrations_path(conn, :new))
        |> halt
    end
  end

  def signed_in_user(conn) do
    if id = get_session(conn, :user_id) do
      Account.get_user(id)
    end
  end

  def find_user(conn) do
    {conn, Poker.Account.get_user(conn.assigns[:user_id])}
  end

  def assign_user(conn, %User{} = user) do
    assign(conn, :current_user, user)
  end
end
