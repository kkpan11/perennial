From stdpp Require Import sorting.
Require Import New.code.go_etcd_io.etcd.client.v3.
Require Import New.generatedproof.go_etcd_io.etcd.client.v3.
Require Import New.proof.proof_prelude.

Inductive ecomp (E : Type → Type) (R : Type) : Type :=
| Pure (r : R) : ecomp E R
| Effect {A} (e : E A) (k : A → ecomp E R) : ecomp E R
(* Having a separate [Bind] permits binding at pure computation steps, whereas
   binding only in [Effect] results in a shallower (and thus easier to reason
   about) embedding. *)
.

Arguments Pure {_ _} (_).
Arguments Effect {_ _ _} (_ _).

Definition Handler (E M : Type → Type) := ∀ A (e : E A), M A.

Fixpoint interp {M E R}`{!MRet M} `{!MBind M} (handler : Handler E M) (e : ecomp E R) : M R :=
  match e with
  | Pure r => mret r
  | Effect e k => v ← handler _ e; interp handler (k v)
  end.

(* Definition Handler E M := ∀ (A B : Type) (e : E A) (k : A → M B), M B. *)
Fixpoint ecomp_bind {E} A B (kx : A → ecomp E B) (x : ecomp E A) : (ecomp E B) :=
  match x with
  | Pure r => kx r
  | Effect e k => (Effect e (λ c, ecomp_bind _ _ kx (k c)))
  end.
Instance ecomp_MBind E : MBind (ecomp E) := ecomp_bind.

Instance ecomp_MRet E : MRet (ecomp E) := (@Pure E).

Existing Instance fallback_genPred.
Existing Instances r_mbind r_mret r_fmap.

