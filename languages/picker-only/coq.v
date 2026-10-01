(* Coq showcase: an inventory model with proofs.
   This file DETECTS AS VERILOG (.v is Verilog's extension) — pick Coq from the language picker. *)

(* ── Comments ── *)
(* A comment (* with a nested comment *) inside it *)
(** Doc comment: stock levels never go negative. *)
(* TODO: prove the reorder invariant. FIXME: tighten bounds. *)

(* ── Imports and settings ── *)
From Coq Require Import Arith List String Lia Bool QArith ZArith Ascii.
Require Import Coq.Program.Basics.
Require Export Coq.Init.Nat.
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
Back.
Drop.
Restart.
Abort.
Reset Initial.
Quit.
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
  intuition. tauto. firstorder. lia. nia. omega. ring. field. ring_simplify. psatz. btauto. decide equality. 
  repeat (try split; auto). do 3 intro. progress simpl. first [ reflexivity | assumption ].
  solve [ auto | eauto ]. now auto. time auto. timeout 2 auto. idtac "message". fail. constructor 2. econstructor.
  refine (fun x => _). unshelve eapply plus_n_O. shelve. admit. give_up.
  tryif assumption then idtac else fail. any_destruct. abstract lia. exact I. trivial. easy. ltac:(auto). 
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
  all: auto. 1,2: auto. 2: { auto. } { auto. } par: auto. Focus 1. 
  Show Existentials. Unfocus. Undo. 
Admitted.

Ltac my_tac t := t; try reflexivity || (simpl; auto).
Ltac rec_tac := repeat match goal with | H : _ /\ _ |- _ => destruct H end.
Tactic Notation "foo" tactic(t) := t.
Declare Scope my_scope.
