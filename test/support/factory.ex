defmodule Platform.Factory do
  use ExMachina.Ecto, repo: Platform.Repo

  def player_factory do
    %Platform.Accounts.Player{
      display_name: "José Valim",
      username: "josevalim",
      score: 0
    }
  end

  def game_factory do
    %Platform.Products.Game{
      description: "Platformer game example.",
      featured: true,
      slug: Enum.random(0..1000) |> Integer.to_string(),
      thumbnail: "https://i.imgur.com/L6ci0xL.png",
      title: "Platformer"
    }
  end

  def gameplay_factory do
    %Platform.Products.Gameplay{
      game_id: 1,
      player_id: 1,
      player_score: 1
    }
  end
end
