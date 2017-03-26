module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode
import Navigation


-- MAIN


main : Program Never Model Msg
main =
    Navigation.program locationToMessage
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- TYPES


type alias Model =
    { currentPage : Page
    , players : List Player
    , games : List Game
    }


type Page
    = Home
    | Players
    | Games
    | NotFound


type alias Player =
    { username : String
    , score : Int
    }


type alias Game =
    { title : String
    , description : String
    , authorId : Int
    }



-- INIT


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    ( location
        |> initPage
        |> initialModel
    , fetchAll
    )


initialModel : Page -> Model
initialModel page =
    { currentPage = page
    , players = []
    , games = []
    }



-- UPDATE


type Msg
    = NoOp
    | Navigate Page
    | ChangePage Page
    | FetchPlayers (Result Http.Error (List Player))
    | FetchGames (Result Http.Error (List Game))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Navigate page ->
            ( { model | currentPage = page }, pageToHash page |> Navigation.newUrl )

        ChangePage page ->
            ( { model | currentPage = page }, Cmd.none )

        FetchPlayers (Ok newPlayers) ->
            ( { model | players = newPlayers }, Cmd.none )

        FetchPlayers (Err _) ->
            ( model, Cmd.none )

        FetchGames (Ok newGames) ->
            ( { model | games = newGames }, Cmd.none )

        FetchGames (Err _) ->
            ( model, Cmd.none )



-- ROUTING


locationToMessage : Navigation.Location -> Msg
locationToMessage location =
    location.hash
        |> hashToPage
        |> ChangePage


initPage : Navigation.Location -> Page
initPage location =
    hashToPage location.hash


hashToPage : String -> Page
hashToPage hash =
    case hash of
        "#/" ->
            Home

        "#/players" ->
            Players

        "#/games" ->
            Games

        _ ->
            NotFound


pageToHash : Page -> String
pageToHash page =
    case page of
        Home ->
            "#/"

        Players ->
            "#/players"

        Games ->
            "#/games"

        NotFound ->
            "#/notfound"


pageView : Model -> Html Msg
pageView model =
    case model.currentPage of
        Home ->
            viewHome

        Players ->
            viewPlayers model

        Games ->
            viewGames model

        _ ->
            viewHome



-- API


fetchAll : Cmd Msg
fetchAll =
    Cmd.batch
        [ fetchPlayers
        , fetchGames
        ]


fetchPlayers : Cmd Msg
fetchPlayers =
    decodePlayerFetch
        |> Http.get "/api/players"
        |> Http.send FetchPlayers


decodePlayerFetch : Decode.Decoder (List Player)
decodePlayerFetch =
    Decode.at [ "data" ] decodePlayerList


decodePlayerList : Decode.Decoder (List Player)
decodePlayerList =
    Decode.list decodePlayerData


decodePlayerData : Decode.Decoder Player
decodePlayerData =
    Decode.map2 Player
        (Decode.field "username" Decode.string)
        (Decode.field "score" Decode.int)


fetchGames : Cmd Msg
fetchGames =
    decodeGameFetch
        |> Http.get "/api/games"
        |> Http.send FetchGames


decodeGameFetch : Decode.Decoder (List Game)
decodeGameFetch =
    Decode.at [ "data" ] decodeGameList


decodeGameList : Decode.Decoder (List Game)
decodeGameList =
    Decode.list decodeGameData


decodeGameData : Decode.Decoder Game
decodeGameData =
    Decode.map3 Game
        (Decode.field "title" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "author_id" Decode.int)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ viewHeader
        , viewPage model
        ]


viewHeader : Html Msg
viewHeader =
    Html.header [ class "header" ]
        [ homeLink
        , navLinksList
        ]


viewPage : Model -> Html Msg
viewPage model =
    case model.currentPage of
        Home ->
            viewHome

        Players ->
            viewPlayers model

        Games ->
            viewGames model

        _ ->
            viewHome


homeLink : Html Msg
homeLink =
    a [ onClick <| Navigate Home ] [ h1 [ class "header-text" ] [ text "Elixir and Elm Tutorial" ] ]


navLinksList : Html Msg
navLinksList =
    nav [] [ ul [ class "nav-list" ] navLinks ]


navLinks : List (Html Msg)
navLinks =
    [ li [] [ a [ onClick <| Navigate Players ] [ text "Players" ] ]
    , li [] [ a [ onClick <| Navigate Games ] [ text "Games" ] ]
    ]


viewHome : Html Msg
viewHome =
    div [] []


viewPlayers : Model -> Html Msg
viewPlayers { players } =
    div []
        [ h2 [] [ text "Players" ]
        , ul [ class "player-list" ] (players |> List.map viewPlayer)
        ]


viewPlayer : Player -> Html Msg
viewPlayer player =
    li [ class "player-list-item" ]
        [ text player.username ]


viewGames : Model -> Html Msg
viewGames { games } =
    div [ class "games" ]
        [ h2 [] [ text "Games" ]
        , ul [] (games |> List.map viewGame)
        ]


viewGame : Game -> Html Msg
viewGame game =
    li [] [ text game.title ]
