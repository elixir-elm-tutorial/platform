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


type alias Player =
    { displayName : Maybe String
    , id : Int
    , score : Int
    , username : String
    }


initialModel : Model
initialModel =
    { gamesList = []
    , playersList = []
    }


initialCommand : Cmd Msg
initialCommand =
    Cmd.batch
        [ fetchGamesList
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



-- UPDATE


type Msg
    = FetchGamesList (Result Http.Error (List Game))
    | FetchPlayersList (Result Http.Error (List Player))


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

        FetchPlayersList result ->
            case result of
                Ok players ->
                    ( { model | playersList = players }, Cmd.none )

                Err _ ->
                    Debug.log "Error fetching players from API."
                        ( model, Cmd.none )



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


playersIndex : Model -> Html msg
playersIndex model =
    if List.isEmpty model.playersList then
        div [] []

    else
        div [ class "players-index container" ]
            [ h2 [] [ text "Players" ]
            , model.playersList
                |> playersSortedByScore
                |> playersList
            ]


playersSortedByScore : List Player -> List Player
playersSortedByScore players =
    players
        |> List.sortBy .score
        |> List.reverse


playersList : List Player -> Html msg
playersList players =
    ul [ class "players-list" ] (List.map playersListItem players)


playersListItem : Player -> Html msg
playersListItem player =
    let
        playerLink name =
            a [ href ("players/" ++ String.fromInt player.id) ]
                [ strong [ class "player-name" ] [ text name ] ]
    in
    li [ class "player-item" ]
        [ p [ class "player-score" ] [ text (String.fromInt player.score) ]
        , case player.displayName of
            Just displayName ->
                playerLink displayName

            Nothing ->
                playerLink player.username
        ]
