(* autogenerated by goose proofgen (types); do not modify *)
Require Export New.proof.proof_prelude.
Require Export New.generatedproof.context.
Require Export New.generatedproof.strings.
Require Export New.generatedproof.sync.
Require Export New.generatedproof.time.
Require Export New.generatedproof.go_etcd_io.etcd.api.v3.etcdserverpb.
Require Export New.generatedproof.go_etcd_io.etcd.api.v3.mvccpb.
Require Export New.generatedproof.go_etcd_io.etcd.client.v3.
Require Export New.generatedproof.errors.
Require Export New.generatedproof.google_golang_org.grpc.codes.
Require Export New.generatedproof.google_golang_org.grpc.status.
Require Export New.generatedproof.go_etcd_io.etcd.api.v3.v3rpc.rpctypes.
Require Export New.generatedproof.go_etcd_io.etcd.client.v3.concurrency.
Require Export New.generatedproof.bytes.
Require Export New.code.go_etcd_io.etcd.client.v3.leasing.
Require Export New.golang.theory.

Module leasing.
Axiom falso : False.
Module leaseCache.
Section def.
Context `{ffi_syntax}.
Record t := mk {
  mu' : sync.RWMutex.t;
  entries' : loc;
  revokes' : loc;
  header' : loc;
}.
End def.
End leaseCache.

Section instances.
Context `{ffi_syntax}.

Global Instance settable_leaseCache `{ffi_syntax}: Settable _ :=
  settable! leaseCache.mk < leaseCache.mu'; leaseCache.entries'; leaseCache.revokes'; leaseCache.header' >.
Global Instance into_val_leaseCache `{ffi_syntax} : IntoVal leaseCache.t.
Admitted.

Global Instance into_val_typed_leaseCache `{ffi_syntax} : IntoValTyped leaseCache.t leasing.leaseCache :=
{|
  default_val := leaseCache.mk (default_val _) (default_val _) (default_val _) (default_val _);
  to_val_has_go_type := ltac:(destruct falso);
  default_val_eq_zero_val := ltac:(destruct falso);
  to_val_inj := ltac:(destruct falso);
  to_val_eqdec := ltac:(solve_decision);
|}.
Global Instance into_val_struct_field_leaseCache_mu `{ffi_syntax} : IntoValStructField "mu" leasing.leaseCache leaseCache.mu'.
Admitted.

Global Instance into_val_struct_field_leaseCache_entries `{ffi_syntax} : IntoValStructField "entries" leasing.leaseCache leaseCache.entries'.
Admitted.

Global Instance into_val_struct_field_leaseCache_revokes `{ffi_syntax} : IntoValStructField "revokes" leasing.leaseCache leaseCache.revokes'.
Admitted.

Global Instance into_val_struct_field_leaseCache_header `{ffi_syntax} : IntoValStructField "header" leasing.leaseCache leaseCache.header'.
Admitted.


Context `{!ffi_model, !ffi_semantics _ _, !ffi_interp _, !heapGS Σ}.
Global Instance wp_struct_make_leaseCache `{ffi_semantics} `{!ffi_interp ffi} `{!heapGS Σ} mu' entries' revokes' header':
  PureWp True
    (struct.make leasing.leaseCache (alist_val [
      "mu" ::= #mu';
      "entries" ::= #entries';
      "revokes" ::= #revokes';
      "header" ::= #header'
    ]))%V
    #(leaseCache.mk mu' entries' revokes' header').
Admitted.


Global Instance leaseCache_struct_fields_split dq l (v : leaseCache.t) :
  StructFieldsSplit dq l v (
    "Hmu" ∷ l ↦s[leasing.leaseCache :: "mu"]{dq} v.(leaseCache.mu') ∗
    "Hentries" ∷ l ↦s[leasing.leaseCache :: "entries"]{dq} v.(leaseCache.entries') ∗
    "Hrevokes" ∷ l ↦s[leasing.leaseCache :: "revokes"]{dq} v.(leaseCache.revokes') ∗
    "Hheader" ∷ l ↦s[leasing.leaseCache :: "header"]{dq} v.(leaseCache.header')
  ).
Admitted.

End instances.
Module leaseKey.
Section def.
Context `{ffi_syntax}.
Record t := mk {
  response' : loc;
  rev' : w64;
  waitc' : loc;
}.
End def.
End leaseKey.

