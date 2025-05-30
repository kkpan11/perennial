(* autogenerated from github.com/mit-pdos/tulip/message *)
From Perennial.goose_lang Require Import prelude.
From Goose Require github_com.mit_pdos.tulip.tulip.
From Goose Require github_com.mit_pdos.tulip.util.
From Goose Require github_com.tchajed.marshal.

From Perennial.goose_lang Require Import ffi.grove_prelude.

Definition TxnRequest := struct.decl [
  "Kind" :: uint64T;
  "Timestamp" :: uint64T;
  "Key" :: stringT;
  "Rank" :: uint64T;
  "PartialWrites" :: slice.T (struct.t tulip.WriteEntry);
  "ParticipantGroups" :: slice.T uint64T;
  "CoordID" :: struct.t tulip.CoordID
].

Definition TxnResponse := struct.decl [
  "Kind" :: uint64T;
  "Timestamp" :: uint64T;
  "ReplicaID" :: uint64T;
  "Result" :: uint64T;
  "Key" :: stringT;
  "Version" :: struct.t tulip.Version;
  "Rank" :: uint64T;
  "RankLast" :: uint64T;
  "Prepared" :: boolT;
  "Validated" :: boolT;
  "Slow" :: boolT;
  "PartialWrites" :: tulip.KVMap;
  "CoordID" :: struct.t tulip.CoordID
].

Definition MSG_TXN_READ : expr := #100.

Definition MSG_TXN_FAST_PREPARE : expr := #201.

Definition MSG_TXN_VALIDATE : expr := #202.

Definition MSG_TXN_PREPARE : expr := #203.

Definition MSG_TXN_UNPREPARE : expr := #204.

Definition MSG_TXN_QUERY : expr := #205.

Definition MSG_TXN_INQUIRE : expr := #206.

Definition MSG_TXN_REFRESH : expr := #210.

Definition MSG_TXN_COMMIT : expr := #300.

Definition MSG_TXN_ABORT : expr := #301.

Definition MSG_DUMP_STATE : expr := #10000.

Definition MSG_FORCE_ELECTION : expr := #10001.

Definition EncodeTxnReadRequest: val :=
  rec: "EncodeTxnReadRequest" "ts" "key" :=
    let: "bs" := NewSliceWithCap byteT #0 #32 in
    let: "bs1" := marshal.WriteInt "bs" MSG_TXN_READ in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "data" := util.EncodeString "bs2" "key" in
    "data".

Definition DecodeTxnReadRequest: val :=
  rec: "DecodeTxnReadRequest" "bs" :=
    let: ("ts", "bs1") := marshal.ReadInt "bs" in
    let: ("key", <>) := util.DecodeString "bs1" in
    struct.mk TxnRequest [
      "Kind" ::= MSG_TXN_READ;
      "Timestamp" ::= "ts";
      "Key" ::= "key"
    ].

Definition EncodeTxnReadResponse: val :=
  rec: "EncodeTxnReadResponse" "ts" "rid" "key" "ver" "slow" :=
    let: "bs" := NewSliceWithCap byteT #0 #32 in
    let: "bs1" := marshal.WriteInt "bs" MSG_TXN_READ in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "bs3" := marshal.WriteInt "bs2" "rid" in
    let: "bs4" := util.EncodeString "bs3" "key" in
    let: "bs5" := util.EncodeVersion "bs4" "ver" in
    let: "data" := marshal.WriteBool "bs5" "slow" in
    "data".

Definition DecodeTxnReadResponse: val :=
  rec: "DecodeTxnReadResponse" "bs" :=
    let: ("ts", "bs1") := marshal.ReadInt "bs" in
    let: ("rid", "bs2") := marshal.ReadInt "bs1" in
    let: ("key", "bs3") := util.DecodeString "bs2" in
    let: ("ver", "bs4") := util.DecodeVersion "bs3" in
    let: ("slow", <>) := marshal.ReadBool "bs4" in
    struct.mk TxnResponse [
      "Kind" ::= MSG_TXN_READ;
      "Timestamp" ::= "ts";
      "ReplicaID" ::= "rid";
      "Key" ::= "key";
      "Version" ::= "ver";
      "Slow" ::= "slow"
    ].

