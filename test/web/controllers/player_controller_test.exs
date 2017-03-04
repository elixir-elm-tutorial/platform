defmodule Platform.Web.PlayerControllerTest do
  use Platform.Web.ConnCase

  alias Platform.Players

  @create_attrs %{score: 42, username: "some username"}
  @update_attrs %{score: 43, username: "some updated username"}
  @invalid_attrs %{score: nil, username: nil}

  def fixture(:player) do
    {:ok, player} = Players.create_player(@create_attrs)
    player
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, player_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing Players"
  end

  test "renders form for new players", %{conn: conn} do
    conn = get conn, player_path(conn, :new)
    assert html_response(conn, 200) =~ "New Player"
  end

  test "creates player and redirects to show when data is valid", %{conn: conn} do
    conn = post conn, player_path(conn, :create), player: @create_attrs

    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == player_path(conn, :show, id)

    conn = get conn, player_path(conn, :show, id)
    assert html_response(conn, 200) =~ "Show Player"
  end

  test "does not create player and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, player_path(conn, :create), player: @invalid_attrs
    assert html_response(conn, 200) =~ "New Player"
  end

  test "renders form for editing chosen player", %{conn: conn} do
    player = fixture(:player)
    conn = get conn, player_path(conn, :edit, player)
    assert html_response(conn, 200) =~ "Edit Player"
  end

  test "updates chosen player and redirects when data is valid", %{conn: conn} do
    player = fixture(:player)
    conn = put conn, player_path(conn, :update, player), player: @update_attrs
    assert redirected_to(conn) == player_path(conn, :show, player)

    conn = get conn, player_path(conn, :show, player)
    assert html_response(conn, 200) =~ "some updated username"
  end

  test "does not update chosen player and renders errors when data is invalid", %{conn: conn} do
    player = fixture(:player)
    conn = put conn, player_path(conn, :update, player), player: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit Player"
  end

  test "deletes chosen player", %{conn: conn} do
    player = fixture(:player)
    conn = delete conn, player_path(conn, :delete, player)
    assert redirected_to(conn) == player_path(conn, :index)
    assert_error_sent 404, fn ->
      get conn, player_path(conn, :show, player)
    end
  end
end