Section instances.
Context `{ffi_syntax}.

Global Instance settable_leaseKey `{ffi_syntax}: Settable _ :=
  settable! leaseKey.mk < leaseKey.response'; leaseKey.rev'; leaseKey.waitc' >.
Global Instance into_val_leaseKey `{ffi_syntax} : IntoVal leaseKey.t.
Admitted.

Global Instance into_val_typed_leaseKey `{ffi_syntax} : IntoValTyped leaseKey.t leasing.leaseKey :=
{|
  default_val := leaseKey.mk (default_val _) (default_val _) (default_val _);
  to_val_has_go_type := ltac:(destruct falso);
  default_val_eq_zero_val := ltac:(destruct falso);
  to_val_inj := ltac:(destruct falso);
  to_val_eqdec := ltac:(solve_decision);
|}.
Global Instance into_val_struct_field_leaseKey_response `{ffi_syntax} : IntoValStructField "response" leasing.leaseKey leaseKey.response'.
Admitted.

Global Instance into_val_struct_field_leaseKey_rev `{ffi_syntax} : IntoValStructField "rev" leasing.leaseKey leaseKey.rev'.
Admitted.

Global Instance into_val_struct_field_leaseKey_waitc `{ffi_syntax} : IntoValStructField "waitc" leasing.leaseKey leaseKey.waitc'.
Admitted.


Context `{!ffi_model, !ffi_semantics _ _, !ffi_interp _, !heapGS Σ}.
Global Instance wp_struct_make_leaseKey `{ffi_semantics} `{!ffi_interp ffi} `{!heapGS Σ} response' rev' waitc':
  PureWp True
    (struct.make leasing.leaseKey (alist_val [
      "response" ::= #response';
      "rev" ::= #rev';
      "waitc" ::= #waitc'
    ]))%V
    #(leaseKey.mk response' rev' waitc').
Admitted.


Global Instance leaseKey_struct_fields_split dq l (v : leaseKey.t) :
  StructFieldsSplit dq l v (
    "Hresponse" ∷ l ↦s[leasing.leaseKey :: "response"]{dq} v.(leaseKey.response') ∗
    "Hrev" ∷ l ↦s[leasing.leaseKey :: "rev"]{dq} v.(leaseKey.rev') ∗
    "Hwaitc" ∷ l ↦s[leasing.leaseKey :: "waitc"]{dq} v.(leaseKey.waitc')
  ).
Admitted.

End instances.
Module leasingKV.
Section def.
Context `{ffi_syntax}.
Record t := mk {
  cl' : loc;
  kv' : clientv3.KV.t;
  pfx' : go_string;
  leases' : leaseCache.t;
  ctx' : context.Context.t;
  cancel' : context.CancelFunc.t;
  wg' : sync.WaitGroup.t;
  sessionOpts' : slice.t;
  session' : loc;
  sessionc' : loc;
}.
End def.
End leasingKV.

Section instances.
Context `{ffi_syntax}.

Global Instance settable_leasingKV `{ffi_syntax}: Settable _ :=
  settable! leasingKV.mk < leasingKV.cl'; leasingKV.kv'; leasingKV.pfx'; leasingKV.leases'; leasingKV.ctx'; leasingKV.cancel'; leasingKV.wg'; leasingKV.sessionOpts'; leasingKV.session'; leasingKV.sessionc' >.
