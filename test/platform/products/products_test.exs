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
      assert {:ok, %Game{} = game} = Products.update_game(game, @update_attrs)
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

  describe "gameplays" do
    alias Platform.Products.Gameplay

    @valid_attrs %{player_score: 42}
    @update_attrs %{player_score: 43}
    @invalid_attrs %{player_score: nil}

    def gameplay_fixture(attrs \\ %{}) do
      {:ok, gameplay} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Products.create_gameplay()

      gameplay
    end

    test "list_gameplays/0 returns all gameplays" do
      gameplay = gameplay_fixture()
      assert Products.list_gameplays() == [gameplay]
    end

    test "get_gameplay!/1 returns the gameplay with given id" do
      gameplay = gameplay_fixture()
      assert Products.get_gameplay!(gameplay.id) == gameplay
    end

    test "create_gameplay/1 with valid data creates a gameplay" do
      assert {:ok, %Gameplay{} = gameplay} = Products.create_gameplay(@valid_attrs)
      assert gameplay.player_score == 42
    end

    test "create_gameplay/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Products.create_gameplay(@invalid_attrs)
    end

    test "update_gameplay/2 with valid data updates the gameplay" do
      gameplay = gameplay_fixture()
      assert {:ok, %Gameplay{} = gameplay} = Products.update_gameplay(gameplay, @update_attrs)
      assert gameplay.player_score == 43
    end

    test "update_gameplay/2 with invalid data returns error changeset" do
      gameplay = gameplay_fixture()
      assert {:error, %Ecto.Changeset{}} = Products.update_gameplay(gameplay, @invalid_attrs)
      assert gameplay == Products.get_gameplay!(gameplay.id)
    end

    test "delete_gameplay/1 deletes the gameplay" do
      gameplay = gameplay_fixture()
      assert {:ok, %Gameplay{}} = Products.delete_gameplay(gameplay)
      assert_raise Ecto.NoResultsError, fn -> Products.get_gameplay!(gameplay.id) end
    end

    test "change_gameplay/1 returns a gameplay changeset" do
      gameplay = gameplay_fixture()
      assert %Ecto.Changeset{} = Products.change_gameplay(gameplay)
    end
  end
end
