-- ── Comments ──
-- PureScript showcase: a typed warehouse inventory model.
-- TODO: replace the String sku with a newtype. FIXME: unsafe partial in `headOr`.

{- A block comment
   {- with a nested block comment -}
   spanning lines. -}

-- | A documentation comment attached to the next declaration.
-- | It may span several lines.
module Sample
  ( Order(..)
  , Status(Pending, Paid)
  , class Describe
  , describe
  , revenue
  , main
  , module Data.Maybe
  ) where

-- ── Imports ──
import Prelude

import Control.Monad.State (State, get, put, modify_, evalState)
import Data.Array (filter, mapMaybe, (:), (..))
import Data.Array as Array
import Data.Either (Either(..), either)
import Data.Generic.Rep (class Generic)
import Data.Foldable (class Foldable, foldl, foldr, sum, for_)
import Data.Int (fromString, toNumber)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe, maybe)
import Data.Newtype (class Newtype, unwrap)
import Data.Number as Number
import Data.String (split, Pattern(..))
import Data.String.CodeUnits (toCharArray)
import Data.Tuple (Tuple(..), fst, snd)
import Effect (Effect)
import Effect.Aff (Aff, launchAff_, delay, Milliseconds(..))
import Effect.Class (liftEffect)
import Effect.Console (log, logShow)
import Foreign.Object (Object)
import Prim.Row (class Cons)
import Type.Proxy (Proxy(..))

-- ── Foreign imports ──
foreign import data Warehouse :: Type
foreign import now :: Effect Number
foreign import jsRound :: Number -> Number

-- ── Literals ──
anInt :: Int
anInt = 42

hex :: Int
hex = 0xFF

negative :: Int
negative = -7

aNumber :: Number
aNumber = 3.14

scientific :: Array Number
scientific = [ 1.0e10, 2.5e-3, 1e5 ]

aChar :: Char
aChar = 'x'

escapedChars :: Array Char
escapedChars = [ '\n', '\t', '\\', '\'', '\x41', 'é' ]

aString :: String
aString = "A string with \"quotes\", a newline\n, a tab\t, a unicode \x1F4E6, and a \
          \gap continuation."

rawString :: String
rawString = """A triple-quoted raw string with "quotes" and \n unescaped
spanning lines."""

aBool :: Boolean
aBool = true && not false || false

anArray :: Array Int
anArray = [ 1, 2, 3 ]

aRecord :: { sku :: String, qty :: Int }
aRecord = { sku: "AC-1001", qty: 25 }

-- ── Data types ──
data Status
  = Pending
  | Paid Number
  | Cancelled String

derive instance eqStatus :: Eq Status
derive instance ordStatus :: Ord Status
derive instance genericStatus :: Generic Status _

instance showStatus :: Show Status where
  show Pending = "Pending"
  show (Paid n) = "Paid " <> show n
  show (Cancelled r) = "Cancelled " <> show r

type Order =
  { number :: Int
  , total :: Number
  , status :: Status
  , tags :: Array String
  }

type Stock r = { sku :: String, qty :: Int | r }

newtype Sku = Sku String

derive instance newtypeSku :: Newtype Sku _
derive newtype instance eqSku :: Eq Sku
derive newtype instance ordSku :: Ord Sku

data Tree a = Leaf | Node (Tree a) a (Tree a)

data Proxy2 (a :: Type) = Proxy2

foreign import data Handle :: Type -> Type

-- ── Type classes ──
class Describe a where
  describe :: a -> String
  describeAll :: Array a -> Array String
  describeAll = map describe

class Container f where
  empty :: forall a. f a
  insert :: forall a. a -> f a -> f a

class (Eq a, Show a) <= Entity a where
  entityId :: a -> Int

class Convert a b | a -> b where
  convert :: a -> b

instance describeOrder :: Describe Order where
  describe o = "#" <> show o.number <> " " <> show o.status

instance describeInt :: Describe Int where
  describe = show

instance containerArray :: Container Array where
  empty = []
  insert = (:)

-- ── Functions ──
parseOrder :: String -> Maybe Order
parseOrder line = case split (Pattern ",") line of
  [ n, t, "paid" ] ->
    { number: _, total: _, status: Paid 0.0, tags: [] } <$> fromString n <*> Number.fromString t
  [ n, t, "pending" ] ->
    { number: _, total: _, status: Pending, tags: [] } <$> fromString n <*> Number.fromString t
  _ -> Nothing

revenue :: Array Order -> Number
revenue = sum <<< map _.total <<< filter (\o -> o.status == Paid 0.0)

