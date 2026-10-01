-- Idris 2 0.8 — syntax showcase
-- ── Comments ──
-- Idris 2: dependent types, totality, interfaces and effects for a warehouse model.
{- Block comment {- nested block comment -} still inside.
   TODO: split into modules. FIXME: proof of associativity. -}
||| Documentation comment for the module.
||| Supports multiple lines.
module Sample

-- ── Imports ──
import Data.Vect
import Data.List
import Data.List.Elem
import Data.Maybe
import Data.Nat
import Data.String
import Data.Fin
import Decidable.Equality
import System
import public Data.So
import Control.Monad.State as S

-- ── Pragmas and directives ──
%default total
%language ElabReflection
%hide Prelude.lookup
%name Vec xs, ys, zs
%auto_implicit_depth 0
%unbound_implicits off
%default total
%ambiguity_depth 5
%foreign "C:puts,libc"
prim__puts : String -> PrimIO ()
%inline
double : Nat -> Nat
double n = n + n

-- ── Literals ──
integer : Integer
integer = 42

negative : Integer
negative = -17

hexNum : Int
hexNum = 0xFF

octNum : Int
octNum = 0o755

binNum : Int
binNum = 0b1010

big : Integer
big = 1_000_000

floating : Double
floating = 3.14

expo : Double
expo = 6.02e23

negExpo : Double
negExpo = 1.5e-3

char1 : Char
char1 = 'a'

char2 : List Char
char2 = ['\n', '\t', '\\', '\'', '\x41', '\65', '\o101', '\NUL', '\DEL', '\u00e9']

str1 : String
str1 = "double \"quoted\" with \\ backslash, \t tab, \x41 hex, \1234 decimal, \u00e9"

multiline : String
multiline = """
  Multi-line string literal
    keeps relative indentation.
  """

rawStr : String
rawStr = #"raw \n string with "quotes""#

interp : String -> String
interp name = "Hello, \{name}! Total: \{show (1 + 2)}"

unitVal : ()
unitVal = ()

boolVals : List Bool
boolVals = [True, False]

-- ── Data types ──
||| A vector whose length is known at the type level.
data Vec : Nat -> Type -> Type where
  Nil  : Vec Z a
  (::) : a -> Vec n a -> Vec (S n) a

data Status = Pending | Paid | Cancelled String

data Tree a = Leaf | Node (Tree a) a (Tree a)

data Expr : Type -> Type where
  IntE  : Int -> Expr Int
  BoolE : Bool -> Expr Bool
  Add   : Expr Int -> Expr Int -> Expr Int
  If    : Expr Bool -> Expr a -> Expr a -> Expr a

data Elem' : a -> List a -> Type where
  Here  : Elem' x (x :: xs)
  There : Elem' x xs -> Elem' x (y :: xs)

public export
data Shape : Type where
  Circle : (radius : Double) -> Shape
  Rect   : (w, h : Double) -> Shape

export
data Opaque = MkOpaque Nat

record Order where
  constructor MkOrder
  number : Nat
  total  : Double
  status : Status

record Point (a : Type) where
  constructor MkPoint
  x, y : a

mutual
  data Even' : Nat -> Type where
    EZ : Even' Z
    ES : Odd' n -> Even' (S n)
  data Odd' : Nat -> Type where
    OS : Even' n -> Odd' (S n)

namespace Geometry
  public export
  area : Shape -> Double
  area (Circle r) = pi * r * r
  area (Rect w h) = w * h

-- ── Interfaces and implementations ──
interface Describable a where
  describe : a -> String
  describe _ = "thing"
  name : a -> String

interface Eq a => Container f a where
  empty : f a
  insert : a -> f a -> f a

implementation Describable Status where
  describe Pending = "pending"
  describe Paid = "paid"
  describe (Cancelled reason) = "cancelled: " ++ reason
  name = describe

Describable Bool where
  name True = "yes"
  name False = "no"

[named] Describable Nat where
  name n = show n

Show Status where
  show = describe

Functor Tree where
  map f Leaf = Leaf
  map f (Node l x r) = Node (map f l) (f x) (map f r)

-- ── Functions: signatures, clauses, with, case, let, where ──
||| The first element; the type rules out an empty vector.
head : Vec (S n) a -> a
head (x :: _) = x

||| Append with the lengths added in the type.
append : Vec n a -> Vec m a -> Vec (n + m) a
append Nil ys = ys
append (x :: xs) ys = x :: append xs ys

total
sumVec : Num a => Vec n a -> a
sumVec Nil = 0
sumVec (x :: xs) = x + sumVec xs

partial
unsafeHead : List a -> a
unsafeHead (x :: _) = x

covering
lookupSku : String -> List (String, Nat) -> Maybe Nat
lookupSku _ [] = Nothing
lookupSku k ((k', v) :: rest) = if k == k' then Just v else lookupSku k rest

classify : Int -> String
classify n =
  if n < 0 then "negative"
  else if n == 0 then "zero"
  else "positive"

caseExample : Maybe Nat -> String
caseExample m = case m of
  Nothing => "none"
  Just 0 => "zero"
  Just (S k) => "succ of " ++ show k

withExample : (n : Nat) -> String
withExample n with (n `mod` 2)
  withExample n | 0 = "even"
  withExample n | _ = "odd"

letExample : Nat -> Nat
letExample x =
  let y = x + 1
      z = y * 2
  in z + y

whereExample : Nat -> Nat
whereExample n = go n 0
  where
    go : Nat -> Nat -> Nat
    go Z acc = acc
    go (S k) acc = go k (acc + 1)

lambdas : List Nat
lambdas = map (\x => x * 2) (filter (\x => x > 1) [1, 2, 3])

lambdaCase : Maybe Nat -> Nat
lambdaCase = \case
  Nothing => 0
  Just n => n

pairs : List (Nat, String)
pairs = [(1, "a"), (2, "b")]

dependentPair : (n : Nat ** Vec n Int)
dependentPair = (2 ** [1, 2])

implicitArgs : {n : Nat} -> {auto prf : IsSucc n} -> Vec n a -> a
implicitArgs {n = S _} (x :: _) = x

linear : (1 x : a) -> a
linear x = x

quantity0 : (0 a : Type) -> a -> a
quantity0 _ x = x

-- ── Operators and fixity ──
infixl 6 |+|
(|+|) : Nat -> Nat -> Nat
a |+| b = a + b

infixr 5 +++
(+++) : List a -> List a -> List a
xs +++ ys = xs ++ ys

prefix 9 !!!
(!!!) : Nat -> Nat
(!!!) n = n

operators : Bool
operators =
  (1 + 2 - 3 * 4 `div` 2 == 3) && (5 `mod` 2 /= 0 || not False)
  && (1 < 2) && (2 <= 3) && (3 > 2) && (3 >= 3)

ranges : List Nat
ranges = [1 .. 10] ++ [1, 3 .. 9]

comprehension : List Nat
comprehension = [x * x | x <- [1 .. 10], x `mod` 2 == 0]

-- ── Do-notation, IO, bang ──
readName : IO String
readName = do
  putStrLn "Name?"
  name <- getLine
  let greeting = "Hello, " ++ name
  putStrLn greeting
  pure name

bangExample : IO ()
bangExample = putStrLn ("Value: " ++ show !(pure 42))

idiom : Maybe Nat
idiom = [| (+) (Just 1) (Just 2) |]

-- ── Proofs, rewrite, with, holes ──
plusZero : (n : Nat) -> n + 0 = n
plusZero Z = Refl
plusZero (S k) = cong S (plusZero k)

proof : (a, b : Nat) -> a + b = b + a
proof a b = rewrite plusCommutative a b in Refl

hole : Nat
hole = ?todo_hole

decEqExample : (a, b : Nat) -> Dec (a = b)
decEqExample a b = decEq a b

soExample : So (1 < 2)
soExample = Oh

example : Vec 3 Int
example = 1 :: 2 :: 3 :: Nil

-- ── Elaboration, syntax, parameters ──
parameters (n : Nat)
  addN : Nat -> Nat
  addN m = n + m

syntax "unless" [c] [t] = if c then () else t


-- ── Visibility modifiers and totality annotations ──
public export
record Config where
  constructor MkConfig
  name : String
  retries : Nat

export
privateHelper : Nat -> Nat
privateHelper = S

private
hidden : Nat
hidden = 0

public export total
exportedTotal : Nat -> Nat
exportedTotal n = n

export covering
exportedCovering : List Nat -> Nat
exportedCovering [] = 0
exportedCovering (x :: xs) = x + exportedCovering xs

-- ── Record update, projection and pattern ──
updateName : Config -> Config
updateName c = { name := "new" } c

modifyRetries : Config -> Config
modifyRetries c = { retries $= S } c

nested : Config -> String
nested c = c.name ++ show c.retries

configPattern : Config -> Nat
configPattern (MkConfig n r) = r

-- ── Laziness, infinite data and streams ──
data Stream' : Type -> Type where
  (:::) : a -> Inf (Stream' a) -> Stream' a

ones : Stream' Nat
ones = 1 ::: ones

lazyValue : Lazy Nat
lazyValue = Delay (1 + 2)

forced : Nat
forced = Force lazyValue

takeStream : Nat -> Stream' a -> List a
takeStream Z _ = []
takeStream (S k) (x ::: xs) = x :: takeStream k xs

-- ── Impossible clauses, absurd, void ──
data Empty : Type where

noEmpty : Empty -> a
noEmpty x impossible

voidElim : Void -> a
voidElim v = absurd v

headEmpty : Vec Z a -> Void
headEmpty Nil impossible

-- ── Auto, default and named implicit arguments ──
safeIndex : (xs : List a) -> (i : Nat) -> {auto prf : InBounds i xs} -> a
safeIndex xs i = index i xs

withDefault : {default 5 n : Nat} -> Nat
withDefault = n

namedImplicit : {a : Type} -> {n : Nat} -> Vec n a -> Nat
namedImplicit {n} _ = n

useNamed : Nat
useNamed = namedImplicit {a = Nat} {n = 2} [1, 2]

-- ── Hints, aliases, ranges of syntax ──
%hint
natEqHint : (a : Nat) -> a = a
natEqHint a = Refl

%defaulthint
defHint : Nat
defHint = 0

%tcinline
inlineMe : Nat -> Nat
inlineMe = id

%unsafe
unsafeCast : a -> b
unsafeCast = believe_me

-- ── Reflection and elaboration ──
quoted : Elab Unit
quoted = do
  let q = `(Nat)
  let n = `{{Prelude.Nat}}
  declare `[ foo : Nat
             foo = 1 ]
  pure ()

%runElab quoted

-- ── Forall, type-level functions, universe levels ──
idForall : forall a. a -> a
idForall x = x

typeFn : Bool -> Type
typeFn True = Nat
typeFn False = String

dependent : (b : Bool) -> typeFn b
dependent True = 5
dependent False = "five"

universe : Type -> Type
universe a = a

-- ── Interfaces: constraints, defaults, using ──
interface Monoid' a where
  neutral : a
  combine : a -> a -> a

interface (Monoid' a) => Group' a where
  inverse : a -> a

implementation Monoid' Nat where
  neutral = 0
  combine = (+)

[sumMonoid] Monoid' Nat where
  neutral = 0
  combine = (+)

[prodMonoid] Monoid' Nat where
  neutral = 1
  combine = (*)

useNamedImpl : Nat
useNamedImpl = combine @{prodMonoid} 2 3

-- ── Operators: bind, let, if-then-else forms ──
(>>>) : (a -> b) -> (b -> c) -> a -> c
(>>>) f g = g . f

infixl 3 >>>

(<?>) : Maybe a -> a -> a
(<?>) (Just x) _ = x
(<?>) Nothing d = d

letPattern : (Nat, Nat) -> Nat
letPattern p =
  let (a, b) = p
      c = a + b
   in c * 2

ifThenElse : Bool -> Nat
ifThenElse b = if b then 1 else 0

caseWithBinder : List Nat -> Nat
caseWithBinder xs = case xs of
  [] => 0
  [x] => x
  (x :: y :: _) => x + y

lambdaMulti : Nat -> Nat -> Nat
lambdaMulti = \a, b => a + b

lambdaPattern : (Nat, Nat) -> Nat
lambdaPattern = \(a, b) => a + b

asPatterns : List Nat -> List Nat
asPatterns xs@(x :: _) = x :: xs
asPatterns [] = []

-- ── Module-level IO with exceptions and ranges ──
rangeExample : List Nat
rangeExample = [1 .. 5] ++ [10, 8 .. 0]

charOps : List Char
charOps = ['a' .. 'e']

stringOps : String
stringOps = "a" ++ "b" ++ pack ['c', 'd'] ++ show 12 ++ cast 3.5

mainIO : IO ()
mainIO = do
  putStrLn "Hello"
  Right line <- pure (Right "x")
    | Left err => putStrLn err
  let n = length line
  when (n > 0) $ putStrLn "non-empty"
  traverse_ putStrLn ["a", "b"]
  Just v <- pure (Just 1)
    | Nothing => pure ()
  printLn v

main : IO ()
main = printLn (head example, sumVec (append example example))

-- ── Quantities, snoc lists, operator sections, projections ──
erased : (0 n : Nat) -> (1 v : Vec n Nat) -> Nat
erased _ v = 0

snoc : SnocList Nat
snoc = [<1, 2, 3]

snocCons : SnocList Nat
snocCons = Lin :< 1 :< 2

sections : List Nat
sections = map (+ 1) [1, 2] ++ map (`div` 2) [4, 6] ++ map (2 *) [1, 2] ++ map (\x => x - 1) [3]

projection : List String
projection = map (.name) [MkConfig "a" 1, MkConfig "b" 2]

namedArgs : Nat
namedArgs = namedImplicit {a = Nat} {n = 1} [0]

-- ── Pragmas: foreign, export, deprecate, transform, logging ──
%foreign "C:strlen,libc" "scheme:string-length" "javascript:lambda:s => s.length"
prim__strlen : String -> Int

%export "C:my_add"
myAdd : Int -> Int -> Int
myAdd = (+)

%deprecate
oldFunction : Nat -> Nat
oldFunction = id

%noinline
neverInline : Nat -> Nat
neverInline = S

%logging "elab" 5
%search_timeout 1000
%default covering
%default total

-- ── Autobind, records with parameters, interface parameters, data with options ──
record Wrapper (a : Type) where
  constructor MkWrapper
  unwrap : a
  count : Nat

data Result : Type -> Type -> Type where
  Ok : (value : a) -> Result e a
  Err : (error : e) -> Result e a

interface Show a => Pretty a where
  pretty : a -> String
  pretty = show

[viaShow] Pretty Nat where

implementation Pretty Bool where
  pretty True = "yes"
  pretty False = "no"

-- ── List comprehension with multiple generators, if-then-else in do, rewrite and with ──
triples : List (Nat, Nat, Nat)
triples = [(a, b, c) | c <- [1 .. 20], b <- [1 .. c], a <- [1 .. b], a * a + b * b == c * c]

unlessDo : IO ()
unlessDo = do
  let x = 5
  if x > 3
     then putStrLn "big"
     else putStrLn "small"
  unless (x > 10) $ putStrLn "not huge"

withProof : (xs : List Nat) -> String
withProof xs with (length xs) proof eq
  withProof xs | Z = "empty"
  withProof xs | (S _) = "non-empty"

-- Non-ASCII: café 日本語 ☕

