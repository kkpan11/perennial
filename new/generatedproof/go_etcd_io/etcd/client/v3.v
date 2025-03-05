(* autogenerated by goose proofgen (types); do not modify *)
Require Export New.proof.proof_prelude.
Require Export New.generatedproof.go_etcd_io.etcd.api.v3.etcdserverpb.
Require Export New.generatedproof.go_etcd_io.etcd.api.v3.mvccpb.
Require Export New.code.go_etcd_io.etcd.client.v3.
Require Export New.golang.theory.

Module clientv3.
Axiom falso : False.
Module Client.
Section def.
Context `{ffi_syntax}.
Axiom t : Type.
End def.
End Client.

Global Instance into_val_Client `{ffi_syntax} : IntoVal Client.t.
Admitted.

Global Instance into_val_typed_Client `{ffi_syntax} : IntoValTyped Client.t clientv3.Client.
Admitted.

Module Cluster.
Section def.
Context `{ffi_syntax}.
Definition t := interface.t.
End def.
End Cluster.

Module Cmp.
Section def.
Context `{ffi_syntax}.
Definition t := etcdserverpb.Compare.t.
End def.
End Cmp.

Module PutResponse.
Section def.
Context `{ffi_syntax}.
Definition t := etcdserverpb.PutResponse.t.
End def.
End PutResponse.

Module GetResponse.
Section def.
Context `{ffi_syntax}.
Definition t := etcdserverpb.RangeResponse.t.
End def.
End GetResponse.

Module DeleteResponse.
Section def.
Context `{ffi_syntax}.
Definition t := etcdserverpb.DeleteRangeResponse.t.
End def.
End DeleteResponse.

Module TxnResponse.
Section def.
Context `{ffi_syntax}.
Definition t := etcdserverpb.TxnResponse.t.
End def.
End TxnResponse.

Module KV.
Section def.
Context `{ffi_syntax}.
Definition t := interface.t.
End def.
End KV.
Module OpResponse.
Section def.
Context `{ffi_syntax}.
Record t := mk {
  put' : loc;
  get' : loc;
  del' : loc;
  txn' : loc;
}.
End def.
End OpResponse.

Section instances.
Context `{ffi_syntax}.

Global Instance settable_OpResponse `{ffi_syntax}: Settable _ :=
  settable! OpResponse.mk < OpResponse.put'; OpResponse.get'; OpResponse.del'; OpResponse.txn' >.
Global Instance into_val_OpResponse `{ffi_syntax} : IntoVal OpResponse.t.
Admitted.

Global Instance into_val_typed_OpResponse `{ffi_syntax} : IntoValTyped OpResponse.t clientv3.OpResponse :=
{|
  default_val := OpResponse.mk (default_val _) (default_val _) (default_val _) (default_val _);
  to_val_has_go_type := ltac:(destruct falso);
  default_val_eq_zero_val := ltac:(destruct falso);
  to_val_inj := ltac:(destruct falso);
  to_val_eqdec := ltac:(solve_decision);
|}.
Global Instance into_val_struct_field_OpResponse_put `{ffi_syntax} : IntoValStructField "put" clientv3.OpResponse OpResponse.put'.
Admitted.

Global Instance into_val_struct_field_OpResponse_get `{ffi_syntax} : IntoValStructField "get" clientv3.OpResponse OpResponse.get'.
Admitted.

Global Instance into_val_struct_field_OpResponse_del `{ffi_syntax} : IntoValStructField "del" clientv3.OpResponse OpResponse.del'.
Admitted.

Global Instance into_val_struct_field_OpResponse_txn `{ffi_syntax} : IntoValStructField "txn" clientv3.OpResponse OpResponse.txn'.
Admitted.


Context `{!ffi_model, !ffi_semantics _ _, !ffi_interp _, !heapGS Σ}.
Global Instance wp_struct_make_OpResponse `{ffi_semantics} `{!ffi_interp ffi} `{!heapGS Σ} put' get' del' txn':
  PureWp True
    (struct.make clientv3.OpResponse (alist_val [
      "put" ::= #put';
      "get" ::= #get';
      "del" ::= #del';
      "txn" ::= #txn'
    ]))%V
    #(OpResponse.mk put' get' del' txn').
Admitted.


Global Instance OpResponse_struct_fields_split dq l (v : OpResponse.t) :
  StructFieldsSplit dq l v (
    "Hput" ∷ l ↦s[clientv3.OpResponse :: "put"]{dq} v.(OpResponse.put') ∗
    "Hget" ∷ l ↦s[clientv3.OpResponse :: "get"]{dq} v.(OpResponse.get') ∗
    "Hdel" ∷ l ↦s[clientv3.OpResponse :: "del"]{dq} v.(OpResponse.del') ∗
    "Htxn" ∷ l ↦s[clientv3.OpResponse :: "txn"]{dq} v.(OpResponse.txn')
  ).
Admitted.

End instances.

Module LeaseID.
Section def.
Context `{ffi_syntax}.
Definition t := w64.
End def.
End LeaseID.
Module LeaseGrantResponse.
Section def.
Context `{ffi_syntax}.
Record t := mk {
  ResponseHeader' : loc;
  ID' : LeaseID.t;
  TTL' : w64;
  Error' : go_string;
}.
End def.
End LeaseGrantResponse.

Section instances.
Context `{ffi_syntax}.

