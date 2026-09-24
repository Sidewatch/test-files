-- Lean 4: natural-number addition with a proof that zero is a right identity.
namespace Sample

inductive MyNat where
  | zero : MyNat
  | succ : MyNat → MyNat
  deriving Repr

open MyNat

def add : MyNat → MyNat → MyNat
  | zero,   n => n
  | succ m, n => succ (add m n)

instance : Add MyNat := ⟨add⟩

theorem add_zero (n : MyNat) : add n zero = n := by
  induction n with
  | zero => rfl
  | succ m ih => simp [add, ih]

def three : MyNat := succ (succ (succ zero))

#eval three
#check @add_zero

structure Point where
  x : Float
  y : Float
deriving Repr

def Point.norm (p : Point) : Float := Float.sqrt (p.x * p.x + p.y * p.y)

#eval (Point.mk 3 4).norm   -- 5.0

end Sample
