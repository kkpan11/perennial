From iris.bi.lib Require Import fractional fixpoint_mono.
From Perennial.program_proof Require Import grove_prelude.
From Perennial Require Import base.
From Goose.github_com.mit_pdos.pav Require Import merkle.

From Perennial.Helpers Require Import bytes.
From Perennial.program_proof.pav Require Import cryptoffi cryptoutil.
From Perennial.program_proof Require Import std_proof marshal_stateless_proof.

Notation empty_node_tag := (W8 0) (only parsing).
Notation inner_node_tag := (W8 1) (only parsing).
Notation leaf_node_tag := (W8 2) (only parsing).

Module MerkleProof.
Record t :=
  mk {
    Siblings: list w8;
    d0: dfrac;
    LeafLabel: list w8;
    d1: dfrac;
    LeafVal: list w8;
    d2: dfrac;
  }.
Definition encodes (obj : t) : list w8 :=
  u64_le (length obj.(Siblings)) ++ obj.(Siblings) ++
  u64_le (length obj.(LeafLabel)) ++ obj.(LeafLabel) ++
  u64_le (length obj.(LeafVal)) ++ obj.(LeafVal).

Section defs.
Context `{!heapGS Σ}.
Definition own ptr obj : iProp Σ :=
  ∃ sl_sibs sl_leaf_label sl_leaf_val,
  "Hsl_sibs" ∷ own_slice_small sl_sibs byteT obj.(d0) obj.(Siblings) ∗
  "Hptr_sibs" ∷ ptr ↦[MerkleProof :: "Siblings"] (slice_val sl_sibs) ∗
  "Hsl_leaf_label" ∷ own_slice_small sl_leaf_label byteT obj.(d1) obj.(LeafLabel) ∗
  "Hptr_leaf_label" ∷ ptr ↦[MerkleProof :: "LeafLabel"] (slice_val sl_leaf_label) ∗
  "Hsl_leaf_val" ∷ own_slice_small sl_leaf_val byteT obj.(d2) obj.(LeafVal) ∗
  "Hptr_leaf_val" ∷ ptr ↦[MerkleProof :: "LeafVal"] (slice_val sl_leaf_val).

Lemma wp_dec sl_enc d0 enc :
  {{{
    "Hsl_enc" ∷ own_slice_small sl_enc byteT d0 enc
  }}}
  MerkleProofDecode (slice_val sl_enc)
  {{{
    ptr_obj sl_tail err, RET (#ptr_obj, slice_val sl_tail, #err);
    "Hgenie" ∷
      (⌜ err = false ⌝ ∗-∗
      ∃ obj tail,
      "%Henc_obj" ∷ ⌜ enc = encodes obj ++ tail ⌝) ∗
    "Herr" ∷
      (∀ obj tail,
      "%Henc_obj" ∷ ⌜ enc = encodes obj ++ tail ⌝
      -∗
      "Hown_obj" ∷ own ptr_obj obj ∗
      "Hsl_tail" ∷ own_slice_small sl_tail byteT d0 tail)
  }}}.
Proof. Admitted.

End defs.
End MerkleProof.

Section proof.
Context `{!heapGS Σ}.

Definition bytes_to_bits l := mjoin (byte_to_bits <$> l).

(* get_bit returns false if bit n of l is 0 (or the bit is past the length of l). *)
Definition get_bit l (n : nat) : bool :=
  match bytes_to_bits l !! n with
  | None => false
  | Some bit => bit
  end.

Inductive tree :=
| Empty
| Leaf (label: list w8) (val: list w8)
| Inner (child0: tree) (child1: tree)
| Cut (hash: list w8).

Fixpoint tree_path (t: tree) (label: list w8) (depth: nat)
    (result: option (list w8 * list w8)%type) : Prop :=
  match t with
  | Empty =>
    result = None
  | Leaf found_label found_val =>
    result = Some (found_label, found_val) ∧
    take depth (bytes_to_bits label) = take depth (bytes_to_bits found_label)
  | Inner child0 child1 =>
    match get_bit label depth with
    | false => tree_path child0 label (depth+1) result
    | true  => tree_path child1 label (depth+1) result
    end
  | Cut _ => False
  end.

Definition tree_map_reln (t : tree) (m : gmap (list w8) (list w8)) depth : Prop :=
  ∀ label, tree_path t label depth ((label,.) <$> m !! label).

(* TODO: rm once seal merged in. *)
Program Definition u64_le_seal := sealed @u64_le.
Definition u64_le_unseal : u64_le_seal = _ := seal_eq _.
Lemma u64_le_seal_len x :
  length $ u64_le_seal x = 8%nat.
