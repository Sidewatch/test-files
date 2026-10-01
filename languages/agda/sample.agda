{-# OPTIONS --safe --without-K #-}
{-# OPTIONS --allow-unsolved-metas #-}
{-
  Warehouse inventory in Agda: natural numbers, vectors, records, proofs.
  {- nested block comments are allowed -}
  TODO: replace the postulate with a real proof.
-}
module Sample where

-- ── Imports ────────────────────────────────────────────────────────
open import Agda.Primitive using (Level; lzero; lsuc; _⊔_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong; sym; trans; subst)
  renaming (cong₂ to congTwo)
import Data.Nat as Nat hiding (_+_)
open import Data.Bool using (Bool; true; false; if_then_else_)
open import Function using (_∘_; id; const)

-- ── Data types ─────────────────────────────────────────────────────
data ℕ : Set where
  zero : ℕ
  suc  : ℕ → ℕ

{-# BUILTIN NATURAL ℕ #-}

data Vec (A : Set) : ℕ → Set where
  []  : Vec A zero
  _∷_ : ∀ {n} → A → Vec A n → Vec A (suc n)

infixr 5 _∷_

data List (A : Set) : Set where
  nil  : List A
  cons : A → List A → List A

data Category : Set where
  tools parts fasteners : Category

-- ── Records ────────────────────────────────────────────────────────
record Item : Set where
  constructor mkItem
  field
    sku      : List ℕ
    quantity : ℕ
    kind     : Category

open Item public

record Monoid (A : Set) : Set where
  field
    ε   : A
    _∙_ : A → A → A
    left-id  : ∀ x → ε ∙ x ≡ x
    right-id : ∀ x → x ∙ ε ≡ x

-- ── Functions and operators ────────────────────────────────────────
infixl 6 _+_
infixl 7 _*_
infix  4 _≤_

_+_ : ℕ → ℕ → ℕ
zero  + n = n
suc m + n = suc (m + n)

_*_ : ℕ → ℕ → ℕ
zero  * n = zero
suc m * n = n + (m * n)

data _≤_ : ℕ → ℕ → Set where
  z≤n : ∀ {n} → zero ≤ n
  s≤s : ∀ {m n} → m ≤ n → suc m ≤ suc n

length : ∀ {A : Set} → List A → ℕ
length nil         = zero
length (cons _ xs) = suc (length xs)

head : ∀ {A n} → Vec A (suc n) → A
head (x ∷ _) = x

map : ∀ {A B : Set} {n} → (A → B) → Vec A n → Vec B n
map f []       = []
map f (x ∷ xs) = f x ∷ map f xs

-- ── Pattern matching, with-abstraction, where ──────────────────────
isLow : ℕ → Bool
isLow n with n
... | zero  = true
... | suc k = lowAux k
  where
    lowAux : ℕ → Bool
    lowAux zero = true
    lowAux (suc zero) = true
    lowAux _ = false

classify : ℕ → Category
classify zero = tools
classify (suc zero) = parts
classify _ = fasteners

absurdity : {A : Set} → .(x : ⊥') → A
absurdity ()

data ⊥' : Set where

-- ── Lambdas, let, if ───────────────────────────────────────────────
double : ℕ → ℕ
double = λ n → n + n

triple : ℕ → ℕ
triple = \ n → let m = n + n in m + n

choose : Bool → ℕ → ℕ → ℕ
choose b x y = if b then x else y

lamCase : ℕ → ℕ
lamCase = λ { zero → zero ; (suc n) → n }

-- ── Proofs ─────────────────────────────────────────────────────────
+-identityʳ : ∀ (n : ℕ) → n + zero ≡ n
+-identityʳ zero    = refl
+-identityʳ (suc n) = cong suc (+-identityʳ n)

+-suc : ∀ (m n : ℕ) → m + suc n ≡ suc (m + n)
+-suc zero    n = refl
+-suc (suc m) n = cong suc (+-suc m n)

+-comm : ∀ (m n : ℕ) → m + n ≡ n + m
+-comm m zero = +-identityʳ m
+-comm m (suc n) =
  begin' m + suc n ≡' +-suc m n
  where
    begin'_≡'_ : ∀ {A : Set} {x y : A} → A → x ≡ y → x ≡ y
    begin' _ ≡' p = p

-- ── Universe polymorphism ──────────────────────────────────────────
id′ : ∀ {ℓ} {A : Set ℓ} → A → A
id′ x = x

record Σ {a b} (A : Set a) (B : A → Set b) : Set (a ⊔ b) where
  constructor _,_
  field
    fst : A
    snd : B fst

Pair : Set → Set → Set
Pair A B = Σ A (λ _ → B)

-- ── Modules, parameters, instance arguments ────────────────────────
module Counting (A : Set) where
  count : List A → ℕ
  count = length

  private
    helper : ℕ → ℕ
    helper = suc

open Counting ℕ using (count)

postulate
  funext : ∀ {A B : Set} {f g : A → B} → (∀ x → f x ≡ g x) → f ≡ g

record Show (A : Set) : Set where
  field show : A → List ℕ
open Show {{...}}

-- ── Pragmas, holes, literals ───────────────────────────────────────
{-# INLINE double #-}
{-# NON_TERMINATING #-}
{-# COMPILE GHC length = Data.List.length #-}

aHole : ℕ
aHole = {! double 2 !}

aMeta : ℕ
aMeta = ?

three : ℕ
three = 1 + 2

hexNumber : ℕ
hexNumber = 0xFF

charLit : Category → ℕ
charLit _ = 7

stringy : List ℕ
stringy = nil

-- Mutual recursion
mutual
  even : ℕ → Bool
  even zero = true
  even (suc n) = odd n

  odd : ℕ → Bool
  odd zero = false
  odd (suc n) = even n

-- Rewriting and abstract
abstract
  secret : ℕ
  secret = 42

syntax choose b x y = b ? x ∶ y

-- ── Further constructs ──────────────────────────────────────────────
{-# OPTIONS --cubical --guardedness --sized-types #-}

open import Agda.Builtin.Equality using (_≡_; refl)
open import Agda.Builtin.String using (String; primStringAppend)
open import Agda.Builtin.Char using (Char)
open import Agda.Builtin.Float using (Float)
open import Agda.Builtin.Sigma
open import Agda.Builtin.Size
open import Agda.Builtin.Unit using (⊤; tt)
open import Data.Product as Prod public using (_×_; proj₁; proj₂)

variable
  ℓ ℓ′ : Level
  A B C : Set ℓ
  m n k : ℕ

primitive
  primStringEquality : String → String → Bool

-- Literals of every kind
aString : String
aString = "tab\t newline\n quote\" backslash\\ unicode \x41 \955 \8704"

aChar : Char
aChar = 'x'

aFloat : Float
aFloat = 3.14e-2

aBigNat : ℕ
aBigNat = 1_000_000

-- Universe levels and sorts
Type₀ : Set₁
Type₀ = Set

Big : Setω
Big = (ℓ : Level) → Set ℓ

Prop′ : Set₁
Prop′ = Prop

-- Irrelevance, erasure, and instance brackets
irrelevantArg : {A : Set} → .A → ⊤
irrelevantArg _ = tt

erased : {@0 A : Set} → ⊤
erased = tt

instArg : {{_ : Show ℕ}} → ℕ → List ℕ
instArg {{s}} n = Show.show s n

weirdBrackets : ⦃ _ : ⊤ ⦄ → ⊤
weirdBrackets = tt

-- Record with where, copatterns, and eta
record Stack (A : Set) : Set where
  coinductive
  constructor mkStack
  field
    top  : A
    rest : Stack A
open Stack

repeatS : A → Stack A
top  (repeatS a) = a
rest (repeatS a) = repeatS a

record Pointed : Set₁ where
  no-eta-equality
  pattern
  field
    Carrier : Set
    point   : Carrier

-- Coinduction with sized types
data Colist (A : Set) (i : Size) : Set where
  []  : Colist A i
  _∷_ : A → ∞ (Colist A i) → Colist A i

-- Pattern synonyms, rewrite, with on multiple expressions
pattern one = suc zero
pattern two = suc one

plus-zero : (n : ℕ) → n + zero ≡ n
plus-zero n rewrite +-identityʳ n = refl

compare : ℕ → ℕ → Bool
compare m n with m | n
... | zero  | zero  = true
... | suc _ | zero  = false
... | _     | suc _ = true

-- let, where, λ where, anonymous modules
useLet : ℕ → ℕ
useLet n = let a = n + n; b = a + a in a + b

lamWhere : ℕ → ℕ
lamWhere = λ where
  zero    → zero
  (suc n) → n

module _ {A : Set} (xs : List A) where
  firstLen : ℕ
  firstLen = length xs

module M (n : ℕ) where
  inner : ℕ
  inner = n
open M 3 renaming (inner to three′) hiding (outer)

-- Mutual blocks, interleaved declarations
interleaved mutual
  data Even′ : ℕ → Set
  data Odd′  : ℕ → Set
  data Even′ where
    ev0 : Even′ zero
  data Odd′ where
    od1 : Odd′ one

-- Opaque, instance, unquote and macros
opaque
  hidden : ℕ
  hidden = 7

instance
  showNat : Show ℕ
  showNat = record { show = λ _ → nil }

macro
  idMacro : Term → TC ⊤
  idMacro goal = unify goal goal

quoted : Name
quoted = quote ℕ

-- Remaining pragmas
{-# TERMINATING #-}
{-# POLARITY ℕ ++ #-}
{-# BUILTIN EQUALITY _≡_ #-}
{-# BUILTIN REWRITE _≡_ #-}
{-# COMPILE JS length = function(x) { return x.length; } #-}
{-# FOREIGN GHC import Data.Char #-}
{-# DISPLAY suc zero = one #-}
{-# CATCHALL #-}
{-# INJECTIVE #-}
{-# WARNING_ON_USAGE secret "do not use" #-}
{-# DEPRECATED_NAME old-name #-}
{-# ETA Stack #-}

-- TODO: derive Show for Item.
-- FIXME: prove associativity of _+_.
