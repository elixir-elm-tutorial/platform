defmodule Platform.Products do
  @moduledoc """
  The Products context.
  """

  import Ecto.Query, warn: false
  alias Platform.Repo

  alias Platform.Products.Game

  @doc """
  Returns the list of games.

  ## Examples

      iex> list_games()
      [%Game{}, ...]

  """
  def list_games do
    Repo.all(Game)
  end

  @doc """
  Gets a single game.

  Raises `Ecto.NoResultsError` if the Game does not exist.

  ## Examples

      iex> get_game!(123)
      %Game{}

      iex> get_game!(456)
      ** (Ecto.NoResultsError)

  """
  def get_game!(id), do: Repo.get!(Game, id)
  def get_game_by_slug!(slug), do: Repo.get_by!(Game, slug: slug)

  @doc """
  Creates a game.

  ## Examples

      iex> create_game(%{field: value})
      {:ok, %Game{}}

      iex> create_game(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a game.

  ## Examples

      iex> update_game(game, %{field: new_value})
      {:ok, %Game{}}

      iex> update_game(game, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_game(%Game{} = game, attrs) do
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Game.

  ## Examples

      iex> delete_game(game)
      {:ok, %Game{}}

      iex> delete_game(game)
      {:error, %Ecto.Changeset{}}

  """
  def delete_game(%Game{} = game) do
    Repo.delete(game)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game changes.

  ## Examples

      iex> change_game(game)
      %Ecto.Changeset{source: %Game{}}

  """
  def change_game(%Game{} = game) do
    Game.changeset(game, %{})
  end

  alias Platform.Products.Gameplay

  @doc """
  Returns the list of gameplays.

  ## Examples

      iex> list_gameplays()
      [%Gameplay{}, ...]

  """
  def list_gameplays do
    Repo.all(Gameplay)
  end

  @doc """
  Gets a single gameplay.

  Raises `Ecto.NoResultsError` if the Gameplay does not exist.

  ## Examples

      iex> get_gameplay!(123)
      %Gameplay{}

      iex> get_gameplay!(456)
      ** (Ecto.NoResultsError)

  """
  def get_gameplay!(id), do: Repo.get!(Gameplay, id)

  @doc """
  Creates a gameplay.

  ## Examples

      iex> create_gameplay(%{field: value})
      {:ok, %Gameplay{}}

      iex> create_gameplay(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_gameplay(attrs \\ %{}) do
    %Gameplay{}
    |> Gameplay.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a gameplay.

  ## Examples

      iex> update_gameplay(gameplay, %{field: new_value})
      {:ok, %Gameplay{}}

      iex> update_gameplay(gameplay, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_gameplay(%Gameplay{} = gameplay, attrs) do
    gameplay
    |> Gameplay.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Gameplay.

  ## Examples

      iex> delete_gameplay(gameplay)
      {:ok, %Gameplay{}}

      iex> delete_gameplay(gameplay)
      {:error, %Ecto.Changeset{}}

  """
  def delete_gameplay(%Gameplay{} = gameplay) do
    Repo.delete(gameplay)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking gameplay changes.

  ## Examples

      iex> change_gameplay(gameplay)
      %Ecto.Changeset{source: %Gameplay{}}

  """
  def change_gameplay(%Gameplay{} = gameplay) do
    Gameplay.changeset(gameplay, %{})
  end
end
