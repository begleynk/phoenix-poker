defmodule Poker.GamePersistence.TableRecord do
  use Ecto.Schema
  import Ecto.Changeset

  schema "table_records" do
    field :name, :string
    field :button, :integer, default: 0

    timestamps()
  end

  @doc false
  def changeset(table_record, attrs \\ %{}) do
    table_record
    |> cast(attrs, [:name, :button])
    |> validate_required([:name])
    |> validate_length(:name, min: 4)
  end
end
