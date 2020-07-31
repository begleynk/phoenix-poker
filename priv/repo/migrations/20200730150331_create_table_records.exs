defmodule Poker.Repo.Migrations.CreateTableRecords do
  use Ecto.Migration

  def change do
    create table(:table_records) do
      add :name, :string, null: false
      add :button, :integer, null: false, default: 0

      timestamps()
    end

    create unique_index(:table_records, [:name])
  end
end
