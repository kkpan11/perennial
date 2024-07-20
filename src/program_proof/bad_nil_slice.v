(*
package test

import (
   "github.com/goose-lang/goose/machine"
)

func test() {
	slEmpt := make([]byte, 0)
	machine.Assert((slEmpt == nil) == true)
}
*)
(* autogenerated from test *)
From Perennial.goose_lang Require Import prelude.

Section code.
Context `{ext_ty: ext_types}.
Local Coercion Var' s: expr := Var s.

(* FIXME: should not be possible to prove this assert *)
Definition test: val :=
  rec: "test" <> :=
    let: "slEmpt" := NewSlice byteT #0 in
    control.impl.Assert (("slEmpt" = slice.nil) = #true);;
    #().

End code.

From Perennial.program_proof Require Import grove_prelude.
From Perennial.goose_lang.lib Require Import slice.
Section proof.
Context `{!heapGS Σ}.
Lemma wp_test :
  {{{
        True
  }}}
    test #()
  {{{
        RET #(); True
  }}}
.
Proof.
  iIntros (Φ) "_ HΦ".
  wp_rec. wp_pures.
  rewrite /NewSlice.
  rewrite /slice.nil.
  wp_pures.
  wp_pure.
  { done. }
  wp_apply wp_Assert.
  2:{ wp_pures; by iApply "HΦ". }
  done.
Qed.

End proof.
