module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


-- MAIN


main : Html msg
main =
    div []
        [ h1 [] [ text "Games" ]
        , gamesIndex model
        ]



-- MODEL


model : List String
model =
    [ "Platform Game"
    , "Adventure Game"
    ]



-- VIEW


gamesIndex : List String -> Html msg
gamesIndex gameTitles =
    div [ class "games-index" ] [ gamesList gameTitles ]


gamesList : List String -> Html msg
gamesList gameTitles =
    ul [ class "games-list" ] (List.map gamesListItem gameTitles)


gamesListItem : String -> Html msg
gamesListItem gameTitle =
    li [] [ text gameTitle ]
