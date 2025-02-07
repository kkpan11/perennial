(* autogenerated by goose proofgen (types); do not modify *)
Require Export New.proof.proof_prelude.
Require Export New.code.context.
Require Export New.golang.theory.

Module context.
Axiom falso : False.
Module Context.
Section def.
Context `{ffi_syntax}.
Axiom t : Type.
End def.
End Context.

Global Instance into_val_Context `{ffi_syntax} : IntoVal Context.t.
Admitted.

Global Instance into_val_typed_Context `{ffi_syntax} : IntoValTyped Context.t context.Context.
Admitted.

Module CancelFunc.
Section def.
Context `{ffi_syntax}.
Definition t := func.t.
End def.
End CancelFunc.

Section names.

Class GlobalAddrs :=
{
}.

Context `{!GlobalAddrs}.
Context `{hG: heapGS Σ, !ffi_semantics _ _}.
Context `{!goGlobalsGS Σ}.

Definition var_addrs : list (go_string * loc) := [
  ].

Definition is_defined := is_global_definitions context.pkg_name' var_addrs context.functions' context.msets'.

Definition own_allocated `{!GlobalAddrs} : iProp Σ :=
True.

End names.
End context.