Proof. Admitted.

Fixpoint is_tree_hash (t: tree) (h: list w8) : iProp Σ :=
  match t with
  | Empty =>
    "#His_hash" ∷ is_hash [empty_node_tag] h
  | Leaf label val =>
    "%Hlen_label" ∷ ⌜ length label = hash_len ⌝ ∗
    "#His_hash" ∷ is_hash ([leaf_node_tag] ++ label ++ (u64_le_seal $ length val) ++ val) h
  | Inner child0 child1 =>
    ∃ hl hr,
    "#Hleft_hash" ∷ is_tree_hash child0 hl ∗
    "#Hright_hash" ∷ is_tree_hash child1 hr ∗
    "#His_hash" ∷ is_hash ([inner_node_tag] ++ hl ++ hr) h
  | Cut ch =>
    "%Heq_cut" ∷ ⌜ h = ch ⌝ ∗
    "%Hlen_hash" ∷ ⌜ length h = hash_len ⌝
  end.

#[global]
Instance is_tree_hash_persistent t h : Persistent (is_tree_hash t h).
Proof. revert h. induction t; apply _. Qed.

Lemma is_tree_hash_len t h:
  is_tree_hash t h -∗
  ⌜length h = hash_len⌝.
Proof. destruct t; iNamed 1; [..|done]; by iApply is_hash_len. Qed.

Theorem tree_path_agree label depth found0 found1 h t0 t1:
  tree_path t0 label depth found0 →
  tree_path t1 label depth found1 →
  is_tree_hash t0 h -∗
  is_tree_hash t1 h -∗
  ⌜found0 = found1⌝.
Proof.
  iInduction t0 as [| ? | ? IH0 ? IH1 | ?] forall (depth t1 h);
    destruct t1; simpl; iIntros "*"; try done;
    iNamedSuffix 1 "0";
    iNamedSuffix 1 "1";
    iDestruct (is_hash_inj with "His_hash0 His_hash1") as %?;
    try naive_solver.

  (* both leaves. use leaf encoding. *)
  - iPureIntro. list_simplifier.
    apply app_inj_1 in H0; [naive_solver|].
    by rewrite !u64_le_seal_len.
  (* both inner. use inner encoding and next_pos same to get
  the same next_hash. then apply IH. *)
  - iDestruct (is_tree_hash_len with "Hleft_hash0") as %?.
    iDestruct (is_tree_hash_len with "Hleft_hash1") as %?.
    list_simplifier. case_match.
    + by iApply "IH1".
    + by iApply "IH0".
Qed.

Definition found_nonmemb (label: list w8) (found: option ((list w8) * (list w8))%type) :=
  match found with
  | None => True
  | Some (found_label, _) => label ≠ found_label
  end.

Definition is_merkle_map (m: gmap (list w8) (list w8)) (h: list w8) : iProp Σ :=
  ∃ t,
  ⌜ tree_map_reln t m 0 ⌝ ∗
  is_tree_hash t h.

Definition is_merkle_found (label: list w8)
    (found: option ((list w8) * (list w8))%type) (h: list w8) : iProp Σ :=
  ∃ t,
  ⌜tree_path t label 0 found⌝ ∗
  is_tree_hash t h.

Definition is_merkle_memb (label: list w8) (val: list w8) (h: list w8) : iProp Σ :=
  is_merkle_found label (Some (label, val)) h.

Definition is_merkle_nonmemb (label: list w8) (h: list w8) : iProp Σ :=
  ∃ found,
  is_merkle_found label found h ∗
  ⌜found_nonmemb label found⌝.

Fixpoint tree_sibs_proof (t: tree) (label: list w8) (depth: nat)
    (proof: list $ list w8) : iProp Σ :=
  match t with
  | Empty => ⌜proof = []⌝
  | Leaf found_label found_val => ⌜proof = []⌝
  | Inner child0 child1 =>
    ∃ sibhash proof',
    ⌜proof = sibhash :: proof'⌝ ∗
    match get_bit label depth with
    | false => tree_sibs_proof child0 label (depth+1) proof' ∗ is_tree_hash child1 sibhash
    | true  => tree_sibs_proof child1 label (depth+1) proof' ∗ is_tree_hash child0 sibhash
    end
  | Cut _ => False
  end.

Definition is_merkle_proof (label: list w8)
    (found: option ((list w8) * (list w8)%type)) (proof: list $ list w8)
    (h: list w8) : iProp Σ :=
  ∃ t,
  is_tree_hash t h ∗
  tree_sibs_proof t label 0 proof ∗
  ⌜tree_path t label 0 found⌝.