Global Instance into_val_leasingKV `{ffi_syntax} : IntoVal leasingKV.t.
Admitted.

Global Instance into_val_typed_leasingKV `{ffi_syntax} : IntoValTyped leasingKV.t leasing.leasingKV :=
{|
  default_val := leasingKV.mk (default_val _) (default_val _) (default_val _) (default_val _) (default_val _) (default_val _) (default_val _) (default_val _) (default_val _) (default_val _);
  to_val_has_go_type := ltac:(destruct falso);
  default_val_eq_zero_val := ltac:(destruct falso);
  to_val_inj := ltac:(destruct falso);
  to_val_eqdec := ltac:(solve_decision);
|}.
Global Instance into_val_struct_field_leasingKV_cl `{ffi_syntax} : IntoValStructField "cl" leasing.leasingKV leasingKV.cl'.
Admitted.

Global Instance into_val_struct_field_leasingKV_kv `{ffi_syntax} : IntoValStructField "kv" leasing.leasingKV leasingKV.kv'.
Admitted.

Global Instance into_val_struct_field_leasingKV_pfx `{ffi_syntax} : IntoValStructField "pfx" leasing.leasingKV leasingKV.pfx'.
Admitted.

Global Instance into_val_struct_field_leasingKV_leases `{ffi_syntax} : IntoValStructField "leases" leasing.leasingKV leasingKV.leases'.
Admitted.

Global Instance into_val_struct_field_leasingKV_ctx `{ffi_syntax} : IntoValStructField "ctx" leasing.leasingKV leasingKV.ctx'.
Admitted.

Global Instance into_val_struct_field_leasingKV_cancel `{ffi_syntax} : IntoValStructField "cancel" leasing.leasingKV leasingKV.cancel'.
Admitted.

Global Instance into_val_struct_field_leasingKV_wg `{ffi_syntax} : IntoValStructField "wg" leasing.leasingKV leasingKV.wg'.
Admitted.

Global Instance into_val_struct_field_leasingKV_sessionOpts `{ffi_syntax} : IntoValStructField "sessionOpts" leasing.leasingKV leasingKV.sessionOpts'.
Admitted.

Global Instance into_val_struct_field_leasingKV_session `{ffi_syntax} : IntoValStructField "session" leasing.leasingKV leasingKV.session'.
Admitted.

Global Instance into_val_struct_field_leasingKV_sessionc `{ffi_syntax} : IntoValStructField "sessionc" leasing.leasingKV leasingKV.sessionc'.
Admitted.


Context `{!ffi_model, !ffi_semantics _ _, !ffi_interp _, !heapGS Σ}.
Global Instance wp_struct_make_leasingKV `{ffi_semantics} `{!ffi_interp ffi} `{!heapGS Σ} cl' kv' pfx' leases' ctx' cancel' wg' sessionOpts' session' sessionc':
  PureWp True
    (struct.make leasing.leasingKV (alist_val [
      "cl" ::= #cl';
      "kv" ::= #kv';
      "pfx" ::= #pfx';
      "leases" ::= #leases';
      "ctx" ::= #ctx';
      "cancel" ::= #cancel';
      "wg" ::= #wg';
      "sessionOpts" ::= #sessionOpts';
      "session" ::= #session';
      "sessionc" ::= #sessionc'
    ]))%V
    #(leasingKV.mk cl' kv' pfx' leases' ctx' cancel' wg' sessionOpts' session' sessionc').
Admitted.


