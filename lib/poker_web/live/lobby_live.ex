defmodule PokerWeb.LobbyLive do
  use PokerWeb, :live_view

  alias Poker.Account
  alias Poker.Table

  @impl true
  def mount(_params, %{"user_id" => id}, socket) do
    if socket.connected?, do: Poker.Lobby.subscribe()

    socket =
      socket
      |> assign(user: Account.get_user!(id))
      |> assign(tables: Poker.Lobby.table_states())
      |> assign(table_name: "")
      |> assign(changeset: Table.changeset(%Table{}))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <p>Playing as <strong><%= @user.name %></strong>. You have <strong><%= @user.chips %></strong> chips remaning.</p>
    <hr />
    <h1>Tables</h1>

    <%= f = form_for @changeset, "#", [phx_submit: :create_table, id: :create_table] %>
      <%= label f, :name %>
      <%= text_input f, :name %>
      <%= error_tag f, :name %>

      <%= submit "Create Table" %>
    </form>

    <%= for t <- @tables do %>
      <h2>
        <%= t.name %>
        <%= link "Join", to: Routes.table_path(@socket, :show, t.name) %>
      </h2>
      <p>Players: <%= Enum.count(t.seats, &(&1 != nil)) %>/ <%= length(t.seats) %></p>
    <% end %>
    """
  end

  @impl true
  def handle_event("create_table", %{"table" => params}, socket) do
    case Poker.Lobby.create_table(params["name"]) do
      {:ok, _} -> {:noreply, socket |> put_flash(:info, "Table created")}
      {:error, changeset} -> {:noreply, socket |> assign(:changeset, changeset)}
    end
  end

  @impl true
  def handle_info({:created, table}, socket) do
    {:noreply, update(socket, :tables, fn tables -> [table | tables] end)}
  end
end
