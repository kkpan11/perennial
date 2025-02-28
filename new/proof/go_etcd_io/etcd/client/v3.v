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

Definition Handler E (M : Type → Type) := ∀ A (e : E A), M A.

Fixpoint denote {M E R}`{!MRet M} `{!MBind M} (handler : Handler E M) (e : ecomp E R) : M R :=
  match e with
  | Pure r => mret r
  | Effect e k => v ← handler _ e; denote handler (k v)
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

(** Effects for etcd specification, with return type [R]. This must be specified
    in the effect type to support early return. *)
Inductive etcdE {R : Type} : Type → Type :=
| Return {A} (r : R) : etcdE A
| Diverge : etcdE False
| SuchThat {A} (pred : A → Prop) : etcdE A
| GetState : etcdE EtcdState.t
| SetState (σ' : EtcdState.t) : etcdE unit
| GetTime : etcdE w64
| Assume (b : Prop) : etcdE unit
| Assert (b : Prop) : etcdE unit.

Arguments etcdE _ _ : clear implicits.

(* Establish monadicity of relation.t *)
Instance relation_mret A : MRet (relation.t A) :=
  λ {A} a, λ σ σ' a', a = a' ∧ σ' = σ.

Instance relation_mbind A : MBind (relation.t A) :=
  λ {A B} kmb ma, λ σ σ' b,
    ∃ a σmiddle,
      ma σ σmiddle a ∧
      kmb a σmiddle σ' b.

Inductive exceptionE R : Type → Type :=
| Throw {A} (r : R) : exceptionE R A.
Arguments Throw {_ _} (_).


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
Program Instance MBind_compose_exception `{mb:MBind M} R :
  MBind (M ∘ (sum R)) :=
  λ {A B} (kmb : A → M (R + B)%type),
    _
.
Abort.

Definition handle_exception R E : Handler (λ A, exceptionE R A + E A)%type (ecomp E) (sum R) :=
  λ A e,
    match e with
    | Throw r =>
    end
.

(* Handle etcd effects as a in the [relation.t EtcdState.t] monad. *)
Definition handler_etcdE (t : w64) R : Handler (etcdE R) (relation.t EtcdState.t) :=
  λ A e,
    match e with
    | Return r => λ σ σ' x, x = inl r
    | SuchThat pred => inl $ λ σ σ' x, ∃ a, x = inr a ∧ pred a ∧ σ' = σ
    | GetState => inl $ λ σ σ' ret, σ' = σ ∧ ret = inr σ
    | SetState σnew => inl $ λ σ σ' ret, σ' = σnew
    | GetTime => inl $ λ σ σ' tret, tret = t ∧ σ' = σ
    | Assume P => inl $ λ σ σ' tret, P ∧ σ = σ'
    | Assert P => inl $ λ σ σ' tret, (P → σ = σ')
    | Diverge => inl $ λ σ σ' _, False
    end.

Definition handler_etcdE t := from_simpler_handler (simpler_handler_etcdE t).

Definition interp {A} (time_of_execution : w64) (e : ecomp etcdE A) : relation.t EtcdState.t A :=
  denote2 (handler_etcdE time_of_execution) e.

Definition eff {E R} (e : E R) : ecomp E R := Effect2 e Ret.

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
  time ← eff GetTime;
  σ ← eff GetState;
  lease_id ← eff $ SuchThat (λ l, ∃ exp, σ.(EtcdState.lease_expiration) !! l = (Some exp) ∧
                                     uint.nat time > uint.nat exp);
  (* FIXME: delete attached keys *)
  eff $ SetState (set EtcdState.lease_expiration (delete lease_id) σ).

Lemma SingleSpontaneousTransition_monotonic (time time' : w64) σ σ' :
  uint.nat time < uint.nat time' →
  interp time SingleSpontaneousTransition σ σ' () →
  interp time' SingleSpontaneousTransition σ σ' ().
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
  num_steps ← eff $ SuchThat (λ (_ : nat), True);
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
  ttl ← eff $ SuchThat (λ ttl, uint.nat ttl > 0);
  σ ← eff GetState;
  lease_id ← (if decide (req.(LeaseGrantRequest.ID) = (W64 0)) then
                eff $ SuchThat (λ lease_id, lease_id ∉ σ.(EtcdState.used_lease_ids))
              else
                (eff $ Assert (req.(LeaseGrantRequest.ID) ∉ σ.(EtcdState.used_lease_ids));;
                 mret req.(LeaseGrantRequest.ID)));
  time ← eff GetTime;
  let σ := (set EtcdState.used_lease_ids (λ old, {[lease_id]} ∪ old) σ) in
  let σ := (set EtcdState.lease_expiration <[lease_id := (word.add time ttl)]> σ) in
  eff (SetState σ);;
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
  σ ← eff $ GetState;
  (* This is conservative. lessor.go looks like it avoids renewing a lease
     if its expiration is in the past, but it's actually possible for it to
     still renew something that would have been considered expired here because
     of leader change, which sets expiry to "forever" before restarting it upon
     promotion. *)
  match σ.(EtcdState.lease_expiration) !! req.(LeaseKeepAliveRequest.ID) with
  | None => mret $ LeaseKeepAliveResponse.mk (W64 0) req.(LeaseKeepAliveRequest.ID)
  | Some expiration =>
      ttl ← eff $ SuchThat (λ _, True);
      time ← eff $ GetTime;
      let new_expiration_lower := (word.add time ttl) in
      let new_expiration := if decide (sint.Z new_expiration_lower < sint.Z expiration) then
                              expiration
                            else
                              new_expiration_lower in
      eff $ SetState (set EtcdState.lease_expiration <[req.(LeaseKeepAliveRequest.ID) := new_expiration]> σ);;
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
    limit : list w8;
    revision : list w8;
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

Search (list _ → list _ → Prop).

Search order list.
(* Early return:

   EarlyReturn x; e

   Should equal `EarlyReturn x`
   interp
 *)
Definition key_le (key1 key2 : list w8) : bool :=
  match key1 key2 with
  | (_ :: _) nil =>
  end
.

(* txn.go:152 which calls
   kvstore_txn.go:72 *)
Definition Range (req : RangeRequest.t) : ecomp etcdE (option RangeResponse.t) :=
  kvs ← eff $ SuchThat
    (λ kvs,
       ∀ k,
       k ≥ req.(RangeRequest.key)
    );
  mret None
  (* computing over a gmap will be annoying *)
.

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
Definition Put (req : PutRequest.t) : ecomp etcdE (option PutResponse.t) :=
  SpontaneousTransition;;
  σ ← eff GetState;
  let kvs := default ∅ (σ.(EtcdState.key_values) !! σ.(EtcdState.revision)) in
  (* NOTE: could use [Range] here. *)
  let prev_kv := kvs !! req.(PutRequest.key) in

  (* The Go code uses early returns, which this mimics. *)
  let opt_computation :=
    (value ← (if req.(PutRequest.ignore_value) then KeyValue.value <$> prev_kv else mret req.(PutRequest.value));
     lease ← (if req.(PutRequest.ignore_lease) then KeyValue.lease <$> prev_kv else mret req.(PutRequest.lease));
     let ret_prev_kv := (if req.(PutRequest.prev_kv) then prev_kv else None) in
     let prev_ver := default (W64 0) (KeyValue.version <$> prev_kv) in
     let mod_revision := (word.add σ.(EtcdState.revision) 1) in
     let create_revision := default mod_revision (KeyValue.create_revision <$> prev_kv) in
     let ver := (word.add prev_ver (W64 1)) in (* should this handle overflow? *)
     let new_kv := KeyValue.mk req.(PutRequest.key) create_revision mod_revision ver value lease in
     let σ := set EtcdState.key_values <[mod_revision := <[req.(PutRequest.key) := new_kv]> kvs]> σ in
     let σ := set EtcdState.revision (const mod_revision) σ in
     (* updating [key_values] handles attaching/detaching leases, since the map
        itself defines the association from LeaseID to Key. *)
     Some (
         eff $ SetState $ σ;;
         Ret $ Some (PutResponse.mk ret_prev_kv)
    ))
  in
  match opt_computation with
  | None => Ret None
  | Some c => c
  end.

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

Definition GrantSpec req γ := denote (handle_etcdE_spec γ) (LeaseGrant req).
Lemma test req γ :
  ⊢ ∀ Φ,
  (∃ (σ : EtcdState.t), ghost_var γ 1%Qp σ ∗
        (∀ resp (σ' : EtcdState.t), ghost_var γ 1%Qp σ' -∗ Φ resp)) -∗
  GrantSpec req γ Φ.
Proof.
  iIntros (?) "Hupd".
  unfold GrantSpec.
  unfold denote.
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
