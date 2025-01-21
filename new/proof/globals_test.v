From New.proof Require Import grove_prelude.
From New.code.github_com.mit_pdos.gokv Require globals_test.
From Perennial.algebra Require Import map.

(* TODO: this should be autogenerated *)
Section autogen.
Class GlobalAddrs :=
  {
    globalB : loc;
    globalA : loc;
    globalY : loc;
    GlobalX : loc;
  }.

Definition var_addrs `{!GlobalAddrs} : list (go_string * loc) := [
    ("GlobalX"%go, GlobalX);
    ("globalY"%go, globalY);
    ("globalA"%go, globalA);
    ("globalB"%go, globalB)
  ].

Context `{!heapGS Σ}.
Context `{!goGlobalsGS Σ}.

Definition is_defined `{!GlobalAddrs} : iProp Σ :=
  is_global_definitions globals_test.pkg_name' var_addrs
                        globals_test.functions' globals_test.msets'.
Context `{!GlobalAddrs}.

Global Instance wp_globals_get_globalB :
  WpGlobalsGet globals_test.pkg_name' "globalB"%go globalB is_defined.
Proof. apply wp_globals_get'. reflexivity. Qed.

Global Instance wp_globals_get_globalA :
  WpGlobalsGet globals_test.pkg_name' "globalA"%go globalA is_defined.
Proof. apply wp_globals_get'. reflexivity. Qed.

Global Instance wp_globals_get_globalY :
  WpGlobalsGet globals_test.pkg_name' "globalY"%go globalY is_defined.
Proof. apply wp_globals_get'. reflexivity. Qed.

Global Instance wp_globals_get_GlobalX :
  WpGlobalsGet globals_test.pkg_name' "GlobalX"%go GlobalX is_defined.
Proof. apply wp_globals_get'. reflexivity. Qed.

Global Instance wp_func_call_foo :
  WpFuncCall globals_test.pkg_name' "foo" globals_test.foo is_defined.
Proof. apply wp_func_call'. reflexivity. Qed.

Global Instance wp_func_call_other :
  WpFuncCall globals_test.pkg_name' "other" globals_test.other is_defined.
Proof. apply wp_func_call'. reflexivity. Qed.

Global Instance wp_func_call_bar :
  WpFuncCall globals_test.pkg_name' "bar" _ is_defined :=
ltac:(apply wp_func_call'; reflexivity).

Global Instance wp_func_call_bar :
  WpFuncCall globals_test.pkg_name' "bar" globals_test.bar is_defined.
Proof. apply wp_func_call'. reflexivity. Qed.

Global Instance wp_func_call_main :
  WpFuncCall globals_test.pkg_name' "main" globals_test.main is_defined.
Proof. apply wp_func_call'. reflexivity. Qed.

End autogen.
(* TODO: end autogenerated part *)

Section proof.
Context `{!heapGS Σ}.
Context `{!goGlobalsGS Σ}.
Context `{!ghost_varG Σ ()}.

Definition own_allocated `{!GlobalAddrs} : iProp Σ :=
  "HglobalB" ∷ globalB ↦ (default_val go_string) ∗
  "HglobalA" ∷ globalA ↦ (default_val go_string) ∗
  "HglobalY" ∷ globalY ↦ (default_val go_string) ∗
  "HGlobalX" ∷ GlobalX ↦ (default_val w64).

Local Instance wp_globals_alloc_inst :
  WpGlobalsAlloc globals_test.vars' (@globals_test.GlobalAddrs) (@globals_test.var_addrs) (@own_allocated).
Proof.
  rewrite /WpGlobalsAlloc.
  iIntros (?) "!# _ HΦ".
  wp_call.
  rewrite -!default_val_eq_zero_val /=.
  wp_alloc globalB_ptr as "?". wp_pures.
  wp_alloc globalA_ptr as "?". wp_pures.
  wp_alloc globalY_ptr as "?". wp_pures.
  wp_alloc GlobalX_ptr as "?". wp_pures.
  iApply ("HΦ" $! (ltac:(econstructor) : GlobalAddrs)).
  iFrame "∗".
Qed.

Definition own_initialized `{!GlobalAddrs} : iProp Σ :=
  "HglobalB" ∷ globalB ↦ "b"%go ∗
  "HglobalA" ∷ globalA ↦ "a"%go ∗
  "HglobalY" ∷ globalY ↦ ""%go ∗
  "HglobalX" ∷ GlobalX ↦ (W64 10).

