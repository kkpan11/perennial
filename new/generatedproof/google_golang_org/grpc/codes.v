(* autogenerated by goose proofgen (types); do not modify *)
Require Export New.proof.proof_prelude.
Require Export New.generatedproof.strconv.
Require Export New.generatedproof.fmt.
Require Export New.code.google_golang_org.grpc.codes.
Require Export New.golang.theory.

Module codes.
Axiom falso : False.

Module Code.
Section def.
Context `{ffi_syntax}.
Definition t := w32.
End def.
End Code.

Section names.

Class GlobalAddrs :=
{
  strToCode : loc;
}.

Context `{!GlobalAddrs}.
Context `{hG: heapGS Σ, !ffi_semantics _ _}.
Context `{!goGlobalsGS Σ}.

Definition var_addrs : list (go_string * loc) := [
    ("strToCode"%go, strToCode)
  ].

Definition is_defined := is_global_definitions codes.pkg_name' var_addrs codes.functions' codes.msets'.

Definition own_allocated `{!GlobalAddrs} : iProp Σ :=
  "HstrToCode" ∷ strToCode ↦ (default_val loc).

Global Instance wp_globals_get_strToCode : 
  WpGlobalsGet codes.pkg_name' "strToCode" strToCode is_defined.
Proof. apply wp_globals_get'. reflexivity. Qed.

Global Instance wp_method_call_Code_String :
  WpMethodCall codes.pkg_name' "Code" "String" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_Code'ptr_String :
  WpMethodCall codes.pkg_name' "Code'ptr" "String" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_Code'ptr_UnmarshalJSON :
  WpMethodCall codes.pkg_name' "Code'ptr" "UnmarshalJSON" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

End names.
End codes.