Definition EncodeTxnFastPrepareRequest: val :=
  rec: "EncodeTxnFastPrepareRequest" "ts" "pwrs" "ptgs" :=
    let: "bs" := NewSliceWithCap byteT #0 #64 in
    let: "bs1" := marshal.WriteInt "bs" MSG_TXN_FAST_PREPARE in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "bs3" := util.EncodeKVMap "bs2" "pwrs" in
    let: "data" := util.EncodeInts "bs3" "ptgs" in
    "data".

Definition DecodeTxnFastPrepareRequest: val :=
  rec: "DecodeTxnFastPrepareRequest" "bs" :=
    let: ("ts", "bs1") := marshal.ReadInt "bs" in
    let: ("pwrs", "bs2") := util.DecodeKVMapIntoSlice "bs1" in
    let: ("ptgs", <>) := util.DecodeInts "bs2" in
    struct.mk TxnRequest [
      "Kind" ::= MSG_TXN_FAST_PREPARE;
      "Timestamp" ::= "ts";
      "PartialWrites" ::= "pwrs";
      "ParticipantGroups" ::= "ptgs"
    ].

Definition EncodeTxnFastPrepareResponse: val :=
  rec: "EncodeTxnFastPrepareResponse" "ts" "rid" "res" :=
    let: "bs" := NewSliceWithCap byteT #0 #32 in
    let: "bs1" := marshal.WriteInt "bs" MSG_TXN_FAST_PREPARE in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "bs3" := marshal.WriteInt "bs2" "rid" in
    let: "data" := marshal.WriteInt "bs3" "res" in
    "data".

Definition DecodeTxnFastPrepareResponse: val :=
  rec: "DecodeTxnFastPrepareResponse" "bs" :=
    let: ("ts", "bs1") := marshal.ReadInt "bs" in
    let: ("rid", "bs2") := marshal.ReadInt "bs1" in
    let: ("res", <>) := marshal.ReadInt "bs2" in
    struct.mk TxnResponse [
      "Kind" ::= MSG_TXN_FAST_PREPARE;
      "Timestamp" ::= "ts";
      "ReplicaID" ::= "rid";
      "Result" ::= "res"
    ].

Definition EncodeTxnValidateRequest: val :=
  rec: "EncodeTxnValidateRequest" "ts" "rank" "pwrs" "ptgs" :=
    let: "bs" := NewSliceWithCap byteT #0 #64 in
    let: "bs1" := marshal.WriteInt "bs" MSG_TXN_VALIDATE in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "bs3" := marshal.WriteInt "bs2" "rank" in
    let: "bs4" := util.EncodeKVMap "bs3" "pwrs" in
    let: "data" := util.EncodeInts "bs4" "ptgs" in
    "data".

Definition DecodeTxnValidateRequest: val :=
  rec: "DecodeTxnValidateRequest" "bs" :=
    let: ("ts", "bs1") := marshal.ReadInt "bs" in
    let: ("rank", "bs2") := marshal.ReadInt "bs1" in
    let: ("pwrs", "bs3") := util.DecodeKVMapIntoSlice "bs2" in
    let: ("ptgs", <>) := util.DecodeInts "bs3" in
    struct.mk TxnRequest [
      "Kind" ::= MSG_TXN_VALIDATE;
      "Timestamp" ::= "ts";
      "Rank" ::= "rank";
      "PartialWrites" ::= "pwrs";
      "ParticipantGroups" ::= "ptgs"
    ].

