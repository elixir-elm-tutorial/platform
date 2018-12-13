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

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"

// Elm
import { Elm } from "../elm/src/Main.elm";

const elmContainer = document.querySelector("#elm-container");
const platformer = document.querySelector("#platformer");

if (elmContainer) {
  Elm.Main.init({ node: elmContainer });
}
if (platformer) {
  Elm.Games.Platformer.init({ node: platformer });
}
