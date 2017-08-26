# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Platform.Repo.insert!(%Platform.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Players

Platform.Repo.insert!(%Platform.Accounts.Player{display_name: "José Valim", username: "josevalim", score: 1000})
Platform.Repo.insert!(%Platform.Accounts.Player{display_name: "Evan Czaplicki", username: "evancz", score: 2000})
Platform.Repo.insert!(%Platform.Accounts.Player{display_name: "Chris McCord", username: "chrismccord", score: 3000})

# Games

Platform.Repo.insert!(%Platform.Products.Game{title: "Platformer", description: "Platform game example.", thumbnail: "http://via.placeholder.com/300x200", featured: true})
