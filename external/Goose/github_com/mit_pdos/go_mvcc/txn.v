(* autogenerated from github.com/mit-pdos/go-mvcc/txn *)
From Perennial.goose_lang Require Import prelude.
From Goose Require github_com.mit_pdos.go_mvcc.config.
From Goose Require github_com.mit_pdos.go_mvcc.index.
From Goose Require github_com.mit_pdos.go_mvcc.tid.
From Goose Require github_com.mit_pdos.go_mvcc.wrbuf.
From Perennial.goose_lang.trusted Require Import github_com.mit_pdos.go_mvcc.trusted_proph.

From Perennial.goose_lang Require Import ffi.grove_prelude.

Definition Txn := struct.decl [
  "tid" :: uint64T;
  "sid" :: uint64T;
  "wrbuf" :: ptrT;
  "idx" :: ptrT;
  "txnMgr" :: ptrT
].

Definition TxnSite := struct.decl [
  "latch" :: ptrT;
  "tidsActive" :: slice.T uint64T;
  "padding" :: arrayT uint64T
].

Definition TxnMgr := struct.decl [
  "latch" :: ptrT;
  "sidCur" :: uint64T;
  "sites" :: slice.T ptrT;
  "idx" :: ptrT;
  "p" :: ProphIdT
].

Definition MkTxnMgr: val :=
  rec: "MkTxnMgr" <> :=
    let: "p" := NewProph #() in
    let: "txnMgr" := struct.new TxnMgr [
      "p" ::= "p"
    ] in
    struct.storeF TxnMgr "latch" "txnMgr" (lock.new #());;
    struct.storeF TxnMgr "sites" "txnMgr" (NewSlice ptrT config.N_TXN_SITES);;
    tid.GenTID #0;;
    let: "i" := ref_to uint64T #0 in
    (for: (λ: <>, ![uint64T] "i" < config.N_TXN_SITES); (λ: <>, "i" <-[uint64T] ![uint64T] "i" + #1) := λ: <>,
      let: "site" := struct.alloc TxnSite (zero_val (struct.t TxnSite)) in
      struct.storeF TxnSite "latch" "site" (lock.new #());;
      struct.storeF TxnSite "tidsActive" "site" (NewSliceWithCap uint64T #0 #8);;
      SliceSet ptrT (struct.loadF TxnMgr "sites" "txnMgr") (![uint64T] "i") "site";;
      Continue);;
    struct.storeF TxnMgr "idx" "txnMgr" (index.MkIndex #());;
    "txnMgr".

Definition TxnMgr__New: val :=
  rec: "TxnMgr__New" "txnMgr" :=
    lock.acquire (struct.loadF TxnMgr "latch" "txnMgr");;
    let: "txn" := struct.alloc Txn (zero_val (struct.t Txn)) in
    struct.storeF Txn "wrbuf" "txn" (wrbuf.MkWrBuf #());;
    let: "sid" := struct.loadF TxnMgr "sidCur" "txnMgr" in
    struct.storeF Txn "sid" "txn" "sid";;
    struct.storeF Txn "idx" "txn" (struct.loadF TxnMgr "idx" "txnMgr");;
    struct.storeF Txn "txnMgr" "txn" "txnMgr";;
    struct.storeF TxnMgr "sidCur" "txnMgr" ("sid" + #1);;
    (if: struct.loadF TxnMgr "sidCur" "txnMgr" ≥ config.N_TXN_SITES
    then struct.storeF TxnMgr "sidCur" "txnMgr" #0
    else #());;
    lock.release (struct.loadF TxnMgr "latch" "txnMgr");;
    "txn".

Definition TxnMgr__activate: val :=
  rec: "TxnMgr__activate" "txnMgr" "sid" :=
    let: "site" := SliceGet ptrT (struct.loadF TxnMgr "sites" "txnMgr") "sid" in
    lock.acquire (struct.loadF TxnSite "latch" "site");;
    let: "t" := ref (zero_val uint64T) in
    "t" <-[uint64T] tid.GenTID "sid";;
    control.impl.Assume (![uint64T] "t" < #18446744073709551615);;
    struct.storeF TxnSite "tidsActive" "site" (SliceAppend uint64T (struct.loadF TxnSite "tidsActive" "site") (![uint64T] "t"));;
    lock.release (struct.loadF TxnSite "latch" "site");;
    ![uint64T] "t".

(* *
    * Precondition:
    * 1. `tid` in `tids`. *)
Definition findTID: val :=
  rec: "findTID" "tid" "tids" :=
    let: "idx" := ref_to uint64T #0 in
    Skip;;
    (for: (λ: <>, "tid" ≠ SliceGet uint64T "tids" (![uint64T] "idx")); (λ: <>, Skip) := λ: <>,
      "idx" <-[uint64T] ![uint64T] "idx" + #1;;
      Continue);;
    ![uint64T] "idx".

(* *
    * Precondition:
    * 1. `xs` not empty.
    * 2. `i < len(xs)` *)
Definition swapWithEnd: val :=
  rec: "swapWithEnd" "xs" "i" :=
    let: "tmp" := SliceGet uint64T "xs" (slice.len "xs" - #1) in
    SliceSet uint64T "xs" (slice.len "xs" - #1) (SliceGet uint64T "xs" "i");;
    SliceSet uint64T "xs" "i" "tmp";;
    #().

(* *
    * This function is called by `Txn` at commit/abort time.
    * Precondition:
    * 1. The set of active transactions contains `tid`. *)
Definition TxnMgr__deactivate: val :=
  rec: "TxnMgr__deactivate" "txnMgr" "sid" "tid" :=
    let: "site" := SliceGet ptrT (struct.loadF TxnMgr "sites" "txnMgr") "sid" in
    lock.acquire (struct.loadF TxnSite "latch" "site");;
    let: "idx" := findTID "tid" (struct.loadF TxnSite "tidsActive" "site") in
    swapWithEnd (struct.loadF TxnSite "tidsActive" "site") "idx";;
    struct.storeF TxnSite "tidsActive" "site" (SliceTake (struct.loadF TxnSite "tidsActive" "site") (slice.len (struct.loadF TxnSite "tidsActive" "site") - #1));;
    lock.release (struct.loadF TxnSite "latch" "site");;
    #().

Definition TxnMgr__getMinActiveTIDSite: val :=
  rec: "TxnMgr__getMinActiveTIDSite" "txnMgr" "sid" :=
    let: "site" := SliceGet ptrT (struct.loadF TxnMgr "sites" "txnMgr") "sid" in
    lock.acquire (struct.loadF TxnSite "latch" "site");;
    let: "tidnew" := ref (zero_val uint64T) in
    "tidnew" <-[uint64T] tid.GenTID "sid";;
    control.impl.Assume (![uint64T] "tidnew" < #18446744073709551615);;
    let: "tidmin" := ref_to uint64T (![uint64T] "tidnew") in
    ForSlice uint64T <> "tid" (struct.loadF TxnSite "tidsActive" "site")
      ((if: "tid" < ![uint64T] "tidmin"
      then "tidmin" <-[uint64T] "tid"
      else #()));;
    lock.release (struct.loadF TxnSite "latch" "site");;
    ![uint64T] "tidmin".

(* *
    * This function returns a lower bound of the active TID. *)
Definition TxnMgr__getMinActiveTID: val :=
  rec: "TxnMgr__getMinActiveTID" "txnMgr" :=
    let: "min" := ref_to uint64T config.TID_SENTINEL in
    let: "sid" := ref_to uint64T #0 in
    (for: (λ: <>, ![uint64T] "sid" < config.N_TXN_SITES); (λ: <>, "sid" <-[uint64T] ![uint64T] "sid" + #1) := λ: <>,
      let: "tid" := TxnMgr__getMinActiveTIDSite "txnMgr" (![uint64T] "sid") in
      (if: "tid" < ![uint64T] "min"
      then
        "min" <-[uint64T] "tid";;
        Continue
      else Continue));;
    ![uint64T] "min".

(* *
    * Probably only used for testing and profiling. *)
Definition TxnMgr__getNumActiveTxns: val :=
  rec: "TxnMgr__getNumActiveTxns" "txnMgr" :=
    let: "n" := ref_to uint64T #0 in
    let: "sid" := ref_to uint64T #0 in
    (for: (λ: <>, ![uint64T] "sid" < config.N_TXN_SITES); (λ: <>, "sid" <-[uint64T] ![uint64T] "sid" + #1) := λ: <>,
      let: "site" := SliceGet ptrT (struct.loadF TxnMgr "sites" "txnMgr") (![uint64T] "sid") in
      lock.acquire (struct.loadF TxnSite "latch" "site");;
      "n" <-[uint64T] ![uint64T] "n" + slice.len (struct.loadF TxnSite "tidsActive" "site");;
      lock.release (struct.loadF TxnSite "latch" "site");;
      Continue);;
    ![uint64T] "n".

Definition TxnMgr__gc: val :=
  rec: "TxnMgr__gc" "txnMgr" :=
    let: "tidMin" := TxnMgr__getMinActiveTID "txnMgr" in
    (if: "tidMin" < config.TID_SENTINEL
    then
      index.Index__DoGC (struct.loadF TxnMgr "idx" "txnMgr") "tidMin";;
      #()
    else #()).

Definition TxnMgr__ActivateGC: val :=
  rec: "TxnMgr__ActivateGC" "txnMgr" :=
    Fork (Skip;;
          (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
            TxnMgr__gc "txnMgr";;
            time.Sleep (#100 * #1000000);;
            Continue));;
    #().

Definition Txn__Put: val :=
  rec: "Txn__Put" "txn" "key" "val" :=
    let: "wrbuf" := struct.loadF Txn "wrbuf" "txn" in
    wrbuf.WrBuf__Put "wrbuf" "key" "val";;
    #().

Definition Txn__Delete: val :=
  rec: "Txn__Delete" "txn" "key" :=
    let: "wrbuf" := struct.loadF Txn "wrbuf" "txn" in
    wrbuf.WrBuf__Delete "wrbuf" "key";;
    #true.

Definition Txn__Get: val :=
  rec: "Txn__Get" "txn" "key" :=
    let: "wrbuf" := struct.loadF Txn "wrbuf" "txn" in
    let: (("valb", "wr"), "found") := wrbuf.WrBuf__Lookup "wrbuf" "key" in
    (if: "found"
    then ("valb", "wr")
    else
      let: "idx" := struct.loadF Txn "idx" "txn" in
      let: "tuple" := index.Index__GetTuple "idx" "key" in
      tuple.Tuple__ReadWait "tuple" (struct.loadF Txn "tid" "txn");;
      trusted_proph.ResolveRead (struct.loadF TxnMgr "p" (struct.loadF Txn "txnMgr" "txn")) (struct.loadF Txn "tid" "txn") "key";;
      let: ("val", "found") := tuple.Tuple__ReadVersion "tuple" (struct.loadF Txn "tid" "txn") in
      ("val", "found")).

Definition Txn__begin: val :=
  rec: "Txn__begin" "txn" :=
    let: "tid" := TxnMgr__activate (struct.loadF Txn "txnMgr" "txn") (struct.loadF Txn "sid" "txn") in
    struct.storeF Txn "tid" "txn" "tid";;
    wrbuf.WrBuf__Clear (struct.loadF Txn "wrbuf" "txn");;
    #().

Definition Txn__acquire: val :=
  rec: "Txn__acquire" "txn" :=
    let: "ok" := wrbuf.WrBuf__OpenTuples (struct.loadF Txn "wrbuf" "txn") (struct.loadF Txn "tid" "txn") (struct.loadF Txn "idx" "txn") in
    "ok".

Definition Txn__commit: val :=
  rec: "Txn__commit" "txn" :=
    trusted_proph.ResolveCommit (struct.loadF TxnMgr "p" (struct.loadF Txn "txnMgr" "txn")) (struct.loadF Txn "tid" "txn") (struct.loadF Txn "wrbuf" "txn");;
    wrbuf.WrBuf__UpdateTuples (struct.loadF Txn "wrbuf" "txn") (struct.loadF Txn "tid" "txn");;
    TxnMgr__deactivate (struct.loadF Txn "txnMgr" "txn") (struct.loadF Txn "sid" "txn") (struct.loadF Txn "tid" "txn");;
    #().

Definition Txn__abort: val :=
  rec: "Txn__abort" "txn" :=
    trusted_proph.ResolveAbort (struct.loadF TxnMgr "p" (struct.loadF Txn "txnMgr" "txn")) (struct.loadF Txn "tid" "txn");;
    TxnMgr__deactivate (struct.loadF Txn "txnMgr" "txn") (struct.loadF Txn "sid" "txn") (struct.loadF Txn "tid" "txn");;
    #().

Definition Txn__DoTxn: val :=
  rec: "Txn__DoTxn" "txn" "body" :=
    Txn__begin "txn";;
    let: "cmt" := "body" "txn" in
    (if: ~ "cmt"
    then
      Txn__abort "txn";;
      #false
    else
      let: "ok" := Txn__acquire "txn" in
      (if: ~ "ok"
      then
        Txn__abort "txn";;
        #false
      else
        Txn__commit "txn";;
        #true)).
