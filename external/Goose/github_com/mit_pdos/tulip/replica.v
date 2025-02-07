(* autogenerated from github.com/mit-pdos/tulip/replica *)
From Perennial.goose_lang Require Import prelude.
From Goose Require github_com.goose_lang.std.
From Goose Require github_com.mit_pdos.tulip.backup.
From Goose Require github_com.mit_pdos.tulip.index.
From Goose Require github_com.mit_pdos.tulip.message.
From Goose Require github_com.mit_pdos.tulip.tulip.
From Goose Require github_com.mit_pdos.tulip.txnlog.
From Goose Require github_com.mit_pdos.tulip.util.
From Goose Require github_com.tchajed.marshal.

From Perennial.goose_lang Require Import ffi.grove_prelude.

Definition PrepareProposal := struct.decl [
  "rank" :: uint64T;
  "dec" :: boolT
].

Definition Replica := struct.decl [
  "mu" :: ptrT;
  "rid" :: uint64T;
  "addr" :: uint64T;
  "fname" :: stringT;
  "txnlog" :: ptrT;
  "lsna" :: uint64T;
  "prepm" :: mapT (slice.T (struct.t tulip.WriteEntry));
  "ptgsm" :: mapT (slice.T uint64T);
  "pstbl" :: mapT (struct.t PrepareProposal);
  "rktbl" :: mapT uint64T;
  "txntbl" :: mapT boolT;
  "ptsm" :: mapT uint64T;
  "sptsm" :: mapT uint64T;
  "idx" :: ptrT;
  "rps" :: mapT uint64T;
  "leader" :: uint64T
].

(* Arguments:
   @ts: Transaction timestamp.

   Return values:
   @terminated: Whether txn @ts has terminated (committed or aborted). *)
Definition Replica__terminated: val :=
  rec: "Replica__terminated" "rp" "ts" :=
    let: (<>, "terminated") := MapGet (struct.loadF Replica "txntbl" "rp") "ts" in
    "terminated".

Definition Replica__Terminated: val :=
  rec: "Replica__Terminated" "rp" "ts" :=
    Mutex__Lock (struct.loadF Replica "mu" "rp");;
    let: "terminated" := Replica__terminated "rp" "ts" in
    Mutex__Unlock (struct.loadF Replica "mu" "rp");;
    "terminated".

(* Arguments:
   @ts: Transaction timestamp.

   Return values:
   @ok: If @true, this transaction is committed. *)
