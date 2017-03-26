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
        [ -- fetchPlayers
          fetchGames
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
    div [ class "header" ]
        [ viewNavbar
          -- , navLinksList
        ]


viewNavbar : Html Msg
viewNavbar =
    div [ class "navbar navbar-default navbar-static-top" ]
        [ div [ class "container" ]
            [ viewNavbarHeader
            , viewNavbarNav
            ]
        ]


viewNavbarHeader : Html Msg
viewNavbarHeader =
    div [ class "navbar-header" ]
        [ a [ class "navbar-brand", onClick <| Navigate Home ] [ text "Elixir and Elm Tutorial" ]
        ]


viewNavbarNav : Html Msg
viewNavbarNav =
    div [ class "collapse navbar-collapse navbar-right" ]
        [ ul [ class "nav navbar-nav" ] viewNavbarNavLinks
        ]


viewNavbarNavLinks : List (Html Msg)
viewNavbarNavLinks =
    [ li [] [ a [ href "https://leanpub.com/elixir-elm-tutorial", target "_blank" ] [ text "Book" ] ]
    , li [] [ a [ onClick <| Navigate Games ] [ text "Games" ] ]
    , li [] [ a [ href "/players" ] [ text "Players" ] ]
      --   <%= if @current_user do %>
      --     <li class="navbar-text">Logged in as <strong><%= @current_user.username %></strong></li>
      --     <li><%= link "Log Out", to: player_session_path(@conn, :delete, @current_user), method: "delete", class: "navbar-link" %></li>
      --   <% else %>
      --     <li><%= link "Sign Up", to: player_path(@conn, :new) %></li>
      --     <li><%= link "Sign In", to: player_session_path(@conn, :new) %></li>
      --   <% end %>
    , li [] [ a [ href "/players/new" ] [ text "Sign Up" ] ]
    , li [] [ a [ href "/sessions/new" ] [ text "Sign In" ] ]
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


viewHome : Html Msg
viewHome =
    div []
        [ viewHomeHero
        , viewHomeContent
        ]


viewHomeHero : Html Msg
viewHomeHero =
    div [ class "container-fluid hero" ]
        [ div [ class "container" ]
            [ div [ class "col-xs-6" ]
                [ a [ href "https://leanpub.com/elixir-elm-tutorial" ] [ img [ class "hero-image", src "images/book_cover.png" ] [] ]
                ]
            , div [ class "col-xs-6" ]
                [ h1 [ class "hero-header" ]
                    [ text "Want to learn how to create a site like this?" ]
                , a [ href "https://leanpub.com/elixir-elm-tutorial", target "_blank" ] [ button [ class "btn btn-lg btn-success" ] [ text "Buy the Book!" ] ]
                , a [ class "twitter-hashtag-button", attribute "data-show-count" "false", attribute "data-text" "I'm learning functional programming with Elixir and Elm!", attribute "data-url" "https://leanpub.com/elixir-elm-tutorial", href "https://twitter.com/intent/tweet?button_hashtag=ElixirElmTutorial" ] [ text "Tweet #ElixirElmTutorial" ]
                , node "script" [ attribute "async" "", charset "utf-8", src "//platform.twitter.com/widgets.js" ] []
                ]
            ]
        ]


viewHomeContent : Html Msg
viewHomeContent =
    div [ class "container" ]
        [ div [ class "content" ]
            [ div [ class "col-xs-8" ]
                [ a [ href "/api/games" ] [ img [ class "content-image games-image", src "images/games_sample.png" ] [] ]
                ]
            , div [ class "col-xs-4" ]
                [ h2 [ class "games-header" ] [ text "Create Minigames with Elm" ]
                , p [ class "games-text" ]
                    [ text "Learn to create fun "
                    , a [ href "/api/games" ]
                        [ text "interactive minigames" ]
                    , text " with the Elm programming language."
                    ]
                ]
            ]
        , div [ class "content" ]
            [ div [ class "col-xs-8" ]
                [ a [ href "/players" ]
                    [ img [ class "content-image platform-image", src "images/platform_sample.png" ]
                        []
                    ]
                ]
            , div [ class "col-xs-4" ]
                [ h2 [ class "platform-header" ]
                    [ text "Create a Player Platform with Elixir and Phoenix" ]
                , p [ class "platform-text" ]
                    [ text "Create a "
                    , a [ href "/players" ]
                        [ text "player platform" ]
                    , text " to track scores and manage player accounts."
                    ]
                ]
            ]
        ]


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
