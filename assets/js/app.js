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
  let app = Elm.Games.Platformer.init({
    node: platformer,
    flags: { token: window.userToken }
  });

  let channel = socket.channel("score:platformer", {})

  channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })

  app.ports.broadcastScore.subscribe(function (scoreData) {
    console.log(`Broadcasting ${scoreData} score data from Elm using the broadcastScore port.`);
    channel.push("broadcast_score", { player_score: scoreData });
  });

  app.ports.saveScore.subscribe(function (scoreData) {
    console.log(`Saving ${scoreData} score data from Elm using the saveScore port.`);
    channel.push("save_score", { player_score: scoreData });
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

// Disable default space bar and arrow keys in favor of game interactions
document.documentElement.addEventListener(
  "keydown",
  function (e) {
    let spaceBarKeyCode = 32;
    let upArrowKeyCode = 38;
    let downArrowKeyCode = 40;

    if (
      (e.keycode || e.which) == spaceBarKeyCode ||
      (e.keycode || e.which) == upArrowKeyCode ||
      (e.keycode || e.which) == downArrowKeyCode
    ) {
      e.preventDefault();
    }
  },
  false
);