compose2 :: forall a b c. (b -> c) -> (a -> b) -> a -> c
compose2 f g x = f (g x)

withConstraint :: forall a. Show a => Ord a => a -> a -> String
withConstraint a b
  | a < b = show a
  | a > b = show b
  | otherwise = "equal"

headOr :: forall a. a -> Array a -> a
headOr default arr = case Array.head arr of
  Just x -> x
  Nothing -> default

higherRank :: (forall a. a -> a) -> Tuple Int String
higherRank f = Tuple (f 1) (f "one")

infixr 5 append2 as +++
infixl 6 Tuple as /\
infix 4 eq as ===
infixr 0 apply as $$

append2 :: forall a. Semigroup a => a -> a -> a
append2 = (<>)

-- ── Operators and expressions ──
operators :: Int -> Int -> Boolean
operators x y =
  let
    a = x + y * 2 - 1
    b = x / 2
    c = x `mod` 3
    d = x `div` 3
    f = (_ + 1) <<< (_ * 2) >>> show
    g = [ 1, 2 ] <> [ 3 ]
    h = map (_ + 1) [ 1, 2, 3 ] # filter (_ > 1)
    i = a == b && c /= d || x < y
    j = (x >= y) == (x <= y)
    k = identity $ 5
  in
    i

-- ── Let, where, if, case, guards ──
classify :: Int -> String
classify n =
  if n < 0 then "negative"
  else if n == 0 then "zero"
  else "positive"

collatz :: Int -> Int
collatz n = go n 0
  where
  go 1 acc = acc
  go m acc
    | even m = go (m `div` 2) (acc + 1)
    | otherwise = go (3 * m + 1) (acc + 1)
  even k = k `mod` 2 == 0

caseGuards :: Maybe Int -> String
caseGuards m = case m of
  Just x | x > 100 -> "big"
         | x > 10 -> "medium"
  Just 0 -> "zero"
  Just _ -> "small"
  Nothing -> "none"

-- ── Records ──
updateQty :: Stock () -> Stock ()
updateQty s = s { qty = s.qty + 1 }

getSku :: forall r. { sku :: String | r } -> String
getSku { sku } = sku

nested :: { a :: { b :: Int } }
nested = { a: { b: 1 } }

nestedUpdate :: { a :: { b :: Int } } -> { a :: { b :: Int } }
nestedUpdate r = r { a { b = r.a.b + 1 } }

recordAccess :: Int
recordAccess = nested.a.b

-- ── Do notation, ado, monads ──
logOrders :: Array Order -> Effect Unit
logOrders orders = do
  log "orders:"
  for_ orders \o -> do
    log $ describe o
    logShow o.total
  let total = revenue orders
  log $ "total: " <> show total
  when (total > 100.0) $ log "large"
  unless (total > 100.0) do
    log "small"

safeDivide :: Int -> Int -> Either String Int
safeDivide _ 0 = Left "div by zero"
safeDivide a b = Right (a / b)

compute :: Either String Int
compute = do
  a <- safeDivide 10 2
  b <- safeDivide a 0
  pure (a + b)

adoExample :: Maybe { x :: Int, y :: Int }
adoExample = ado
  x <- Just 1
  y <- Just 2
  in { x, y }

counter :: State Int Int
counter = do
  n <- get
  put (n + 1)
  modify_ (_ * 2)
  pure n

asyncWork :: Aff Unit
asyncWork = do
  delay (Milliseconds 100.0)
  liftEffect $ log "done"

-- ── Type-level features ──
type Row1 = ( a :: Int, b :: String )
type Open r = ( c :: Boolean | r )

data Symbol' = Symbol'

kindSignature :: Proxy "label"
kindSignature = Proxy

typeOperator :: Int /\ String
typeOperator = 1 /\ "x"

class IsSymbol' (s :: Symbol) where
  reflect :: Proxy s -> String

foreign import data Fn :: Type -> Type -> Type

-- ── Type annotations and anonymous functions ──
lambda :: Int -> Int
lambda = \x -> x + 1

lambdaCase :: Maybe Int -> Int
lambdaCase = case _ of
  Just x -> x
  Nothing -> 0

annotated :: Int
annotated = (42 :: Int)

section :: Array Int
section = map (_ * 2) (1 .. 5)

-- ── Main ──
main :: Effect Unit
main = do
  let orders = mapMaybe parseOrder [ "1,120.5,paid", "2,42,pending", "x,y,z" ]
  log $ "revenue: " <> show (revenue orders)
  logOrders orders