(* https://etcd.io/docs/v3.6/learning/api/ *)
Module KeyValue.
Record t :=
mk {
    key : list w8;
    create_revision : w64;
    mod_revision : w64;
    version : w64;
    value : list w8;
    lease : w64;
  }.

Global Instance settable : Settable _ :=
  settable! mk < key; create_revision; mod_revision; version; value; lease>.
End KeyValue.

Module EtcdState.
Record t :=
mk {
    revision : w64;
    compact_revision : w64;
    key_values : gmap w64 (gmap (list w8) KeyValue.t);

    (* XXX: Though the docs don't explain or guarantee this, this tracks lease
       IDs that have been given out previously to avoid reusing LeaseIDs. If
       reuse were allowed, it's possible that a lease expires & its keys are
       deleted, then another client creates a lease with the same ID and
       attaches the same keys, after which the first expired client would
       incorrectly see its keys still attached with its leaseid.
     *)
    used_lease_ids : gset w64;
    lease_expiration : gmap w64 w64; (* If an ID is used but not in here, then it has been expired. *)
  }.

Global Instance settable : Settable _ :=
  settable! mk < revision; compact_revision; key_values; used_lease_ids; lease_expiration>.
End EtcdState.

(** Effects for etcd specification. *)
Inductive etcdE : Type → Type :=
| SuchThat {A} (pred : A → Prop) : etcdE A
| GetState : etcdE EtcdState.t
| SetState (σ' : EtcdState.t) : etcdE unit
| GetTime : etcdE w64
| Assume (b : Prop) : etcdE unit
| Assert (b : Prop) : etcdE unit.


(* Establish monadicity of relation.t *)
Instance relation_mret A : MRet (relation.t A) :=
  λ {A} a, λ σ σ' a', a = a' ∧ σ' = σ.

Instance relation_mbind A : MBind (relation.t A) :=
  λ {A B} kmb ma, λ σ σ' b,
    ∃ a σmiddle,
      ma σ σmiddle a ∧
      kmb a σmiddle σ' b.

(* Monads can't be composed in general.
  Can we still show that ecomp E (R + ∙) is a monad?
  https://www.cis.upenn.edu/~stevez/papers/SH+23.pdf claims to use `interp` to
  interpret an exception effect into a (R + A) value type.
  However, the paper does not argue (or even claim) that (itree (excE Err ⊕ E)
  (Err ⊕ ∙)) is a monad, which is needed for interpretation.
  E.g. one must define that as soon as an exception is reached, no more effects
  should be carried out, which seems like it ought to be part of the bind for
  that not-a-Monad....
  In fact, looking at the code
  (https://github.com/DeepSpec/InteractionTrees/blob/secure/theories/Events/Exception.v),
  reveals that the formal development does not do what the paper claims.
  Instead, it manually creates a looping itree computation that carries out one
  effect at a time, terminating early if an exception is encountered. It does
  not use the standard `interp`. Is it possible to define *any* itree handler
  such that Theorem 2 holds?
 *)
Instance exception_compose_mret {M} `{!MRet M} R :
  MRet (M ∘ (sum R)) := λ {A} a, mret $ inr a.

Instance exception_compose_mbind {M} `{!MBind M, !MRet M} R :
  MBind (M ∘ (sum R)) :=
  λ {A B} (kmb : A → M (R + B)%type) (a : M (R + A)%type),
    mbind (λ ea, match ea with | inl r => mret $ inl r | inr a => kmb a end) a.

(* I guess this just proved that M ↦ (M ∘ sum R) is a monad transformation.... *)

Inductive with_exceptionE R (E : Type → Type) (A : Type) : Type :=
| Throw (r : R)
| Ok (e : E A)
.

Arguments Throw {_ _ _} (_).
Arguments Ok {_ _ _} (_).

Definition handle_exceptionE {R E} : Handler (with_exceptionE R E) ((ecomp E) ∘ (sum R)) :=
  λ A e,
    match e with
    | Throw r => Pure (inl r)
    | Ok e => Effect e (λ x, Pure (inr x))
    end.

(* Handle etcd effects with the [relation.t EtcdState.t] monad. *)
Definition handle_etcdE (t : w64) : Handler etcdE (relation.t EtcdState.t) :=
  λ A e,
    match e with
    | SuchThat pred => λ σ σ' a, pred a ∧ σ' = σ
    | GetState => λ σ σ' ret, σ' = σ ∧ ret = σ
    | SetState σnew => λ σ σ' ret, σ' = σnew
    | GetTime => λ σ σ' tret, tret = t ∧ σ' = σ
    | Assume P => λ σ σ' tret, P ∧ σ = σ'
    | Assert P => λ σ σ' tret, (P → σ = σ')
    end.

Definition do {E R} (e : E R) : ecomp E R := Effect e Pure.

(** This covers all transitions of the etcd state that are not tied to a client
   API call, e.g. lease expiration happens "in the background". This will be
   called as a prelude by all the client-facing operations, since it is sound to
   delay running spontaneous transitions until they would actually affect the
   client. This relies on [SpontaneousTransition] being monotonic: if a
   transition can happen at time [t'] with [t' > t], then it must be possible at
   [t] as well. The following lemma confirms this. *)
Definition SingleSpontaneousTransition : ecomp etcdE () :=
  (* expire some lease *)
  (* XXX: this is a "partial" transition: it is not always possible to expire a
     lease. *)
  time ← do GetTime;
  σ ← do GetState;
  lease_id ← do $ SuchThat (λ l, ∃ exp, σ.(EtcdState.lease_expiration) !! l = (Some exp) ∧
                                     uint.nat time > uint.nat exp);
  (* FIXME: delete attached keys *)
  do $ SetState (set EtcdState.lease_expiration (delete lease_id) σ).

Lemma SingleSpontaneousTransition_monotonic (time time' : w64) σ σ' :
  uint.nat time < uint.nat time' →
  interp (handle_etcdE time) SingleSpontaneousTransition σ σ' () →
  interp (handle_etcdE time') SingleSpontaneousTransition σ σ' ().
Proof.
  intros Htime Hstep.
  rewrite /SingleSpontaneousTransition in Hstep |- *.
  rewrite /interp /= /mbind /relation_mbind /mret /relation_mret in Hstep.
  destruct Hstep as (? & ? & [-> ->] & Hstep).
  destruct Hstep as (? & ? & [-> ->] & Hstep).
  destruct Hstep as (? & ? & [(? & Hexp & Hlt) ->] & Hstep).
  destruct Hstep as (? & ? & -> & _ & ->).
  repeat econstructor; try done.
  lia.
Qed.

(** This does a non-deterministic number of spontaneous transitions. *)
Definition SpontaneousTransition : ecomp etcdE unit :=
  num_steps ← do $ SuchThat (λ (_ : nat), True);
  Nat.iter num_steps (λ p, SingleSpontaneousTransition;; p) (mret ()).

Module LeaseGrantRequest.
Record t :=
mk {
    TTL : w64;
    ID : w64;
  }.
Global Instance settable : Settable _ :=
  settable! mk < TTL; ID>.
End LeaseGrantRequest.

Module LeaseGrantResponse.
Record t :=
mk {
    TTL : w64;
    ID : w64;
  }.
Global Instance settable : Settable _ :=
  settable! mk <TTL; ID>.
End LeaseGrantResponse.

Definition LeaseGrant (req : LeaseGrantRequest.t) : ecomp etcdE LeaseGrantResponse.t :=
  (* FIXME: add this back *)
  (* SpontaneousTransition;; *)
  (* req.TTL is advisory, so it is ignored. *)
  ttl ← do $ SuchThat (λ ttl, uint.nat ttl > 0);
  σ ← do GetState;
  lease_id ← (if decide (req.(LeaseGrantRequest.ID) = (W64 0)) then
                do $ SuchThat (λ lease_id, lease_id ∉ σ.(EtcdState.used_lease_ids))
              else
                (do $ Assert (req.(LeaseGrantRequest.ID) ∉ σ.(EtcdState.used_lease_ids));;
                 mret req.(LeaseGrantRequest.ID)));
  time ← do GetTime;
  let σ := (set EtcdState.used_lease_ids (λ old, {[lease_id]} ∪ old) σ) in
  let σ := (set EtcdState.lease_expiration <[lease_id := (word.add time ttl)]> σ) in
  do (SetState σ);;
  mret (LeaseGrantResponse.mk lease_id ttl).

Module LeaseKeepAliveRequest.
Record t :=
mk {
    ID : w64;
  }.
Global Instance settable : Settable _ :=
  settable! mk < ID>.
End LeaseKeepAliveRequest.

Module LeaseKeepAliveResponse.
Record t :=
mk {
    TTL : w64;
    ID : w64;
  }.
Global Instance settable : Settable _ :=
  settable! mk <TTL; ID>.
End LeaseKeepAliveResponse.

Definition LeaseKeepAlive (req : LeaseKeepAliveRequest.t) : ecomp etcdE LeaseKeepAliveResponse.t :=
  (* XXX *)
  (* if the lease is expired, returns TTL=0. *)
  (* Q: if the lease expiration time is in the past, is it guaranteed that
     the lease is expired (i.e. its attached keys are now deleted)? Or does a
     failed KeepAlive merely mean a _lack_ of new knowledge of a lower bound on
     lease expiration?
     A comment in v3_server.go says:
    // A expired lease might be pending for revoking or going through
    // quorum to be revoked. To be accurate, renew request must wait for the
    // deletion to complete.
    But the following code actually also returns if the lessor gets demoted, in
    which case the lease expiration time is extended to "forever".
    Q: when refreshing, "extend" is set to 0. Is it possible for `remainingTTL >
    0` when reaching lessor.go:441, resulting in the `Lease` expiry being too
    small?
  *)
  SpontaneousTransition;;
  σ ← do $ GetState;
  (* This is conservative. lessor.go looks like it avoids renewing a lease
     if its expiration is in the past, but it's actually possible for it to
     still renew something that would have been considered expired here because
     of leader change, which sets expiry to "forever" before restarting it upon
     promotion. *)
  match σ.(EtcdState.lease_expiration) !! req.(LeaseKeepAliveRequest.ID) with
  | None => mret $ LeaseKeepAliveResponse.mk (W64 0) req.(LeaseKeepAliveRequest.ID)
  | Some expiration =>
      ttl ← do $ SuchThat (λ _, True);
      time ← do $ GetTime;
      let new_expiration_lower := (word.add time ttl) in
      let new_expiration := if decide (sint.Z new_expiration_lower < sint.Z expiration) then
                              expiration
                            else
                              new_expiration_lower in
      do $ SetState (set EtcdState.lease_expiration <[req.(LeaseKeepAliveRequest.ID) := new_expiration]> σ);;
      mret $ LeaseKeepAliveResponse.mk ttl req.(LeaseKeepAliveRequest.ID)
  end.

Module RangeRequest.
(* sort order *)
Definition NONE := (W32 0).
Definition ASCEND := (W32 1).
Definition DESCEND := (W32 2).

(* sort target *)
Definition KEY := (W32 0).
Definition VERSION := (W32 1).
Definition MOD := (W32 2).
Definition VALUE := (W32 3).

Record t :=
mk {
    key : list w8;
    range_end : list w8;
    limit : w64;
    revision : w64;
    sort_order : w32;
    sort_target : w32;
    serializable : bool;
    keys_only : bool;
    count_only : bool;
    min_mod_revision : w64;
    max_mod_revision : w64;
    min_create_revision : w64;
    max_create_revision : w64;
  }.
End RangeRequest.

Module RangeResponse.
Record t :=
mk {
    kvs : list KeyValue.t;
    more : bool;
    count : w64;
  }.
End RangeResponse.

Inductive Error :=
| Bad (msg : go_string).

(* txn.go:152 which calls kvstore_txn.go:72 *)
(* XXX:
   The etcd documentation states that if the sort_order is None, there will be "no sorting".
   In fact, the implementation seems to *always* return sorted results, as of
   https://github.com/etcd-io/etcd/issues/6671

   Nonetheless, this model is conservative and does not guarantee sortedness if
   sort_order == None.
 *)

(* XXX: cannot use `relation A` and `relation B` here because it causes universe
   inconsistency....
   Relatedly, [Set Universe Polymorphism.] causes the [Put] definition to be
   rejected.
 *)
Definition relation_pullback {A B} (f : A → B) (R : B → B → Prop) : (A → A → Prop) :=
  λ a1 a2, R (f a1) (f a2).

(* This should be eventually be defined in lang.v *)
Fixpoint go_string_ltb (x y : go_string) : bool :=
  match x, y with
  | [], [] => false
  | [], _ => true
  | _, [] => false
  | (a :: x), (b :: y) => if (word.ltu a b) then
                         true
                       else if (word.eqb a b) then
                              go_string_ltb x y
                            else false
  end.

Example go_string_ltb_examples :
  go_string_ltb "" "" = false ∧
  go_string_ltb "" "a" = true ∧
  go_string_ltb "a" "" = false ∧
  go_string_ltb "ab" "a" = false ∧
  go_string_ltb "ab" "b" = true
  := ltac:(auto).

Fixpoint go_string_lt (x y : go_string) : Prop :=
  match x, y with
  | [], [] => False
  | [], _ => True
  | _, [] => False
  | (a :: x), (b :: y) => if decide (uint.Z a < uint.Z b) then
                         True
                       else if decide (uint.Z a = uint.Z b) then
                              go_string_lt x y
                            else false
  end.

Definition kv_key_comp := (relation_pullback (KeyValue.key) go_string_lt).

Definition Range (req : RangeRequest.t) : ecomp etcdE (Error + RangeResponse.t) :=
interp handle_exceptionE (
  σ ← do $ Ok $ GetState;
  let current_revision := σ.(EtcdState.revision) in
  (if decide (sint.Z req.(RangeRequest.revision) > sint.Z current_revision) then
     (do $ Throw $ Bad "Future revision")
   else Pure ());;
  let rev := (if decide (sint.Z req.(RangeRequest.revision) < 0) then current_revision
              else req.(RangeRequest.revision))
  in
  kvs ← do $ Ok $ SuchThat (λ (kvs : list KeyValue.t), True); (* FIXME: say stuff about the range containing everything *)
  let kvs :=
    (if decide (req.(RangeRequest.max_mod_revision) ≠ W64 0) then
       filter (λ kv, sint.Z kv.(KeyValue.mod_revision) ≤ sint.Z req.(RangeRequest.max_mod_revision)) kvs
     else kvs) in
  let kvs :=
    (if decide (req.(RangeRequest.min_mod_revision) ≠ W64 0) then
       filter (λ kv,  sint.Z req.(RangeRequest.min_mod_revision) ≤ sint.Z kv.(KeyValue.mod_revision)) kvs
     else kvs) in
  let kvs :=
    (if decide (req.(RangeRequest.max_create_revision) ≠ W64 0) then
       filter (λ kv, sint.Z kv.(KeyValue.create_revision) ≤ sint.Z req.(RangeRequest.max_create_revision)) kvs
     else kvs) in
  let kvs :=
    (if decide (req.(RangeRequest.min_create_revision) ≠ W64 0) then
       filter (λ kv,  sint.Z req.(RangeRequest.min_create_revision) ≤ sint.Z kv.(KeyValue.create_revision)) kvs
     else kvs) in
  (* for sorting in ascending order; descending means flipping the order of the list. *)
  sort_relation ←
    (match uint.Z req.(RangeRequest.sort_target) with
     | (* KEY *) 0 => Pure (relation_pullback KeyValue.key go_string_lt)
     | _ => (do $ Ok (Assert False);; do $ Throw $ Bad "unreachable")
     end);
  (* | 0 => Pure (@id (list KeyValue.t)) (* XXX: the etcd implementation seems to sort even in this case. *) *)
  (do $ Throw $ Bad "Incomplete spec")
).

Module PutRequest.
Record t :=
mk {
    key : list w8;
    value : list w8;
    lease : w64;
    prev_kv : bool;
    ignore_value : bool;
    ignore_lease : bool;
  }.
Global Instance settable : Settable _ :=
  settable! mk < key; value; lease; prev_kv; ignore_value; ignore_lease>.
End PutRequest.

Module PutResponse.
Record t :=
mk {
    (* TODO: add response header *)
    (* header : ResponseHeader.t; *)
    prev_kv : option KeyValue.t;
  }.
Global Instance settable : Settable _ :=
  settable! mk < prev_kv>.
End PutResponse.

(* server/etcdserver/txn.go:58, then
   server/storage/mvcc/kvstore_txn.go:196 *)
Definition Put (req : PutRequest.t) : ecomp etcdE (Error + PutResponse.t) :=
interp handle_exceptionE (
  σ ← do $ Ok $ GetState;
  let kvs := default ∅ (σ.(EtcdState.key_values) !! σ.(EtcdState.revision)) in
  (* NOTE: could use [Range] here. *)
  let prev_kv := kvs !! req.(PutRequest.key) in

  (* compute value and lease, possibly throwing an error. *)
  value ← (if req.(PutRequest.ignore_value) then
             default (do $ Throw $ Bad "Key not found") ((Pure ∘ KeyValue.value) <$> prev_kv)
           else Pure req.(PutRequest.value));
  lease ← (if req.(PutRequest.ignore_lease) then
             default (do $ Throw $ Bad "Key not found") ((Pure ∘ KeyValue.lease) <$> prev_kv)
           else Pure req.(PutRequest.lease));

  let ret_prev_kv := (if req.(PutRequest.prev_kv) then prev_kv else None) in
  let prev_ver := default (W64 0) (KeyValue.version <$> prev_kv) in
  let ver := (word.add prev_ver (W64 1)) in (* should this handle overflow? *)
  let mod_revision := (word.add σ.(EtcdState.revision) 1) in
  let create_revision := default mod_revision (KeyValue.create_revision <$> prev_kv) in
  let new_kv := KeyValue.mk req.(PutRequest.key) create_revision mod_revision ver value lease in
  let σ := set EtcdState.key_values <[mod_revision := <[req.(PutRequest.key) := new_kv]> kvs]> σ in
  let σ := set EtcdState.revision (const mod_revision) σ in
  (* updating [key_values] handles attaching/detaching leases, since the map
        itself defines the association from LeaseID to Key. *)
  do $ Ok $ SetState $ σ;;
  Pure (PutResponse.mk ret_prev_kv)
).

Section spec.
Context `{hG: heapGS Σ, !ffi_semantics _ _}.
Definition Spec Resp := (Resp → iProp Σ) → iProp Σ.

Instance Spec_MRet : MRet Spec :=
  λ {Resp} resp Φ, Φ resp.

Instance Spec_MBind : MBind Spec :=
  λ {RespA RespB} (kmb : RespA → Spec RespB) (ma : Spec RespA) ΦB,
    ma (λ respa, kmb respa ΦB).

Context `{!ghost_varG Σ EtcdState.t}.

(* This is only in grove_ffi. *)
Axiom own_time : w64 → iProp Σ.

Definition handle_etcdE_spec (γ : gname) (A : Type) (e : etcdE A) : Spec A :=
  (match e with
   | GetState => λ Φ, (∃ σ q, ghost_var γ q σ ∗ (ghost_var γ q σ -∗ Φ σ))
   | SetState σ' => λ Φ, (∃ (_σ : EtcdState.t), ghost_var γ 1%Qp _σ ∗ (ghost_var γ 1%Qp σ' -∗ Φ tt))
   | GetTime => λ Φ, (∀ time, own_time time -∗ own_time time ∗ Φ time)
   | Assume P => λ Φ, (⌜ P ⌝ -∗ Φ ())
   | Assert P => λ Φ, (⌜ P ⌝ ∗ Φ ())
   | SuchThat pred => λ Φ, ∀ x, ⌜ pred x ⌝ -∗ Φ x
   end)%I.

Definition GrantSpec req γ := interp (handle_etcdE_spec γ) (LeaseGrant req).
Lemma test req γ :
  ⊢ ∀ Φ,
  (∃ (σ : EtcdState.t), ghost_var γ 1%Qp σ ∗
        (∀ resp (σ' : EtcdState.t), ghost_var γ 1%Qp σ' -∗ Φ resp)) -∗
  GrantSpec req γ Φ.
Proof.
  iIntros (?) "Hupd".
  unfold GrantSpec.
  unfold interp.
  simpl. unfold mbind, mret.
  unfold Spec_MBind, Spec_MRet, handle_etcdE_spec.
  simpl.
  iIntros "* _".
  iDestruct "Hupd" as (?) "[Hv Hupd]".
  repeat iExists _. iFrame.
  iIntros "Hv".
  simpl.
  destruct decide.
  {
    simpl.
    iIntros "* %Hnot".
    iIntros (?) "Htime".
    iFrame "Htime".
    iExists _; iFrame.
    iIntros "Hv".
    iApply "Hupd".
    iFrame.
  }
  {
    simpl.
    iSplitR.
    { admit. } (* need to prove this assert statement. *)
    iIntros (?) "Htime".
    iFrame "Htime".
    iExists _; iFrame.
    iIntros "Hv".
    iApply "Hupd".
    iFrame.
  }
Abort.
End spec.
