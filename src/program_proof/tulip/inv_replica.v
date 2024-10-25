From Perennial.program_proof Require Import grove_prelude.
From Perennial.program_proof.rsm.pure Require Import list.
From Perennial.program_proof.tulip Require Import base cmd res.
(* TODO: might be better to separate out the common definitions from [inv_group]. *)
From Perennial.program_proof.tulip Require Import inv_group.

Section inv.
  Context `{!tulip_ghostG Σ}.
  (* TODO: remove this once we have real defintions for resources. *)
  Implicit Type (γ : tulip_names).

  Definition safe_replica_prepare γ gid ts st : iProp Σ :=
    match st with
    | StPrepared pwrs => is_txn_pwrs γ gid ts pwrs
    | _ => True
    end.

  #[global]
  Instance safe_replica_prepare_persistent γ gid ts st :
    Persistent (safe_replica_prepare γ gid ts st).
  Proof. destruct st; apply _. Defined.

  Definition locked_key_validation vd pts :=
    pts ≠ O -> vd !! pts = Some true ∧ length vd = S pts.

  Definition validated_pwrs_of_txn γ gid rid vts : iProp Σ :=
    ∃ pwrs, is_txn_pwrs γ gid vts pwrs ∗
            ([∗ set] key ∈ dom pwrs, is_replica_key_validated_at γ gid rid key vts).

  Definition replica_inv_with_cm_with_stm
    γ (gid rid : u64) (cm : gmap nat bool) (stm : gmap nat txnst) : iProp Σ :=
    ∃ (clog : dblog) (vtss : gset nat) (kvdm : gmap dbkey (list bool))
      (histm : gmap dbkey dbhist) (ptsm : gmap dbkey nat),
      "Hvtss"     ∷ own_replica_validated_tss γ gid rid vtss ∗
      "Hkvdm"     ∷ ([∗ map] k ↦ vd ∈ kvdm, own_replica_key_validation γ gid rid k vd) ∗
      "#Hclog"    ∷ is_txn_log_lb γ gid clog ∗
      "#Hsafep"   ∷ ([∗ map] ts ↦ st ∈ stm, safe_replica_prepare γ gid ts st) ∗
      "#Hvpwrs"   ∷ ([∗ set] ts ∈ vtss, validated_pwrs_of_txn γ gid rid ts) ∗
      "%Hrsm"     ∷ ⌜apply_cmds clog = State cm histm⌝ ∗
      "%Hdomstm"  ∷ ⌜vtss ⊆ dom stm⌝ ∗
      "%Hdomptsm" ∷ ⌜dom ptsm = keys_all⌝ ∗
      "%Hlocked"  ∷ ⌜map_Forall2 (λ _ vd pts, locked_key_validation vd pts) kvdm ptsm⌝ ∗
      "%Hcm"      ∷ ⌜cm = omap txnst_to_option_bool stm⌝ ∗
      "%Hpil"     ∷ ⌜prepared_impl_locked stm ptsm⌝.

  Definition replica_inv γ (gid rid : u64) : iProp Σ :=
    ∃ cm stm, "Hrp" ∷ replica_inv_with_cm_with_stm γ gid rid cm stm.

  Definition replica_inv_xfinalized γ (gid rid : u64) (tss : gset nat) : iProp Σ :=
    ∃ cm stm,
      "Hrp"      ∷ replica_inv_with_cm_with_stm γ gid rid cm stm ∗
      "%Hxfinal" ∷ ⌜set_Forall (λ t, cm !! t = None) tss⌝.

  Lemma replica_inv_xfinalized_empty γ gid rid :
    replica_inv γ gid rid -∗
    replica_inv_xfinalized γ gid rid ∅.
  Proof. iNamed 1. iFrame. iPureIntro. apply set_Forall_empty. Qed.

  Lemma replicas_inv_xfinalized_empty γ gid rids :
    ([∗ set] rid ∈ rids, replica_inv γ gid rid) -∗
    ([∗ set] rid ∈ rids, replica_inv_xfinalized γ gid rid ∅).
  Proof.
    iIntros "Hreplicas".
    iApply (big_sepS_mono with "Hreplicas").
    iIntros (rid Hrid).
    iApply replica_inv_xfinalized_empty.
  Qed.

  Lemma replica_inv_xfinalized_validated_impl_prepared
    γ gid rid cm stm (tss : gset nat) ts :
    set_Forall (λ t, cm !! t = None) tss ->
    ts ∈ tss ->
    is_replica_validated_ts γ gid rid ts -∗
    replica_inv_with_cm_with_stm γ gid rid cm stm -∗
    ⌜∃ pwrs, stm !! ts = Some (StPrepared pwrs)⌝.
  Proof.
    iIntros (Hxfinal Hin) "Hvd Hrp".
    iNamed "Hrp".
    iDestruct (replica_validated_ts_elem_of with "Hvd Hvtss") as %Hinvtss.
    destruct (stm !! ts) as [st |] eqn:Hstm; last first.
    { exfalso.
      rewrite -not_elem_of_dom in Hstm.
      clear -Hdomstm Hinvtss Hstm. set_solver.
    }
    specialize (Hxfinal _ Hin). simpl in Hxfinal.
    destruct st as [pwrs | |]; last first.
    { exfalso. by rewrite Hcm lookup_omap Hstm in Hxfinal. }
    { exfalso. by rewrite Hcm lookup_omap Hstm in Hxfinal. }
    by eauto.
  Qed.

  Lemma replica_inv_validated_keys_of_txn γ gid rid ts :
    is_replica_validated_ts γ gid rid ts -∗
    replica_inv γ gid rid -∗
    validated_pwrs_of_txn γ gid rid ts.
  Proof.
    iIntros "#Hvd Hrp".
    do 2 iNamed "Hrp".
    iDestruct (replica_validated_ts_elem_of with "Hvd Hvtss") as %Hinvtss.
    by iDestruct (big_sepS_elem_of with "Hvpwrs") as "Hvts"; first apply Hinvtss.
  Qed.

  Lemma replicas_inv_validated_keys_of_txn γ gid rids ts :
    ([∗ set] rid ∈ rids, is_replica_validated_ts γ gid rid ts) -∗
    ([∗ set] rid ∈ rids, replica_inv γ gid rid) -∗
    ([∗ set] rid ∈ rids, validated_pwrs_of_txn γ gid rid ts).
  Proof.
    iIntros "#Hvds Hrps".
    iApply big_sepS_forall.
    iIntros (rid Hrid).
    iDestruct (big_sepS_elem_of with "Hvds") as "Hvd"; first apply Hrid.
    iDestruct (big_sepS_elem_of with "Hrps") as "Hrp"; first apply Hrid.
    iApply (replica_inv_validated_keys_of_txn with "Hvd Hrp").
  Qed.

End inv.