Definition EncodeTxnValidateResponse: val :=
  rec: "EncodeTxnValidateResponse" "ts" "rid" "res" :=
    let: "bs" := NewSliceWithCap byteT #0 #32 in
    let: "bs1" := marshal.WriteInt "bs" MSG_TXN_VALIDATE in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "bs3" := marshal.WriteInt "bs2" "rid" in
    let: "data" := marshal.WriteInt "bs3" "res" in
    "data".

Definition DecodeTxnValidateResponse: val :=
  rec: "DecodeTxnValidateResponse" "bs" :=
    let: ("ts", "bs1") := marshal.ReadInt "bs" in
    let: ("rid", "bs2") := marshal.ReadInt "bs1" in
    let: ("res", <>) := marshal.ReadInt "bs2" in
    struct.mk TxnResponse [
      "Kind" ::= MSG_TXN_VALIDATE;
      "Timestamp" ::= "ts";
      "ReplicaID" ::= "rid";
      "Result" ::= "res"
    ].

Definition EncodeTxnPrepareRequest: val :=
  rec: "EncodeTxnPrepareRequest" "ts" "rank" :=
    let: "bs" := NewSliceWithCap byteT #0 #24 in
    let: "bs1" := marshal.WriteInt "bs" MSG_TXN_PREPARE in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "data" := marshal.WriteInt "bs2" "rank" in
    "data".

Definition DecodeTxnPrepareRequest: val :=
  rec: "DecodeTxnPrepareRequest" "bs" :=
    let: ("ts", "bs1") := marshal.ReadInt "bs" in
    let: ("rank", <>) := marshal.ReadInt "bs1" in
    struct.mk TxnRequest [
      "Kind" ::= MSG_TXN_PREPARE;
      "Timestamp" ::= "ts";
      "Rank" ::= "rank"
    ].

Definition EncodeTxnPrepareResponse: val :=
  rec: "EncodeTxnPrepareResponse" "ts" "rank" "rid" "res" :=
    let: "bs" := NewSliceWithCap byteT #0 #32 in
    let: "bs1" := marshal.WriteInt "bs" MSG_TXN_PREPARE in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "bs3" := marshal.WriteInt "bs2" "rank" in
    let: "bs4" := marshal.WriteInt "bs3" "rid" in
    let: "data" := marshal.WriteInt "bs4" "res" in
    "data".

Definition DecodeTxnPrepareResponse: val :=
  rec: "DecodeTxnPrepareResponse" "bs" :=
    let: ("ts", "bs1") := marshal.ReadInt "bs" in
    let: ("rank", "bs2") := marshal.ReadInt "bs1" in
    let: ("rid", "bs3") := marshal.ReadInt "bs2" in
    let: ("res", <>) := marshal.ReadInt "bs3" in
    struct.mk TxnResponse [
      "Kind" ::= MSG_TXN_PREPARE;
      "Timestamp" ::= "ts";
      "Rank" ::= "rank";
      "ReplicaID" ::= "rid";
      "Result" ::= "res"
    ].

Definition EncodeTxnUnprepareRequest: val :=
  rec: "EncodeTxnUnprepareRequest" "ts" "rank" :=
    let: "bs" := NewSliceWithCap byteT #0 #24 in
    let: "bs1" := marshal.WriteInt "bs" MSG_TXN_UNPREPARE in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "data" := marshal.WriteInt "bs2" "rank" in
    "data".

Definition DecodeTxnUnprepareRequest: val :=
  rec: "DecodeTxnUnprepareRequest" "bs" :=
    let: ("ts", "bs1") := marshal.ReadInt "bs" in
    let: ("rank", <>) := marshal.ReadInt "bs1" in
    struct.mk TxnRequest [
      "Kind" ::= MSG_TXN_UNPREPARE;
      "Timestamp" ::= "ts";
      "Rank" ::= "rank"
    ].

