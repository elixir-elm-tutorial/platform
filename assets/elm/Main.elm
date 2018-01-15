module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode


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


type alias Model =
    { gamesList : List Game
    , gameplaysList : List Gameplay
    , playersList : List Player
    , errors : String
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
    { displayGameplays : Maybe Bool
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
    , errors = ""
    }


initialCommand : Cmd Msg
initialCommand =
    Cmd.batch
        [ fetchGamesList
        , fetchGameplaysList
        , fetchPlayersList
        ]


init : ( Model, Cmd Msg )
init =
    ( initialModel, initialCommand )



-- API


fetchGamesList : Cmd Msg
fetchGamesList =
    Http.get "/api/games" decodeGamesList
        |> Http.send FetchGamesList


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
    Decode.map5 Player
        (Decode.maybe (Decode.field "display_gameplays" Decode.bool))
        (Decode.maybe (Decode.field "display_name" Decode.string))
        (Decode.field "id" Decode.int)
        (Decode.field "score" Decode.int)
        (Decode.field "username" Decode.string)


anonymousPlayer : Player
anonymousPlayer =
    { displayGameplays = Just False
    , displayName = Just "Anonymous User"
    , id = 0
    , score = 0
    , username = "anonymous"
    }



-- UPDATE


type Msg
    = TogglePlayerGameplays Player
    | FetchGamesList (Result Http.Error (List Game))
    | FetchGameplaysList (Result Http.Error (List Gameplay))
    | FetchPlayersList (Result Http.Error (List Player))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TogglePlayerGameplays player ->
            let
                newPlayersList =
                    List.map
                        (\p ->
                            if p.id == player.id then
                                { player | displayGameplays = Just <| not <| Maybe.withDefault False player.displayGameplays }
                            else
                                p
                        )
                        model.playersList
            in
                ( { model | playersList = newPlayersList }, Cmd.none )

        FetchGamesList result ->
            case result of
                Ok games ->
                    ( { model | gamesList = games }, Cmd.none )

                Err message ->
                    ( { model | errors = toString message }, Cmd.none )

        FetchGameplaysList result ->
            case result of
                Ok gameplays ->
                    ( { model | gameplaysList = gameplays }, Cmd.none )

                Err message ->
                    ( { model | errors = toString message }, Cmd.none )

        FetchPlayersList result ->
            case result of
                Ok players ->
                    ( { model | playersList = players }, Cmd.none )

                Err message ->
                    ( { model | errors = toString message }, Cmd.none )



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


featured : Model -> Html msg
featured model =
    case featuredGame model.gamesList of
        Just game ->
            div [ class "row featured" ]
                [ div [ class "container" ]
                    [ div [ class "featured-img" ]
                        [ img [ class "featured-thumbnail", src game.thumbnail ] [] ]
                    , div [ class "featured-data" ]
                        [ h1 [] [ text "Featured" ]
                        , h2 [] [ text game.title ]
                        , p [] [ text game.description ]
                        , a [ class "btn btn-lg btn-primary", href <| "games/" ++ game.slug ] [ text "Play Now!" ]
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


gamesIndex : Model -> Html msg
gamesIndex model =
    if List.isEmpty model.gamesList then
        div [] []
    else
        div [ class "games-index" ]
            [ h1 [ class "games-section" ] [ text "Games" ]
            , gamesList model.gamesList
            ]


gamesList : List Game -> Html msg
gamesList games =
    ul [ class "games-list media-list" ] (List.map gamesListItem games)


gamesListItem : Game -> Html msg
gamesListItem game =
    a [ href <| "games/" ++ game.slug ]
        [ li [ class "game-item media" ]
            [ div [ class "media-left" ]
                [ img [ class "media-object", src game.thumbnail ] []
                ]
            , div [ class "media-body media-middle" ]
                [ h4 [ class "media-heading" ] [ text game.title ]
                , p [] [ text game.description ]
                ]
            ]
        ]


playersIndex : Model -> Html Msg
playersIndex model =
    if List.isEmpty model.playersList then
        div [] []
    else
        div [ class "players-index" ]
            [ h1 [ class "players-section" ] [ text "Players" ]
            , (playersList model) <| playersSortedByScore model.playersList
            ]


playersSortedByScore : List Player -> List Player
playersSortedByScore players =
    players
        |> List.sortBy .score
        |> List.reverse


playersList : Model -> List Player -> Html Msg
playersList model players =
    div [ class "players-list panel panel-info" ]
        [ div [ class "panel-heading" ] [ text "Leaderboard" ]
        , ul [ class "list-group" ] (List.map (playersListItem model) players)
        ]


playersListItem : Model -> Player -> Html Msg
playersListItem model player =
    let
        displayName =
            if player.displayName == Nothing then
                player.username
            else
                Maybe.withDefault "" player.displayName

        displayGameplays =
            if player.displayGameplays == Nothing || player.displayGameplays == Just False then
                div [] []
            else
                (playerGameplaysList model) player
    in
        li [ class "player-item list-group-item" ]
            [ strong [] [ a [ onClick <| TogglePlayerGameplays player ] [ text displayName ] ]
            , span [ class "badge" ] [ text (toString player.score) ]
            , displayGameplays
            ]


playerGameplaysList : Model -> Player -> Html msg
playerGameplaysList model player =
    let
        gameplays =
            List.filter (\gameplay -> gameplay.playerId == player.id) model.gameplaysList
    in
        if List.isEmpty gameplays then
            p [] [ text "No gameplays to display yet!" ]
        else
            ul [] (List.map (playerGameplaysListItem model) gameplays)


playerGameplaysListItem : Model -> Gameplay -> Html msg
playerGameplaysListItem model gameplay =
    let
        gameTitle =
            if gameplay.gameId == 1 then
                "Platformer   "
            else
                toString gameplay.gameId
    in
        li []
            [ span [] [ text gameTitle ]
            , span [ class "badge" ] [ text <| toString <| gameplay.playerScore ]
            ]
