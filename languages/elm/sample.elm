-- Elm 0.19.1 — syntax showcase (latest stable; the compiler is not installed locally)
port module Warehouse exposing (Model, Msg(..), Category(..), main, update, view)

{-| Module documentation comment.

    Warehouse.update Increment init

@docs Model, Msg
-}

-- ── Comments ──
-- Line comment. TODO: persist bins. FIXME: handle negative stock.
{- Block comment
   {- nested block comment -}
   still a comment -}

-- ── Imports ──

import Array exposing (Array)
import Browser
import Dict exposing (Dict)
import Html exposing (Html, button, div, h1, input, li, p, span, text, ul)
import Html.Attributes as Attr exposing (class, classList, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode exposing (Decoder, field, int, list, string)
import Http
import Json.Encode as Encode
import Set exposing (..)
import Task as T
import Url.Parser exposing ((</>), (<?>), Parser, s)
import Time exposing (Posix)



-- ── Constants and literals ──


maxBins : Int
maxBins =
    64


piApprox : Float
piApprox =
    3.14159


numbers : List Float
numbers =
    [ 42, 1000000, 0xFF, 0x2A, 6.02e23, 1.5e-10, -17 ]


chars : List Char
chars =
    [ 'a', '\n', '\t', '\\', '\'', '\u{00E9}', '\u{1F4E6}' ]


greeting : String
greeting =
    "Warehouse \"north\"\t\n \u{00E9} \\"


multiline : String
multiline =
    """Triple-quoted
string with "quotes" inside
and a second line"""


unit : ()
unit =
    ()


tuple : ( Int, String, Float )
tuple =
    ( 1, "two", 3.0 )


emptyList : List a
emptyList =
    []


infinity : Float
infinity =
    1 / 0


nan : Float
nan =
    0 / 0



-- ── Types ──


type alias Sku =
    String


type alias Item =
    { sku : Sku
    , qty : Int
    , price : Float
    , tags : List String
    , category : Category
    }


type alias Model =
    { items : Dict Sku Item
    , selected : Maybe Sku
    , step : Int
    , filter : String
    , now : Posix
    }


type Category
    = Tools
    | Fasteners
    | Safety Int
    | Bulk { weight : Float }


type Msg
    = Increment Sku
    | Decrement Sku
    | SetStep String
    | Select (Maybe Sku)
    | Loaded (Result Http.Error (List Item))
    | Tick Posix
    | NoOp


type Tree a
    = Leaf
    | Node (Tree a) a (Tree a)


type Opaque
    = Opaque Int


type alias Pair a b =
    ( a, b )


type alias Extensible r =
    { r | sku : Sku }



-- ── Ports ──


port saveStock : Encode.Value -> Cmd msg


port loadStock : (Decode.Value -> msg) -> Sub msg



-- ── Functions ──


init : Model
init =
    { items = Dict.empty
    , selected = Nothing
    , step = 1
    , filter = ""
    , now = Time.millisToPosix 0
    }


clampValue : comparable -> comparable -> comparable -> comparable
clampValue lo hi value =
    if value < lo then
        lo

    else if value > hi then
        hi

    else
        value


describe : Category -> String
describe category =
    case category of
        Tools ->
            "tools"

        Fasteners ->
            "fasteners"

        Safety level ->
            "safety " ++ String.fromInt level

        Bulk { weight } ->
            "bulk " ++ String.fromFloat weight


size : Tree a -> Int
size tree =
    case tree of
        Leaf ->
            0

        Node left _ right ->
            size left + 1 + size right


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Increment sku ->
            ( { model | items = Dict.update sku (Maybe.map (\item -> { item | qty = item.qty + model.step })) model.items }
            , Cmd.none
            )

        Decrement sku ->
            let
                bump item =
                    { item | qty = max 0 (item.qty - model.step) }

                updated =
                    Dict.update sku (Maybe.map bump) model.items
            in
            ( { model | items = updated }, saveStock (encode updated) )

        SetStep raw ->
            ( { model | step = Maybe.withDefault 1 (String.toInt raw) }, Cmd.none )

        Select (Just sku) ->
            ( { model | selected = Just sku }, Cmd.none )

        Select Nothing ->
            ( { model | selected = Nothing }, Cmd.none )

        Loaded (Ok items) ->
            ( { model | items = Dict.fromList (List.map (\i -> ( i.sku, i )) items) }, Cmd.none )

        Loaded (Err _) ->
            ( model, Cmd.none )

        Tick now ->
            ( { model | now = now }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


encode : Dict Sku Item -> Encode.Value
encode items =
    Encode.list
        (\item ->
            Encode.object
                [ ( "sku", Encode.string item.sku )
                , ( "qty", Encode.int item.qty )
                , ( "price", Encode.float item.price )
                ]
        )
        (Dict.values items)


decoder : Decoder Item
decoder =
    Decode.map5 Item
        (field "sku" string)
        (field "qty" int)
        (field "price" Decode.float)
        (field "tags" (list string))
        (Decode.succeed Tools)



-- ── Operators ──


operators : Int -> Int -> Bool
operators a b =
    let
        sum =
            a + b - a * b // 2

        power =
            2 ^ 3

        ratio =
            toFloat a / toFloat b

        composed =
            String.fromInt >> String.toUpper << String.trim

        piped =
            a |> String.fromInt |> String.length

        backPiped =
            String.length <| String.fromInt a

        remainder =
            modBy 3 a + remainderBy 3 b

        cat =
            "a" ++ "b"

        cons =
            0 :: [ 1, 2 ]
    in
    (a < b && a <= b || a > b) && a /= b && not (a == b)


parser : Maybe Int -> Int
parser =
    Maybe.withDefault 0


infixOperators : Int
infixOperators =
    let
        ( first, second ) =
            ( 1, 2 )

        { sku, qty } =
            { sku = "A-1", qty = 5 }

        (Opaque inner) =
            Opaque 7
    in
    first + second + qty + inner



-- ── View ──


view : Model -> Html Msg
view model =
    div [ class "stock", classList [ ( "empty", Dict.isEmpty model.items ) ], style "padding" "8px" ]
        [ h1 [] [ text "Stock" ]
        , button [ onClick NoOp ] [ text "-" ]
        , input [ type_ "number", value (String.fromInt model.step), onInput SetStep ] []
        , ul [] (List.map viewItem (Dict.values model.items))
        , p [] [ text (describe (Safety 3)) ]
        , if Dict.isEmpty model.items then
            span [] [ text "no items" ]

          else
            text ""
        ]


viewItem : Item -> Html Msg
viewItem item =
    li [ onClick (Select (Just item.sku)) ]
        [ text (item.sku ++ " x" ++ String.fromInt item.qty) ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ Time.every 1000 Tick, loadStock (\_ -> NoOp) ]


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( init, Cmd.none )
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- ── Further constructs ──


{-| Doc comment before a declaration with `inline code`.

    exampleBlock : Int
    exampleBlock =
        1

-}
documented : Int
documented =
    1


{- Block comment {- nested -} -}
-- | Special-looking line comment
--- Triple-dash comment


type alias Record3 =
    { a : Int, b : Int, c : Int }


type alias WithFunction =
    { handler : Int -> Int -> Int, maybeValue : Maybe (List (Result String Int)) }


type Phantom a
    = Phantom


type Wrapper a b
    = Wrapper { first : a, second : b }
    | Pair ( a, b )
    | Func (a -> b)
    | Many a b a b


numbersAndTexts : List String
numbersAndTexts =
    [ String.fromInt 0x7FFFFFFF
    , String.fromFloat 1.0e10
    , String.fromFloat 1.5E-3
    , "emoji 📦 and \u{1F4E6}"
    , "tab\t newline\n carriage\r quote\" backslash\\ unicode\u{00E9}"
    , """triple "quotes" \n are literal-ish and "may" span
    several lines"""
    , String.fromChar '\t'
    ]


letInExamples : Int -> Int
letInExamples n =
    let
        ( a, b ) =
            ( n, n + 1 )

        [ x, y ] =
            [ 1, 2 ]

        { first, second } =
            { first = 1, second = 2 }

        twice : Int -> Int
        twice v =
            v * 2

        _ =
            Debug.log "ignored" n
    in
    twice (a + b + x + y + first + second)


caseExamples : Maybe (List Int) -> Result String Int -> String
caseExamples maybe result =
    case ( maybe, result ) of
        ( Just [], _ ) ->
            "empty"

        ( Just [ one ], Ok _ ) ->
            "one " ++ String.fromInt one

        ( Just (first :: second :: _), Err msg ) ->
            msg ++ String.fromInt (first + second)

        ( Just ((_ :: _) as all), Ok v ) ->
            String.fromInt (List.length all + v)

        ( Nothing, Ok 0 ) ->
            "zero"

        ( Nothing, Err "" ) ->
            "blank"

        ( Nothing, Err ('a' :: _) ) ->
            "starts with a"

        ( _, _ ) ->
            "other"


recordOps : { a : Int, b : String } -> String
recordOps r =
    let
        updated =
            { r | a = r.a + 1, b = r.b ++ "!" }

        getter =
            .a

        accessChain =
            updated.b |> String.length
    in
    String.fromInt (getter updated + accessChain)


lambdas : List (Int -> Int)
lambdas =
    [ \x -> x + 1
    , \_ -> 0
    , \( a, b ) -> a + b
    , \{ a } -> a
    , \(Wrapper _) -> 0
    , (+) 1
    , (<<) negate abs
    , (|>) 5
    ]


ifChains : Int -> String
ifChains n =
    if n < 0 then
        "neg"

    else if n == 0 then
        "zero"

    else if modBy 2 n == 0 && n > 100 || n == 42 then
        "big even or 42"

    else
        "other"


portsAndFlags : Cmd msg
portsAndFlags =
    Cmd.none


orElse : Maybe a -> Maybe a -> Maybe a
orElse first second =
    case first of
        Nothing ->
            second

        _ ->
            first


keep : a -> b -> a
keep a _ =
    a


testExpectations : List String
testExpectations =
    [ Debug.toString 1, Debug.toString [ 1, 2 ], Debug.toString "s", Debug.toString ( 1, 'c' ) ]


-- ── Extra forms ──


qualifiedUse : String
qualifiedUse =
    String.toUpper "x"


negatives : List Int
negatives =
    [ -1, negate 2, -0x10, 1 - -1 ]


multiArgLambda : Int -> Int -> Int
multiArgLambda =
    \a b -> a * b


whereLike : Int
whereLike =
    let
        go : Int -> Int -> Int
        go acc n =
            if n <= 0 then
                acc

            else
                go (acc + n) (n - 1)
    in
    go 0 10