Definition EncodeTxnUnprepareResponse: val :=
  rec: "EncodeTxnUnprepareResponse" "ts" "rank" "rid" "res" :=
    let: "bs" := NewSliceWithCap byteT #0 #32 in
    let: "bs1" := marshal.WriteInt "bs" MSG_TXN_UNPREPARE in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "bs3" := marshal.WriteInt "bs2" "rank" in
    let: "bs4" := marshal.WriteInt "bs3" "rid" in
    let: "data" := marshal.WriteInt "bs4" "res" in
    "data".

Definition DecodeTxnUnprepareResponse: val :=
  rec: "DecodeTxnUnprepareResponse" "bs" :=
    let: ("ts", "bs1") := marshal.ReadInt "bs" in
    let: ("rank", "bs2") := marshal.ReadInt "bs1" in
    let: ("rid", "bs3") := marshal.ReadInt "bs2" in
    let: ("res", <>) := marshal.ReadInt "bs3" in
    struct.mk TxnResponse [
      "Kind" ::= MSG_TXN_UNPREPARE;
      "Timestamp" ::= "ts";
      "Rank" ::= "rank";
      "ReplicaID" ::= "rid";
      "Result" ::= "res"
    ].

Definition EncodeTxnQueryRequest: val :=
  rec: "EncodeTxnQueryRequest" "ts" "rank" :=
    let: "bs" := NewSliceWithCap byteT #0 #24 in
    let: "bs1" := marshal.WriteInt "bs" MSG_TXN_QUERY in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "data" := marshal.WriteInt "bs2" "rank" in
    "data".

Definition DecodeTxnQueryRequest: val :=
  rec: "DecodeTxnQueryRequest" "bs" :=
    let: ("ts", "bs1") := marshal.ReadInt "bs" in
    let: ("rank", <>) := marshal.ReadInt "bs1" in
    struct.mk TxnRequest [
      "Kind" ::= MSG_TXN_QUERY;
      "Timestamp" ::= "ts";
      "Rank" ::= "rank"
    ].

Definition EncodeTxnQueryResponse: val :=
  rec: "EncodeTxnQueryResponse" "ts" "res" :=
    let: "bs" := NewSliceWithCap byteT #0 #24 in
    let: "bs1" := marshal.WriteInt "bs" MSG_TXN_QUERY in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "data" := marshal.WriteInt "bs2" "res" in
    "data".

Definition DecodeTxnQueryResponse: val :=
  rec: "DecodeTxnQueryResponse" "bs" :=
    let: ("ts", "bs1") := marshal.ReadInt "bs" in
    let: ("res", <>) := marshal.ReadInt "bs1" in
    struct.mk TxnResponse [
      "Kind" ::= MSG_TXN_QUERY;
      "Timestamp" ::= "ts";
      "Result" ::= "res"
    ].

Definition EncodeTxnInquireRequest: val :=
  rec: "EncodeTxnInquireRequest" "ts" "rank" "cid" :=
    let: "bs" := NewSliceWithCap byteT #0 #40 in
    let: "bs1" := marshal.WriteInt "bs" MSG_TXN_INQUIRE in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "bs3" := marshal.WriteInt "bs2" "rank" in
    let: "bs4" := marshal.WriteInt "bs3" (struct.get tulip.CoordID "GroupID" "cid") in
    let: "data" := marshal.WriteInt "bs4" (struct.get tulip.CoordID "ReplicaID" "cid") in
    "data".

Definition DecodeTxnInquireRequest: val :=
  rec: "DecodeTxnInquireRequest" "bs" :=
    let: ("ts", "bs1") := marshal.ReadInt "bs" in
    let: ("rank", "bs2") := marshal.ReadInt "bs1" in
    let: ("cgid", "bs3") := marshal.ReadInt "bs2" in
    let: ("crid", <>) := marshal.ReadInt "bs3" in
    let: "cid" := struct.mk tulip.CoordID [
      "GroupID" ::= "cgid";
      "ReplicaID" ::= "crid"
    ] in
    struct.mk TxnRequest [
      "Kind" ::= MSG_TXN_INQUIRE;
      "Timestamp" ::= "ts";
      "Rank" ::= "rank";
      "CoordID" ::= "cid"
    ].

