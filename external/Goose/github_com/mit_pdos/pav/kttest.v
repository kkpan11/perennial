(* autogenerated from github.com/mit-pdos/pav/kttest *)
From Perennial.goose_lang Require Import prelude.
From Goose Require github_com.goose_lang.std.
From Goose Require github_com.mit_pdos.pav.advrpc.
From Goose Require github_com.mit_pdos.pav.cryptoffi.
From Goose Require github_com.mit_pdos.pav.kt.

Section code.
Context `{ext_ty: ext_types}.

(* test.go *)

Definition aliceUid : expr := #0.

Definition bobUid : expr := #1.

(* setupParams from testhelpers.go *)

Definition setupParams := struct.decl [
  "servAddr" :: uint64T;
  "servSigPk" :: cryptoffi.SigPublicKey;
  "servVrfPk" :: slice.T byteT;
  "adtrAddrs" :: slice.T uint64T;
  "adtrPks" :: slice.T cryptoffi.SigPublicKey
].

(* alice from test.go *)

Definition alice := struct.decl [
  "cli" :: ptrT;
  "hist" :: slice.T ptrT
].

Definition bob := struct.decl [
  "cli" :: ptrT;
  "epoch" :: uint64T;
  "isReg" :: boolT;
  "alicePk" :: slice.T byteT
].

Definition alice__run: val :=
  rec: "alice__run" "a" :=
    let: "i" := ref_to uint64T #0 in
    (for: (λ: <>, (![uint64T] "i") < #20); (λ: <>, "i" <-[uint64T] ((![uint64T] "i") + #1)) := λ: <>,
      time.Sleep #5000000;;
      let: "pk" := SliceSingleton #(U8 1) in
      let: ("epoch", "err0") := kt.Client__Put (struct.loadF alice "cli" "a") "pk" in
      control.impl.Assume (~ (struct.loadF kt.ClientErr "Err" "err0"));;
      struct.storeF alice "hist" "a" (SliceAppend ptrT (struct.loadF alice "hist" "a") (struct.new kt.HistEntry [
        "Epoch" ::= "epoch";
        "HistVal" ::= "pk"
      ]));;
      Continue);;
    #().

Definition bob__run: val :=
  rec: "bob__run" "b" :=
    time.Sleep #120000000;;
    let: ((("isReg", "pk"), "epoch"), "err0") := kt.Client__Get (struct.loadF bob "cli" "b") aliceUid in
    control.impl.Assume (~ (struct.loadF kt.ClientErr "Err" "err0"));;
    struct.storeF bob "epoch" "b" "epoch";;
    struct.storeF bob "isReg" "b" "isReg";;
    struct.storeF bob "alicePk" "b" "pk";;
    #().

(* mkRpcClients from testhelpers.go *)

Definition mkRpcClients: val :=
  rec: "mkRpcClients" "addrs" :=
    let: "c" := ref (zero_val (slice.T ptrT)) in
    ForSlice uint64T <> "addr" "addrs"
      (let: "cli" := advrpc.Dial "addr" in
      "c" <-[slice.T ptrT] (SliceAppend ptrT (![slice.T ptrT] "c") "cli"));;
    ![slice.T ptrT] "c".

Definition updAdtrsOnce: val :=
  rec: "updAdtrsOnce" "upd" "adtrs" :=
    ForSlice ptrT <> "cli" "adtrs"
      (let: "err" := kt.CallAdtrUpdate "cli" "upd" in
      control.impl.Assume (~ "err"));;
    #().

Definition updAdtrsAll: val :=
  rec: "updAdtrsAll" "servAddr" "adtrAddrs" :=
    let: "servCli" := advrpc.Dial "servAddr" in
    let: "adtrs" := mkRpcClients "adtrAddrs" in
    let: "epoch" := ref (zero_val uint64T) in
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: ("upd", "err") := kt.CallServAudit "servCli" (![uint64T] "epoch") in
      (if: "err"
      then Break
      else
        updAdtrsOnce "upd" "adtrs";;
        "epoch" <-[uint64T] ((![uint64T] "epoch") + #1);;
        Continue));;
    #().

Definition doAudits: val :=
  rec: "doAudits" "cli" "adtrAddrs" "adtrPks" :=
    let: "numAdtrs" := slice.len "adtrAddrs" in
    let: "i" := ref_to uint64T #0 in
    (for: (λ: <>, (![uint64T] "i") < "numAdtrs"); (λ: <>, "i" <-[uint64T] ((![uint64T] "i") + #1)) := λ: <>,
      let: "addr" := SliceGet uint64T "adtrAddrs" (![uint64T] "i") in
      let: "pk" := SliceGet cryptoffi.SigPublicKey "adtrPks" (![uint64T] "i") in
      let: "err" := kt.Client__Audit "cli" "addr" "pk" in
      control.impl.Assume (~ (struct.loadF kt.ClientErr "Err" "err"));;
      Continue);;
    #().

(* testAll from test.go *)

Definition testAll: val :=
  rec: "testAll" "setup" :=
    let: "aliceCli" := kt.NewClient aliceUid (struct.loadF setupParams "servAddr" "setup") (struct.loadF setupParams "servSigPk" "setup") (struct.loadF setupParams "servVrfPk" "setup") in
    let: "alice" := struct.new alice [
      "cli" ::= "aliceCli"
    ] in
    let: "bobCli" := kt.NewClient bobUid (struct.loadF setupParams "servAddr" "setup") (struct.loadF setupParams "servSigPk" "setup") (struct.loadF setupParams "servVrfPk" "setup") in
    let: "bob" := struct.new bob [
      "cli" ::= "bobCli"
    ] in
    let: "wg" := waitgroup.New #() in
    waitgroup.Add "wg" #1;;
    waitgroup.Add "wg" #1;;
    Fork (alice__run "alice";;
          waitgroup.Done "wg");;
    Fork (bob__run "bob";;
          waitgroup.Done "wg");;
    waitgroup.Wait "wg";;
    let: ("selfMonEp", "err0") := kt.Client__SelfMon (struct.loadF alice "cli" "alice") in
    control.impl.Assume (~ (struct.loadF kt.ClientErr "Err" "err0"));;
    control.impl.Assume ((struct.loadF bob "epoch" "bob") ≤ "selfMonEp");;
    updAdtrsAll (struct.loadF setupParams "servAddr" "setup") (struct.loadF setupParams "adtrAddrs" "setup");;
    doAudits (struct.loadF alice "cli" "alice") (struct.loadF setupParams "adtrAddrs" "setup") (struct.loadF setupParams "adtrPks" "setup");;
    doAudits (struct.loadF bob "cli" "bob") (struct.loadF setupParams "adtrAddrs" "setup") (struct.loadF setupParams "adtrPks" "setup");;
    let: ("isReg", "alicePk") := kt.GetHist (struct.loadF alice "hist" "alice") (struct.loadF bob "epoch" "bob") in
    control.impl.Assert ("isReg" = (struct.loadF bob "isReg" "bob"));;
    (if: "isReg"
    then
      control.impl.Assert (std.BytesEqual "alicePk" (struct.loadF bob "alicePk" "bob"));;
      #()
    else #()).

(* setup from testhelpers.go *)

(* setup starts server and auditors. it's mainly a logical convenience.
   it consolidates the external parties, letting us more easily describe
   different adversary configs. *)
Definition setup: val :=
  rec: "setup" "servAddr" "adtrAddrs" :=
    let: (("serv", "servSigPk"), "servVrfPk") := kt.NewServer #() in
    let: "servVrfPkEnc" := cryptoffi.VrfPublicKeyEncode "servVrfPk" in
    let: "servRpc" := kt.NewRpcServer "serv" in
    advrpc.Server__Serve "servRpc" "servAddr";;
    let: "adtrPks" := ref (zero_val (slice.T cryptoffi.SigPublicKey)) in
    ForSlice uint64T <> "adtrAddr" "adtrAddrs"
      (let: ("adtr", "adtrPk") := kt.NewAuditor #() in
      let: "adtrRpc" := kt.NewRpcAuditor "adtr" in
      advrpc.Server__Serve "adtrRpc" "adtrAddr";;
      "adtrPks" <-[slice.T cryptoffi.SigPublicKey] (SliceAppend cryptoffi.SigPublicKey (![slice.T cryptoffi.SigPublicKey] "adtrPks") "adtrPk"));;
    time.Sleep #1000000;;
    struct.new setupParams [
      "servAddr" ::= "servAddr";
      "servSigPk" ::= "servSigPk";
      "servVrfPk" ::= "servVrfPkEnc";
      "adtrAddrs" ::= "adtrAddrs";
      "adtrPks" ::= ![slice.T cryptoffi.SigPublicKey] "adtrPks"
    ].

Definition testAllFull: val :=
  rec: "testAllFull" "servAddr" "adtrAddrs" :=
    testAll (setup "servAddr" "adtrAddrs");;
    #().

(* testhelpers.go *)

End code.