Definition is_initialized (γtok : gname) `{!GlobalAddrs} : iProp Σ :=
  inv nroot (ghost_var γtok 1 () ∨ own_initialized).

Lemma wp_initialize' pending postconds γtok :
  globals_test.pkg_name' ∉ pending →
  postconds !! globals_test.pkg_name' = Some (∃ (d : GlobalAddrs), is_defined ∗ is_initialized γtok)%I →
  {{{ own_globals_tok pending postconds }}}
    globals_test.initialize' #()
  {{{ (_ : GlobalAddrs), RET #();
      is_defined ∗ is_initialized γtok ∗ own_globals_tok pending postconds
  }}}.
Proof.
  iIntros (???) "Hunused HΦ".
  wp_call.
  wp_apply (wp_package_init with "[$]").
  { eassumption. }
  { set_solver. }
  { (* prove init function *)
    iIntros "* #Hdefs Hvars Htok".
    wp_pures.

    iNamed "Hvars".

    (* go into foo() *)
    wp_func_call.
    wp_call.
    wp_globals_get.
    wp_store.
    wp_pures.
    wp_globals_get.
    wp_store.
    wp_pures.
    wp_globals_get.
    wp_store.
    wp_pures.
    wp_globals_get.
    wp_load.
    wp_pures.
    wp_globals_get.
    wp_store.
    wp_pures.
    wp_globals_get.
    wp_store.
    iApply wp_fupd.
    wp_pures.
    iFrame "Htok".
    iSplitR; first done.
    unfold is_initialized.
    iMod (inv_alloc with "[-]") as "#?".
    2:{ repeat iModIntro. iFrame "#". }
    iNext. iRight.
    iFrame "∗#".
  }
  iApply "HΦ".
Qed.

Context `{!GlobalAddrs}.
Lemma wp_main :
  {{{ is_defined ∗ own_initialized }}}
  func_call #globals_test.pkg_name' #"main" #()
  {{{ RET #(); True }}}.
Proof.
  iIntros (?) "[#Hdef Hpre] HΦ".
  iNamed "Hpre".
  wp_func_call. wp_call.
  wp_func_call. wp_call.
  wp_func_call. wp_call.
  wp_globals_get.
  wp_store.
  wp_pures.
  wp_globals_get.
  wp_load. wp_pures.
  wp_globals_get.
  wp_load.
  wp_pures.
  by iApply "HΦ".
Qed.

End proof.

From Perennial.goose_lang Require Import adequacy dist_adequacy.
From Perennial.goose_lang.ffi Require Import grove_ffi.adequacy.
From New.proof Require Import grove_prelude.
Section closed.

Definition globals_testΣ : gFunctors := #[heapΣ ; goGlobalsΣ; ghost_varΣ ()].

Lemma globals_test_boot σ (g : goose_lang.global_state) :
  ffi_initgP g.(global_world) →
  ffi_initP σ.(world) g.(global_world) →
  σ.(globals) = ∅ → (* FIXME: this should be abstracted into a "goose_lang.init" predicate or something. *)
  dist_adequate_failstop [
      ((globals_test.initialize' #() ;; func_call #globals_test.pkg_name' #"main" #())%E, σ) ] g (λ _, True).
Proof.
  simpl.
  intros ? ? Hgempty.
  apply (grove_ffi_dist_adequacy_failstop globals_testΣ).
  { done. }
  { constructor; done. }
  intros HG.
  iIntros "_".
  iModIntro.
  iSplitL.
  2:{ iIntros. iApply fupd_mask_intro; [set_solver|iIntros "_"; done]. }
  iApply big_sepL_cons.
  iSplitL.
  {
    iIntros (HL) "_".
    set (hG' := HeapGS _ _ _). (* overcome impedence mismatch between heapGS (bundled) and gooseGLobalGS+gooseLocalGS (split) proofs *)
    iIntros "Hglobals".
    rewrite Hgempty.
    iMod (ghost_var_alloc ()) as (γtok) "Hescrow".
    iMod (go_global_init
            (λ _, {[ globals_test.pkg_name' := _ ]}) with "[$]") as
      (hGlobals) "Hpost".
    iModIntro.
    iExists (λ _, True)%I.
    wp_apply (wp_initialize' with "[$]").
    { set_solver. }
    { rewrite lookup_singleton. done. }
    iIntros "* (Hdef & Hinit & Htok)".
    iApply fupd_wp. iInv "Hinit" as ">[Hbad|Hi]" "Hclose".
    { iCombine "Hbad Hescrow" gives %[Hbad _]. done. }
    iMod ("Hclose" with "[$Hescrow]") as "_". iModIntro.
    wp_pures.
    by wp_apply (wp_main with "[$]").
  }
  by iApply big_sepL_nil.
Qed.

Print Assumptions globals_test_boot.

End closed.
