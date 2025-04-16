(* autogenerated from github.com/mit-pdos/tulip/backup *)
From Perennial.goose_lang Require Import prelude.
From Goose Require github_com.goose_lang.std.
From Goose Require github_com.mit_pdos.tulip.message.
From Goose Require github_com.mit_pdos.tulip.params.
From Goose Require github_com.mit_pdos.tulip.quorum.
From Goose Require github_com.mit_pdos.tulip.tulip.
From Perennial.goose_lang.trusted Require Import github_com.mit_pdos.tulip.trusted_proph.

From Perennial.goose_lang Require Import ffi.grove_prelude.

(* A note on relationship between @phase and @pwrsok/@pwrs: Ideally, we should
   construct an invariant saying that if @phase is VALIDATING, PREPARING, or
   PREPARED, then @pwrsok = true (and @pwrs is available). But before figuring
   out the right invariant, we added some redundant checks (i.e., ones that
   should never fail) to make the proof happy (see calls of @gcoord.GetPwrs). *)
Definition BackupGroupPreparer := struct.decl [
  "nrps" :: uint64T;
  "phase" :: uint64T;
  "pwrsok" :: boolT;
  "pwrs" :: mapT (struct.t tulip.Value);
  "pps" :: mapT (struct.t tulip.PrepareProposal);
  "vdm" :: mapT boolT;
  "srespm" :: mapT boolT
].

Definition BGPP_INQUIRING : expr := #0.

Definition BGPP_VALIDATING : expr := #1.

Definition BGPP_PREPARING : expr := #2.

Definition BGPP_UNPREPARING : expr := #3.

Definition BGPP_PREPARED : expr := #4.

Definition BGPP_COMMITTED : expr := #5.

Definition BGPP_ABORTED : expr := #6.

Definition BGPP_STOPPED : expr := #7.

Definition mkBackupGroupPreparer: val :=
  rec: "mkBackupGroupPreparer" "nrps" :=
    let: "gpp" := struct.new BackupGroupPreparer [
      "nrps" ::= "nrps";
      "phase" ::= BGPP_INQUIRING;
      "pwrsok" ::= #false;
      "pps" ::= NewMap uint64T (struct.t tulip.PrepareProposal) #();
      "vdm" ::= NewMap uint64T boolT #();
      "srespm" ::= NewMap uint64T boolT #()
    ] in
    "gpp".

Definition BGPP_INQUIRE : expr := #0.

Definition BGPP_VALIDATE : expr := #1.

Definition BGPP_PREPARE : expr := #2.

Definition BGPP_UNPREPARE : expr := #3.

Definition BGPP_REFRESH : expr := #4.

Definition BackupGroupPreparer__inquired: val :=
  rec: "BackupGroupPreparer__inquired" "gpp" "rid" :=
    let: (<>, "inquired") := MapGet (struct.loadF BackupGroupPreparer "pps" "gpp") "rid" in
    "inquired".

Definition BackupGroupPreparer__validated: val :=
  rec: "BackupGroupPreparer__validated" "gpp" "rid" :=
    let: (<>, "validated") := MapGet (struct.loadF BackupGroupPreparer "vdm" "gpp") "rid" in
    "validated".

Definition BackupGroupPreparer__accepted: val :=
  rec: "BackupGroupPreparer__accepted" "gpp" "rid" :=
    let: (<>, "accepted") := MapGet (struct.loadF BackupGroupPreparer "srespm" "gpp") "rid" in
    "accepted".

Definition BackupGroupPreparer__getPhase: val :=
  rec: "BackupGroupPreparer__getPhase" "gpp" :=
    struct.loadF BackupGroupPreparer "phase" "gpp".

(* Argument:
   @rid: ID of the replica to which a new action is performed.

   Return value:
   @action: Next action to perform. *)
Definition BackupGroupPreparer__action: val :=
  rec: "BackupGroupPreparer__action" "gpp" "rid" :=
    let: "phase" := BackupGroupPreparer__getPhase "gpp" in
    (if: "phase" = BGPP_INQUIRING
    then
      let: "inquired" := BackupGroupPreparer__inquired "gpp" "rid" in
      (if: (~ "inquired")
      then BGPP_INQUIRE
      else BGPP_REFRESH)
    else
      (if: "phase" = BGPP_VALIDATING
      then
        let: "inquired" := BackupGroupPreparer__inquired "gpp" "rid" in
        (if: (~ "inquired")
        then BGPP_INQUIRE
        else
          let: "validated" := BackupGroupPreparer__validated "gpp" "rid" in
          (if: (~ "validated")
          then BGPP_VALIDATE
          else BGPP_REFRESH))
      else
        (if: "phase" = BGPP_PREPARING
        then
          let: "prepared" := BackupGroupPreparer__accepted "gpp" "rid" in
          (if: (~ "prepared")
          then BGPP_PREPARE
          else BGPP_REFRESH)
        else
          (if: "phase" = BGPP_UNPREPARING
          then
            let: "unprepared" := BackupGroupPreparer__accepted "gpp" "rid" in
            (if: (~ "unprepared")
            then BGPP_UNPREPARE
            else BGPP_REFRESH)
          else BGPP_REFRESH)))).

Definition BackupGroupPreparer__fquorum: val :=
  rec: "BackupGroupPreparer__fquorum" "gpp" "n" :=
    (quorum.FastQuorum (struct.loadF BackupGroupPreparer "nrps" "gpp")) ≤ "n".

