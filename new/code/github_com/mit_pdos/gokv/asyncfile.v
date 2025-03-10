(* autogenerated from github.com/mit-pdos/gokv/asyncfile *)
From New.golang Require Import defn.
Require Export New.code.github_com.goose_lang.std.
Require Export New.code.github_com.mit_pdos.gokv.grove_ffi.
Require Export New.code.sync.

Definition asyncfile : go_string := "github.com/mit-pdos/gokv/asyncfile".

From New Require Import grove_prelude.
Module asyncfile.
Section code.


Definition AsyncFile : go_type := structT [
  "mu" :: ptrT;
  "data" :: sliceT;
  "filename" :: stringT;
  "index" :: uint64T;
  "indexCond" :: ptrT;
  "durableIndex" :: uint64T;
  "durableIndexCond" :: ptrT;
  "closeRequested" :: boolT;
  "closed" :: boolT;
  "closedCond" :: ptrT
].

(* go: storage.go:24:21 *)
Definition AsyncFile__Write : val :=
  rec: "AsyncFile__Write" "s" "data" :=
    with_defer: (let: "s" := (ref_ty ptrT "s") in
    let: "data" := (ref_ty sliceT "data") in
    do:  ((method_call #sync #"Mutex'ptr" #"Lock" (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #());;;
    do:  (let: "$f" := (method_call #sync #"Mutex'ptr" #"Unlock" (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) in
    "$defer" <-[funcT] (let: "$oldf" := (![funcT] "$defer") in
    (λ: <>,
      "$f" #();;
      "$oldf" #()
      )));;;
    let: "$r0" := (![sliceT] "data") in
    do:  ((struct.field_ref AsyncFile "data" (![ptrT] "s")) <-[sliceT] "$r0");;;
    let: "$r0" := (let: "$a0" := (![uint64T] (struct.field_ref AsyncFile "index" (![ptrT] "s"))) in
    let: "$a1" := #(W64 1) in
    (func_call #std #"SumAssumeNoOverflow"%go) "$a0" "$a1") in
    do:  ((struct.field_ref AsyncFile "index" (![ptrT] "s")) <-[uint64T] "$r0");;;
    let: "index" := (ref_ty uint64T (zero_val uint64T)) in
    let: "$r0" := (![uint64T] (struct.field_ref AsyncFile "index" (![ptrT] "s"))) in
    do:  ("index" <-[uint64T] "$r0");;;
    do:  ((method_call #sync #"Cond'ptr" #"Signal" (![ptrT] (struct.field_ref AsyncFile "indexCond" (![ptrT] "s")))) #());;;
    return: ((λ: <>,
       exception_do (do:  (let: "$a0" := (![uint64T] "index") in
       (method_call #asyncfile.asyncfile #"AsyncFile'ptr" #"wait" (![ptrT] "s")) "$a0"))
       ))).

(* go: storage.go:36:21 *)
Definition AsyncFile__wait : val :=
  rec: "AsyncFile__wait" "s" "index" :=
    with_defer: (let: "s" := (ref_ty ptrT "s") in
    let: "index" := (ref_ty uint64T "index") in
    do:  ((method_call #sync #"Mutex'ptr" #"Lock" (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #());;;
    do:  (let: "$f" := (method_call #sync #"Mutex'ptr" #"Unlock" (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) in
    "$defer" <-[funcT] (let: "$oldf" := (![funcT] "$defer") in
    (λ: <>,
      "$f" #();;
      "$oldf" #()
      )));;;
    (for: (λ: <>, (![uint64T] (struct.field_ref AsyncFile "durableIndex" (![ptrT] "s"))) < (![uint64T] "index")); (λ: <>, Skip) := λ: <>,
      do:  ((method_call #sync #"Cond'ptr" #"Wait" (![ptrT] (struct.field_ref AsyncFile "durableIndexCond" (![ptrT] "s")))) #()))).

(* go: storage.go:45:21 *)
Definition AsyncFile__flushThread : val :=
  rec: "AsyncFile__flushThread" "s" <> :=
    exception_do (let: "s" := (ref_ty ptrT "s") in
    do:  ((method_call #sync #"Mutex'ptr" #"Lock" (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #());;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      (if: ![boolT] (struct.field_ref AsyncFile "closeRequested" (![ptrT] "s"))
      then
        do:  (let: "$a0" := (![stringT] (struct.field_ref AsyncFile "filename" (![ptrT] "s"))) in
        let: "$a1" := (![sliceT] (struct.field_ref AsyncFile "data" (![ptrT] "s"))) in
        (func_call #grove_ffi #"FileWrite"%go) "$a0" "$a1");;;
        let: "$r0" := (![uint64T] (struct.field_ref AsyncFile "index" (![ptrT] "s"))) in
        do:  ((struct.field_ref AsyncFile "durableIndex" (![ptrT] "s")) <-[uint64T] "$r0");;;
        do:  ((method_call #sync #"Cond'ptr" #"Broadcast" (![ptrT] (struct.field_ref AsyncFile "durableIndexCond" (![ptrT] "s")))) #());;;
        let: "$r0" := #true in
        do:  ((struct.field_ref AsyncFile "closed" (![ptrT] "s")) <-[boolT] "$r0");;;
        do:  ((method_call #sync #"Mutex'ptr" #"Unlock" (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #());;;
        do:  ((method_call #sync #"Cond'ptr" #"Signal" (![ptrT] (struct.field_ref AsyncFile "closedCond" (![ptrT] "s")))) #());;;
        return: (#())
      else do:  #());;;
      (if: (![uint64T] (struct.field_ref AsyncFile "durableIndex" (![ptrT] "s"))) ≥ (![uint64T] (struct.field_ref AsyncFile "index" (![ptrT] "s")))
      then
        do:  ((method_call #sync #"Cond'ptr" #"Wait" (![ptrT] (struct.field_ref AsyncFile "indexCond" (![ptrT] "s")))) #());;;
        continue: #()
      else do:  #());;;
      let: "index" := (ref_ty uint64T (zero_val uint64T)) in
      let: "$r0" := (![uint64T] (struct.field_ref AsyncFile "index" (![ptrT] "s"))) in
      do:  ("index" <-[uint64T] "$r0");;;
      let: "data" := (ref_ty sliceT (zero_val sliceT)) in
      let: "$r0" := (![sliceT] (struct.field_ref AsyncFile "data" (![ptrT] "s"))) in
      do:  ("data" <-[sliceT] "$r0");;;
      do:  ((method_call #sync #"Mutex'ptr" #"Unlock" (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #());;;
      do:  (let: "$a0" := (![stringT] (struct.field_ref AsyncFile "filename" (![ptrT] "s"))) in
      let: "$a1" := (![sliceT] "data") in
      (func_call #grove_ffi #"FileWrite"%go) "$a0" "$a1");;;
      do:  ((method_call #sync #"Mutex'ptr" #"Lock" (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #());;;
      let: "$r0" := (![uint64T] "index") in
      do:  ((struct.field_ref AsyncFile "durableIndex" (![ptrT] "s")) <-[uint64T] "$r0");;;
      do:  ((method_call #sync #"Cond'ptr" #"Broadcast" (![ptrT] (struct.field_ref AsyncFile "durableIndexCond" (![ptrT] "s")))) #()))).

(* go: storage.go:73:21 *)
Definition AsyncFile__Close : val :=
  rec: "AsyncFile__Close" "s" <> :=
    with_defer: (let: "s" := (ref_ty ptrT "s") in
    do:  ((method_call #sync #"Mutex'ptr" #"Lock" (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #());;;
    do:  (let: "$f" := (method_call #sync #"Mutex'ptr" #"Unlock" (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) in
    "$defer" <-[funcT] (let: "$oldf" := (![funcT] "$defer") in
    (λ: <>,
      "$f" #();;
      "$oldf" #()
      )));;;
    let: "$r0" := #true in
    do:  ((struct.field_ref AsyncFile "closeRequested" (![ptrT] "s")) <-[boolT] "$r0");;;
    do:  ((method_call #sync #"Cond'ptr" #"Signal" (![ptrT] (struct.field_ref AsyncFile "indexCond" (![ptrT] "s")))) #());;;
    (for: (λ: <>, (~ (![boolT] (struct.field_ref AsyncFile "closed" (![ptrT] "s"))))); (λ: <>, Skip) := λ: <>,
      do:  ((method_call #sync #"Cond'ptr" #"Wait" (![ptrT] (struct.field_ref AsyncFile "closedCond" (![ptrT] "s")))) #()))).

(* returns the state, then the File object

   go: storage.go:85:6 *)
Definition MakeAsyncFile : val :=
  rec: "MakeAsyncFile" "filename" :=
    exception_do (let: "filename" := (ref_ty stringT "filename") in
    let: "mu" := (ref_ty sync.Mutex (zero_val sync.Mutex)) in
    let: "s" := (ref_ty ptrT (zero_val ptrT)) in
    let: "$r0" := (ref_ty AsyncFile (let: "$mu" := "mu" in
    let: "$indexCond" := (let: "$a0" := (interface.make #sync #"Mutex'ptr" "mu") in
    (func_call #sync #"NewCond"%go) "$a0") in
    let: "$closedCond" := (let: "$a0" := (interface.make #sync #"Mutex'ptr" "mu") in
    (func_call #sync #"NewCond"%go) "$a0") in
    let: "$durableIndexCond" := (let: "$a0" := (interface.make #sync #"Mutex'ptr" "mu") in
    (func_call #sync #"NewCond"%go) "$a0") in
    let: "$filename" := (![stringT] "filename") in
    let: "$data" := (let: "$a0" := (![stringT] "filename") in
    (func_call #grove_ffi #"FileRead"%go) "$a0") in
    let: "$index" := #(W64 0) in
    let: "$durableIndex" := #(W64 0) in
    let: "$closed" := #false in
    let: "$closeRequested" := #false in
    struct.make AsyncFile [{
      "mu" ::= "$mu";
      "data" ::= "$data";
      "filename" ::= "$filename";
      "index" ::= "$index";
      "indexCond" ::= "$indexCond";
      "durableIndex" ::= "$durableIndex";
      "durableIndexCond" ::= "$durableIndexCond";
      "closeRequested" ::= "$closeRequested";
      "closed" ::= "$closed";
      "closedCond" ::= "$closedCond"
    }])) in
    do:  ("s" <-[ptrT] "$r0");;;
    let: "data" := (ref_ty sliceT (zero_val sliceT)) in
    let: "$r0" := (![sliceT] (struct.field_ref AsyncFile "data" (![ptrT] "s"))) in
    do:  ("data" <-[sliceT] "$r0");;;
    let: "$go" := (method_call #asyncfile.asyncfile #"AsyncFile'ptr" #"flushThread" (![ptrT] "s")) in
    do:  (Fork ("$go" #()));;;
    return: (![sliceT] "data", ![ptrT] "s")).

Definition vars' : list (go_string * go_type) := [].

Definition functions' : list (go_string * val) := [("MakeAsyncFile"%go, MakeAsyncFile)].

Definition msets' : list (go_string * (list (go_string * val))) := [("AsyncFile"%go, []); ("AsyncFile'ptr"%go, [("Close"%go, AsyncFile__Close); ("Write"%go, AsyncFile__Write); ("flushThread"%go, AsyncFile__flushThread); ("wait"%go, AsyncFile__wait)])].

#[global] Instance info' : PkgInfo asyncfile.asyncfile :=
  {|
    pkg_vars := vars';
    pkg_functions := functions';
    pkg_msets := msets';
    pkg_imported_pkgs := [sync; std; grove_ffi];
  |}.

Definition initialize' : val :=
  rec: "initialize'" <> :=
    globals.package_init asyncfile.asyncfile (λ: <>,
      exception_do (do:  grove_ffi.initialize';;;
      do:  std.initialize';;;
      do:  sync.initialize')
      ).

End code.
End asyncfile.
