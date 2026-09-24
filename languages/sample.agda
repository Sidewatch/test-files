-- Natural numbers, addition, and a proof that zero is a right identity.
module Sample where

open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

data ℕ : Set where
  zero : ℕ
  suc  : ℕ → ℕ

{-# BUILTIN NATURAL ℕ #-}

_+_ : ℕ → ℕ → ℕ
zero  + n = n
suc m + n = suc (m + n)

infixl 6 _+_

+-identityʳ : ∀ (n : ℕ) → n + zero ≡ n
+-identityʳ zero    = refl
+-identityʳ (suc n) = cong suc (+-identityʳ n)

three : ℕ
three = 1 + 2
