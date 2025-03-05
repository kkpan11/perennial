(* autogenerated by goose proofgen (types); do not modify *)
Require Export New.proof.proof_prelude.
Require Export New.code.google_golang_org.grpc.status.
Require Export New.golang.theory.

Module status.
Axiom falso : False.

Section names.

Class GlobalAddrs :=
{
}.

Context `{!GlobalAddrs}.
Context `{hG: heapGS Σ, !ffi_semantics _ _}.
Context `{!goGlobalsGS Σ}.

Definition var_addrs : list (go_string * loc) := [
  ].

Definition is_defined := is_global_definitions status.pkg_name' var_addrs status.functions' status.msets'.

Definition own_allocated `{!GlobalAddrs} : iProp Σ :=
True.

End names.
End status.
