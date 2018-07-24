module Platformer exposing (..)

import AnimationFrame exposing (diffs)
import Html exposing (Html, button, div, h1, li, span, strong, ul)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Keyboard exposing (KeyCode, downs, ups)
import Phoenix.Channel
import Phoenix.Push
import Phoenix.Socket
import Random
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Time exposing (Time, every, second)


-- MAIN


type alias Flags =
    { token : String
    }


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type Direction
    = Left
    | Right


type GameState
    = StartScreen
    | Playing
    | Success
    | GameOver


type alias Gameplay =
    { gameId : Int
    , playerId : Int
    , playerScore : Int
    }


type alias Player =
    { displayName : Maybe String
    , id : Int
    , score : Int
    , username : String
    }


type alias Model =
    { characterDirection : Direction
    , characterPositionX : Float
    , characterPositionY : Float
    , characterVelocityX : Float
    , characterVelocityY : Float
    , errors : String
    , gameId : Int
    , gameplays : List Gameplay
    , gameState : GameState
    , itemPositionX : Float
    , itemPositionY : Float
    , itemsCollected : Int
    , phxSocket : Phoenix.Socket.Socket Msg
    , playersList : List Player
    , playerScore : Int
    , timeRemaining : Int
    }


initialModel : Flags -> Model
initialModel flags =
    { characterDirection = Right
    , characterPositionX = 50.0
    , characterPositionY = 300.0
    , characterVelocityX = 0.0
    , characterVelocityY = 0.0
    , errors = ""
    , gameId = 1
    , gameplays = []
    , gameState = StartScreen
    , itemPositionX = 150.0
    , itemPositionY = 300.0
    , itemsCollected = 0
    , phxSocket = initialSocketJoin flags
    , playersList = []
    , playerScore = 0
    , timeRemaining = 10
    }


initialSocket : Flags -> ( Phoenix.Socket.Socket Msg, Cmd (Phoenix.Socket.Msg Msg) )
initialSocket flags =
    let
        devSocketServer =
            if String.isEmpty flags.token then
                "ws://localhost:4000/socket/websocket"
            else
                "ws://localhost:4000/socket/websocket?token=" ++ flags.token

        prodSocketServer =
            if String.isEmpty flags.token then
                "wss://elixir-elm-tutorial.herokuapp.com/socket/websocket"
            else
                "wss://elixir-elm-tutorial.herokuapp.com/socket/websocket?token=" ++ flags.token
    in
        Phoenix.Socket.init devSocketServer
            |> Phoenix.Socket.withDebug
            |> Phoenix.Socket.on "save_score" "score:platformer" SaveScore
            |> Phoenix.Socket.on "save_score" "score:platformer" ReceiveScoreChanges
            |> Phoenix.Socket.join initialChannel


initialChannel : Phoenix.Channel.Channel msg
initialChannel =
    Phoenix.Channel.init "score:platformer"


initialSocketJoin : Flags -> Phoenix.Socket.Socket Msg
initialSocketJoin flags =
    initialSocket flags
        |> Tuple.first


initialSocketCommand : Flags -> Cmd (Phoenix.Socket.Msg Msg)
initialSocketCommand flags =
    initialSocket flags
        |> Tuple.second


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( initialModel flags
    , Cmd.batch
        [ fetchGameplaysList
        , fetchPlayersList
        , Cmd.map PhoenixMsg (initialSocketCommand flags)
        ]
    )



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


anonymousPlayer : Player
anonymousPlayer =
    { displayName = Just "Anonymous User"
    , id = 0
    , score = 0
    , username = "anonymous"
    }



-- UPDATE


