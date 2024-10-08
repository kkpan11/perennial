From Perennial.program_proof Require Import grove_prelude.
From Goose.github_com.mit_pdos.pav Require Import kt.

From Perennial.program_proof.pav Require Import misc cryptoffi merkle rpc invs chain.
From Perennial.program_proof Require Import std_proof.
From iris.unstable.base_logic Require Import mono_list.
From Perennial.base_logic Require Import ghost_map.

Section evidence.
Context `{!heapGS Σ, !pavG Σ}.

Definition is_signedLink pk (obj : signedLink.t) link : iProp Σ :=
  "#His_ln" ∷ is_link obj.(signedLink.epoch) obj.(signedLink.prevLink)
    obj.(signedLink.dig) link ∗
  "#His_sig" ∷ is_sig pk (servSepLink.encodesF (servSepLink.mk link)) obj.(signedLink.sig).

Lemma is_signedLink_agree_link pk obj link0 link1 :
  is_signedLink pk obj link0 -∗
  is_link obj.(signedLink.epoch) obj.(signedLink.prevLink)
    obj.(signedLink.dig) link1 -∗
  ⌜ link0 = link1 ⌝.
Proof.
  iIntros "H #His_ln'". iNamed "H".
  by iDestruct (is_link_func (_,_,_) with "His_ln His_ln'") as %<-.
Qed.

Lemma is_signedLink_agree_obj pk0 pk1 obj link0 link1 :
  is_signedLink pk0 obj link0 -∗
  is_signedLink pk1 obj link1 -∗
  ⌜ link0 = link1 ⌝.
Proof.
  iIntros "#His_sigLn0 H1". iNamedSuffix "H1" "1".
  by iDestruct (is_signedLink_agree_link with "His_sigLn0 His_ln1") as %<-.
Qed.

Definition is_signedPut pk (obj : signedPut.t) : iProp Σ :=
  "#His_sig" ∷ is_sig
    pk
    (servSepPut.encodesF (servSepPut.mk
      obj.(signedPut.epoch) obj.(signedPut.id) obj.(signedPut.val)))
    obj.(signedPut.sig).

Definition is_evidServLink pk (obj : evidServLink.t) : iProp Σ :=
  ∃ link0 link1,
  "#His_sigLn0" ∷ is_signedLink pk (obj.(evidServLink.sigLn0)) link0 ∗
  "#His_sigLn1" ∷ is_signedLink pk (obj.(evidServLink.sigLn1)) link1 ∗
  let epoch0 := obj.(evidServLink.sigLn0).(signedLink.epoch) in
  let epoch1 := obj.(evidServLink.sigLn1).(signedLink.epoch) in
  let prevLink1 := obj.(evidServLink.sigLn1).(signedLink.prevLink) in
  (* use nat equality for off-by-one case to prevent underflow
  and capture >= 0 requirement. *)
  "%Hneq_links" ∷ ⌜ (epoch0 = epoch1 ∧ link0 ≠ link1) ∨
    (S (uint.nat epoch0) = uint.nat epoch1 ∧ link0 ≠ prevLink1) ⌝.

Definition is_evidServPut pk (obj : evidServPut.t) : iProp Σ :=
  ∃ link,
  "#His_sigLn" ∷ is_signedLink pk (obj.(evidServPut.sigLn)) link ∗
  "#His_sigPut" ∷ is_signedPut pk (obj.(evidServPut.sigPut)) ∗
  "#His_proof" ∷ is_merkle_proof
    obj.(evidServPut.proof)
    obj.(evidServPut.sigPut).(signedPut.id)
    (Some obj.(evidServPut.val))
    (* sigLn.dig connects merkle proof to ghost state. *)
    obj.(evidServPut.sigLn).(signedLink.dig) ∗
  let epochLn := obj.(evidServPut.sigLn).(signedLink.epoch) in
  let epochPut := obj.(evidServPut.sigPut).(signedPut.epoch) in
  "%Heq_epochs" ∷ ⌜ epochLn = epochPut ⌝ ∗
  let val_sigPut := obj.(evidServPut.sigPut).(signedPut.val) in
  let val_merkle := obj.(evidServPut.val) in
  "%Hneq_vals" ∷ ⌜ val_sigPut ≠ val_merkle ⌝.

Lemma wp_signedLink_check ptr_sigLn sigLn sl_pk pk γ d0 :
  {{{
    "Hown" ∷ signedLink.own ptr_sigLn sigLn ∗
    "Hsl_pk" ∷ own_slice_small sl_pk byteT d0 pk ∗
    "#His_pk" ∷ is_pk pk (serv_sigpred γ)
  }}}
  signedLink__check #ptr_sigLn (slice_val sl_pk)
  {{{
    sl_link (link : list w8) (err : bool), RET (slice_val sl_link, #err);
    "Hown" ∷ signedLink.own ptr_sigLn sigLn ∗
    "Hsl_pk" ∷ own_slice_small sl_pk byteT d0 pk ∗
    "#Hsl_ln" ∷ own_slice_small sl_link byteT DfracDiscarded link ∗
    (* in no err case, this lets us learn enough about the link
    to tie down err cond. *)
    "#His_ln" ∷ is_link sigLn.(signedLink.epoch) sigLn.(signedLink.prevLink)
      sigLn.(signedLink.dig) link ∗
    "Hgenie" ∷ (is_signedLink pk sigLn link ∗-∗ ⌜ err = false ⌝)
  }}}.
Proof.
  rewrite /signedLink__check.
  iIntros (Φ) "H HΦ". iNamed "H". iNamed "Hown".

  (* encode link preimg. *)
  do 3 wp_loadField.
  wp_apply wp_allocStruct; [val_ty|].
  iIntros (?) "Hptr_pre".
  iDestruct (struct_fields_split with "Hptr_pre") as "H".
  iNamed "H". iClear "tag".
  iMod (own_slice_small_persist with "Hsl_prevLink") as "#Hsl_prevLink".
  iMod (own_slice_small_persist with "Hsl_dig") as "#Hsl_dig".
  wp_apply (chainSepSome.wp_encode (chainSepSome.mk _ _ _) with "[epoch prevLink data]").
  { rewrite /chainSepSome.own /=. iFrame "epoch data prevLink #". }
  iIntros (??). iNamedSuffix 1 "_pre".

  (* hash link. *)
  wp_apply (wp_Hash with "Hsl_enc_pre").
  iIntros (??). iNamedSuffix 1 "_pre".
  iMod (own_slice_small_persist with "Hhash_pre") as "#Hhash_pre".

  (* encode link sep. *)
  wp_apply wp_allocStruct; [val_ty|].
  iIntros (?) "H".
  iDestruct (struct_fields_split with "H") as "H".
  iNamed "H". iClear "tag".
  wp_apply (servSepLink.wp_encode (servSepLink.mk _) with "[link]").
  { rewrite /servSepLink.own /=. iFrame "link #". }
  iIntros (??). iNamedSuffix 1 "_sep".

  (* verify sig. *)
  wp_loadField.
  wp_apply (wp_Verify (serv_sigpred γ) with "[Hsl_pk Hsl_enc_sep Hsl_sig]").
  { iFrame. }
  iIntros (?). iNamed 1.

  (* postcond. *)
  wp_pures. iApply "HΦ".
  iFrame "Hptr_epoch Hptr_prevLink Hptr_dig Hptr_sig ∗#".
  iEval (rewrite /is_signedLink /is_link -Henc_pre -Henc_sep).
  iFrame "His_hash_pre".
  (* deal with various combos of ok and bi_iff. *)
  destruct ok; iIntros "!>"; iSplit.
  - naive_solver.
  - iDestruct "Hgenie" as "[_ Hgenie]".
    by iDestruct ("Hgenie" with "[//]") as "$".
  - iNamedSuffix 1 "'". iDestruct "Hgenie" as "[Hgenie _]".
    by iDestruct ("Hgenie" with "His_sig'") as %?.
  - by iIntros "%".
Qed.

Lemma wp_evidServLink_check ptr_evid evid sl_pk pk γ d0 :
  {{{
    "Hown" ∷ evidServLink.own ptr_evid evid ∗
    "Hsl_pk" ∷ own_slice_small sl_pk byteT d0 pk ∗
    "#His_pk" ∷ is_pk pk (serv_sigpred γ)
  }}}
  evidServLink__check #ptr_evid (slice_val sl_pk)
  {{{
    (err : bool), RET #err;
    "Hown" ∷ evidServLink.own ptr_evid evid ∗
    "Hsl_pk" ∷ own_slice_small sl_pk byteT d0 pk ∗
    "Hgenie" ∷ (is_evidServLink pk evid ∗-∗ ⌜ err = false ⌝) ∗
    "Herr" ∷ if negb err then False else True
  }}}.
Proof.
  rewrite /evidServLink__check.
  iIntros (Φ) "H HΦ". iNamed "H". iNamed "Hown".

  (* check signed links. *)
  wp_loadField.
  wp_apply (wp_signedLink_check with "[$Hown_sigLn0 $Hsl_pk $His_pk]").
  iIntros (???). iNamedSuffix 1 "0".
  wp_if_destruct.
  (* error. first signed link didn't validate. *)
  { iApply "HΦ". iFrame "Hown0 Hown_sigLn1 ∗".
    iIntros "!>". repeat iSplit; [|by iIntros "%"|done]. iNamed 1.
    iDestruct (is_signedLink_agree_link with "His_sigLn0 His_ln0") as %<-.
    iDestruct "Hgenie0" as "[Hgenie0 _]".
    iDestruct ("Hgenie0" with "[$]") as "$". }

  wp_loadField.
  wp_apply (wp_signedLink_check with "[$Hown_sigLn1 $Hsl_pk0 $His_pk]").
  iIntros (???). iNamedSuffix 1 "1".
  wp_if_destruct.
  (* error. second signed link didn't validate. *)
  { iApply "HΦ". iFrame "Hown0 Hown1 ∗".
    iIntros "!>". repeat iSplit; [|by iIntros "%"|done]. iNamed 1.
    iDestruct (is_signedLink_agree_link with "His_sigLn1 His_ln1") as %<-.
    iDestruct "Hgenie1" as "[Hgenie1 _]".
    iDestruct ("Hgenie1" with "[$]") as "$". }

  iDestruct "Hgenie0" as "[_ Hgenie0]".
  iDestruct ("Hgenie0" with "[//]") as "#His_sigLn0".
  iDestruct "Hgenie1" as "[_ Hgenie1]".
  iDestruct ("Hgenie1" with "[//]") as "#His_sigLn1".

  (* case: link epochs equal and links differ. *)
  iNamedSuffix "Hown0" "0". iNamedSuffix "Hown1" "1".
  do 4 wp_loadField.
  wp_if_destruct; move: Heqb1 => Heq_epoch0.
  { (* epochs equal. *)
    wp_apply (wp_BytesEqual with "[]"); [iFrame "#"|].
    iIntros "_".
    case_bool_decide as Heq_links; iApply "HΦ".
    - (* error. links same. *)
      iFrame "Hptr_sigLn0 ∗". repeat iSplit; [|by iIntros "%"|done].
      iNamedSuffix 1 "'".
      iDestruct (is_signedLink_agree_obj with "His_sigLn0 His_sigLn0'") as %<-.
      iDestruct (is_signedLink_agree_obj with "His_sigLn1 His_sigLn1'") as %<-.

      iPureIntro.
      destruct Hneq_links' as [[_ ?] | [Heq _]]; [done|].
      rewrite Heq_epoch0 in Heq. lia.
    - (* no error. links differ. *)
      iFrame "Hptr_sigLn0 ∗". iSplit.
      { iSplit; [naive_solver|].
        iIntros "_". iFrame "#". by iLeft. }
      iClear "His_ln0 His_ln1 Hsl_ln0 Hsl_ln1".
      iNamedSuffix "His_sigLn0" "0". iNamedSuffix "His_sigLn1" "1".
      (* TODO: maybe combine below steps into lemma.
      all the way from is_pk is_sig to inner link sigpred.
      in link sigpred, is_ln should be in outer def.
      from link sig, extract pred. *)
      iDestruct (is_sig_to_pred with "His_pk His_sig0") as "#HP0".
      iDestruct (is_sig_to_pred with "His_pk His_sig1") as "#HP1".
      iDestruct (serv_sigpred_know_link with "HP0") as "{HP0} HP0".
      iDestruct (serv_sigpred_know_link with "HP1") as "{HP1} HP1".
      iNamedSuffix "HP0" "0'". iNamedSuffix "HP1" "1'".
      iDestruct (is_link_inj (_,_,_) (_,_,_) with "His_ln0 His_ln0'") as %H. inv H.
      iDestruct (is_link_inj (_,_,_) (_,_,_) with "His_ln1 His_ln1'") as %H. inv H.
      iDestruct (is_com_st_links_prefix with "His_com0' His_com1'") as %Hpref.

      iPureIntro. rewrite -Heq_epoch0 in Hlook_ln1'.
      destruct Hpref as [Hpref | Hpref].
      (* contradiction: link0 differs from link1.
      they're at the same epoch of prefixed lists. *)
      + pose proof (prefix_lookup_Some _ _ _ _ Hlook_ln0' Hpref) as ?. naive_solver.
      + pose proof (prefix_lookup_Some _ _ _ _ Hlook_ln1' Hpref) as ?. naive_solver.
  }

  (* case: S epoch0 = epoch1 and link0 differs from prevLink1. *)
  wp_apply (wp_and' with "[-] [] []"); [iNamedAccu|..].
  { iNamed 1. do 2 wp_loadField. wp_pures. by iFrame "∗#". }
  { iNamed 1. iIntros "_". do 4 wp_loadField. wp_pures. by iFrame "∗#". }
  iNamed 1.

  (* we take two w64 props and show that they're equal to a nat prop.
  the latter can be more easily used in list lemmas. *)
  evar (tmp_cond : bool). wp_bind (If #?tmp_cond _ _).
  assert (tmp_cond =
    bool_decide (S (uint.nat evid.(evidServLink.sigLn0).(signedLink.epoch)) =
    uint.nat evid.(evidServLink.sigLn1).(signedLink.epoch))) as Htmp; subst tmp_cond.
  { replace (uint.Z (W64 0)) with (0%Z) by word.
    case_bool_decide as H10; case_bool_decide as H11.
    #[local] Ltac Zify.zify_post_hook ::= Z.div_mod_to_equations.
    - naive_solver.
    - destruct H10 as [H9 H10].
      apply inv_litint in H10.
      rewrite H10 word.unsigned_sub /word.wrap in H11. word.
    - apply Classical_Prop.not_and_or in H10 as [H10 | H10]; [lia|].
      apply u64_val_ne in H10.
      rewrite word.unsigned_sub /word.wrap in H10. word.
    - naive_solver. }
  rewrite Htmp {Htmp}.

  wp_if_destruct; move: Heqb1 => Heq_epoch1.
  { (* S epoch0 = epoch1. *)
    do 2 wp_loadField.
    wp_apply (wp_BytesEqual with "[Hsl_prevLink1]"); [iFrame "∗#"|].
    iIntros "[_ Hsl_prevLink1]".
    case_bool_decide as Heq_links; iApply "HΦ".
    - (* error. links same. *)
      iFrame "Hptr_sigLn0 ∗". repeat iSplit; [|by iIntros "%"|done].
      iNamedSuffix 1 "'".
      iDestruct (is_signedLink_agree_obj with "His_sigLn0 His_sigLn0'") as %<-.
      iDestruct (is_signedLink_agree_obj with "His_sigLn1 His_sigLn1'") as %<-.

      iPureIntro.
      destruct Hneq_links' as [[Heq _] | [_ ?]]; [|done].
      rewrite Heq in Heq_epoch0. naive_solver.
    - (* no error. links differ. *)
      iFrame "Hptr_sigLn0 ∗". iSplit.
      { iSplit; [naive_solver|].
        iIntros "_". iFrame "#". naive_solver. }
      iClear "His_ln0 His_ln1 Hsl_ln0 Hsl_ln1".
      iNamedSuffix "His_sigLn0" "0". iNamedSuffix "His_sigLn1" "1".
      iDestruct (is_sig_to_pred with "His_pk His_sig0") as "#HP0".
      iDestruct (is_sig_to_pred with "His_pk His_sig1") as "#HP1".
      iDestruct (serv_sigpred_know_link with "HP0") as "{HP0} HP0".
      iDestruct (serv_sigpred_know_link with "HP1") as "{HP1} HP1".
      iNamedSuffix "HP0" "0'". iNamedSuffix "HP1" "1'".
      iDestruct (is_link_inj (_,_,_) (_,_,_) with "His_ln0 His_ln0'") as %H. inv H.
      iDestruct (is_link_inj (_,_,_) (_,_,_) with "His_ln1 His_ln1'") as %H. inv H.
      iDestruct (is_com_st_links_prefix with "His_com0' His_com1'") as %Hpref.

      iClear "His_ln0' His_ln1' His_sig0 His_sig1".
      opose proof (lookup_lt_is_Some_2 com_st0.(links)
        (uint.nat evid.(evidServLink.sigLn0).(signedLink.epoch)) _)
        as [? Hlook_prevLn1].
      { opose proof (lookup_lt_is_Some_1 _ _ _) as ?.
        + eexists. exact Hlook_ln1'.
        + lia. }
      iNamedSuffix "His_com1'" "1".
      iDestruct (big_sepL_lookup with "Hlinks1") as "His_chain_prevLn1".
      { exact Hlook_prevLn1. }
      iDestruct (big_sepL_lookup with "Hlinks1") as "His_chain_ln1".
      { exact Hlook_ln1'. }

      opose proof (lookup_lt_is_Some_2 com_st0.(digs)
        (uint.nat evid.(evidServLink.sigLn0).(signedLink.epoch)) _) as [? Hlook_tmp].
      { opose proof (lookup_lt_is_Some_1 _ _ _) as ?.
        + eexists. exact Hlook_prevLn1.
        + lia. }
      opose proof (take_S_r _ _ _ _) as Htake_digs.
      { exact Hlook_tmp. }
      clear Hlook_tmp.
      iEval (rewrite -Heq_epoch1 Htake_digs) in "His_chain_ln1".

      iDestruct (is_chain_to_link with "His_chain_prevLn1 His_chain_ln1") as "His_ln1'".
      iDestruct (is_link_inj (_,_,_) (_,_,_) with "His_ln1 His_ln1'") as %H.
      inv H as [H1]. clear H1.

      iPureIntro. destruct Hpref as [Hpref | Hpref].
      (* contradiction: link0 differs from prevLink1.
      they're at the same epoch of prefixed lists. *)
      + pose proof (prefix_lookup_Some _ _ _ _ Hlook_ln0' Hpref) as ?. naive_solver.
      + pose proof (prefix_lookup_Some _ _ _ _ Hlook_prevLn1 Hpref) as ?. naive_solver.
  }

  (* failed both if conds, so no valid evid. *)
  iApply "HΦ".
  iFrame "Hptr_sigLn0 ∗". iIntros "!>". iSplit; [|done]. iSplit; [|by iIntros "%"].
  iNamedSuffix 1 "'".
  iDestruct (is_signedLink_agree_obj with "His_sigLn0 His_sigLn0'") as %<-.
  iDestruct (is_signedLink_agree_obj with "His_sigLn1 His_sigLn1'") as %<-.

  iPureIntro. destruct Hneq_links' as [[Heq _] | [Heq _]].
  - by rewrite Heq in Heq_epoch0.
  - by rewrite Heq in Heq_epoch1.
Qed.

Lemma wp_signedPut_check ptr_sigPut sigPut sl_pk pk d0 γ :
  {{{
    "Hown" ∷ signedPut.own ptr_sigPut sigPut ∗
    "Hsl_pk" ∷ own_slice_small sl_pk byteT d0 pk ∗
    "#Hpk" ∷ is_pk pk (serv_sigpred γ)
  }}}
  signedPut__check #ptr_sigPut (slice_val sl_pk)
  {{{
    (err : bool), RET #err;
    "Hown" ∷ signedPut.own ptr_sigPut sigPut ∗
    "Hsl_pk" ∷ own_slice_small sl_pk byteT d0 pk ∗
    "Hgenie" ∷ (is_signedPut pk sigPut ∗-∗ ⌜ err = false ⌝)
  }}}.
Proof.
  rewrite /signedPut__check.
  iIntros (Φ) "H HΦ". iNamed "H". iNamed "Hown".
  do 3 wp_loadField.
  wp_apply wp_allocStruct; [val_ty|].
  iIntros (?) "Hptr_sep".
  iDestruct (struct_fields_split with "Hptr_sep") as "H".
  iNamed "H". iClear "tag".
  wp_apply (servSepPut.wp_encode (servSepPut.mk _ _ _) with "[epoch id val Hsl_id Hsl_val]").
  { rewrite /servSepPut.own /=. iFrame "epoch id val ∗". }
  iIntros (??). iNamedSuffix 1 "_sep".
  wp_loadField.
  wp_apply (wp_Verify (serv_sigpred γ) with "[$Hsl_pk $Hsl_sig $Hsl_enc_sep]").
  iIntros (?). iNamedSuffix 1 "_ver".
  wp_pures. iApply "HΦ". iNamed "Hobj_sep".
  iFrame "Hptr_epoch Hptr_id Hptr_val Hptr_sig ∗".
  iEval (rewrite Henc_sep) in "Hgenie_ver".
  iIntros "!> /=". destruct ok; iSplit.
  - eauto.
  - iIntros "_". iDestruct "Hgenie_ver" as "[_ Hgenie_ver]".
    iDestruct ("Hgenie_ver" with "[//]") as "$".
  - iIntros "His_sigPut". iDestruct "Hgenie_ver" as "[Hgenie_ver _]".
    by iDestruct ("Hgenie_ver" with "His_sigPut") as %?.
  - by iIntros "%".
Qed.

Lemma wp_evidServPut_check ptr_evid evid sl_pk pk γ d0 :
  {{{
    "Hown_evid" ∷ evidServPut.own ptr_evid evid ∗
    "Hsl_pk" ∷ own_slice_small sl_pk byteT d0 pk ∗
    "#His_pk" ∷ is_pk pk (serv_sigpred γ)
  }}}
  evidServPut__check #ptr_evid (slice_val sl_pk)
  {{{
    (err : bool), RET #err;
    "Hown_evid" ∷ evidServPut.own ptr_evid evid ∗
    "Hsl_pk" ∷ own_slice_small sl_pk byteT d0 pk ∗
    "Hgenie" ∷ (is_evidServPut pk evid ∗-∗ ⌜ err = false ⌝) ∗
    "Herr" ∷ if negb err then False else True
  }}}.
Proof.
  rewrite /evidServPut__check.
  iIntros (Φ) "H HΦ". iNamed "H". iNamed "Hown_evid".

  wp_loadField.
  wp_apply (wp_signedLink_check with "[$Hown_sigLn $Hsl_pk $His_pk]").
  iIntros (???). iNamedSuffix 1 "_sigLn". iClear "Hsl_ln_sigLn".
  wp_if_destruct; move: Heqb => Heq_err0.
  { iApply "HΦ". iFrame "Hptr_sigLn Hptr_sigPut Hptr_val Hptr_proof ∗#".
    iIntros "!>". repeat iSplit; [|by iIntros "%"|done].
    iDestruct "Hgenie_sigLn" as "[Hgenie_sigLn _]". iNamed 1.
    iDestruct (is_signedLink_agree_link with "His_sigLn His_ln_sigLn") as %->.
    by iDestruct ("Hgenie_sigLn" with "His_sigLn") as %?. }

  wp_loadField.
  wp_apply (wp_signedPut_check with "[$Hown_sigPut $Hsl_pk_sigLn $His_pk]").
  iIntros (?). iNamedSuffix 1 "_sigPut".
  wp_if_destruct; move: Heqb => Heq_err1.
  { iApply "HΦ". iFrame "Hptr_sigLn Hptr_sigPut Hptr_val Hptr_proof ∗#".
    iIntros "!>". repeat iSplit; [|by iIntros "%"|done].
    iDestruct "Hgenie_sigPut" as "[Hgenie_sigPut _]". iNamed 1.
    by iDestruct ("Hgenie_sigPut" with "His_sigPut") as %?. }

  iNamedSuffix "Hown_sigLn" "_sigLn".
  iNamedSuffix "Hown_sigPut" "_sigPut".
  do 6 wp_loadField.
  wp_apply (wp_CheckProof with "[$Hsl_proof $Hsl_id_sigPut $Hsl_val $Hsl_dig_sigLn]").
  iIntros (?). iNamedSuffix 1 "_merk".
  wp_if_destruct; move: Heqb => Heq_err2.
  { iApply "HΦ". iFrame "Hptr_sigLn Hptr_sigPut Hptr_val Hptr_proof ∗#".
    iIntros "!>". repeat iSplit; [|by iIntros "%"|done].
    iDestruct "Hgenie_merk" as "[Hgenie_merk _]". iNamed 1.
    by iDestruct ("Hgenie_merk" with "His_proof") as %?. }
  do 4 wp_loadField.
  wp_if_destruct; move: Heqb => Heq_epochs.
  { iApply "HΦ". iFrame "Hptr_sigLn Hptr_sigPut Hptr_val Hptr_proof ∗#".
    iIntros "!>". repeat iSplit; [|by iIntros "%"|done].
    iNamedSuffix 1 "_contra". by rewrite Heq_epochs_contra in Heq_epochs. }
  do 3 wp_loadField.
  wp_apply (wp_BytesEqual with "[$Hsl_val_sigPut $Hval_merk]").
  iIntros "[Hsl_val_sigPut Hsl_val_merk]".

  iDestruct "Hgenie_sigLn" as "[_ Hgenie_sigLn]".
  iDestruct "Hgenie_sigPut" as "[_ Hgenie_sigPut]".
  iDestruct "Hgenie_merk" as "[_ Hgenie_merk]".
  iDestruct ("Hgenie_sigLn" with "[//]") as "#His_sigLn".
  iDestruct ("Hgenie_sigPut" with "[//]") as "#His_sigPut".
  iDestruct ("Hgenie_merk" with "[//]") as "#His_merk".
  iApply "HΦ". iFrame "Hptr_sigLn Hptr_sigPut Hptr_val Hptr_proof ∗#".
  case_bool_decide as Heq_val.
  { repeat iSplit; [|by iIntros "%"|done].
    iNamedSuffix 1 "_contra". by rewrite Heq_val in Hneq_vals_contra. }
  repeat iSplit.
  { by iIntros "_". }
  { iIntros "_". iFrame "#%". }
  (* derive contra.
  merkle proof and sigPut say, for a given id, diff vals are in their own maps.
  maps tied together by sigLn, which includes:
  1) the same dig as the merkle proof.
  2) the same epoch as the sigPut. *)
  iDestruct (is_merkle_proof_to_entry with "His_merk") as "His_entry".
  iNamedSuffix "His_sigLn" "_sigLn'".
  iDestruct (is_sig_to_pred with "His_pk His_sig_sigLn'") as "HP".
  iDestruct (serv_sigpred_know_link with "HP") as "{HP} HP". iNamed "HP".
  iDestruct (is_link_inj (_,_,_) (_,_,_) with "His_ln_sigLn His_ln") as %H. inv H.
  iClear "His_ln_sigLn His_sig_sigLn' Hsl_proof".
  iDestruct (serv_sigpred_link_get_all_state with "[]") as "Htmp".
  { iFrame "#%". }
  iNamed "Htmp".
  iDestruct (is_merkle_entry_with_map with "His_entry Hdig") as %Hlook_merk.
  (* TODO: don't know why this is needed. *)
  iEval (rewrite /is_signedPut) in "His_sigPut".
  iNamedSuffix "His_sigPut" "_sigPut".
  iDestruct (is_sig_to_pred with "His_pk His_sig_sigPut") as "HP".
  iDestruct (serv_sigpred_know_put with "HP") as "{HP} HP".
  iNamedSuffix "HP" "_sigPut". simpl. rewrite Heq_epochs.
  iDestruct (mono_list_idx_agree with "Hγmap Hidx_γmap_sigPut") as %<-.
  iDestruct (ghost_map_pers_lookup with "Hmap Hentry_sigPut") as %Hlook_sigPut.
  naive_solver.
Qed.

End evidence.
