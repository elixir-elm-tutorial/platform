defmodule PlatformWeb.GameplayView do
  use PlatformWeb, :view
  alias PlatformWeb.GameplayView

  def render("index.json", %{gameplays: gameplays}) do
    %{data: render_many(gameplays, GameplayView, "gameplay.json")}
  end

  def render("show.json", %{gameplay: gameplay}) do
    %{data: render_one(gameplay, GameplayView, "gameplay.json")}
  end

  def render("gameplay.json", %{gameplay: gameplay}) do
    %{id: gameplay.id,
      player_score: gameplay.player_score}
  end
end