Definition BackupGroupPreparer__cquorum: val :=
  rec: "BackupGroupPreparer__cquorum" "gpp" "n" :=
    (quorum.ClassicQuorum (struct.loadF BackupGroupPreparer "nrps" "gpp")) ≤ "n".

Definition BackupGroupPreparer__hcquorum: val :=
  rec: "BackupGroupPreparer__hcquorum" "gpp" "n" :=
    (quorum.Half (quorum.ClassicQuorum (struct.loadF BackupGroupPreparer "nrps" "gpp"))) ≤ "n".

Definition BackupGroupPreparer__ready: val :=
  rec: "BackupGroupPreparer__ready" "gpp" :=
    BGPP_PREPARED ≤ (struct.loadF BackupGroupPreparer "phase" "gpp").

Definition BackupGroupPreparer__tryResign: val :=
  rec: "BackupGroupPreparer__tryResign" "gpp" "res" :=
    (if: BackupGroupPreparer__ready "gpp"
    then #true
    else
      (if: "res" = tulip.REPLICA_COMMITTED_TXN
      then
        struct.storeF BackupGroupPreparer "phase" "gpp" BGPP_COMMITTED;;
        #true
      else
        (if: "res" = tulip.REPLICA_ABORTED_TXN
        then
          struct.storeF BackupGroupPreparer "phase" "gpp" BGPP_ABORTED;;
          #true
        else
          (if: "res" = tulip.REPLICA_STALE_COORDINATOR
          then
            struct.storeF BackupGroupPreparer "phase" "gpp" BGPP_STOPPED;;
            #true
          else #false)))).

Definition BackupGroupPreparer__accept: val :=
  rec: "BackupGroupPreparer__accept" "gpp" "rid" :=
    MapInsert (struct.loadF BackupGroupPreparer "srespm" "gpp") "rid" #true;;
    #().

Definition BackupGroupPreparer__quorumAccepted: val :=
  rec: "BackupGroupPreparer__quorumAccepted" "gpp" :=
    let: "n" := MapLen (struct.loadF BackupGroupPreparer "srespm" "gpp") in
    BackupGroupPreparer__cquorum "gpp" "n".

Definition BackupGroupPreparer__in: val :=
  rec: "BackupGroupPreparer__in" "gpp" "phase" :=
    (struct.loadF BackupGroupPreparer "phase" "gpp") = "phase".

Definition BackupGroupPreparer__quorumValidated: val :=
  rec: "BackupGroupPreparer__quorumValidated" "gpp" :=
    let: "n" := MapLen (struct.loadF BackupGroupPreparer "vdm" "gpp") in
    BackupGroupPreparer__cquorum "gpp" "n".

Definition BackupGroupPreparer__processPrepareResult: val :=
  rec: "BackupGroupPreparer__processPrepareResult" "gpp" "rid" "res" :=
    (if: BackupGroupPreparer__tryResign "gpp" "res"
    then #()
    else
      (if: (~ (BackupGroupPreparer__in "gpp" BGPP_PREPARING))
      then #()
      else
        BackupGroupPreparer__accept "gpp" "rid";;
        (if: (~ (BackupGroupPreparer__quorumValidated "gpp"))
        then #()
        else
          (if: BackupGroupPreparer__quorumAccepted "gpp"
          then
            struct.storeF BackupGroupPreparer "phase" "gpp" BGPP_PREPARED;;
            #()
          else #())))).

Definition BackupGroupPreparer__processUnprepareResult: val :=
  rec: "BackupGroupPreparer__processUnprepareResult" "gpp" "rid" "res" :=
    (if: BackupGroupPreparer__tryResign "gpp" "res"
    then #()
    else
      (if: (~ (BackupGroupPreparer__in "gpp" BGPP_UNPREPARING))
      then #()
      else
        BackupGroupPreparer__accept "gpp" "rid";;
        (if: BackupGroupPreparer__quorumAccepted "gpp"
        then
          struct.storeF BackupGroupPreparer "phase" "gpp" BGPP_ABORTED;;
          #()
        else #()))).

(* Return value:
   @latest: The latest non-fast proposal if @latest.rank > 0; @gpp.pps
   contain only fast proposals if @latest.rank == 0. *)
Definition BackupGroupPreparer__latestProposal: val :=
  rec: "BackupGroupPreparer__latestProposal" "gpp" :=
    let: "latest" := ref (zero_val (struct.t tulip.PrepareProposal)) in
    MapIter (struct.loadF BackupGroupPreparer "pps" "gpp") (λ: <> "pp",
      (if: (struct.get tulip.PrepareProposal "Rank" (![struct.t tulip.PrepareProposal] "latest")) ≤ (struct.get tulip.PrepareProposal "Rank" "pp")
      then "latest" <-[struct.t tulip.PrepareProposal] "pp"
      else #()));;
    ![struct.t tulip.PrepareProposal] "latest".

(* Return value:
   @nprep: The number of fast unprepares collected in @gpp.pps.

   Note that this function requires all proposals in @gpp.pps to be proposed in
   the fast rank in order to match its semantics. *)
Definition BackupGroupPreparer__countFastProposals: val :=
  rec: "BackupGroupPreparer__countFastProposals" "gpp" "b" :=
    let: "nprep" := ref (zero_val uint64T) in
    MapIter (struct.loadF BackupGroupPreparer "pps" "gpp") (λ: <> "pp",
      (if: "b" = (struct.get tulip.PrepareProposal "Prepared" "pp")
      then "nprep" <-[uint64T] (std.SumAssumeNoOverflow (![uint64T] "nprep") #1)
      else #()));;
    ![uint64T] "nprep".

Definition BackupGroupPreparer__collectProposal: val :=
  rec: "BackupGroupPreparer__collectProposal" "gpp" "rid" "pp" :=
    MapInsert (struct.loadF BackupGroupPreparer "pps" "gpp") "rid" "pp";;
    #().

Definition BackupGroupPreparer__countProposals: val :=
  rec: "BackupGroupPreparer__countProposals" "gpp" :=
    MapLen (struct.loadF BackupGroupPreparer "pps" "gpp").

Definition BackupGroupPreparer__setPwrs: val :=
  rec: "BackupGroupPreparer__setPwrs" "gpp" "pwrs" :=
    struct.storeF BackupGroupPreparer "pwrsok" "gpp" #true;;
    struct.storeF BackupGroupPreparer "pwrs" "gpp" "pwrs";;
    #().

Definition BackupGroupPreparer__validate: val :=
  rec: "BackupGroupPreparer__validate" "gpp" "rid" :=
    MapInsert (struct.loadF BackupGroupPreparer "vdm" "gpp") "rid" #true;;
    #().

Definition BackupGroupPreparer__tryValidate: val :=
  rec: "BackupGroupPreparer__tryValidate" "gpp" "rid" "vd" "pwrs" :=
    (if: "vd"
    then
      BackupGroupPreparer__setPwrs "gpp" "pwrs";;
      BackupGroupPreparer__validate "gpp" "rid";;
      #()
    else #()).

Definition BackupGroupPreparer__becomePreparing: val :=
  rec: "BackupGroupPreparer__becomePreparing" "gpp" :=
    struct.storeF BackupGroupPreparer "srespm" "gpp" (NewMap uint64T boolT #());;
    struct.storeF BackupGroupPreparer "phase" "gpp" BGPP_PREPARING;;
    #().

Definition BackupGroupPreparer__becomeUnpreparing: val :=
  rec: "BackupGroupPreparer__becomeUnpreparing" "gpp" :=
    struct.storeF BackupGroupPreparer "srespm" "gpp" (NewMap uint64T boolT #());;
    struct.storeF BackupGroupPreparer "phase" "gpp" BGPP_UNPREPARING;;
    #().

Definition BackupGroupPreparer__getPwrs: val :=
  rec: "BackupGroupPreparer__getPwrs" "gpp" :=
    (struct.loadF BackupGroupPreparer "pwrs" "gpp", struct.loadF BackupGroupPreparer "pwrsok" "gpp").

Definition BackupGroupPreparer__processInquireResult: val :=
  rec: "BackupGroupPreparer__processInquireResult" "gpp" "rid" "pp" "vd" "pwrs" "res" :=
    (if: BackupGroupPreparer__tryResign "gpp" "res"
    then #()
    else
      (if: (BackupGroupPreparer__in "gpp" BGPP_PREPARING) || (BackupGroupPreparer__in "gpp" BGPP_UNPREPARING)
      then #()
      else
        BackupGroupPreparer__collectProposal "gpp" "rid" "pp";;
        BackupGroupPreparer__tryValidate "gpp" "rid" "vd" "pwrs";;
        let: "n" := BackupGroupPreparer__countProposals "gpp" in
        (if: (~ (BackupGroupPreparer__cquorum "gpp" "n"))
        then #()
        else
          let: "latest" := BackupGroupPreparer__latestProposal "gpp" in
          (if: (struct.get tulip.PrepareProposal "Rank" "latest") ≠ #0
          then
            (if: (~ (struct.get tulip.PrepareProposal "Prepared" "latest"))
            then
              BackupGroupPreparer__becomeUnpreparing "gpp";;
              #()
            else
              let: (<>, "ok") := BackupGroupPreparer__getPwrs "gpp" in
              (if: (~ "ok")
              then #()
              else
                BackupGroupPreparer__becomePreparing "gpp";;
                #()))
          else
            let: "nfu" := BackupGroupPreparer__countFastProposals "gpp" #false in
            (if: BackupGroupPreparer__hcquorum "gpp" "nfu"
            then
              BackupGroupPreparer__becomeUnpreparing "gpp";;
              #()
            else
              let: "nfp" := BackupGroupPreparer__countFastProposals "gpp" #true in
              (if: (~ (BackupGroupPreparer__hcquorum "gpp" "nfp"))
              then #()
              else
                (if: BackupGroupPreparer__quorumValidated "gpp"
                then
                  BackupGroupPreparer__becomePreparing "gpp";;
                  #()
                else
                  struct.storeF BackupGroupPreparer "phase" "gpp" BGPP_VALIDATING;;
                  #()))))))).

Definition BackupGroupPreparer__processValidateResult: val :=
  rec: "BackupGroupPreparer__processValidateResult" "gpp" "rid" "res" :=
    (if: BackupGroupPreparer__tryResign "gpp" "res"
    then #()
    else
      (if: (~ (BackupGroupPreparer__in "gpp" BGPP_VALIDATING))
      then #()
      else
        (if: "res" = tulip.REPLICA_FAILED_VALIDATION
        then #()
        else
          BackupGroupPreparer__validate "gpp" "rid";;
          (if: BackupGroupPreparer__quorumValidated "gpp"
          then
            BackupGroupPreparer__becomePreparing "gpp";;
            #()
          else #())))).

Definition BackupGroupPreparer__processQueryResult: val :=
  rec: "BackupGroupPreparer__processQueryResult" "gpp" "rid" "res" :=
    BackupGroupPreparer__tryResign "gpp" "res";;
    #().

Definition BackupGroupPreparer__stop: val :=
  rec: "BackupGroupPreparer__stop" "gpp" :=
    struct.storeF BackupGroupPreparer "phase" "gpp" BGPP_STOPPED;;
    #().

Definition BackupGroupPreparer__processFinalizationResult: val :=
  rec: "BackupGroupPreparer__processFinalizationResult" "gpp" "res" :=
    (if: "res" = tulip.REPLICA_WRONG_LEADER
    then #()
    else
      BackupGroupPreparer__stop "gpp";;
      #()).

Definition BackupGroupPreparer__finalized: val :=
  rec: "BackupGroupPreparer__finalized" "gpp" :=
    BGPP_COMMITTED ≤ (struct.loadF BackupGroupPreparer "phase" "gpp").

Definition BackupGroupCoordinator := struct.decl [
  "cid" :: struct.t tulip.CoordID;
  "ts" :: uint64T;
  "rank" :: uint64T;
  "rps" :: slice.T uint64T;
  "addrm" :: mapT uint64T;
  "mu" :: ptrT;
  "cv" :: ptrT;
  "idxleader" :: uint64T;
  "gpp" :: ptrT;
  "conns" :: mapT grove_ffi.Connection
].

Definition mkBackupGroupCoordinator: val :=
  rec: "mkBackupGroupCoordinator" "addrm" "cid" "ts" "rank" :=
    let: "mu" := newMutex #() in
    let: "cv" := NewCond "mu" in
    let: "nrps" := MapLen "addrm" in
    let: "rps" := ref_to (slice.T uint64T) (NewSlice uint64T #0) in
    MapIter "addrm" (λ: "rid" <>,
      "rps" <-[slice.T uint64T] (SliceAppend uint64T (![slice.T uint64T] "rps") "rid"));;
    let: "gcoord" := struct.new BackupGroupCoordinator [
      "cid" ::= "cid";
      "ts" ::= "ts";
      "rank" ::= "rank";
      "rps" ::= ![slice.T uint64T] "rps";
      "addrm" ::= "addrm";
      "mu" ::= "mu";
      "cv" ::= "cv";
      "idxleader" ::= #0;
      "gpp" ::= mkBackupGroupPreparer "nrps";
      "conns" ::= NewMap uint64T grove_ffi.Connection #()
    ] in
    "gcoord".

Definition BackupGroupCoordinator__GetConnection: val :=
  rec: "BackupGroupCoordinator__GetConnection" "gcoord" "rid" :=
    Mutex__Lock (struct.loadF BackupGroupCoordinator "mu" "gcoord");;
    let: ("conn", "ok") := MapGet (struct.loadF BackupGroupCoordinator "conns" "gcoord") "rid" in
    Mutex__Unlock (struct.loadF BackupGroupCoordinator "mu" "gcoord");;
    ("conn", "ok").

Definition BackupGroupCoordinator__Connect: val :=
  rec: "BackupGroupCoordinator__Connect" "gcoord" "rid" :=
    let: "addr" := SliceGet uint64T (struct.loadF BackupGroupCoordinator "rps" "gcoord") "rid" in
    let: "ret" := grove_ffi.Connect "addr" in
    (if: (~ (struct.get grove_ffi.ConnectRet "Err" "ret"))
    then
      Mutex__Lock (struct.loadF BackupGroupCoordinator "mu" "gcoord");;
      MapInsert (struct.loadF BackupGroupCoordinator "conns" "gcoord") "rid" (struct.get grove_ffi.ConnectRet "Connection" "ret");;
      Mutex__Unlock (struct.loadF BackupGroupCoordinator "mu" "gcoord");;
      #true
    else #false).

Definition BackupGroupCoordinator__Receive: val :=
  rec: "BackupGroupCoordinator__Receive" "gcoord" "rid" :=
    let: ("conn", "ok") := BackupGroupCoordinator__GetConnection "gcoord" "rid" in
    (if: (~ "ok")
    then
      BackupGroupCoordinator__Connect "gcoord" "rid";;
      (slice.nil, #false)
    else
      let: "ret" := grove_ffi.Receive "conn" in
      (if: struct.get grove_ffi.ReceiveRet "Err" "ret"
      then
        BackupGroupCoordinator__Connect "gcoord" "rid";;
        (slice.nil, #false)
      else (struct.get grove_ffi.ReceiveRet "Data" "ret", #true))).

Definition BackupGroupCoordinator__ResponseSession: val :=
  rec: "BackupGroupCoordinator__ResponseSession" "gcoord" "rid" :=
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: ("data", "ok") := BackupGroupCoordinator__Receive "gcoord" "rid" in
      (if: (~ "ok")
      then
        time.Sleep params.NS_RECONNECT;;
        Continue
      else
        let: "msg" := message.DecodeTxnResponse "data" in
        let: "kind" := struct.get message.TxnResponse "Kind" "msg" in
        (if: (struct.loadF BackupGroupCoordinator "ts" "gcoord") ≠ (struct.get message.TxnResponse "Timestamp" "msg")
        then Continue
        else
          Mutex__Lock (struct.loadF BackupGroupCoordinator "mu" "gcoord");;
          let: "gpp" := struct.loadF BackupGroupCoordinator "gpp" "gcoord" in
          (if: "kind" = message.MSG_TXN_INQUIRE
          then
            (if: (((struct.get tulip.CoordID "GroupID" (struct.loadF BackupGroupCoordinator "cid" "gcoord")) = (struct.get tulip.CoordID "GroupID" (struct.get message.TxnResponse "CoordID" "msg"))) && ((struct.get tulip.CoordID "ReplicaID" (struct.loadF BackupGroupCoordinator "cid" "gcoord")) = (struct.get tulip.CoordID "ReplicaID" (struct.get message.TxnResponse "CoordID" "msg")))) && ((struct.loadF BackupGroupCoordinator "rank" "gcoord") = (struct.get message.TxnResponse "Rank" "msg"))
            then
              let: "pp" := struct.mk tulip.PrepareProposal [
                "Rank" ::= struct.get message.TxnResponse "RankLast" "msg";
                "Prepared" ::= struct.get message.TxnResponse "Prepared" "msg"
              ] in
              BackupGroupPreparer__processInquireResult "gpp" (struct.get message.TxnResponse "ReplicaID" "msg") "pp" (struct.get message.TxnResponse "Validated" "msg") (struct.get message.TxnResponse "PartialWrites" "msg") (struct.get message.TxnResponse "Result" "msg")
            else #())
          else
            (if: "kind" = message.MSG_TXN_VALIDATE
            then BackupGroupPreparer__processValidateResult "gpp" (struct.get message.TxnResponse "ReplicaID" "msg") (struct.get message.TxnResponse "Result" "msg")
            else
              (if: "kind" = message.MSG_TXN_PREPARE
              then
                (if: (struct.loadF BackupGroupCoordinator "rank" "gcoord") = (struct.get message.TxnResponse "Rank" "msg")
                then BackupGroupPreparer__processPrepareResult "gpp" (struct.get message.TxnResponse "ReplicaID" "msg") (struct.get message.TxnResponse "Result" "msg")
                else #())
              else
                (if: "kind" = message.MSG_TXN_UNPREPARE
                then
                  (if: (struct.loadF BackupGroupCoordinator "rank" "gcoord") = (struct.get message.TxnResponse "Rank" "msg")
                  then BackupGroupPreparer__processUnprepareResult "gpp" (struct.get message.TxnResponse "ReplicaID" "msg") (struct.get message.TxnResponse "Result" "msg")
                  else #())
                else
                  (if: "kind" = message.MSG_TXN_REFRESH
                  then #()
                  else
                    (if: ("kind" = message.MSG_TXN_COMMIT) || ("kind" = message.MSG_TXN_ABORT)
                    then BackupGroupPreparer__processFinalizationResult "gpp" (struct.get message.TxnResponse "Result" "msg")
                    else #()))))));;
          Cond__Signal (struct.loadF BackupGroupCoordinator "cv" "gcoord");;
          Mutex__Unlock (struct.loadF BackupGroupCoordinator "mu" "gcoord");;
          Continue)));;
    #().

(* TODO: We probably don't need to remember @ts since it can be passsed directly
   to @gcoord.ResponseSession and @gcoord.Prepare. We just need to maintain
   logically the connection between those parameters and the gcoord
   representation predicate. Remembering @cid and @rank makes sense since they
   belong to the group coordinator, rather than the transaction
   coordinator. This means we can remove @rank from @gcoord.Prepare and @gcoord.PrepareSession. *)
Definition startBackupGroupCoordinator: val :=
  rec: "startBackupGroupCoordinator" "addrm" "cid" "ts" "rank" :=
    let: "gcoord" := mkBackupGroupCoordinator "addrm" "cid" "ts" "rank" in
    MapIter "addrm" (λ: "ridloop" <>,
      let: "rid" := "ridloop" in
      Fork (BackupGroupCoordinator__ResponseSession "gcoord" "rid"));;
    "gcoord".

Definition BackupGroupCoordinator__Finalized: val :=
  rec: "BackupGroupCoordinator__Finalized" "gcoord" :=
    Mutex__Lock (struct.loadF BackupGroupCoordinator "mu" "gcoord");;
    let: "done" := BackupGroupPreparer__finalized (struct.loadF BackupGroupCoordinator "gpp" "gcoord") in
    Mutex__Unlock (struct.loadF BackupGroupCoordinator "mu" "gcoord");;
    "done".

Definition BackupGroupCoordinator__NextPrepareAction: val :=
  rec: "BackupGroupCoordinator__NextPrepareAction" "gcoord" "rid" :=
    Mutex__Lock (struct.loadF BackupGroupCoordinator "mu" "gcoord");;
    let: "a" := BackupGroupPreparer__action (struct.loadF BackupGroupCoordinator "gpp" "gcoord") "rid" in
    Mutex__Unlock (struct.loadF BackupGroupCoordinator "mu" "gcoord");;
    "a".

Definition BackupGroupCoordinator__Send: val :=
  rec: "BackupGroupCoordinator__Send" "gcoord" "rid" "data" :=
    let: ("conn", "ok") := BackupGroupCoordinator__GetConnection "gcoord" "rid" in
    (if: (~ "ok")
    then
      BackupGroupCoordinator__Connect "gcoord" "rid";;
      #()
    else
      let: "err" := grove_ffi.Send "conn" "data" in
      (if: "err"
      then
        BackupGroupCoordinator__Connect "gcoord" "rid";;
        #()
      else #())).

Definition BackupGroupCoordinator__SendInquire: val :=
  rec: "BackupGroupCoordinator__SendInquire" "gcoord" "rid" "ts" "rank" "cid" :=
    let: "data" := message.EncodeTxnInquireRequest "ts" "rank" "cid" in
    BackupGroupCoordinator__Send "gcoord" "rid" "data";;
    #().

Definition BackupGroupCoordinator__GetPwrs: val :=
  rec: "BackupGroupCoordinator__GetPwrs" "gcoord" :=
    Mutex__Lock (struct.loadF BackupGroupCoordinator "mu" "gcoord");;
    let: ("pwrs", "ok") := BackupGroupPreparer__getPwrs (struct.loadF BackupGroupCoordinator "gpp" "gcoord") in
    Mutex__Unlock (struct.loadF BackupGroupCoordinator "mu" "gcoord");;
    ("pwrs", "ok").

Definition BackupGroupCoordinator__SendValidate: val :=
  rec: "BackupGroupCoordinator__SendValidate" "gcoord" "rid" "ts" "rank" "pwrs" "ptgs" :=
    let: "data" := message.EncodeTxnValidateRequest "ts" "rank" "pwrs" "ptgs" in
    BackupGroupCoordinator__Send "gcoord" "rid" "data";;
    #().

Definition BackupGroupCoordinator__SendPrepare: val :=
  rec: "BackupGroupCoordinator__SendPrepare" "gcoord" "rid" "ts" "rank" :=
    let: "data" := message.EncodeTxnPrepareRequest "ts" "rank" in
    BackupGroupCoordinator__Send "gcoord" "rid" "data";;
    #().

Definition BackupGroupCoordinator__SendUnprepare: val :=
  rec: "BackupGroupCoordinator__SendUnprepare" "gcoord" "rid" "ts" "rank" :=
    let: "data" := message.EncodeTxnUnprepareRequest "ts" "rank" in
    BackupGroupCoordinator__Send "gcoord" "rid" "data";;
    #().

Definition BackupGroupCoordinator__SendRefresh: val :=
  rec: "BackupGroupCoordinator__SendRefresh" "gcoord" "rid" "ts" "rank" :=
    let: "data" := message.EncodeTxnRefreshRequest "ts" "rank" in
    BackupGroupCoordinator__Send "gcoord" "rid" "data";;
    #().

Definition BackupGroupCoordinator__PrepareSession: val :=
  rec: "BackupGroupCoordinator__PrepareSession" "gcoord" "rid" "ts" "rank" "ptgs" :=
    Skip;;
    (for: (λ: <>, (~ (BackupGroupCoordinator__Finalized "gcoord"))); (λ: <>, Skip) := λ: <>,
      let: "act" := BackupGroupCoordinator__NextPrepareAction "gcoord" "rid" in
      (if: "act" = BGPP_INQUIRE
      then BackupGroupCoordinator__SendInquire "gcoord" "rid" "ts" "rank" (struct.loadF BackupGroupCoordinator "cid" "gcoord")
      else
        (if: "act" = BGPP_VALIDATE
        then
          let: ("pwrs", "ok") := BackupGroupCoordinator__GetPwrs "gcoord" in
          (if: "ok"
          then BackupGroupCoordinator__SendValidate "gcoord" "rid" "ts" "rank" "pwrs" "ptgs"
          else #())
        else
          (if: "act" = BGPP_PREPARE
          then BackupGroupCoordinator__SendPrepare "gcoord" "rid" "ts" "rank"
          else
            (if: "act" = BGPP_UNPREPARE
            then BackupGroupCoordinator__SendUnprepare "gcoord" "rid" "ts" "rank"
            else
              (if: "act" = BGPP_REFRESH
              then BackupGroupCoordinator__SendRefresh "gcoord" "rid" "ts" "rank"
              else #())))));;
      (if: "act" = BGPP_REFRESH
      then
        time.Sleep params.NS_SEND_REFRESH;;
        Continue
      else
        time.Sleep params.NS_RESEND_PREPARE;;
        Continue));;
    #().

Definition BackupGroupCoordinator__WaitUntilPrepareDone: val :=
  rec: "BackupGroupCoordinator__WaitUntilPrepareDone" "gcoord" :=
    Mutex__Lock (struct.loadF BackupGroupCoordinator "mu" "gcoord");;
    Skip;;
    (for: (λ: <>, (~ (BackupGroupPreparer__ready (struct.loadF BackupGroupCoordinator "gpp" "gcoord")))); (λ: <>, Skip) := λ: <>,
      Cond__Wait (struct.loadF BackupGroupCoordinator "cv" "gcoord");;
      Continue);;
    let: "phase" := BackupGroupPreparer__getPhase (struct.loadF BackupGroupCoordinator "gpp" "gcoord") in
    Mutex__Unlock (struct.loadF BackupGroupCoordinator "mu" "gcoord");;
    (if: "phase" = BGPP_STOPPED
    then (tulip.TXN_PREPARED, #false)
    else
      (if: "phase" = BGPP_COMMITTED
      then (tulip.TXN_COMMITTED, #true)
      else
        (if: "phase" = BGPP_ABORTED
        then (tulip.TXN_ABORTED, #true)
        else (tulip.TXN_PREPARED, #true)))).

(* Arguments:
   @ts: Transaction timestamp.

   Return values:
   @status: Transaction status.
   @valid: If true, the prepare process goes through without encountering a more
   recent coordinator. @status is meaningful iff @valid is true.

   @Prepare blocks until the prepare decision (one of prepared, committed,
   aborted) is made, or a higher-ranked backup coordinator is up. *)
Definition BackupGroupCoordinator__Prepare: val :=
  rec: "BackupGroupCoordinator__Prepare" "gcoord" "ts" "rank" "ptgs" :=
    MapIter (struct.loadF BackupGroupCoordinator "addrm" "gcoord") (λ: "ridloop" <>,
      let: "rid" := "ridloop" in
      Fork (BackupGroupCoordinator__PrepareSession "gcoord" "rid" "ts" "rank" "ptgs"));;
    let: ("status", "valid") := BackupGroupCoordinator__WaitUntilPrepareDone "gcoord" in
    ("status", "valid").

Definition BackupGroupCoordinator__GetLeader: val :=
  rec: "BackupGroupCoordinator__GetLeader" "gcoord" :=
    Mutex__Lock (struct.loadF BackupGroupCoordinator "mu" "gcoord");;
    let: "idxleader" := struct.loadF BackupGroupCoordinator "idxleader" "gcoord" in
    Mutex__Unlock (struct.loadF BackupGroupCoordinator "mu" "gcoord");;
    SliceGet uint64T (struct.loadF BackupGroupCoordinator "rps" "gcoord") "idxleader".

Definition BackupGroupCoordinator__SendCommit: val :=
  rec: "BackupGroupCoordinator__SendCommit" "gcoord" "rid" "ts" "pwrs" :=
    let: "data" := message.EncodeTxnCommitRequest "ts" "pwrs" in
    BackupGroupCoordinator__Send "gcoord" "rid" "data";;
    #().

Definition BackupGroupCoordinator__ChangeLeader: val :=
  rec: "BackupGroupCoordinator__ChangeLeader" "gcoord" :=
    Mutex__Lock (struct.loadF BackupGroupCoordinator "mu" "gcoord");;
    let: "idxleader" := ((struct.loadF BackupGroupCoordinator "idxleader" "gcoord") + #1) `rem` (slice.len (struct.loadF BackupGroupCoordinator "rps" "gcoord")) in
    struct.storeF BackupGroupCoordinator "idxleader" "gcoord" "idxleader";;
    Mutex__Unlock (struct.loadF BackupGroupCoordinator "mu" "gcoord");;
    SliceGet uint64T (struct.loadF BackupGroupCoordinator "rps" "gcoord") "idxleader".

Definition BackupGroupCoordinator__Commit: val :=
  rec: "BackupGroupCoordinator__Commit" "gcoord" "ts" :=
    let: ("pwrs", "ok") := BackupGroupCoordinator__GetPwrs "gcoord" in
    (if: (~ "ok")
    then #()
    else
      let: "leader" := ref_to uint64T (BackupGroupCoordinator__GetLeader "gcoord") in
      BackupGroupCoordinator__SendCommit "gcoord" (![uint64T] "leader") "ts" "pwrs";;
      time.Sleep params.NS_RESEND_COMMIT;;
      Skip;;
      (for: (λ: <>, (~ (BackupGroupCoordinator__Finalized "gcoord"))); (λ: <>, Skip) := λ: <>,
        "leader" <-[uint64T] (BackupGroupCoordinator__ChangeLeader "gcoord");;
        BackupGroupCoordinator__SendCommit "gcoord" (![uint64T] "leader") "ts" "pwrs";;
        time.Sleep params.NS_RESEND_COMMIT;;
        Continue);;
      #()).

Definition BackupGroupCoordinator__SendAbort: val :=
  rec: "BackupGroupCoordinator__SendAbort" "gcoord" "rid" "ts" :=
    let: "data" := message.EncodeTxnAbortRequest "ts" in
    BackupGroupCoordinator__Send "gcoord" "rid" "data";;
    #().

Definition BackupGroupCoordinator__Abort: val :=
  rec: "BackupGroupCoordinator__Abort" "gcoord" "ts" :=
    let: "leader" := ref_to uint64T (BackupGroupCoordinator__GetLeader "gcoord") in
    BackupGroupCoordinator__SendAbort "gcoord" (![uint64T] "leader") "ts";;
    time.Sleep params.NS_RESEND_ABORT;;
    Skip;;
    (for: (λ: <>, (~ (BackupGroupCoordinator__Finalized "gcoord"))); (λ: <>, Skip) := λ: <>,
      "leader" <-[uint64T] (BackupGroupCoordinator__ChangeLeader "gcoord");;
      BackupGroupCoordinator__SendAbort "gcoord" (![uint64T] "leader") "ts";;
      time.Sleep params.NS_RESEND_ABORT;;
      Continue);;
    #().

Definition BackupGroupCoordinator__ConnectAll: val :=
  rec: "BackupGroupCoordinator__ConnectAll" "gcoord" :=
    ForSlice uint64T <> "rid" (struct.loadF BackupGroupCoordinator "rps" "gcoord")
      (BackupGroupCoordinator__Connect "gcoord" "rid");;
    #().

Definition BackupTxnCoordinator := struct.decl [
  "ts" :: uint64T;
  "rank" :: uint64T;
  "ptgs" :: slice.T uint64T;
  "gcoords" :: mapT ptrT;
  "proph" :: ProphIdT
].

Definition Start: val :=
  rec: "Start" "ts" "rank" "cid" "ptgs" "gaddrm" "leader" "proph" :=
    let: "gcoords" := NewMap uint64T ptrT #() in
    ForSlice uint64T <> "gid" "ptgs"
      (let: "addrm" := Fst (MapGet "gaddrm" "gid") in
      let: "gcoord" := startBackupGroupCoordinator "addrm" "cid" "ts" "rank" in
      MapInsert "gcoords" "gid" "gcoord");;
    let: "tcoord" := struct.new BackupTxnCoordinator [
      "ts" ::= "ts";
      "rank" ::= "rank";
      "ptgs" ::= "ptgs";
      "gcoords" ::= "gcoords";
      "proph" ::= "proph"
    ] in
    "tcoord".

(* @Connect tries to create connections with all the replicas in each
   participant group. *)
Definition BackupTxnCoordinator__ConnectAll: val :=
  rec: "BackupTxnCoordinator__ConnectAll" "tcoord" :=
    MapIter (struct.loadF BackupTxnCoordinator "gcoords" "tcoord") (λ: <> "gcoord",
      BackupGroupCoordinator__ConnectAll "gcoord");;
    #().

Definition BackupTxnCoordinator__stabilize: val :=
  rec: "BackupTxnCoordinator__stabilize" "tcoord" :=
    let: "ts" := struct.loadF BackupTxnCoordinator "ts" "tcoord" in
    let: "rank" := struct.loadF BackupTxnCoordinator "rank" "tcoord" in
    let: "ptgs" := struct.loadF BackupTxnCoordinator "ptgs" "tcoord" in
    let: "mu" := newMutex #() in
    let: "cv" := NewCond "mu" in
    let: "nr" := ref_to uint64T #0 in
    let: "np" := ref_to uint64T #0 in
    let: "st" := ref_to uint64T tulip.TXN_PREPARED in
    let: "vd" := ref_to boolT #true in
    ForSlice uint64T <> "gid" "ptgs"
      (let: "gcoord" := Fst (MapGet (struct.loadF BackupTxnCoordinator "gcoords" "tcoord") "gid") in
      Fork (let: ("stg", "vdg") := BackupGroupCoordinator__Prepare "gcoord" "ts" "rank" "ptgs" in
            Mutex__Lock "mu";;
            "nr" <-[uint64T] ((![uint64T] "nr") + #1);;
            (if: (~ "vdg")
            then "vd" <-[boolT] #false
            else
              (if: "stg" = tulip.TXN_PREPARED
              then "np" <-[uint64T] ((![uint64T] "np") + #1)
              else "st" <-[uint64T] "stg"));;
            Mutex__Unlock "mu";;
            Cond__Signal "cv"));;
    Mutex__Lock "mu";;
    Skip;;
    (for: (λ: <>, (![boolT] "vd") && ((![uint64T] "nr") ≠ (slice.len "ptgs"))); (λ: <>, Skip) := λ: <>,
      Cond__Wait "cv";;
      Continue);;
    let: "status" := ![uint64T] "st" in
    let: "valid" := ![boolT] "vd" in
    Mutex__Unlock "mu";;
    ("status", "valid").

Definition mergeKVMap: val :=
  rec: "mergeKVMap" "mw" "mr" :=
    MapIter "mr" (λ: "k" "v",
      MapInsert "mw" "k" "v");;
    #().

(* TODO: This function should go to a trusted package (but not trusted_proph
   since that would create a circular dependency), and be implemented as a
   "ghost function". *)
Definition BackupTxnCoordinator__mergeWrites: val :=
  rec: "BackupTxnCoordinator__mergeWrites" "tcoord" :=
    let: "valid" := ref_to boolT #true in
    let: "wrs" := NewMap stringT (struct.t tulip.Value) #() in
    ForSlice uint64T <> "gid" (struct.loadF BackupTxnCoordinator "ptgs" "tcoord")
      (let: "gcoord" := Fst (MapGet (struct.loadF BackupTxnCoordinator "gcoords" "tcoord") "gid") in
      let: ("pwrs", "ok") := BackupGroupCoordinator__GetPwrs "gcoord" in
      (if: "ok"
      then mergeKVMap "wrs" "pwrs"
      else "valid" <-[boolT] #false));;
    ("wrs", ![boolT] "valid").

Definition BackupTxnCoordinator__resolve: val :=
  rec: "BackupTxnCoordinator__resolve" "tcoord" "status" :=
    (if: "status" = tulip.TXN_COMMITTED
    then #true
    else
      let: ("wrs", "ok") := BackupTxnCoordinator__mergeWrites "tcoord" in
      (if: (~ "ok")
      then #false
      else
        trusted_proph.ResolveCommit (struct.loadF BackupTxnCoordinator "proph" "tcoord") (struct.loadF BackupTxnCoordinator "ts" "tcoord") "wrs";;
        #true)).

Definition BackupTxnCoordinator__commit: val :=
  rec: "BackupTxnCoordinator__commit" "tcoord" :=
    MapIter (struct.loadF BackupTxnCoordinator "gcoords" "tcoord") (λ: <> "gcoordloop",
      let: "gcoord" := "gcoordloop" in
      Fork (BackupGroupCoordinator__Commit "gcoord" (struct.loadF BackupTxnCoordinator "ts" "tcoord")));;
    #().

Definition BackupTxnCoordinator__abort: val :=
  rec: "BackupTxnCoordinator__abort" "tcoord" :=
    MapIter (struct.loadF BackupTxnCoordinator "gcoords" "tcoord") (λ: <> "gcoordloop",
      let: "gcoord" := "gcoordloop" in
      Fork (BackupGroupCoordinator__Abort "gcoord" (struct.loadF BackupTxnCoordinator "ts" "tcoord")));;
    #().

(* Top-level method of backup transaction coordinator. *)
Definition BackupTxnCoordinator__Finalize: val :=
  rec: "BackupTxnCoordinator__Finalize" "tcoord" :=
    let: ("status", "valid") := BackupTxnCoordinator__stabilize "tcoord" in
    (if: (~ "valid")
    then #()
    else
      (if: "status" = tulip.TXN_ABORTED
      then
        BackupTxnCoordinator__abort "tcoord";;
        #()
      else
        (if: (~ (BackupTxnCoordinator__resolve "tcoord" "status"))
        then #()
        else
          BackupTxnCoordinator__commit "tcoord";;
          #()))).
