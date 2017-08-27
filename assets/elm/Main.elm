module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


-- MAIN


main : Html msg
main =
    gamesIndex



-- MODEL


model : List String
model =
    [ "Platform Game"
    , "Adventure Game"
    ]


firstGameMaybe : Maybe String
firstGameMaybe =
    List.head model


firstGameTitle : String
firstGameTitle =
    Maybe.withDefault "" firstGameMaybe



-- VIEW


gamesIndex : Html msg
gamesIndex =
    div [ class "games-index" ] [ gamesList ]


gamesList : Html msg
gamesList =
    ul [ class "games-list" ] [ gamesListItem ]


gamesListItem : Html msg
gamesListItem =
    li [] [ text firstGameTitle ]