Definition own_merkle_tree_fix (recur : loc -d> tree -d> dfrac -d> iProp Σ) :
    loc -d> tree -d> dfrac -d> iProp Σ :=
  (λ ptr t d,
  ∃ hash,
  "#Htree_hash" ∷ is_tree_hash t hash ∗
  ( ⌜ ptr = null ⌝ ∗
    ⌜ t = Empty ⌝ ) ∨
  ( ⌜ ptr ≠ null ⌝ ∗
    ∃ sl_hash (ptr_child0 ptr_child1 : loc) sl_label sl_val,
    "Hptr_hash" ∷ ptr ↦[node :: "hash"]{d} (slice_val sl_hash) ∗
    "Hsl_hash" ∷ own_slice_small sl_hash byteT d hash ∗
    "Hptr_child0" ∷ ptr ↦[node :: "child0"]{d} #ptr_child0 ∗
    "Hptr_child1" ∷ ptr ↦[node :: "child1"]{d} #ptr_child1 ∗
    "Hptr_label" ∷ ptr ↦[node :: "label"]{d} (slice_val sl_label) ∗
    "Hptr_val" ∷ ptr ↦[node :: "val"]{d} (slice_val sl_val) ∗
    ( ∃ label val,
      ⌜ ptr_child0 = null ∧ ptr_child1 = null ⌝ ∗
      ⌜ t = Leaf label val ⌝ ∗
      "Hsl_label" ∷ own_slice_small sl_label byteT DfracDiscarded label ∗
      "Hsl_val" ∷ own_slice_small sl_val byteT DfracDiscarded val ) ∨
    ( ∃ child0 child1,
      ⌜ ptr_child0 ≠ null ∨ ptr_child1 ≠ null ⌝ ∗
      ⌜ t = Inner child0 child1 ⌝ ∗
      "Hown_child0" ∷ ▷ recur ptr_child0 child0 d ∗
      "Hown_child1" ∷ ▷ recur ptr_child1 child1 d ) ) )%I.

Local Instance own_merkle_tree_fix_contractive : Contractive own_merkle_tree_fix.
Proof.
  repeat intros ?.
  solve_proper_prepare.
  repeat (f_contractive || f_equiv); apply H.
Qed.

Definition own_merkle_tree :=
  fixpoint own_merkle_tree_fix.

Definition own_merkle_map_aux (ptr : loc) (t : tree)
    (m : gmap (list w8) (list w8)) depth d : iProp Σ :=
  ⌜ tree_map_reln t m depth ⌝ ∗
  own_merkle_tree ptr t d.

Definition own_merkle_map (ptr: loc) (m: gmap (list w8) (list w8)) d : iProp Σ :=
  ∃ t,
  ⌜ tree_map_reln t m 0 ⌝ ∗
  own_merkle_tree ptr t d.

(* Some facts that might be helpful to derive from the above: *)

Lemma own_merkle_map_to_is_merkle_map ptr m d:
  own_merkle_map ptr m d -∗
  ∃ h,
  is_merkle_map m h.
Proof.
  iIntros "H".
  iDestruct "H" as (t) "[% H]".
  destruct t; iDestruct "H" as (h) "[H _]"; iExists _; iFrame; iPureIntro; intuition eauto.
Qed.

Lemma is_merkle_proof_to_is_merkle_found label found proof h:
  is_merkle_proof label found proof h -∗
  is_merkle_found label found h.
Proof.
  iIntros "H".
  iDestruct "H" as (?) "(Ht & Hsib & %)".
  iExists _; iFrame. done.
Qed.

Lemma is_merkle_found_agree label found0 found1 h:
  is_merkle_found label found0 h -∗
  is_merkle_found label found1 h -∗
  ⌜found0 = found1⌝.
Proof.
  iIntros "H0 H1".
  iDestruct "H0" as (?) "[% H0]".
  iDestruct "H1" as (?) "[% H1]".
  iApply (tree_path_agree with "H0 H1"); eauto.
Qed.

Lemma is_merkle_map_agree_is_merkle_found m h label found:
  is_merkle_map m h -∗
  is_merkle_found label found h -∗
  ⌜ match m !! label with
  | None => found_nonmemb label found
  | Some val => found = Some (label, val)
  end ⌝.
Proof.
  iIntros "[% [%Hreln Hhash0]] [% [%Hpath1 Hhash1]]".
  opose proof (Hreln label) as Hpath0.
  iDestruct (tree_path_agree with "Hhash0 Hhash1") as %Heq; [done..|].
  iPureIntro. case_match; [done|naive_solver].
Qed.

(* Program proofs. *)

