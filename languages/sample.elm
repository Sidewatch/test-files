module Counter exposing (main)

-- A counter with a step size, the Elm Architecture in one file.

import Browser
import Html exposing (Html, button, div, input, text)
import Html.Attributes exposing (value)
import Html.Events exposing (onClick, onInput)


type alias Model =
    { count : Int, step : Int }


type Msg
    = Increment
    | Decrement
    | SetStep String


init : Model
init =
    { count = 0, step = 1 }


update : Msg -> Model -> Model
update msg model =
    case msg of
        Increment ->
            { model | count = model.count + model.step }

        Decrement ->
            { model | count = model.count - model.step }

        SetStep raw ->
            { model | step = Maybe.withDefault 1 (String.toInt raw) }


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick Decrement ] [ text "-" ]
        , text (" " ++ String.fromInt model.count ++ " ")
        , button [ onClick Increment ] [ text "+" ]
        , input [ value (String.fromInt model.step), onInput SetStep ] []
        ]


main : Program () Model Msg
main =
    Browser.sandbox { init = init, update = update, view = view }