type Msg
    = NoOp
    | CountdownTimer Time
    | FetchGameplaysList (Result Http.Error (List Gameplay))
    | FetchPlayersList (Result Http.Error (List Player))
    | KeyDown KeyCode
    | KeyUp KeyCode
    | MoveCharacter Time
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | ReceiveScoreChanges Encode.Value
    | SaveScore Encode.Value
    | SaveScoreError Encode.Value
    | SaveScoreRequest
    | SetNewItemPositionX Float
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

        FetchGameplaysList result ->
            case result of
                Ok gameplays ->
                    ( { model | gameplays = gameplays }, Cmd.none )

                Err message ->
                    ( { model | errors = toString message }, Cmd.none )

        FetchPlayersList result ->
            case result of
                Ok players ->
                    ( { model | playersList = players }, Cmd.none )

                Err message ->
                    ( { model | errors = toString message }, Cmd.none )

        KeyDown keyCode ->
            let
                walkSpeed =
                    3.0

                runSpeed =
                    5.0

                jumpSpeed =
                    6.0
            in
                case keyCode of
                    -- Space bar key to start game
                    32 ->
                        if model.gameState /= Playing then
                            ( { model
                                | characterDirection = Right
                                , characterPositionX = 50
                                , itemsCollected = 0
                                , gameState = Playing
                                , playerScore = 0
                                , timeRemaining = 10
                              }
                            , Cmd.none
                            )
                        else
                            ( model, Cmd.none )

                    -- Left arrow key to walk left
                    37 ->
                        if model.gameState == Playing then
                            ( { model
                                | characterDirection = Left
                                , characterVelocityX = -walkSpeed
                              }
                            , Cmd.none
                            )
                        else
                            ( model, Cmd.none )

                    -- Up arrow key to jump
                    38 ->
                        if model.gameState == Playing && model.characterVelocityY == 0 then
                            ( { model | characterVelocityY = jumpSpeed }
                            , Cmd.none
                            )
                        else
                            ( model, Cmd.none )

                    -- Right arrow key to walk right
                    39 ->
                        if model.gameState == Playing then
                            ( { model
                                | characterDirection = Right
                                , characterVelocityX = walkSpeed
                              }
                            , Cmd.none
                            )
                        else
                            ( model, Cmd.none )

                    -- A key to run left
                    65 ->
                        if model.gameState == Playing then
                            ( { model
                                | characterDirection = Left
                                , characterVelocityX = -runSpeed
                              }
                            , Cmd.none
                            )
                        else
                            ( model, Cmd.none )

                    -- D key to run right
                    68 ->
                        if model.gameState == Playing then
                            ( { model
                                | characterDirection = Right
                                , characterVelocityX = runSpeed
                              }
                            , Cmd.none
                            )
                        else
                            ( model, Cmd.none )

                    -- any other key
                    _ ->
                        ( model, Cmd.none )

        KeyUp keyCode ->
            case keyCode of
                -- key up to stop movement
                _ ->
                    ( { model
                        | characterVelocityX = 0
                        , characterVelocityY = 0
                      }
                    , Cmd.none
                    )

        MoveCharacter time ->
            let
                newCharacterVelocityY =
                    -- apply gravity if character position is above ground
                    if model.characterPositionY < 300.0 then
                        model.characterVelocityY - (time / 50)
                    else
                        0
            in
                ( { model
                    | characterVelocityY = newCharacterVelocityY
                    , characterPositionX = model.characterPositionX + model.characterVelocityX * (time / 10)
                    , characterPositionY = Basics.min 300.0 (model.characterPositionY - model.characterVelocityY * (time / 10))
                  }
                , Cmd.none
                )

        PhoenixMsg msg ->
            let
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.update msg model.phxSocket
            in
                ( { model | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )

        ReceiveScoreChanges raw ->
            case Decode.decodeValue decodeGameplay raw of
                Ok scoreChange ->
                    ( { model | gameplays = scoreChange :: model.gameplays }, Cmd.none )

                Err message ->
                    ( { model | errors = message }, Cmd.none )

        SaveScore value ->
            ( model, Cmd.none )

        SaveScoreError message ->
            Debug.log "Error saving score over socket."
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

        SetNewItemPositionX newPositionX ->
            ( { model | itemPositionX = newPositionX }, Cmd.none )

        TimeUpdate time ->
            if characterFoundItem model then
                ( { model
                    | itemsCollected = model.itemsCollected + 1
                    , playerScore = model.playerScore + 100
                  }
                , Random.generate SetNewItemPositionX (Random.float 50 500)
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
        -- Allow character to find coin without having to be in exact spot
        collisionBuffer =
            35.0
    in
        model.characterPositionX
            >= (model.itemPositionX - collisionBuffer)
            && model.characterPositionX
            <= model.itemPositionX
            && model.characterPositionY
            >= (model.itemPositionY - collisionBuffer)
            && model.characterPositionY
            <= model.itemPositionY



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ downs KeyDown
        , ups KeyUp
        , diffs MoveCharacter
        , diffs TimeUpdate
        , every second CountdownTimer
        , Phoenix.Socket.listen model.phxSocket PhoenixMsg
        ]



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ viewGame model
        , viewSaveScoreButton
        , viewGameplaysIndex model
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
            model.playersList
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
    let
        characterImage =
            case model.characterDirection of
                Left ->
                    "/images/character-left.gif"

                Right ->
                    "/images/character-right.gif"
    in
        image
            [ xlinkHref characterImage
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
