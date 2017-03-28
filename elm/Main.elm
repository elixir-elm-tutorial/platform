module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
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
    , newPlayerUsername : String
    , players : List Player
    , games : List Game
    , errors : String
    }


type Page
    = Home
    | SignUp
    | SignIn
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
    , newPlayerUsername = ""
    , players = []
    , games = []
    , errors = ""
    }



-- UPDATE


type Msg
    = NoOp
    | Navigate Page
    | ChangePage Page
    | PlayerCreate String
    | PlayerCreateHandler (Result Http.Error Player)
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

        PlayerCreate username ->
            ( model, performPlayerCreation username )

        PlayerCreateHandler (Ok player) ->
            ( model, Cmd.none )

        PlayerCreateHandler (Err httpError) ->
            ( { model | errors = httpError |> toString }, Cmd.none )

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

        "#/signup" ->
            SignUp

        "#/signin" ->
            SignIn

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

        SignUp ->
            "#/signup"

        SignIn ->
            "#/signin"

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
            viewHomePage

        SignUp ->
            viewSignUpPage model

        SignIn ->
            viewSignInPage

        Players ->
            viewPlayersPage model

        Games ->
            viewGamesPage model

        _ ->
            viewHomePage



-- API


newPlayer : String -> Encode.Value
newPlayer username =
    Encode.object
        [ ( "player"
          , Encode.object
                [ ( "username", Encode.string username )
                , ( "score", Encode.int 0 )
                ]
          )
        ]


playerCreation : String -> Http.Request Player
playerCreation username =
    Http.post "/api/players" (Http.jsonBody (newPlayer username)) decodePlayerData


performPlayerCreation : String -> Cmd Msg
performPlayerCreation username =
    username
        |> playerCreation
        |> Http.send PlayerCreateHandler


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
    , li [] [ a [ onClick <| Navigate SignUp ] [ text "Sign Up" ] ]
    , li [] [ a [ onClick <| Navigate SignIn ] [ text "Sign In" ] ]
    ]


viewPage : Model -> Html Msg
viewPage model =
    case model.currentPage of
        SignUp ->
            viewSignUpPage model

        SignIn ->
            viewSignInPage

        Home ->
            viewHomePage

        Players ->
            viewPlayersPage model

        Games ->
            viewGamesPage model

        _ ->
            viewHomePage


viewHomePage : Html Msg
viewHomePage =
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


viewSignUpPage : Model -> Html Msg
viewSignUpPage model =
    div [ class "container" ]
        [ h2 [] [ text "Player Sign Up" ]
          -- <%= form_for @changeset, player_path(@conn, :create), fn f -> %>
          -- hidden input for csrf_token
        , Html.form [ onSubmit <| PlayerCreate model.newPlayerUsername, acceptCharset "UTF-8", action "/players", method "post" ]
            [ div [ class "form-group" ]
                [ label [ class "control-label", for "player_username" ] [ text "Player Username" ]
                , input [ class "form-control", id "player_username", name "player[username]", placeholder "Enter username...", type_ "text" ] []
                ]
            , div [ class "form-group" ]
                [ label [ class "control-label", for "player_password" ] [ text "Player Password" ]
                , input [ class "form-control", id "player_password", name "player[password]", placeholder "Enter password...", type_ "text" ] []
                ]
            , button [ class "btn btn-primary", type_ "submit" ] [ text "Sign Up" ]
            ]
        ]


viewSignInPage : Html Msg
viewSignInPage =
    div [ class "container" ]
        [ h2 [] [ text "Player Sign In" ]
          -- <%= form_for @conn, player_session_path(@conn, :create), [as: :session], fn f -> %>
          -- hidden input for csrf_token
        , Html.form [ acceptCharset "UTF-8", action "/sessions", method "post" ]
            [ div [ class "form-group" ]
                [ label [ class "control-label", for "session_username" ] [ text "Player Username" ]
                , input [ class "form-control", id "session_username", name "session[username]", placeholder "Enter username...", type_ "text" ] []
                ]
            , div [ class "form-group" ]
                [ label [ class "control-label", for "session_password" ] [ text "Player Password" ]
                , input [ class "form-control", id "session_password", name "session[password]", placeholder "Enter password...", type_ "text" ] []
                ]
            , button [ class "btn btn-primary", type_ "submit" ] [ text "Sign In" ]
            ]
        ]


viewPlayersPage : Model -> Html Msg
viewPlayersPage { players } =
    div []
        [ h2 [] [ text "Players" ]
        , ul [ class "player-list" ] (players |> List.map viewPlayer)
        ]


viewPlayer : Player -> Html Msg
viewPlayer player =
    li [ class "player-list-item" ]
        [ text player.username ]


viewGamesPage : Model -> Html Msg
viewGamesPage model =
    div [ class "games-page" ]
        [ viewGamesHero
        , viewGamesContent model
        ]


viewGamesHero : Html Msg
viewGamesHero =
    div [ class "container-fluid hero" ]
        [ div [ class "container" ]
            [ div [ class "col-xs-6" ]
                [ a [ href "/" ] [ img [ class "hero-image", src "images/games_sample.png" ] [] ]
                ]
            , div [ class "col-xs-6" ]
                [ h1 [ class "hero-header" ] [ text "Featured" ]
                , a [ href "/" ] [ button [ class "btn btn-lg btn-success" ] [ text "Play Now!" ] ]
                ]
            ]
        ]


viewGamesContent : Model -> Html Msg
viewGamesContent { games } =
    div []
        (games |> List.map viewGame)


viewGame : Game -> Html Msg
viewGame game =
    div [ class "container" ]
        [ div [ class "content" ]
            [ div [ class "col-xs-8" ]
                [ a [ href "/" ] [ img [ class "content-image games-image", src "http://placehold.it/400x200" ] [] ]
                ]
            , div [ class "col-xs-4" ]
                [ h2 [ class "games-header" ] [ text game.title ]
                , p [ class "games-text" ]
                    [ text game.description
                    ]
                ]
            ]
        ]