Lemma wp_compEmptyHash :
  {{{ True }}}
  compEmptyHash #()
  {{{
    sl_hash hash, RET (slice_val sl_hash);
    "Hsl_hash" ∷ own_slice sl_hash byteT (DfracOwn 1) hash ∗
    "#His_hash" ∷ is_hash [empty_node_tag] hash
  }}}.
Proof. Admitted.

Lemma wp_compLeafHash sl_label sl_val d0 d1 (label val : list w8) :
  {{{
    "Hsl_label" ∷ own_slice_small sl_label byteT d0 label ∗
    "Hsl_val" ∷ own_slice_small sl_val byteT d1 val
  }}}
  compLeafHash (slice_val sl_label) (slice_val sl_val)
  {{{
    sl_hash hash, RET (slice_val sl_hash);
    "Hsl_label" ∷ own_slice_small sl_label byteT d0 label ∗
    "Hsl_val" ∷ own_slice_small sl_val byteT d1 val ∗
    "Hsl_hash" ∷ own_slice sl_hash byteT (DfracOwn 1) hash ∗
    "#His_hash" ∷ is_hash
      (leaf_node_tag :: label ++ (u64_le_seal $ length val) ++ val) hash
  }}}.
Proof. Admitted.

Lemma wp_compInnerHash sl_child0 sl_child1 sl_hash_in d0 d1 (child0 child1 : list w8) :
  {{{
    "Hsl_child0" ∷ own_slice_small sl_child0 byteT d0 child0 ∗
    "Hsl_child1" ∷ own_slice_small sl_child1 byteT d1 child1 ∗
    "Hsl_hash_in" ∷ own_slice sl_hash_in byteT (DfracOwn 1) ([] : list w8)
  }}}
  compInnerHash (slice_val sl_child0) (slice_val sl_child1) (slice_val sl_hash_in)
  {{{
    sl_hash_out hash, RET (slice_val sl_hash_out);
    "Hsl_child0" ∷ own_slice_small sl_child0 byteT d0 child0 ∗
    "Hsl_child1" ∷ own_slice_small sl_child1 byteT d1 child1 ∗
    "Hsl_hash_out" ∷ own_slice sl_hash_out byteT (DfracOwn 1) hash ∗
    "#His_hash" ∷ is_hash (inner_node_tag :: child0 ++ child1) hash
  }}}.
Proof. Admitted.

Lemma wp_getBit sl_b d0 (b : list w8) (n : w64) :
  {{{
    "Hsl_b" ∷ own_slice_small sl_b byteT d0 b ∗
    "%Hinb" ∷ ⌜ uint.nat n < length b * 8 ⌝
  }}}
  getBit (slice_val sl_b) #n
  {{{
    pos, RET #pos;
    "Hsl_b" ∷ own_slice_small sl_b byteT d0 b ∗
    "%Hget_bit" ∷ ⌜ get_bit b (uint.nat n) = pos ⌝
  }}}.
Proof. Admitted.

Definition own_context ptr d : iProp Σ :=
  ∃ sl_empty_hash empty_hash,
  "Hptr_empty_hash" ∷ ptr ↦[context :: "emptyHash"]{d} (slice_val sl_empty_hash) ∗
  "Hsl_empty_hash" ∷ own_slice_small sl_empty_hash byteT d empty_hash ∗
  "#His_empty_hash" ∷ is_hash [empty_node_tag] empty_hash.

Global Instance own_context_fractional ptr :
  Fractional (λ q, own_context ptr (DfracOwn q)).
Proof.
  intros ??. iSplit.
  - iNamed 1.
    iDestruct "Hptr_empty_hash" as "[H0 H1]".
    iDestruct "Hsl_empty_hash" as "[H2 H3]".
    iSplitL "H0 H2"; iFrame "∗#".
  - iIntros "[H0 H1]". iNamedSuffix "H0" "0". iNamedSuffix "H1" "1".

    iDestruct (struct_field_pointsto_agree with "Hptr_empty_hash0 Hptr_empty_hash1") as %Heq.
    destruct sl_empty_hash, sl_empty_hash0. simplify_eq/=.
    iCombine "Hptr_empty_hash0 Hptr_empty_hash1" as "H0".

    iDestruct (own_slice_small_agree with "Hsl_empty_hash0 Hsl_empty_hash1") as %->.
    iCombine "Hsl_empty_hash0 Hsl_empty_hash1" as "H1".

    iFrame "∗#".
Qed.

Global Instance own_context_as_fractional ptr q :
  AsFractional (own_context ptr (DfracOwn q)) (λ q, own_context ptr (DfracOwn q)) q.
