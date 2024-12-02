From Perennial.program_proof Require Import marshal_stateless_proof.
From Perennial.program_proof.tulip.program Require Import prelude.
From Perennial.program_proof.tulip.program.util Require Import
  decode_string decode_kvmap_into_slice.

Definition txnreq_to_val (req : txnreq) (pwrsP : Slice.t) : val :=
  match req with
  | ReadReq ts key =>
      struct.mk_f TxnRequest [
          ("Kind", #(U64 100)); ("Timestamp", #ts); ("Key", #(LitString key))]
  | FastPrepareReq ts pwrs =>
      struct.mk_f TxnRequest [
          ("Kind", #(U64 201)); ("Timestamp", #ts); ("PartialWrites", to_val pwrsP)]
  | ValidateReq ts rank pwrs =>
      struct.mk_f TxnRequest [
          ("Kind", #(U64 202)); ("Timestamp", #ts); ("Rank", #rank);
          ("PartialWrites", to_val pwrsP)]
  | PrepareReq ts rank =>
      struct.mk_f TxnRequest [
          ("Kind", #(U64 203)); ("Timestamp", #ts); ("Rank", #rank)]
  | UnprepareReq ts rank =>
      struct.mk_f TxnRequest [
          ("Kind", #(U64 204)); ("Timestamp", #ts); ("Rank", #rank)]
  | QueryReq ts rank =>
      struct.mk_f TxnRequest [
          ("Kind", #(U64 205)); ("Timestamp", #ts); ("Rank", #rank)]
  | RefreshReq ts rank =>
      struct.mk_f TxnRequest [
          ("Kind", #(U64 210)); ("Timestamp", #ts); ("Rank", #rank)]
  | CommitReq ts pwrs =>
      struct.mk_f TxnRequest [
          ("Kind", #(U64 300)); ("Timestamp", #ts); ("PartialWrites", to_val pwrsP)]
  | AbortReq ts =>
      struct.mk_f TxnRequest [
          ("Kind", #(U64 301)); ("Timestamp", #ts)]
  end.

Section decode.
  Context `{!heapGS Σ, !tulip_ghostG Σ}.

  Theorem wp_DecodeTxnReadRequest (bsP : Slice.t) ts key :
    let bs := encode_read_req_xkind ts key in
    {{{ own_slice_small bsP byteT (DfracOwn 1) bs }}}
      DecodeTxnReadRequest (to_val bsP)
    {{{ RET (txnreq_to_val (ReadReq ts key) Slice.nil); True }}}.
  Proof.
    iIntros (bs Φ) "Hbs HΦ".
    wp_rec.

    (*@ func DecodeTxnReadRequest(bs []byte) TxnRequest {                       @*)
    (*@     ts, bs1 := marshal.ReadInt(bs)                                      @*)
    (*@     key, _ := util.DecodeString(bs1)                                    @*)
    (*@     return TxnRequest{                                                  @*)
    (*@         Kind      : MSG_TXN_READ,                                       @*)
    (*@         Timestamp : ts,                                                 @*)
    (*@         Key       : key,                                                @*)
    (*@     }                                                                   @*)
    (*@ }                                                                       @*)
    wp_apply (wp_ReadInt with "Hbs").
    iIntros (bs1P) "Hbs".
    rewrite -(app_nil_r (encode_string key)).
    wp_apply (wp_DecodeString with "Hbs").
    iIntros (dataP) "Hdata".
    wp_pures.
    by iApply "HΦ".
  Qed.

  Theorem wp_DecodeTxnFastPrepareRequest (bsP : Slice.t) ts pwrs bs :
    encode_fast_prepare_req_xkind ts pwrs bs ->
    {{{ own_slice_small bsP byteT (DfracOwn 1) bs }}}
      DecodeTxnFastPrepareRequest (to_val bsP)
    {{{ (pwrsP : Slice.t), RET (txnreq_to_val (FastPrepareReq ts pwrs) pwrsP);
        own_dbmap_in_slice pwrsP pwrs
    }}}.
  Proof.
    iIntros (Henc Φ) "Hbs HΦ".
    wp_rec.

    (*@ func DecodeTxnFastPrepareRequest(bs []byte) TxnRequest {                @*)
    (*@     ts, bs1 := marshal.ReadInt(bs)                                      @*)
    (*@     pwrs, _ := util.DecodeKVMapIntoSlice(bs1)                           @*)
    (*@     return TxnRequest{                                                  @*)
    (*@         Kind          : MSG_TXN_FAST_PREPARE,                           @*)
    (*@         Timestamp     : ts,                                             @*)
    (*@         PartialWrites : pwrs,                                           @*)
    (*@     }                                                                   @*)
    (*@ }                                                                       @*)
    destruct Henc as (reqdata & -> & Hreqdata).
    wp_apply (wp_ReadInt with "Hbs").
    iIntros (bs1P) "Hbs".
    rewrite -(app_nil_r reqdata).
    wp_apply (wp_DecodeKVMapIntoSlice with "Hbs").
    { apply Hreqdata. }
    iIntros (pwrsP dataP) "[Hpwrs Hdata]".
    wp_pures.
    by iApply "HΦ".
  Qed.

  Theorem wp_DecodeTxnValidateRequest (bsP : Slice.t) ts rank pwrs bs :
    encode_validate_req_xkind ts rank pwrs bs ->
    {{{ own_slice_small bsP byteT (DfracOwn 1) bs }}}
      DecodeTxnValidateRequest (to_val bsP)
    {{{ (pwrsP : Slice.t), RET (txnreq_to_val (ValidateReq ts rank pwrs) pwrsP);
        own_dbmap_in_slice pwrsP pwrs
    }}}.
  Proof.
    iIntros (Henc Φ) "Hbs HΦ".
    wp_rec.

    (*@ func DecodeTxnValidateRequest(bs []byte) TxnRequest {                   @*)
    (*@     ts, bs1 := marshal.ReadInt(bs)                                      @*)
    (*@     rank, bs2 := marshal.ReadInt(bs1)                                   @*)
    (*@     pwrs, _ := util.DecodeKVMapIntoSlice(bs2)                           @*)
    (*@     return TxnRequest{                                                  @*)
    (*@         Kind          : MSG_TXN_VALIDATE,                               @*)
    (*@         Timestamp     : ts,                                             @*)
    (*@         Rank          : rank,                                           @*)
    (*@         PartialWrites : pwrs,                                           @*)
    (*@     }                                                                   @*)
    (*@ }                                                                       @*)
    destruct Henc as (reqdata & -> & Hreqdata).
    wp_apply (wp_ReadInt with "Hbs").
    iIntros (bs1P) "Hbs".
    wp_apply (wp_ReadInt with "Hbs").
    iIntros (bs2P) "Hbs".
    rewrite -(app_nil_r reqdata).
    wp_apply (wp_DecodeKVMapIntoSlice with "Hbs").
    { apply Hreqdata. }
    iIntros (pwrsP dataP) "[Hpwrs Hdata]".
    wp_pures.
    by iApply "HΦ".
  Qed.

  Theorem wp_DecodeTxnPrepareRequest (bsP : Slice.t) ts rank :
    let bs := encode_ts_rank ts rank in
    {{{ own_slice_small bsP byteT (DfracOwn 1) bs }}}
      DecodeTxnPrepareRequest (to_val bsP)
    {{{ RET (txnreq_to_val (PrepareReq ts rank) Slice.nil); True }}}.
  Proof.
    iIntros (bs Φ) "Hbs HΦ".
    wp_rec.

    (*@ func DecodeTxnPrepareRequest(bs []byte) TxnRequest {                    @*)
    (*@     ts, bs1 := marshal.ReadInt(bs)                                      @*)
    (*@     rank, _ := marshal.ReadInt(bs1)                                     @*)
    (*@     return TxnRequest{                                                  @*)
    (*@         Kind          : MSG_TXN_PREPARE,                                @*)
    (*@         Timestamp     : ts,                                             @*)
    (*@         Rank          : rank,                                           @*)
    (*@     }                                                                   @*)
    (*@ }                                                                       @*)
    wp_apply (wp_ReadInt with "Hbs").
    iIntros (bs1P) "Hbs".
    wp_apply (wp_ReadInt with "Hbs").
    iIntros (bs2P) "Hbs".
    wp_pures.
    by iApply "HΦ".
  Qed.

  Theorem wp_DecodeTxnUnprepareRequest (bsP : Slice.t) ts rank :
    let bs := encode_ts_rank ts rank in
    {{{ own_slice_small bsP byteT (DfracOwn 1) bs }}}
      DecodeTxnUnprepareRequest (to_val bsP)
    {{{ RET (txnreq_to_val (UnprepareReq ts rank) Slice.nil); True }}}.
  Proof.
    iIntros (bs Φ) "Hbs HΦ".
    wp_rec.

    (*@ func DecodeTxnUnprepareRequest(bs []byte) TxnRequest {                  @*)
    (*@     ts, bs1 := marshal.ReadInt(bs)                                      @*)
    (*@     rank, _ := marshal.ReadInt(bs1)                                     @*)
    (*@     return TxnRequest{                                                  @*)
    (*@         Kind          : MSG_TXN_UNPREPARE,                              @*)
    (*@         Timestamp     : ts,                                             @*)
    (*@         Rank          : rank,                                           @*)
    (*@     }                                                                   @*)
    (*@ }                                                                       @*)
    wp_apply (wp_ReadInt with "Hbs").
    iIntros (bs1P) "Hbs".
    wp_apply (wp_ReadInt with "Hbs").
    iIntros (bs2P) "Hbs".
    wp_pures.
    by iApply "HΦ".
  Qed.

  Theorem wp_DecodeTxnQueryRequest (bsP : Slice.t) ts rank :
    let bs := encode_ts_rank ts rank in
    {{{ own_slice_small bsP byteT (DfracOwn 1) bs }}}
      DecodeTxnQueryRequest (to_val bsP)
    {{{ RET (txnreq_to_val (QueryReq ts rank) Slice.nil); True }}}.
  Proof.
    iIntros (bs Φ) "Hbs HΦ".
    wp_rec.

    (*@ func DecodeTxnQueryRequest(bs []byte) TxnRequest {                      @*)
    (*@     ts, bs1 := marshal.ReadInt(bs)                                      @*)
    (*@     rank, _ := marshal.ReadInt(bs1)                                     @*)
    (*@     return TxnRequest{                                                  @*)
    (*@         Kind          : MSG_TXN_QUERY,                                  @*)
    (*@         Timestamp     : ts,                                             @*)
    (*@         Rank          : rank,                                           @*)
    (*@     }                                                                   @*)
    (*@ }                                                                       @*)
    wp_apply (wp_ReadInt with "Hbs").
    iIntros (bs1P) "Hbs".
    wp_apply (wp_ReadInt with "Hbs").
    iIntros (bs2P) "Hbs".
    wp_pures.
    by iApply "HΦ".
  Qed.

  Theorem wp_DecodeTxnRefreshRequest (bsP : Slice.t) ts rank :
    let bs := encode_ts_rank ts rank in
    {{{ own_slice_small bsP byteT (DfracOwn 1) bs }}}
      DecodeTxnRefreshRequest (to_val bsP)
    {{{ RET (txnreq_to_val (RefreshReq ts rank) Slice.nil); True }}}.
  Proof.
    iIntros (bs Φ) "Hbs HΦ".
    wp_rec.

    (*@ func DecodeTxnRefreshRequest(bs []byte) TxnRequest {                    @*)
    (*@     ts, bs1 := marshal.ReadInt(bs)                                      @*)
    (*@     rank, _ := marshal.ReadInt(bs1)                                     @*)
    (*@     return TxnRequest{                                                  @*)
    (*@         Kind          : MSG_TXN_REFRESH,                                @*)
    (*@         Timestamp     : ts,                                             @*)
    (*@         Rank          : rank,                                           @*)
    (*@     }                                                                   @*)
    (*@ }                                                                       @*)
    wp_apply (wp_ReadInt with "Hbs").
    iIntros (bs1P) "Hbs".
    wp_apply (wp_ReadInt with "Hbs").
    iIntros (bs2P) "Hbs".
    wp_pures.
    by iApply "HΦ".
  Qed.

  Theorem wp_DecodeTxnCommitRequest (bsP : Slice.t) ts pwrs bs :
    encode_commit_req_xkind ts pwrs bs ->
    {{{ own_slice_small bsP byteT (DfracOwn 1) bs }}}
      DecodeTxnCommitRequest (to_val bsP)
    {{{ (pwrsP : Slice.t), RET (txnreq_to_val (CommitReq ts pwrs) pwrsP);
        own_dbmap_in_slice pwrsP pwrs
    }}}.
  Proof.
    iIntros (Henc Φ) "Hbs HΦ".
    wp_rec.

    (*@ func DecodeTxnCommitRequest(bs []byte) TxnRequest {                     @*)
    (*@     ts, bs1 := marshal.ReadInt(bs)                                      @*)
    (*@     pwrs, _ := util.DecodeKVMapIntoSlice(bs1)                           @*)
    (*@     return TxnRequest{                                                  @*)
    (*@         Kind          : MSG_TXN_COMMIT,                                 @*)
    (*@         Timestamp     : ts,                                             @*)
    (*@         PartialWrites : pwrs,                                           @*)
    (*@     }                                                                   @*)
    (*@ }                                                                       @*)
    destruct Henc as (reqdata & -> & Hreqdata).
    wp_apply (wp_ReadInt with "Hbs").
    iIntros (bs1P) "Hbs".
    rewrite -(app_nil_r reqdata).
    wp_apply (wp_DecodeKVMapIntoSlice with "Hbs").
    { apply Hreqdata. }
    iIntros (pwrsP dataP) "[Hpwrs Hdata]".
    wp_pures.
    by iApply "HΦ".
  Qed.

  Theorem wp_DecodeTxnAbortRequest (bsP : Slice.t) ts :
    let bs := encode_abort_req_xkind ts in
    {{{ own_slice_small bsP byteT (DfracOwn 1) bs }}}
      DecodeTxnAbortRequest (to_val bsP)
    {{{ RET (txnreq_to_val (AbortReq ts) Slice.nil); True }}}.
  Proof.
    iIntros (bs Φ) "Hbs HΦ".
    wp_rec.

    (*@ func DecodeTxnAbortRequest(bs []byte) TxnRequest {                      @*)
    (*@     ts, _ := marshal.ReadInt(bs)                                        @*)
    (*@     return TxnRequest{                                                  @*)
    (*@         Kind          : MSG_TXN_ABORT,                                  @*)
    (*@         Timestamp     : ts,                                             @*)
    (*@     }                                                                   @*)
    (*@ }                                                                       @*)
    wp_apply (wp_ReadInt with "Hbs").
    iIntros (bs1P) "Hbs".
    wp_pures.
    by iApply "HΦ".
  Qed.

  Theorem wp_DecodeTxnRequest (bsP : Slice.t) (bs : list u8) (req : txnreq) :
    encode_txnreq req bs ->
    {{{ own_slice_small bsP byteT (DfracOwn 1) bs }}}
      DecodeTxnRequest (to_val bsP)
    {{{ (pwrsP : Slice.t), RET (txnreq_to_val req pwrsP);
        match req with
        | FastPrepareReq _ pwrs => own_dbmap_in_slice pwrsP pwrs
        | ValidateReq _ _ pwrs => own_dbmap_in_slice pwrsP pwrs
        | CommitReq _ pwrs => own_dbmap_in_slice pwrsP pwrs
        | _ => True
        end
    }}}.
  Proof.
    iIntros (Henc Φ) "Hbs HΦ".
    wp_rec.

    (*@ func DecodeTxnRequest(bs []byte) TxnRequest {                           @*)
    (*@     kind, bs1 := marshal.ReadInt(bs)                                    @*)
    (*@                                                                         @*)
    destruct req; wp_pures; simpl in Henc.
    { rewrite Henc.

      (*@     if kind == MSG_TXN_READ {                                           @*)
      (*@         return DecodeTxnReadRequest(bs1)                                @*)
      (*@     }                                                                   @*)
      (*@                                                                         @*)
      wp_apply (wp_ReadInt with "Hbs").
      iIntros (p) "Hbs".
      wp_pures.
      wp_apply (wp_DecodeTxnReadRequest with "Hbs").
      by iApply "HΦ".
    }
    { destruct Henc as (reqdata & -> & Hreqdata).

      (*@     if kind == MSG_TXN_FAST_PREPARE {                                   @*)
      (*@         return DecodeTxnFastPrepareRequest(bs1)                         @*)
      (*@     }                                                                   @*)
      (*@                                                                         @*)
      wp_apply (wp_ReadInt with "Hbs").
      iIntros (p) "Hbs".
      wp_pures.
      wp_apply (wp_DecodeTxnFastPrepareRequest with "Hbs").
      { apply Hreqdata. }
      by iApply "HΦ".
    }
    { destruct Henc as (reqdata & -> & Hreqdata).

      (*@     if kind == MSG_TXN_VALIDATE {                                       @*)
      (*@         return DecodeTxnValidateRequest(bs1)                            @*)
      (*@     }                                                                   @*)
      (*@                                                                         @*)
      wp_apply (wp_ReadInt with "Hbs").
      iIntros (p) "Hbs".
      wp_pures.
      wp_apply (wp_DecodeTxnValidateRequest with "Hbs").
      { apply Hreqdata. }
      by iApply "HΦ".
    }
    { rewrite Henc.

      (*@     if kind == MSG_TXN_PREPARE {                                        @*)
      (*@         return DecodeTxnPrepareRequest(bs1)                             @*)
      (*@     }                                                                   @*)
      (*@                                                                         @*)
      wp_apply (wp_ReadInt with "Hbs").
      iIntros (p) "Hbs".
      wp_pures.
      wp_apply (wp_DecodeTxnPrepareRequest with "Hbs").
      by iApply "HΦ".
    }
    { rewrite Henc.

      (*@     if kind == MSG_TXN_UNPREPARE {                                      @*)
      (*@         return DecodeTxnUnprepareRequest(bs1)                           @*)
      (*@     }                                                                   @*)
      (*@                                                                         @*)
      wp_apply (wp_ReadInt with "Hbs").
      iIntros (p) "Hbs".
      wp_pures.
      wp_apply (wp_DecodeTxnUnprepareRequest with "Hbs").
      by iApply "HΦ".
    }
    { rewrite Henc.

      (*@     if kind == MSG_TXN_QUERY {                                          @*)
      (*@         return DecodeTxnQueryRequest(bs1)                               @*)
      (*@     }                                                                   @*)
      (*@                                                                         @*)
      wp_apply (wp_ReadInt with "Hbs").
      iIntros (p) "Hbs".
      wp_pures.
      wp_apply (wp_DecodeTxnQueryRequest with "Hbs").
      by iApply "HΦ".
    }
    { rewrite Henc.

      (*@     if kind == MSG_TXN_REFRESH {                                        @*)
      (*@         return DecodeTxnRefreshRequest(bs1)                             @*)
      (*@     }                                                                   @*)
      (*@                                                                         @*)
      wp_apply (wp_ReadInt with "Hbs").
      iIntros (p) "Hbs".
      wp_pures.
      wp_apply (wp_DecodeTxnRefreshRequest with "Hbs").
      by iApply "HΦ".
    }
    { destruct Henc as (reqdata & -> & Hreqdata).

      (*@     if kind == MSG_TXN_COMMIT {                                         @*)
      (*@         return DecodeTxnCommitRequest(bs1)                              @*)
      (*@     }                                                                   @*)
      (*@                                                                         @*)
      wp_apply (wp_ReadInt with "Hbs").
      iIntros (p) "Hbs".
      wp_pures.
      wp_apply (wp_DecodeTxnCommitRequest with "Hbs").
      { apply Hreqdata. }
      by iApply "HΦ".
    }
    { rewrite Henc.

      (*@     if kind == MSG_TXN_ABORT {                                          @*)
      (*@         return DecodeTxnAbortRequest(bs1)                               @*)
      (*@     }                                                                   @*)
      (*@                                                                         @*)
      wp_apply (wp_ReadInt with "Hbs").
      iIntros (p) "Hbs".
      wp_pures.
      wp_apply (wp_DecodeTxnAbortRequest with "Hbs").
      by iApply "HΦ".
    }

    (*@     return TxnRequest{}                                                 @*)
    (*@ }                                                                       @*)
  Qed.

End decode.