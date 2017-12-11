module Platformer exposing (..)

import AnimationFrame exposing (diffs)
import Html exposing (Html, button, div, h1, li, span, strong, ul)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Keyboard exposing (KeyCode, downs)
import Phoenix.Channel
import Phoenix.Push
import Phoenix.Socket
import Random
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Time exposing (Time, every, second)


-- MAIN


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type GameState
    = StartScreen
    | Playing
    | Success
    | GameOver


type alias Player =
    { displayName : Maybe String
    , id : Int
    , score : Int
    , username : String
    }


type alias Model =
    { errors : String
    , gameId : Int
    , gameState : GameState
    , characterPositionX : Int
    , characterPositionY : Int
    , itemPositionX : Int
    , itemPositionY : Int
    , itemsCollected : Int
    , phxSocket : Phoenix.Socket.Socket Msg
    , playersList : List Player
    , playerScore : Int
    , playerScores : List Score
    , timeRemaining : Int
    }


initialModel : Model
initialModel =
    { errors = ""
    , gameId = 1
    , gameState = StartScreen
    , characterPositionX = 50
    , characterPositionY = 300
    , itemPositionX = 150
    , itemPositionY = 300
    , itemsCollected = 0
    , phxSocket = initialSocketJoin
    , playersList = []
    , playerScore = 0
    , playerScores = []
    , timeRemaining = 10
    }


initialSocket : ( Phoenix.Socket.Socket Msg, Cmd (Phoenix.Socket.Msg Msg) )
initialSocket =
    let
        devSocketServer =
            "ws://localhost:4000/socket/websocket"
    in
        Phoenix.Socket.init devSocketServer
            |> Phoenix.Socket.withDebug
            |> Phoenix.Socket.on "shout" "score:platformer" SendScore
            |> Phoenix.Socket.on "save_score" "score:platformer" ReceiveScoreChanges
            |> Phoenix.Socket.join initialChannel


initialChannel : Phoenix.Channel.Channel msg
initialChannel =
    Phoenix.Channel.init "score:platformer"


initialSocketJoin : Phoenix.Socket.Socket Msg
initialSocketJoin =
    initialSocket
        |> Tuple.first


initialSocketCommand : Cmd (Phoenix.Socket.Msg Msg)
initialSocketCommand =
    initialSocket
        |> Tuple.second


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.map PhoenixMsg initialSocketCommand )



-- API


fetchPlayersList : Cmd Msg
fetchPlayersList =
    Http.get "/api/players" decodePlayersList
        |> Http.send FetchPlayersList


decodePlayersList : Decode.Decoder (List Player)
decodePlayersList =
    decodePlayer
        |> Decode.list
        |> Decode.at [ "data" ]


decodePlayer : Decode.Decoder Player
decodePlayer =
    Decode.map4 Player
        (Decode.maybe (Decode.field "display_name" Decode.string))
        (Decode.field "id" Decode.int)
        (Decode.field "score" Decode.int)
        (Decode.field "username" Decode.string)


type alias Score =
    { gameId : Int
    , playerId : Int
    , playerScore : Int
    }


scoreDecoder : Decode.Decoder Score
scoreDecoder =
    Decode.map3 Score
        (Decode.field "game_id" Decode.int)
        (Decode.field "player_id" Decode.int)
        (Decode.field "player_score" Decode.int)



-- UPDATE


