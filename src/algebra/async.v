From stdpp Require Import countable.
From iris.algebra Require Import mlist gmap_view.
From iris.base_logic Require Import lib.iprop.
From iris.proofmode Require Import tactics.
From Perennial.algebra Require Import log_heap.

Set Default Proof Using "Type".

Class asyncG Σ (K V: Type) `{Countable K, EqDecision V} := {
  async_listG :> fmlistG (gmap K V) Σ;
  async_mapG :> inG Σ (gmap_viewR K natO);
}.

(** We need two ghost names. *)
Record async_gname := {
  async_list : gname;
  async_map : gname;
}.

Section async.
Context {K V: Type} `{Countable K, EqDecision V, asyncG Σ K V}.

Implicit Types (γ:async_gname) (k:K) (v:V) (i:nat) (σ: gmap K V) (σs: async (gmap K V)) (last: gmap K nat).

Definition lookup_async σs i k : option V :=
  σ ← possible σs !! i; σ !! k.

(* The possible states in [σs] are tracked in a regular append-only list.
Additionally, there is a way to control which was the last transaction that changed
a certain key, which ensures that the key stayed unchanged since then.

 Durability is orthogonal to this library: separately from the async we know
 that some index is durable, which guarantees that facts about that index and
 below can be carried across a crash. *)
Definition is_last σs k i : Prop :=
  ∃ v, lookup_async σs i k = Some v ∧ 
    ∀ i', i ≤ i' → lookup_async σs i' k = Some v.
Definition async_ctx γ σs : iProp Σ :=
  ∃ last, ⌜map_Forall (is_last σs) last⌝ ∗ own γ.(async_map) (gmap_view_auth last) ∗
    (* We also have the [lb] in here to avoid some update modalities below. *)
    fmlist γ.(async_list) 1 (possible σs) ∗ fmlist_lb γ.(async_list) (possible σs).


Global Instance async_ctx_timeless γ σs : Timeless (async_ctx γ σs).
Proof. apply _. Qed.


(* ephemeral_txn_val owns only a single point in the ephemeral transactions.
It is persistent. *)
Definition ephemeral_txn_val γ (i:nat) (k: K) (v: V) : iProp Σ :=
  ∃ σ, ⌜σ !! k = Some v⌝ ∗ fmlist_idx γ.(async_list) i σ.

(* ephemeral_val_from owns ephemeral transactions from i onward (including
future transactions); this is what makes it possible to use ephemeral
maps-to facts to append a new gmap with those addresses updated (see
[map_update_predicate] for the kind of thing we should be able to do) *)
Definition ephemeral_val_from γ (i:nat) (k: K) (v: V) : iProp Σ :=
  ephemeral_txn_val γ i k v ∗ own γ.(async_map) (gmap_view_frag k (DfracOwn 1) i).

(* exactly like [ephemeral_txn_val] except owning a half-empty range of
transactions [lo, hi) *)
Definition ephemeral_txn_val_range γ (lo hi:nat) (k: K) (v: V): iProp Σ :=
  [∗ list] i ∈ seq lo (hi-lo), ephemeral_txn_val γ i k v.

Theorem ephemeral_txn_val_range_acc γ lo hi k v i :
  (lo ≤ i < hi)%nat →
  ephemeral_txn_val_range γ lo hi k v -∗
  (* does not return the range under the assumption we make these persistent *)
  ephemeral_txn_val γ i k v.
Proof.
  iIntros (Hbound) "Hrange".
  rewrite /ephemeral_txn_val_range.
  assert (seq lo (hi - lo)%nat !! (i - lo)%nat = Some i).
  { apply lookup_seq; lia. }
  iDestruct (big_sepL_lookup with "Hrange") as "$"; eauto.
Qed.

Theorem ephemeral_val_from_in_bounds γ σs i k v :
  async_ctx γ σs -∗
  ephemeral_val_from γ i k v -∗
  (* if equal, only owns the new transactions and no current ones *)
  ⌜i < length (possible σs)⌝%nat.
Proof.
  iIntros "Hauth [Hval Hlast]".
  iDestruct "Hauth" as (last Hlast) "(Hmap & Halist & _)".
  iDestruct "Hval" as (σ Hσ) "Hflist".
  iDestruct (fmlist_idx_agree_2 with "Halist Hflist") as %Hi.
  iPureIntro.
  apply lookup_lt_is_Some. rewrite Hi. eauto.
Qed.

Theorem ephemeral_txn_val_lookup γ σs i k v :
  async_ctx γ σs -∗
  ephemeral_txn_val γ i k v -∗
  ⌜lookup_async σs i k = Some v⌝.
Proof.
  iIntros "Hauth Hval".
  iDestruct "Hauth" as (last Hlast) "(Hmap & Halist & _)".
  iDestruct "Hval" as (σ Hσ) "Hflist".
  iDestruct (fmlist_idx_agree_2 with "Halist Hflist") as %Hi.
  rewrite /lookup_async Hi /=. done.
Qed.

Theorem ephemeral_lookup_txn_val γ σs i k v :
  lookup_async σs i k = Some v →
  async_ctx γ σs -∗
  ephemeral_txn_val γ i k v.
