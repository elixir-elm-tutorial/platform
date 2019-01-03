// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

// Phoenix Socket
import { Socket } from "phoenix"

let socketParams = (window.userToken == "") ? {} : { token: window.userToken };

let socket = new Socket("/socket", {
  params: socketParams
})

socket.connect()

// Elm
import { Elm } from "../elm/src/Main.elm";

const elmContainer = document.querySelector("#elm-container");
const platformer = document.querySelector("#platformer");

if (elmContainer) {
  Elm.Main.init({ node: elmContainer });
}
if (platformer) {
  let app = Elm.Games.Platformer.init({ node: platformer });

  let channel = socket.channel("score:platformer", {})

  channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })

  app.ports.broadcastScore.subscribe(function (scoreData) {
    console.log(`Broadcasting ${scoreData} score data from Elm using the broadcastScore port.`);
    channel.push("broadcast_score", { player_score: scoreData });
  });

  channel.on("broadcast_score", payload => {
    console.log(`Receiving payload data from Phoenix using the receivingScoreFromPhoenix port.`);

    app.ports.receiveScoreFromPhoenix.send({
      game_id: payload.game_id || 0,
      player_id: payload.player_id || 0,
      player_score: payload.player_score || 0
    });
  });
}