Definition EncodeTxnInquireResponse: val :=
  rec: "EncodeTxnInquireResponse" "ts" "rank" "rid" "cid" "pp" "vd" "pwrs" "res" :=
    let: "bs" := NewSliceWithCap byteT #0 #128 in
    let: "bs1" := marshal.WriteInt "bs" MSG_TXN_INQUIRE in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "bs3" := marshal.WriteInt "bs2" "rid" in
    let: "bs4" := marshal.WriteInt "bs3" "rank" in
    let: "bs5" := util.EncodePrepareProposal "bs4" "pp" in
    let: "bs6" := marshal.WriteBool "bs5" "vd" in
    let: "bs7" := marshal.WriteInt "bs6" (struct.get tulip.CoordID "GroupID" "cid") in
    let: "bs8" := marshal.WriteInt "bs7" (struct.get tulip.CoordID "ReplicaID" "cid") in
    let: "bs9" := marshal.WriteInt "bs8" "res" in
    (if: "vd"
    then
      let: "data" := util.EncodeKVMapFromSlice "bs9" "pwrs" in
      "data"
    else "bs9").

Definition DecodeTxnInquireResponse: val :=
  rec: "DecodeTxnInquireResponse" "bs" :=
    let: ("ts", "bs1") := marshal.ReadInt "bs" in
    let: ("rid", "bs2") := marshal.ReadInt "bs1" in
    let: ("rank", "bs3") := marshal.ReadInt "bs2" in
    let: ("pp", "bs4") := util.DecodePrepareProposal "bs3" in
    let: ("vd", "bs5") := marshal.ReadBool "bs4" in
    let: ("cgid", "bs6") := marshal.ReadInt "bs5" in
    let: ("crid", "bs7") := marshal.ReadInt "bs6" in
    let: ("res", "bs8") := marshal.ReadInt "bs7" in
    let: "cid" := struct.mk tulip.CoordID [
      "GroupID" ::= "cgid";
      "ReplicaID" ::= "crid"
    ] in
    (if: "vd"
    then
      let: ("pwrs", <>) := util.DecodeKVMap "bs8" in
      struct.mk TxnResponse [
        "Kind" ::= MSG_TXN_INQUIRE;
        "Timestamp" ::= "ts";
        "ReplicaID" ::= "rid";
        "Rank" ::= "rank";
        "RankLast" ::= struct.get tulip.PrepareProposal "Rank" "pp";
        "Prepared" ::= struct.get tulip.PrepareProposal "Prepared" "pp";
        "Validated" ::= "vd";
        "PartialWrites" ::= "pwrs";
        "CoordID" ::= "cid";
        "Result" ::= "res"
      ]
    else
      struct.mk TxnResponse [
        "Kind" ::= MSG_TXN_INQUIRE;
        "Timestamp" ::= "ts";
        "ReplicaID" ::= "rid";
        "Rank" ::= "rank";
        "RankLast" ::= struct.get tulip.PrepareProposal "Rank" "pp";
        "Prepared" ::= struct.get tulip.PrepareProposal "Prepared" "pp";
        "Validated" ::= "vd";
        "CoordID" ::= "cid";
        "Result" ::= "res"
      ]).

Definition EncodeTxnRefreshRequest: val :=
  rec: "EncodeTxnRefreshRequest" "ts" "rank" :=
    let: "bs" := NewSliceWithCap byteT #0 #24 in
    let: "bs1" := marshal.WriteInt "bs" MSG_TXN_REFRESH in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "data" := marshal.WriteInt "bs2" "rank" in
    "data".