Global Instance settable_LeaseGrantResponse `{ffi_syntax}: Settable _ :=
  settable! LeaseGrantResponse.mk < LeaseGrantResponse.ResponseHeader'; LeaseGrantResponse.ID'; LeaseGrantResponse.TTL'; LeaseGrantResponse.Error' >.
Global Instance into_val_LeaseGrantResponse `{ffi_syntax} : IntoVal LeaseGrantResponse.t.
Admitted.

Global Instance into_val_typed_LeaseGrantResponse `{ffi_syntax} : IntoValTyped LeaseGrantResponse.t clientv3.LeaseGrantResponse :=
{|
  default_val := LeaseGrantResponse.mk (default_val _) (default_val _) (default_val _) (default_val _);
  to_val_has_go_type := ltac:(destruct falso);
  default_val_eq_zero_val := ltac:(destruct falso);
  to_val_inj := ltac:(destruct falso);
  to_val_eqdec := ltac:(solve_decision);
|}.
Global Instance into_val_struct_field_LeaseGrantResponse_ResponseHeader `{ffi_syntax} : IntoValStructField "ResponseHeader" clientv3.LeaseGrantResponse LeaseGrantResponse.ResponseHeader'.
Admitted.

Global Instance into_val_struct_field_LeaseGrantResponse_ID `{ffi_syntax} : IntoValStructField "ID" clientv3.LeaseGrantResponse LeaseGrantResponse.ID'.
Admitted.

Global Instance into_val_struct_field_LeaseGrantResponse_TTL `{ffi_syntax} : IntoValStructField "TTL" clientv3.LeaseGrantResponse LeaseGrantResponse.TTL'.
Admitted.

Global Instance into_val_struct_field_LeaseGrantResponse_Error `{ffi_syntax} : IntoValStructField "Error" clientv3.LeaseGrantResponse LeaseGrantResponse.Error'.
Admitted.


Context `{!ffi_model, !ffi_semantics _ _, !ffi_interp _, !heapGS Σ}.
Global Instance wp_struct_make_LeaseGrantResponse `{ffi_semantics} `{!ffi_interp ffi} `{!heapGS Σ} ResponseHeader' ID' TTL' Error':
  PureWp True
    (struct.make clientv3.LeaseGrantResponse (alist_val [
      "ResponseHeader" ::= #ResponseHeader';
      "ID" ::= #ID';
      "TTL" ::= #TTL';
      "Error" ::= #Error'
    ]))%V
    #(LeaseGrantResponse.mk ResponseHeader' ID' TTL' Error').
Admitted.


Global Instance LeaseGrantResponse_struct_fields_split dq l (v : LeaseGrantResponse.t) :
  StructFieldsSplit dq l v (
    "HResponseHeader" ∷ l ↦s[clientv3.LeaseGrantResponse :: "ResponseHeader"]{dq} v.(LeaseGrantResponse.ResponseHeader') ∗
    "HID" ∷ l ↦s[clientv3.LeaseGrantResponse :: "ID"]{dq} v.(LeaseGrantResponse.ID') ∗
    "HTTL" ∷ l ↦s[clientv3.LeaseGrantResponse :: "TTL"]{dq} v.(LeaseGrantResponse.TTL') ∗
    "HError" ∷ l ↦s[clientv3.LeaseGrantResponse :: "Error"]{dq} v.(LeaseGrantResponse.Error')
  ).
Admitted.

End instances.

Module Lease.
Section def.
Context `{ffi_syntax}.
Definition t := interface.t.
End def.
End Lease.
Module Op.
Section def.
Context `{ffi_syntax}.
Axiom t : Type.
End def.
End Op.

Global Instance into_val_Op `{ffi_syntax} : IntoVal Op.t.
Admitted.

Global Instance into_val_typed_Op `{ffi_syntax} : IntoValTyped Op.t clientv3.Op.
Admitted.

Module OpOption.
Section def.
Context `{ffi_syntax}.
Definition t := func.t.
End def.
End OpOption.

Module Txn.
Section def.
Context `{ffi_syntax}.
Definition t := interface.t.
End def.
End Txn.

Module Event.
Section def.
Context `{ffi_syntax}.
Definition t := mvccpb.Event.t.
End def.
End Event.

Module WatchChan.
Section def.
Context `{ffi_syntax}.
Definition t := loc.
End def.
End WatchChan.

Module Watcher.
Section def.
Context `{ffi_syntax}.
Definition t := interface.t.
End def.
End Watcher.
Module WatchResponse.
Section def.
Context `{ffi_syntax}.
Record t := mk {
  Header' : etcdserverpb.ResponseHeader.t;
  Events' : slice.t;
  CompactRevision' : w64;
  Canceled' : bool;
  Created' : bool;
  closeErr' : error.t;
  cancelReason' : go_string;
}.
End def.
End WatchResponse.

Section instances.
Context `{ffi_syntax}.