Definition Replica__Commit: val :=
  rec: "Replica__Commit" "rp" "ts" "pwrs" :=
    let: "committed" := Replica__Terminated "rp" "ts" in
    (if: "committed"
    then #true
    else
      let: ("lsn", "term") := txnlog.TxnLog__SubmitCommit (struct.loadF Replica "txnlog" "rp") "ts" "pwrs" in
      (if: "term" = #0
      then #false
      else
        let: "safe" := txnlog.TxnLog__WaitUntilSafe (struct.loadF Replica "txnlog" "rp") "lsn" "term" in
        (if: (~ "safe")
        then #false
        else #true))).

(* Arguments:
   @ts: Transaction timestamp.

   Return values:
   @ok: If @true, this transaction is aborted. *)
Definition Replica__Abort: val :=
  rec: "Replica__Abort" "rp" "ts" :=
    let: "aborted" := Replica__Terminated "rp" "ts" in
    (if: "aborted"
    then #true
    else
      let: ("lsn", "term") := txnlog.TxnLog__SubmitAbort (struct.loadF Replica "txnlog" "rp") "ts" in
      (if: "term" = #0
      then #false
      else
        let: "safe" := txnlog.TxnLog__WaitUntilSafe (struct.loadF Replica "txnlog" "rp") "lsn" "term" in
        (if: (~ "safe")
        then #false
        else #true))).

Definition Replica__readableKey: val :=
  rec: "Replica__readableKey" "rp" "ts" "key" :=
    let: "pts" := Fst (MapGet (struct.loadF Replica "ptsm" "rp") "key") in
    (if: ("pts" ≠ #0) && ("pts" ≤ "ts")
    then #false
    else #true).

Definition Replica__bumpKey: val :=
  rec: "Replica__bumpKey" "rp" "ts" "key" :=
    let: "spts" := Fst (MapGet (struct.loadF Replica "sptsm" "rp") "key") in
    (if: ("ts" - #1) ≤ "spts"
    then #false
    else
      MapInsert (struct.loadF Replica "sptsm" "rp") "key" ("ts" - #1);;
      #true).

Definition CMD_READ : expr := #0.

Definition CMD_VALIDATE : expr := #1.

Definition CMD_FAST_PREPARE : expr := #2.

Definition CMD_ACCEPT : expr := #3.

Definition logRead: val :=
  rec: "logRead" "fname" "ts" "key" :=
    let: "bs" := NewSliceWithCap byteT #0 #32 in
    let: "bs1" := marshal.WriteInt "bs" CMD_READ in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "bs3" := util.EncodeString "bs2" "key" in
    grove_ffi.FileAppend "fname" "bs3";;
    #().

(* Arguments:
   @ts: Transaction timestamp.
   @key: Key to be read.

   Return values:
   @ver: If @ver.Timestamp = 0, then this is a fast-path read---the value at @ts
   has been determined to be @ver.Value. Otherwise, this is a slow-path read,
   the replica promises not to accept prepare requests from transactions that
   modifies this tuple and whose timestamp lies within @ver.Timestamp and @ts.

   @ok: @ver is meaningful iff @ok is true.

   Design note:

   1. It might seem redundant and inefficient to call @tpl.ReadVersion twice for
   each @rp.Read, but the point is that the first one is called without holding
   the global replica lock, which improves the latency for a fast-read, and
   throughput for non-conflicting fast-reads. An alternative design is to remove
   the first part at all, which favors slow-reads.

   2. Right now the index is still a global lock; ideally we should also shard
   the index lock as done in vMVCC. However, the index lock should be held
   relatively short compared to the replica lock, so the performance impact
   should be less. *)
Definition Replica__Read: val :=
  rec: "Replica__Read" "rp" "ts" "key" :=
    let: "tpl" := index.Index__GetTuple (struct.loadF Replica "idx" "rp") "key" in
    let: ("v1", "slow1") := tuple.Tuple__ReadVersion "tpl" "ts" in
    (if: (~ "slow1")
    then ("v1", #false, #true)
    else
      Mutex__Lock (struct.loadF Replica "mu" "rp");;
      let: "ok" := Replica__readableKey "rp" "ts" "key" in
      (if: (~ "ok")
      then
        Mutex__Unlock (struct.loadF Replica "mu" "rp");;
        (struct.mk tulip.Version [
         ], #false, #false)
      else
        let: ("v2", "slow2") := tuple.Tuple__ReadVersion "tpl" "ts" in
        (if: (~ "slow2")
        then
          Mutex__Unlock (struct.loadF Replica "mu" "rp");;
          ("v2", #false, #true)
        else
          Replica__bumpKey "rp" "ts" "key";;
          logRead (struct.loadF Replica "fname" "rp") "ts" "key";;
          Mutex__Unlock (struct.loadF Replica "mu" "rp");;
          ("v2", #true, #true)))).

Definition Replica__writableKey: val :=
  rec: "Replica__writableKey" "rp" "ts" "key" :=
    let: "pts" := Fst (MapGet (struct.loadF Replica "ptsm" "rp") "key") in
    (if: "pts" ≠ #0
    then #false
    else
      let: "spts" := Fst (MapGet (struct.loadF Replica "sptsm" "rp") "key") in
      (if: "ts" ≤ "spts"
      then #false
      else #true)).

Definition Replica__acquireKey: val :=
  rec: "Replica__acquireKey" "rp" "ts" "key" :=
    MapInsert (struct.loadF Replica "ptsm" "rp") "key" "ts";;
    MapInsert (struct.loadF Replica "sptsm" "rp") "key" "ts";;
    #().

Definition Replica__acquire: val :=
  rec: "Replica__acquire" "rp" "ts" "pwrs" :=
    let: "pos" := ref_to uint64T #0 in
    Skip;;
    (for: (λ: <>, (![uint64T] "pos") < (slice.len "pwrs")); (λ: <>, Skip) := λ: <>,
      let: "ent" := SliceGet (struct.t tulip.WriteEntry) "pwrs" (![uint64T] "pos") in
      let: "writable" := Replica__writableKey "rp" "ts" (struct.get tulip.WriteEntry "Key" "ent") in
      (if: (~ "writable")
      then Break
      else
        "pos" <-[uint64T] ((![uint64T] "pos") + #1);;
        Continue));;
    (if: (![uint64T] "pos") < (slice.len "pwrs")
    then #false
    else
      ForSlice (struct.t tulip.WriteEntry) <> "ent" "pwrs"
        (Replica__acquireKey "rp" "ts" (struct.get tulip.WriteEntry "Key" "ent"));;
      #true).

Definition Replica__finalized: val :=
  rec: "Replica__finalized" "rp" "ts" :=
    let: ("cmted", "done") := MapGet (struct.loadF Replica "txntbl" "rp") "ts" in
    (if: "done"
    then
      (if: "cmted"
      then (tulip.REPLICA_COMMITTED_TXN, #true)
      else (tulip.REPLICA_ABORTED_TXN, #true))
    else (tulip.REPLICA_OK, #false)).

Definition logValidate: val :=
  rec: "logValidate" "fname" "ts" "pwrs" "ptgs" :=
    let: "bs" := NewSliceWithCap byteT #0 #64 in
    let: "bs1" := marshal.WriteInt "bs" CMD_VALIDATE in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "bs3" := util.EncodeKVMapFromSlice "bs2" "pwrs" in
    grove_ffi.FileAppend "fname" "bs3";;
    #().

(* Arguments:
   @ts: Transaction timestamp.
   @pwrs: Write set of transaction @ts.
   @ptgs: Participant groups of transaction @ts.

   Return values:
   @error: Error code. *)
Definition Replica__validate: val :=
  rec: "Replica__validate" "rp" "ts" "pwrs" "ptgs" :=
    let: ("res", "final") := Replica__finalized "rp" "ts" in
    (if: "final"
    then "res"
    else
      let: (<>, "validated") := MapGet (struct.loadF Replica "prepm" "rp") "ts" in
      (if: "validated"
      then tulip.REPLICA_OK
      else
        let: "acquired" := Replica__acquire "rp" "ts" "pwrs" in
        (if: (~ "acquired")
        then tulip.REPLICA_FAILED_VALIDATION
        else
          MapInsert (struct.loadF Replica "prepm" "rp") "ts" "pwrs";;
          logValidate (struct.loadF Replica "fname" "rp") "ts" "pwrs" "ptgs";;
          tulip.REPLICA_OK))).

(* Keep alive coordinator for @ts at @rank. *)
Definition Replica__refresh: val :=
  rec: "Replica__refresh" "rp" "ts" "rank" :=
    #().

Definition Replica__Validate: val :=
  rec: "Replica__Validate" "rp" "ts" "rank" "pwrs" "ptgs" :=
    Mutex__Lock (struct.loadF Replica "mu" "rp");;
    let: "res" := Replica__validate "rp" "ts" "pwrs" "ptgs" in
    Replica__refresh "rp" "ts" "rank";;
    Mutex__Unlock (struct.loadF Replica "mu" "rp");;
    "res".

Definition Replica__lastProposal: val :=
  rec: "Replica__lastProposal" "rp" "ts" :=
    let: ("ps", "ok") := MapGet (struct.loadF Replica "pstbl" "rp") "ts" in
    (struct.get PrepareProposal "rank" "ps", struct.get PrepareProposal "dec" "ps", "ok").

Definition Replica__accept: val :=
  rec: "Replica__accept" "rp" "ts" "rank" "dec" :=
    let: "pp" := struct.mk PrepareProposal [
      "rank" ::= "rank";
      "dec" ::= "dec"
    ] in
    MapInsert (struct.loadF Replica "pstbl" "rp") "ts" "pp";;
    MapInsert (struct.loadF Replica "rktbl" "rp") "ts" (std.SumAssumeNoOverflow "rank" #1);;
    #().

Definition logAccept: val :=
  rec: "logAccept" "fname" "ts" "rank" "dec" :=
    let: "bs" := NewSliceWithCap byteT #0 #32 in
    let: "bs1" := marshal.WriteInt "bs" CMD_ACCEPT in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "bs3" := marshal.WriteInt "bs2" "rank" in
    let: "bs4" := marshal.WriteBool "bs3" "dec" in
    grove_ffi.FileAppend "fname" "bs4";;
    #().

Definition logFastPrepare: val :=
  rec: "logFastPrepare" "fname" "ts" "pwrs" "ptgs" :=
    let: "bs" := NewSliceWithCap byteT #0 #64 in
    let: "bs1" := marshal.WriteInt "bs" CMD_FAST_PREPARE in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "bs3" := util.EncodeKVMapFromSlice "bs2" "pwrs" in
    grove_ffi.FileAppend "fname" "bs3";;
    #().

(* Arguments:
   @ts: Transaction timestamp.

   @pwrs: Transaction write set.

   Return values:

   @error: Error code. *)
Definition Replica__fastPrepare: val :=
  rec: "Replica__fastPrepare" "rp" "ts" "pwrs" "ptgs" :=
    let: ("res", "final") := Replica__finalized "rp" "ts" in
    (if: "final"
    then "res"
    else
      let: (("rank", "dec"), "ok") := Replica__lastProposal "rp" "ts" in
      (if: "ok"
      then
        (if: #0 < "rank"
        then tulip.REPLICA_STALE_COORDINATOR
        else
          (if: (~ "dec")
          then tulip.REPLICA_FAILED_VALIDATION
          else tulip.REPLICA_OK))
      else
        let: (<>, "validated") := MapGet (struct.loadF Replica "prepm" "rp") "ts" in
        (if: "validated"
        then tulip.REPLICA_STALE_COORDINATOR
        else
          let: "acquired" := Replica__acquire "rp" "ts" "pwrs" in
          Replica__accept "rp" "ts" #0 "acquired";;
          (if: (~ "acquired")
          then
            logAccept (struct.loadF Replica "fname" "rp") "ts" #0 #false;;
            tulip.REPLICA_FAILED_VALIDATION
          else
            MapInsert (struct.loadF Replica "prepm" "rp") "ts" "pwrs";;
            logFastPrepare (struct.loadF Replica "fname" "rp") "ts" "pwrs" "ptgs";;
            tulip.REPLICA_OK)))).

Definition Replica__FastPrepare: val :=
  rec: "Replica__FastPrepare" "rp" "ts" "pwrs" "ptgs" :=
    Mutex__Lock (struct.loadF Replica "mu" "rp");;
    let: "res" := Replica__fastPrepare "rp" "ts" "pwrs" "ptgs" in
    Replica__refresh "rp" "ts" #0;;
    Mutex__Unlock (struct.loadF Replica "mu" "rp");;
    "res".

Definition Replica__lowestRank: val :=
  rec: "Replica__lowestRank" "rp" "ts" :=
    let: ("rank", "ok") := MapGet (struct.loadF Replica "rktbl" "rp") "ts" in
    ("rank", "ok").

(* Accept the prepare decision for @ts at @rank, if @rank is most recent.

   Arguments:
   @ts: Transaction timestamp.
   @rank: Coordinator rank.
   @dec: Prepared or unprepared.

   Return values:
   @error: Error code. *)
Definition Replica__tryAccept: val :=
  rec: "Replica__tryAccept" "rp" "ts" "rank" "dec" :=
    let: ("res", "final") := Replica__finalized "rp" "ts" in
    (if: "final"
    then "res"
    else
      let: ("rankl", "ok") := Replica__lowestRank "rp" "ts" in
      (if: "ok" && ("rank" < "rankl")
      then tulip.REPLICA_STALE_COORDINATOR
      else
        Replica__accept "rp" "ts" "rank" "dec";;
        logAccept (struct.loadF Replica "fname" "rp") "ts" "rank" "dec";;
        tulip.REPLICA_OK)).

Definition Replica__Prepare: val :=
  rec: "Replica__Prepare" "rp" "ts" "rank" :=
    Mutex__Lock (struct.loadF Replica "mu" "rp");;
    let: "res" := Replica__tryAccept "rp" "ts" "rank" #true in
    Replica__refresh "rp" "ts" "rank";;
    Mutex__Unlock (struct.loadF Replica "mu" "rp");;
    "res".

Definition Replica__Unprepare: val :=
  rec: "Replica__Unprepare" "rp" "ts" "rank" :=
    Mutex__Lock (struct.loadF Replica "mu" "rp");;
    let: "res" := Replica__tryAccept "rp" "ts" "rank" #false in
    Replica__refresh "rp" "ts" "rank";;
    Mutex__Unlock (struct.loadF Replica "mu" "rp");;
    "res".

Definition Replica__inquire: val :=
  rec: "Replica__inquire" "rp" "ts" "rank" :=
    let: ("cmted", "done") := MapGet (struct.loadF Replica "txntbl" "rp") "ts" in
    (if: "done"
    then
      (if: "cmted"
      then
        (struct.mk PrepareProposal [
         ], #false, slice.nil, tulip.REPLICA_COMMITTED_TXN)
      else
        (struct.mk PrepareProposal [
         ], #false, slice.nil, tulip.REPLICA_ABORTED_TXN))
    else
      let: ("rankl", "ok") := MapGet (struct.loadF Replica "rktbl" "rp") "ts" in
      (if: "ok" && ("rank" ≤ "rankl")
      then
        (struct.mk PrepareProposal [
         ], #false, slice.nil, tulip.REPLICA_INVALID_RANK)
      else
        let: "pp" := Fst (MapGet (struct.loadF Replica "pstbl" "rp") "ts") in
        MapInsert (struct.loadF Replica "rktbl" "rp") "ts" "rank";;
        let: ("pwrs", "vd") := MapGet (struct.loadF Replica "prepm" "rp") "ts" in
        ("pp", "vd", "pwrs", tulip.REPLICA_OK))).

Definition Replica__Inquire: val :=
  rec: "Replica__Inquire" "rp" "ts" "rank" :=
    Mutex__Lock (struct.loadF Replica "mu" "rp");;
    let: ((("pp", "vd"), "pwrs"), "res") := Replica__inquire "rp" "ts" "rank" in
    Replica__refresh "rp" "ts" "rank";;
    Mutex__Unlock (struct.loadF Replica "mu" "rp");;
    ("pp", "vd", "pwrs", "res").

Definition Replica__query: val :=
  rec: "Replica__query" "rp" "ts" "rank" :=
    let: ("res", "final") := Replica__finalized "rp" "ts" in
    (if: "final"
    then "res"
    else
      let: ("rankl", "ok") := Replica__lowestRank "rp" "ts" in
      (if: "ok" && ("rank" < "rankl")
      then tulip.REPLICA_STALE_COORDINATOR
      else tulip.REPLICA_OK)).

Definition Replica__Query: val :=
  rec: "Replica__Query" "rp" "ts" "rank" :=
    Mutex__Lock (struct.loadF Replica "mu" "rp");;
    let: "res" := Replica__query "rp" "ts" "rank" in
    Replica__refresh "rp" "ts" "rank";;
    Mutex__Unlock (struct.loadF Replica "mu" "rp");;
    "res".

Definition Replica__Refresh: val :=
  rec: "Replica__Refresh" "rp" "ts" "rank" :=
    Mutex__Lock (struct.loadF Replica "mu" "rp");;
    Replica__refresh "rp" "ts" "rank";;
    Mutex__Unlock (struct.loadF Replica "mu" "rp");;
    #().

Definition Replica__multiwrite: val :=
  rec: "Replica__multiwrite" "rp" "ts" "pwrs" :=
    ForSlice (struct.t tulip.WriteEntry) <> "ent" "pwrs"
      (let: "key" := struct.get tulip.WriteEntry "Key" "ent" in
      let: "value" := struct.get tulip.WriteEntry "Value" "ent" in
      let: "tpl" := index.Index__GetTuple (struct.loadF Replica "idx" "rp") "key" in
      (if: struct.get tulip.Value "Present" "value"
      then tuple.Tuple__AppendVersion "tpl" "ts" (struct.get tulip.Value "Content" "value")
      else tuple.Tuple__KillVersion "tpl" "ts"));;
    #().

Definition Replica__releaseKey: val :=
  rec: "Replica__releaseKey" "rp" "key" :=
    MapDelete (struct.loadF Replica "ptsm" "rp") "key";;
    #().

Definition Replica__release: val :=
  rec: "Replica__release" "rp" "pwrs" :=
    ForSlice (struct.t tulip.WriteEntry) <> "ent" "pwrs"
      (let: "key" := struct.get tulip.WriteEntry "Key" "ent" in
      Replica__releaseKey "rp" "key");;
    #().

Definition Replica__applyCommit: val :=
  rec: "Replica__applyCommit" "rp" "ts" "pwrs" :=
    let: "committed" := Replica__terminated "rp" "ts" in
    (if: "committed"
    then #()
    else
      Replica__multiwrite "rp" "ts" "pwrs";;
      MapInsert (struct.loadF Replica "txntbl" "rp") "ts" #true;;
      let: (<>, "prepared") := MapGet (struct.loadF Replica "prepm" "rp") "ts" in
      (if: "prepared"
      then
        Replica__release "rp" "pwrs";;
        MapDelete (struct.loadF Replica "prepm" "rp") "ts";;
        #()
      else #())).

Definition Replica__applyAbort: val :=
  rec: "Replica__applyAbort" "rp" "ts" :=
    let: "aborted" := Replica__terminated "rp" "ts" in
    (if: "aborted"
    then #()
    else
      MapInsert (struct.loadF Replica "txntbl" "rp") "ts" #false;;
      let: ("pwrs", "prepared") := MapGet (struct.loadF Replica "prepm" "rp") "ts" in
      (if: "prepared"
      then
        Replica__release "rp" "pwrs";;
        MapDelete (struct.loadF Replica "prepm" "rp") "ts";;
        #()
      else #())).

Definition Replica__apply: val :=
  rec: "Replica__apply" "rp" "cmd" :=
    (if: (struct.get txnlog.Cmd "Kind" "cmd") = txnlog.TXNLOG_COMMIT
    then
      Replica__applyCommit "rp" (struct.get txnlog.Cmd "Timestamp" "cmd") (struct.get txnlog.Cmd "PartialWrites" "cmd");;
      #()
    else
      (if: (struct.get txnlog.Cmd "Kind" "cmd") = txnlog.TXNLOG_ABORT
      then
        Replica__applyAbort "rp" (struct.get txnlog.Cmd "Timestamp" "cmd");;
        #()
      else #())).

Definition Replica__Applier: val :=
  rec: "Replica__Applier" "rp" :=
    Mutex__Lock (struct.loadF Replica "mu" "rp");;
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: ("cmd", "ok") := txnlog.TxnLog__Lookup (struct.loadF Replica "txnlog" "rp") (struct.loadF Replica "lsna" "rp") in
      (if: (~ "ok")
      then
        Mutex__Unlock (struct.loadF Replica "mu" "rp");;
        time.Sleep (#1 * #1000000);;
        Mutex__Lock (struct.loadF Replica "mu" "rp");;
        Continue
      else
        Replica__apply "rp" "cmd";;
        struct.storeF Replica "lsna" "rp" (std.SumAssumeNoOverflow (struct.loadF Replica "lsna" "rp") #1);;
        Continue));;
    #().

Definition Replica__StartBackupTxnCoordinator: val :=
  rec: "Replica__StartBackupTxnCoordinator" "rp" "ts" :=
    Mutex__Lock (struct.loadF Replica "mu" "rp");;
    let: "rank" := (Fst (MapGet (struct.loadF Replica "rktbl" "rp") "ts")) + #1 in
    let: "ptgs" := Fst (MapGet (struct.loadF Replica "ptgsm" "rp") "ts") in
    let: "tcoord" := backup.MkBackupTxnCoordinator "ts" "rank" "ptgs" (struct.loadF Replica "rps" "rp") (struct.loadF Replica "leader" "rp") in
    backup.BackupTxnCoordinator__ConnectAll "tcoord";;
    Mutex__Unlock (struct.loadF Replica "mu" "rp");;
    backup.BackupTxnCoordinator__Finalize "tcoord";;
    #().

(* For debugging and evaluation purpose. *)
Definition Replica__DumpState: val :=
  rec: "Replica__DumpState" "rp" "gid" :=
    Mutex__Lock (struct.loadF Replica "mu" "rp");;
    (* fmt.Printf("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n") *)
    (* fmt.Printf("[G %d / R %d] Dumping replica state:\n", gid, rp.rid) *)
    (* fmt.Printf("-------------------------------------------------------------\n") *)
    (* fmt.Printf("Number of finalized txns: %d\n", uint64(len(rp.txntbl))) *)
    (* fmt.Printf("Number of prepared txns: %d\n", uint64(len(rp.prepm))) *)
    (* fmt.Printf("Number of acquired keys: %d\n", uint64(len(rp.ptsm))) *)
    (* fmt.Printf("Applied LSN: %d\n\n", rp.lsna) *)
    (* fmt.Printf("[G %d / R %d] Dumping paxos state:\n", gid, rp.rid) *)
    (* fmt.Printf("-------------------------------------------------------------\n") *)
    txnlog.TxnLog__DumpState (struct.loadF Replica "txnlog" "rp");;
    (* fmt.Printf("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n") *)
    Mutex__Unlock (struct.loadF Replica "mu" "rp");;
    #().

Definition Replica__ForceElection: val :=
  rec: "Replica__ForceElection" "rp" :=
    txnlog.TxnLog__ForceElection (struct.loadF Replica "txnlog" "rp");;
    #().

Definition Replica__RequestSession: val :=
  rec: "Replica__RequestSession" "rp" "conn" :=
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "ret" := grove_ffi.Receive "conn" in
      (if: struct.get grove_ffi.ReceiveRet "Err" "ret"
      then Break
      else
        let: "req" := message.DecodeTxnRequest (struct.get grove_ffi.ReceiveRet "Data" "ret") in
        let: "kind" := struct.get message.TxnRequest "Kind" "req" in
        let: "ts" := struct.get message.TxnRequest "Timestamp" "req" in
        (if: "kind" = message.MSG_TXN_READ
        then
          let: "key" := struct.get message.TxnRequest "Key" "req" in
          let: (("ver", "slow"), "ok") := Replica__Read "rp" "ts" "key" in
          (if: (~ "ok")
          then Continue
          else
            let: "data" := message.EncodeTxnReadResponse "ts" (struct.loadF Replica "rid" "rp") "key" "ver" "slow" in
            grove_ffi.Send "conn" "data";;
            Continue)
        else
          (if: "kind" = message.MSG_TXN_FAST_PREPARE
          then
            let: "pwrs" := struct.get message.TxnRequest "PartialWrites" "req" in
            let: "res" := Replica__FastPrepare "rp" "ts" "pwrs" slice.nil in
            let: "data" := message.EncodeTxnFastPrepareResponse "ts" (struct.loadF Replica "rid" "rp") "res" in
            grove_ffi.Send "conn" "data";;
            Continue
          else
            (if: "kind" = message.MSG_TXN_VALIDATE
            then
              let: "pwrs" := struct.get message.TxnRequest "PartialWrites" "req" in
              let: "rank" := struct.get message.TxnRequest "Rank" "req" in
              let: "res" := Replica__Validate "rp" "ts" "rank" "pwrs" slice.nil in
              let: "data" := message.EncodeTxnValidateResponse "ts" (struct.loadF Replica "rid" "rp") "res" in
              grove_ffi.Send "conn" "data";;
              Continue
            else
              (if: "kind" = message.MSG_TXN_PREPARE
              then
                let: "rank" := struct.get message.TxnRequest "Rank" "req" in
                let: "res" := Replica__Prepare "rp" "ts" "rank" in
                let: "data" := message.EncodeTxnPrepareResponse "ts" "rank" (struct.loadF Replica "rid" "rp") "res" in
                grove_ffi.Send "conn" "data";;
                Continue
              else
                (if: "kind" = message.MSG_TXN_UNPREPARE
                then
                  let: "rank" := struct.get message.TxnRequest "Rank" "req" in
                  let: "res" := Replica__Unprepare "rp" "ts" "rank" in
                  let: "data" := message.EncodeTxnUnprepareResponse "ts" "rank" (struct.loadF Replica "rid" "rp") "res" in
                  grove_ffi.Send "conn" "data";;
                  Continue
                else
                  (if: "kind" = message.MSG_TXN_QUERY
                  then
                    let: "rank" := struct.get message.TxnRequest "Rank" "req" in
                    let: "res" := Replica__Query "rp" "ts" "rank" in
                    let: "data" := message.EncodeTxnQueryResponse "ts" "res" in
                    grove_ffi.Send "conn" "data";;
                    Continue
                  else
                    (if: "kind" = message.MSG_TXN_COMMIT
                    then
                      let: "pwrs" := struct.get message.TxnRequest "PartialWrites" "req" in
                      let: "ok" := Replica__Commit "rp" "ts" "pwrs" in
                      (if: "ok"
                      then
                        let: "data" := message.EncodeTxnCommitResponse "ts" tulip.REPLICA_COMMITTED_TXN in
                        grove_ffi.Send "conn" "data";;
                        Continue
                      else
                        let: "data" := message.EncodeTxnCommitResponse "ts" tulip.REPLICA_WRONG_LEADER in
                        grove_ffi.Send "conn" "data";;
                        Continue)
                    else
                      (if: "kind" = message.MSG_TXN_ABORT
                      then
                        let: "ok" := Replica__Abort "rp" "ts" in
                        (if: "ok"
                        then
                          let: "data" := message.EncodeTxnAbortResponse "ts" tulip.REPLICA_ABORTED_TXN in
                          grove_ffi.Send "conn" "data";;
                          Continue
                        else
                          let: "data" := message.EncodeTxnAbortResponse "ts" tulip.REPLICA_WRONG_LEADER in
                          grove_ffi.Send "conn" "data";;
                          Continue)
                      else
                        (if: "kind" = message.MSG_DUMP_STATE
                        then
                          let: "gid" := struct.get message.TxnRequest "Timestamp" "req" in
                          Replica__DumpState "rp" "gid";;
                          Continue
                        else
                          (if: "kind" = message.MSG_FORCE_ELECTION
                          then
                            Replica__ForceElection "rp";;
                            Continue
                          else Continue))))))))))));;
    #().

Definition Replica__Serve: val :=
  rec: "Replica__Serve" "rp" :=
    let: "ls" := grove_ffi.Listen (struct.loadF Replica "addr" "rp") in
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "conn" := grove_ffi.Accept "ls" in
      Fork (Replica__RequestSession "rp" "conn");;
      Continue);;
    #().

Definition Start: val :=
  rec: "Start" "rid" "addr" "fname" "addrmpx" "fnamepx" :=
    let: "txnlog" := txnlog.Start "rid" "addrmpx" "fnamepx" in
    let: "rp" := struct.new Replica [
      "mu" ::= newMutex #();
      "rid" ::= "rid";
      "addr" ::= "addr";
      "fname" ::= "fname";
      "txnlog" ::= "txnlog";
      "lsna" ::= #0;
      "prepm" ::= NewMap uint64T (slice.T (struct.t tulip.WriteEntry)) #();
      "ptgsm" ::= NewMap uint64T (slice.T uint64T) #();
      "pstbl" ::= NewMap uint64T (struct.t PrepareProposal) #();
      "rktbl" ::= NewMap uint64T uint64T #();
      "txntbl" ::= NewMap uint64T boolT #();
      "ptsm" ::= NewMap stringT uint64T #();
      "sptsm" ::= NewMap stringT uint64T #();
      "idx" ::= index.MkIndex #()
    ] in
    Fork (Replica__Serve "rp");;
    Fork (Replica__Applier "rp");;
    "rp".
