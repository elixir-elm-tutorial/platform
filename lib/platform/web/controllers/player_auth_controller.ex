defmodule Platform.Web.PlayerAuthController do
  import Plug.Conn

  def init(opts) do
    Keyword.fetch!(opts, :repo)
  end

  def call(conn, repo) do
    player_id = get_session(conn, :player_id)
    player = player_id && repo.get(Platform.Players.Player, player_id)
    assign(conn, :current_user, player)
  end

  def login(conn, player) do
    conn
    |> assign(:current_user, player)
    |> put_session(:player_id, player.id)
    |> configure_session(renew: true)
  end
end