Global Instance leasingKV_struct_fields_split dq l (v : leasingKV.t) :
  StructFieldsSplit dq l v (
    "Hcl" ∷ l ↦s[leasing.leasingKV :: "cl"]{dq} v.(leasingKV.cl') ∗
    "Hkv" ∷ l ↦s[leasing.leasingKV :: "kv"]{dq} v.(leasingKV.kv') ∗
    "Hpfx" ∷ l ↦s[leasing.leasingKV :: "pfx"]{dq} v.(leasingKV.pfx') ∗
    "Hleases" ∷ l ↦s[leasing.leasingKV :: "leases"]{dq} v.(leasingKV.leases') ∗
    "Hctx" ∷ l ↦s[leasing.leasingKV :: "ctx"]{dq} v.(leasingKV.ctx') ∗
    "Hcancel" ∷ l ↦s[leasing.leasingKV :: "cancel"]{dq} v.(leasingKV.cancel') ∗
    "Hwg" ∷ l ↦s[leasing.leasingKV :: "wg"]{dq} v.(leasingKV.wg') ∗
    "HsessionOpts" ∷ l ↦s[leasing.leasingKV :: "sessionOpts"]{dq} v.(leasingKV.sessionOpts') ∗
    "Hsession" ∷ l ↦s[leasing.leasingKV :: "session"]{dq} v.(leasingKV.session') ∗
    "Hsessionc" ∷ l ↦s[leasing.leasingKV :: "sessionc"]{dq} v.(leasingKV.sessionc')
  ).
Admitted.

End instances.
Module txnLeasing.
Section def.
Context `{ffi_syntax}.
Record t := mk {
  Txn' : clientv3.Txn.t;
  lkv' : loc;
  ctx' : context.Context.t;
  cs' : slice.t;
  opst' : slice.t;
  opse' : slice.t;
}.
End def.
End txnLeasing.

Section instances.
Context `{ffi_syntax}.

Global Instance settable_txnLeasing `{ffi_syntax}: Settable _ :=
  settable! txnLeasing.mk < txnLeasing.Txn'; txnLeasing.lkv'; txnLeasing.ctx'; txnLeasing.cs'; txnLeasing.opst'; txnLeasing.opse' >.
Global Instance into_val_txnLeasing `{ffi_syntax} : IntoVal txnLeasing.t.
Admitted.

Global Instance into_val_typed_txnLeasing `{ffi_syntax} : IntoValTyped txnLeasing.t leasing.txnLeasing :=
{|
  default_val := txnLeasing.mk (default_val _) (default_val _) (default_val _) (default_val _) (default_val _) (default_val _);
  to_val_has_go_type := ltac:(destruct falso);
  default_val_eq_zero_val := ltac:(destruct falso);
  to_val_inj := ltac:(destruct falso);
  to_val_eqdec := ltac:(solve_decision);
|}.
Global Instance into_val_struct_field_txnLeasing_Txn `{ffi_syntax} : IntoValStructField "Txn" leasing.txnLeasing txnLeasing.Txn'.
Admitted.

Global Instance into_val_struct_field_txnLeasing_lkv `{ffi_syntax} : IntoValStructField "lkv" leasing.txnLeasing txnLeasing.lkv'.
Admitted.

Global Instance into_val_struct_field_txnLeasing_ctx `{ffi_syntax} : IntoValStructField "ctx" leasing.txnLeasing txnLeasing.ctx'.
Admitted.

Global Instance into_val_struct_field_txnLeasing_cs `{ffi_syntax} : IntoValStructField "cs" leasing.txnLeasing txnLeasing.cs'.
Admitted.

Global Instance into_val_struct_field_txnLeasing_opst `{ffi_syntax} : IntoValStructField "opst" leasing.txnLeasing txnLeasing.opst'.
Admitted.

Global Instance into_val_struct_field_txnLeasing_opse `{ffi_syntax} : IntoValStructField "opse" leasing.txnLeasing txnLeasing.opse'.
Admitted.


Context `{!ffi_model, !ffi_semantics _ _, !ffi_interp _, !heapGS Σ}.
Global Instance wp_struct_make_txnLeasing `{ffi_semantics} `{!ffi_interp ffi} `{!heapGS Σ} Txn' lkv' ctx' cs' opst' opse':
  PureWp True
    (struct.make leasing.txnLeasing (alist_val [
      "Txn" ::= #Txn';
      "lkv" ::= #lkv';
      "ctx" ::= #ctx';
      "cs" ::= #cs';
      "opst" ::= #opst';
      "opse" ::= #opse'
    ]))%V
    #(txnLeasing.mk Txn' lkv' ctx' cs' opst' opse').
Admitted.


Global Instance txnLeasing_struct_fields_split dq l (v : txnLeasing.t) :
  StructFieldsSplit dq l v (
    "HTxn" ∷ l ↦s[leasing.txnLeasing :: "Txn"]{dq} v.(txnLeasing.Txn') ∗
    "Hlkv" ∷ l ↦s[leasing.txnLeasing :: "lkv"]{dq} v.(txnLeasing.lkv') ∗
    "Hctx" ∷ l ↦s[leasing.txnLeasing :: "ctx"]{dq} v.(txnLeasing.ctx') ∗
    "Hcs" ∷ l ↦s[leasing.txnLeasing :: "cs"]{dq} v.(txnLeasing.cs') ∗
    "Hopst" ∷ l ↦s[leasing.txnLeasing :: "opst"]{dq} v.(txnLeasing.opst') ∗
    "Hopse" ∷ l ↦s[leasing.txnLeasing :: "opse"]{dq} v.(txnLeasing.opse')
  ).
Admitted.

End instances.

Section names.

Class GlobalAddrs :=
{
  closedCh : loc;
}.

Context `{!GlobalAddrs}.
Context `{hG: heapGS Σ, !ffi_semantics _ _}.
Context `{!goGlobalsGS Σ}.

Definition var_addrs : list (go_string * loc) := [
    ("closedCh"%go, closedCh)
  ].

Definition is_defined := is_global_definitions leasing.pkg_name' var_addrs leasing.functions' leasing.msets'.

Definition own_allocated `{!GlobalAddrs} : iProp Σ :=
  "HclosedCh" ∷ closedCh ↦ (default_val loc).

Global Instance wp_globals_get_closedCh : 
  WpGlobalsGet leasing.pkg_name' "closedCh" closedCh is_defined.
Proof. apply wp_globals_get'. reflexivity. Qed.

Global Instance wp_func_call_inRange :
  WpFuncCall leasing.pkg_name' "inRange" _ is_defined :=
  ltac:(apply wp_func_call'; reflexivity).

Global Instance wp_func_call_isBadOp :
  WpFuncCall leasing.pkg_name' "isBadOp" _ is_defined :=
  ltac:(apply wp_func_call'; reflexivity).

Global Instance wp_func_call_NewKV :
  WpFuncCall leasing.pkg_name' "NewKV" _ is_defined :=
  ltac:(apply wp_func_call'; reflexivity).

Global Instance wp_func_call_compareInt64 :
  WpFuncCall leasing.pkg_name' "compareInt64" _ is_defined :=
  ltac:(apply wp_func_call'; reflexivity).

Global Instance wp_func_call_evalCmp :
  WpFuncCall leasing.pkg_name' "evalCmp" _ is_defined :=
  ltac:(apply wp_func_call'; reflexivity).

Global Instance wp_func_call_gatherOps :
  WpFuncCall leasing.pkg_name' "gatherOps" _ is_defined :=
  ltac:(apply wp_func_call'; reflexivity).

Global Instance wp_func_call_gatherResponseOps :
  WpFuncCall leasing.pkg_name' "gatherResponseOps" _ is_defined :=
  ltac:(apply wp_func_call'; reflexivity).

Global Instance wp_func_call_copyHeader :
  WpFuncCall leasing.pkg_name' "copyHeader" _ is_defined :=
  ltac:(apply wp_func_call'; reflexivity).

Global Instance wp_func_call_closeAll :
  WpFuncCall leasing.pkg_name' "closeAll" _ is_defined :=
  ltac:(apply wp_func_call'; reflexivity).

Global Instance wp_method_call_leaseCache'ptr_Add :
  WpMethodCall leasing.pkg_name' "leaseCache'ptr" "Add" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leaseCache'ptr_Delete :
  WpMethodCall leasing.pkg_name' "leaseCache'ptr" "Delete" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leaseCache'ptr_Evict :
  WpMethodCall leasing.pkg_name' "leaseCache'ptr" "Evict" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leaseCache'ptr_EvictRange :
  WpMethodCall leasing.pkg_name' "leaseCache'ptr" "EvictRange" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leaseCache'ptr_Get :
  WpMethodCall leasing.pkg_name' "leaseCache'ptr" "Get" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leaseCache'ptr_Lock :
  WpMethodCall leasing.pkg_name' "leaseCache'ptr" "Lock" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leaseCache'ptr_LockRange :
  WpMethodCall leasing.pkg_name' "leaseCache'ptr" "LockRange" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leaseCache'ptr_LockWriteOps :
  WpMethodCall leasing.pkg_name' "leaseCache'ptr" "LockWriteOps" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leaseCache'ptr_MayAcquire :
  WpMethodCall leasing.pkg_name' "leaseCache'ptr" "MayAcquire" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leaseCache'ptr_NotifyOps :
  WpMethodCall leasing.pkg_name' "leaseCache'ptr" "NotifyOps" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leaseCache'ptr_Rev :
  WpMethodCall leasing.pkg_name' "leaseCache'ptr" "Rev" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leaseCache'ptr_Update :
  WpMethodCall leasing.pkg_name' "leaseCache'ptr" "Update" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leaseCache'ptr_clearOldRevokes :
  WpMethodCall leasing.pkg_name' "leaseCache'ptr" "clearOldRevokes" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leaseCache'ptr_delete :
  WpMethodCall leasing.pkg_name' "leaseCache'ptr" "delete" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leaseCache'ptr_evalCmp :
  WpMethodCall leasing.pkg_name' "leaseCache'ptr" "evalCmp" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leaseCache'ptr_evalOps :
  WpMethodCall leasing.pkg_name' "leaseCache'ptr" "evalOps" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leaseCache'ptr_notify :
  WpMethodCall leasing.pkg_name' "leaseCache'ptr" "notify" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leaseKey'ptr_get :
  WpMethodCall leasing.pkg_name' "leaseKey'ptr" "get" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_Close :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "Close" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_Compact :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "Compact" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_Delete :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "Delete" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_Do :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "Do" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_Get :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "Get" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_Put :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "Put" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_Txn :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "Txn" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_acquire :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "acquire" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_delete :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "delete" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_deleteRange :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "deleteRange" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_deleteRangeRPC :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "deleteRangeRPC" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_get :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "get" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_leaseID :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "leaseID" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_monitorLease :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "monitorLease" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_monitorSession :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "monitorSession" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_put :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "put" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_readySession :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "readySession" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_rescind :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "rescind" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_revoke :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "revoke" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_revokeLeaseKvs :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "revokeLeaseKvs" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_revokeRange :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "revokeRange" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_tryModifyOp :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "tryModifyOp" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_waitRescind :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "waitRescind" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_leasingKV'ptr_waitSession :
  WpMethodCall leasing.pkg_name' "leasingKV'ptr" "waitSession" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_txnLeasing'ptr_Commit :
  WpMethodCall leasing.pkg_name' "txnLeasing'ptr" "Commit" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_txnLeasing'ptr_Else :
  WpMethodCall leasing.pkg_name' "txnLeasing'ptr" "Else" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_txnLeasing'ptr_If :
  WpMethodCall leasing.pkg_name' "txnLeasing'ptr" "If" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_txnLeasing'ptr_Then :
  WpMethodCall leasing.pkg_name' "txnLeasing'ptr" "Then" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_txnLeasing'ptr_commitToCache :
  WpMethodCall leasing.pkg_name' "txnLeasing'ptr" "commitToCache" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_txnLeasing'ptr_eval :
  WpMethodCall leasing.pkg_name' "txnLeasing'ptr" "eval" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_txnLeasing'ptr_fallback :
  WpMethodCall leasing.pkg_name' "txnLeasing'ptr" "fallback" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_txnLeasing'ptr_guard :
  WpMethodCall leasing.pkg_name' "txnLeasing'ptr" "guard" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_txnLeasing'ptr_guardKeys :
  WpMethodCall leasing.pkg_name' "txnLeasing'ptr" "guardKeys" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_txnLeasing'ptr_guardRanges :
  WpMethodCall leasing.pkg_name' "txnLeasing'ptr" "guardRanges" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_txnLeasing'ptr_revokeFallback :
  WpMethodCall leasing.pkg_name' "txnLeasing'ptr" "revokeFallback" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

Global Instance wp_method_call_txnLeasing'ptr_serverTxn :
  WpMethodCall leasing.pkg_name' "txnLeasing'ptr" "serverTxn" _ is_defined :=
  ltac:(apply wp_method_call'; reflexivity).

End names.
End leasing.
