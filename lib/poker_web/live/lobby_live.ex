defmodule PokerWeb.LobbyLive do
  use PokerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if socket.connected?, do: Poker.Lobby.subscribe

    socket = socket
      |> assign(tables: Poker.Lobby.table_states())
      |> assign(table_name: "")

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <h1>Tables</h1>
    </hr>

    <%= f = form_for :table, "#", [phx_submit: :create_table, id: :create_table] %>
      <%= label f, :name %>
      <%= text_input f, :name %>

      <%= submit "Create Table" %>
    </form>

    <%= for t <- @tables do %>
      <h2><%= t.name %></h2>
    <% end %>
    """
  end

  @impl true
  def handle_event("create_table", %{"table" => params}, socket) do
    Poker.Lobby.create_table(params["name"])
    {:noreply, socket |> put_flash(:info, "Table created")}
  end

  @impl true
  def handle_info({:created, table}, socket) do
    {:noreply, update(socket, :tables, fn tables -> [table | tables] end)}
  end
end
