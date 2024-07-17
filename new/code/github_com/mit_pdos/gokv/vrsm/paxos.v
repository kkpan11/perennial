(* autogenerated from github.com/mit-pdos/gokv/vrsm/paxos *)
From New.golang Require Import defn.
From New.code Require github_com.goose_lang.std.
From New.code Require github_com.mit_pdos.gokv.asyncfile.
From New.code Require github_com.mit_pdos.gokv.grove_ffi.
From New.code Require github_com.mit_pdos.gokv.reconnectclient.
From New.code Require github_com.mit_pdos.gokv.urpc.
From New.code Require github_com.tchajed.marshal.
From New.code Require log.
From New.code Require sync.

From New Require Import grove_prelude.

(* internalclerk.go *)

Definition RPC_APPLY_AS_FOLLOWER : expr := #0.

Definition RPC_ENTER_NEW_EPOCH : expr := #1.

Definition RPC_BECOME_LEADER : expr := #2.

Definition singleClerk : go_type := structT [
  "cl" :: ptrT
].

Definition MakeSingleClerk : val :=
  rec: "MakeSingleClerk" "addr" :=
    exception_do (let: "addr" := ref_ty uint64T "addr" in
    let: "ck" := ref_ty ptrT (zero_val ptrT) in
    let: "$a0" := ref_ty singleClerk (struct.make singleClerk [{
      "cl" ::= reconnectclient.MakeReconnectingClient (![uint64T] "addr")
    }]) in
    do:  "ck" <-[ptrT] "$a0";;;
    return: (![ptrT] "ck");;;
    do:  #()).

(* Error from marshal.go *)

Definition Error : go_type := uint64T.

Definition enterNewEpochReply : go_type := structT [
  "err" :: Error;
  "acceptedEpoch" :: uint64T;
  "nextIndex" :: uint64T;
  "state" :: sliceT byteT
].

Definition ENone : expr := #0.

Definition EEpochStale : expr := #1.

Definition EOutOfOrder : expr := #2.

Definition ETimeout : expr := #3.

Definition ENotLeader : expr := #4.

Definition decodeEnterNewEpochReply : val :=
  rec: "decodeEnterNewEpochReply" "enc" :=
    exception_do (let: "enc" := ref_ty (sliceT byteT) "enc" in
    let: "o" := ref_ty ptrT (zero_val ptrT) in
    let: "$a0" := ref_ty enterNewEpochReply (struct.make enterNewEpochReply [{
    }]) in
    do:  "o" <-[ptrT] "$a0";;;
    let: "err" := ref_ty uint64T (zero_val uint64T) in
    let: ("$a0", "$a1") := marshal.ReadInt (![sliceT byteT] "enc") in
    do:  "enc" <-[sliceT byteT] "$a1";;;
    do:  "err" <-[uint64T] "$a0";;;
    let: "$a0" := ![uint64T] "err" in
    do:  (struct.field_ref enterNewEpochReply "err" (![ptrT] "o")) <-[Error] "$a0";;;
    let: ("$a0", "$a1") := marshal.ReadInt (![sliceT byteT] "enc") in
    do:  "enc" <-[sliceT byteT] "$a1";;;
    do:  (struct.field_ref enterNewEpochReply "acceptedEpoch" (![ptrT] "o")) <-[uint64T] "$a0";;;
    let: ("$a0", "$a1") := marshal.ReadInt (![sliceT byteT] "enc") in
    do:  "enc" <-[sliceT byteT] "$a1";;;
    do:  (struct.field_ref enterNewEpochReply "nextIndex" (![ptrT] "o")) <-[uint64T] "$a0";;;
    let: "$a0" := ![sliceT byteT] "enc" in
    do:  (struct.field_ref enterNewEpochReply "state" (![ptrT] "o")) <-[sliceT byteT] "$a0";;;
    return: (![ptrT] "o");;;
    do:  #()).

Definition enterNewEpochArgs : go_type := structT [
  "epoch" :: uint64T
].

Definition encodeEnterNewEpochArgs : val :=
  rec: "encodeEnterNewEpochArgs" "o" :=
    exception_do (let: "o" := ref_ty ptrT "o" in
    let: "enc" := ref_ty (sliceT byteT) (zero_val (sliceT byteT)) in
    let: "$a0" := slice.make3 byteT #0 #8 in
    do:  "enc" <-[sliceT byteT] "$a0";;;
    let: "$a0" := marshal.WriteInt (![sliceT byteT] "enc") (![uint64T] (struct.field_ref enterNewEpochArgs "epoch" (![ptrT] "o"))) in
    do:  "enc" <-[sliceT byteT] "$a0";;;
    return: (![sliceT byteT] "enc");;;
    do:  #()).

Definition singleClerk__enterNewEpoch : val :=
  rec: "singleClerk__enterNewEpoch" "s" "args" :=
    exception_do (let: "s" := ref_ty ptrT "s" in
    let: "args" := ref_ty ptrT "args" in
    let: "raw_args" := ref_ty (sliceT byteT) (zero_val (sliceT byteT)) in
    let: "$a0" := encodeEnterNewEpochArgs (![ptrT] "args") in
    do:  "raw_args" <-[sliceT byteT] "$a0";;;
    let: "raw_reply" := ref_ty ptrT (zero_val ptrT) in
    let: "$a0" := ref_ty (sliceT byteT) (zero_val (sliceT byteT)) in
    do:  "raw_reply" <-[ptrT] "$a0";;;
    let: "err" := ref_ty uint64T (zero_val uint64T) in
    let: "$a0" := (reconnectclient.ReconnectingClient__Call (![ptrT] (struct.field_ref singleClerk "cl" (![ptrT] "s")))) RPC_ENTER_NEW_EPOCH (![sliceT byteT] "raw_args") (![ptrT] "raw_reply") #500 in
    do:  "err" <-[uint64T] "$a0";;;
    (if: (![uint64T] "err") = #0
    then
      return: (decodeEnterNewEpochReply (![sliceT byteT] (![ptrT] "raw_reply")));;;
      do:  #()
    else
      return: (ref_ty enterNewEpochReply (struct.make enterNewEpochReply [{
         "err" ::= ETimeout
       }]));;;
      do:  #());;;
    do:  #()).

Definition applyAsFollowerReply : go_type := structT [
  "err" :: Error
].

Definition decodeApplyAsFollowerReply : val :=
  rec: "decodeApplyAsFollowerReply" "s" :=
    exception_do (let: "s" := ref_ty (sliceT byteT) "s" in
    let: "o" := ref_ty ptrT (zero_val ptrT) in
    let: "$a0" := ref_ty applyAsFollowerReply (struct.make applyAsFollowerReply [{
    }]) in
    do:  "o" <-[ptrT] "$a0";;;
    let: <> := ref_ty (sliceT byteT) (zero_val (sliceT byteT)) in
    let: "err" := ref_ty uint64T (zero_val uint64T) in
    let: ("$a0", "$a1") := marshal.ReadInt (![sliceT byteT] "s") in
    do:  "$a1";;;
    do:  "err" <-[uint64T] "$a0";;;
    let: "$a0" := ![uint64T] "err" in
    do:  (struct.field_ref applyAsFollowerReply "err" (![ptrT] "o")) <-[Error] "$a0";;;
    return: (![ptrT] "o");;;
    do:  #()).

Definition applyAsFollowerArgs : go_type := structT [
  "epoch" :: uint64T;
  "nextIndex" :: uint64T;
  "state" :: sliceT byteT
].

Definition encodeApplyAsFollowerArgs : val :=
  rec: "encodeApplyAsFollowerArgs" "o" :=
    exception_do (let: "o" := ref_ty ptrT "o" in
    let: "enc" := ref_ty (sliceT byteT) (zero_val (sliceT byteT)) in
    let: "$a0" := slice.make3 byteT #0 ((#8 + #8) + (slice.len (![sliceT byteT] (struct.field_ref applyAsFollowerArgs "state" (![ptrT] "o"))))) in
    do:  "enc" <-[sliceT byteT] "$a0";;;
    let: "$a0" := marshal.WriteInt (![sliceT byteT] "enc") (![uint64T] (struct.field_ref applyAsFollowerArgs "epoch" (![ptrT] "o"))) in
    do:  "enc" <-[sliceT byteT] "$a0";;;
    let: "$a0" := marshal.WriteInt (![sliceT byteT] "enc") (![uint64T] (struct.field_ref applyAsFollowerArgs "nextIndex" (![ptrT] "o"))) in
    do:  "enc" <-[sliceT byteT] "$a0";;;
    let: "$a0" := marshal.WriteBytes (![sliceT byteT] "enc") (![sliceT byteT] (struct.field_ref applyAsFollowerArgs "state" (![ptrT] "o"))) in
    do:  "enc" <-[sliceT byteT] "$a0";;;
    return: (![sliceT byteT] "enc");;;
    do:  #()).

Definition singleClerk__applyAsFollower : val :=
  rec: "singleClerk__applyAsFollower" "s" "args" :=
    exception_do (let: "s" := ref_ty ptrT "s" in
    let: "args" := ref_ty ptrT "args" in
    let: "raw_args" := ref_ty (sliceT byteT) (zero_val (sliceT byteT)) in
    let: "$a0" := encodeApplyAsFollowerArgs (![ptrT] "args") in
    do:  "raw_args" <-[sliceT byteT] "$a0";;;
    let: "raw_reply" := ref_ty ptrT (zero_val ptrT) in
    let: "$a0" := ref_ty (sliceT byteT) (zero_val (sliceT byteT)) in
    do:  "raw_reply" <-[ptrT] "$a0";;;
    let: "err" := ref_ty uint64T (zero_val uint64T) in
    let: "$a0" := (reconnectclient.ReconnectingClient__Call (![ptrT] (struct.field_ref singleClerk "cl" (![ptrT] "s")))) RPC_APPLY_AS_FOLLOWER (![sliceT byteT] "raw_args") (![ptrT] "raw_reply") #500 in
    do:  "err" <-[uint64T] "$a0";;;
    (if: (![uint64T] "err") = #0
    then
      return: (decodeApplyAsFollowerReply (![sliceT byteT] (![ptrT] "raw_reply")));;;
      do:  #()
    else
      return: (ref_ty applyAsFollowerReply (struct.make applyAsFollowerReply [{
         "err" ::= ETimeout
       }]));;;
      do:  #());;;
    do:  #()).

Definition singleClerk__TryBecomeLeader : val :=
  rec: "singleClerk__TryBecomeLeader" "s" <> :=
    exception_do (let: "s" := ref_ty ptrT "s" in
    let: "reply" := ref_ty ptrT (zero_val ptrT) in
    let: "$a0" := ref_ty (sliceT byteT) (zero_val (sliceT byteT)) in
    do:  "reply" <-[ptrT] "$a0";;;
    do:  (reconnectclient.ReconnectingClient__Call (![ptrT] (struct.field_ref singleClerk "cl" (![ptrT] "s")))) RPC_BECOME_LEADER (slice.make2 byteT #0) (![ptrT] "reply") #500;;;
    do:  #()).

(* marshal.go *)

Definition decodeApplyAsFollowerArgs : val :=
  rec: "decodeApplyAsFollowerArgs" "enc" :=
    exception_do (let: "enc" := ref_ty (sliceT byteT) "enc" in
    let: "o" := ref_ty ptrT (zero_val ptrT) in
    let: "$a0" := ref_ty applyAsFollowerArgs (zero_val applyAsFollowerArgs) in
    do:  "o" <-[ptrT] "$a0";;;
    let: ("$a0", "$a1") := marshal.ReadInt (![sliceT byteT] "enc") in
    do:  "enc" <-[sliceT byteT] "$a1";;;
    do:  (struct.field_ref applyAsFollowerArgs "epoch" (![ptrT] "o")) <-[uint64T] "$a0";;;
    let: ("$a0", "$a1") := marshal.ReadInt (![sliceT byteT] "enc") in
    do:  "enc" <-[sliceT byteT] "$a1";;;
    do:  (struct.field_ref applyAsFollowerArgs "nextIndex" (![ptrT] "o")) <-[uint64T] "$a0";;;
    let: "$a0" := ![sliceT byteT] "enc" in
    do:  (struct.field_ref applyAsFollowerArgs "state" (![ptrT] "o")) <-[sliceT byteT] "$a0";;;
    return: (![ptrT] "o");;;
    do:  #()).

Definition encodeApplyAsFollowerReply : val :=
  rec: "encodeApplyAsFollowerReply" "o" :=
    exception_do (let: "o" := ref_ty ptrT "o" in
    let: "enc" := ref_ty (sliceT byteT) (zero_val (sliceT byteT)) in
    let: "$a0" := slice.make3 byteT #0 #8 in
    do:  "enc" <-[sliceT byteT] "$a0";;;
    let: "$a0" := marshal.WriteInt (![sliceT byteT] "enc") (![Error] (struct.field_ref applyAsFollowerReply "err" (![ptrT] "o"))) in
    do:  "enc" <-[sliceT byteT] "$a0";;;
    return: (![sliceT byteT] "enc");;;
    do:  #()).

Definition decodeEnterNewEpochArgs : val :=
  rec: "decodeEnterNewEpochArgs" "s" :=
    exception_do (let: "s" := ref_ty (sliceT byteT) "s" in
    let: "o" := ref_ty ptrT (zero_val ptrT) in
    let: "$a0" := ref_ty enterNewEpochArgs (zero_val enterNewEpochArgs) in
    do:  "o" <-[ptrT] "$a0";;;
    let: ("$a0", "$a1") := marshal.ReadInt (![sliceT byteT] "s") in
    do:  "$a1";;;
    do:  (struct.field_ref enterNewEpochArgs "epoch" (![ptrT] "o")) <-[uint64T] "$a0";;;
    return: (![ptrT] "o");;;
    do:  #()).

Definition encodeEnterNewEpochReply : val :=
  rec: "encodeEnterNewEpochReply" "o" :=
    exception_do (let: "o" := ref_ty ptrT "o" in
    let: "enc" := ref_ty (sliceT byteT) (zero_val (sliceT byteT)) in
    let: "$a0" := slice.make3 byteT #0 (((#8 + #8) + #8) + (slice.len (![sliceT byteT] (struct.field_ref enterNewEpochReply "state" (![ptrT] "o"))))) in
    do:  "enc" <-[sliceT byteT] "$a0";;;
    let: "$a0" := marshal.WriteInt (![sliceT byteT] "enc") (![Error] (struct.field_ref enterNewEpochReply "err" (![ptrT] "o"))) in
    do:  "enc" <-[sliceT byteT] "$a0";;;
    let: "$a0" := marshal.WriteInt (![sliceT byteT] "enc") (![uint64T] (struct.field_ref enterNewEpochReply "acceptedEpoch" (![ptrT] "o"))) in
    do:  "enc" <-[sliceT byteT] "$a0";;;
    let: "$a0" := marshal.WriteInt (![sliceT byteT] "enc") (![uint64T] (struct.field_ref enterNewEpochReply "nextIndex" (![ptrT] "o"))) in
    do:  "enc" <-[sliceT byteT] "$a0";;;
    let: "$a0" := marshal.WriteBytes (![sliceT byteT] "enc") (![sliceT byteT] (struct.field_ref enterNewEpochReply "state" (![ptrT] "o"))) in
    do:  "enc" <-[sliceT byteT] "$a0";;;
    return: (![sliceT byteT] "enc");;;
    do:  #()).

Definition applyReply : go_type := structT [
  "err" :: Error;
  "ret" :: sliceT byteT
].

Definition encodeApplyReply : val :=
  rec: "encodeApplyReply" "o" :=
    exception_do (let: "o" := ref_ty ptrT "o" in
    let: "enc" := ref_ty (sliceT byteT) (zero_val (sliceT byteT)) in
    let: "$a0" := slice.make3 byteT #0 (#8 + (slice.len (![sliceT byteT] (struct.field_ref applyReply "ret" (![ptrT] "o"))))) in
    do:  "enc" <-[sliceT byteT] "$a0";;;
    let: "$a0" := marshal.WriteInt (![sliceT byteT] "enc") (![Error] (struct.field_ref applyReply "err" (![ptrT] "o"))) in
    do:  "enc" <-[sliceT byteT] "$a0";;;
    let: "$a0" := marshal.WriteBytes (![sliceT byteT] "enc") (![sliceT byteT] (struct.field_ref applyReply "ret" (![ptrT] "o"))) in
    do:  "enc" <-[sliceT byteT] "$a0";;;
    return: (![sliceT byteT] "enc");;;
    do:  #()).

Definition decodeApplyReply : val :=
  rec: "decodeApplyReply" "enc" :=
    exception_do (let: "enc" := ref_ty (sliceT byteT) "enc" in
    let: "o" := ref_ty ptrT (zero_val ptrT) in
    let: "$a0" := ref_ty applyReply (struct.make applyReply [{
    }]) in
    do:  "o" <-[ptrT] "$a0";;;
    let: "err" := ref_ty uint64T (zero_val uint64T) in
    let: ("$a0", "$a1") := marshal.ReadInt (![sliceT byteT] "enc") in
    do:  "enc" <-[sliceT byteT] "$a1";;;
    do:  "err" <-[uint64T] "$a0";;;
    let: "$a0" := ![uint64T] "err" in
    do:  (struct.field_ref applyReply "err" (![ptrT] "o")) <-[Error] "$a0";;;
    let: "$a0" := ![sliceT byteT] "enc" in
    do:  (struct.field_ref applyReply "ret" (![ptrT] "o")) <-[sliceT byteT] "$a0";;;
    return: (![ptrT] "o");;;
    do:  #()).

Definition boolToU64 : val :=
  rec: "boolToU64" "b" :=
    exception_do (let: "b" := ref_ty boolT "b" in
    (if: ![boolT] "b"
    then
      return: (#1);;;
      do:  #()
    else
      return: (#0);;;
      do:  #());;;
    do:  #()).

(* paxosState from server.go *)

Definition paxosState : go_type := structT [
  "epoch" :: uint64T;
  "acceptedEpoch" :: uint64T;
  "nextIndex" :: uint64T;
  "state" :: sliceT byteT;
  "isLeader" :: boolT
].

Definition encodePaxosState : val :=
  rec: "encodePaxosState" "ps" :=
    exception_do (let: "ps" := ref_ty ptrT "ps" in
    let: "e" := ref_ty (sliceT byteT) (slice.make2 byteT #0) in
    let: "$a0" := marshal.WriteInt (![sliceT byteT] "e") (![uint64T] (struct.field_ref paxosState "epoch" (![ptrT] "ps"))) in
    do:  "e" <-[sliceT byteT] "$a0";;;
    let: "$a0" := marshal.WriteInt (![sliceT byteT] "e") (![uint64T] (struct.field_ref paxosState "acceptedEpoch" (![ptrT] "ps"))) in
    do:  "e" <-[sliceT byteT] "$a0";;;
    let: "$a0" := marshal.WriteInt (![sliceT byteT] "e") (![uint64T] (struct.field_ref paxosState "nextIndex" (![ptrT] "ps"))) in
    do:  "e" <-[sliceT byteT] "$a0";;;
    let: "$a0" := marshal.WriteInt (![sliceT byteT] "e") (boolToU64 (![boolT] (struct.field_ref paxosState "isLeader" (![ptrT] "ps")))) in
    do:  "e" <-[sliceT byteT] "$a0";;;
    let: "$a0" := marshal.WriteBytes (![sliceT byteT] "e") (![sliceT byteT] (struct.field_ref paxosState "state" (![ptrT] "ps"))) in
    do:  "e" <-[sliceT byteT] "$a0";;;
    return: (![sliceT byteT] "e");;;
    do:  #()).

Definition decodePaxosState : val :=
  rec: "decodePaxosState" "enc" :=
    exception_do (let: "enc" := ref_ty (sliceT byteT) "enc" in
    let: "e" := ref_ty (sliceT byteT) (![sliceT byteT] "enc") in
    let: "leaderInt" := ref_ty uint64T (zero_val uint64T) in
    let: "ps" := ref_ty ptrT (zero_val ptrT) in
    let: "$a0" := ref_ty paxosState (zero_val paxosState) in
    do:  "ps" <-[ptrT] "$a0";;;
    let: ("$a0", "$a1") := marshal.ReadInt (![sliceT byteT] "e") in
    do:  "e" <-[sliceT byteT] "$a1";;;
    do:  (struct.field_ref paxosState "epoch" (![ptrT] "ps")) <-[uint64T] "$a0";;;
    let: ("$a0", "$a1") := marshal.ReadInt (![sliceT byteT] "e") in
    do:  "e" <-[sliceT byteT] "$a1";;;
    do:  (struct.field_ref paxosState "acceptedEpoch" (![ptrT] "ps")) <-[uint64T] "$a0";;;
    let: ("$a0", "$a1") := marshal.ReadInt (![sliceT byteT] "e") in
    do:  "e" <-[sliceT byteT] "$a1";;;
    do:  (struct.field_ref paxosState "nextIndex" (![ptrT] "ps")) <-[uint64T] "$a0";;;
    let: ("$a0", "$a1") := marshal.ReadInt (![sliceT byteT] "e") in
    do:  (struct.field_ref paxosState "state" (![ptrT] "ps")) <-[sliceT byteT] "$a1";;;
    do:  "leaderInt" <-[uint64T] "$a0";;;
    let: "$a0" := (![uint64T] "leaderInt") = #1 in
    do:  (struct.field_ref paxosState "isLeader" (![ptrT] "ps")) <-[boolT] "$a0";;;
    return: (![ptrT] "ps");;;
    do:  #()).

(* server.go *)

Definition Server : go_type := structT [
  "mu" :: ptrT;
  "ps" :: ptrT;
  "storage" :: ptrT;
  "clerks" :: sliceT ptrT
].

Definition Server__withLock : val :=
  rec: "Server__withLock" "s" "f" :=
    exception_do (let: "s" := ref_ty ptrT "s" in
    let: "f" := ref_ty funcT "f" in
    do:  (sync.Mutex__Lock (![ptrT] (struct.field_ref Server "mu" (![ptrT] "s")))) #();;;
    do:  (![funcT] "f") (![ptrT] (struct.field_ref Server "ps" (![ptrT] "s")));;;
    let: "waitFn" := ref_ty funcT (zero_val funcT) in
    let: "$a0" := (asyncfile.AsyncFile__Write (![ptrT] (struct.field_ref Server "storage" (![ptrT] "s")))) (encodePaxosState (![ptrT] (struct.field_ref Server "ps" (![ptrT] "s")))) in
    do:  "waitFn" <-[funcT] "$a0";;;
    do:  (sync.Mutex__Unlock (![ptrT] (struct.field_ref Server "mu" (![ptrT] "s")))) #();;;
    do:  (![funcT] "waitFn") #();;;
    do:  #()).

Definition Server__applyAsFollower : val :=
  rec: "Server__applyAsFollower" "s" "args" "reply" :=
    exception_do (let: "s" := ref_ty ptrT "s" in
    let: "reply" := ref_ty ptrT "reply" in
    let: "args" := ref_ty ptrT "args" in
    do:  (Server__withLock (![ptrT] "s")) (λ: "ps",
      (if: (![uint64T] (struct.field_ref paxosState "epoch" (![ptrT] "ps"))) ≤ (![uint64T] (struct.field_ref applyAsFollowerArgs "epoch" (![ptrT] "args")))
      then
        (if: (![uint64T] (struct.field_ref paxosState "acceptedEpoch" (![ptrT] "ps"))) = (![uint64T] (struct.field_ref applyAsFollowerArgs "epoch" (![ptrT] "args")))
        then
          (if: (![uint64T] (struct.field_ref paxosState "nextIndex" (![ptrT] "ps"))) < (![uint64T] (struct.field_ref applyAsFollowerArgs "nextIndex" (![ptrT] "args")))
          then
            let: "$a0" := ![uint64T] (struct.field_ref applyAsFollowerArgs "nextIndex" (![ptrT] "args")) in
            do:  (struct.field_ref paxosState "nextIndex" (![ptrT] "ps")) <-[uint64T] "$a0";;;
            let: "$a0" := ![sliceT byteT] (struct.field_ref applyAsFollowerArgs "state" (![ptrT] "args")) in
            do:  (struct.field_ref paxosState "state" (![ptrT] "ps")) <-[sliceT byteT] "$a0";;;
            let: "$a0" := ENone in
            do:  (struct.field_ref applyAsFollowerReply "err" (![ptrT] "reply")) <-[Error] "$a0";;;
            do:  #()
          else
            let: "$a0" := ENone in
            do:  (struct.field_ref applyAsFollowerReply "err" (![ptrT] "reply")) <-[Error] "$a0";;;
            do:  #());;;
          do:  #()
        else
          let: "$a0" := ![uint64T] (struct.field_ref applyAsFollowerArgs "epoch" (![ptrT] "args")) in
          do:  (struct.field_ref paxosState "acceptedEpoch" (![ptrT] "ps")) <-[uint64T] "$a0";;;
          let: "$a0" := ![uint64T] (struct.field_ref applyAsFollowerArgs "epoch" (![ptrT] "args")) in
          do:  (struct.field_ref paxosState "epoch" (![ptrT] "ps")) <-[uint64T] "$a0";;;
          let: "$a0" := ![sliceT byteT] (struct.field_ref applyAsFollowerArgs "state" (![ptrT] "args")) in
          do:  (struct.field_ref paxosState "state" (![ptrT] "ps")) <-[sliceT byteT] "$a0";;;
          let: "$a0" := ![uint64T] (struct.field_ref applyAsFollowerArgs "nextIndex" (![ptrT] "args")) in
          do:  (struct.field_ref paxosState "nextIndex" (![ptrT] "ps")) <-[uint64T] "$a0";;;
          let: "$a0" := #false in
          do:  (struct.field_ref paxosState "isLeader" (![ptrT] "ps")) <-[boolT] "$a0";;;
          let: "$a0" := ENone in
          do:  (struct.field_ref applyAsFollowerReply "err" (![ptrT] "reply")) <-[Error] "$a0";;;
          do:  #());;;
        do:  #()
      else
        let: "$a0" := EEpochStale in
        do:  (struct.field_ref applyAsFollowerReply "err" (![ptrT] "reply")) <-[Error] "$a0";;;
        do:  #());;;
      do:  #()
      );;;
    do:  #()).

(* NOTE:
   This will vote yes only the first time it's called in an epoch.
   If you have too aggressive of a timeout and end up retrying this, the retry
   might fail because it may be the second execution of enterNewEpoch(epoch) on
   the server.
   Solution: either conservative (maybe double) timeouts, or don't use this for
   leader election, only for coming up with a valid proposal. *)
Definition Server__enterNewEpoch : val :=
  rec: "Server__enterNewEpoch" "s" "args" "reply" :=
    exception_do (let: "s" := ref_ty ptrT "s" in
    let: "reply" := ref_ty ptrT "reply" in
    let: "args" := ref_ty ptrT "args" in
    do:  (Server__withLock (![ptrT] "s")) (λ: "ps",
      (if: (![uint64T] (struct.field_ref paxosState "epoch" (![ptrT] "ps"))) ≥ (![uint64T] (struct.field_ref enterNewEpochArgs "epoch" (![ptrT] "args")))
      then
        let: "$a0" := EEpochStale in
        do:  (struct.field_ref enterNewEpochReply "err" (![ptrT] "reply")) <-[Error] "$a0";;;
        return: (#());;;
        do:  #()
      else do:  #());;;
      let: "$a0" := #false in
      do:  (struct.field_ref paxosState "isLeader" (![ptrT] "ps")) <-[boolT] "$a0";;;
      let: "$a0" := ![uint64T] (struct.field_ref enterNewEpochArgs "epoch" (![ptrT] "args")) in
      do:  (struct.field_ref paxosState "epoch" (![ptrT] "ps")) <-[uint64T] "$a0";;;
      let: "$a0" := ![uint64T] (struct.field_ref paxosState "acceptedEpoch" (![ptrT] "ps")) in
      do:  (struct.field_ref enterNewEpochReply "acceptedEpoch" (![ptrT] "reply")) <-[uint64T] "$a0";;;
      let: "$a0" := ![uint64T] (struct.field_ref paxosState "nextIndex" (![ptrT] "ps")) in
      do:  (struct.field_ref enterNewEpochReply "nextIndex" (![ptrT] "reply")) <-[uint64T] "$a0";;;
      let: "$a0" := ![sliceT byteT] (struct.field_ref paxosState "state" (![ptrT] "ps")) in
      do:  (struct.field_ref enterNewEpochReply "state" (![ptrT] "reply")) <-[sliceT byteT] "$a0";;;
      do:  #()
      );;;
    do:  #()).

Definition Server__TryBecomeLeader : val :=
  rec: "Server__TryBecomeLeader" "s" <> :=
    exception_do (let: "s" := ref_ty ptrT "s" in
    do:  log.Println #(str "started trybecomeleader");;;
    do:  (sync.Mutex__Lock (![ptrT] (struct.field_ref Server "mu" (![ptrT] "s")))) #();;;
    (if: ![boolT] (struct.field_ref paxosState "isLeader" (![ptrT] (struct.field_ref Server "ps" (![ptrT] "s"))))
    then
      do:  log.Println #(str "already leader");;;
      do:  (sync.Mutex__Unlock (![ptrT] (struct.field_ref Server "mu" (![ptrT] "s")))) #();;;
      return: (#());;;
      do:  #()
    else do:  #());;;
    let: "clerks" := ref_ty (sliceT ptrT) (zero_val (sliceT ptrT)) in
    let: "$a0" := ![sliceT ptrT] (struct.field_ref Server "clerks" (![ptrT] "s")) in
    do:  "clerks" <-[sliceT ptrT] "$a0";;;
    let: "args" := ref_ty ptrT (zero_val ptrT) in
    let: "$a0" := ref_ty enterNewEpochArgs (struct.make enterNewEpochArgs [{
      "epoch" ::= (![uint64T] (struct.field_ref paxosState "epoch" (![ptrT] (struct.field_ref Server "ps" (![ptrT] "s"))))) + #1
    }]) in
    do:  "args" <-[ptrT] "$a0";;;
    do:  (sync.Mutex__Unlock (![ptrT] (struct.field_ref Server "mu" (![ptrT] "s")))) #();;;
    let: "numReplies" := ref_ty uint64T #0 in
    let: "replies" := ref_ty (sliceT ptrT) (zero_val (sliceT ptrT)) in
    let: "$a0" := slice.make2 ptrT (slice.len (![sliceT ptrT] "clerks")) in
    do:  "replies" <-[sliceT ptrT] "$a0";;;
    let: "mu" := ref_ty ptrT (zero_val ptrT) in
    let: "$a0" := ref_ty sync.Mutex (zero_val sync.Mutex) in
    do:  "mu" <-[ptrT] "$a0";;;
    let: "numReplies_cond" := ref_ty ptrT (zero_val ptrT) in
    let: "$a0" := sync.NewCond (![ptrT] "mu") in
    do:  "numReplies_cond" <-[ptrT] "$a0";;;
    let: "n" := ref_ty uint64T (zero_val uint64T) in
    let: "$a0" := slice.len (![sliceT ptrT] "clerks") in
    do:  "n" <-[uint64T] "$a0";;;
    do:  let: "$range" := ![sliceT ptrT] "clerks" in
    slice.for_range ptrT "$range" (λ: "i" "ck",
      let: "i" := ref_ty uint64T "i" in
      let: "ck" := ref_ty ptrT "ck" in
      let: "$go" := (λ: <>,
        let: "reply" := ref_ty ptrT (zero_val ptrT) in
        let: "$a0" := (singleClerk__enterNewEpoch (![ptrT] "ck")) (![ptrT] "args") in
        do:  "reply" <-[ptrT] "$a0";;;
        do:  (sync.Mutex__Lock (![ptrT] "mu")) #();;;
        do:  "numReplies" <-[uint64T] ((![uint64T] "numReplies") + #1);;;
        let: "$a0" := ![ptrT] "reply" in
        do:  (slice.elem_ref ptrT (![sliceT ptrT] "replies") (![intT] "i")) <-[ptrT] "$a0";;;
        (if: (#2 * (![uint64T] "numReplies")) > (![uint64T] "n")
        then
          do:  (sync.Cond__Signal (![ptrT] "numReplies_cond")) #();;;
          do:  #()
        else do:  #());;;
        do:  (sync.Mutex__Unlock (![ptrT] "mu")) #();;;
        do:  #()
        ) in
      do:  Fork ("$go" #());;;
      do:  #());;;
    do:  (sync.Mutex__Lock (![ptrT] "mu")) #();;;
    (for: (λ: <>, (#2 * (![uint64T] "numReplies")) ≤ (![uint64T] "n")); (λ: <>, Skip) := λ: <>,
      do:  (sync.Cond__Wait (![ptrT] "numReplies_cond")) #();;;
      do:  #());;;
    let: "latestReply" := ref_ty ptrT (zero_val ptrT) in
    let: "numSuccesses" := ref_ty uint64T #0 in
    do:  let: "$range" := ![sliceT ptrT] "replies" in
    slice.for_range ptrT "$range" (λ: <> "reply",
      let: "reply" := ref_ty ptrT "reply" in
      (if: (![ptrT] "reply") ≠ #null
      then
        (if: (![Error] (struct.field_ref enterNewEpochReply "err" (![ptrT] "reply"))) = ENone
        then
          (if: (![uint64T] "numSuccesses") = #0
          then
            let: "$a0" := ![ptrT] "reply" in
            do:  "latestReply" <-[ptrT] "$a0";;;
            do:  #()
          else
            (if: (![uint64T] (struct.field_ref enterNewEpochReply "acceptedEpoch" (![ptrT] "latestReply"))) < (![uint64T] (struct.field_ref enterNewEpochReply "acceptedEpoch" (![ptrT] "reply")))
            then
              let: "$a0" := ![ptrT] "reply" in
              do:  "latestReply" <-[ptrT] "$a0";;;
              do:  #()
            else
              (if: ((![uint64T] (struct.field_ref enterNewEpochReply "acceptedEpoch" (![ptrT] "latestReply"))) = (![uint64T] (struct.field_ref enterNewEpochReply "acceptedEpoch" (![ptrT] "reply")))) && ((![uint64T] (struct.field_ref enterNewEpochReply "nextIndex" (![ptrT] "reply"))) > (![uint64T] (struct.field_ref enterNewEpochReply "nextIndex" (![ptrT] "latestReply"))))
              then
                let: "$a0" := ![ptrT] "reply" in
                do:  "latestReply" <-[ptrT] "$a0";;;
                do:  #()
              else do:  #());;;
              #());;;
            do:  #());;;
          do:  "numSuccesses" <-[uint64T] ((![uint64T] "numSuccesses") + #1);;;
          do:  #()
        else do:  #());;;
        do:  #()
      else do:  #());;;
      do:  #());;;
    (if: (#2 * (![uint64T] "numSuccesses")) > (![uint64T] "n")
    then
      do:  (Server__withLock (![ptrT] "s")) (λ: "ps",
        (if: (![uint64T] (struct.field_ref paxosState "epoch" (![ptrT] "ps"))) ≤ (![uint64T] (struct.field_ref enterNewEpochArgs "epoch" (![ptrT] "args")))
        then
          do:  log.Printf #(str "succeeded becomeleader in epoch %!!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)!(MISSING)d(MISSING)
          ") (![uint64T] (struct.field_ref enterNewEpochArgs "epoch" (![ptrT] "args")));;;
          let: "$a0" := ![uint64T] (struct.field_ref enterNewEpochArgs "epoch" (![ptrT] "args")) in
          do:  (struct.field_ref paxosState "epoch" (![ptrT] "ps")) <-[uint64T] "$a0";;;
          let: "$a0" := #true in
          do:  (struct.field_ref paxosState "isLeader" (![ptrT] "ps")) <-[boolT] "$a0";;;
          let: "$a0" := ![uint64T] (struct.field_ref paxosState "epoch" (![ptrT] "ps")) in
          do:  (struct.field_ref paxosState "acceptedEpoch" (![ptrT] "ps")) <-[uint64T] "$a0";;;
          let: "$a0" := ![uint64T] (struct.field_ref enterNewEpochReply "nextIndex" (![ptrT] "latestReply")) in
          do:  (struct.field_ref paxosState "nextIndex" (![ptrT] "ps")) <-[uint64T] "$a0";;;
          let: "$a0" := ![sliceT byteT] (struct.field_ref enterNewEpochReply "state" (![ptrT] "latestReply")) in
          do:  (struct.field_ref paxosState "state" (![ptrT] "ps")) <-[sliceT byteT] "$a0";;;
          do:  #()
        else do:  #());;;
        do:  #()
        );;;
      do:  (sync.Mutex__Unlock (![ptrT] "mu")) #();;;
      do:  #()
    else
      do:  (sync.Mutex__Unlock (![ptrT] "mu")) #();;;
      do:  log.Println #(str "failed becomeleader");;;
      do:  #());;;
    do:  #()).

Definition Server__TryAcquire : val :=
  rec: "Server__TryAcquire" "s" <> :=
    exception_do (let: "s" := ref_ty ptrT "s" in
    let: "retErr" := ref_ty Error (zero_val Error) in
    do:  (sync.Mutex__Lock (![ptrT] (struct.field_ref Server "mu" (![ptrT] "s")))) #();;;
    (if: (~ (![boolT] (struct.field_ref paxosState "isLeader" (![ptrT] (struct.field_ref Server "ps" (![ptrT] "s"))))))
    then
      do:  (sync.Mutex__Unlock (![ptrT] (struct.field_ref Server "mu" (![ptrT] "s")))) #();;;
      let: "n" := ref_ty ptrT (zero_val ptrT) in
      return: (ENotLeader, ![ptrT] "n", slice.nil);;;
      do:  #()
    else do:  #());;;
    let: "tryRelease" := ref_ty funcT (zero_val funcT) in
    let: "$a0" := (λ: <>,
      let: "$a0" := std.SumAssumeNoOverflow (![uint64T] (struct.field_ref paxosState "nextIndex" (![ptrT] (struct.field_ref Server "ps" (![ptrT] "s"))))) #1 in
      do:  (struct.field_ref paxosState "nextIndex" (![ptrT] (struct.field_ref Server "ps" (![ptrT] "s")))) <-[uint64T] "$a0";;;
      let: "args" := ref_ty ptrT (zero_val ptrT) in
      let: "$a0" := ref_ty applyAsFollowerArgs (struct.make applyAsFollowerArgs [{
        "epoch" ::= ![uint64T] (struct.field_ref paxosState "epoch" (![ptrT] (struct.field_ref Server "ps" (![ptrT] "s"))));
        "nextIndex" ::= ![uint64T] (struct.field_ref paxosState "nextIndex" (![ptrT] (struct.field_ref Server "ps" (![ptrT] "s"))));
        "state" ::= ![sliceT byteT] (struct.field_ref paxosState "state" (![ptrT] (struct.field_ref Server "ps" (![ptrT] "s"))))
      }]) in
      do:  "args" <-[ptrT] "$a0";;;
      let: "waitFn" := ref_ty funcT (zero_val funcT) in
      let: "$a0" := (asyncfile.AsyncFile__Write (![ptrT] (struct.field_ref Server "storage" (![ptrT] "s")))) (encodePaxosState (![ptrT] (struct.field_ref Server "ps" (![ptrT] "s")))) in
      do:  "waitFn" <-[funcT] "$a0";;;
      do:  (sync.Mutex__Unlock (![ptrT] (struct.field_ref Server "mu" (![ptrT] "s")))) #();;;
      do:  (![funcT] "waitFn") #();;;
      let: "clerks" := ref_ty (sliceT ptrT) (zero_val (sliceT ptrT)) in
      let: "$a0" := ![sliceT ptrT] (struct.field_ref Server "clerks" (![ptrT] "s")) in
      do:  "clerks" <-[sliceT ptrT] "$a0";;;
      let: "numReplies" := ref_ty uint64T #0 in
      let: "replies" := ref_ty (sliceT ptrT) (zero_val (sliceT ptrT)) in
      let: "$a0" := slice.make2 ptrT (slice.len (![sliceT ptrT] "clerks")) in
      do:  "replies" <-[sliceT ptrT] "$a0";;;
      let: "mu" := ref_ty ptrT (zero_val ptrT) in
      let: "$a0" := ref_ty sync.Mutex (zero_val sync.Mutex) in
      do:  "mu" <-[ptrT] "$a0";;;
      let: "numReplies_cond" := ref_ty ptrT (zero_val ptrT) in
      let: "$a0" := sync.NewCond (![ptrT] "mu") in
      do:  "numReplies_cond" <-[ptrT] "$a0";;;
      let: "n" := ref_ty uint64T (zero_val uint64T) in
      let: "$a0" := slice.len (![sliceT ptrT] "clerks") in
      do:  "n" <-[uint64T] "$a0";;;
      do:  let: "$range" := ![sliceT ptrT] "clerks" in
      slice.for_range ptrT "$range" (λ: "i" "ck",
        let: "i" := ref_ty uint64T "i" in
        let: "ck" := ref_ty ptrT "ck" in
        let: "ck" := ref_ty ptrT (zero_val ptrT) in
        let: "$a0" := ![ptrT] "ck" in
        do:  "ck" <-[ptrT] "$a0";;;
        let: "i" := ref_ty intT (zero_val intT) in
        let: "$a0" := ![intT] "i" in
        do:  "i" <-[intT] "$a0";;;
        let: "$go" := (λ: <>,
          let: "reply" := ref_ty ptrT (zero_val ptrT) in
          let: "$a0" := (singleClerk__applyAsFollower (![ptrT] "ck")) (![ptrT] "args") in
          do:  "reply" <-[ptrT] "$a0";;;
          do:  (sync.Mutex__Lock (![ptrT] "mu")) #();;;
          do:  "numReplies" <-[uint64T] ((![uint64T] "numReplies") + #1);;;
          let: "$a0" := ![ptrT] "reply" in
          do:  (slice.elem_ref ptrT (![sliceT ptrT] "replies") (![intT] "i")) <-[ptrT] "$a0";;;
          (if: (#2 * (![uint64T] "numReplies")) > (![uint64T] "n")
          then
            do:  (sync.Cond__Signal (![ptrT] "numReplies_cond")) #();;;
            do:  #()
          else do:  #());;;
          do:  (sync.Mutex__Unlock (![ptrT] "mu")) #();;;
          do:  #()
          ) in
        do:  Fork ("$go" #());;;
        do:  #());;;
      do:  (sync.Mutex__Lock (![ptrT] "mu")) #();;;
      (for: (λ: <>, (#2 * (![uint64T] "numReplies")) ≤ (![uint64T] "n")); (λ: <>, Skip) := λ: <>,
        do:  (sync.Cond__Wait (![ptrT] "numReplies_cond")) #();;;
        do:  #());;;
      let: "numSuccesses" := ref_ty uint64T #0 in
      do:  let: "$range" := ![sliceT ptrT] "replies" in
      slice.for_range ptrT "$range" (λ: <> "reply",
        let: "reply" := ref_ty ptrT "reply" in
        (if: (![ptrT] "reply") ≠ #null
        then
          (if: (![Error] (struct.field_ref applyAsFollowerReply "err" (![ptrT] "reply"))) = ENone
          then
            do:  "numSuccesses" <-[uint64T] ((![uint64T] "numSuccesses") + #1);;;
            do:  #()
          else do:  #());;;
          do:  #()
        else do:  #());;;
        do:  #());;;
      (if: (#2 * (![uint64T] "numSuccesses")) > (![uint64T] "n")
      then
        let: "$a0" := ENone in
        do:  "retErr" <-[Error] "$a0";;;
        do:  #()
      else
        let: "$a0" := EEpochStale in
        do:  "retErr" <-[Error] "$a0";;;
        do:  #());;;
      return: (![Error] "retErr");;;
      do:  #()
      ) in
    do:  "tryRelease" <-[funcT] "$a0";;;
    return: (ENone, struct.field_ref paxosState "state" (![ptrT] (struct.field_ref Server "ps" (![ptrT] "s"))), ![funcT] "tryRelease");;;
    do:  #()).

Definition Server__WeakRead : val :=
  rec: "Server__WeakRead" "s" <> :=
    exception_do (let: "s" := ref_ty ptrT "s" in
    do:  (sync.Mutex__Lock (![ptrT] (struct.field_ref Server "mu" (![ptrT] "s")))) #();;;
    let: "ret" := ref_ty (sliceT byteT) (zero_val (sliceT byteT)) in
    let: "$a0" := ![sliceT byteT] (struct.field_ref paxosState "state" (![ptrT] (struct.field_ref Server "ps" (![ptrT] "s")))) in
    do:  "ret" <-[sliceT byteT] "$a0";;;
    do:  (sync.Mutex__Unlock (![ptrT] (struct.field_ref Server "mu" (![ptrT] "s")))) #();;;
    return: (![sliceT byteT] "ret");;;
    do:  #()).

Definition makeServer : val :=
  rec: "makeServer" "fname" "initstate" "config" :=
    exception_do (let: "config" := ref_ty (sliceT uint64T) "config" in
    let: "initstate" := ref_ty (sliceT byteT) "initstate" in
    let: "fname" := ref_ty stringT "fname" in
    let: "s" := ref_ty ptrT (zero_val ptrT) in
    let: "$a0" := ref_ty Server (zero_val Server) in
    do:  "s" <-[ptrT] "$a0";;;
    let: "$a0" := ref_ty sync.Mutex (zero_val sync.Mutex) in
    do:  (struct.field_ref Server "mu" (![ptrT] "s")) <-[ptrT] "$a0";;;
    let: "$a0" := slice.make2 ptrT #0 in
    do:  (struct.field_ref Server "clerks" (![ptrT] "s")) <-[sliceT ptrT] "$a0";;;
    do:  let: "$range" := ![sliceT uint64T] "config" in
    slice.for_range uint64T "$range" (λ: <> "host",
      let: "host" := ref_ty uint64T "host" in
      let: "$a0" := slice.append ptrT (![sliceT ptrT] (struct.field_ref Server "clerks" (![ptrT] "s"))) (slice.literal ptrT [MakeSingleClerk (![uint64T] "host")]) in
      do:  (struct.field_ref Server "clerks" (![ptrT] "s")) <-[sliceT ptrT] "$a0";;;
      do:  #());;;
    let: "encstate" := ref_ty (sliceT byteT) (zero_val (sliceT byteT)) in
    let: ("$a0", "$a1") := asyncfile.MakeAsyncFile (![stringT] "fname") in
    do:  (struct.field_ref Server "storage" (![ptrT] "s")) <-[ptrT] "$a1";;;
    do:  "encstate" <-[sliceT byteT] "$a0";;;
    (if: (slice.len (![sliceT byteT] "encstate")) = #0
    then
      let: "$a0" := ref_ty paxosState (zero_val paxosState) in
      do:  (struct.field_ref Server "ps" (![ptrT] "s")) <-[ptrT] "$a0";;;
      let: "$a0" := ![sliceT byteT] "initstate" in
      do:  (struct.field_ref paxosState "state" (![ptrT] (struct.field_ref Server "ps" (![ptrT] "s")))) <-[sliceT byteT] "$a0";;;
      do:  #()
    else
      let: "$a0" := decodePaxosState (![sliceT byteT] "encstate") in
      do:  (struct.field_ref Server "ps" (![ptrT] "s")) <-[ptrT] "$a0";;;
      do:  #());;;
    return: (![ptrT] "s");;;
    do:  #()).

Definition StartServer : val :=
  rec: "StartServer" "fname" "initstate" "me" "config" :=
    exception_do (let: "config" := ref_ty (sliceT uint64T) "config" in
    let: "me" := ref_ty uint64T "me" in
    let: "initstate" := ref_ty (sliceT byteT) "initstate" in
    let: "fname" := ref_ty stringT "fname" in
    let: "s" := ref_ty ptrT (zero_val ptrT) in
    let: "$a0" := makeServer (![stringT] "fname") (![sliceT byteT] "initstate") (![sliceT uint64T] "config") in
    do:  "s" <-[ptrT] "$a0";;;
    let: "handlers" := ref_ty (mapT uint64T funcT) (zero_val (mapT uint64T funcT)) in
    let: "$a0" := map.make uint64T funcT #() in
    do:  "handlers" <-[mapT uint64T funcT] "$a0";;;
    let: "$a0" := (λ: "raw_args" "raw_reply",
      let: "reply" := ref_ty ptrT (zero_val ptrT) in
      let: "$a0" := ref_ty applyAsFollowerReply (zero_val applyAsFollowerReply) in
      do:  "reply" <-[ptrT] "$a0";;;
      let: "args" := ref_ty ptrT (zero_val ptrT) in
      let: "$a0" := decodeApplyAsFollowerArgs (![sliceT byteT] "raw_args") in
      do:  "args" <-[ptrT] "$a0";;;
      do:  (Server__applyAsFollower (![ptrT] "s")) (![ptrT] "args") (![ptrT] "reply");;;
      let: "$a0" := encodeApplyAsFollowerReply (![ptrT] "reply") in
      do:  (![ptrT] "raw_reply") <-[sliceT byteT] "$a0";;;
      do:  #()
      ) in
    do:  map.insert (![mapT uint64T funcT] "handlers") RPC_APPLY_AS_FOLLOWER "$a0";;;
    let: "$a0" := (λ: "raw_args" "raw_reply",
      let: "reply" := ref_ty ptrT (zero_val ptrT) in
      let: "$a0" := ref_ty enterNewEpochReply (zero_val enterNewEpochReply) in
      do:  "reply" <-[ptrT] "$a0";;;
      let: "args" := ref_ty ptrT (zero_val ptrT) in
      let: "$a0" := decodeEnterNewEpochArgs (![sliceT byteT] "raw_args") in
      do:  "args" <-[ptrT] "$a0";;;
      do:  (Server__enterNewEpoch (![ptrT] "s")) (![ptrT] "args") (![ptrT] "reply");;;
      let: "$a0" := encodeEnterNewEpochReply (![ptrT] "reply") in
      do:  (![ptrT] "raw_reply") <-[sliceT byteT] "$a0";;;
      do:  #()
      ) in
    do:  map.insert (![mapT uint64T funcT] "handlers") RPC_ENTER_NEW_EPOCH "$a0";;;
    let: "$a0" := (λ: "raw_args" "raw_reply",
      do:  (Server__TryBecomeLeader (![ptrT] "s")) #();;;
      do:  #()
      ) in
    do:  map.insert (![mapT uint64T funcT] "handlers") RPC_BECOME_LEADER "$a0";;;
    let: "r" := ref_ty ptrT (zero_val ptrT) in
    let: "$a0" := urpc.MakeServer (![mapT uint64T funcT] "handlers") in
    do:  "r" <-[ptrT] "$a0";;;
    do:  (urpc.Server__Serve (![ptrT] "r")) (![uint64T] "me");;;
    return: (![ptrT] "s");;;
    do:  #()).