module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)



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
    , displayGamesList : Bool
    }


type alias Game =
    { title : String
    , description : String
    }


initialModel : Model
initialModel =
    { gamesList =
        [ { title = "Platform Game", description = "Platform game example." }
        , { title = "Adventure Game", description = "Adventure game example." }
        ]
    , displayGamesList = True
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( initialModel, Cmd.none )



-- UPDATE


type Msg
    = DisplayGamesList
    | HideGamesList


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DisplayGamesList ->
            ( { model | displayGamesList = True }, Cmd.none )

        HideGamesList ->
            ( { model | displayGamesList = False }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ h1 [ class "games-section" ] [ text "Games" ]
        , button [ class "button", onClick DisplayGamesList ] [ text "Display Games List" ]
        , button [ class "button", onClick HideGamesList ] [ text "Hide Games List" ]
        , if model.displayGamesList then
            gamesIndex model

          else
            div [] []
        ]


gamesIndex : Model -> Html msg
gamesIndex model =
    div [ class "games-index" ] [ gamesList model.gamesList ]


gamesList : List Game -> Html msg
gamesList games =
    ul [ class "games-list" ] (List.map gamesListItem games)


gamesListItem : Game -> Html msg
gamesListItem game =
    li [ class "game-item" ]
        [ strong [] [ text game.title ]
        , p [] [ text game.description ]
        ]
