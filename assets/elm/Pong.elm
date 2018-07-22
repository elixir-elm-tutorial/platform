module Pong exposing (..)

import Html exposing (..)


---- MODEL ----


type alias Ball =
    { id : Int
    , positionX : Float
    , positionY : Float
    }


type GameState
    = StartScreen
    | Playing
    | EndScreen


type alias Player =
    { id : Int
    , positionX : Float
    , positionY : Float
    , score : Int
    }


type alias Model =
    { ball : Ball
    , errors : Maybe String
    , gameState : GameState
    , players : List Player
    }


type Msg
    = NoOp



---- INIT ----


initialBall : Ball
initialBall =
    { id = 1
    , positionX = 100
    , positionY = 100
    }


initialModel : Model
initialModel =
    { ball = initialBall
    , errors = Nothing
    , gameState = StartScreen
    , players = []
    }


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )



---- UPDATE ----


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        _ ->
            ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div [] []



---- MAIN ----


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }
