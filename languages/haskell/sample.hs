-- Haskell (GHC 9.12, GHC2024 language edition) — syntax showcase
{-# LANGUAGE GHC2024 #-}
{-# LANGUAGE OrPatterns, MultilineStrings, NamedDefaults, RequiredTypeArguments, TypeAbstractions #-}
{-# LANGUAGE ExtendedLiterals, TypeData, LinearTypes, OverloadedLabels, OverloadedRecordDot #-}
{-# LANGUAGE QuantifiedConstraints, ImpredicativeTypes, LexicalNegation, HexFloatLiterals, NegativeLiterals #-}
{-# LANGUAGE ApplicativeDo, StrictData, UnliftedNewtypes, StaticPointers, Safe #-}
{-# LANGUAGE LambdaCase, BinaryLiterals, NumericUnderscores #-}
{-# LANGUAGE ScopedTypeVariables, TupleSections #-}
{-# LANGUAGE GADTs, KindSignatures, RankNTypes #-}
{-# LANGUAGE TypeFamilies, MultiParamTypeClasses, FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings, DerivingStrategies, DeriveFunctor, DeriveGeneric #-}
{-# LANGUAGE RecordWildCards, NamedFieldPuns, BangPatterns, MultiWayIf #-}
{-# LANGUAGE PatternSynonyms, ViewPatterns, TemplateHaskell, QuasiQuotes #-}
{-# LANGUAGE DataKinds, PolyKinds, TypeApplications, FunctionalDependencies, DefaultSignatures #-}
{-# LANGUAGE MagicHash, UnboxedTuples, Arrows, RecursiveDo, ForeignFunctionInterface #-}
{-# LANGUAGE DerivingVia, StandaloneDeriving, GeneralizedNewtypeDeriving, DeriveAnyClass #-}
{-# LANGUAGE ImportQualifiedPost, ParallelListComp, MonadComprehensions, ExistentialQuantification #-}
{-# LANGUAGE StandaloneKindSignatures, EmptyCase, InstanceSigs, BlockArguments, UnicodeSyntax #-}
{-# LANGUAGE PartialTypeSignatures, TypeOperators, ConstraintKinds, ImplicitParams, CPP #-}
{-# OPTIONS_GHC -Wall -Wno-unused-imports -Wno-partial-type-signatures #-}
-- ── Comments ──
-- Haskell: a typed inventory pipeline with every syntactic category.
{- Block comment {- nested block comment -} still inside.
   TODO: split into modules. FIXME: rounding. -}
-- | Haddock documentation comment for the module.
-- Supports @code@, /emphasis/, __bold__, 'Identifier' links and "Module.Name" links.
--
-- * bullet item
-- * another item
--
-- >>> 1 + 2
-- 3
module Sample
  ( Order (..)
  , Status (Pending, Paid)
  , parseOrder
  , revenue
  , Shape (..)
  , main
  ) where

import Control.Exception (SomeException, catch, evaluate, throwIO, try)
import Control.Monad (forM_, unless, when, (>=>))
import Data.Char (isDigit, toUpper)
import Data.IORef
import Data.List (foldl', sortBy, sortOn)
import qualified Data.Map.Strict as Map
import Data.Maybe (fromMaybe, mapMaybe)
import Data.Ord (comparing)
import qualified Data.Text as T
import Text.Printf (printf)
import Text.Read (readMaybe)
import Prelude hiding (lookup)

-- ── Types: data, newtype, type synonym, records ──
type Name = String
type Table k v = Map.Map k v

newtype Sku = Sku {unSku :: String}
  deriving stock (Show, Eq, Ord)

data Status = Pending | Paid | Cancelled String
  deriving (Show, Eq)

data Order = Order
  { number :: !Int
  , total :: Double
  , status :: Status
  } deriving (Show)

data Shape
  = Circle {radius :: Double}
  | Rect Double Double
  | Triangle Double Double Double
  deriving (Show, Eq, Ord)

data Tree a = Leaf | Node (Tree a) a (Tree a)
  deriving (Show, Functor)

infixr 5 :+:
data Expr = Lit Int | Expr :+: Expr | Neg Expr

-- GADT with kind signature
data Term :: * -> * where
  IntT :: Int -> Term Int
  BoolT :: Bool -> Term Bool
  If :: Term Bool -> Term a -> Term a -> Term a

-- ── Type classes and instances ──
class Describable a where
  describe :: a -> String
  describe _ = "thing"
  name' :: a -> String
  {-# MINIMAL name' #-}

class (Eq a, Show a) => Entity a where
  entityId :: a -> Int

class Container f where
  empty :: f a
  insert :: a -> f a -> f a

instance Describable Status where
  describe Pending = "pending"
  describe Paid = "paid"
  describe (Cancelled r) = "cancelled: " ++ r
  name' = show

instance Describable Order where
  name' Order {number} = "order-" ++ show number

instance Semigroup Sku where
  Sku a <> Sku b = Sku (a ++ b)

instance Monoid Sku where
  mempty = Sku ""

-- Type families
type family Elem c where
  Elem [a] = a

class Collection c where
  type Item c
  toL :: c -> [Item c]

-- ── Literals ──
integers :: [Integer]
integers = [42, 0xFF, 0XAB, 0o755, 0b1010, 1_000_000, -7]

floats :: [Double]
floats = [3.14, 6.02e23, 1.5E-3]

characters :: [Char]
characters = ['a', '\n', '\t', '\\', '\'', '\x41', '\o101', '\65', '\NUL', '\DEL', '\^A', '\1234']

strings :: [String]
strings =
  [ "plain \"quoted\" \\ \t tab \1234 \x41 \o101 \NUL \SOH"
  , "multi\
    \line gap"
  , "unicode: café 日本語 ☕"
  ]

-- ── Functions ──
parseOrder :: String -> Maybe Order
parseOrder line = case words line of
  [n, t, "paid"] -> Order <$> readMaybe n <*> readMaybe t <*> pure Paid
  [n, t, "pending"] -> Order <$> readMaybe n <*> readMaybe t <*> pure Pending
  _ -> Nothing

revenue :: [Order] -> Double
revenue = sum . map total . filter ((== Paid) . status)

area :: Shape -> Double
area (Circle r) = pi * r ^ (2 :: Int)
area (Rect w h) = w * h
area (Triangle a b c) =
  let s = (a + b + c) / 2
   in sqrt (s * (s - a) * (s - b) * (s - c))

classify :: Int -> String
classify n
  | n < 0 = "negative"
  | n == 0 = "zero"
  | n < 10, even n = "small even"
  | Just m <- lookup' n = m
  | otherwise = "large"
  where
    lookup' k = Map.lookup k table
    table = Map.fromList [(11, "eleven"), (12, "twelve")]

describeAll :: [Order] -> [String]
describeAll orders = [describe (status o) | o <- orders, total o > 0, let t = total o, t < 1e6]

-- Lambda, operator sections, composition
transforms :: [Int]
transforms = map (\x -> x * 2) . filter (> 3) . map (subtract 1) $ [1 .. 10]

lambdaCase :: Maybe Int -> String
lambdaCase = \case
  Nothing -> "none"
  Just n | n > 0 -> "positive"
         | otherwise -> "other"

multiIf :: Int -> String
multiIf n = if | n < 0 -> "neg"
               | n > 0 -> "pos"
               | otherwise -> "zero"

-- Operators
infixl 6 |+|
(|+|) :: Int -> Int -> Int
a |+| b = a + b

ops :: Bool
ops = (1 + 2 - 3 * 4) `div` 2 == 3 && (5 `mod` 2 /= 0 || not False)
  && (1 < 2) && (2 <= 3) && (3 > 2) && (3 >= 3)

lists :: ([Int], [Int], [(Int, Char)], [Int])
lists = ([1, 2, 3] ++ [4], 0 : [1, 2], zip [1 ..] "abc", [x | x <- [1 .. 20], odd x, x `mod` 3 == 0])

ranges :: [[Int]]
ranges = [[1 .. 5], [1, 3 .. 9], [10, 8 .. 0], take 3 [1 ..]]

tuples :: (Int, String, Bool)
tuples = (1, "two", True)

-- ── Do-notation, monads, IO ──
main :: IO ()
main = do
  let orders = [o | Just o <- map parseOrder ["1 120.5 paid", "2 42 pending", "x y z"]]
      byStatus = Map.fromListWith (+) [(show (status o), 1 :: Int) | o <- orders]
  ref <- newIORef (0 :: Int)
  forM_ orders $ \o -> do
    modifyIORef' ref (+ 1)
    printf "%d %.2f\n" (number o) (total o)
  count <- readIORef ref
  when (count > 1) $ putStrLn "many"
  unless (count > 5) $
    putStrLn "few"
  result <- try (evaluate (1 `div` 0 :: Int)) :: IO (Either SomeException Int)
  case result of
    Left err -> putStrLn ("error: " ++ show err)
    Right v -> print v
  mapM_ print (sortOn number orders)
  putStrLn $ "revenue: " ++ show (revenue orders) ++ " " ++ show byStatus
  let go !acc [] = acc
      go !acc (x : xs) = go (acc + x) xs
  print (go 0 [1 .. 100 :: Int])
  where
    _unused = ()

-- Maybe and Either monads, where clauses, guards in case
safeDiv :: Int -> Int -> Either String Int
safeDiv _ 0 = Left "divide by zero"
safeDiv a b = Right (a `div` b)

pipeline :: Int -> Either String Int
pipeline x = do
  a <- safeDiv 100 x
  b <- safeDiv a 2
  return (a + b)

-- Records: wildcards, puns, update
render :: Order -> String
render Order {..} = show number ++ ": " ++ show total

bump :: Order -> Order
bump o = o {total = total o * 1.1}

-- Type annotations: forall, constraints, higher-rank
applyAll :: forall a. (Show a, Ord a) => [a] -> String
applyAll = concatMap show . sortBy (comparing id)

rank2 :: (forall a. a -> a) -> (Int, Bool)
rank2 f = (f 1, f True)

-- Foreign, pragmas, inline
{-# INLINE area #-}
{-# NOINLINE classify #-}
{-# SPECIALIZE revenue :: [Order] -> Double #-}
{-# DEPRECATED oldRevenue "Use revenue" #-}
oldRevenue :: [Order] -> Double
oldRevenue = revenue

-- Template-style quasi quotes and Typed holes are not included; Arrows and proc omitted.
-- Non-ASCII: ¡Hola! 你好 こんにちは

-- ── Imports in every form ──
import Data.Map.Strict qualified as M
import Data.Set (Set, (\\), member)
import {-# SOURCE #-} Data.Kind (Type, Constraint)
import safe Data.Functor ((<&>), ($>))
import "base" Data.Foldable (for_, traverse_)
import GHC.Exts (Int (I#), (+#))
import Foreign.C.Types (CInt (..))

-- ── Pragmas of every kind ──
{-# ANN module "HLint: ignore" #-}
{-# ANN number "annotation" #-}
{-# RULES "map/map" forall f g xs. map f (map g xs) = map (f . g) xs #-}
{-# INLINABLE sumAll #-}
{-# INLINE [1] stage1 #-}
{-# NOINLINE [~1] stage2 #-}
{-# OPAQUE opaqueFn #-}
{-# SPECIALISE sumAll :: [Int] -> Int #-}
{-# COMPLETE Zero, Succ #-}
{-# WARNING unsafeThing "Do not use" #-}
{-# LINE 42 "Generated.hs" #-}
{-# COLUMN 1 #-}

sumAll :: Num a => [a] -> a
sumAll = foldl' (+) 0

stage1, stage2, opaqueFn :: Int -> Int
stage1 = (+ 1)
stage2 = (* 2)
opaqueFn = id

unsafeThing :: Int
unsafeThing = {-# SCC "unsafe" #-} 0

-- ── Pattern synonyms, view patterns, bang and lazy patterns ──
pattern Zero :: Int
pattern Zero = 0

pattern Succ :: Int -> Int
pattern Succ n <- (predMaybe -> Just n) where
  Succ n = n + 1

predMaybe :: Int -> Maybe Int
predMaybe n | n > 0 = Just (n - 1) | otherwise = Nothing

pattern Head :: a -> [a]
pattern Head x <- x : _

viewPat :: [Int] -> Int
viewPat (length -> n) = n

asPattern :: [Int] -> [Int]
asPattern all'@(x : _) = x : all'
asPattern [] = []

lazyPat :: (Int, Int) -> Int
lazyPat ~(a, _) = a

strictPat :: Int -> Int
strictPat !x = x + 1

nPlusK :: Int -> Int
nPlusK 0 = 0
nPlusK n = n

wildcards :: Maybe Int -> Int
wildcards (Just _) = 1
wildcards Nothing = 0

-- ── Type-level programming ──
type Nat' :: Type
data Nat' = Z | S Nat'

type Vec :: Nat' -> Type -> Type
data Vec n a where
  VNil :: Vec 'Z a
  VCons :: a -> Vec n a -> Vec ('S n) a

type family Plus (a :: Nat') (b :: Nat') :: Nat' where
  Plus 'Z b = b
  Plus ('S a) b = 'S (Plus a b)

type family F a = r | r -> a
data family DF a
data instance DF Int = DFInt Int
newtype instance DF Bool = DFBool Bool

type role Ptr' representational
data Ptr' a = Ptr' Int

type Showy a = (Show a, Eq a)
type List' = '[Int, Bool, String]
type Tuple' = '(Int, Bool)
type Symbolic = "a type-level string"
type Numeric = 42

class Monad m => MonadLogger m where
  logMsg :: String -> m ()
  default logMsg :: (m ~ IO) => String -> m ()
  logMsg = putStrLn

class Convert a b | a -> b where
  convert :: a -> b

instance {-# OVERLAPPING #-} Convert Int String where convert = show
instance {-# OVERLAPPABLE #-} Convert a a where convert = id
instance {-# INCOHERENT #-} Convert Bool Int where convert b = if b then 1 else 0

data Showable = forall a. Show a => MkShowable a
data Some (c :: Type -> Constraint) = forall a. c a => Some a

-- ── Deriving: strategies, via, anyclass, standalone ──
newtype Age = Age Int
  deriving newtype (Show, Eq, Ord, Num)
  deriving stock (Read)

newtype Total = Total Int
  deriving (Semigroup, Monoid) via (Sum' Int)

newtype Sum' a = Sum' a
instance Num a => Semigroup (Sum' a) where Sum' a <> Sum' b = Sum' (a + b)
instance Num a => Monoid (Sum' a) where mempty = Sum' 0

deriving instance Show Showable' => Show (Wrapper' Showable')
data Showable' = Showable'
data Wrapper' a = Wrapper' a

-- ── Records: dot syntax, update, puns, wildcards ──
data Person = Person {name :: String, age :: Int}

describePerson :: Person -> String
describePerson p = p.name ++ " " ++ show p.age

olderPerson :: Person -> Person
olderPerson p = p {age = p.age + 1}

-- ── Template Haskell and quasi-quotes ──
thSplice :: Int
thSplice = $(litE (integerL 42))

thQuote :: Q Exp
thQuote = [| 1 + 2 |]

thTypedQuote :: Code Q Int
thTypedQuote = [|| 1 + 2 ||]

thDecs :: Q [Dec]
thDecs = [d| helper :: Int; helper = 1 |]

thType :: Q Type
thType = [t| Maybe Int |]

thPat :: Q Pat
thPat = [p| (x, y) |]

thName :: Name
thName = 'map

thTypeName :: Name
thTypeName = ''Maybe

quasi :: String
quasi = [str|multi
line quasi quote|]

$(return [])

-- ── Arrows, mdo, rec ──
addA :: Arrow a => a b Int -> a b Int -> a b Int
addA f g = proc x -> do
  y <- f -< x
  z <- g -< x
  returnA -< y + z

mdoExample :: IO [Int]
mdoExample = mdo
  xs <- return (1 : map (* 2) ys)
  ys <- return (take 3 xs)
  return ys

recExample :: IO Int
recExample = do
  rec let a = b + 1
      b <- return 1
  return a

-- ── Unboxed, MagicHash and FFI ──
foreign import ccall unsafe "math.h sin" c_sin :: Double -> Double
foreign import ccall "wrapper" mkCallback :: (Int -> IO ()) -> IO (FunPtr (Int -> IO ()))
foreign export ccall exported :: Int -> Int

exported :: Int -> Int
exported = (+ 1)

unboxed :: Int -> (# Int, Int #)
unboxed x = (# x, x #)

magic :: Int
magic = I# (1# +# 2#)

magicLits :: (Char, Double, Word)
magicLits = ('a'#, 1.5##, 3##) `seq` ('x', 1.5, 3)

-- ── Operators, sections, backticks, numeric literals ──
infix 4 ===
(===) :: Eq a => a -> a -> Bool
(===) = (==)

infixl 1 &&&&
(&&&&) :: Bool -> Bool -> Bool
a &&&& b = a && b

sections :: [Int]
sections = [(+ 1) 1, (1 +) 1, (subtract 1) 1, (`div` 2) 10, (10 `div`) 2, negate 1, (- 1)]

unicodeSyntax :: ∀ a. Show a ⇒ a → String
unicodeSyntax = show

numericForms :: [Double]
numericForms = [1e3, 1.5e-3, 0xFF, 0o17, 0b11, 1_000, 0x_ff, 1e+3, 6.022e23]

negLits :: [Int]
negLits = [-1, - 1, (-1), negate 1]

-- ── Comprehensions and where / let / guards ──
parallel :: [(Int, Char)]
parallel = [(x, y) | x <- [1 .. 3] | y <- "abc"]

monadComp :: Maybe Int
monadComp = [x + y | x <- Just 1, y <- Just 2]

nestedComp :: [(Int, Int)]
nestedComp = [(x, y) | x <- [1 .. 3], let z = x * 2, y <- [z .. 6], x /= y, odd x]

guards :: Int -> String
guards n
  | n < 0 = "neg"
  | let m = n * 2, m > 10 = "big"
  | Just k <- lookup n table, k > 0 = "table"
  | otherwise = "other"
  where table = [(1, 1)]

blockArgs :: IO ()
blockArgs = for_ [1, 2, 3] \i -> do
  print i

lambdaCases :: Int -> Int -> String
lambdaCases = \cases
  0 0 -> "zeros"
  _ _ -> "other"

typeApp :: Int
typeApp = read @Int "42"

implicitParam :: (?verbose :: Bool) => String
implicitParam = if ?verbose then "verbose" else "quiet"

typedHole :: Int -> Int
typedHole x = _ + x

partialSig :: _ -> Int
partialSig x = x + 1

emptyCase :: Void' -> a
emptyCase v = case v of {}

data Void'

instSigs :: Num a => a
instSigs = 0

instance Show Void' where
  show :: Void' -> String
  show _ = "void"

-- ── Typeclass defaulting, where-less module end ──
default (Integer, Double)

#if MIN_VERSION_base(4,18,0)
cppFeature :: String
cppFeature = "new base"
#else
cppFeature :: String
cppFeature = "old base"
#endif

-- ── GHC 9.6–9.12 additions ──
-- Or-patterns (9.12): alternatives sharing one right-hand side
orPattern :: Status -> Bool
orPattern (Pending; Paid) = True
orPattern _ = False

-- Required type arguments (9.10): a visible forall
sizeOfType :: forall a -> Show a => String
sizeOfType a = "type argument"

useRequired :: String
useRequired = sizeOfType Int

-- Type abstractions in constructor patterns and lambdas (9.8+)
tyAbs :: Maybe Int -> Int
tyAbs (Just @Int n) = n
tyAbs Nothing = 0

tyAbsLam :: Int
tyAbsLam = (\ @a (x :: a) -> x) 1

-- Extended literals (9.8)
extLits :: (Int, Int)
extLits = (0x01#Int8 `seq` 1, 0xFF#Word8 `seq` 2)

-- type data (9.6): constructors live only at the type level
type data Universe = Planet | Moon

data Body (u :: Universe) where
  MkPlanet :: Body Planet
  MkMoon :: Body Moon

-- Linear types
linearSwap :: (a, b) %1 -> (b, a)
linearSwap (a, b) = (b, a)

linearMany :: a %Many -> a
linearMany x = x

polyMult :: forall (m :: Multiplicity) a. a %m -> a
polyMult x = x

-- Named defaults (9.12)
default Show (Integer, Double)

-- Overloaded labels, record dot sections, quantified constraints
label' :: IsLabel "name" a => a
label' = #name

dotSection :: [Person] -> [String]
dotSection = map (.name)

nestedDot :: Person -> Int
nestedDot p = p.age + 1

newtype Fix' f = Fix' (f (Fix' f))
instance (forall a. Show a => Show (f a)) => Show (Fix' f) where
  showsPrec d (Fix' x) = showParen (d > 10) (showString "Fix' " . showsPrec 11 x)

-- Lexical negation, hex floats, applicative do
lexNeg :: Int
lexNeg = (- 1) + -2

hexFloat :: Double
hexFloat = 0x1.8p3

appDo :: Maybe Int
appDo = do
  x <- Just 1
  y <- Just 2
  pure (x + y)

-- Static pointers, impredicative types, standalone kind signatures
impredicative :: Maybe (forall a. [a] -> [a])
impredicative = Just reverse

-- Deriving with explicit type applications and empty deriving
data Unit' = Unit' deriving ()
data Color' = Red' | Green' deriving stock (Show, Eq, Enum, Bounded)

-- Multi-way if inside do, let with guards, operator sections with backticks
guardLet :: Int -> String
guardLet n = let f x | x > 0 = "pos" | otherwise = "non-pos" in f n

-- Arrow-style where with typeclass defaulting
typeclassDefault :: String
typeclassDefault = show (2 ^ 10)

-- Multiline string literals (9.12)
banner :: String
banner = """
  Welcome to the warehouse.
    Indentation relative to the closing quotes is kept.
  Escapes like \t and quotes " work.
  """