Proof.
  rewrite /lookup_async /ephemeral_txn_val.
  iIntros (Hlookup) "Hauth".
  iDestruct "Hauth" as (last _) "(_ & _ & Hflist)". clear last.
  destruct (possible σs !! i) as [σ|] eqn:Hσ; last done.
  simpl in Hlookup.
  iExists _. iSplit; first done.
  iApply fmlist_lb_to_idx; done.
Qed.

(** All transactions since [i] have the value given by [ephemeral_val_from γ i]. *)
Theorem ephemeral_val_from_val γ σs i i' k v :
  (i ≤ i') →
  (i' < length (possible σs))%nat →
  async_ctx γ σs -∗
  ephemeral_val_from γ i k v -∗
  ephemeral_txn_val γ i' k v.
Proof.
  iIntros (??) "Hauth [Hval Hlast]".
  iDestruct (ephemeral_txn_val_lookup with "Hauth Hval") as %Hlookup.
  iClear "Hval".
  iDestruct "Hauth" as (last Hlast) "(Hmap & Halist & Hflist)".
  iDestruct (own_valid_2 with "Hmap Hlast") as %[_ Hmap]%gmap_view_both_valid_L.
  destruct (Hlast _ _ Hmap) as (v' & Hlookup' & Htail).
  rewrite Hlookup in Hlookup'. injection Hlookup' as [=<-].
  iApply ephemeral_lookup_txn_val; last first.
  - iExists last. iFrame. done.
  - apply Htail. done.
Qed.

(** Move the "from" resource from i to i', and obtain a
[ephemeral_txn_val_range] for the skipped range. *)
Theorem ephemeral_val_from_split i' γ i k v v' :
  (i ≤ i')%nat →
  ephemeral_val_from γ i k v -∗
  ephemeral_txn_val γ i' k v' -∗ (* witnesses that i' is in-bounds *)
  ephemeral_txn_val_range γ i i' k v ∗ ephemeral_val_from γ i' k v.
Proof.
Admitted.

(* TODO: we really need a strong init that also creates ephemeral_val_from for
every address in the domain; this is where it's useful to know that the async
has maps with the same domain *)
Theorem async_ctx_init σs:
  ⊢ |==> ∃ γ, async_ctx γ σs.
Proof.
Admitted.

Theorem async_update_map m' γ σs m0 txn_id :
  dom (gset _) m' = dom (gset _) m0 →
  async_ctx γ σs -∗
  ([∗ map] a↦v ∈ m0, ephemeral_val_from γ txn_id a v) -∗
  |==> async_ctx γ (async_put (m' ∪ latest σs) σs) ∗
       ([∗ map] a↦v ∈ m', ephemeral_val_from γ txn_id a v).
Proof.
  (* this can probably be proven by adding a copy of latest σs to the end and
  then updating each address in-place (normally it's not possible to change an
  old txn_id, but perhaps that's fine at the logical level? after all,
  ephemeral_val_from txn_id a v is more-or-less mutable if txn_id is lost) *)
Admitted.

(* this splits off an [ephemeral_val_from] at exactly the last transaction *)
Theorem async_ctx_ephemeral_val_from_split γ σs i k v :
  async_ctx γ σs -∗
  ephemeral_val_from γ i k v -∗
  async_ctx γ σs ∗ ephemeral_txn_val_range γ i (length (possible σs) - 1) k v ∗
    ephemeral_val_from γ (length (possible σs) - 1) k v.
Proof.
  iIntros "Hctx Hi+".
  iDestruct (ephemeral_val_from_in_bounds with "Hctx Hi+") as %Hinbounds.
  iAssert (ephemeral_txn_val γ (length (possible σs) - 1) k v) as "#Hval".
  { iApply (ephemeral_val_from_val with "Hctx"); last done; lia. }
  iDestruct (ephemeral_val_from_split (length (possible σs) - 1) with "Hi+ []") as "[Hold H+]"; eauto.
  { lia. }
  iFrame.
Qed.

Theorem async_ctx_ephemeral_val_from_map_split γ σs i m :
  async_ctx γ σs -∗
  big_opM bi_sep (ephemeral_val_from γ i) m -∗
  async_ctx γ σs ∗ big_opM bi_sep (ephemeral_txn_val_range γ i (length (possible σs) - 1)) m ∗
  big_opM bi_sep (ephemeral_val_from γ (length (possible σs) - 1)) m.
Proof.
  iIntros "Hctx Hm".
  iInduction m as [|a v m] "IH" using map_ind.
  - rewrite !big_sepM_empty.
    iFrame.
  - iDestruct (big_sepM_insert with "Hm") as "[Hi Hm]"; auto.
    iDestruct (async_ctx_ephemeral_val_from_split with "Hctx Hi") as "(Hctx&Hrange&H+)".
    iDestruct ("IH" with "Hctx Hm") as "(Hctx&Hmrange&Hm+)".
    iFrame.
    rewrite !big_sepM_insert //; iFrame.
Qed.

End async.
