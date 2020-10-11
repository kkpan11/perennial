From Perennial.program_proof.lockservice Require Import lockservice.
From iris.program_logic Require Export weakestpre.
From Perennial.goose_lang Require Import prelude.
From Perennial.goose_lang Require Import ffi.disk_prelude.
From Perennial.goose_lang Require Import notation.
From Perennial.program_proof Require Import proof_prelude.
From stdpp Require Import gmap.
From RecordUpdate Require Import RecordUpdate.
From Perennial.algebra Require Import auth_map fmcounter.
From Perennial.goose_lang.lib Require Import lock.
From Perennial.Helpers Require Import NamedProps.
From iris.algebra Require Import numbers.
From Coq.Structures Require Import OrdersTac.
Section lockservice_proof.
Context `{!heapG Σ}.

Implicit Types s : Slice.t.
Implicit Types (stk:stuckness) (E: coPset).

Axiom nondet_spec:
  {{{ True }}}
    nondet #()
  {{{ v, RET v; ⌜v = #true⌝ ∨ ⌜v = #false⌝}}}.

Record LockArgsC :=
  mkLockArgsC{
  Lockname:u64;
  CID:u64;
  Seq:u64
  }.
Instance: Settable LockArgsC := settable! mkLockArgsC <Lockname; CID; Seq>.

Record LockReplyC :=
  mkLockReplyC {
  OK:bool ;
  Stale:bool
  }.
Instance: Settable LockReplyC := settable! mkLockReplyC <OK; Stale>.

Global Instance ToVal_bool : into_val.IntoVal bool.
Proof.
  refine {| into_val.to_val := λ (x: bool), #x;
            IntoVal_def := false; |}; congruence.
Defined.

Definition locknameN (lockname : u64) := nroot .@ "lock" .@ lockname.

  Context `{!mapG Σ u64 (u64 * bool)}.
  Context `{!mapG Σ u64 bool}.
  Context `{!mapG Σ u64 u64}.
  Context `{!mapG Σ (u64*u64) (option bool)}.
  Context `{!mapG Σ (u64*u64) unit}.
  Context `{!inG Σ (exclR unitO)}.
  Context `{!inG Σ (gmapUR u64 fmcounterUR)}.
  Context `{!inG Σ (gmapUR u64 (lebnizO boolO))}.

  Parameter validLocknames : gmap u64 unit.

(* TODO: out of date, needs to be re-written *)
Definition own_clerk (ck:val) (srv:val) (γ:gname) (γrc:gname) : iProp Σ
  :=
  ∃ (ck_l:loc) (cid seq ls_seq : u64) (last_reply:bool),
    ⌜ck = #ck_l⌝
    ∗⌜int.val seq > int.val ls_seq⌝%Z
    ∗ck_l ↦[Clerk.S :: "cid"] #cid
    ∗ck_l ↦[Clerk.S :: "cid"] #seq
    ∗ck_l ↦[Clerk.S :: "primary"] srv
    ∗ (cid [[γrc]]↦ (ls_seq, last_reply))
       (*∗own γ (seq) *)
.

Definition fmcounter_map_own γ (k:u64) q n := own γ {[ k := (●{q}MaxNat n)]}.
Definition fmcounter_map_lb γ (k:u64) n := own γ {[ k := (◯MaxNat n)]}.

Notation "k fm[[ γ ]]↦{ q } n " := (fmcounter_map_own γ k q%Qp n)
(at level 20, format "k fm[[ γ ]]↦{ q }  n") : bi_scope.
Notation "k fm[[ γ ]]↦ n " := (k fm[[ γ ]]↦{ 1 } n)%I
(at level 20, format "k fm[[ γ ]]↦ n") : bi_scope.
Notation "k fm[[ γ ]]≥ n " := (fmcounter_map_lb γ k n)
(at level 20, format "k fm[[ γ ]]≥ n") : bi_scope.
Notation "k fm[[ γ ]]> n " := (fmcounter_map_lb γ k (n + 1))
(at level 20, format "k fm[[ γ ]]> n") : bi_scope.

Definition LockReq_inner (lockArgs:LockArgsC) γrc cseqγ (Ps:u64 -> iProp Σ) (Pγ:gname) : iProp Σ :=
   "#Hlseq_bound" ∷ lockArgs.(CID) fm[[cseqγ]]> int.nat lockArgs.(Seq)
  ∗ ("Hreply" ∷ (lockArgs.(CID), lockArgs.(Seq)) [[γrc]]↦ None ∨
      (∃ (last_reply:bool), (lockArgs.(CID), lockArgs.(Seq)) [[γrc]]↦ro Some last_reply
        ∗ (⌜last_reply = false⌝ ∨ (Ps lockArgs.(Lockname)) ∨ own Pγ (Excl ()))
      )
    )
.

Definition LockServer_inner (γrc γi cseqγ:gname) (Ps: u64 -> (iProp Σ)) : iProp Σ :=
  ∃ replyHistory:gmap (u64 * u64) (option bool),
      ("Hrcctx" ∷ map_ctx γrc 1 replyHistory)
    ∗ ("Hseq_lb" ∷ [∗ map] cid_seq ↦ _ ∈ replyHistory, cid_seq.1 fm[[cseqγ]]> int.nat cid_seq.2)
.

Definition own_lockserver (srv:loc) (γrc γi cseqγ:gname) (Ps: u64 -> (iProp Σ)) : iProp Σ :=
  ∃ (lastSeq_ptr lastReply_ptr locks_ptr:loc) (lastSeqM:gmap u64 u64)
    (lastReplyM locksM:gmap u64 bool),
      "HlastSeqOwn" ∷ srv ↦[LockServer.S :: "lastSeq"] #lastSeq_ptr
    ∗ "HlastReplyOwn" ∷ srv ↦[LockServer.S :: "lastReply"] #lastReply_ptr
    ∗ "HlocksOwn" ∷ srv ↦[LockServer.S :: "locks"] #locks_ptr

    ∗ "HlastSeqMap" ∷ is_map (lastSeq_ptr) lastSeqM
    ∗ "HlastReplyMap" ∷ is_map (lastReply_ptr) lastReplyM
    ∗ "HlocksMap" ∷ is_map (locks_ptr) locksM
    
    ∗ ("#Hrcagree" ∷ [∗ map] cid ↦ seq ; r ∈ lastSeqM ; lastReplyM, (cid, seq) [[γrc]]↦ro Some r)
    ∗ ("Hlockeds" ∷ [∗ map] ln ↦ locked ; _ ∈ locksM ; validLocknames, (⌜locked=true⌝ ∨ (Ps ln)))
.

(* Should make this readonly so it can be read by the RPC background thread *)
Definition read_lock_args (args_ptr:loc) (lockArgs:LockArgsC): iProp Σ :=
  "#HLockArgsOwnLockname" ∷ readonly (args_ptr ↦[LockArgs.S :: "Lockname"] #lockArgs.(Lockname))
  ∗ "#HLocknameValid" ∷ ⌜is_Some (validLocknames !! lockArgs.(Lockname))⌝
  ∗ "#HLockArgsOwnCID" ∷ readonly (args_ptr ↦[LockArgs.S :: "CID"] #lockArgs.(CID))
  ∗ "#HLockArgsOwnSeq" ∷ readonly (args_ptr ↦[LockArgs.S :: "Seq"] #lockArgs.(Seq))
.

Definition own_lockreply (args_ptr:loc) (lockReply:LockReplyC): iProp Σ :=
  "HreplyOK" ∷ args_ptr ↦[LockReply.S :: "OK"] #lockReply.(OK)
  ∗ "HreplyStale" ∷ args_ptr ↦[LockReply.S :: "Stale"] #lockReply.(Stale)
.

Definition lockserverinvN : namespace := nroot .@ "lockserverinv".

Definition is_lockserver srv γrc γi cseqγ Ps lockN: iProp Σ :=
  ∃ (mu_ptr:loc),
    "Hmuptr" ∷ readonly (srv ↦[LockServer.S :: "mu"] #mu_ptr)
    ∗ ( "Hlinv" ∷ inv lockserverinvN (LockServer_inner γrc γi cseqγ Ps ) )
    ∗ ( "Hmu" ∷ is_lock lockN #mu_ptr (own_lockserver srv γrc γi cseqγ Ps))
.

Instance inj_MaxNat_equiv : Inj eq equiv MaxNat.
Proof.
  intros n1 n2.
  intros ?%leibniz_equiv.
  inversion H0; auto.
Qed.

Print LockReq_inner.

Lemma TryLock_spec (srv args reply:loc) (lockArgs:LockArgsC) (lockReply:LockReplyC) (γrc γi cseqγ:gname) (Ps: u64 -> (iProp Σ)) P Pγ M lockN :
  Ps lockArgs.(Lockname) = P →
  {{{ "#Hls" ∷ is_lockserver srv γrc γi cseqγ Ps lockN
      ∗ "#HargsInv" ∷ inv M (LockReq_inner lockArgs γrc cseqγ Ps Pγ)
      ∗ "#Hargs" ∷ read_lock_args args lockArgs
      ∗ "Hreply" ∷ own_lockreply reply lockReply
  }}}
LockServer__TryLock #srv #args #reply
{{{ RET #false; ∃ lockReply', own_lockreply reply lockReply'
            ∗ (⌜lockReply'.(Stale) = true⌝ ∨ (lockArgs.(CID), lockArgs.(Seq)) [[γrc]]↦ro (Some lockReply'.(OK)))
}}}.
Proof.
  intros HPs.
  iIntros (Φ) "Hpre HPost".
  iNamed "Hpre".
  iNamed "Hargs"; iNamed "Hreply".
  wp_lam.
  wp_pures.
  iNamed "Hls".
  wp_loadField.
  wp_apply (acquire_spec lockN #mu_ptr _ with "Hmu").
  iIntros "(Hlocked & Hlsown)".
  iNamed "Hlsown".
  wp_seq.
  repeat wp_loadField.
  wp_apply (wp_MapGet with "HlastSeqMap").
  iIntros (v ok) "(HSeqMapGet&HlastSeqMap)"; iDestruct "HSeqMapGet" as %HSeqMapGet.
  wp_pures.
  destruct ok.
  - (* Case cid in lastSeqM *)
    apply map_get_true in HSeqMapGet.
    wp_storeField.
    wp_pures. repeat wp_loadField. wp_binop.
    destruct bool_decide eqn:Hineq.
    -- (* old seqno *)
      apply bool_decide_eq_true in Hineq.
      wp_pures. 
      wp_loadField. wp_binop.
      destruct bool_decide eqn:Hineqstrict.
      { (* Stale case *)
        wp_pures. wp_storeField. wp_loadField.
        wp_apply (release_spec lockN #mu_ptr _ with "[-HPost HreplyOK HreplyStale]"); iFrame; iFrame "#".
        { (* Re-establish own_lockserver *)
          iNext. iExists _, _, _, _,_,_. iFrame "#". iFrame.
        }
        wp_seq. iApply "HPost". iExists ({| OK := _; Stale := true |}); iFrame.
        iLeft. done.
      }
      (* Not stale *)
      assert (v = lockArgs.(Seq)) as ->. {
        (* not strict + non-strict ineq ==> eq *)
        apply bool_decide_eq_false in Hineqstrict.
        assert (int.val lockArgs.(Seq) = int.val v) by lia.
        by word.
      }
      wp_pures.
      repeat wp_loadField.
      wp_apply (wp_MapGet with "HlastReplyMap").
      iIntros (reply_v reply_get_ok) "(HlastReplyMapGet & HlastReplyMap)"; iDestruct "HlastReplyMapGet" as %HlastReplyMapGet.
      wp_storeField.
      iAssert ⌜reply_get_ok = true⌝%I as %->.
      { Check big_sepM2_eq. iDestruct (big_sepM2_lookup_1 _ _ _ lockArgs.(CID) with "Hrcagree") as "HH"; first done.
        iDestruct "HH" as (x B) "H".
        simpl. iPureIntro. unfold map_get in HlastReplyMapGet.
        revert HlastReplyMapGet.
        rewrite B. simpl. intros. injection HlastReplyMapGet. done.
        (* TODO: get a better proof of this... *)
      }
      apply map_get_true in HlastReplyMapGet.
      iDestruct (big_sepM2_delete with "Hrcagree") as "[#Hrcptsto _]"; eauto.
      wp_loadField.
      wp_apply (release_spec lockN #mu_ptr _ with "[-HPost HreplyOK HreplyStale]"); iFrame; iFrame "#".
      {
        iNext. iExists _,_,_,_,_,_; iFrame "#"; iFrame.
      }
      wp_seq. iApply "HPost". iExists {| OK:=_; Stale:=_ |}; iFrame.
      iRight. simpl. iFrame "#".
    -- (* new seqno *)
      apply bool_decide_eq_false in Hineq.
      rename Hineq into HnegatedIneq.
      assert (int.val lockArgs.(Seq) > int.val v)%Z as Hineq; first lia.
      wp_pures.
      wp_loadField.
      wp_loadField.
      wp_loadField.
      wp_apply (wp_MapInsert _ _ lastSeqM _ lockArgs.(Seq) (#lockArgs.(Seq)) with "HlastSeqMap"); try eauto.
      iIntros "HlastSeqMap".
      wp_pures.
      wp_loadField.
      wp_loadField.
      wp_apply (wp_MapGet with "HlocksMap").
      iIntros (lock_v ok) "(HLocksMapGet&HlocksMap)"; iDestruct "HLocksMapGet" as %HLocksMapGet.
      wp_pures.
      destruct lock_v.
      + (* Lock already held by someone *)
        wp_pures.
        wp_storeField.
        repeat wp_loadField.
        wp_apply (wp_MapInsert _ _ lastReplyM _ false #false with "HlastReplyMap"); first eauto; iIntros "HlastReplyMap".
        wp_seq. wp_loadField.
        iApply fupd_wp.
        iInv M as "[#>Hargseq_lb Hcases]" "HMClose".
        iDestruct "Hcases" as "[>Hunproc|Hproc]".
        {
          iInv lockserverinvN as ">HNinner" "HNClose"; first admit.
          (* Give unique namespaces to invariants *)
          iNamed "HNinner".
          iDestruct (map_update _ _ (Some false) with "Hrcctx Hunproc") as ">[Hrcctx Hrcptsto]".
          iDestruct (map_freeze with "Hrcctx Hrcptsto") as ">[Hrcctx #Hrcptsoro]".
          iDestruct (big_sepM_insert_2 _ _ (lockArgs.(CID), lockArgs.(Seq)) (Some false) with "[Hargseq_lb] Hseq_lb") as "Hseq_lb"; eauto.
          iMod ("HNClose" with "[Hrcctx Hseq_lb]") as "_".
          { iNext. iExists _; iFrame. }

          iMod ("HMClose" with "[]") as "_".
          { iNext. iFrame "#". iRight. iExists _; iFrame "#". by iLeft. }
          iModIntro.

          iDestruct (big_sepM2_insert_2 _ lastSeqM lastReplyM lockArgs.(CID) lockArgs.(Seq) false with "[Hargseq_lb] Hrcagree") as "Hrcagree2"; eauto.
          wp_apply (release_spec lockN #mu_ptr _ with "[-HreplyOK HreplyStale HPost]"); try iFrame "Hmu Hlocked".
          {
            iNext. iExists _, _, _, _, _, _; iFrame; iFrame "#".
          }
          wp_seq. iApply "HPost". iExists {| OK:=_; Stale:= _|}; iFrame.
          iRight. iFrame "#".
        }
        {
          iDestruct "Hproc" as (last_reply) "[#>Hrcptstoro Hcases]".
          iInv lockserverinvN as ">HNinner" "HNClose"; first admit.
          iNamed "HNinner".
        }



        
        iDestruct "HMinner" as (real_lseq) "[#>Hle [>Hlseq_own Hcases]]".
        assert (v = real_lseq) as Htemp; first admit. (* TODO: make this a lemma *)
        Check map_alloc.
        iAssert ⌜replyHistory !! (lockArgs.(CID), lockArgs.(Seq)) = None⌝%I as %HtempMap.
        {
          admit.
        }
        iMod (map_alloc_ro (lockArgs.(CID), lockArgs.(Seq)) (Some false) with "Hrcctx") as "[Hrcctx #Hrc_ptsto]"; first done.
        iDestruct (big_sepM_delete _ _ lockArgs.(CID) v with "Hownlseqγ") as "(Hlseq_frombigSep & Hlseqγauth)"; first done.
        Check own_update_2.
        destruct Htemp.
        iCombine "Hlseq_frombigSep Hlseq_own" as "Hcombined".
        iMod (own_update with "Hcombined") as "Hcombined".
        {
          eapply singleton_update.
          eapply auth_update_alloc.
          eapply (max_nat_local_update _ _ (MaxNat (int.nat lockArgs.(Seq)))). simpl. lia.
        }
        iDestruct "Hcombined" as "[[Hlseq_frombigSep Hlseq_own] Hfrag]".
        iDestruct (big_sepM_insert_delete with "[$Hlseqγauth $Hlseq_frombigSep]") as "Hlseqγauth".
        Check big_sepM_insert.
        iDestruct (big_sepM_insert _ _ (lockArgs.(CID), lockArgs.(Seq)) _ with "[$Hrc_lseqbound $Hfrag]") as "#Hrc_lseqbound2"; first done.
        iDestruct (big_sepM_insert _ _ (lockArgs.(CID), lockArgs.(Seq)) _ with "[$Htbd $Hrc_ptsto]") as "#Htbd2"; first done.
        
        iMod ("HMClose" with "[Hrc_ptsto Hcases Hlseq_own]") as "_".
        { iNext. iLeft. iExists _; iFrame. iFrame "#".
          iSplitL ""; first done. iRight. iExists false. iFrame "#".
          iSplitL ""; first done. by iLeft.
        }
        iModIntro.
        wp_apply (release_spec lockN #mu_ptr _ with "[-Hreply HPost]"); try iFrame "Hmu Hlocked".
        { (* Re-establish own_lockserver *)
          iNext. iExists _, _, _, _, _, _, _; try iFrame; try iFrame "#"; try iFrame "%".
          iPureIntro.
          split.
          {
            intros.
            admit.
          }
          {
            intros.
            admit.
          }
        }
        wp_seq.
        iApply "HPost".
        iExists false. iFrame. iFrame "#".
      + (* Lock not held by anyone *)
        wp_pures.
        wp_storeField.
        repeat wp_loadField.
        wp_apply (wp_MapInsert _ _ locksM _ true #true with "HlocksMap"); first eauto; iIntros "HlocksMap".
        wp_seq.
        repeat wp_loadField.
        wp_apply (wp_MapInsert _ _ lastReplyM _ true #true with "HlastReplyMap"); first eauto; iIntros "HlastReplyMap".
        wp_seq. wp_loadField.
        iApply fupd_wp.
        iInv M as "HMinner" "HMClose".
        iDestruct "HMinner" as "[HMinner|Hbad]"; last admit.
        iDestruct "HMinner" as (real_lseq) "[#>Hle [>Hlseq_own Hcases]]".
        assert (v = real_lseq) as Htemp; first admit. (* TODO: make this a lemma *)
        iAssert ⌜replyHistory !! (lockArgs.(CID), lockArgs.(Seq)) = None⌝%I as %HtempMap.
        {
          admit.
        }
        iMod (map_alloc_ro (lockArgs.(CID), lockArgs.(Seq)) (Some true) with "Hrcctx") as "[Hrcctx #Hrc_ptsto]"; first done.
        iDestruct (big_sepM_delete _ _ lockArgs.(CID) v with "Hownlseqγ") as "(Hlseq_frombigSep & Hlseqγauth)"; first done.
        destruct Htemp.
        iCombine "Hlseq_frombigSep Hlseq_own" as "Hcombined".
        iMod (own_update with "Hcombined") as "Hcombined".
        {
          eapply singleton_update.
          eapply auth_update_alloc.
          eapply (max_nat_local_update _ _ (MaxNat (int.nat lockArgs.(Seq)))). simpl. lia.
        }
        iDestruct "Hcombined" as "[[Hlseq_frombigSep Hlseq_own] Hfrag]".
        iDestruct (big_sepM_insert_delete with "[$Hlseqγauth $Hlseq_frombigSep]") as "Hlseqγauth".
        Check big_sepM_insert.
        iDestruct (big_sepM_insert _ _ (lockArgs.(CID), lockArgs.(Seq)) _ with "[$Hrc_lseqbound $Hfrag]") as "#Hrc_lseqbound2"; first done.
        iDestruct (big_sepM_insert _ _ (lockArgs.(CID), lockArgs.(Seq)) _ with "[$Htbd $Hrc_ptsto]") as "#Htbd2"; first done.
        
        iMod ("HMClose" with "[Hrc_ptsto Hcases Hlseq_own]") as "_".
        { iNext. iLeft. iExists _; iFrame. iFrame "#".
          iSplitL ""; first done. iRight. iExists true. iFrame "#".
          iSplitL ""; first done. iRight. iLeft.
          (* TODO: Get (Ps ln) here; need to know that lockname was in the locks map, or
             get (Ps ln) from somewhere else...*)
          admit.
        }
        iModIntro.
        wp_apply (release_spec lockN #mu_ptr _ with "[-Hreply HPost]"); try iFrame "Hmu Hlocked".
        { (* Re-establish own_lockserver *)
          iNext. iExists _, _, _, _, _, _, _; try iFrame; try iFrame "#"; try iFrame "%".
          (* TODO: Go back and update the locked big_sepM *)
          iPureIntro.
          split.
          {
            intros.
            admit.
          }
          {
            intros.
            admit.
          }
        }
        wp_seq.
        iApply "HPost".
        iExists false. iFrame. iFrame "#".








        

(*
        iApply fupd_wp.
        iInv M as "HMinner" "HCloseM".
        iDestruct "HMinner" as (lseq_fi _) "HMinner".
        iMod (map_update lockArgs.(CID) (lseq_fi, last_reply) (lockArgs.(Seq), false) with "Hmapctx Hptsto") as "(Hmapctx & Hptsto)".
        rewrite (map_insert_zip_with pair _ _ lockArgs.(CID) _ _).
        iMod ("HCloseM" with "[Hptsto]") as "_".
        { iModIntro.
          unfold CallTryLock_inv.
          iExists lockArgs.(Seq).
          admit. }
        iModIntro.
        wp_seq.
        wp_loadField.
        wp_apply (release_spec lockN #mu_ptr _ with "[-Hreply HPost]"); try iFrame "Hmu Hlocked".
        { (* Estanlish own_lockserver *)
          iNext. iFrame.
          iExists _, _, _, _, _, _; iFrame.
        }
        wp_seq. iApply ("HPost").
        iExists false. iFrame. by iRight.
      + (* Lock not held by anyone *)
        wp_pures. wp_storeField. repeat wp_loadField.
      wp_apply (wp_MapInsert _ _ locksM _ true #true with "HlocksMap"); first eauto; iIntros "HlocksMap".
      wp_seq. repeat wp_loadField.
      wp_apply (wp_MapInsert _ _ lastReplyM _ true #true with "HlastReplyMap"); first eauto; iIntros "HlastReplyMap".
      wp_seq.
      iDestruct (big_sepM_delete _ locksM lockArgs.(Lockname) false with "HPs") as "(HP & HPs)".
      { assert (ok=true); first admit. rewrite H in HLocksMapGet. admit. }
      iDestruct (big_sepM_insert _ (_) lockArgs.(Lockname) true with "[HPs]") as "HPs"; try iFrame.
      { admit. }
      { by iLeft. }
      rewrite (insert_delete).
      wp_loadField.
      wp_apply (release_spec lockN #mu_ptr _ with "[-Hreply HPost HP]").
      { (* Establish own_lockserver *)
        iFrame "Hmu Hlocked". iNext.
        iExists _, _, _, _, _, _; try iFrame.
        (* TODO: Update rc_γ *)
        admit.
      }
      iMod (inv_alloc N _ (P ∨ own Pγ (Excl ())) with "[HP]") as "Hescrow".
      {
        iNext. iDestruct "HP" as "[%|HP]"; first done.
        rewrite HPs. by iLeft.
      }
      wp_seq.
      iApply "HPost".
      iExists true. iFrame.
      iLeft. iSplit; try done.
Admitted.

Lemma CallTryLock_spec (srv reply args:loc) (lockArgs:LockArgsC) (lockReply:LockReplyC) (used:gset u64) rc_γ (Ps:u64 -> iProp Σ) P Pγ N M:
  lockArgs.(Lockname) ∈ used → Ps lockArgs.(Lockname) = P →
  {{{ "#HinvM" ∷ inv M (CallTryLock_inv lockArgs.(CID) rc_γ P Pγ N)
          ∗ "Hargs" ∷ read_lock_args args lockArgs
          ∗ "Hreply" ∷ own_lock_reply reply lockReply
  }}}
    CallTryLock #srv #args #reply
  {{{ v, RET v; ⌜v = #true⌝ ∨ ⌜v = #false⌝ ∗∃ ok, (⌜ok = false⌝ ∨ ⌜ok = true⌝∗(inv N (P ∨ own Pγ (Excl()))) ) ∗ reply ↦[LockReply.S :: "OK"] #ok }}}.
Proof.
  intros Hused Hp.
  iIntros (Φ).
  iNamed 1. iIntros "HPost".
  wp_lam.
  wp_pures.
  wp_apply wp_fork.
  { (* Background invocations of TryLock *)
    wp_bind (Alloc (_))%E.
    wp_apply wp_alloc_untyped; first by eauto.
    iIntros (l) "Hl".
    wp_pures.
    Search "wp_forBreak".
    wp_apply (wp_forBreak
                (fun b => ⌜b = true⌝%I)
             ); try eauto.
    {
      iIntros (Ψ) "_".
      iModIntro.
      iIntros "HPost".
      wp_pures.
      (*
      wp_apply (TryLock_spec with "[Hreply Hargs]"); try iFrame "HinvM Hreply Hargs".
      iIntros "HTryLockPost".
      wp_seq. by iApply "HPost".
    }
  }

  wp_pures.
  wp_apply (nondet_spec).
  iIntros (choice) "[Hv|Hv]"; iDestruct "Hv" as %->.
  { (* Actually return the reply from running TryLock *)
    wp_pures. 
    wp_apply (TryLock_spec); try iFrame "HinvM"; try apply Hp.
    iIntros "HTryLockPost".
    iDestruct "HTryLockPost" as (ok) "[[[Htrue Hescrow]|Hfalse] Hrc]".
    - (* TryLock succeeded *)
      iApply "HPost". iRight.
      iSplit; try done. iExists true. iDestruct "Htrue" as %->.
      iFrame. iRight. by iFrame.
    - (* TryLock failed *)
      iApply "HPost". iRight. iSplitL ""; try done. iDestruct "Hfalse" as %->.
      iExists false. iFrame. by iLeft.
  }
  { (* Don't return any reply from TryLock *)
    wp_pures.
    iApply "HPost". by iLeft.
  }
*)*)
Admitted.

(*
Lemma Lock_spec ck γ (ln:u64) (Ps: gmap u64 (iProp Σ)) (P: iProp Σ) :
  Ps !! ln = Some P →
  {{{ own_clerk ck γ }}}
    Clerk__Lock ck #ln
  {{{ RET #(); own_clerk ck γ ∗ P }}}.
Proof.
Admitted.

Lemma Unlock_spec ck γ (ln:u64) (Ps: gmap u64 (iProp Σ)) (P: iProp Σ) :
  Ps !! ln = Some P →
  {{{ P ∗ own_clerk ck γ }}}
    Clerk__Unlock ck #ln
  {{{ RET #(); own_clerk ck γ }}}
.
Proof.
Admitted.
 *)

End lockservice_proof.
