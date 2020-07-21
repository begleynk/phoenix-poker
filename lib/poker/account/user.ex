defmodule Poker.Account.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :chips, :integer, default: 10000
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :chips])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
