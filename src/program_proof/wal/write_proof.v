From RecordUpdate Require Import RecordSet.

From Perennial.program_proof Require Import disk_lib.
From Perennial.program_proof Require Import wal.invariant.

Section goose_lang.
Context `{!heapG Σ}.
Context `{!lockG Σ}.
Context `{!walG Σ}.

Implicit Types (v:val) (z:Z).
Implicit Types (γ: wal_names (Σ:=Σ)).
Implicit Types (s: log_state.t) (memLog: slidingM.t) (txns: list (u64 * list update.t)).
Implicit Types (pos: u64) (txn_id: nat).

Context (P: log_state.t -> iProp Σ).
Let N := walN.
Let circN := walN .@ "circ".

Definition memEnd (σ: locked_state): Z :=
  int.val σ.(memLog).(slidingM.start) + length σ.(memLog).(slidingM.log).

Hint Unfold memEnd : word.
Hint Unfold slidingM.endPos : word.
Hint Unfold slidingM.wf : word.
Hint Unfold slidingM.numMutable : word.

Theorem wp_WalogState__updatesOverflowU64 st σ (newUpdates: u64) :
  {{{ wal_linv_fields st σ }}}
    WalogState__updatesOverflowU64 #st #newUpdates
  {{{ (overflow:bool), RET #overflow; ⌜overflow = bool_decide (memEnd σ + int.val newUpdates >= 2^64)⌝ ∗
                                      wal_linv_fields st σ
  }}}.
Proof.
  iIntros (Φ) "Hfields HΦ".
  iNamed "Hfields".
  iNamed "Hfield_ptsto".
  (* iDestruct (updates_slice_len with "His_memLog") as %HmemLog_sz. *)
  wp_call.
  rewrite /WalogState__memEnd.
  wp_loadField. wp_apply (wp_sliding__end with "His_memLog"); iIntros "His_memLog".
  wp_apply util_proof.wp_SumOverflows.
  iIntros (?) "->".
  iApply "HΦ".
  iSplit.
  { iPureIntro.
    apply bool_decide_iff.
    word. }
  iFrame.
  iExists _; by iFrame "# ∗".
Qed.

Theorem wp_WalogState__memLogHasSpace st σ (newUpdates: u64) :
  memEnd σ + int.val newUpdates < 2^64 ->
  {{{ wal_linv_fields st σ }}}
    WalogState__memLogHasSpace #st #newUpdates
  {{{ (has_space:bool), RET #has_space; ⌜has_space = bool_decide (memEnd σ - int.val σ.(diskEnd) + int.val newUpdates ≤ LogSz)⌝ ∗
                                        wal_linv_fields st σ
  }}}.
Proof.
  iIntros (Hnon_overflow Φ) "Hfields HΦ".
  iNamed "Hfields".
  iNamed "Hfield_ptsto".
  (* iDestruct (updates_slice_len with "His_memLog") as %HmemLog_sz. *)
  wp_call.
  rewrite /WalogState__memEnd.
  wp_loadField. wp_apply (wp_sliding__end with "His_memLog"); iIntros "His_memLog".
  wp_loadField.
  wp_pures.
  change (int.val $ word.divu (word.sub 4096 8) 8) with LogSz.
  iAssert (wal_linv_fields st σ) with "[-HΦ]" as "Hfields".
  { iFrame.
    iExists _; by iFrame "# ∗". }
  wp_if_destruct; iApply "HΦ"; iFrame; iPureIntro.
  - symmetry; apply bool_decide_eq_false.
    revert Heqb; repeat word_cleanup.
  - symmetry; apply bool_decide_eq_true.
    revert Heqb; repeat word_cleanup.
Qed.

(* TODO: this intermediate function still provides no value, since it has
essentially the same spec as sliding.memWrite *)
Theorem wp_WalogState__doMemAppend l memLog bufs upds :
  {{{ "His_memLog" ∷ is_sliding l memLog ∗
      "Hupds" ∷ updates_slice_frag bufs 1 upds
  }}}
    doMemAppend #l (slice_val bufs)
  {{{ RET #(slidingM.endPos (memWrite memLog upds));
      "His_memLog" ∷ is_sliding l (memWrite memLog upds) }}}.
Proof.
Admitted.

Lemma is_wal_wf l γ σ :
  is_wal_inner l γ σ -∗ ⌜wal_wf σ⌝.
Proof.
  by iNamed 1.
Qed.

Theorem wp_Walog__MemAppend (PreQ : iProp Σ) (Q: u64 -> iProp Σ) l γ bufs bs :
  {{{ is_wal P l γ ∗
       updates_slice bufs bs ∗
       (∀ σ σ' pos,
         ⌜wal_wf σ⌝ -∗
         ⌜relation.denote (log_mem_append bs) σ σ' pos⌝ -∗
         let txn_id := length σ'.(log_state.txns) in
         (P σ ={⊤ ∖↑ N}=∗ P σ' ∗ (txn_pos γ txn_id pos -∗ Q pos))) ∧ PreQ
   }}}
    Walog__MemAppend #l (slice_val bufs)
  {{{ pos (ok : bool), RET (#pos, #ok); if ok then Q pos ∗ ∃ txn_id, txn_pos γ txn_id pos else PreQ }}}.
Proof.
  iIntros (Φ) "(#Hwal & Hbufs & Hfupd) HΦ".
  wp_call.
  iDestruct (updates_slice_to_frag with "Hbufs") as "Hbufs".
  iDestruct (updates_slice_frag_len with "Hbufs") as %Hbufs_sz.
  wp_apply wp_slice_len.
  wp_pures.
  change (int.val (word.divu (word.sub 4096 8) 8)) with LogSz.
  wp_if_destruct.
  - wp_pures.
    iApply "HΦ".
    iDestruct "Hfupd" as "[_ $]".
  - wp_apply wp_ref_to; [ by val_ty | iIntros (txn_l) "txn" ].
    wp_apply wp_ref_to; [ by val_ty | iIntros (ok_l) "ok" ].
    iMod (is_wal_read_mem with "Hwal") as "#Hmem".
    wp_pures.
    iNamed "Hmem".
    iNamed "Hstfields".
    wp_loadField.
    wp_apply (acquire_spec with "lk"); iIntros "(Hlocked&Hlockinv)".
    wp_loadField.
    wp_pures.
    wp_bind (For _ _ _).
    wp_apply (wp_forBreak_cond
                (fun b =>
                   ∃ (txn: u64) (ok: bool),
                     "txn" ∷ txn_l ↦[uint64T] #txn ∗
                     "ok" ∷ ok_l ↦[boolT] #ok ∗
                    "Hsim" ∷ (if b then
                               (∀ (σ σ' : log_state.t) pos,
                                ⌜wal_wf σ⌝
                                -∗ ⌜relation.denote (log_mem_append bs) σ σ' pos⌝
                                    -∗ P σ
                                      ={⊤ ∖ ↑N}=∗ P σ'
                                                  ∗ (txn_pos γ (length σ'.(log_state.txns)) pos
                                                      -∗ Q pos)) ∧ PreQ else
                               (if ok then Q txn else PreQ)) ∗
                     "Hlocked" ∷ locked γ.(lock_name) ∗
                     "Hlockinv" ∷ wal_linv σₛ.(wal_st) γ ∗
                     "Hbufs" ∷ if b then updates_slice_frag bufs 1 bs else emp
                )%I
                with  "[] [-HΦ]"
             ).
    2: { iExists _, _; iFrame. }
    { clear Φ.
      iIntros "!>" (Φ) "HI HΦ". iNamed "HI".
      wp_pures.
      (* hide postcondition from the IPM goal *)
      match goal with
      | |- context[Esnoc _ (INamed "HΦ") ?P] =>
        set (post:=P)
      end.
      wp_apply wp_slice_len.
      iNamed "Hlockinv".
      wp_apply (wp_WalogState__updatesOverflowU64 with "Hfields").
      iIntros (?) "[-> Hfields]".
      wp_pures.
      wp_if_destruct.
      { (* error path *)
        wp_store.
        wp_pures.
        iApply "HΦ".
        iExists _, _; iFrame.
        rewrite right_id.
        iDestruct "Hsim" as "[_ $]".
        iExists _; iFrame "# ∗". }
      wp_apply wp_slice_len.
      wp_apply (wp_WalogState__memLogHasSpace with "Hfields").
      { revert Heqb0; word. }
      iIntros (?) "[-> Hfields]".
      wp_if_destruct.
      - iNamed "Hfields". iNamed "Hfield_ptsto".
        wp_loadField.
        wp_apply (wp_WalogState__doMemAppend with "[$His_memLog $Hbufs]").
        set (memLog' := memWrite σ.(memLog) bs).
        iNamed 1.
        iDestruct "Hwal" as "[Hwal Hcirc]".
        rewrite -wp_fupd.
        wp_store.
        wp_bind Skip.
        iInv "Hwal" as (σ') "[Hinner HP]".
        wp_call.
        iDestruct (is_wal_wf with "Hinner") as %Hwal_wf.
        iDestruct "Hsim" as "[Hsim _]".
        iMod ("Hsim" $! _ (set log_state.txns (λ txns, txns ++ [(slidingM.endPos memLog', bs)]) σ') with "[% //] [%] [$HP]") as "[HP HQ]".
        { simpl; monad_simpl.
          eexists _ (slidingM.endPos memLog'); simpl; monad_simpl.
          econstructor; eauto.
          admit. (* new endpos should actually be the highest *)
        }
        admit.
      - wp_apply util_proof.wp_DPrintf.
        admit.
Admitted.

End goose_lang.
