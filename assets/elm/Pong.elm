module Pong exposing (..)

import AnimationFrame exposing (diffs)
import Html exposing (Html, div, h1, li, span, strong, ul)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Keyboard exposing (KeyCode, downs)
import Phoenix.Channel as Channel
import Phoenix.Push as Push
import Phoenix.Socket as Socket
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


type alias Context =
    { host : String
    , httpProtocol : String
    , socketServer : String
    , userToken : String
    }


type alias Gameplay =
    { gameId : Int
    , playerId : Int
    , playerScore : Int
    }


type alias GamePlayer =
    { displayName : Maybe String
    , id : Int
    , score : Int
    , username : String
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
    , gameplays : List Gameplay
    , gamePlayers : List GamePlayer
    , gameState : GameState
    , phxSocket : Socket.Socket Msg
    , players : List Player
    }


type Msg
    = FetchGameplaysList (Result Http.Error (List Gameplay))
    | FetchPlayersList (Result Http.Error (List GamePlayer))
    | GameLoop Time
    | MovePlayerOne KeyCode
    | NoOp
    | PhoenixMsg (Socket.Msg Msg)
    | ReceiveBallPositionUpdate Encode.Value
    | ReceivePaddlePositionUpdate Encode.Value
    | StartGame KeyCode
    | UpdateBallPositionError Encode.Value
    | UpdateBallPositionRequest
    | UpdateBallPositionSuccess Encode.Value
    | UpdatePaddlePositionError Encode.Value
    | UpdatePaddlePositionSuccess Encode.Value



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


initialChannel : Channel.Channel msg
initialChannel =
    Channel.init "game:pong"


