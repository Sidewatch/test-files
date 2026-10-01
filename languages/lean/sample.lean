-- Lean 4 (4.2x series, with Mathlib-style tactics) — syntax showcase; no Lean toolchain is installed here, so it was not compiled
/-
  Lean 4: warehouse stock model with types, proofs and tactics.
  /- nested block comment -/
-/
-- Line comment. TODO: prove the reorder lemma. FIXME: Float equality.

/-! # Module doc comment
Inventory structures and lemmas. -/

import Lean
import Std.Data.HashMap
import Mathlib.Tactic

set_option autoImplicit false
set_option maxRecDepth 1000
set_option pp.all true in
#check Nat

namespace Warehouse

open Nat List
open Std (HashMap)
open Lean hiding Name
open Nat renaming succ → s

universe u v
variable {α : Type u} [Inhabited α] (n m : Nat)

/-- Doc comment: a stock keeping unit. -/
abbrev Sku := String

/-- Status of a stock line. -/
inductive Status where
  | inStock : Status
  | low (threshold : Nat) : Status
  | out
  deriving Repr, BEq, DecidableEq, Inhabited

/-- Peano naturals, for the proof section. -/
inductive MyNat where
  | zero : MyNat
  | succ : MyNat → MyNat
  deriving Repr

open MyNat

/-- A stock line with a proof that quantities are bounded. -/
structure Item where
  sku : Sku
  quantity : Nat := 0
  price : Float := 0.0
  tags : List String := []
  h : quantity ≤ 1000000 := by decide
  deriving Repr

structure Perishable extends Item where
  expiresIn : Nat
  deriving Repr

class Priced (α : Type u) where
  price : α → Float
  discount : α → Float := fun _ => 0.0

instance : Priced Item where
  price i := i.price * i.quantity.toFloat

instance : Add MyNat := ⟨fun a b => a⟩

instance : ToString Status where
  toString
    | .inStock => "in stock"
    | .low t => s!"low (<{t})"
    | .out => "out"