Definition DecodeTxnRefreshRequest: val :=
  rec: "DecodeTxnRefreshRequest" "bs" :=
    let: ("ts", "bs1") := marshal.ReadInt "bs" in
    let: ("rank", <>) := marshal.ReadInt "bs1" in
    struct.mk TxnRequest [
      "Kind" ::= MSG_TXN_REFRESH;
      "Timestamp" ::= "ts";
      "Rank" ::= "rank"
    ].

Definition EncodeTxnCommitRequest: val :=
  rec: "EncodeTxnCommitRequest" "ts" "pwrs" :=
    let: "bs" := NewSliceWithCap byteT #0 #64 in
    let: "bs1" := marshal.WriteInt "bs" MSG_TXN_COMMIT in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "data" := util.EncodeKVMap "bs2" "pwrs" in
    "data".

Definition DecodeTxnCommitRequest: val :=
  rec: "DecodeTxnCommitRequest" "bs" :=
    let: ("ts", "bs1") := marshal.ReadInt "bs" in
    let: ("pwrs", <>) := util.DecodeKVMapIntoSlice "bs1" in
    struct.mk TxnRequest [
      "Kind" ::= MSG_TXN_COMMIT;
      "Timestamp" ::= "ts";
      "PartialWrites" ::= "pwrs"
    ].

Definition EncodeTxnCommitResponse: val :=
  rec: "EncodeTxnCommitResponse" "ts" "res" :=
    let: "bs" := NewSliceWithCap byteT #0 #24 in
    let: "bs1" := marshal.WriteInt "bs" MSG_TXN_COMMIT in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "data" := marshal.WriteInt "bs2" "res" in
    "data".

Definition DecodeTxnCommitResponse: val :=
  rec: "DecodeTxnCommitResponse" "bs" :=
    let: ("ts", "bs1") := marshal.ReadInt "bs" in
    let: ("res", <>) := marshal.ReadInt "bs1" in
    struct.mk TxnResponse [
      "Kind" ::= MSG_TXN_COMMIT;
      "Timestamp" ::= "ts";
      "Result" ::= "res"
    ].

Definition EncodeTxnAbortRequest: val :=
  rec: "EncodeTxnAbortRequest" "ts" :=
    let: "bs" := NewSliceWithCap byteT #0 #16 in
    let: "bs1" := marshal.WriteInt "bs" MSG_TXN_ABORT in
    let: "data" := marshal.WriteInt "bs1" "ts" in
    "data".

Definition DecodeTxnAbortRequest: val :=
  rec: "DecodeTxnAbortRequest" "bs" :=
    let: ("ts", <>) := marshal.ReadInt "bs" in
    struct.mk TxnRequest [
      "Kind" ::= MSG_TXN_ABORT;
      "Timestamp" ::= "ts"
    ].

Definition EncodeTxnAbortResponse: val :=
  rec: "EncodeTxnAbortResponse" "ts" "res" :=
    let: "bs" := NewSliceWithCap byteT #0 #24 in
    let: "bs1" := marshal.WriteInt "bs" MSG_TXN_ABORT in
    let: "bs2" := marshal.WriteInt "bs1" "ts" in
    let: "data" := marshal.WriteInt "bs2" "res" in
    "data".

Definition DecodeTxnAbortResponse: val :=
  rec: "DecodeTxnAbortResponse" "bs" :=
    let: ("ts", "bs1") := marshal.ReadInt "bs" in
    let: ("res", <>) := marshal.ReadInt "bs1" in
    struct.mk TxnResponse [
      "Kind" ::= MSG_TXN_ABORT;
      "Timestamp" ::= "ts";
      "Result" ::= "res"
    ].

Definition EncodeDumpStateRequest: val :=
  rec: "EncodeDumpStateRequest" "gid" :=
    let: "bs" := NewSliceWithCap byteT #0 #16 in
    let: "bs1" := marshal.WriteInt "bs" MSG_DUMP_STATE in
    let: "data" := marshal.WriteInt "bs1" "gid" in
    "data".

