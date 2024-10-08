From iris.proofmode Require Import coq_tactics reduction.
From iris.proofmode Require Import tactics.
From iris.proofmode Require Import environments.
From Perennial.program_logic Require Import weakestpre.
From Perennial.goose_lang Require Import proofmode.
From New.golang.defn Require Export mem.
From New.golang.theory Require Import typing.
Require Import Coq.Program.Equality.

Set Default Proof Using "Type".

Section goose_lang.
  Context `{ffi_sem: ffi_semantics} `{!ffi_interp ffi} `{!heapGS Σ}.

  Definition typed_pointsto_def l (dq : dfrac) (t : go_type) (v : val) : iProp Σ :=
    (([∗ list] j↦vj ∈ flatten_struct v, (l +ₗ j) ↦{dq} vj) ∗ ⌜ has_go_type v t ⌝)%I.
  Definition typed_pointsto_aux : seal (@typed_pointsto_def). Proof. by eexists. Qed.
  Definition typed_pointsto := typed_pointsto_aux.(unseal).
  Definition typed_pointsto_unseal : @typed_pointsto = @typed_pointsto_def := typed_pointsto_aux.(seal_eq).

  Notation "l ↦[ t ] dq v" := (typed_pointsto l dq t v%V)
                                   (at level 20, dq custom dfrac at level 1, t at level 50,
                                    format "l  ↦[ t ] dq  v") : bi_scope.

  Ltac unseal := rewrite ?typed_pointsto_unseal /typed_pointsto_def.

  Global Instance typed_pointsto_timeless l t q v: Timeless (l ↦[t]{q} v).
  Proof. unseal. apply _. Qed.

  Global Instance typed_pointsto_persistent l t v: Persistent (l ↦[t]□ v).
  Proof. unseal. apply _. Qed.

  Global Instance typed_pointsto_fractional l t v: fractional.Fractional (λ q, l ↦[t]{#q} v)%I.
  Proof. unseal. apply _. Qed.

  Global Instance typed_pointsto_as_fractional l t v q: fractional.AsFractional
                                                     (l ↦[t]{#q} v)
                                                     (λ q, l ↦[t]{#q} v)%I q.
  Proof. constructor; auto. apply _. Qed.

  Global Instance list_val_inj:
    Inj (=) (=) list.val.
  Proof.
    rewrite list.val_unseal.
    intros ?? Heq.
    dependent induction x.
    - destruct y; done.
    - destruct y.
      + done.
      + inversion Heq. subst. f_equal. apply IHx. done.
  Qed.

  Global Instance struct_fields_val_inj :
    Inj (=) (=) struct.fields_val.
  Proof.
    rewrite struct.fields_val_unseal /struct.fields_val_def.
    intros ?? Heq.
    eapply inj in Heq; last apply _.
    eapply inj in Heq; first done.
    apply list_fmap_eq_inj.
    clear Heq x y.
    intros [][] Heq. simpl in *.
    inversion Heq; subst.
    done.
  Qed.

  Global Instance typed_pointsto_combine_sep_gives l t dq1 dq2 v1 v2 :
    CombineSepGives (l ↦[t]{dq1} v1)%I (l ↦[t]{dq2} v2)%I
                    ⌜ (go_type_size t > O → ✓(dq1 ⋅ dq2)) ∧ v1 = v2 ⌝%I.
  Proof.
    unfold CombineSepGives.
    unseal.
    rewrite go_type_size_unseal.
    iIntros "[[H1 %Hty1] [H2 %Hty2]]".
    rename l into l'.
    iInduction Hty1 as [] "IH" forall (l' v2 Hty2); subst.
    Local Ltac solve_combines := inversion Hty2; subst; rewrite ?slice.val_unseal ?interface.val_unseal;
                                 rewrite /= ?loc_add_0 ?right_id;
                                 iDestruct (heap_pointsto_agree with "[$]") as "%H";
                                 inversion H; subst; iCombine "H1 H2" gives %?; iModIntro; iPureIntro; split; naive_solver.
    all: try solve_combines; shelve.
    Unshelve.
    - (* arrays *)
      inversion_clear Hty2; subst.
      rewrite array.val_unseal /=.
      rename a0 into a'.
      iInduction a as [|? a] "IH2" forall (l' a' Hlen Helems0); destruct a' as [|? ]; try by exfalso.
      { iModIntro. iPureIntro. simpl. split; first (intros; lia); done. }
      iDestruct "H1" as "(Ha1 & Ha2)"; iDestruct "H2" as "(Hb1 & Hb2)".
      fold flatten_struct.
      iDestruct ("IH" with "[] [] Ha1 Hb1") as %[Hfrac1 Heq1].
      { iPureIntro. by left. }
      { iPureIntro. apply Helems0. by left. }
      subst.

      iDestruct ("IH2" with "[] [] [] [] [Ha2] [Hb2]") as %[Hfrac2 Heq2].
      { iPureIntro. intros. apply Helems. by right. }
      { iPureIntro. instantiate (1:=a'). by inversion Hlen. }
      { iPureIntro. intros. apply Helems0. by right. }
      { iModIntro. iIntros. iApply ("IH" with "[] [//] [$] [$]"). iPureIntro. by right. }
      { setoid_rewrite Nat2Z.inj_add. setoid_rewrite <- loc_add_assoc. iFrame. }
      { erewrite has_go_type_len; last (apply Helems0; by left).
        setoid_rewrite Nat2Z.inj_add. setoid_rewrite <- loc_add_assoc. iFrame. }
      iModIntro. iPureIntro. simpl.
      split.
      2:{ simpl in *. by rewrite Heq2. }
      intros.
      destruct (decide (go_type_size_def elem = O)).
      { eapply Hfrac2. lia. }
      { eapply Hfrac1. lia. }
    - (* structs*)
      inversion Hty2; subst; rewrite /= ?loc_add_0 ?right_id.
      rewrite struct.val_unseal.
      iInduction d as [|[] d] "IH2" forall (l' Hty2).
      { iModIntro. iPureIntro. split; first (intros; lia); done. }
      iDestruct "H1" as "(Ha1 & Ha2)"; iDestruct "H2" as "(Hb1 & Hb2)".
      fold flatten_struct struct.val.
      iDestruct ("IH" with "[] [] Ha1 Hb1") as %[Hfrac1 Heq1].
      { iPureIntro. by left. }
      { iPureIntro. apply Hfields0. by left. }

      iDestruct ("IH2" with "[] [] [] [] [Ha2] [Hb2]") as %[Hfrac2 Heq2].
      { iPureIntro. intros. apply Hfields. by right. }
      { iPureIntro. intros. apply Hfields0. by right. }
      { iPureIntro. constructor. intros. apply Hfields0. by right. }
      { iModIntro. iIntros. iApply ("IH" with "[] [//] [$] [$]"). iPureIntro. by right. }
      { setoid_rewrite Nat2Z.inj_add. setoid_rewrite <- loc_add_assoc. iFrame. }
      { erewrite has_go_type_len; last (apply Hfields0; by left).
        erewrite has_go_type_len; last (apply Hfields; by left).
        setoid_rewrite Nat2Z.inj_add. setoid_rewrite <- loc_add_assoc. iFrame. }
      iModIntro. iPureIntro. simpl.
      split.
      2:{ simpl in *. by rewrite Heq1 Heq2. }
      intros.
      destruct (decide (go_type_size_def g = O)).
      { eapply Hfrac2. lia. }
      { eapply Hfrac1. lia. }
  Qed.

  Lemma typed_pointsto_persist l t dq v :
    l ↦[t]{dq} v ==∗ l ↦[t]□ v.
  Proof.
    unseal. iIntros "[? $]".
    iApply big_sepL_bupd.
    iApply (big_sepL_impl with "[$]").
    iModIntro. iIntros.
    iApply (heap_pointsto_persist with "[$]").
  Qed.

  Lemma typed_pointsto_not_null l t dq v :
    go_type_size t > 0 →
    l ↦[t]{dq} v -∗ ⌜ l ≠ null ⌝.
  Proof.
    unseal. intros Hlen. iIntros "[? %Hty]".
    iInduction Hty as [] "IH"; subst;
    simpl; rewrite ?slice.val_unseal ?interface.val_unseal /= ?right_id ?loc_add_0;
      try (iApply heap_pointsto_non_null; by iFrame).
    - (* array *)
      rewrite go_type_size_unseal /= in Hlen.
      iInduction a as [|] "IH2"; simpl in *.
      { exfalso. lia. }
      rewrite array.val_unseal /=.
      destruct (decide (go_type_size_def elem = O)).
      {
        rewrite (nil_length_inv (flatten_struct a)).
        2:{
          erewrite has_go_type_len.
          { rewrite go_type_size_unseal. done. }
          apply Helems. by left.
        }
        rewrite app_nil_l.
        iApply ("IH2" with "[] [] [] [$]").
        - iPureIntro. intros. apply Helems. by right.
        - iPureIntro. lia.
        - iModIntro. iIntros. iApply ("IH" with "[] [] [$]").
          + iPureIntro. by right.
          + iPureIntro. lia.
      }
      {
        iDestruct select ([∗ list] _ ↦ _ ∈ _, _)%I as "[? _]".
        iApply ("IH" with "[] [] [$]").
        - iPureIntro. by left.
        - iPureIntro. rewrite go_type_size_unseal. lia.
      }
    - (* struct *)
      rewrite go_type_size_unseal /= in Hlen.
      iInduction d as [|[]] "IH2"; simpl in *.
    { exfalso. lia. }
    rewrite struct.val_unseal /=.
    destruct (decide (go_type_size_def g = O)).
    {
      rewrite (nil_length_inv (flatten_struct (default _ _))).
      2:{
        erewrite has_go_type_len.
        { rewrite go_type_size_unseal. done. }
        apply Hfields. by left.
      }
      rewrite app_nil_l.
      iApply ("IH2" with "[] [] [] [$]").
      - iPureIntro. intros. apply Hfields. by right.
      - iPureIntro. lia.
      - iModIntro. iIntros. iApply ("IH" with "[] [] [$]").
        + iPureIntro. by right.
        + iPureIntro. lia.
    }
    {
      iDestruct select ([∗ list] _ ↦ _ ∈ _, _)%I as "[? _]".
      iApply ("IH" with "[] [] [$]").
      - iPureIntro. by left.
      - iPureIntro. rewrite go_type_size_unseal. lia.
    }
  Qed.

  Local Lemma wp_AllocAt t stk E v :
    has_go_type v t ->
    {{{ True }}}
      ref v @ stk; E
    {{{ l, RET #l; l ↦[t] v }}}.
  Proof.
    iIntros (Hty Φ) "_ HΦ".
    wp_apply wp_allocN_seq; first by word.
    change (uint.nat 1) with 1%nat; simpl.
    iIntros (l) "[Hl _]".
    iApply "HΦ".
    unseal.
    iSplitL; auto.
    rewrite Z.mul_0_r loc_add_0.
    iFrame.
  Qed.

  Lemma wp_ref_ty t stk E v :
    has_go_type v t ->
    {{{ True }}}
      ref_ty t v @ stk; E
    {{{ l, RET #l; l ↦[t] v }}}.
  Proof.
    iIntros (Hty Φ) "_ HΦ".
    rewrite ref_ty_unseal.
    wp_rec. wp_pures.
    wp_apply (wp_AllocAt t); auto.
  Qed.

  Lemma wp_ref_of_zero stk E t :
    {{{ True }}}
      ref (zero_val t) @ stk; E
    {{{ l, RET #l; l ↦[t] (zero_val t) }}}.
  Proof.
    iIntros (Φ) "_ HΦ".
    wp_apply (wp_AllocAt t); eauto.
    apply zero_val_has_go_type.
  Qed.

  Lemma wp_typed_load stk E q l t v :
    {{{ ▷ l ↦[t]{q} v }}}
      load_ty t #l @ stk; E
    {{{ RET v; l ↦[t]{q} v }}}.
  Proof.
    iIntros (Φ) ">Hl HΦ".
    unseal.
    iDestruct "Hl" as "[Hl %Hty]".
    iAssert (▷ (([∗ list] j↦vj ∈ flatten_struct v, (l +ₗ j)↦{q} vj) -∗ Φ v))%I with "[HΦ]" as "HΦ".
    { iIntros "!> HPost".
      iApply "HΦ".
      iSplit; eauto. }
    rewrite load_ty_unseal.
    rename l into l'.
    iInduction Hty as [] "IH" forall (l' Φ) "HΦ".
    all: rewrite ?slice.val_unseal ?interface.val_unseal /= ?loc_add_0 ?right_id; wp_pures.
    all: try (wp_apply (wp_load with "[$]"); done).
    - (* case arrayT *)
      subst.
      rewrite array.val_unseal.
      iInduction a as [|] "IH2" forall (l' Φ).
      { wp_pures. iApply "HΦ". by iFrame. }
      wp_pures.
      iDestruct "Hl" as "[Hf Hl]".
      fold flatten_struct.
      wp_apply ("IH" with "[] Hf").
      { iPureIntro. by left. }
      iIntros "Hf".
      wp_pures.
      wp_apply ("IH2" with "[] [] [Hl]").
      { iPureIntro. intros. apply Helems. by right. }
      { iModIntro. iIntros. wp_apply ("IH" with "[] [$] [$]").
        iPureIntro. by right. }
      {
        erewrite has_go_type_len.
        2:{ eapply Helems. by left. }
        rewrite right_id. setoid_rewrite Nat2Z.inj_add. setoid_rewrite <- loc_add_assoc.
        iFrame.
      }
      iIntros "Hl".
      wp_pures.
      iApply "HΦ".
      iFrame.
      fold flatten_struct.
      erewrite has_go_type_len.
      2:{ eapply Helems. by left. }
      rewrite right_id. setoid_rewrite Nat2Z.inj_add. setoid_rewrite <- loc_add_assoc.
      by iFrame.
    - (* case structT *)
      rewrite struct.val_unseal.
      iInduction d as [|] "IH2" forall (l' Φ).
      { wp_pures. iApply "HΦ". by iFrame. }
      destruct a.
      wp_pures.
      iDestruct "Hl" as "[Hf Hl]".
      fold flatten_struct.
      wp_apply ("IH" with "[] Hf").
      { iPureIntro. by left. }
      iIntros "Hf".
      wp_pures.
      wp_apply ("IH2" with "[] [] [Hl]").
      { iPureIntro. intros. apply Hfields. by right. }
      { iModIntro. iIntros. wp_apply ("IH" with "[] [$] [$]").
        iPureIntro. by right. }
      {
        erewrite has_go_type_len.
        2:{ eapply Hfields. by left. }
        rewrite right_id. setoid_rewrite Nat2Z.inj_add. setoid_rewrite <- loc_add_assoc.
        iFrame.
      }
      iIntros "Hl".
      wp_pures.
      iApply "HΦ".
      iFrame.
      fold flatten_struct.
      erewrite has_go_type_len.
      2:{ eapply Hfields. by left. }
      rewrite right_id. setoid_rewrite Nat2Z.inj_add. setoid_rewrite <- loc_add_assoc.
      by iFrame.
  Qed.

  Lemma wp_store stk E l v v' :
    {{{ ▷ l ↦ v' }}} Store (Val $ LitV (LitLoc l)) (Val v) @ stk; E
    {{{ RET LitV LitUnit; l ↦ v }}}.
  Proof.
    iIntros (Φ) "Hl HΦ". rewrite /Store.
    wp_apply (wp_prepare_write with "Hl"); iIntros "[Hl Hl']".
    by wp_apply (wp_finish_store with "[$Hl $Hl']").
  Qed.

  Lemma wp_typed_store stk E l t v v' :
    has_go_type v' t ->
    {{{ ▷ l ↦[t] v }}}
      (#l <-[t] v')%V @ stk; E
    {{{ RET #(); l ↦[t] v' }}}.
  Proof.
    intros Hty.
    iIntros (Φ) ">Hl HΦ".
    unseal.
    iDestruct "Hl" as "[Hl %Hty_old]".
    iAssert (▷ (([∗ list] j↦vj ∈ flatten_struct v', (l +ₗ j)↦ vj) -∗ Φ #()))%I with "[HΦ]" as "HΦ".
    { iIntros "!> HPost".
      iApply "HΦ".
      iSplit; eauto. }
    rename l into l'.
    rewrite store_ty_unseal.
    iInduction Hty_old as [] "IH" forall (v' Hty l' Φ) "HΦ".
    all: inversion_clear Hty; subst; rewrite ?slice.val_unseal ?interface.val_unseal /= ?loc_add_0 ?right_id;
      wp_pures.
    all: try (wp_apply (wp_store with "[$]"); iIntros "H"; iApply "HΦ"; iFrame).
    - (* array *)
      rewrite array.val_unseal.
      rename a0 into a'.
      iInduction a as [|] "IH2" forall (l' a' Hlen0 Helems0).
      { simpl. wp_pures. iApply "HΦ". apply nil_length_inv in Hlen0.
        subst. done. }
      wp_pures.
      iDestruct "Hl" as "[Hf Hl]".
      fold flatten_struct.
      erewrite has_go_type_len.
      2:{ eapply Helems. by left. }
      setoid_rewrite Nat2Z.inj_add. setoid_rewrite <- loc_add_assoc.
      destruct a'; first by exfalso.
      wp_pures.
      wp_apply ("IH" with "[] [] [$Hf]").
      { iPureIntro. simpl. by left. }
      { iPureIntro. apply Helems0. by left. }
      iIntros "Hf".
      wp_pures.
      wp_apply ("IH2" with "[] [] [] [] [Hl]").
      { iPureIntro. intros. apply Helems. by right. }
      { iPureIntro. by inversion Hlen0. }
      { iPureIntro. intros. apply Helems0. by right. }
      { iModIntro. iIntros. wp_apply ("IH" with "[] [//] [$] [$]"). iPureIntro. by right. }
      { rewrite ?right_id. iFrame. }
      iIntros "Hl".
      iApply "HΦ".
      iFrame.
      fold flatten_struct.
      erewrite has_go_type_len.
      2:{ eapply Helems0. by left. }
      setoid_rewrite Nat2Z.inj_add. setoid_rewrite <- loc_add_assoc.
      rewrite ?right_id. iFrame.
    - (* struct *)
      rewrite struct.val_unseal.
      unfold struct.val_def.
      iInduction d as [|] "IH2" forall (l').
      { simpl. wp_pures. iApply "HΦ". done. }
      destruct a.
      wp_pures.
      iDestruct "Hl" as "[Hf Hl]".
      fold flatten_struct.
      erewrite has_go_type_len.
      2:{ eapply Hfields. by left. }
      setoid_rewrite Nat2Z.inj_add. setoid_rewrite <- loc_add_assoc.
      wp_apply ("IH" with "[] [] [$Hf]").
      { iPureIntro. simpl. by left. }
      { iPureIntro. apply Hfields0. by left. }
      iIntros "Hf".
      wp_pures.
      wp_apply ("IH2" with "[] [] [] [Hl]").
      { iPureIntro. intros. apply Hfields. by right. }
      { iPureIntro. intros. apply Hfields0. by right. }
      { iModIntro. iIntros. wp_apply ("IH" with "[] [//] [$] [$]"). iPureIntro. by right. }
      { rewrite ?right_id. iFrame. }
      iIntros "Hl".
      iApply "HΦ".
      iFrame.
      fold flatten_struct.
      erewrite has_go_type_len.
      2:{ eapply Hfields0. by left. }
      setoid_rewrite Nat2Z.inj_add. setoid_rewrite <- loc_add_assoc.
      rewrite ?right_id. iFrame.
  Qed.

  Lemma tac_wp_load_ty Δ Δ' s E i K l q t v Φ is_pers :
    MaybeIntoLaterNEnvs 1 Δ Δ' →
    envs_lookup i Δ' = Some (is_pers, typed_pointsto l q t v)%I →
    envs_entails Δ' (WP fill K (Val v) @ s; E {{ Φ }}) →
    envs_entails Δ (WP fill K (load_ty t (LitV l)) @ s; E {{ Φ }}).
  Proof.
    rewrite envs_entails_unseal=> ? ? Hwp.
    rewrite -wp_bind. eapply bi.wand_apply; first by apply bi.wand_entails, wp_typed_load.
    iIntros "H".
    rewrite into_laterN_env_sound -bi.later_sep envs_lookup_split //; simpl.
    iNext.
    destruct is_pers; simpl.
    + iDestruct "H" as "[#? H]". iFrame "#". iIntros.
      iSpecialize ("H" with "[$]"). by wp_apply Hwp.
    + iDestruct "H" as "[? H]". iFrame. iIntros.
      iSpecialize ("H" with "[$]"). by wp_apply Hwp.
  Qed.

  Lemma tac_wp_store_ty Δ Δ' Δ'' stk E i K l t v v' Φ :
    has_go_type v' t ->
    MaybeIntoLaterNEnvs 1 Δ Δ' →
    envs_lookup i Δ' = Some (false, l ↦[t] v)%I →
    envs_simple_replace i false (Esnoc Enil i (l ↦[t] v')) Δ' = Some Δ'' →
    envs_entails Δ'' (WP fill K (Val $ LitV LitUnit) @ stk; E {{ Φ }}) →
    envs_entails Δ (WP fill K (store_ty t (LitV l) v') @ stk; E {{ Φ }}).
  Proof.
    intros Hty.
    rewrite envs_entails_unseal=> ????.
    rewrite -wp_bind. eapply bi.wand_apply; first by eapply bi.wand_entails, wp_typed_store.
    rewrite into_laterN_env_sound -bi.later_sep envs_simple_replace_sound //; simpl.
    rewrite right_id. by apply bi.later_mono, bi.sep_mono_r, bi.wand_mono.
  Qed.

Definition is_primitive_type (t : go_type) : Prop :=
  match t with
  | structT d => False
  | arrayT n t => False
  | funcT => False
  | sliceT e => False
  | interfaceT => False
  | _ => True
  end.

Lemma wp_typed_cmpxchg_fail s E l dq v' v1 v2 t :
  is_primitive_type t →
  has_go_type v1 t →
  v' ≠ v1 →
  {{{ ▷ l ↦[t]{dq} v' }}} CmpXchg (Val $ LitV $ LitLoc l) (Val v1) (Val v2) @ s; E
  {{{ RET (v', #false); l ↦[t]{dq} v' }}}.
Proof.
  intros Hprim Hty Hne.
  iIntros (?) "Hl HΦ". unseal.
  iDestruct "Hl" as "[H >%Hty_old]".
  destruct t; try by exfalso.
  all: inversion Hty_old; subst; inversion Hty; subst;
    simpl; rewrite loc_add_0 right_id;
    wp_apply (wp_cmpxchg_fail with "[$]"); first done; first (by econstructor);
    iIntros; iApply "HΦ"; iFrame; done.
Qed.

Lemma wp_typed_cmpxchg_suc s E l v' v1 v2 t :
  is_primitive_type t →
  has_go_type v2 t →
  v' = v1 →
  {{{ ▷ l ↦[t] v' }}} CmpXchg (Val $ LitV $ LitLoc l) (Val v1) (Val v2) @ s; E
  {{{ RET (v', #true); l ↦[t] v2 }}}.
Proof.
  intros Hprim Hty Heq.
  iIntros (?) "Hl HΦ". unseal.
  iDestruct "Hl" as "[H >%Hty_old]".
  destruct t; try by exfalso.
  all: inversion Hty_old; subst;
    inversion Hty; subst;
    simpl; rewrite loc_add_0 right_id;
    wp_apply (wp_cmpxchg_suc with "[$H]"); first done; first (by econstructor);
    iIntros; iApply "HΦ"; iFrame; done.
Qed.

End goose_lang.

Notation "l ↦[ t ] dq v" := (typed_pointsto l dq t v%V)
                              (at level 20, dq custom dfrac at level 50, t at level 50,
                               format "l  ↦[ t ] dq  v") : bi_scope.

Create HintDb has_go_type.
Hint Constructors has_go_type : has_go_type.
Hint Resolve zero_val_has_go_type : has_go_type.

Tactic Notation "wp_alloc" ident(l) "as" constr(H) :=
  wp_apply wp_ref_ty;
  [ solve_has_go_type
  | iIntros (l) H ]
.

Tactic Notation "wp_load" :=
  let solve_pointsto _ :=
    let l := match goal with |- _ = Some (_, (?l ↦[_]{_} _)%I) => l end in
    iAssumptionCore || fail "wp_load: cannot find" l "↦[t] ?" in
  wp_pures;
  lazymatch goal with
  | |- envs_entails _ (wp ?s ?E ?e ?Q) =>
    ( first
        [reshape_expr e ltac:(fun K e' => eapply (tac_wp_load_ty _ _ _ _ _ K))
        |fail 1 "wp_load: cannot find 'load_ty' in" e];
      [tc_solve
      |solve_pointsto ()
      |wp_finish] )
  | _ => fail "wp_load: not a 'wp'"
  end.

Tactic Notation "wp_store" :=
  let solve_pointsto _ :=
    let l := match goal with |- _ = Some (_, (?l ↦[_] _)%I) => l end in
    iAssumptionCore || fail "wp_store: cannot find" l "↦[t] ?" in
  wp_pures;
  lazymatch goal with
  | |- envs_entails _ (wp ?s ?E ?e ?Q) =>
    first
      [reshape_expr e ltac:(fun K e' => eapply (tac_wp_store_ty _ _ _ _ _ _ K))
      |fail 1 "wp_store: cannot find 'store_ty' in" e];
    [(repeat econstructor || fail "could not establish [has_go_type]") (* solve [has_go_type v' t] *)
    |tc_solve
    |solve_pointsto ()
    |pm_reflexivity
    |first [wp_pure_filter (Rec BAnon BAnon _)|wp_finish]]
  | _ => fail "wp_store: not a 'wp'"
  end.
