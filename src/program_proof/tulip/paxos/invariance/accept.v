From Perennial.program_proof.tulip.paxos Require Import prelude.

Section accept.
  Context `{!paxos_ghostG Σ}.

  Lemma node_inv_accept {γ nids nid termc v} v' :
    (length v ≤ length v')%nat ->
    prefix_base_ledger γ termc v' -∗
    prefix_growing_ledger γ termc v' -∗
    own_current_term_half γ nid termc -∗
    own_node_ledger_half γ nid v -∗
    node_inv γ nids nid termc ==∗
    own_current_term_half γ nid termc ∗
    own_node_ledger_half γ nid v' ∗
    node_inv γ nids nid termc ∗
    is_accepted_proposal_lb γ nid termc v'.
  Proof.
    iIntros (Hlen) "#Hpfb #Hpfg HtermcX HlognX Hinv".
    iNamed "Hinv".
    (* Agreements. *)
    iDestruct (current_term_agree with "HtermcX Htermc") as %->.
    iDestruct (node_ledger_agree with "HlognX Hlogn") as %->.
    iAssert (⌜prefix v v'⌝)%I as %Hprefix.
    { iDestruct (accepted_proposal_lookup with "Hacpt Hpsa") as %Hlogn.
      iDestruct (big_sepM_lookup with "Hpsaubs") as (vub1) "[#Hvub1 %Hprefix1]"; first apply Hlogn.
      iDestruct "Hpfg" as (vub2) "[#Hvub2 %Hprefix2]".
      iDestruct (proposal_lb_prefix with "Hvub1 Hvub2") as %Hprefix.
      iPureIntro.
      destruct Hprefix as [Hprefix | Hprefix].
      { by apply (prefix_common_ub_length _ _ vub2 Hlen); first trans vub1. }
      { by apply (prefix_common_ub_length _ _ vub1 Hlen); last trans vub2. }
    }
    (* Update the node ledger. *)
    iMod (node_ledger_update v' with "HlognX Hlogn") as "[HlognX Hlogn]".
    (* Obtain [termc ∈ dom psa] to later re-establish [free_terms_after]. *)
    iDestruct (accepted_proposal_lookup with "Hacpt Hpsa") as %Hin.
    apply elem_of_dom_2 in Hin.
    (* Extend the accepted proposal at [term] from [logn] to [logn'] and extract a witness. *)
    iMod (accepted_proposal_update v' with "Hacpt Hpsa") as "[Hacpt Hpsa]".
    { apply Hprefix. }
    iDestruct (accepted_proposal_witness with "Hacpt") as "#Hacptlb'".
    (* Re-establish [safe_ledger] w.r.t. [v']. *)
    rewrite (take_prefix_le _ _ _ Hltlog Hprefix).
    iFrame "∗ # %".
    iModIntro.
    iSplit.
    { by iApply big_sepM_insert_2. }
    iSplit.
    { by iApply big_sepM_insert_2. }
    iPureIntro.
    split.
    { (* Re-establish [fixed_proposals]. *)
      intros t d Hd.
      destruct (decide (t = termc)) as [-> | Hne]; last first.
      { rewrite lookup_insert_ne; last done.
        by specialize (Hfixed _ _ Hd).
      }
      exfalso.
      (* Derive contradiction from [Hlends] and [Hd]. *)
      apply lookup_lt_Some in Hd.
      lia.
    }
    split.
    { (* Re-establish [free_terms_after]. *)
      rewrite dom_insert_L.
      by replace (_ ∪ _) with (dom psa) by set_solver.
    }
    { (* Re-establish [lsnc ≤ length v']. *)
      clear -Hlen Hltlog. lia.
    }
  Qed.

  Lemma paxos_inv_accept γ nids nid termc v v' :
    nid ∈ nids ->
    (length v ≤ length v')%nat ->
    prefix_base_ledger γ termc v' -∗
    prefix_growing_ledger γ termc v' -∗
    own_current_term_half γ nid termc -∗
    own_ledger_term_half γ nid termc -∗
    own_node_ledger_half γ nid v -∗
    paxos_inv γ nids ==∗
    own_current_term_half γ nid termc ∗
    own_ledger_term_half γ nid termc ∗
    own_node_ledger_half γ nid v' ∗
    paxos_inv γ nids ∗
    is_accepted_proposal_lb γ nid termc v'.
  Proof.
    iIntros (Hnid Hlen) "#Hpfb #Hpfg Htermc Hterml Hlogn Hinv".
    iNamed "Hinv".
    rewrite -Hdomtermlm elem_of_dom in Hnid.
    destruct Hnid as [terml' Hnid].
    iDestruct (big_sepM_lookup_acc _ _ nid with "Hnodes") as "[Hnode HnodesC]".
    { apply Hnid. }
    iDestruct (own_ledger_term_node_inv_terml_eq with "Hterml Hnode") as %->.
    (* Re-establish the node invariant. *)
    iMod (node_inv_accept with "Hpfb Hpfg Htermc Hlogn Hnode")
      as "(Htermc & Hlogn & Hnode & #Hacptlb')".
    { apply Hlen. }
    iDestruct ("HnodesC" with "Hnode") as "Hnodes".
    by iFrame "∗ # %".
  Qed.

End accept.