Definition DecodeDumpStateRequest: val :=
  rec: "DecodeDumpStateRequest" "bs" :=
    let: ("gid", <>) := marshal.ReadInt "bs" in
    struct.mk TxnRequest [
      "Kind" ::= MSG_DUMP_STATE;
      "Timestamp" ::= "gid"
    ].

Definition EncodeForceElectionRequest: val :=
  rec: "EncodeForceElectionRequest" <> :=
    let: "bs" := NewSliceWithCap byteT #0 #8 in
    let: "data" := marshal.WriteInt "bs" MSG_FORCE_ELECTION in
    "data".

Definition DecodeForceElectionRequest: val :=
  rec: "DecodeForceElectionRequest" <> :=
    struct.mk TxnRequest [
      "Kind" ::= MSG_FORCE_ELECTION
    ].

Definition DecodeTxnRequest: val :=
  rec: "DecodeTxnRequest" "bs" :=
    let: ("kind", "bs1") := marshal.ReadInt "bs" in
    (if: "kind" = MSG_TXN_READ
    then DecodeTxnReadRequest "bs1"
    else
      (if: "kind" = MSG_TXN_FAST_PREPARE
      then DecodeTxnFastPrepareRequest "bs1"
      else
        (if: "kind" = MSG_TXN_VALIDATE
        then DecodeTxnValidateRequest "bs1"
        else
          (if: "kind" = MSG_TXN_PREPARE
          then DecodeTxnPrepareRequest "bs1"
          else
            (if: "kind" = MSG_TXN_UNPREPARE
            then DecodeTxnUnprepareRequest "bs1"
            else
              (if: "kind" = MSG_TXN_QUERY
              then DecodeTxnQueryRequest "bs1"
              else
                (if: "kind" = MSG_TXN_INQUIRE
                then DecodeTxnInquireRequest "bs1"
                else
                  (if: "kind" = MSG_TXN_REFRESH
                  then DecodeTxnRefreshRequest "bs1"
                  else
                    (if: "kind" = MSG_TXN_COMMIT
                    then DecodeTxnCommitRequest "bs1"
                    else
                      (if: "kind" = MSG_TXN_ABORT
                      then DecodeTxnAbortRequest "bs1"
                      else
                        (if: "kind" = MSG_DUMP_STATE
                        then DecodeDumpStateRequest "bs1"
                        else
                          (if: "kind" = MSG_FORCE_ELECTION
                          then DecodeForceElectionRequest #()
                          else
                            struct.mk TxnRequest [
                            ])))))))))))).

Definition DecodeTxnResponse: val :=
  rec: "DecodeTxnResponse" "bs" :=
    let: ("kind", "bs1") := marshal.ReadInt "bs" in
    (if: "kind" = MSG_TXN_READ
    then DecodeTxnReadResponse "bs1"
    else
      (if: "kind" = MSG_TXN_FAST_PREPARE
      then DecodeTxnFastPrepareResponse "bs1"
      else
        (if: "kind" = MSG_TXN_VALIDATE
        then DecodeTxnValidateResponse "bs1"
        else
          (if: "kind" = MSG_TXN_PREPARE
          then DecodeTxnPrepareResponse "bs1"
          else
            (if: "kind" = MSG_TXN_UNPREPARE
            then DecodeTxnUnprepareResponse "bs1"
            else
              (if: "kind" = MSG_TXN_QUERY
              then DecodeTxnQueryResponse "bs1"
              else
                (if: "kind" = MSG_TXN_INQUIRE
                then DecodeTxnInquireResponse "bs1"
                else
                  (if: "kind" = MSG_TXN_COMMIT
                  then DecodeTxnCommitResponse "bs1"
                  else
                    (if: "kind" = MSG_TXN_ABORT
                    then DecodeTxnAbortResponse "bs1"
                    else
                      struct.mk TxnResponse [
                      ]))))))))).