Global Instance settable_WatchResponse `{ffi_syntax}: Settable _ :=
  settable! WatchResponse.mk < WatchResponse.Header'; WatchResponse.Events'; WatchResponse.CompactRevision'; WatchResponse.Canceled'; WatchResponse.Created'; WatchResponse.closeErr'; WatchResponse.cancelReason' >.
Global Instance into_val_WatchResponse `{ffi_syntax} : IntoVal WatchResponse.t.
Admitted.

Global Instance into_val_typed_WatchResponse `{ffi_syntax} : IntoValTyped WatchResponse.t clientv3.WatchResponse :=
{|
  default_val := WatchResponse.mk (default_val _) (default_val _) (default_val _) (default_val _) (default_val _) (default_val _) (default_val _);
  to_val_has_go_type := ltac:(destruct falso);
  default_val_eq_zero_val := ltac:(destruct falso);
  to_val_inj := ltac:(destruct falso);
  to_val_eqdec := ltac:(solve_decision);
|}.
Global Instance into_val_struct_field_WatchResponse_Header `{ffi_syntax} : IntoValStructField "Header" clientv3.WatchResponse WatchResponse.Header'.
Admitted.

Global Instance into_val_struct_field_WatchResponse_Events `{ffi_syntax} : IntoValStructField "Events" clientv3.WatchResponse WatchResponse.Events'.
Admitted.

Global Instance into_val_struct_field_WatchResponse_CompactRevision `{ffi_syntax} : IntoValStructField "CompactRevision" clientv3.WatchResponse WatchResponse.CompactRevision'.
Admitted.

Global Instance into_val_struct_field_WatchResponse_Canceled `{ffi_syntax} : IntoValStructField "Canceled" clientv3.WatchResponse WatchResponse.Canceled'.
Admitted.

Global Instance into_val_struct_field_WatchResponse_Created `{ffi_syntax} : IntoValStructField "Created" clientv3.WatchResponse WatchResponse.Created'.
Admitted.

Global Instance into_val_struct_field_WatchResponse_closeErr `{ffi_syntax} : IntoValStructField "closeErr" clientv3.WatchResponse WatchResponse.closeErr'.
Admitted.

Global Instance into_val_struct_field_WatchResponse_cancelReason `{ffi_syntax} : IntoValStructField "cancelReason" clientv3.WatchResponse WatchResponse.cancelReason'.
Admitted.


Context `{!ffi_model, !ffi_semantics _ _, !ffi_interp _, !heapGS Σ}.
Global Instance wp_struct_make_WatchResponse `{ffi_semantics} `{!ffi_interp ffi} `{!heapGS Σ} Header' Events' CompactRevision' Canceled' Created' closeErr' cancelReason':
  PureWp True
    (struct.make clientv3.WatchResponse (alist_val [
      "Header" ::= #Header';
      "Events" ::= #Events';
      "CompactRevision" ::= #CompactRevision';
      "Canceled" ::= #Canceled';
      "Created" ::= #Created';
      "closeErr" ::= #closeErr';
      "cancelReason" ::= #cancelReason'
    ]))%V
    #(WatchResponse.mk Header' Events' CompactRevision' Canceled' Created' closeErr' cancelReason').
Admitted.


Global Instance WatchResponse_struct_fields_split dq l (v : WatchResponse.t) :
  StructFieldsSplit dq l v (
    "HHeader" ∷ l ↦s[clientv3.WatchResponse :: "Header"]{dq} v.(WatchResponse.Header') ∗
    "HEvents" ∷ l ↦s[clientv3.WatchResponse :: "Events"]{dq} v.(WatchResponse.Events') ∗
    "HCompactRevision" ∷ l ↦s[clientv3.WatchResponse :: "CompactRevision"]{dq} v.(WatchResponse.CompactRevision') ∗
    "HCanceled" ∷ l ↦s[clientv3.WatchResponse :: "Canceled"]{dq} v.(WatchResponse.Canceled') ∗
    "HCreated" ∷ l ↦s[clientv3.WatchResponse :: "Created"]{dq} v.(WatchResponse.Created') ∗
    "HcloseErr" ∷ l ↦s[clientv3.WatchResponse :: "closeErr"]{dq} v.(WatchResponse.closeErr') ∗
    "HcancelReason" ∷ l ↦s[clientv3.WatchResponse :: "cancelReason"]{dq} v.(WatchResponse.cancelReason')
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

Definition is_defined := is_global_definitions clientv3.pkg_name' var_addrs clientv3.functions' clientv3.msets'.

Definition own_allocated `{!GlobalAddrs} : iProp Σ :=
True.

End names.
End clientv3.
