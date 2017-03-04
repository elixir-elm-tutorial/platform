defmodule Platform.PlayersTest do
  use Platform.DataCase

  alias Platform.Players
  alias Platform.Players.Player

  @create_attrs %{score: 42, username: "some username"}
  @update_attrs %{score: 43, username: "some updated username"}
  @invalid_attrs %{score: nil, username: nil}

  def fixture(:player, attrs \\ @create_attrs) do
    {:ok, player} = Players.create_player(attrs)
    player
  end

  test "list_players/1 returns all players" do
    player = fixture(:player)
    assert Players.list_players() == [player]
  end

  test "get_player! returns the player with given id" do
    player = fixture(:player)
    assert Players.get_player!(player.id) == player
  end

  test "create_player/1 with valid data creates a player" do
    assert {:ok, %Player{} = player} = Players.create_player(@create_attrs)
    
    assert player.score == 42
    assert player.username == "some username"
  end

  test "create_player/1 with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = Players.create_player(@invalid_attrs)
  end

  test "update_player/2 with valid data updates the player" do
    player = fixture(:player)
    assert {:ok, player} = Players.update_player(player, @update_attrs)
    assert %Player{} = player
    
    assert player.score == 43
    assert player.username == "some updated username"
  end

  test "update_player/2 with invalid data returns error changeset" do
    player = fixture(:player)
    assert {:error, %Ecto.Changeset{}} = Players.update_player(player, @invalid_attrs)
    assert player == Players.get_player!(player.id)
  end

  test "delete_player/1 deletes the player" do
    player = fixture(:player)
    assert {:ok, %Player{}} = Players.delete_player(player)
    assert_raise Ecto.NoResultsError, fn -> Players.get_player!(player.id) end
  end

  test "change_player/1 returns a player changeset" do
    player = fixture(:player)
    assert %Ecto.Changeset{} = Players.change_player(player)
  end
end
