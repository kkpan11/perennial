(* autogenerated from github.com/mit-pdos/gokv/urpc *)
From New.golang Require Import defn.
From New.code Require github_com.goose_lang.primitive.
From New.code Require github_com.goose_lang.std.
From New.code Require github_com.mit_pdos.gokv.grove_ffi.
From New.code Require github_com.tchajed.marshal.
From New.code Require log.
From New.code Require sync.

From New Require Import grove_prelude.

Definition Server : go_type := structT [
  "handlers" :: mapT uint64T funcT
].

Definition Server__mset : list (string * val) := [
].

(* go: urpc.go:19:20 *)
Definition Server__rpcHandle : val :=
  rec: "Server__rpcHandle" "srv" "conn" "rpcid" "seqno" "data" :=
    exception_do (let: "srv" := (ref_ty ptrT "srv") in
    let: "data" := (ref_ty sliceT "data") in
    let: "seqno" := (ref_ty uint64T "seqno") in
    let: "rpcid" := (ref_ty uint64T "rpcid") in
    let: "conn" := (ref_ty grove_ffi.Connection "conn") in
    let: "replyData" := (ref_ty ptrT (zero_val ptrT)) in
    let: "$r0" := (ref_ty sliceT (zero_val sliceT)) in
    do:  ("replyData" <-[ptrT] "$r0");;;
    let: "f" := (ref_ty funcT (zero_val funcT)) in
    let: "$r0" := (Fst (map.get (![mapT uint64T funcT] (struct.field_ref Server "handlers" (![ptrT] "srv"))) (![uint64T] "rpcid"))) in
    do:  ("f" <-[funcT] "$r0");;;
    do:  (let: "$a0" := (![sliceT] "data") in
    let: "$a1" := (![ptrT] "replyData") in
    (![funcT] "f") "$a0" "$a1");;;
    let: "data1" := (ref_ty sliceT (zero_val sliceT)) in
    let: "$r0" := (slice.make3 byteT #(W64 0) (#(W64 8) + (let: "$a0" := (![sliceT] (![ptrT] "replyData")) in
    slice.len "$a0"))) in
    do:  ("data1" <-[sliceT] "$r0");;;
    let: "data2" := (ref_ty sliceT (zero_val sliceT)) in
    let: "$r0" := (let: "$a0" := (![sliceT] "data1") in
    let: "$a1" := (![uint64T] "seqno") in
    marshal.WriteInt "$a0" "$a1") in
    do:  ("data2" <-[sliceT] "$r0");;;
    let: "data3" := (ref_ty sliceT (zero_val sliceT)) in
    let: "$r0" := (let: "$a0" := (![sliceT] "data2") in
    let: "$a1" := (![sliceT] (![ptrT] "replyData")) in
    marshal.WriteBytes "$a0" "$a1") in
    do:  ("data3" <-[sliceT] "$r0");;;
    do:  (let: "$a0" := (![grove_ffi.Connection] "conn") in
    let: "$a1" := (![sliceT] "data3") in
    grove_ffi.Send "$a0" "$a1")).

(* go: urpc.go:36:20 *)
Definition Server__readThread : val :=
  rec: "Server__readThread" "srv" "conn" :=
    exception_do (let: "srv" := (ref_ty ptrT "srv") in
    let: "conn" := (ref_ty grove_ffi.Connection "conn") in
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "r" := (ref_ty grove_ffi.ReceiveRet (zero_val grove_ffi.ReceiveRet)) in
      let: "$r0" := (let: "$a0" := (![grove_ffi.Connection] "conn") in
      grove_ffi.Receive "$a0") in
      do:  ("r" <-[grove_ffi.ReceiveRet] "$r0");;;
      (if: ![boolT] (struct.field_ref grove_ffi.ReceiveRet "Err" "r")
      then break: #()
      else do:  #());;;
      let: "data" := (ref_ty sliceT (zero_val sliceT)) in
      let: "$r0" := (![sliceT] (struct.field_ref grove_ffi.ReceiveRet "Data" "r")) in
      do:  ("data" <-[sliceT] "$r0");;;
      let: "rpcid" := (ref_ty uint64T (zero_val uint64T)) in
      let: ("$ret0", "$ret1") := (let: "$a0" := (![sliceT] "data") in
      marshal.ReadInt "$a0") in
      let: "$r0" := "$ret0" in
      let: "$r1" := "$ret1" in
      do:  ("rpcid" <-[uint64T] "$r0");;;
      do:  ("data" <-[sliceT] "$r1");;;
      let: "seqno" := (ref_ty uint64T (zero_val uint64T)) in
      let: ("$ret0", "$ret1") := (let: "$a0" := (![sliceT] "data") in
      marshal.ReadInt "$a0") in
      let: "$r0" := "$ret0" in
      let: "$r1" := "$ret1" in
      do:  ("seqno" <-[uint64T] "$r0");;;
      do:  ("data" <-[sliceT] "$r1");;;
      let: "req" := (ref_ty sliceT (zero_val sliceT)) in
      let: "$r0" := (![sliceT] "data") in
      do:  ("req" <-[sliceT] "$r0");;;
      let: "$go" := (λ: <>,
        exception_do (do:  (let: "$a0" := (![grove_ffi.Connection] "conn") in
        let: "$a1" := (![uint64T] "rpcid") in
        let: "$a2" := (![uint64T] "seqno") in
        let: "$a3" := (![sliceT] "req") in
        (Server__rpcHandle (![ptrT] "srv")) "$a0" "$a1" "$a2" "$a3"))
        ) in
      do:  (Fork ("$go" #()));;;
      continue: #())).

(* go: urpc.go:58:20 *)
Definition Server__Serve : val :=
  rec: "Server__Serve" "srv" "host" :=
    exception_do (let: "srv" := (ref_ty ptrT "srv") in
    let: "host" := (ref_ty uint64T "host") in
    let: "listener" := (ref_ty grove_ffi.Listener (zero_val grove_ffi.Listener)) in
    let: "$r0" := (let: "$a0" := (![uint64T] "host") in
    grove_ffi.Listen "$a0") in
    do:  ("listener" <-[grove_ffi.Listener] "$r0");;;
    let: "$go" := (λ: <>,
      exception_do ((for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
        let: "conn" := (ref_ty grove_ffi.Connection (zero_val grove_ffi.Connection)) in
        let: "$r0" := (let: "$a0" := (![grove_ffi.Listener] "listener") in
        grove_ffi.Accept "$a0") in
        do:  ("conn" <-[grove_ffi.Connection] "$r0");;;
        let: "$go" := (λ: <>,
          exception_do (do:  (let: "$a0" := (![grove_ffi.Connection] "conn") in
          (Server__readThread (![ptrT] "srv")) "$a0"))
          ) in
        do:  (Fork ("$go" #()))))
      ) in
    do:  (Fork ("$go" #()))).

Definition Server__mset_ptr : list (string * val) := [
  ("Serve", Server__Serve%V);
  ("readThread", Server__readThread%V);
  ("rpcHandle", Server__rpcHandle%V)
].

(* go: urpc.go:32:6 *)
Definition MakeServer : val :=
  rec: "MakeServer" "handlers" :=
    exception_do (let: "handlers" := (ref_ty (mapT uint64T funcT) "handlers") in
    return: (ref_ty Server (let: "$handlers" := (![mapT uint64T funcT] "handlers") in
     struct.make Server [{
       "handlers" ::= "$handlers"
     }]))).

Definition callbackStateWaiting : expr := #(W64 0).

Definition callbackStateDone : expr := #(W64 1).

Definition callbackStateAborted : expr := #(W64 2).

Definition Callback : go_type := structT [
  "reply" :: ptrT;
  "state" :: ptrT;
  "cond" :: ptrT
].

Definition Callback__mset : list (string * val) := [
].

Definition Callback__mset_ptr : list (string * val) := [
].

Definition Client : go_type := structT [
  "mu" :: ptrT;
  "conn" :: grove_ffi.Connection;
  "seq" :: uint64T;
  "pending" :: mapT uint64T ptrT
].

Definition Client__mset : list (string * val) := [
].

Definition ErrTimeout : expr := #(W64 1).

Definition ErrDisconnect : expr := #(W64 2).

(* go: urpc.go:188:19 *)
Definition Client__CallComplete : val :=
  rec: "Client__CallComplete" "cl" "cb" "reply" "timeout_ms" :=
    exception_do (let: "cl" := (ref_ty ptrT "cl") in
    let: "timeout_ms" := (ref_ty uint64T "timeout_ms") in
    let: "reply" := (ref_ty ptrT "reply") in
    let: "cb" := (ref_ty ptrT "cb") in
    do:  ((sync.Mutex__Lock (![ptrT] (struct.field_ref Client "mu" (![ptrT] "cl")))) #());;;
    (if: (![uint64T] (![ptrT] (struct.field_ref Callback "state" (![ptrT] "cb")))) = callbackStateWaiting
    then
      do:  (let: "$a0" := (![ptrT] (struct.field_ref Callback "cond" (![ptrT] "cb"))) in
      let: "$a1" := (![uint64T] "timeout_ms") in
      primitive.WaitTimeout "$a0" "$a1")
    else do:  #());;;
    let: "state" := (ref_ty uint64T (zero_val uint64T)) in
    let: "$r0" := (![uint64T] (![ptrT] (struct.field_ref Callback "state" (![ptrT] "cb")))) in
    do:  ("state" <-[uint64T] "$r0");;;
    (if: (![uint64T] "state") = callbackStateDone
    then
      let: "$r0" := (![sliceT] (![ptrT] (struct.field_ref Callback "reply" (![ptrT] "cb")))) in
      do:  ((![ptrT] "reply") <-[sliceT] "$r0");;;
      do:  ((sync.Mutex__Unlock (![ptrT] (struct.field_ref Client "mu" (![ptrT] "cl")))) #());;;
      return: (#(W64 0))
    else
      do:  ((sync.Mutex__Unlock (![ptrT] (struct.field_ref Client "mu" (![ptrT] "cl")))) #());;;
      (if: (![uint64T] "state") = callbackStateAborted
      then return: (ErrDisconnect)
      else return: (ErrTimeout)))).

Definition ErrNone : expr := #(W64 0).

(* go: urpc.go:155:19 *)
Definition Client__CallStart : val :=
  rec: "Client__CallStart" "cl" "rpcid" "args" :=
    exception_do (let: "cl" := (ref_ty ptrT "cl") in
    let: "args" := (ref_ty sliceT "args") in
    let: "rpcid" := (ref_ty uint64T "rpcid") in
    let: "reply_buf" := (ref_ty ptrT (zero_val ptrT)) in
    let: "$r0" := (ref_ty sliceT (zero_val sliceT)) in
    do:  ("reply_buf" <-[ptrT] "$r0");;;
    let: "cb" := (ref_ty ptrT (zero_val ptrT)) in
    let: "$r0" := (ref_ty Callback (let: "$reply" := (![ptrT] "reply_buf") in
    let: "$state" := (ref_ty uint64T (zero_val uint64T)) in
    let: "$cond" := (let: "$a0" := (interface.make sync.Mutex__mset_ptr (![ptrT] (struct.field_ref Client "mu" (![ptrT] "cl")))) in
    sync.NewCond "$a0") in
    struct.make Callback [{
      "reply" ::= "$reply";
      "state" ::= "$state";
      "cond" ::= "$cond"
    }])) in
    do:  ("cb" <-[ptrT] "$r0");;;
    let: "$r0" := callbackStateWaiting in
    do:  ((![ptrT] (struct.field_ref Callback "state" (![ptrT] "cb"))) <-[uint64T] "$r0");;;
    do:  ((sync.Mutex__Lock (![ptrT] (struct.field_ref Client "mu" (![ptrT] "cl")))) #());;;
    let: "seqno" := (ref_ty uint64T (zero_val uint64T)) in
    let: "$r0" := (![uint64T] (struct.field_ref Client "seq" (![ptrT] "cl"))) in
    do:  ("seqno" <-[uint64T] "$r0");;;
    let: "$r0" := (let: "$a0" := (![uint64T] (struct.field_ref Client "seq" (![ptrT] "cl"))) in
    let: "$a1" := #(W64 1) in
    std.SumAssumeNoOverflow "$a0" "$a1") in
    do:  ((struct.field_ref Client "seq" (![ptrT] "cl")) <-[uint64T] "$r0");;;
    let: "$r0" := (![ptrT] "cb") in
    do:  (map.insert (![mapT uint64T ptrT] (struct.field_ref Client "pending" (![ptrT] "cl"))) (![uint64T] "seqno") "$r0");;;
    do:  ((sync.Mutex__Unlock (![ptrT] (struct.field_ref Client "mu" (![ptrT] "cl")))) #());;;
    let: "data1" := (ref_ty sliceT (zero_val sliceT)) in
    let: "$r0" := (slice.make3 byteT #(W64 0) (#(W64 (8 + 8)) + (let: "$a0" := (![sliceT] "args") in
    slice.len "$a0"))) in
    do:  ("data1" <-[sliceT] "$r0");;;
    let: "data2" := (ref_ty sliceT (zero_val sliceT)) in
    let: "$r0" := (let: "$a0" := (![sliceT] "data1") in
    let: "$a1" := (![uint64T] "rpcid") in
    marshal.WriteInt "$a0" "$a1") in
    do:  ("data2" <-[sliceT] "$r0");;;
    let: "data3" := (ref_ty sliceT (zero_val sliceT)) in
    let: "$r0" := (let: "$a0" := (![sliceT] "data2") in
    let: "$a1" := (![uint64T] "seqno") in
    marshal.WriteInt "$a0" "$a1") in
    do:  ("data3" <-[sliceT] "$r0");;;
    let: "reqData" := (ref_ty sliceT (zero_val sliceT)) in
    let: "$r0" := (let: "$a0" := (![sliceT] "data3") in
    let: "$a1" := (![sliceT] "args") in
    marshal.WriteBytes "$a0" "$a1") in
    do:  ("reqData" <-[sliceT] "$r0");;;
    (if: let: "$a0" := (![grove_ffi.Connection] (struct.field_ref Client "conn" (![ptrT] "cl"))) in
    let: "$a1" := (![sliceT] "reqData") in
    grove_ffi.Send "$a0" "$a1"
    then
      return: (ref_ty Callback (struct.make Callback [{
         "reply" ::= zero_val ptrT;
         "state" ::= zero_val ptrT;
         "cond" ::= zero_val ptrT
       }]), ErrDisconnect)
    else do:  #());;;
    return: (![ptrT] "cb", ErrNone)).

(* go: urpc.go:215:19 *)
Definition Client__Call : val :=
  rec: "Client__Call" "cl" "rpcid" "args" "reply" "timeout_ms" :=
    exception_do (let: "cl" := (ref_ty ptrT "cl") in
    let: "timeout_ms" := (ref_ty uint64T "timeout_ms") in
    let: "reply" := (ref_ty ptrT "reply") in
    let: "args" := (ref_ty sliceT "args") in
    let: "rpcid" := (ref_ty uint64T "rpcid") in
    let: "err" := (ref_ty uint64T (zero_val uint64T)) in
    let: "cb" := (ref_ty ptrT (zero_val ptrT)) in
    let: ("$ret0", "$ret1") := (let: "$a0" := (![uint64T] "rpcid") in
    let: "$a1" := (![sliceT] "args") in
    (Client__CallStart (![ptrT] "cl")) "$a0" "$a1") in
    let: "$r0" := "$ret0" in
    let: "$r1" := "$ret1" in
    do:  ("cb" <-[ptrT] "$r0");;;
    do:  ("err" <-[uint64T] "$r1");;;
    (if: (![uint64T] "err") ≠ #(W64 0)
    then return: (![uint64T] "err")
    else do:  #());;;
    return: (let: "$a0" := (![ptrT] "cb") in
     let: "$a1" := (![ptrT] "reply") in
     let: "$a2" := (![uint64T] "timeout_ms") in
     (Client__CallComplete (![ptrT] "cl")) "$a0" "$a1" "$a2")).

(* go: urpc.go:88:19 *)
Definition Client__replyThread : val :=
  rec: "Client__replyThread" "cl" <> :=
    exception_do (let: "cl" := (ref_ty ptrT "cl") in
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "r" := (ref_ty grove_ffi.ReceiveRet (zero_val grove_ffi.ReceiveRet)) in
      let: "$r0" := (let: "$a0" := (![grove_ffi.Connection] (struct.field_ref Client "conn" (![ptrT] "cl"))) in
      grove_ffi.Receive "$a0") in
      do:  ("r" <-[grove_ffi.ReceiveRet] "$r0");;;
      (if: ![boolT] (struct.field_ref grove_ffi.ReceiveRet "Err" "r")
      then
        do:  ((sync.Mutex__Lock (![ptrT] (struct.field_ref Client "mu" (![ptrT] "cl")))) #());;;
        do:  (map.for_range (![mapT uint64T ptrT] (struct.field_ref Client "pending" (![ptrT] "cl"))) (λ: <> "cb",
          let: "$r0" := callbackStateAborted in
          do:  ((![ptrT] (struct.field_ref Callback "state" (![ptrT] "cb"))) <-[uint64T] "$r0");;;
          do:  ((sync.Cond__Signal (![ptrT] (struct.field_ref Callback "cond" (![ptrT] "cb")))) #())));;;
        do:  ((sync.Mutex__Unlock (![ptrT] (struct.field_ref Client "mu" (![ptrT] "cl")))) #());;;
        break: #()
      else do:  #());;;
      let: "data" := (ref_ty sliceT (zero_val sliceT)) in
      let: "$r0" := (![sliceT] (struct.field_ref grove_ffi.ReceiveRet "Data" "r")) in
      do:  ("data" <-[sliceT] "$r0");;;
      let: "seqno" := (ref_ty uint64T (zero_val uint64T)) in
      let: ("$ret0", "$ret1") := (let: "$a0" := (![sliceT] "data") in
      marshal.ReadInt "$a0") in
      let: "$r0" := "$ret0" in
      let: "$r1" := "$ret1" in
      do:  ("seqno" <-[uint64T] "$r0");;;
      do:  ("data" <-[sliceT] "$r1");;;
      let: "reply" := (ref_ty sliceT (zero_val sliceT)) in
      let: "$r0" := (![sliceT] "data") in
      do:  ("reply" <-[sliceT] "$r0");;;
      do:  ((sync.Mutex__Lock (![ptrT] (struct.field_ref Client "mu" (![ptrT] "cl")))) #());;;
      let: "ok" := (ref_ty boolT (zero_val boolT)) in
      let: "cb" := (ref_ty ptrT (zero_val ptrT)) in
      let: ("$ret0", "$ret1") := (map.get (![mapT uint64T ptrT] (struct.field_ref Client "pending" (![ptrT] "cl"))) (![uint64T] "seqno")) in
      let: "$r0" := "$ret0" in
      let: "$r1" := "$ret1" in
      do:  ("cb" <-[ptrT] "$r0");;;
      do:  ("ok" <-[boolT] "$r1");;;
      (if: ![boolT] "ok"
      then
        do:  (let: "$a0" := (![mapT uint64T ptrT] (struct.field_ref Client "pending" (![ptrT] "cl"))) in
        let: "$a1" := (![uint64T] "seqno") in
        map.delete "$a0" "$a1");;;
        let: "$r0" := (![sliceT] "reply") in
        do:  ((![ptrT] (struct.field_ref Callback "reply" (![ptrT] "cb"))) <-[sliceT] "$r0");;;
        let: "$r0" := callbackStateDone in
        do:  ((![ptrT] (struct.field_ref Callback "state" (![ptrT] "cb"))) <-[uint64T] "$r0");;;
        do:  ((sync.Cond__Signal (![ptrT] (struct.field_ref Callback "cond" (![ptrT] "cb")))) #())
      else do:  #());;;
      do:  ((sync.Mutex__Unlock (![ptrT] (struct.field_ref Client "mu" (![ptrT] "cl")))) #());;;
      continue: #())).

Definition Client__mset_ptr : list (string * val) := [
  ("Call", Client__Call%V);
  ("CallComplete", Client__CallComplete%V);
  ("CallStart", Client__CallStart%V);
  ("replyThread", Client__replyThread%V)
].

(* go: urpc.go:120:6 *)
Definition TryMakeClient : val :=
  rec: "TryMakeClient" "host_name" :=
    exception_do (let: "host_name" := (ref_ty uint64T "host_name") in
    let: "host" := (ref_ty uint64T (zero_val uint64T)) in
    let: "$r0" := (![uint64T] "host_name") in
    do:  ("host" <-[uint64T] "$r0");;;
    let: "a" := (ref_ty grove_ffi.ConnectRet (zero_val grove_ffi.ConnectRet)) in
    let: "$r0" := (let: "$a0" := (![uint64T] "host") in
    grove_ffi.Connect "$a0") in
    do:  ("a" <-[grove_ffi.ConnectRet] "$r0");;;
    let: "nilClient" := (ref_ty ptrT (zero_val ptrT)) in
    (if: ![boolT] (struct.field_ref grove_ffi.ConnectRet "Err" "a")
    then return: (#(W64 1), ![ptrT] "nilClient")
    else do:  #());;;
    let: "cl" := (ref_ty ptrT (zero_val ptrT)) in
    let: "$r0" := (ref_ty Client (let: "$conn" := (![grove_ffi.Connection] (struct.field_ref grove_ffi.ConnectRet "Connection" "a")) in
    let: "$mu" := (ref_ty sync.Mutex (zero_val sync.Mutex)) in
    let: "$seq" := #(W64 1) in
    let: "$pending" := (map.make uint64T ptrT #()) in
    struct.make Client [{
      "mu" ::= "$mu";
      "conn" ::= "$conn";
      "seq" ::= "$seq";
      "pending" ::= "$pending"
    }])) in
    do:  ("cl" <-[ptrT] "$r0");;;
    let: "$go" := (λ: <>,
      exception_do (do:  ((Client__replyThread (![ptrT] "cl")) #()))
      ) in
    do:  (Fork ("$go" #()));;;
    return: (#(W64 0), ![ptrT] "cl")).

(* go: urpc.go:140:6 *)
Definition MakeClient : val :=
  rec: "MakeClient" "host_name" :=
    exception_do (let: "host_name" := (ref_ty uint64T "host_name") in
    let: "cl" := (ref_ty ptrT (zero_val ptrT)) in
    let: "err" := (ref_ty uint64T (zero_val uint64T)) in
    let: ("$ret0", "$ret1") := (let: "$a0" := (![uint64T] "host_name") in
    TryMakeClient "$a0") in
    let: "$r0" := "$ret0" in
    let: "$r1" := "$ret1" in
    do:  ("err" <-[uint64T] "$r0");;;
    do:  ("cl" <-[ptrT] "$r1");;;
    (if: (![uint64T] "err") ≠ #(W64 0)
    then
      do:  (let: "$a0" := #"Unable to connect to %s" in
      let: "$a1" := ((let: "$sl0" := (interface.make string__mset (let: "$a0" := (![uint64T] "host_name") in
      grove_ffi.AddressToStr "$a0")) in
      slice.literal interfaceT ["$sl0"])) in
      log.Printf "$a0" "$a1")
    else do:  #());;;
    do:  (let: "$a0" := ((![uint64T] "err") = #(W64 0)) in
    primitive.Assume "$a0");;;
    return: (![ptrT] "cl")).

Definition Error : go_type := uint64T.