initialModel : Context -> Model
initialModel context =
    { ball = initialBall
    , errors = Nothing
    , gameplays = []
    , gamePlayers = []
    , gameState = StartScreen
    , phxSocket = initialSocketJoin context
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


initialSocket : Context -> ( Socket.Socket Msg, Cmd (Socket.Msg Msg) )
initialSocket context =
    let
        socketServer =
            if String.isEmpty context.userToken then
                context.socketServer
            else
                context.socketServer
                    ++ "?token="
                    ++ context.userToken
    in
        Socket.init socketServer
            |> Socket.withDebug
            |> Socket.on "ball:position_x" "game:pong" UpdateBallPositionSuccess
            |> Socket.on "ball:position_x" "game:pong" ReceiveBallPositionUpdate
            |> Socket.on "paddle:position_y" "game:pong" UpdatePaddlePositionSuccess
            |> Socket.on "paddle:position_y" "game:pong" ReceivePaddlePositionUpdate
            |> Socket.join initialChannel


initialSocketJoin : Context -> Socket.Socket Msg
initialSocketJoin context =
    initialSocket context
        |> Tuple.first


initialSocketCommand : Context -> Cmd (Socket.Msg Msg)
initialSocketCommand context =
    initialSocket context
        |> Tuple.second


initialCommand : Context -> Cmd Msg
initialCommand context =
    Cmd.batch
        [ fetchPlayersList
        , fetchGameplaysList
        , Cmd.map PhoenixMsg (initialSocketCommand context)
        ]


init : Context -> ( Model, Cmd Msg )
init context =
    ( initialModel context, initialCommand context )



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



---- API ----


fetchPlayersList : Cmd Msg
fetchPlayersList =
    Http.get "/api/players" decodePlayersList
        |> Http.send FetchPlayersList


decodePlayersList : Decode.Decoder (List GamePlayer)
decodePlayersList =
    decodePlayer
        |> Decode.list
        |> Decode.at [ "data" ]


decodePlayer : Decode.Decoder GamePlayer
decodePlayer =
    Decode.map4 GamePlayer
        (Decode.maybe (Decode.field "display_name" Decode.string))
        (Decode.field "id" Decode.int)
        (Decode.field "score" Decode.int)
        (Decode.field "username" Decode.string)


fetchGameplaysList : Cmd Msg
fetchGameplaysList =
    Http.get "/api/gameplays" decodeGameplaysList
        |> Http.send FetchGameplaysList


decodeGameplaysList : Decode.Decoder (List Gameplay)
decodeGameplaysList =
    decodeGameplay
        |> Decode.list
        |> Decode.at [ "data" ]


decodeGameplay : Decode.Decoder Gameplay
decodeGameplay =
    Decode.map3 Gameplay
        (Decode.field "game_id" Decode.int)
        (Decode.field "player_id" Decode.int)
        (Decode.field "player_score" Decode.int)


decodeBallPosition : Decode.Decoder Float
decodeBallPosition =
    Decode.field "ball_position_x" Decode.float


decodePaddlePosition : Decode.Decoder Float
decodePaddlePosition =
    Decode.field "paddle_position_y" Decode.float


anonymousPlayer : GamePlayer
anonymousPlayer =
    { displayName = Just "Anonymous User"
    , id = 0
    , score = 0
    , username = "anonymous"
    }



---- UPDATE ----


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchGameplaysList result ->
            case result of
                Ok gameplays ->
                    ( { model | gameplays = gameplays }, Cmd.none )

                Err message ->
                    ( { model | errors = Just <| toString message }, Cmd.none )

        FetchPlayersList result ->
            case result of
                Ok players ->
                    ( { model | gamePlayers = players }, Cmd.none )

                Err message ->
                    ( { model | errors = Just <| toString message }, Cmd.none )

        GameLoop dt ->
            let
                updatedModel =
                    { model
                        | ball = updateBallPosition model dt model.ball
                        , players = updatePlayerScores model.ball model.players
                    }
            in
                ( updatedModel, Cmd.none )

        MovePlayerOne keyCode ->
            let
                payload =
                    Encode.object [ ( "paddle_position_y", Encode.float <| (updatePlayerPosition keyCode playerOne).positionY ) ]

                phxPush =
                    Push.init "paddle:position_y" "game:pong"
                        |> Push.withPayload payload
                        |> Push.onOk UpdatePaddlePositionSuccess
                        |> Push.onError UpdatePaddlePositionError

                ( phxSocket, phxCmd ) =
                    Socket.push phxPush model.phxSocket

                defaultPlayer =
                    { color = ""
                    , id = 0
                    , positionX = 0
                    , positionY = 0
                    , score = 0
                    , sizeX = 0
                    , sizeY = 0
                    }

                playerOne =
                    model.players
                        |> List.filter (\p -> p.id == 1)
                        |> List.head
                        |> Maybe.withDefault defaultPlayer

                updatedPlayers =
                    List.map (updatePlayerPosition keyCode) model.players
            in
                ( { model
                    | phxSocket = phxSocket
                    , players = updatedPlayers
                  }
                , Cmd.map PhoenixMsg phxCmd
                )

        NoOp ->
            ( model, Cmd.none )

        PhoenixMsg msg ->
            let
                ( phxSocket, phxCmd ) =
                    Socket.update msg model.phxSocket
            in
                ( { model | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )

        ReceiveBallPositionUpdate raw ->
            case Decode.decodeValue decodeBallPosition raw of
                Ok ballPositionChange ->
                    let
                        ball =
                            model.ball

                        newBall =
                            { ball | positionX = 1 }
                    in
                        ( { model | ball = newBall }, Cmd.none )

                Err message ->
                    ( { model | errors = Just message }, Cmd.none )

        ReceivePaddlePositionUpdate raw ->
            case Decode.decodeValue decodePaddlePosition raw of
                Ok paddlePositionChange ->
                    let
                        defaultPlayer =
                            { color = ""
                            , id = 0
                            , positionX = 0
                            , positionY = 0
                            , score = 0
                            , sizeX = 0
                            , sizeY = 0
                            }

                        playerOne =
                            model.players
                                |> List.filter (\p -> p.id == 1)
                                |> List.head
                                |> Maybe.withDefault defaultPlayer

                        updatedPlayers =
                            List.map
                                (\p ->
                                    if p.id == playerOne.id then
                                        { p | positionY = paddlePositionChange }
                                    else
                                        p
                                )
                                model.players
                    in
                        ( { model | players = updatedPlayers }, Cmd.none )

                Err message ->
                    ( { model | errors = Just message }, Cmd.none )

        StartGame keyCode ->
            if model.gameState == StartScreen && keyCode == 32 then
                ( { model | gameState = Playing }, Cmd.none )
            else
                ( model, Cmd.none )

        UpdateBallPositionError message ->
            Debug.log "Error sending ball position over socket."
                ( model, Cmd.none )

        UpdateBallPositionRequest ->
            let
                payload =
                    Encode.object [ ( "ball_position_x", Encode.float model.ball.positionX ) ]

                phxPush =
                    Push.init "ball:position_x" "game:pong"
                        |> Push.withPayload payload
                        |> Push.onOk UpdateBallPositionSuccess
                        |> Push.onError UpdateBallPositionError

                ( phxSocket, phxCmd ) =
                    Socket.push phxPush model.phxSocket
            in
                ( { model | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )

        UpdateBallPositionSuccess value ->
            Debug.log "Success sending ball position over socket."
                ( model, Cmd.none )

        UpdatePaddlePositionError message ->
            Debug.log "Error sending paddle position over socket."
                ( model, Cmd.none )

        UpdatePaddlePositionSuccess value ->
            Debug.log "Success sending paddle position over socket."
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
        if player.id == 1 then
            case keyCode of
                38 ->
                    { player | positionY = max (player.positionY - moveSpeed) 0 }

                40 ->
                    { player | positionY = min (player.positionY + moveSpeed) (toFloat gameWindowHeight - toFloat player.sizeY) }

                _ ->
                    player
        else
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
        , downs MovePlayerOne
        , downs StartGame
        , Socket.listen model.phxSocket PhoenixMsg
        ]



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ viewGame model
        , viewGameplaysIndex model
        ]


viewGame : Model -> Svg Msg
viewGame model =
    svg
        [ height (toString gameWindowHeight)
        , onClick UpdateBallPositionRequest
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


viewGameplaysIndex : Model -> Html Msg
viewGameplaysIndex model =
    if List.isEmpty model.gameplays then
        div [] []
    else
        div [ Html.Attributes.class "players-index" ]
            [ h1 [ Html.Attributes.class "players-section" ] [ text "Player Scores" ]
            , viewGameplaysList model
            ]


viewGameplaysList : Model -> Html Msg
viewGameplaysList model =
    div [ Html.Attributes.class "players-list panel panel-info" ]
        [ div [ Html.Attributes.class "panel-heading" ] [ text "Scores" ]
        , ul [ Html.Attributes.class "list-group" ] (List.map (viewGameplayItem model) model.gameplays)
        ]


viewGameplayItem : Model -> Gameplay -> Html Msg
viewGameplayItem model gameplay =
    let
        currentPlayer =
            model.gamePlayers
                |> List.filter (\player -> player.id == gameplay.playerId)
                |> List.head
                |> Maybe.withDefault anonymousPlayer

        displayName =
            Maybe.withDefault currentPlayer.username currentPlayer.displayName
    in
        li [ Html.Attributes.class "player-item list-group-item" ]
            [ strong [] [ text displayName ]
            , span [ Html.Attributes.class "badge" ] [ text (toString gameplay.playerScore) ]
            ]



---- MAIN ----


main : Program Context Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
