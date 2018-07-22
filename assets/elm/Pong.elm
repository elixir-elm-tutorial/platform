module Pong exposing (..)

import Html exposing (Html, div)
import Svg exposing (Svg, rect, svg, text, text_)
import Svg.Attributes exposing (color, fill, fontFamily, fontSize, fontWeight, height, version, width, x, y)


---- MODEL ----


type alias Ball =
    { color : String
    , id : Int
    , positionX : Float
    , positionY : Float
    , size : Int
    }


type GameState
    = StartScreen
    | Playing
    | EndScreen


type alias Player =
    { color : String
    , id : Int
    , positionX : Float
    , positionY : Float
    , score : Int
    , sizeX : Int
    , sizeY : Int
    }


type alias Model =
    { ball : Ball
    , errors : Maybe String
    , gameState : GameState
    , players : List Player
    }


type Msg
    = NoOp



---- INIT ----


initialBall : Ball
initialBall =
    { color = "white"
    , id = 1
    , positionX = 440
    , positionY = 290
    , size = 10
    }


initialModel : Model
initialModel =
    { ball = initialBall
    , errors = Nothing
    , gameState = Playing
    , players = initialPlayers
    }


initialPlayers : List Player
initialPlayers =
    [ initialPlayerOne, initialPlayerTwo ]


initialPlayerOne : Player
initialPlayerOne =
    { color = "white"
    , id = 1
    , positionX = distanceFromEdge
    , positionY = distanceFromEdge
    , score = 0
    , sizeX = 10
    , sizeY = 80
    }


initialPlayerTwo : Player
initialPlayerTwo =
    { color = "white"
    , id = 2
    , positionX = (toFloat gameWindowWidth - distanceFromEdge)
    , positionY = distanceFromEdge
    , score = 0
    , sizeX = 10
    , sizeY = 80
    }


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )



---- CONSTANTS ----


distanceFromEdge : Float
distanceFromEdge =
    40.0


gameWindowHeight : Int
gameWindowHeight =
    600


gameWindowWidth : Int
gameWindowWidth =
    900



---- UPDATE ----


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        _ ->
            ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ viewGame model
        ]


viewGame : Model -> Svg Msg
viewGame model =
    svg
        [ height (toString gameWindowHeight)
        , version "1.1"
        , width (toString gameWindowWidth)
        ]
        (viewGameState model)


viewGameState : Model -> List (Svg Msg)
viewGameState model =
    case model.gameState of
        StartScreen ->
            [ viewStartScreenText
            ]

        Playing ->
            [ viewPlayingState model
            , viewBall model
            ]
                ++ viewPlayers model

        EndScreen ->
            []


viewStartScreenText : Svg Msg
viewStartScreenText =
    svg []
        [ viewGameText 280 160 "Pong!"
        , viewGameText 140 180 "Press the SPACE BAR key to start."
        ]


viewGameText : Int -> Int -> String -> Svg Msg
viewGameText textPositionX textPositionY str =
    text_
        [ color "white"
        , fontFamily "Courier"
        , fontSize "16"
        , fontWeight "bold"
        , x (toString textPositionX)
        , y (toString textPositionY)
        ]
        [ text str ]


viewPlayingState : Model -> Svg Msg
viewPlayingState model =
    rect
        [ fill "black"
        , height (toString gameWindowHeight)
        , width (toString gameWindowWidth)
        ]
        []


viewBall : Model -> Svg Msg
viewBall { ball } =
    rect
        [ fill ball.color
        , height (toString ball.size)
        , width (toString ball.size)
        , x (toString ball.positionX)
        , y (toString ball.positionY)
        ]
        []


viewPlayers : Model -> List (Svg Msg)
viewPlayers { players } =
    List.map viewPlayer players


viewPlayer : Player -> Svg Msg
viewPlayer player =
    rect
        [ fill player.color
        , height (toString player.sizeY)
        , width (toString player.sizeX)
        , x (toString player.positionX)
        , y (toString player.positionY)
        ]
        []



---- MAIN ----


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }
