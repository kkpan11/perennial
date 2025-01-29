(* autogenerated from github.com/mit-pdos/gokv/tutorial/kvservice *)
From Perennial.goose_lang Require Import prelude.
From Goose Require github_com.goose_lang.std.
From Goose Require github_com.mit_pdos.gokv.tutorial.kvservice.conditionalput_gk.
From Goose Require github_com.mit_pdos.gokv.tutorial.kvservice.get_gk.
From Goose Require github_com.mit_pdos.gokv.tutorial.kvservice.put_gk.
From Goose Require github_com.mit_pdos.gokv.urpc.
From Goose Require github_com.tchajed.marshal.

From Perennial.goose_lang Require Import ffi.grove_prelude.

(* client.go *)

Definition Clerk := struct.decl [
  "rpcCl" :: ptrT
].

Definition Locked := struct.decl [
  "rpcCl" :: ptrT;
  "id" :: uint64T
].

(* Client from kvservice_rpc.gb.go *)

Definition Client := struct.decl [
  "cl" :: ptrT
].

Definition makeClient: val :=
  rec: "makeClient" "hostname" :=
    struct.new Client [
      "cl" ::= urpc.MakeClient "hostname"
    ].

Definition MakeClerk: val :=
  rec: "MakeClerk" "host" :=
    struct.new Clerk [
      "rpcCl" ::= makeClient "host"
    ].

Notation Error := uint64T (only parsing).

Definition rpcIdGetFreshNum : expr := #0.

Definition rpcIdPut : expr := #1.

Definition rpcIdConditionalPut : expr := #2.

Definition rpcIdGet : expr := #3.

(* DecodeUint64 from kvservice.gb.go *)

Definition DecodeUint64: val :=
  rec: "DecodeUint64" "x" :=
    let: ("a", <>) := marshal.ReadInt "x" in
    "a".

(* Client__getFreshNumRpc from kvservice_rpc.gb.go *)

Definition Client__getFreshNumRpc: val :=
  rec: "Client__getFreshNumRpc" "cl" :=
    let: "reply" := ref (zero_val (slice.T byteT)) in
    let: "err" := urpc.Client__Call (struct.loadF Client "cl" "cl") rpcIdGetFreshNum (NewSlice byteT #0) "reply" #100 in
    (if: "err" = urpc.ErrNone
    then (DecodeUint64 (![slice.T byteT] "reply"), "err")
    else (#0, "err")).

Definition Client__putRpc: val :=
  rec: "Client__putRpc" "cl" "args" :=
    let: "reply" := ref (zero_val (slice.T byteT)) in
    let: "err" := urpc.Client__Call (struct.loadF Client "cl" "cl") rpcIdPut (put_gk.Marshal (NewSlice byteT #0) "args") "reply" #100 in
    (if: "err" = urpc.ErrNone
    then "err"
    else "err").

Definition Clerk__Put: val :=
  rec: "Clerk__Put" "ck" "key" "val" :=
    let: "err" := ref (zero_val uint64T) in
    let: "opId" := ref (zero_val uint64T) in
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: ("0_ret", "1_ret") := Client__getFreshNumRpc (struct.loadF Clerk "rpcCl" "ck") in
      "opId" <-[uint64T] "0_ret";;
      "err" <-[uint64T] "1_ret";;
      (if: (![uint64T] "err") = #0
      then Break
      else Continue));;
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "args" := struct.mk put_gk.S [
        "OpId" ::= ![uint64T] "opId";
        "Key" ::= "key";
        "Value" ::= "val"
      ] in
      (if: (Client__putRpc (struct.loadF Clerk "rpcCl" "ck") "args") = urpc.ErrNone
      then Break
      else Continue));;
    #().

Definition Client__conditionalPutRpc: val :=
  rec: "Client__conditionalPutRpc" "cl" "args" :=
    let: "reply" := ref (zero_val (slice.T byteT)) in
    let: "err" := urpc.Client__Call (struct.loadF Client "cl" "cl") rpcIdConditionalPut (conditionalput_gk.Marshal (NewSlice byteT #0) "args") "reply" #100 in
    (if: "err" = urpc.ErrNone
    then (StringFromBytes (![slice.T byteT] "reply"), "err")
    else (#(str""), "err")).

(* returns true if ConditionalPut was successful, false if current value did not
   match expected value. *)
Definition Clerk__ConditionalPut: val :=
  rec: "Clerk__ConditionalPut" "ck" "key" "expectedVal" "newVal" :=
    let: "err" := ref (zero_val uint64T) in
    let: "opId" := ref (zero_val uint64T) in
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: ("0_ret", "1_ret") := Client__getFreshNumRpc (struct.loadF Clerk "rpcCl" "ck") in
      "opId" <-[uint64T] "0_ret";;
      "err" <-[uint64T] "1_ret";;
      (if: (![uint64T] "err") = #0
      then Break
      else Continue));;
    let: "ret" := ref (zero_val boolT) in
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "args" := struct.mk conditionalput_gk.S [
        "OpId" ::= ![uint64T] "opId";
        "Key" ::= "key";
        "ExpectedVal" ::= "expectedVal";
        "NewVal" ::= "newVal"
      ] in
      let: ("reply", "err") := Client__conditionalPutRpc (struct.loadF Clerk "rpcCl" "ck") "args" in
      (if: "err" = urpc.ErrNone
      then
        "ret" <-[boolT] ("reply" = #(str"ok"));;
        Break
      else Continue));;
    ![boolT] "ret".

Definition Client__getRpc: val :=
  rec: "Client__getRpc" "cl" "args" :=
    let: "reply" := ref (zero_val (slice.T byteT)) in
    let: "err" := urpc.Client__Call (struct.loadF Client "cl" "cl") rpcIdGet (get_gk.Marshal (NewSlice byteT #0) "args") "reply" #100 in
    (if: "err" = urpc.ErrNone
    then (StringFromBytes (![slice.T byteT] "reply"), "err")
    else (#(str""), "err")).

(* returns true if ConditionalPut was successful, false if current value did not
   match expected value. *)
Definition Clerk__Get: val :=
  rec: "Clerk__Get" "ck" "key" :=
    let: "err" := ref (zero_val uint64T) in
    let: "opId" := ref (zero_val uint64T) in
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: ("0_ret", "1_ret") := Client__getFreshNumRpc (struct.loadF Clerk "rpcCl" "ck") in
      "opId" <-[uint64T] "0_ret";;
      "err" <-[uint64T] "1_ret";;
      (if: (![uint64T] "err") = #0
      then Break
      else Continue));;
    let: "ret" := ref (zero_val stringT) in
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "args" := struct.mk get_gk.S [
        "OpId" ::= ![uint64T] "opId";
        "Key" ::= "key"
      ] in
      let: ("reply", "err") := Client__getRpc (struct.loadF Clerk "rpcCl" "ck") "args" in
      (if: "err" = urpc.ErrNone
      then
        "ret" <-[stringT] "reply";;
        Break
      else Continue));;
    ![stringT] "ret".

(* kvservice.gb.go *)

(* TODO: these are generic *)
Definition EncodeBool: val :=
  rec: "EncodeBool" "a" :=
    (if: "a"
    then SliceAppend byteT (NewSlice byteT #0) #(U8 1)
    else SliceAppend byteT (NewSlice byteT #0) #(U8 0)).

Definition DecodeBool: val :=
  rec: "DecodeBool" "x" :=
    (SliceGet byteT "x" #0) = #(U8 1).

Definition EncodeUint64: val :=
  rec: "EncodeUint64" "a" :=
    marshal.WriteInt (NewSlice byteT #0) "a".

(* Put *)
Definition putArgs := struct.decl [
  "opId" :: uint64T;
  "key" :: stringT;
  "val" :: stringT
].

Definition encodePutArgs: val :=
  rec: "encodePutArgs" "a" :=
    let: "e" := ref_to (slice.T byteT) (NewSlice byteT #0) in
    "e" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "e") (struct.loadF putArgs "opId" "a"));;
    let: "keyBytes" := StringToBytes (struct.loadF putArgs "key" "a") in
    "e" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "e") (slice.len "keyBytes"));;
    "e" <-[slice.T byteT] (marshal.WriteBytes (![slice.T byteT] "e") "keyBytes");;
    "e" <-[slice.T byteT] (marshal.WriteBytes (![slice.T byteT] "e") (StringToBytes (struct.loadF putArgs "val" "a")));;
    ![slice.T byteT] "e".

Definition decodePutArgs: val :=
  rec: "decodePutArgs" "x" :=
    let: "e" := ref_to (slice.T byteT) "x" in
    let: "a" := struct.alloc putArgs (zero_val (struct.t putArgs)) in
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "e") in
    struct.storeF putArgs "opId" "a" "0_ret";;
    "e" <-[slice.T byteT] "1_ret";;
    let: ("keyLen", "e2") := marshal.ReadInt (![slice.T byteT] "e") in
    let: ("keyBytes", "valBytes") := marshal.ReadBytes "e2" "keyLen" in
    struct.storeF putArgs "key" "a" (StringFromBytes "keyBytes");;
    struct.storeF putArgs "val" "a" (StringFromBytes "valBytes");;
    "a".

(* ConditionalPut *)
Definition conditionalPutArgs := struct.decl [
  "opId" :: uint64T;
  "key" :: stringT;
  "expectedVal" :: stringT;
  "newVal" :: stringT
].

Definition encodeConditionalPutArgs: val :=
  rec: "encodeConditionalPutArgs" "a" :=
    let: "e" := ref_to (slice.T byteT) (NewSlice byteT #0) in
    "e" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "e") (struct.loadF conditionalPutArgs "opId" "a"));;
    let: "keyBytes" := StringToBytes (struct.loadF conditionalPutArgs "key" "a") in
    "e" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "e") (slice.len "keyBytes"));;
    "e" <-[slice.T byteT] (marshal.WriteBytes (![slice.T byteT] "e") "keyBytes");;
    let: "expectedValBytes" := StringToBytes (struct.loadF conditionalPutArgs "expectedVal" "a") in
    "e" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "e") (slice.len "expectedValBytes"));;
    "e" <-[slice.T byteT] (marshal.WriteBytes (![slice.T byteT] "e") "expectedValBytes");;
    "e" <-[slice.T byteT] (marshal.WriteBytes (![slice.T byteT] "e") (StringToBytes (struct.loadF conditionalPutArgs "newVal" "a")));;
    ![slice.T byteT] "e".

Definition decodeConditionalPutArgs: val :=
  rec: "decodeConditionalPutArgs" "x" :=
    let: "e" := ref_to (slice.T byteT) "x" in
    let: "a" := struct.alloc conditionalPutArgs (zero_val (struct.t conditionalPutArgs)) in
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "e") in
    struct.storeF conditionalPutArgs "opId" "a" "0_ret";;
    "e" <-[slice.T byteT] "1_ret";;
    let: ("keyLen", "e2") := marshal.ReadInt (![slice.T byteT] "e") in
    let: ("keyBytes", "e3") := marshal.ReadBytes "e2" "keyLen" in
    struct.storeF conditionalPutArgs "key" "a" (StringFromBytes "keyBytes");;
    let: ("expectedValLen", "e4") := marshal.ReadInt "e3" in
    let: ("expectedValBytes", "newValBytes") := marshal.ReadBytes "e4" "expectedValLen" in
    struct.storeF conditionalPutArgs "expectedVal" "a" (StringFromBytes "expectedValBytes");;
    struct.storeF conditionalPutArgs "newVal" "a" (StringFromBytes "newValBytes");;
    "a".

(* Get *)
Definition getArgs := struct.decl [
  "opId" :: uint64T;
  "key" :: stringT
].

Definition encodeGetArgs: val :=
  rec: "encodeGetArgs" "a" :=
    let: "e" := ref_to (slice.T byteT) (NewSlice byteT #0) in
    "e" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "e") (struct.loadF getArgs "opId" "a"));;
    "e" <-[slice.T byteT] (marshal.WriteBytes (![slice.T byteT] "e") (StringToBytes (struct.loadF getArgs "key" "a")));;
    ![slice.T byteT] "e".

Definition decodeGetArgs: val :=
  rec: "decodeGetArgs" "x" :=
    let: "e" := ref_to (slice.T byteT) "x" in
    let: "keyBytes" := ref (zero_val (slice.T byteT)) in
    let: "a" := struct.alloc getArgs (zero_val (struct.t getArgs)) in
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "e") in
    struct.storeF getArgs "opId" "a" "0_ret";;
    "keyBytes" <-[slice.T byteT] "1_ret";;
    struct.storeF getArgs "key" "a" (StringFromBytes (![slice.T byteT] "keyBytes"));;
    "a".

(* kvservice_rpc.gb.go *)

(* kvservice_rpc_server.gb.go *)

(* Server from server.go *)

Definition Server := struct.decl [
  "mu" :: ptrT;
  "nextFreshId" :: uint64T;
  "lastReplies" :: mapT stringT;
  "kvs" :: mapT stringT
].

Definition Server__getFreshNum: val :=
  rec: "Server__getFreshNum" "s" :=
    Mutex__Lock (struct.loadF Server "mu" "s");;
    let: "n" := struct.loadF Server "nextFreshId" "s" in
    struct.storeF Server "nextFreshId" "s" (std.SumAssumeNoOverflow (struct.loadF Server "nextFreshId" "s") #1);;
    Mutex__Unlock (struct.loadF Server "mu" "s");;
    "n".

Definition Server__put: val :=
  rec: "Server__put" "s" "args" :=
    Mutex__Lock (struct.loadF Server "mu" "s");;
    let: (<>, "ok") := MapGet (struct.loadF Server "lastReplies" "s") (struct.get put_gk.S "OpId" "args") in
    (if: "ok"
    then
      Mutex__Unlock (struct.loadF Server "mu" "s");;
      #()
    else
      MapInsert (struct.loadF Server "kvs" "s") (struct.get put_gk.S "Key" "args") (struct.get put_gk.S "Value" "args");;
      MapInsert (struct.loadF Server "lastReplies" "s") (struct.get put_gk.S "OpId" "args") #(str"");;
      Mutex__Unlock (struct.loadF Server "mu" "s");;
      #()).

Definition Server__conditionalPut: val :=
  rec: "Server__conditionalPut" "s" "args" :=
    Mutex__Lock (struct.loadF Server "mu" "s");;
    let: ("ret", "ok") := MapGet (struct.loadF Server "lastReplies" "s") (struct.get conditionalput_gk.S "OpId" "args") in
    (if: "ok"
    then
      Mutex__Unlock (struct.loadF Server "mu" "s");;
      "ret"
    else
      let: "ret2" := ref_to stringT #(str"") in
      (if: (Fst (MapGet (struct.loadF Server "kvs" "s") (struct.get conditionalput_gk.S "Key" "args"))) = (struct.get conditionalput_gk.S "ExpectedVal" "args")
      then
        MapInsert (struct.loadF Server "kvs" "s") (struct.get conditionalput_gk.S "Key" "args") (struct.get conditionalput_gk.S "NewVal" "args");;
        "ret2" <-[stringT] #(str"ok")
      else #());;
      MapInsert (struct.loadF Server "lastReplies" "s") (struct.get conditionalput_gk.S "OpId" "args") (![stringT] "ret2");;
      Mutex__Unlock (struct.loadF Server "mu" "s");;
      ![stringT] "ret2").

Definition Server__get: val :=
  rec: "Server__get" "s" "args" :=
    Mutex__Lock (struct.loadF Server "mu" "s");;
    let: ("ret", "ok") := MapGet (struct.loadF Server "lastReplies" "s") (struct.get get_gk.S "OpId" "args") in
    (if: "ok"
    then
      Mutex__Unlock (struct.loadF Server "mu" "s");;
      "ret"
    else
      let: "ret2" := Fst (MapGet (struct.loadF Server "kvs" "s") (struct.get get_gk.S "Key" "args")) in
      MapInsert (struct.loadF Server "lastReplies" "s") (struct.get get_gk.S "OpId" "args") "ret2";;
      Mutex__Unlock (struct.loadF Server "mu" "s");;
      "ret2").

Definition Server__Start: val :=
  rec: "Server__Start" "s" "me" :=
    let: "handlers" := NewMap uint64T ((slice.T byteT) -> ptrT -> unitT)%ht #() in
    MapInsert "handlers" rpcIdGetFreshNum (λ: "enc_args" "enc_reply",
      "enc_reply" <-[slice.T byteT] (EncodeUint64 (Server__getFreshNum "s"));;
      #()
      );;
    MapInsert "handlers" rpcIdPut (λ: "enc_args" "enc_reply",
      let: ("args", <>) := put_gk.Unmarshal "enc_args" in
      Server__put "s" "args";;
      #()
      );;
    MapInsert "handlers" rpcIdConditionalPut (λ: "enc_args" "enc_reply",
      let: ("args", <>) := conditionalput_gk.Unmarshal "enc_args" in
      "enc_reply" <-[slice.T byteT] (StringToBytes (Server__conditionalPut "s" "args"));;
      #()
      );;
    MapInsert "handlers" rpcIdGet (λ: "enc_args" "enc_reply",
      let: ("args", <>) := get_gk.Unmarshal "enc_args" in
      "enc_reply" <-[slice.T byteT] (StringToBytes (Server__get "s" "args"));;
      #()
      );;
    urpc.Server__Serve (urpc.MakeServer "handlers") "me";;
    #().

(* server.go *)

Definition MakeServer: val :=
  rec: "MakeServer" <> :=
    let: "s" := struct.alloc Server (zero_val (struct.t Server)) in
    struct.storeF Server "mu" "s" (newMutex #());;
    struct.storeF Server "kvs" "s" (NewMap stringT stringT #());;
    struct.storeF Server "lastReplies" "s" (NewMap uint64T stringT #());;
    "s".
