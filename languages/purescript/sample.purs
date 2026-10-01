-- PureScript 0.15 — syntax showcase
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

-- ── Kind signatures, roles, and standalone declarations ──
data Pair :: Type -> Type -> Type
data Pair a b = Pair a b

newtype Wrapper :: Type -> Type
newtype Wrapper a = Wrapper a

type Fn2 :: Type -> Type -> Type
type Fn2 a b = a -> b

class Monoid2 :: Type -> Constraint
class Monoid2 a where
  mempty2 :: a

type role Ref nominal
data Ref a

foreign import data Fx :: (Type -> Type) -> Type

data Rec (r :: Row Type) = Rec
data HKT (f :: Type -> Type) a = HKT (f a)
data Phantom (n :: Symbol) = Phantom
data Void'

-- ── Unicode syntax ──
unicodeId :: ∀ a. a → a
unicodeId x = x

unicodeConstraint :: ∀ a. Show a ⇒ a → String
unicodeConstraint = show

-- ── Instance chains, deriving, overlapping resolution ──
class TypeName a where
  typeName :: Proxy a -> String

instance typeNameInt :: TypeName Int where
  typeName _ = "Int"
else instance typeNameString :: TypeName String where
  typeName _ = "String"
else instance typeNameOther :: TypeName a where
  typeName _ = "other"

derive instance functorTree :: Functor Tree
derive instance eqTree :: Eq a => Eq (Tree a)
derive newtype instance showSku :: Show Sku
derive instance ordPair :: (Ord a, Ord b) => Ord (Pair a b)

instance showTree :: Show a => Show (Tree a) where
  show Leaf = "Leaf"
  show (Node l v r) = "(Node " <> show l <> " " <> show v <> " " <> show r <> ")"

instance semigroupTree :: Semigroup (Tree a) where
  append l _ = l

instance foldableTree :: Foldable Tree where
  foldr _ z Leaf = z
  foldr f z (Node l v r) = foldr f (f v (foldr f z r)) l
  foldl _ z Leaf = z
  foldl f z (Node l v r) = foldl f (f (foldl f z l) v) r
  foldMap _ Leaf = mempty
  foldMap f (Node l v r) = foldMap f l <> f v <> foldMap f r

instance emptyClass :: Container Maybe

-- ── Operators: definitions, type operators, sections ──
infixl 6 add as +++
infixr 5 type Tuple as ⨯
infix 4 type Eq as ~
infixl 1 bindFlipped as =<<<
infixr 9 compose as ∘

opSections :: Array Int
opSections = [ (_ + 1) 1, (1 + _) 2, (_ `mod` 2) 3, (negate <<< _) 4, (_ <> _) [] [] # length ]
  where
  length = Array.length

-- ── Patterns: every kind ──
patterns :: Maybe Int -> Array Int -> String -> Number -> Char -> { a :: Int } -> String
patterns (Just n) [ x, y ] "lit" 1.5 'c' { a: 1 } = show (n + x + y)
patterns whole@(Just (-1)) [] _ _ _ _ = "neg"
patterns Nothing [ _ ] "" 0.0 '\n' { a } = show a
patterns _ _ _ _ _ _ = "other"

multiScrutinee :: Int -> Int -> String
multiScrutinee a b = case a, b of
  0, 0 -> "both zero"
  0, _ -> "first zero"
  _, 0 -> "second zero"
  x, y | x == y -> "equal"
       | Just z <- Array.head [ x ], z > 0 -> "positive head"
       | otherwise -> "different"

negativeLits :: Int -> Int
negativeLits (-1) = 0
negativeLits n = n

-- ── Visible type application, wildcards, holes ──
visible :: String
visible = show @Int 1

typeAppMany :: Proxy "x"
typeAppMany = identity @(Proxy "x") Proxy

anyType :: _ -> Int
anyType x = 1

-- ── Row polymorphism and record syntax forms ──
type Person = { name :: String, age :: Int }
type Named r = { name :: String | r }
type Rows = ( x :: Int, "quoted label" :: String )

mkPerson :: String -> Int -> Person
mkPerson name age = { name, age }

modify :: Person -> Person
modify p = p { age = p.age + 1, name = "x" }

quotedLabel :: { "quoted label" :: Int } -> Int
quotedLabel r = r."quoted label"

sectionAccess :: Array Person -> Array String
sectionAccess = map _.name

sectionUpdate :: Array Person -> Array Person
sectionUpdate = map _ { age = 0 }

emptyRecord :: {}
emptyRecord = {}

emptyRow :: Record ()
emptyRow = {}

-- ── Qualified do, ado, let in do ──
qualifiedDo :: Maybe Int
qualifiedDo = Ix.do
  a <- Just 1
  Just (a + 1)

letInDo :: Effect Unit
letInDo = do
  let
    a = 1
    b = 2
    f x = x + a
  let c = f b
  _ <- pure c
  void $ pure a
  if a > b then log "gt" else log "le"
  case a of
    1 -> log "one"
    _ -> log "other"

-- ── Numeric and string literal forms ──
numericForms :: Array Number
numericForms = [ 0.5, 1.0, 1e3, 1.5e-3, 123_456.789_0, 0x1F # toNumber, 0b101 # toNumber ]

charForms :: Array Char
charForms = [ 'a', '\t', '\\', '\'', '\"', '\x0041', '\x1F4E6' ]

stringGap :: String
stringGap = "line one \
            \line two"

-- ── Where, guards, and local operators ──
localOps :: Int -> Int
localOps x = x <+> 1
  where
  infixl 6 add as <+>

guardsInLet :: Int -> String
guardsInLet n =
  let
    go k
      | k > 0 = "pos"
      | k < 0 = "neg"
      | otherwise = "zero"
  in
    go n

-- ── Main ──
main :: Effect Unit
main = do
  let orders = mapMaybe parseOrder [ "1,120.5,paid", "2,42,pending", "x,y,z" ]
  log $ "revenue: " <> show (revenue orders)
  logOrders orders
