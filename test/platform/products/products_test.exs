defmodule Platform.ProductsTest do
  use Platform.DataCase

  alias Platform.Products

  describe "games" do
    alias Platform.Products.Game

    @valid_attrs %{description: "some description", featured: true, thumbnail: "some thumbnail", title: "some title"}
    @update_attrs %{description: "some updated description", featured: false, thumbnail: "some updated thumbnail", title: "some updated title"}
    @invalid_attrs %{description: nil, featured: nil, thumbnail: nil, title: nil}

    def game_fixture(attrs \\ %{}) do
      {:ok, game} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Products.create_game()

      game
    end

    test "list_games/0 returns all games" do
      game = game_fixture()
      assert Products.list_games() == [game]
    end

    test "get_game!/1 returns the game with given id" do
      game = game_fixture()
      assert Products.get_game!(game.id) == game
    end

    test "create_game/1 with valid data creates a game" do
      assert {:ok, %Game{} = game} = Products.create_game(@valid_attrs)
      assert game.description == "some description"
      assert game.featured == true
      assert game.thumbnail == "some thumbnail"
      assert game.title == "some title"
    end

    test "create_game/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Products.create_game(@invalid_attrs)
    end

    test "update_game/2 with valid data updates the game" do
      game = game_fixture()
      assert {:ok, game} = Products.update_game(game, @update_attrs)
      assert %Game{} = game
      assert game.description == "some updated description"
      assert game.featured == false
      assert game.thumbnail == "some updated thumbnail"
      assert game.title == "some updated title"
    end

    test "update_game/2 with invalid data returns error changeset" do
      game = game_fixture()
      assert {:error, %Ecto.Changeset{}} = Products.update_game(game, @invalid_attrs)
      assert game == Products.get_game!(game.id)
    end

    test "delete_game/1 deletes the game" do
      game = game_fixture()
      assert {:ok, %Game{}} = Products.delete_game(game)
      assert_raise Ecto.NoResultsError, fn -> Products.get_game!(game.id) end
    end

    test "change_game/1 returns a game changeset" do
      game = game_fixture()
      assert %Ecto.Changeset{} = Products.change_game(game)
    end
  end
end