Proof. split; [auto|apply _]. Qed.

Lemma own_nil_tree t d :
  own_merkle_tree null t d -∗
  ⌜ t = Empty ⌝.
Proof.
  iIntros "Htree". destruct t; [done|iExFalso..].
  - iNamed "Htree". iNamed "Htree".
    iDestruct (struct_field_pointsto_not_null with "Hptr_child0") as %Heq.
    (* annoying reasoning here. *)
    { admit. }
    { admit. }
    done.
  - admit.
  - admit.
Admitted.

Lemma own_nil_map m depth :
  tree_map_reln Empty m depth →
  m = ∅.
Proof.
  intros Hreln.
  apply map_empty. intros label. specialize (Hreln label).
  by destruct (m !! label).
Qed.

Lemma wp_put n0 ptr_n tr (depth : w64) elems sl_label sl_val (label val : list w8) ptr_ctx :
  {{{
    "Hown_merkle" ∷ own_merkle_map_aux ptr_n tr elems (uint.nat depth) (DfracOwn 1) ∗
    "Hptr_n0" ∷ n0 ↦[ptrT] #ptr_n ∗
    "Hsl_label" ∷ own_slice_small sl_label byteT DfracDiscarded label ∗
    "%Hlen_label" ∷ ⌜ length label = hash_len ⌝ ∗
    "Hsl_val" ∷ own_slice_small sl_val byteT DfracDiscarded val ∗
    "Hown_ctx" ∷ own_context ptr_ctx (DfracOwn 1)
  }}}
  put #n0 #depth (slice_val sl_label) (slice_val sl_val) #ptr_ctx
  {{{
    ptr_n' tr', RET #();
    "Hown_merkle" ∷ own_merkle_map_aux ptr_n' tr' (<[label:=val]>elems) (uint.nat depth) (DfracOwn 1) ∗
    "Hptr_n0" ∷ n0 ↦[ptrT] #ptr_n' ∗
    "Hown_ctx" ∷ own_context ptr_ctx (DfracOwn 1)
  }}}.
