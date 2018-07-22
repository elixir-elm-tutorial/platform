module Pong exposing (..)

import AnimationFrame exposing (diffs)
import Html exposing (Html, div)
import Keyboard exposing (KeyCode, downs)
import Svg exposing (Svg, line, rect, svg, text, text_)
import Svg.Attributes exposing (color, fill, fontFamily, fontSize, fontWeight, height, stroke, strokeDasharray, strokeWidth, version, width, x, x1, x2, y, y1, y2)
import Time exposing (Time, every, second)


---- TYPES ----


type alias Ball =
    { color : String
    , id : Int
    , positionX : Float
    , positionY : Float
    , size : Int
    , velocityX : Float
    , velocityY : Float
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
    = GameLoop Time
    | MovePlayer KeyCode
    | NoOp
    | StartGame KeyCode



---- MODEL ----


initialBall : Ball
initialBall =
    { color = "white"
    , id = 1
    , positionX = 440
    , positionY = 290
    , size = 10
    , velocityX = 0.2
    , velocityY = 0.2
    }


initialModel : Model
initialModel =
    { ball = initialBall
    , errors = Nothing
    , gameState = StartScreen
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
    , positionY = (toFloat gameWindowHeight / 2 - distanceFromEdge)
    , score = 0
    , sizeX = 10
    , sizeY = 80
    }


initialPlayerTwo : Player
initialPlayerTwo =
    { color = "white"
    , id = 2
    , positionX = (toFloat gameWindowWidth - distanceFromEdge)
    , positionY = (toFloat gameWindowHeight / 2 - distanceFromEdge)
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
        GameLoop dt ->
            let
                updatedModel =
                    { model | ball = updateBallPosition model.ball dt }
            in
                ( updatedModel, Cmd.none )

        MovePlayer keyCode ->
            let
                updatedPlayers =
                    List.map (updatePlayerPosition keyCode) model.players
            in
                ( { model | players = updatedPlayers }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

        StartGame keyCode ->
            if model.gameState == StartScreen && keyCode == 32 then
                ( { model | gameState = Playing }, Cmd.none )
            else
                ( model, Cmd.none )


updateBallPosition : Ball -> Time -> Ball
updateBallPosition ball dt =
    let
        x =
            ball.positionX
    in
        if x > 800 then
            { ball | positionX = x + (1 * ball.velocityX) * dt }
        else if x < 0 then
            { ball | positionX = x + (abs ball.velocityX) * dt }
        else if x > 0 && x < 800 then
            { ball | positionX = x + (-1 * ball.velocityX) * dt }
        else
            ball


updatePlayerPosition : Int -> Player -> Player
updatePlayerPosition keyCode player =
    case keyCode of
        38 ->
            { player | positionY = player.positionY - 5 }

        40 ->
            { player | positionY = player.positionY + 5 }

        _ ->
            player



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ diffs GameLoop
        , downs MovePlayer
        , downs StartGame
        ]



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
            , viewPlayerOneScore model
            , viewPlayerTwoScore model
            , viewNet
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
        , x <| toString <| round ball.positionX
        , y <| toString <| round ball.positionY
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


viewPlayerOneScore : Model -> Svg Msg
viewPlayerOneScore model =
    svg [ fill "white" ]
        [ text_
            [ fontFamily "Courier"
            , fontSize "64"
            , fontWeight "bold"
            , x "180"
            , y "80"
            ]
            [ text "0" ]
        ]


viewPlayerTwoScore : Model -> Svg Msg
viewPlayerTwoScore model =
    svg [ fill "white" ]
        [ text_
            [ fontFamily "Courier"
            , fontSize "64"
            , fontWeight "bold"
            , x "660"
            , y "80"
            ]
            [ text "0" ]
        ]


viewNet : Svg Msg
viewNet =
    line
        [ x1 "445"
        , y1 "0"
        , x2 "445"
        , y2 "600"
        , stroke "white"
        , strokeDasharray "21"
        , strokeWidth "10"
        ]
        []



---- MAIN ----


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
