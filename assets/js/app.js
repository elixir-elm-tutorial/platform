// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html";

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"

// Elm
import Elm from "./elm";

const elmContainer = document.querySelector("#elm-container");
const platformer = document.querySelector("#platformer");
const pong = document.querySelector("#pong");

function socketProtocol() {
  if (window.location.protocol == "https:") {
    return "wss:";
  } else {
    return "ws:";
  }
}

const context = {
  host: window.location.host,
  httpProtocol: window.location.protocol,
  socketServer:
    socketProtocol() + "//" + window.location.host + "/socket/websocket",
  userToken: window.userToken
};

if (elmContainer) Elm.Main.embed(elmContainer);
if (platformer) Elm.Platformer.embed(platformer, context);
if (pong) Elm.Pong.embed(pong, context);

// Disable default space bar and arrow keys in favor of game interactions
document.documentElement.addEventListener(
  "keydown",
  function(e) {
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
