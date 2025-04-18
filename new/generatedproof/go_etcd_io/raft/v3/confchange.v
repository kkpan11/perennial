(* autogenerated by goose proofgen; do not modify *)
Require Export New.proof.proof_prelude.
Require Export New.generatedproof.go_etcd_io.raft.v3.tracker.
Require Export New.golang.theory.

Require Export New.code.go_etcd_io.raft.v3.confchange.
Module confchange.
Axiom falso : False.
Module Changer.
Section def.
Context `{ffi_syntax}.
Record t := mk {
  Tracker' : tracker.ProgressTracker.t;
  LastIndex' : w64;
}.
End def.
End Changer.

Section instances.
Context `{ffi_syntax}.

Global Instance settable_Changer `{ffi_syntax}: Settable _ :=
  settable! Changer.mk < Changer.Tracker'; Changer.LastIndex' >.
Global Instance into_val_Changer `{ffi_syntax} : IntoVal Changer.t.
Admitted.

Global Instance into_val_typed_Changer `{ffi_syntax} : IntoValTyped Changer.t confchange.Changer :=
{|
  default_val := Changer.mk (default_val _) (default_val _);
  to_val_has_go_type := ltac:(destruct falso);
  default_val_eq_zero_val := ltac:(destruct falso);
  to_val_inj := ltac:(destruct falso);
  to_val_eqdec := ltac:(solve_decision);
|}.
Global Instance into_val_struct_field_Changer_Tracker `{ffi_syntax} : IntoValStructField "Tracker" confchange.Changer Changer.Tracker'.
Admitted.

Global Instance into_val_struct_field_Changer_LastIndex `{ffi_syntax} : IntoValStructField "LastIndex" confchange.Changer Changer.LastIndex'.
Admitted.


Context `{!ffi_model, !ffi_semantics _ _, !ffi_interp _, !heapGS Σ}.
Global Instance wp_struct_make_Changer `{ffi_semantics} `{!ffi_interp ffi} `{!heapGS Σ} Tracker' LastIndex':
  PureWp True
    (struct.make #confchange.Changer (alist_val [
      "Tracker" ::= #Tracker';
      "LastIndex" ::= #LastIndex'
    ]))%struct
    #(Changer.mk Tracker' LastIndex').
Admitted.


Global Instance Changer_struct_fields_split dq l (v : Changer.t) :
  StructFieldsSplit dq l v (
    "HTracker" ∷ l ↦s[confchange.Changer :: "Tracker"]{dq} v.(Changer.Tracker') ∗
    "HLastIndex" ∷ l ↦s[confchange.Changer :: "LastIndex"]{dq} v.(Changer.LastIndex')
  ).
Admitted.

End instances.

Section names.

Class GlobalAddrs :=
{
}.

Context `{!GlobalAddrs}.
Context `{hG: heapGS Σ, !ffi_semantics _ _}.
Context `{!goGlobalsGS Σ}.

Definition var_addrs : list (go_string * loc) := [
  ].

Global Instance is_pkg_defined_instance : IsPkgDefined confchange :=
{|
  is_pkg_defined := is_global_definitions confchange var_addrs;
|}.

Definition own_allocated `{!GlobalAddrs} : iProp Σ :=
True.

End names.
End confchange.
