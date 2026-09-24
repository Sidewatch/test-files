(* Coq: natural numbers, addition, and a proof that zero is a right identity.
   This file DETECTS AS VERILOG (.v is Verilog's extension) — pick Coq from the language picker. *)
Inductive nat : Type :=
  | O : nat
  | S : nat -> nat.

Fixpoint plus (n m : nat) : nat :=
  match n with
  | O => m
  | S n' => S (plus n' m)
  end.

Notation "x + y" := (plus x y) (at level 50, left associativity).

Theorem plus_n_O : forall n : nat, n + O = n.
Proof.
  intros n. induction n as [| n' IHn'].
  - reflexivity.
  - simpl. rewrite IHn'. reflexivity.
Qed.

Definition three : nat := S (S (S O)).
Compute (three + three).
