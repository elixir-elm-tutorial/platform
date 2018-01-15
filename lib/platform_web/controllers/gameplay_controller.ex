defmodule PlatformWeb.GameplayController do
  use PlatformWeb, :controller

  alias Platform.Products
  alias Platform.Products.Gameplay

  action_fallback PlatformWeb.FallbackController

  def index(conn, _params) do
    gameplays = Products.list_gameplays()
    render(conn, "index.json", gameplays: gameplays)
  end

  def create(conn, %{"gameplay" => gameplay_params}) do
    with {:ok, %Gameplay{} = gameplay} <- Products.create_gameplay(gameplay_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", gameplay_path(conn, :show, gameplay))
      |> render("show.json", gameplay: gameplay)
    end
  end

  def show(conn, %{"id" => id}) do
    gameplay = Products.get_gameplay!(id)
    render(conn, "show.json", gameplay: gameplay)
  end

  def update(conn, %{"id" => id, "gameplay" => gameplay_params}) do
    gameplay = Products.get_gameplay!(id)

    with {:ok, %Gameplay{} = gameplay} <- Products.update_gameplay(gameplay, gameplay_params) do
      render(conn, "show.json", gameplay: gameplay)
    end
  end

  def delete(conn, %{"id" => id}) do
    gameplay = Products.get_gameplay!(id)
    with {:ok, %Gameplay{}} <- Products.delete_gameplay(gameplay) do
      send_resp(conn, :no_content, "")
    end
  end
end
