(* Multi-generational heaps *)
From iris.algebra Require Import auth gmap frac agree functions list.
From iris.bi.lib Require Import fractional.
From iris.base_logic.lib Require Export own invariants.
From iris.base_logic.lib Require Import gen_heap.
From iris.proofmode Require Import tactics.
Set Default Proof Using "Type".
Import uPred.

Definition log_heapUR (L V : Type) `{Countable L}: ucmraT :=
  discrete_funUR (λ (n : nat), gen_heapUR L V).

Class log_heapG (L V: Type) (Σ : gFunctors) `{Countable L} := LogHeapG {
  log_heap_inG :> inG Σ (authR (log_heapUR L V));
  log_heap_name : gname
}.

Definition to_log_heap {L V} `{Countable L} (s: nat -> gmap L V) : log_heapUR L V :=
  λ n, to_gen_heap (s n).

Arguments log_heap_name {_ _ _ _ _} _ : assert.

Class log_heapPreG (L V : Type) (Σ : gFunctors) `{Countable L} :=
  { log_heap_preG_inG :> inG Σ (authR (log_heapUR L V)) }.

Definition log_heapΣ (L V : Type) `{Countable L} : gFunctors :=
  #[GFunctor (authR (log_heapUR L V))].

Instance subG_log_heapPreG {Σ L V} `{Countable L} :
  subG (log_heapΣ L V) Σ → log_heapPreG L V Σ.
Proof. solve_inG. Qed.


Record async T := {
  latest : T;
  pending : list T;
}.

Arguments Build_async {_} _ _.
Arguments latest {_} _.
Arguments pending {_} _.

Definition possible {T} (ab : async T) :=
  pending ab ++ [latest ab].

Definition sync {T} (v : T) : async T :=
  Build_async v nil.

Definition async_put {T} (v : T) (a : async T) :=
  Build_async v (possible a).


Section definitions.
  Context `{hG : log_heapG L V Σ}.

  Definition log_heap_ctx (σl : async (gmap L V)) : iProp Σ :=
    let σfun := λ n, match possible σl !! n with
                     | Some σ => σ
                     | None => latest σl
                     end in
    own (log_heap_name hG) (● (to_log_heap σfun)).

  Definition mapsto_log (first: nat) (last: option nat) (l: L) (q: Qp) (v: V) : iProp Σ :=
    ( ⌜ hG = hG ⌝ )%I.

End definitions.

Lemma seq_heap_init `{log_heapPreG L V Σ} σl:
  ⊢ |==> ∃ _ : log_heapG L V Σ, log_heap_ctx σl.
Proof.
Admitted.


Section log_heap.
  Context `{log_heapG L V Σ}.
  Implicit Types P Q : iProp Σ.
  Implicit Types Φ : V → iProp Σ.
  Implicit Types σ : gmap L V.
  Implicit Types σl : async (gmap L V).
  Implicit Types h g : log_heapUR L V.
  Implicit Types l : L.
  Implicit Types v : V.

  Lemma log_heap_valid σl l q v first last :
    log_heap_ctx σl -∗
      mapsto_log first last l q v -∗
      ⌜∀ n σ,
        first ≤ n ->
        match last with
        | Some a => n < a
        | None => True
        end ->
        possible σl !! n = Some σ ->
        σ !! l = Some v⌝.
  Proof.
  Admitted.

  Lemma mapsto_log_advance first first' last l q v :
    first ≤ first' ->
    mapsto_log first last l q v -∗ mapsto_log first' last l q v.
  Proof.
  Admitted.

  Lemma log_heap_append σl l v v' first :
    log_heap_ctx σl -∗
      mapsto_log first None l 1%Qp v ∗ ⌜ (first < length (possible σl))%nat ⌝ -∗
      ( let σ := <[l := v]> (latest σl) in
        log_heap_ctx (async_put σ σl) ∗
        mapsto_log first (Some (length (possible σl))) l 1%Qp v ∗
        mapsto_log (length (possible σl)) None l 1%Qp v' ).
  Proof.
  Admitted.

End log_heap.