Proof.
  iIntros (Φ) "H HΦ". iNamed "H".
  iLöb as "IH" forall (n0 ptr_n tr elems depth).
  wp_rec. wp_load. wp_if_destruct.
  { wp_apply wp_allocStruct; [val_ty|]. iIntros (?) "Hptr_leaf".
    iDestruct (struct_fields_split with "Hptr_leaf") as "H". iNamed "H".
    wp_store. wp_rec. do 2 wp_loadField.
    wp_apply (wp_compLeafHash with "[$Hsl_label $Hsl_val]").
    iIntros "*". iNamed 1.
    iDestruct (own_slice_to_small with "Hsl_hash") as "Hsl_hash".
    wp_storeField.
    wp_pures. iApply ("HΦ" $! _ (Leaf label val)). iFrame "∗#%".
    iDestruct "Hown_merkle" as "[%Hreln _]". iIntros "!%".
    unfold tree_map_reln in *.
    intros label'.
    destruct (bool_decide (label = label')) eqn:Heq.
    - apply bool_decide_eq_true in Heq. subst. by simpl_map.
    - apply bool_decide_eq_false in Heq. simpl_map.
Admitted.

Lemma wp_verifySiblings sl_label sl_last_hash sl_sibs sl_dig
    d0 d1 d2 (label last_hash sibs dig : list w8) last_node found :
  {{{
    "Hsl_label" ∷ own_slice_small sl_label byteT d0 label ∗
    "%Hlen_label" ∷ ⌜ length label = hash_len ⌝ ∗
    "Hsl_last_hash" ∷ own_slice sl_last_hash byteT (DfracOwn 1) last_hash ∗
    "Hsl_sibs" ∷ own_slice_small sl_sibs byteT d1 sibs ∗
    "Hsl_dig" ∷ own_slice_small sl_dig byteT d2 dig ∗

    "#Hlast_hash" ∷ is_tree_hash last_node last_hash ∗
    "%Hlast_path" ∷ ⌜ ∀ depth, tree_path last_node label depth found ⌝
  }}}
  verifySiblings (slice_val sl_label) (slice_val sl_last_hash)
    (slice_val sl_sibs) (slice_val sl_dig)
  {{{
    (err : bool), RET #err;
    "Hsl_label" ∷ own_slice_small sl_label byteT d0 label ∗
    "Hsl_dig" ∷ own_slice_small sl_dig byteT d2 dig ∗

    "Herr" ∷ (if err then True else
      ∃ tr,
      "#Htree_hash" ∷ is_tree_hash tr dig ∗
      "%Htree_path" ∷ ⌜ tree_path tr label 0 found ⌝)
  }}}.
Proof.
  iIntros (Φ) "H HΦ". iNamed "H". wp_rec.
  wp_apply wp_slice_len.
  wp_if_destruct. { iApply "HΦ". by iFrame. }
  wp_if_destruct. { iApply "HΦ". by iFrame. }
  remember (word.divu _ _) as max_depth.

  wp_apply wp_ref_to; [done|]. iIntros (ptr_curr_hash) "Hptr_curr_hash".
  wp_apply wp_NewSliceWithCap; [done|]. iIntros (?) "Hsl_hash_out".
  wp_apply wp_ref_to; [done|]. iIntros (ptr_hash_out) "Hptr_hash_out".
  wp_apply wp_ref_to; [naive_solver|]. iIntros (ptr_depth) "Hptr_depth".

  iMod (own_slice_small_persist with "Hsl_sibs") as "#Hsl_sibs".
  wp_apply (wp_forDec
    (λ depth, ∃ tr sl_curr_hash curr_hash sl_hash_out,
    "Hsl_label" ∷ own_slice_small sl_label byteT d0 label ∗
    "Hsl_curr_hash" ∷ own_slice sl_curr_hash byteT (DfracOwn 1) curr_hash ∗
    "Hptr_curr_hash" ∷ ptr_curr_hash ↦[slice.T byteT] sl_curr_hash ∗
    "Hsl_hash_out" ∷ own_slice sl_hash_out byteT (DfracOwn 1) [] ∗
    "Hptr_hash_out" ∷ ptr_hash_out ↦[slice.T byteT] sl_hash_out ∗

    "#Htree_hash" ∷ is_tree_hash tr curr_hash ∗
    "%Htree_path" ∷ ⌜ tree_path tr label (uint.nat depth) found ⌝
    )%I
    with "[] [Hptr_depth Hsl_label Hsl_last_hash Hptr_curr_hash
      Hsl_hash_out Hptr_hash_out]"
  ).
  2: { specialize (Hlast_path (uint.nat max_depth)).
    iFrame "Hptr_curr_hash Hptr_hash_out ∗#%". }

  (* return. *)
  2: { iIntros "[H Hptr_depth]". iNamed "H". wp_load.
    iDestruct (own_slice_to_small with "Hsl_curr_hash") as "Hsl_curr_hash".
    wp_apply (wp_BytesEqual with "[$Hsl_curr_hash $Hsl_dig]").
    iIntros "[_ Hsl_dig]".
    case_bool_decide; wp_pures.
    2: { iApply "HΦ". by iFrame. }
    iApply "HΦ". subst. by iFrame "∗#%". }

  (* loop body. *)
  iIntros (depth Φ2) "!> (H & Hptr_depth & %Hlt_depth) HΦ2". iNamed "H".
  do 2 wp_load.
  iDestruct (own_slice_small_sz with "Hsl_sibs") as "%Hlen_sibs".
  (* FIXME(word) *)
  assert (sl_sibs.(Slice.sz) = word.mul max_depth (W64 32)) as Hlen_sibs0.
  { apply w64_val_f_equal in Heqb as [Heqb _].
    rewrite word.unsigned_modu_nowrap in Heqb; [|word].
    subst. word. }
  (* FIXME(word): word should probably do subst. *)
  assert (uint.Z (word.mul max_depth (W64 32)) = uint.Z max_depth * uint.Z 32) as Hnoof.
  { subst. word. }
  wp_apply wp_SliceSubslice_small.
  3: iFrame "#".
  { apply _. }
  { word. }
  iIntros (?) "#Hsl_sibs_sub". wp_load.
  match goal with
  | |- context[own_slice_small s' _ _ ?x] => set (sibs_sub:=x)
  end.

  iDestruct (own_slice_small_sz with "Hsl_label") as %?.
  wp_apply (wp_getBit with "[$Hsl_label]").
  { (* FIXME(word) *)
    rewrite word.unsigned_mul in Heqb0.
    subst. word. }
  iIntros "*". iNamed 1. iRename "Hsl_b" into "Hsl_label".
  wp_pures. wp_bind (if: _ then _ else _)%E.
  wp_apply (wp_wand _ _ _
    (λ _,
    ∃ new_sl_hash_out new_hash_out,
    "Hsl_curr_hash" ∷ own_slice sl_curr_hash byteT (DfracOwn 1) curr_hash ∗
    "Hptr_curr_hash" ∷ ptr_curr_hash ↦[slice.T byteT] sl_curr_hash ∗
    "Hsl_hash_out" ∷ own_slice new_sl_hash_out byteT (DfracOwn 1) new_hash_out ∗
    "Hptr_hash_out" ∷ ptr_hash_out ↦[slice.T byteT] new_sl_hash_out ∗
    "#His_hash" ∷
      match pos with
      | false => is_hash (inner_node_tag :: curr_hash ++ sibs_sub) new_hash_out
      | true => is_hash (inner_node_tag :: sibs_sub ++ curr_hash) new_hash_out
      end
    )%I
    with "[Hsl_curr_hash Hptr_curr_hash Hsl_hash_out Hptr_hash_out]"
  ).
  { wp_if_destruct.
    - do 2 wp_load.
      iDestruct (own_slice_small_read with "Hsl_curr_hash") as "[Hsl_curr_hash Hclose]".
      wp_apply (wp_compInnerHash with "[$Hsl_curr_hash $Hsl_sibs_sub $Hsl_hash_out]").
      iIntros "*". iNamed 1. wp_store.
      iDestruct ("Hclose" with "Hsl_child0") as "Hsl_curr_hash".
      rewrite Heqb1. by iFrame "∗#".
    - do 2 wp_load.
      iDestruct (own_slice_small_read with "Hsl_curr_hash") as "[Hsl_curr_hash Hclose]".
      wp_apply (wp_compInnerHash with "[Hsl_curr_hash $Hsl_hash_out]").
      { iFrame "∗#". }
      iIntros "*". iNamed 1. wp_store.
      iDestruct ("Hclose" with "Hsl_child1") as "Hsl_curr_hash".
      rewrite Heqb1. by iFrame "∗#". }

  iIntros (tmp). iNamed 1. wp_pures. clear tmp.
  do 2 wp_load.
  wp_apply (wp_SliceTake_full with "[$Hsl_curr_hash]"); [word|].
  iIntros "Hsl_curr_hash". rewrite take_0.
  iDestruct (own_slice_small_read with "Hsl_hash_out") as "[Hsl_hash_out Hclose]".
  wp_apply (wp_SliceAppendSlice with "[$Hsl_curr_hash $Hsl_hash_out]"); [done|].
  iIntros (?) "[Hsl_curr_hash Hsl_hash_out]".
  iDestruct ("Hclose" with "Hsl_hash_out") as "Hsl_hash_out".
  wp_store. wp_load.
  wp_apply (wp_SliceTake_full with "[$Hsl_hash_out]"); [word|].
  iIntros "Hsl_hash_out". rewrite take_0. wp_store.
  iApply "HΦ2". iFrame "Hptr_curr_hash Hptr_hash_out ∗".
  iIntros "!>". case_match.
  - iExists (Inner (Cut sibs_sub) tr).
    iFrame "#". repeat iSplit; [done|..].
    + rewrite subslice_length; word.
    + simpl. rewrite Hget_bit.
      replace (uint.nat (word.sub depth _) + _)%nat with (uint.nat depth); [done|word].
  - iExists (Inner tr (Cut sibs_sub)).
    iFrame "#". repeat iSplit; [done|..].
    + rewrite subslice_length; word.
    + simpl. rewrite Hget_bit.
      replace (uint.nat (word.sub depth _) + _)%nat with (uint.nat depth); [done|word].
Qed.

Lemma wp_Verify sl_label sl_val sl_proof sl_dig (in_tree : bool)
    d0 d1 d2 d3 (label val proof dig : list w8) :
  {{{
    "Hsl_label" ∷ own_slice_small sl_label byteT d0 label ∗
    "Hsl_val" ∷ own_slice_small sl_val byteT d1 val ∗
    "Hsl_proof" ∷ own_slice_small sl_proof byteT d2 proof ∗
    "Hsl_dig" ∷ own_slice_small sl_dig byteT d3 dig
  }}}
  Verify #in_tree (slice_val sl_label) (slice_val sl_val)
    (slice_val sl_proof) (slice_val sl_dig)
  {{{
    (err : bool), RET #err;
    "Hsl_label" ∷ own_slice_small sl_label byteT d0 label ∗
    "Hsl_val" ∷ own_slice_small sl_val byteT d1 val ∗
    "Hsl_dig" ∷ own_slice_small sl_dig byteT d3 dig ∗
    "Herr" ∷ (if err then True else
      if in_tree then
        is_merkle_memb label val dig
      else
        is_merkle_nonmemb label dig)
  }}}.
Proof.
  iIntros (Φ) "H HΦ". iNamed "H". wp_rec.
  wp_apply wp_slice_len.
  wp_if_destruct. { iApply "HΦ". by iFrame. }
  wp_apply (MerkleProof.wp_dec with "Hsl_proof"). iIntros "*". iNamed 1.
  wp_if_destruct. { iApply "HΦ". by iFrame. }
  iDestruct "Hgenie" as "[Hgenie _]".
  iDestruct ("Hgenie" with "[//]") as "H". iNamed "H".
  iDestruct ("Herr" with "[//]") as "H". iNamed "H".
  iClear (err Heqb0 tail sl_tail Henc_obj) "Hsl_tail".
  iNamed "Hown_obj". wp_loadField.
  wp_apply (wp_BytesEqual with "[$Hsl_label $Hsl_leaf_label]").
  iIntros "[Hsl_label Hsl_leaf_label]".
  wp_if_destruct. { iApply "HΦ". by iFrame. }

  (* leaf hash. *)
  wp_apply wp_ref_of_zero; [done|]. iIntros (ptr_last_hash) "Hptr_last_hash".
  wp_pures. wp_bind (if: _ then _ else _)%E.
  wp_apply (wp_wand _ _ _
    (λ _,
    ∃ last_node found sl_last_hash (last_hash : list w8),
    "Hsl_label" ∷ own_slice_small sl_label byteT d0 label ∗
    "Hsl_val" ∷ own_slice_small sl_val byteT d1 val ∗
    "Hsl_leaf_label" ∷ own_slice_small sl_leaf_label byteT
                         obj.(MerkleProof.d1) obj.(MerkleProof.LeafLabel) ∗
    "Hptr_leaf_label" ∷ ptr_obj ↦[MerkleProof::"LeafLabel"] sl_leaf_label ∗
    "Hsl_leaf_val" ∷ own_slice_small sl_leaf_val byteT
                       obj.(MerkleProof.d2) obj.(MerkleProof.LeafVal) ∗
    "Hptr_leaf_val" ∷ ptr_obj ↦[MerkleProof::"LeafVal"] sl_leaf_val ∗
    "Hptr_last_hash" ∷ ptr_last_hash ↦[slice.T byteT] (slice_val sl_last_hash) ∗
    "Hsl_last_hash" ∷ own_slice sl_last_hash byteT (DfracOwn 1) last_hash ∗

    "#Htree_hash" ∷ is_tree_hash last_node last_hash ∗
    "%Htree_path" ∷ ⌜ ∀ depth, tree_path last_node label depth found ⌝ ∗
    "%Hfound" ∷ ⌜ if in_tree then found = Some (label, val)
      else found_nonmemb label found ⌝
    )%I
    with "[Hsl_label Hsl_val Hsl_leaf_label Hptr_leaf_label
      Hptr_leaf_val Hsl_leaf_val Hptr_last_hash]"
  ).
  { wp_if_destruct.
    - wp_apply (wp_compLeafHash with "[$Hsl_label $Hsl_val]").
      iIntros "*". iNamed 1. wp_store.
      iDestruct (own_slice_small_sz with "Hsl_label") as %Hlen_label.
      iExists (Leaf label val), _. iFrame "∗#".
      iIntros "!>". iSplit; [word|naive_solver].
    - wp_loadField. wp_apply wp_slice_len.
      wp_if_destruct.
      + do 2 wp_loadField.
        wp_apply (wp_compLeafHash with "[$Hsl_leaf_label $Hsl_leaf_val]").
        iIntros "*". iNamedSuffix 1 "_leaf". wp_store.
        iDestruct (own_slice_small_sz with "Hsl_label_leaf") as %Hlen_label.
        iExists (Leaf obj.(MerkleProof.LeafLabel) obj.(MerkleProof.LeafVal)), _.
        iFrame "∗#". iIntros "!>". iSplit; [word|naive_solver].
      + wp_apply wp_compEmptyHash.
        iIntros "*". iNamed 1. wp_store.
        iDestruct (own_slice_small_sz with "Hsl_leaf_label") as %Hlen_label.
        iExists Empty, _. iFrame "∗#". naive_solver. }
  iIntros (tmp). iNamed 1. wp_pures. clear tmp Heqb0.

  wp_loadField. wp_load.
  iDestruct (own_slice_small_sz with "Hsl_label") as %?.
  wp_apply (wp_verifySiblings with "[$Hsl_label $Hsl_last_hash
    $Hsl_sibs $Hsl_dig]").
  { iFrame "#%". word. }
  iClear (Htree_path) "Htree_hash". iIntros (err) "H". iNamed "H".
  iApply "HΦ". iFrame.
  destruct err; [done|]. iNamed "Herr".
  case_match; subst; by iFrame "#%".
Qed.

End proof.
