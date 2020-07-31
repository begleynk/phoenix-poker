defmodule Poker.GamePersistence do
  @moduledoc """
  The GamePersistence context.
  """

  import Ecto.Query, warn: false
  alias Poker.Repo

  alias Poker.GamePersistence.TableRecord

  @doc """
  Returns the list of table_records.

  ## Examples

      iex> list_table_records()
      [%TableRecord{}, ...]

  """
  def list_table_records do
    Repo.all(TableRecord)
  end

  @doc """
  Gets a single table_record.

  Raises `Ecto.NoResultsError` if the Table record does not exist.

  ## Examples

      iex> get_table_record!(123)
      %TableRecord{}

      iex> get_table_record!(456)
      ** (Ecto.NoResultsError)

  """
  def get_table_record!(id), do: Repo.get!(TableRecord, id)

  @doc """
  Finds a table record by name
  """
  def get_table_record_by_name(name), do: Repo.get_by(TableRecord, [name: name])

  @doc """
  Creates a table_record.

  ## Examples

      iex> create_table_record(%{field: value})
      {:ok, %TableRecord{}}

      iex> create_table_record(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_table_record(attrs \\ %{}) do
    %TableRecord{}
    |> TableRecord.changeset(attrs)
    |> Repo.insert(returning: true)
  end

  @doc """
  Updates a table_record.

  ## Examples

      iex> update_table_record(table_record, %{field: new_value})
      {:ok, %TableRecord{}}

      iex> update_table_record(table_record, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_table_record(%TableRecord{} = table_record, attrs) do
    table_record
    |> TableRecord.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a table_record.

  ## Examples

      iex> delete_table_record(table_record)
      {:ok, %TableRecord{}}

      iex> delete_table_record(table_record)
      {:error, %Ecto.Changeset{}}

  """
  def delete_table_record(%TableRecord{} = table_record) do
    Repo.delete(table_record)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking table_record changes.

  ## Examples

      iex> change_table_record(table_record)
      %Ecto.Changeset{data: %TableRecord{}}

  """
  def change_table_record(%TableRecord{} = table_record, attrs \\ %{}) do
    TableRecord.changeset(table_record, attrs)
  end
end
