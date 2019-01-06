module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode



-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias Model =
    { gamesList : List Game
    , gameplaysList : List Gameplay
    , playersList : List Player
    }


type alias Game =
    { description : String
    , featured : Bool
    , id : Int
    , slug : String
    , thumbnail : String
    , title : String
    }


type alias Gameplay =
    { gameId : Int
    , playerId : Int
    , playerScore : Int
    }


type alias Player =
    { displayGameplays : Bool
    , displayName : Maybe String
    , id : Int
    , score : Int
    , username : String
    }


initialModel : Model
initialModel =
    { gamesList = []
    , gameplaysList = []
    , playersList = []
    }


initialCommand : Cmd Msg
initialCommand =
    Cmd.batch
        [ fetchGamesList
        , fetchGameplaysList
        , fetchPlayersList
        ]


init : () -> ( Model, Cmd Msg )
init _ =
    ( initialModel, initialCommand )



-- API


fetchGamesList : Cmd Msg
fetchGamesList =
    Http.get
        { url = "/api/games"
        , expect = Http.expectJson FetchGamesList decodeGamesList
        }


fetchGameplaysList : Cmd Msg
fetchGameplaysList =
    Http.get
        { url = "/api/gameplays"
        , expect = Http.expectJson FetchGameplaysList decodeGameplaysList
        }


fetchPlayersList : Cmd Msg
fetchPlayersList =
    Http.get
        { url = "/api/players"
        , expect = Http.expectJson FetchPlayersList decodePlayersList
        }


decodeGamesList : Decode.Decoder (List Game)
decodeGamesList =
    decodeGame
        |> Decode.list
        |> Decode.at [ "data" ]


decodeGame : Decode.Decoder Game
decodeGame =
    Decode.map6 Game
        (Decode.field "description" Decode.string)
        (Decode.field "featured" Decode.bool)
        (Decode.field "id" Decode.int)
        (Decode.field "slug" Decode.string)
        (Decode.field "thumbnail" Decode.string)
        (Decode.field "title" Decode.string)


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


decodePlayersList : Decode.Decoder (List Player)
decodePlayersList =
    decodePlayer
        |> Decode.list
        |> Decode.at [ "data" ]


decodePlayer : Decode.Decoder Player
decodePlayer =
    Decode.map5 Player
        (Decode.succeed False)
        (Decode.maybe (Decode.field "display_name" Decode.string))
        (Decode.field "id" Decode.int)
        (Decode.field "score" Decode.int)
        (Decode.field "username" Decode.string)



-- UPDATE


type Msg
    = FetchGamesList (Result Http.Error (List Game))
    | FetchGameplaysList (Result Http.Error (List Gameplay))
    | FetchPlayersList (Result Http.Error (List Player))
    | TogglePlayerGameplays Player


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchGamesList result ->
            case result of
                Ok games ->
                    ( { model | gamesList = games }, Cmd.none )

                Err _ ->
                    Debug.log "Error fetching games from API."
                        ( model, Cmd.none )

        FetchGameplaysList result ->
            case result of
                Ok gameplays ->
                    ( { model | gameplaysList = gameplays }, Cmd.none )

                Err _ ->
                    Debug.log "Error fetching gameplays from API."
                        ( model, Cmd.none )

        FetchPlayersList result ->
            case result of
                Ok players ->
                    let
                        updatedPlayersList =
                            players
                                |> List.map
                                    (\player -> { player | score = findTotalScoreForPlayer model player })
                    in
                    ( { model | playersList = updatedPlayersList }, Cmd.none )

                Err message ->
                    Debug.log "Error fetching players from API."
                        ( model, Cmd.none )

        TogglePlayerGameplays player ->
            let
                updatedPlayersList =
                    List.map
                        (\p ->
                            if p.id == player.id then
                                { player | displayGameplays = not player.displayGameplays }

                            else
                                p
                        )
                        model.playersList
            in
            ( { model | playersList = updatedPlayersList }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ featured model
        , gamesIndex model
        , playersIndex model
        ]



-- FEATURED