-- ── Numbers and literals ──
def numbers : List Nat := [0, 42, 1_000, 0xFF, 0b1010, 0o755]
def floats : List Float := [3.14, 6.022e23, 1.5e-9, 2.0]
def chars : List Char := ['a', '\n', '\x41', '\u00e9', '\\', '\'']
def unit : Unit := ()
def bools : List Bool := [true, false]
def option : Option Nat := some 3
def pair : Nat × String := (1, "one")
def triple : Nat × Nat × Nat := (1, 2, 3)
def anon : Fin 10 := ⟨3, by decide⟩
def sub : { n : Nat // n > 0 } := ⟨1, by decide⟩

-- ── Strings ──
def plain : String := "Pallet \"A-100\"\ttab \\ backslash \u{1F4E6} \x41"
def interpolated (n : Nat) (name : String) : String := s!"Item {name} x{n} total {n * 2}"
def multi : String := "line one
line two \
continued"
def raw : String := r"C:\warehouse\bin"
def rawHash : String := r#"has "quotes" inside"#
def unicode : String := "Zürich → 東京 ✓"
def fmt : String := f!"formatted {1 + 1}"

-- ── Functions ──
def add : MyNat → MyNat → MyNat
  | zero,   n => n
  | succ m, n => succ (add m n)

def fib : Nat → Nat
  | 0 => 0
  | 1 => 1
  | n + 2 => fib n + fib (n + 1)

def sum (xs : List Nat) : Nat := xs.foldl (· + ·) 0
def double := fun (x : Nat) => 2 * x
def compose (f : β → γ) (g : α → β) : α → γ := f ∘ g
def withDefault (x : Nat := 5) (y : Nat) : Nat := x + y
@[inline] def fast (x : Nat) : Nat := x + 1
@[simp] def slow (x : Nat) : Nat := x - 1
private def hidden := 1
protected def Item.cost (i : Item) : Float := i.price * i.quantity.toFloat
partial def loopForever (n : Nat) : Nat := loopForever (n + 1)
unsafe def danger : Nat := unsafeCast 1
noncomputable def choice : Nat := Classical.choice ⟨1⟩
macro "mytriv" : tactic => `(tactic| trivial)
notation:65 a " +++ " b => a ++ b
infixl:70 " ** " => Nat.mul
syntax "[[" term "]]" : term
macro_rules | `([[ $x ]]) => `($x)

def total (items : List Item) : Float :=
  items.foldl (fun acc i => acc + i.price * i.quantity.toFloat) 0

def describe (s : Status) : String :=
  match s with
  | .inStock => "plenty"
  | .low t => if t < 5 then "very low" else "low"
  | .out => "none"

def process (xs : List Nat) : IO Unit := do
  let mut acc := 0
  for x in xs do
    if x == 0 then continue
    if x > 100 then break
    acc := acc + x
  let rec go (n : Nat) : Nat := match n with
    | 0 => 0
    | k + 1 => go k + 1
  IO.println s!"acc = {acc}, go = {go 3}"
  try
    throw <| IO.userError "boom"
  catch e =>
    IO.eprintln e
  finally
    IO.println "done"
  let some v := xs.head? | return
  unless v == 0 do pure ()
  while false do pure ()

def main : IO Unit := do
  let items := [{ sku := "A-100", quantity := 5, price := 2.5 : Item }]
  IO.println (total items)
  let arr := #[1, 2, 3]
  let h := arr[0]!
  let t := arr[1]?
  let w := arr.map (· * 2) |>.toList
  IO.println s!"{h} {t} {w}"

-- ── Theorems and tactics ──
theorem add_zero (n : MyNat) : add n zero = n := by
  induction n with
  | zero => rfl
  | succ m ih => simp [add, ih]

theorem and_swap (p q : Prop) (hp : p) (hq : q) : q ∧ p := by
  constructor
  · exact hq
  · exact hp

theorem or_comm' {p q : Prop} : p ∨ q → q ∨ p := by
  intro h
  cases h with
  | inl hp => exact Or.inr hp
  | inr hq => exact Or.inl hq

theorem arith (a b : Nat) : a + b = b + a := by
  omega

theorem exists_pos : ∃ n : Nat, n > 0 := ⟨1, by decide⟩

theorem zero_right : ∀ x : Nat, x + 0 = x := by
  intro x; rw [Nat.add_zero]

example (xs : List Nat) : xs ++ [] = xs := by simp
example : 2 + 2 = 4 := rfl
example (f : Nat → Nat) (h : ∀ x, f x = x) : f 3 = 3 := by
  have h3 := h 3
  calc f 3 = 3 := h3
    _ = 3 := rfl
  <;> try rfl
  all_goals sorry

instance : Decidable (1 < 2) := by infer_instance
theorem lt_example : 1 < 2 := by
  first | decide | simp | omega
  repeat (apply And.intro)
  exact?

-- ── Types, universes, dependent types ──
def Vec (α : Type u) (n : Nat) := { xs : List α // xs.length = n }
def ident {α : Sort u} (a : α) : α := a
def depPair : (n : Nat) × Fin (n + 1) := ⟨3, 2⟩
def dep : (n : Nat) → Fin (n + 1) := fun n => ⟨n, Nat.lt_succ_self n⟩
def logic : Prop := ∀ p : Prop, p ∨ ¬p
def sets : Prop := ∃ x, x ∈ [1, 2] ∧ x ≠ 3 ∨ x ≥ 1 ∧ x ≤ 5 ↔ True
def arrows (f : Nat → Nat → Nat) : Nat ⊕ Nat := Sum.inl (f 1 2)
def lambdaForms := (λ x => x + 1, fun | 0 => 1 | _ => 2, ·)

-- ── Commands ──
#eval fib 10
#eval (Item.mk "A-1" 3 1.5 [] (by decide)).cost
#check @add_zero
#print Status
#reduce 2 + 3
#synth Inhabited Nat
#print axioms add_zero

attribute [local simp] Nat.add_comm
deriving instance Repr for Status
end Warehouse

section Extras
variable (p : Prop)
mutual
  def isEven : Nat → Bool
    | 0 => true
    | n + 1 => isOdd n
  def isOdd : Nat → Bool
    | 0 => false
    | n + 1 => isEven n
end
end Extras

/-! ## Rare constructs -/
section Rare
universe w
variable {α β : Type w} [inst : BEq α] {p q r : Prop} (xs ys : List α)

mutual
  inductive Tree (α : Type) where
    | node : α → Forest α → Tree α
  inductive Forest (α : Type) where
    | nil : Forest α
    | cons : Tree α → Forest α → Forest α
end

class inductive Good : Nat → Prop where
  | zero : Good 0
  | succ {n : Nat} : Good n → Good (n + 1)

structure Config where mk' ::
  verbose : Bool := false
  level : Nat := 3
  name : String := "default"
  deriving Repr, Hashable, Ord

class Shape (α : Type) extends ToString α where
  area : α → Float
  perimeter (x : α) : Float := 0.0

axiom choice_ax : ∀ α : Type, Nonempty α → α
opaque secretFn : Nat → Nat
@[implemented_by secretFn] def public' : Nat → Nat := fun n => n
@[reducible, inline, specialize] def alias' := Nat
@[simp, norm_cast] theorem t1 : (1 : Nat) = 1 := rfl
@[ext] structure Wrap where val : Nat
@[instance] def instWrap : Inhabited Wrap := ⟨⟨0⟩⟩
attribute [simp] Nat.add_comm in
theorem uses_attr : True := trivial
local notation "ℕ'" => Nat
scoped infixr:67 " ::: " => List.cons
prefix:max "√" => Nat.sqrt
postfix:max "!" => Nat.succ
declare_syntax_cat color
syntax "red" : color
syntax "color!" color : term
macro_rules | `(color! red) => `("red")
elab "answer!" : term => do return Lean.mkNatLit 42
initialize counter : IO.Ref Nat ← IO.mkRef 0
builtin_initialize registry : IO.Ref (Array Nat) ← IO.mkRef #[]

-- numbers, characters, strings
def lits : List Float := [1.5e3, 2.0E-2, 0.5, 1e10]
def nats : List Nat := [0xAB, 0XCD, 0b11, 0B11, 0o17, 0O17, 1_000_000]
def chs : List Char := ['\t', '\\', '\"', '\'', '\x7f', 'λ', 'λ', '∀']
def strs : List String := ["\r\n", "\x41", "\u{1F600}", "tab\there", "gap \
                         continues", r"raw \n", r#"raw "# "quotes"#]
def fmts (n : Nat) := (s!"n = {n}", s!"nested {s!"inner {n}"}", m!"msg {n}", f!"fmt {n}")
def names := (`foo, `Foo.bar, ``Nat.add, `(1 + 2), `(tactic| rfl), `($(Lean.mkIdent `x) + 1), `x.y)
def arrays := (#[1, 2, 3], #[], #[#[1], #[2]], [1, 2, 3][0]!, #[1, 2][1]?, #[1, 2, 3][1:2], (#[1, 2] : Array Nat)[0]'(by decide))

-- binders, lambdas, patterns
def lam1 := fun (x : Nat) (y : Nat := 2) => x + y
def lam2 := λ x => x + 1
def lam3 : Nat × Nat → Nat := fun ⟨a, b⟩ => a + b
def lam4 : Option Nat → Nat := fun | some n => n | none => 0
def lam5 := (· + ·) 1 2
def lam6 := (fun x => x) <| 1
def lam7 := List.map (· * 2) [1, 2] |>.length
def lam8 := [1, 2].map fun x => x + 1
def pat1 : List Nat → Nat
  | [] => 0
  | [x] => x
  | x :: y :: _ => x + y
def pat2 (n : Nat) : String :=
  match h : n with
  | 0 => "zero"
  | k + 1 => s!"succ {k}"
def pat3 (p : Nat × Option Nat) : Nat :=
  let (a, some b) := p | 0
  a + b
def pat4 (x : Nat) : Bool := if h : x > 0 then true else false
def pat5 (o : Option Nat) : Nat := if let some v := o then v else 0
def pat6 (o : Option Nat) : Nat := match o with | .some v => v | .none => 0
def pat7 (n : Nat) : Nat := match n, n with | 0, _ => 1 | _, 0 => 2 | _, _ => 3
def pat8 : (n : Nat) → n = n → Nat | 0, _ => 0 | _ + 1, _ => 1
def withWhere (n : Nat) : Nat := go n 0
where
  go : Nat → Nat → Nat
    | 0, acc => acc
    | k + 1, acc => go k (acc + k)
  termination_by n => n
def withLet : Nat := let x := 1; let y := x + 1; have z : y = 2 := rfl; x + y
def withShow : Nat := show Nat from 5
def withFrom (h : p ∧ q) : q ∧ p := ⟨h.2, h.1⟩
def projections (p : Nat × Nat × Nat) := (p.1, p.2.1, p.2.2, p.fst, p.snd)

-- operators
def ops (a b : Nat) (p q : Prop) :=
  (a + b, a - b, a * b, a / b, a % b, a ^ b, a ∣ b, a ≤ b, a ≥ b, a < b, a > b, a ≠ b, a = b, a == b, a != b,
   a &&& b, a ||| b, a ^^^ b, a <<< b, a >>> b, ~~~a, a ∈ [b], a ∉ [b], [a] ++ [b], a :: [b], a <|> b,
   p ∧ q, p ∨ q, ¬p, p → q, p ↔ q, p ⊕' q, True, False, (⊤ : Prop), (⊥ : Prop), a ≡ b [MOD 3],
   some a >>= fun x => some x, (· + 1) <$> some a, some (· + 1) <*> some a, a |> id, id <| a, id $ a, a ∘ b, (a, b), ⟨a, b⟩,
   a ∪ b, a ∩ b, a ⊆ b, ∅, a \ b, aᶜ, |a|, ‖a‖, ∑ i in range 3, i, ∏ i in range 3, i, a ⁻¹, a ⬝ b, a • b, a ⊗ b)

-- do notation and monads
def doDemo : IO Unit := do
  let mut sum := 0
  let arr := #[1, 2, 3]
  for h : i in [0:arr.size] do
    sum := sum + arr[i]'(Membership.get_elem_helper h rfl)
  for x in arr, y in [10, 20, 30] do sum := sum + x * y
  for i in [0:10:2] do if i > 6 then break else continue
  let ref ← IO.mkRef 0
  ref.modify (· + 1)
  let v ← ref.get
  let x : Nat ← pure 5
  let some y ← pure (some 1) | return
  let (a, b) ← pure (1, 2)
  if v > 0 then IO.println "pos" else if v < 0 then IO.println "neg"
  match v with
  | 0 => pure ()
  | _ => IO.println "nonzero"
  unless v == 0 do IO.println "unless"
  let r ← try pure 1 catch _ => pure 0
  let e ← (throw (IO.userError "x") : IO Nat) <|> pure 0
  (← IO.getStdout).putStrLn s!"{sum} {x} {y} {a} {b} {r} {e}"
  return ()

instance : Monad Option' where
  pure := some
  bind o f := match o with | none => none | some x => f x

-- tactic zoo
theorem tactics (a b c : Nat) (h : a = b) (h2 : b = c) (hp : p) (hq : q) : a = c ∧ p ∧ q := by
  refine ⟨?_, hp, hq⟩
  · rw [h, h2]
  all_goals skip
  any_goals skip
  on_goal 1 => skip
  case _ => skip
  next => skip
  show a = c
  calc a = b := h
       _ = c := h2

theorem tactics2 (n : Nat) (xs : List Nat) (h : n > 0) : n ≠ 0 ∧ xs.length ≥ 0 := by
  constructor
  · intro hn; subst hn; contradiction
  · simp only [List.length] at *
    omega
  <;> first | rfl | simp | omega
  repeat' rfl
  try (rfl)
  rcases xs with _ | ⟨x, xs'⟩
  obtain ⟨y, hy⟩ : ∃ y, y = 1 := ⟨1, rfl⟩
  rintro ⟨_, _⟩
  cases' h with k hk
  induction' n with m ih generalizing xs
  specialize h
  exfalso; by_contra hc; push_neg at hc
  unfold id at h ⊢
  conv => lhs; rw [h]
  rw [← h] at h2 ⊢
  simp [*, -List.length] at h
  exact?; apply?; rw?; simp?; decide; native_decide; norm_num; ring; linarith; nlinarith [sq_nonneg 1]; aesop; tauto; trivial; assumption
  exact absurd h (by decide)
  have : n = n := rfl
  suffices h : n = n from h
  use 1; exists 1; existsi 1
  ext x; funext y; congr 1; split <;> simp; split_ifs; by_cases hc : n = 0
  nofun; nomatch h; infer_instance; exact_mod_cast h; positivity; gcongr; bound
  sorry

-- commands
#eval IO.println "eval"
#reduce fun x : Nat => x + 0
#check_failure (1 + "a")
#print "message"
#print instances Monad
#print Nat.add
#help tactic
end Rare

/-! ## Recent additions -/
section Recent
-- configuration options after tactics use +flag / -flag / (name := value)
example (a b : Nat) : a + b = b + a := by simp +arith
example (a b : Nat) (h : a ≤ b) : a < b + 1 := by omega
example : 10 * 10 = 100 := by decide +kernel
example (xs : List Nat) : (xs ++ []).length = xs.length := by simp (config := { decide := true })
example (a b c : Nat) (h : a = b) (h' : b = c) : a = c := by grind
example (p q : Prop) (hp : p) (hq : q) : p ∧ q := by exact ⟨hp, hq⟩

-- #guard and #guard_msgs
#guard 1 + 1 == 2
/-- info: 3 -/
#guard_msgs in
#eval 1 + 2

-- instance priorities, named instances, default instances
instance (priority := low) lowPrio : Inhabited Nat := ⟨0⟩
instance instNamed : ToString Warehouse.Status := ⟨fun _ => "status"⟩
@[default_instance] instance : HMul Float Float Float := ⟨Float.mul⟩

-- structural and well-founded recursion annotations
def ack : Nat → Nat → Nat
  | 0, n => n + 1
  | m + 1, 0 => ack m 1
  | m + 1, n + 1 => ack m (ack (m + 1) n)
termination_by m n => (m, n)

def countDown (n : Nat) : List Nat :=
  if h : n = 0 then [0] else n :: countDown (n - 1)
termination_by n
decreasing_by omega

-- include / omit and variable scoping
variable (x : Nat) (h : x > 0)
include h in
theorem needs_h : x ≠ 0 := by omega
omit h in
theorem no_h : x = x := rfl

-- Subtype, anonymous constructor, structure instance update, dot-notation
structure Point where
  x : Nat
  y : Nat
  deriving Repr

def shifted (p : Point) : Point := { p with x := p.x + 1 }
def origin : Point := ⟨0, 0⟩
def viaWhere : Point where
  x := 1
  y := 2
def namedArgs := Nat.add (n := 1) (m := 2)
def pipeline := [1, 2, 3] |>.map (· + 1) |>.filter (· > 2) |>.length
def anonymousHyp (n : Nat) (h : n > 0) : n > 0 := ‹n > 0›
end Recent
