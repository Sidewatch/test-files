(* Rocq 9.1 (formerly Coq) — syntax showcase: an inventory model with proofs.
   This file DETECTS AS VERILOG (.v is Verilog's extension) — pick Coq from the language picker. *)

(* ── Comments ── *)
(* A comment (* with a nested comment *) inside it *)
(** Doc comment: stock levels never go negative. *)
(* TODO: prove the reorder invariant. FIXME: tighten bounds. *)

(* ── Imports and settings ── *)
From Stdlib Require Import Arith List String Lia Bool QArith ZArith Ascii.
Require Import Stdlib.Program.Basics.
From Coq Require Import Sorting. (* deprecated prefix: Coq is now Stdlib *)
Import ListNotations.
Open Scope string_scope.
Set Implicit Arguments.
Unset Strict Implicit.
Set Printing Width 80.
Local Set Warnings "-notation-overridden".
Declare Scope warehouse_scope.
Delimit Scope warehouse_scope with wh.

(* ── Strings, numbers, characters ── *)
Definition greeting : string := "Warehouse ""north"" ready".
Definition empty_note : string := "".
Definition forty_two : nat := 42.
Definition big : nat := 1000000.
Definition ch : Ascii.ascii := "a"%char.
Definition ch_code : Ascii.ascii := "065"%char.
Definition hex_literal : nat := 0x2A.
Definition frac : Q := 3 # 4.
Definition neg : Z := (-17)%Z.

(* ── Inductive types ── *)
Inductive Category : Type :=
  | Tools
  | Fasteners
  | Safety
  | Bulk (weight : nat).

Inductive Item : Type :=
  | MkItem : string -> Category -> nat -> Item.

Inductive Tree (A : Type) : Type :=
  | Leaf : Tree A
  | Node : Tree A -> A -> Tree A -> Tree A.
Arguments Leaf {A}.
Arguments Node {A} _ _ _.

Inductive even : nat -> Prop :=
  | even_O : even 0
  | even_SS : forall n, even n -> even (S (S n)).

CoInductive Stream (A : Type) : Type :=
  | Cons : A -> Stream A -> Stream A.

(* ── Records and classes ── *)
Record Bin := mkBin {
  bin_id : nat;
  bin_items : list Item;
  bin_capacity : nat
}.

Structure Pallet := { pallet_no : nat; pallet_bins : list Bin }.

Class Priced (A : Type) := { price : A -> nat }.

Instance priced_item : Priced Item :=
  { price := fun i => match i with MkItem _ _ p => p end }.

(* ── Definitions and fixpoints ── *)
Definition item_name (i : Item) : string :=
  match i with MkItem n _ _ => n end.

Definition restock (current delta : nat) : nat := current + delta.

Fixpoint total_price (l : list Item) : nat :=
  match l with
  | [] => 0
  | i :: rest => price i + total_price rest
  end.

Fixpoint size {A : Type} (t : Tree A) : nat :=
  match t with
  | Leaf => 0
  | Node l _ r => size l + 1 + size r
  end.

Fixpoint fib (n : nat) : nat :=
  match n with
  | 0 => 0
  | 1 => 1
  | S (S k as m) => fib k + fib m
  end.

CoFixpoint ones : Stream nat := Cons 1 ones.

Definition classify (n : nat) : string :=
  if n =? 0 then "empty"
  else if n <? 10 then "low"
  else "ok".

Definition with_let (x : nat) : nat :=
  let y := x * 2 in
  let z := y + 1 in
  z.

Definition anon := fun (x : nat) => x + 1.
Definition anon2 := fun x y : nat => x * y.
Definition ifte (b : bool) := if b then 1 else 0.
Definition pm_ex (p : nat * nat) := let (a, b) := p in a + b.
Definition forall_ex := forall n : nat, n >= 0.
Definition exists_ex := exists n : nat, n > 3.

(* ── Notation ── *)
Notation "x ++> y" := (x ++ y) (at level 60, right associativity) : warehouse_scope.
Notation "[ x ; .. ; y ]" := (cons x .. (cons y nil) ..).
Infix "+++" := plus (at level 50, left associativity).
Reserved Notation "x === y" (at level 70, no associativity).

(* ── Sections and modules ── *)
Section Stock.
  Variable capacity : nat.
  Hypothesis cap_pos : capacity > 0.
  Context {A : Type}.

  Definition fits (n : nat) : bool := n <=? capacity.

  Lemma fits_zero : fits 0 = true.
  Proof. unfold fits. apply Nat.leb_le. lia. Qed.
End Stock.

Module Type PRICING.
  Parameter base : nat.
  Axiom base_pos : base > 0.
End PRICING.

Module Flat <: PRICING.
  Definition base := 10.
  Lemma base_pos : base > 0. Proof. unfold base. lia. Qed.
End Flat.

Module Export Helpers.
  Definition double (n : nat) := 2 * n.
End Helpers.

(* ── Theorems and tactics ── *)
Theorem plus_n_O : forall n : nat, n + 0 = n.
Proof.
  intros n. induction n as [| n' IHn'].
  - reflexivity.
  - simpl. rewrite IHn'. reflexivity.
Qed.

Lemma plus_comm' : forall a b : nat, a + b = b + a.
Proof.
  intros a b.
  destruct a; destruct b; simpl; auto with arith.
  rewrite Nat.add_comm. reflexivity.
Qed.

Example three_even : even 4.
Proof.
  repeat constructor.
Qed.

Lemma double_even : forall n, even (double n).
Proof.
  induction n; unfold double in *; simpl.
  { constructor. }
  { replace (n + S (n + 0)) with (S (n + n)) by lia.
    apply even_SS. rewrite <- plus_n_O in IHn. assumption. }
Admitted.

Theorem and_swap : forall P Q : Prop, P /\ Q -> Q /\ P.
Proof.
  intros P Q [HP HQ]. split; [exact HQ | exact HP].
Qed.

Theorem or_swap : forall P Q : Prop, P \/ Q -> Q \/ P.
Proof.
  intros P Q H. destruct H as [p | q].
  - right. exact p.
  - left. exact q.
Qed.

Lemma neg_ex : ~ (1 = 2).
Proof. intro H. discriminate H. Qed.

Lemma arith_ex : forall x y, x < y -> x + 1 <= y.
Proof. intros. lia. Qed.

Lemma try_ex : forall n, n = n.
Proof. intro n. try (exfalso; fail). reflexivity. Qed.

Goal forall b : bool, b || true = true.
Proof. intros [|]; simpl; try reflexivity; auto. Defined.

Fact one_ne_zero : 1 <> 0.
Proof. congruence. Qed.

Corollary fib_5 : fib 5 = 5.
Proof. vm_compute. reflexivity. Qed.

Remark rem : True. Proof. exact I. Qed.

Ltac solve_arith := intros; simpl; lia.
Tactic Notation "my_auto" := auto with *.

Lemma uses_ltac : 1 + 1 = 2. Proof. solve_arith. Qed.

(* ── Commands ── *)
Check plus_n_O.
Print Item.
About fib.
Compute (fib 10).
Eval compute in (total_price []).
Search (_ + 0 = _).
Locate "+".
Fail Check (1 + true).
Hint Resolve plus_n_O : core.
Hint Rewrite Nat.add_0_r : arith_db.
Existing Instance priced_item.
Obligation Tactic := auto.
Program Definition safe_pred (n : nat) (H : n > 0) : nat := n - 1.
Extraction Language OCaml.
Eval cbv in (3 + 4).
Axiom classical : forall P : Prop, P \/ ~ P.
Parameter stock_limit : nat.
Variables a b : nat.
Universe u.
Definition poly@{v} (A : Type@{v}) := A.
Set Universe Polymorphism.
Typeclasses eauto := 5.

(* ── Unicode notation and logic symbols ── *)
Notation "∀ x , P" := (forall x, P) (at level 200, x binder).
Definition lam_ex := λ (x : nat), x.
Check (fun (A : Type) (x : A) => x).
Lemma unicode_ex : ∀ n : nat, n = n.
Proof. intro n; reflexivity. Qed.
Lemma iff_ex : forall P Q : Prop, (P <-> Q) -> (Q -> P).
Proof. intros P Q [H1 H2]; exact H2. Qed.

(* ── Mutual and nested definitions ── *)
Inductive tree : Type := Node : nat -> forest -> tree
with forest : Type := Nil : forest | Cons : tree -> forest -> forest.

Fixpoint tree_size (t : tree) : nat :=
  match t with Node _ f => 1 + forest_size f end
with forest_size (f : forest) : nat :=
  match f with Nil => 0 | Cons t f' => tree_size t + forest_size f' end.

Variant color : Set := Red | Green | Blue.
Function div2 (n : nat) {measure (fun x => x)} : nat :=
  match n with 0 => 0 | 1 => 0 | S (S k) => S (div2 k) end.
Program Fixpoint log2 (n : nat) {wf lt n} : nat := 0.
Scheme Equality for color.
Scheme Induction for nat Sort Prop.
Coercion nat_of_bool (b : bool) : nat := if b then 1 else 0.
Canonical Structure nat_eqType := nat.
Generalizable Variables A B.
Arguments plus _ _ : simpl nomatch.
Arguments size {A}%type_scope t.
Implicit Types n m : nat.
Remove Hints plus_n_O : core.
Create HintDb warehouse.
Opaque fib.
Transparent fib.
Global Instance inst_ex : Priced nat := { price := fun n => n }.
#[global] Hint Resolve and_swap : core.
#[local] Instance local_ex : Priced bool := { price := fun _ => 0 }.
#[export] Set Printing All.
#[deprecated(since="1.0", note="use new_name")] Definition old_name := 1.
#[program] Definition prog_attr := 1.
Unset Printing Notations.
Local Open Scope nat_scope.
Close Scope nat_scope.
Bind Scope nat_scope with nat.
Undelimit Scope nat_scope.
Section Vars.
  Variables (T : Type) (x y : T).
  Let local_def := 5.
  Local Definition ld := 1.
  Local Parameter lp : nat.
End Vars.
Module M := Flat.
Module Type Sig. End Sig.
Declare Module Dm : PRICING.
Include Flat.
Export Helpers.
Import Helpers.
Print Module Flat.
Print Assumptions plus_n_O.
Print Grammar constr.
Print Hint *.
Print LoadPath.
Show.
Restart.
Abort.
Reset Initial.
Timeout 5 Check 1.
Time Compute 1 + 1.
Redirect "out.txt" Check 1.
Optimize Proof.
Proof using A.
Proof with auto.
Unshelve.
Admit Obligations.
Next Obligation.
Solve Obligations with auto.
Obligation 1.
Declare ML Module "ltac_plugin".
Declare Custom Entry expr.
Declare Reduction myred := cbv beta.
Add Rec LoadPath "lib" as Warehouse.
Add LoadPath "lib".
Add Parametric Relation : nat eq reflexivity proved by eq_refl as eq_rel.
Add Ring nat_ring : Nat.add_0_r.
Hint Constructors even : core.
Hint Unfold fits : core.
Hint Extern 1 (_ = _) => reflexivity : core.
Hint Immediate eq_refl : core.
Hint Transparent plus : core.
Hint Mode Priced + : typeclass_instances.
Hint Cut [_* eq_refl] : core.
Hint Variables Opaque : typeclass_instances.
Hint Constants Transparent : typeclass_instances.
Hint Resolve -> iff_ex : core.

(* ── Tactics (extended) ── *)
Lemma tactics_ex : forall (a b c : nat) (H : a = b) (l : list nat),
  a = b /\ (b = c -> a = c) /\ exists k, k = a.
Proof.
  intros a b c H l.
  split; [| split].
  - exact H.
  - intro H2. transitivity b; try assumption. symmetry in H. subst. auto.
  - exists a. reflexivity.
  assert (Hx : a = a) by reflexivity.
  assert (Hy : b = b). { reflexivity. }
  pose proof (Nat.add_comm a b) as Hc.
  pose (p := a + b).
  set (q := b + c) in *.
  cut (a = a); [intro | reflexivity].
  generalize dependent a.
  revert b. clear c. rename l into l2. specialize (Hc).
  remember (a + b) as r eqn:Hr.
  inversion H; subst; clear H.
  injection H as Hinj.
  discriminate H.
  congruence.
  contradiction.
  exfalso.
  left. right.
  apply Nat.le_refl in Hx.
  apply (Nat.add_comm a b).
  eapply Nat.le_trans. eauto. auto with arith.
  rewrite <- Hc in Hy. rewrite Hc at 1. rewrite ! Nat.add_0_r. rewrite -> H by lia.
  simpl in *. cbn. compute. vm_compute. native_compute. lazy. hnf. red. unfold fits in Hx. fold fits.
  change (a + 0) with a. replace (a + b) with (b + a) by lia.
  destruct a eqn:Ea; destruct (a =? b) eqn:Hab; destruct H as [H1 [H2 H3]]; destruct l as [| h t].
  induction a as [| a' IH] using nat_ind; induction l; elim a; case a.
  functional induction (div2 a).
  intuition. tauto. firstorder. lia. nia. ring. field. ring_simplify. btauto. decide equality. 
  repeat (try split; auto). do 3 intro. progress simpl. first [ reflexivity | assumption ].
  solve [ auto | eauto ]. now auto. time auto. timeout 2 auto. idtac "message". fail. constructor 2. econstructor.
  refine (fun x => _). unshelve eapply plus_n_O. shelve. admit. give_up.
  tryif assumption then idtac else fail. abstract lia. exact I. trivial. easy. ltac:(auto). 
  match goal with
  | [ H : ?x = ?y |- _ ] => rewrite H
  | |- context [?a + 0] => rewrite Nat.add_0_r
  | _ => idtac
  end.
  lazymatch goal with | |- ?g => idtac g end.
  multimatch goal with | |- _ => idtac end.
  let t := type of a in idtac t.
  let x := fresh "x" in intros x. 
  assert_succeeds auto. assert_fails fail.
  all: auto. 1,2: auto. 2: { auto. } { auto. } par: auto. Show Existentials. Undo. 
Admitted.

Ltac my_tac t := t; try reflexivity || (simpl; auto).
Ltac rec_tac := repeat match goal with | H : _ /\ _ |- _ => destruct H end.
Tactic Notation "foo" tactic(t) := t.
Declare Scope my_scope.

(* ── Rocq 9: attributes, universes, primitives ── *)
Set Primitive Projections.
#[projections(primitive=yes)] Record Cfg := { cfg_name : string; cfg_size : nat }.
#[universes(polymorphic)] Definition id_poly (A : Type) (a : A) := a.
Polymorphic Definition id_poly2@{u | } (A : Type@{u}) (a : A) := a.
Polymorphic Cumulative Inductive Box@{u} (A : Type@{u}) : Type@{u} := box : A -> Box A.
Monomorphic Universe m1 m2.
Universes p q.
Constraint m1 < m2.
Definition with_constraint@{a b | a < b} (A : Type@{a}) : Type@{b} := A.
Definition sprop_ex (P : SProp) := P.
Definition prop_ex : Prop := True.
Definition set_ex : Set := nat.
Definition type_ex : Type := Type.
Print Universes.
Check Type@{m1}.
#[local] Set Warnings "-deprecated".
#[export] Hint Resolve plus_n_O : core.
#[deprecated(since="9.0", note="use fits")] Notation old_fits := fits.
#[reversible] Coercion bool_to_nat := nat_of_bool.
#[refine] Instance refined : Priced unit := { price := fun _ => 0 }.
#[canonical=no] Record NoCanon := { nc : nat }.
#[warnings="-notation-overridden"] Notation "x +!+ y" := (x + y) (at level 50).

(* ── Terms: match, fix, cofix, patterns ── *)
Definition match_full (n : nat) : nat :=
  match n as m in nat return nat with
  | 0 => 1
  | S k => k
  end.
Definition match_or (n : nat) : bool :=
  match n with
  | 0 | 1 | 2 => true
  | _ => false
  end.
Definition match_nested (p : nat * option nat) : nat :=
  match p with
  | (a, Some b) => a + b
  | (a, None) => a
  end.
Definition destruct_pat '((a, b) : nat * nat) : nat := a + b.
Definition let_pat (p : nat * nat) := let '(a, b) := p in a * b.
Definition lam_pat := fun '(a, b) => a + b.
Definition lam_multi := fun (x : nat) (y : bool) => if y then x else 0.
Definition fix_term := fix f (n : nat) : nat := match n with 0 => 0 | S k => S (f k) end.
Definition cofix_term := cofix cf : Stream nat := Cons 0 cf.
Definition struct_fix := fix g (n m : nat) {struct n} : nat := match n with 0 => m | S k => g k (S m) end.
Definition impl_args {A B : Type} (a : A) (b : B) := (a, b).
Definition strict_impl {A : Type} `{Priced A} (a : A) := price a.
Definition explicit_app := @impl_args nat bool 1 true.
Definition named_arg := impl_args (A := nat) (B := bool) 1 true.
Definition typed_hole : nat := _.
Definition num_scopes := ((1 + 2)%nat, (3 - 4)%Z, (5 # 6)%Q, 7%positive, 8%N).
Definition pair_ex := (1, 2, 3).
Definition list_ex : list nat := [1; 2; 3].
Definition cons_ex := 1 :: 2 :: nil.
Definition app_ex := [1] ++ [2].
Definition proj_ex (c : Cfg) := c.(cfg_size).
Definition record_ex := {| cfg_name := "a"; cfg_size := 1 |}.
Definition record_upd (c : Cfg) := {| c with cfg_size := 2 |}.
Definition sigma_ex : { n : nat | n > 0 } := exist _ 1 (le_n 1).
Definition sumbool_ex (n : nat) : {n = 0} + {n <> 0} := Nat.eq_dec n 0.
Definition exists_unique := exists! n : nat, n = 0.
Definition forall_multi := forall (a b : nat) (P : nat -> Prop), P a -> P b.
Definition arrow_ex : nat -> nat -> nat := fun a b => a + b.
Definition logic_ex := forall P Q : Prop, ~ (P /\ Q) \/ (P -> Q) <-> True.
Definition cmp_ex := (1 <= 2, 1 < 2, 2 >= 1, 2 > 1, 1 <> 2, 1 = 1, 1 =? 1, 1 <=? 2, 1 <? 2).
Definition arith_ex := (1 + 2 * 3 - 4, 7 / 2, 7 mod 2, 2 ^ 3).
Definition bool_ex := (true && false || negb true, andb true false, orb true false, xorb true false).
Definition ascii_ex := ("a"%char, "b"%char :: nil).
Definition str_ex := ("abc" ++ "def", String.length "abc", "a"%string).
Definition float_ex := 1.5e3.
Definition hex_ex := 0xFF.

(* ── Inductives: parameters, indices, notations, records ── *)
Inductive vec (A : Type) : nat -> Type :=
  | vnil : vec A 0
  | vcons : forall n, A -> vec A n -> vec A (S n).
Inductive le_ex (n : nat) : nat -> Prop :=
  | le_ex_n : le_ex n n
  | le_ex_S : forall m, le_ex n m -> le_ex n (S m).
Inductive expr : Type :=
  | Num (n : nat)
  | Add (a b : expr)
  | Mul (a b : expr) where "a +. b" := (Add a b) and "a *. b" := (Mul a b).
Inductive empty_ex : Type := .
Inductive unit_ex : Type := tt_ex.
Inductive wrapper (A : Type) := wrap { unwrap : A }.
#[universes(template)] Inductive tmpl (A : Type) := t1 | t2.
Variant opt (A : Type) : Type := Nope | Yep (a : A).
Record point3 : Set := mk3 { px : nat; py : nat; pz : nat }.
Class Eq (A : Type) := { eqb : A -> A -> bool; eqb_refl : forall a, eqb a a = true }.
Class Monoid (A : Type) := { mempty : A; mappend : A -> A -> A }.
Instance monoid_nat : Monoid nat := { mempty := 0; mappend := Nat.add }.
Instance eq_nat : Eq nat.
Proof. refine {| eqb := Nat.eqb; eqb_refl := Nat.eqb_refl |}. Defined.
Declare Instance dummy : Priced unit.
#[global] Instance anon_inst : Priced string := {| price := fun _ => 1 |}.
Inductive cofin : nat -> Type := .
CoInductive colist (A : Type) := conil | cocons (a : A) (l : colist A).
CoInductive stream_rec (A : Type) := { hd : A; tl : stream_rec A }.
Definition sr_ex : stream_rec nat := cofix s := {| hd := 0; tl := s |}.

(* ── Notation forms ── *)
Notation "'IF' c 'THEN' a 'ELSE' b" := (if c then a else b) (at level 200, c at level 100, right associativity).
Notation "x ⊕ y" := (xorb x y) (at level 50, left associativity) : bool_scope.
Notation "{{ x }}" := (S x) (format "{{ x }}", at level 0).
Notation "'λ' x .. y , t" := (fun x => .. (fun y => t) ..) (at level 200, x binder, y binder, right associativity).
Notation "∑ x , f" := (fold_right plus 0 (map f x)) (at level 45, only parsing).
Notation "x ≤ y" := (le x y) (only printing, at level 70).
Notation succ := S (only parsing).
Local Notation "# x" := (S x) (at level 1).
Number Notation nat Nat.of_num_uint Nat.to_num_uint : nat_scope.
Declare Custom Entry stack.
Notation "<{ e }>" := e (e custom stack at level 99).
Declare Scope cmd_scope.
Delimit Scope cmd_scope with cmd.
Bind Scope cmd_scope with nat.
Reserved Infix "<=>" (at level 70, no associativity).
Infix "<+>" := Nat.add (at level 50, left associativity) : nat_scope.
Arguments mk3 {_ _ _}.
Arguments vcons {A n} _ _.
Arguments Leaf : clear implicits.
Arguments plus n m /.
Arguments plus : extra scopes.
Arguments impl_args {A B} a b : rename.
Implicit Type n : nat.
Strategy opaque [fib].
Strategy 10 [plus].
Typeclasses Opaque Eq.
Typeclasses Transparent Eq.

(* ── Modules and functors ── *)
Module Type ORD.
  Parameter t : Type.
  Parameter le : t -> t -> Prop.
  Axiom le_refl : forall x, le x x.
End ORD.
Module Type SORT (O : ORD).
  Parameter sort : list O.t -> list O.t.
End SORT.
Module Nat_ord <: ORD.
  Definition t := nat.
  Definition le := Nat.le.
  Lemma le_refl : forall x, le x x. Proof. apply Nat.le_refl. Qed.
End Nat_ord.
Module Sorter (O : ORD) : SORT O.
  Definition sort (l : list O.t) := l.
End Sorter.
Module NatSorter := Sorter Nat_ord.
Module Opaque_ord : ORD with Definition t := nat.
  Definition t := nat.
  Definition le := Nat.le.
  Lemma le_refl : forall x, le x x. Proof. apply Nat.le_refl. Qed.
End Opaque_ord.
Import NatSorter.
Import Nat_ord (le).
Require Import Stdlib.Lists.List.
Local Open Scope list_scope.
Export Stdlib.Arith.Arith.
Print Module Type ORD.
Print Module Sorter.

(* ── Proof-mode commands and bullets ── *)
Theorem mutual_a : forall n, n = n
with mutual_b : forall m, m + 0 = m.
Proof.
  - intros. reflexivity.
  - intros. apply plus_n_O.
Qed.
Proposition prop_ex2 : True. Proof. trivial. Qed.
Property prop_ex3 : True. Proof. trivial. Qed.
Lemma bullets : (True /\ True) /\ (True /\ True).
Proof.
  split.
  - split.
    + exact I.
    + exact I.
  - split.
    * exact I.
    * exact I.
Qed.
Lemma bullets_deep : (True /\ True) /\ True.
Proof.
  split.
  -- split.
     ++ exact I.
     ++ exact I.
  -- exact I.
Qed.
Lemma bullets_triple : True /\ True /\ True.
Proof.
  repeat split.
  --- exact I.
  +++ exact I.
  *** exact I.
Qed.
Lemma selectors : True /\ True.
Proof.
  split; [ | ].
  all: exact I.
Qed.
Lemma named_goals : forall n : nat, n = n.
Proof.
  intro n. induction n as [ | k IH ] eqn:E.
  [Zero]: reflexivity.
  [Succ]: reflexivity.
Qed.
Lemma using_ex : True.
Proof using Type. exact I. Qed.
Lemma abort_ex : False.
Proof. Abort.
Lemma save_ex : True.
Proof. exact I. Save.
Lemma admitted_ex : False.
Proof. Admitted.
Set Default Goal Selector "!".
Set Default Proof Using "Type".
Unset Default Goal Selector.
Obligation Tactic := intuition.
Hint Resolve le_n : core arith.
Hint Rewrite <- plus_n_O : core.
Remove Hints le_n : core.
Create HintDb mydb discriminated.
Hint Opaque fib : mydb.
Hint Transparent fib : mydb.
Derive Inversion inv_even with (forall n, even n) Sort Prop.
Derive Dependent Inversion inv_even2 with (forall n, even n) Sort Prop.
Print Coercions.
Print Instances Priced.
Print Canonical Projections.
Print Libraries.
Print Visibility.
Print Scope nat_scope.
Print Scopes.
Test Printing Width.
Add Printing Constructor wrapper.
Remove Printing Let wrapper.
Add Search Blacklist "internal".
Search nat -bool.
Search "plus" "comm" inside Nat.
SearchPattern (_ + _ = _).
SearchRewrite (_ + 0).
Show Proof.
Show Conjectures.
Info 1 auto.
Comments "just a comment" 1 "number".
Check let x := 1 in x.
Eval simpl in 1 + 1.
Eval lazy in 1 + 1.
Eval hnf in 1 + 1.
Eval cbn in 1 + 1.
Eval unfold plus in 1 + 1.
Eval red in 1 + 1.
Eval vm_compute in 1 + 1.
Eval native_compute in 1 + 1.
Print Assumptions classical.
Section Using.
  Variable A : Type.
  Variables (a : A) (b : A).
  Hypotheses (H1 : a = a) (H2 : b = b).
  Let x := a.
  Definition d (n : nat) := a.
  Lemma lemma_using : a = a. Proof using a. reflexivity. Qed.
End Using.

(* ── Ltac2 ── *)
From Ltac2 Require Import Ltac2.
Ltac2 Type color := [ Red | Green | Blue (int) ].
Ltac2 Type rec tree := [ Leaf | Branch (tree, tree) ].
Ltac2 Type ('a) box := { mutable contents : 'a }.
Ltac2 mutable counter := 0.
Ltac2 rec fact (n : int) : int := if Int.equal n 0 then 1 else Int.mul n (fact (Int.sub n 1)).
Ltac2 greet () := Message.print (Message.of_string "hello").
Ltac2 Notation "my_split" := split.
Ltac2 Notation "twice" t(tactic) := t; t.
Ltac2 Eval fact 5.
Ltac2 Set counter := 1.
Ltac2 match_ex (c : color) : int :=
  match c with
  | Red => 0
  | Green => 1
  | Blue n => n
  end.
Ltac2 ex_tac () :=
  let x := Fresh.in_goal @h in
  let t := '(1 + 1) in
  let c := constr:(2 + 2) in
  let l := [1; 2; 3] in
  let (a, b) := (1, 2) in
  let arr := Array.make 3 0 in
  let r := { contents := 0 } in
  r.(contents) := 1;
  Array.set arr 0 5;
  for i := 0 to 2 do Message.print (Message.of_int i) done;
  while Bool.neg false do () done;
  lazy_match! goal with
  | [ |- ?g ] => Message.print (Message.of_constr g)
  end;
  match! constr:(1 + 1) with
  | ?a + ?b => ()
  end;
  assert (True) by (exact I);
  ltac1:(auto);
  Control.enter (fun () => ());
  Control.zero (Tactic_failure None);
  ().
Ltac2 @ external my_ext : int -> int := "plugin" "name".
