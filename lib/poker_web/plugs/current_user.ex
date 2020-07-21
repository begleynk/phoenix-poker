defmodule PokerWeb.Plugs.CurrentUser do
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  alias PokerWeb.Router.Helpers, as: Routes
  alias Poker.Account
  alias Poker.Account.User

  def init(_) do
  end

  def call(conn, _) do
    case user_session(conn) do
      {:ok, user} ->
        conn |> assign_user(user)
      {:error, _} ->
        conn
        |> clear_session
        |> redirect(to: Routes.registrations_path(conn, :new))
    end
  end

  def user_session(conn) do
    if id = get_session(conn, :user_id) do
      case Account.get_user(id) do
        %User{} = user -> {:ok, user}
        nil -> {:error, nil}
      end
    else
      {:error, nil}
    end
  end

  def find_user(conn) do
    {conn, Poker.Account.get_user(conn.assigns[:user_id])}
  end

  def assign_user(conn, %User{} = user) do
    assign(conn, :current_user, user)
  end
end
