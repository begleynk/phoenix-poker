defmodule Poker.GamePersistenceTest do
  use Poker.DataCase

  alias Poker.GamePersistence

  describe "table_records" do
    alias Poker.GamePersistence.TableRecord

    @valid_attrs %{button: 42, name: "some name"}
    @update_attrs %{button: 43, name: "some updated name"}
    @invalid_attrs %{button: nil, name: nil}

    def table_record_fixture(attrs \\ %{}) do
      {:ok, table_record} =
        attrs
        |> Enum.into(@valid_attrs)
        |> GamePersistence.create_table_record()

      table_record
    end

    test "list_table_records/0 returns all table_records" do
      table_record = table_record_fixture()
      assert GamePersistence.list_table_records() == [table_record]
    end

    test "get_table_record!/1 returns the table_record with given id" do
      table_record = table_record_fixture()
      assert GamePersistence.get_table_record!(table_record.id) == table_record
    end

    test "create_table_record/1 with valid data creates a table_record" do
      assert {:ok, %TableRecord{} = table_record} = GamePersistence.create_table_record(@valid_attrs)
      assert table_record.button == 42
      assert table_record.name == "some name"
    end

    test "create_table_record/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = GamePersistence.create_table_record(@invalid_attrs)
    end

    test "update_table_record/2 with valid data updates the table_record" do
      table_record = table_record_fixture()
      assert {:ok, %TableRecord{} = table_record} = GamePersistence.update_table_record(table_record, @update_attrs)
      assert table_record.button == 43
      assert table_record.name == "some updated name"
    end

    test "update_table_record/2 with invalid data returns error changeset" do
      table_record = table_record_fixture()
      assert {:error, %Ecto.Changeset{}} = GamePersistence.update_table_record(table_record, @invalid_attrs)
      assert table_record == GamePersistence.get_table_record!(table_record.id)
    end

    test "delete_table_record/1 deletes the table_record" do
      table_record = table_record_fixture()
      assert {:ok, %TableRecord{}} = GamePersistence.delete_table_record(table_record)
      assert_raise Ecto.NoResultsError, fn -> GamePersistence.get_table_record!(table_record.id) end
    end

    test "change_table_record/1 returns a table_record changeset" do
      table_record = table_record_fixture()
      assert %Ecto.Changeset{} = GamePersistence.change_table_record(table_record)
    end
  end
end
