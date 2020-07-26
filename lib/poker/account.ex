defmodule Poker.Account do
  @moduledoc """
  The Account context.
  """

  import Ecto.Query, warn: false
  alias Poker.Repo

  alias Poker.Account.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a single user.

  ## Examples

      iex> get_user(123)
      %User{}

      iex> get_user(456)
      nil

  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Finds a user by name
  """
  def get_user_by_name(name), do: Repo.get_by(User, [name: name])

  @doc """
  Finds a user by the given parameters
  """
  def get_user_by(keywords), do: Repo.get_by(User, keywords)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Returns the account balance for the user.

  ## Examples

      iex> balance(user_id)
      10000

  """
  def balance(%User{} = user), do: balance(user.id)

  def balance(id) do
    Repo.one(
      from u in User,
        select: u.chips,
        where: u.id == ^id
    )
  end

  @doc """
  Subtracts from the account balance for the user.

  ## Examples

      iex> balance(user_id)
      10000

  """
  def subtract_balance(%User{} = user, amount), do: subtract_balance(user.id, amount)

  def subtract_balance(id, amount) do
    {1, _} =
      Repo.update_all(
        from(u in User,
          where: u.id == ^id,
          update: [set: [chips: u.chips - ^amount]]
        ),
        []
      )

    :ok
  end

  @doc """
  Adds chips to the account balance for the user.

  ## Examples

      iex> balance(user_id)
      10000

  """
  def add_balance(%User{} = user, amount), do: add_balance(user.id, amount)

  def add_balance(id, amount) do
    {1, _} =
      Repo.update_all(
        from(u in User,
          where: u.id == ^id,
          update: [set: [chips: u.chips + ^amount]]
        ),
        []
      )

    :ok
  end
end