featured : Model -> Html msg
featured model =
    case featuredGame model.gamesList of
        Just game ->
            div [ class "row featured" ]
                [ div [ class "container" ]
                    [ div [ class "featured-img" ]
                        [ img [ class "featured-thumbnail", src game.thumbnail ] [] ]
                    , div [ class "featured-data" ]
                        [ h2 [] [ text "Featured" ]
                        , h3 [] [ text game.title ]
                        , p [] [ text game.description ]
                        , a
                            [ class "button"
                            , href ("games/" ++ game.slug)
                            ]
                            [ text "Play Now!" ]
                        ]
                    ]
                ]

        Nothing ->
            div [] []


featuredGame : List Game -> Maybe Game
featuredGame games =
    games
        |> List.filter .featured
        |> List.head



-- GAMES


gamesIndex : Model -> Html msg
gamesIndex model =
    if List.isEmpty model.gamesList then
        div [] []

    else
        div [ class "games-index container" ]
            [ h2 [] [ text "Games" ]
            , gamesList model.gamesList
            ]


gamesList : List Game -> Html msg
gamesList games =
    ul [ class "games-list" ] (List.map gamesListItem games)


gamesListItem : Game -> Html msg
gamesListItem game =
    a [ href ("games/" ++ game.slug) ]
        [ li [ class "game-item" ]
            [ div [ class "game-image" ]
                [ img [ src game.thumbnail ] []
                ]
            , div [ class "game-info" ]
                [ h3 [] [ text game.title ]
                , p [] [ text game.description ]
                ]
            ]
        ]



-- PLAYERS


playersIndex : Model -> Html Msg
playersIndex model =
    if List.isEmpty model.playersList then
        div [] []

    else
        div [ class "players-index container" ]
            [ h2 [] [ text "Player Scores" ]
            , playersList model
            ]


playersList : Model -> Html Msg
playersList model =
    model.playersList
        |> sortPlayersByScore
        |> List.map (playersListItem model)
        |> ul [ class "players-list" ]


playersListItem : Model -> Player -> Html Msg
playersListItem model player =
    li [ class "player-item" ]
        [ playersListItemName player
        , playersListItemScore model player
        , if player.displayGameplays then
            gameplaysList model player

          else
            div [] []
        ]


playersListItemName : Player -> Html Msg
playersListItemName player =
    let
        displayName =
            case player.displayName of
                Just name ->
                    name

                Nothing ->
                    player.username
    in
    strong []
        [ a [ onClick (TogglePlayerGameplays player) ]
            [ text displayName ]
        ]


playersListItemScore : Model -> Player -> Html Msg
playersListItemScore model player =
    let
        playerScore =
            findTotalScoreForPlayer model player
    in
    span [ class "player-score" ]
        [ text (String.fromInt playerScore) ]



-- GAMEPLAYS


gameplaysList : Model -> Player -> Html msg
gameplaysList model player =
    let
        gameplays =
            findGameplaysForPlayer model player
    in
    if List.isEmpty gameplays then
        div [ class "gameplays-empty" ]
            [ text "No gameplays to display yet!" ]

    else
        div [ class "gameplays" ]
            (List.map (gameplaysListItem model) gameplays)


gameplaysListItem : Model -> Gameplay -> Html msg
gameplaysListItem model gameplay =
    let
        gameTitle =
            case findGameForGameplay model gameplay of
                Just game ->
                    game.title

                Nothing ->
                    String.fromInt gameplay.gameId
    in
    div []
        [ strong [] [ text (gameTitle ++ ": ") ]
        , span [] [ text (String.fromInt gameplay.playerScore) ]
        ]



-- HELPERS


findGameplaysForPlayer : Model -> Player -> List Gameplay
findGameplaysForPlayer model player =
    List.filter (\gameplay -> gameplay.playerId == player.id) model.gameplaysList


findGameForGameplay : Model -> Gameplay -> Maybe Game
findGameForGameplay model gameplay =
    model.gamesList
        |> List.filter (\game -> game.id == gameplay.gameId)
        |> List.head


findTotalScoreForPlayer : Model -> Player -> Int
findTotalScoreForPlayer model player =
    findGameplaysForPlayer model player
        |> List.map .playerScore
        |> List.sum


sortPlayersByScore : List Player -> List Player
sortPlayersByScore players =
    players
        |> List.sortBy .score
        |> List.reverse
