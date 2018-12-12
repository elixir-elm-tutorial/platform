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
    }


type alias Game =
    { title : String
    , description : String
    }


initialModel : Model
initialModel =
    { gamesList = []
    }


initialCommand : Cmd Msg
initialCommand =
    Cmd.none


init : ( Model, Cmd Msg )
init =
    ( initialModel, initialCommand )



-- UPDATE


type Msg
    = FetchGamesList


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchGamesList ->
            ( { model | gamesList = [] }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    if List.isEmpty model.gamesList then
        div [] []

    else
        div []
            [ h1 [ class "games-section" ] [ text "Games" ]
            , gamesIndex model
            ]
