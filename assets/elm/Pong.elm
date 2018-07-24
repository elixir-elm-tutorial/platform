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


type alias Flags =
    { token : String
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


initialModel : Flags -> Model
initialModel flags =
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


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( initialModel flags, Cmd.none )



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
                    { model
                        | ball = updateBallPosition model dt model.ball
                        , players = updatePlayerScores model.ball model.players
                    }
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


updateBallPosition : Model -> Time -> Ball -> Ball
updateBallPosition model dt ball =
    let
        ballCollidedWithPlayerOne =
            (ball.positionX >= playerOne.positionX && ball.positionX <= playerOne.positionX + toFloat playerOne.sizeX)
                && (ball.positionY >= playerOne.positionY && ball.positionY <= playerOne.positionY + toFloat playerOne.sizeY)

        ballCollidedWithPlayerTwo =
            (ball.positionX >= playerTwo.positionX && ball.positionX <= playerTwo.positionX + toFloat playerTwo.sizeX)
                && (ball.positionY >= playerTwo.positionY && ball.positionY <= playerTwo.positionY + toFloat playerTwo.sizeY)

        defaultPlayer =
            { color = ""
            , id = 0
            , positionX = 0
            , positionY = 0
            , score = 0
            , sizeX = 0
            , sizeY = 0
            }

        height =
            toFloat gameWindowHeight

        offsetDistance =
            toFloat ball.size

        playerOne =
            model.players
                |> List.filter (\p -> p.id == 1)
                |> List.head
                |> Maybe.withDefault defaultPlayer

        playerTwo =
            model.players
                |> List.filter (\p -> p.id == 2)
                |> List.head
                |> Maybe.withDefault defaultPlayer

        width =
            toFloat gameWindowWidth
    in
        if ballCollidedWithPlayerOne then
            { ball
                | positionX = playerOne.positionX + toFloat playerOne.sizeX + 1
                , velocityX = abs ball.velocityX
            }
        else if ballCollidedWithPlayerTwo then
            { ball
                | positionX = playerTwo.positionX - 1
                , velocityX = -1.0 * ball.velocityX
            }
        else if ball.positionX >= width then
            { ball
                | positionX = width - offsetDistance
                , velocityX = -1.0 * ball.velocityX
            }
        else if ball.positionX <= 0 then
            { ball
                | positionX = 1.0
                , velocityX = abs ball.velocityX
            }
        else if ball.positionY >= 600.0 then
            { ball
                | positionY = height - offsetDistance
                , velocityY = -1.0 * ball.velocityY
            }
        else if ball.positionY <= 0 then
            { ball
                | positionY = 1.0
                , velocityY = abs ball.velocityY
            }
        else
            { ball
                | positionX = ball.positionX + ball.velocityX * dt
                , positionY = ball.positionY + ball.velocityY * dt
            }


updatePlayerPosition : Int -> Player -> Player
updatePlayerPosition keyCode player =
    let
        moveSpeed =
            5.0
    in
        case keyCode of
            38 ->
                { player | positionY = max (player.positionY - moveSpeed) 0 }

            40 ->
                { player | positionY = min (player.positionY + moveSpeed) (toFloat gameWindowHeight - toFloat player.sizeY) }

            _ ->
                player


updatePlayerScores : Ball -> List Player -> List Player
updatePlayerScores ball players =
    if ball.positionX >= 900.0 then
        List.map
            (\player ->
                if player.id == 1 then
                    updatePlayerScore player
                else
                    player
            )
            players
    else if ball.positionX <= 0 then
        List.map
            (\player ->
                if player.id == 2 then
                    updatePlayerScore player
                else
                    player
            )
            players
    else
        players


updatePlayerScore : Player -> Player
updatePlayerScore player =
    { player | score = player.score + 1 }



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
            , viewPlayerScore 1 180 80 model
            , viewPlayerScore 2 660 80 model
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


viewPlayerScore : Int -> Int -> Int -> Model -> Svg Msg
viewPlayerScore playerId positionX positionY model =
    let
        playerScore =
            model.players
                |> List.filter (\player -> player.id == playerId)
                |> List.map .score
                |> List.head
                |> Maybe.withDefault 0
    in
        svg [ fill "white" ]
            [ text_
                [ fontFamily "Courier"
                , fontSize "64"
                , fontWeight "bold"
                , x <| toString positionX
                , y <| toString positionY
                ]
                [ text <| toString playerScore ]
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


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
