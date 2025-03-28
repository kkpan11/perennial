(* autogenerated by goose proofgen; do not modify *)
Require Export New.proof.grove_prelude.
Require Export New.manualproof.github_com.mit_pdos.gokv.grove_ffi.
Require Export New.golang.theory.

Require Export New.code.github_com.mit_pdos.gokv.grove_ffi.
Module grove_ffi.
Axiom falso : False.

Section names.

Class GlobalAddrs :=
{
}.

Context `{!GlobalAddrs}.
Context `{!heapGS Σ}.
Context `{!goGlobalsGS Σ}.

Definition var_addrs : list (go_string * loc) := [
  ].

Global Instance is_pkg_defined_instance : IsPkgDefined grove_ffi :=
{|
  is_pkg_defined := is_global_definitions grove_ffi var_addrs;
|}.

Definition own_allocated `{!GlobalAddrs} : iProp Σ :=
True.

Global Instance wp_func_call_FileWrite :
  WpFuncCall grove_ffi "FileWrite" _ (is_pkg_defined grove_ffi) :=
  ltac:(apply wp_func_call'; reflexivity).

Global Instance wp_func_call_FileRead :
  WpFuncCall grove_ffi "FileRead" _ (is_pkg_defined grove_ffi) :=
  ltac:(apply wp_func_call'; reflexivity).

Global Instance wp_func_call_FileAppend :
  WpFuncCall grove_ffi "FileAppend" _ (is_pkg_defined grove_ffi) :=
  ltac:(apply wp_func_call'; reflexivity).

Global Instance wp_func_call_Listen :
  WpFuncCall grove_ffi "Listen" _ (is_pkg_defined grove_ffi) :=
  ltac:(apply wp_func_call'; reflexivity).

Global Instance wp_func_call_Accept :
  WpFuncCall grove_ffi "Accept" _ (is_pkg_defined grove_ffi) :=
  ltac:(apply wp_func_call'; reflexivity).

Global Instance wp_func_call_Connect :
  WpFuncCall grove_ffi "Connect" _ (is_pkg_defined grove_ffi) :=
  ltac:(apply wp_func_call'; reflexivity).

Global Instance wp_func_call_Send :
  WpFuncCall grove_ffi "Send" _ (is_pkg_defined grove_ffi) :=
  ltac:(apply wp_func_call'; reflexivity).

Global Instance wp_func_call_Receive :
  WpFuncCall grove_ffi "Receive" _ (is_pkg_defined grove_ffi) :=
  ltac:(apply wp_func_call'; reflexivity).

Global Instance wp_func_call_GetTimeRange :
  WpFuncCall grove_ffi "GetTimeRange" _ (is_pkg_defined grove_ffi) :=
  ltac:(apply wp_func_call'; reflexivity).

Global Instance wp_func_call_GetTSC :
  WpFuncCall grove_ffi "GetTSC" _ (is_pkg_defined grove_ffi) :=
  ltac:(apply wp_func_call'; reflexivity).

End names.
End grove_ffi.