type Msg
    = NoOp
    | CountdownTimer Time
    | FetchPlayersList (Result Http.Error (List Player))
    | KeyDown KeyCode
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | ReceiveScoreChanges Encode.Value
    | SaveScore Encode.Value
    | SaveScoreError Encode.Value
    | SaveScoreRequest
    | SendScore Encode.Value
    | SendScoreError Encode.Value
    | SendScoreRequest
    | SetNewItemPositionX Int
    | TimeUpdate Time


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        CountdownTimer time ->
            if model.gameState == Playing && model.timeRemaining > 0 then
                ( { model | timeRemaining = model.timeRemaining - 1 }, Cmd.none )
            else
                ( model, Cmd.none )

        FetchPlayersList result ->
            case result of
                Ok players ->
                    ( { model | playersList = players }, Cmd.none )

                Err message ->
                    ( { model | errors = toString message }, Cmd.none )

        KeyDown keyCode ->
            case keyCode of
                32 ->
                    if model.gameState /= Playing then
                        ( { model
                            | gameState = Playing
                            , characterPositionX = 50
                            , playerScore = 0
                            , itemsCollected = 0
                            , timeRemaining = 10
                          }
                        , Cmd.none
                        )
                    else
                        ( model, Cmd.none )

                37 ->
                    if model.gameState == Playing then
                        ( { model | characterPositionX = model.characterPositionX - 15 }, Cmd.none )
                    else
                        ( model, Cmd.none )

                39 ->
                    if model.gameState == Playing then
                        ( { model | characterPositionX = model.characterPositionX + 15 }, Cmd.none )
                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        PhoenixMsg msg ->
            let
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.update msg model.phxSocket
            in
                ( { model | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )

        ReceiveScoreChanges raw ->
            case Decode.decodeValue scoreDecoder raw of
                Ok scoreChange ->
                    ( { model | playerScores = scoreChange :: model.playerScores }, Cmd.none )

                Err message ->
                    ( { model | errors = message }, Cmd.none )

        SaveScore value ->
            ( model, Cmd.none )

        SaveScoreError message ->
            Debug.log "Error saveing score over socket."
                ( model, Cmd.none )

        SaveScoreRequest ->
            let
                payload =
                    Encode.object [ ( "player_score", Encode.int model.playerScore ) ]

                phxPush =
                    Phoenix.Push.init "save_score" "score:platformer"
                        |> Phoenix.Push.withPayload payload
                        |> Phoenix.Push.onOk SaveScore
                        |> Phoenix.Push.onError SaveScoreError

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.push phxPush model.phxSocket
            in
                ( { model | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )

        SendScore value ->
            ( model, Cmd.none )

        SendScoreError message ->
            Debug.log "Error sending score over socket."
                ( model, Cmd.none )

        SendScoreRequest ->
            let
                payload =
                    Encode.object [ ( "player_score", Encode.int model.playerScore ) ]

                phxPush =
                    Phoenix.Push.init "shout" "score:platformer"
                        |> Phoenix.Push.withPayload payload
                        |> Phoenix.Push.onOk SendScore
                        |> Phoenix.Push.onError SendScoreError

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.push phxPush model.phxSocket
            in
                ( { model | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )

        SetNewItemPositionX newPositionX ->
            ( { model | itemPositionX = newPositionX }, Cmd.none )

        TimeUpdate time ->
            if characterFoundItem model then
                ( { model
                    | itemsCollected = model.itemsCollected + 1
                    , playerScore = model.playerScore + 100
                  }
                , Random.generate SetNewItemPositionX (Random.int 50 500)
                )
            else if model.itemsCollected >= 10 then
                ( { model | gameState = Success }, Cmd.none )
            else if model.itemsCollected < 10 && model.timeRemaining == 0 then
                ( { model | gameState = GameOver }, Cmd.none )
            else
                ( model, Cmd.none )


characterFoundItem : Model -> Bool
characterFoundItem model =
    let
        approximateItemLowerBound =
            model.itemPositionX - 35

        approximateItemUpperBound =
            model.itemPositionX

        approximateItemRange =
            List.range approximateItemLowerBound approximateItemUpperBound
    in
        List.member model.characterPositionX approximateItemRange



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ downs KeyDown
        , diffs TimeUpdate
        , every second CountdownTimer
        , Phoenix.Socket.listen model.phxSocket PhoenixMsg
        ]



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ viewGame model
        , viewSendScoreButton
        , viewSaveScoreButton
        , viewPlayerScoresIndex model
        ]


viewSendScoreButton : Html Msg
viewSendScoreButton =
    div []
        [ button
            [ onClick SendScoreRequest
            , Html.Attributes.class "btn btn-primary"
            ]
            [ text "Send Score" ]
        ]


viewSaveScoreButton : Html Msg
viewSaveScoreButton =
    div []
        [ button
            [ onClick SaveScoreRequest
            , Html.Attributes.class "btn btn-primary"
            ]
            [ text "Save Score" ]
        ]


viewPlayerScoresIndex : Model -> Html Msg
viewPlayerScoresIndex model =
    if List.isEmpty model.playerScores then
        div [] []
    else
        div [ Html.Attributes.class "players-index" ]
            [ h1 [ Html.Attributes.class "players-section" ] [ text "Player Scores" ]
            , viewPlayerScoresList model.playerScores
            ]


viewPlayerScoresList : List Score -> Html Msg
viewPlayerScoresList scores =
    div [ Html.Attributes.class "players-list panel panel-info" ]
        [ div [ Html.Attributes.class "panel-heading" ] [ text "Leaderboard" ]
        , ul [ Html.Attributes.class "list-group" ] (List.map viewPlayerScoreItem scores)
        ]


viewPlayerScoreItem : Score -> Html Msg
viewPlayerScoreItem score =
    li [ Html.Attributes.class "player-item list-group-item" ]
        [ strong [] [ text (toString score.playerId) ]
        , span [ Html.Attributes.class "badge" ] [ text (toString score.playerScore) ]
        ]


viewGame : Model -> Svg Msg
viewGame model =
    svg [ version "1.1", width "600", height "400" ]
        (viewGameState model)


viewGameState : Model -> List (Svg Msg)
viewGameState model =
    case model.gameState of
        StartScreen ->
            [ viewGameWindow
            , viewGameSky
            , viewGameGround
            , viewCharacter model
            , viewItem model
            , viewStartScreenText
            ]

        Playing ->
            [ viewGameWindow
            , viewGameSky
            , viewGameGround
            , viewCharacter model
            , viewItem model
            , viewGameScore model
            , viewItemsCollected model
            , viewGameTime model
            ]

        Success ->
            [ viewGameWindow
            , viewGameSky
            , viewGameGround
            , viewCharacter model
            , viewItem model
            , viewSuccessScreenText
            ]

        GameOver ->
            [ viewGameWindow
            , viewGameSky
            , viewGameGround
            , viewCharacter model
            , viewItem model
            , viewGameOverScreenText
            ]


viewStartScreenText : Svg Msg
viewStartScreenText =
    Svg.svg []
        [ viewGameText 140 160 "Collect ten coins in ten seconds!"
        , viewGameText 140 180 "Press the SPACE BAR key to start."
        ]


viewSuccessScreenText : Svg Msg
viewSuccessScreenText =
    Svg.svg []
        [ viewGameText 260 160 "Success!"
        , viewGameText 140 180 "Press the SPACE BAR key to restart."
        ]


viewGameOverScreenText : Svg Msg
viewGameOverScreenText =
    Svg.svg []
        [ viewGameText 260 160 "Game Over"
        , viewGameText 140 180 "Press the SPACE BAR key to restart."
        ]


viewGameWindow : Svg Msg
viewGameWindow =
    rect
        [ width "600"
        , height "400"
        , fill "none"
        , stroke "black"
        ]
        []


viewGameSky : Svg Msg
viewGameSky =
    rect
        [ x "0"
        , y "0"
        , width "600"
        , height "300"
        , fill "#4b7cfb"
        ]
        []


viewGameGround : Svg Msg
viewGameGround =
    rect
        [ x "0"
        , y "300"
        , width "600"
        , height "100"
        , fill "green"
        ]
        []


viewCharacter : Model -> Svg Msg
viewCharacter model =
    image
        [ xlinkHref "/images/character.gif"
        , x (toString model.characterPositionX)
        , y (toString model.characterPositionY)
        , width "50"
        , height "50"
        ]
        []


viewItem : Model -> Svg Msg
viewItem model =
    image
        [ xlinkHref "/images/coin.svg"
        , x (toString model.itemPositionX)
        , y (toString model.itemPositionY)
        , width "20"
        , height "20"
        ]
        []


viewGameText : Int -> Int -> String -> Svg Msg
viewGameText positionX positionY str =
    Svg.text_
        [ x (toString positionX)
        , y (toString positionY)
        , fontFamily "Courier"
        , fontWeight "bold"
        , fontSize "16"
        ]
        [ Svg.text str ]


viewGameScore : Model -> Svg Msg
viewGameScore model =
    let
        currentScore =
            model.playerScore
                |> toString
                |> String.padLeft 5 '0'
    in
        Svg.svg []
            [ viewGameText 25 25 "SCORE"
            , viewGameText 25 40 currentScore
            ]


viewItemsCollected : Model -> Svg Msg
viewItemsCollected model =
    let
        currentItemCount =
            model.itemsCollected
                |> toString
                |> String.padLeft 3 '0'
    in
        Svg.svg []
            [ image
                [ xlinkHref "/images/coin.svg"
                , x "275"
                , y "18"
                , width "15"
                , height "15"
                ]
                []
            , viewGameText 300 30 ("x " ++ currentItemCount)
            ]


viewGameTime : Model -> Svg Msg
viewGameTime model =
    let
        currentTime =
            model.timeRemaining
                |> toString
                |> String.padLeft 4 '0'
    in
        Svg.svg []
            [ viewGameText 525 25 "TIME"
            , viewGameText 525 40 currentTime
            ]
