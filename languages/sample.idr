-- Idris 2: length-indexed vectors and a total, type-safe head.
module Sample

import Data.Vect

%default total

||| A vector whose length is known at the type level.
data Vec : Nat -> Type -> Type where
  Nil  : Vec Z a
  (::) : a -> Vec n a -> Vec (S n) a

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

example : Vec 3 Int
example = 1 :: 2 :: 3 :: Nil

main : IO ()
main = printLn (head example, sumVec (append example example))
