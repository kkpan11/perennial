(* autogenerated from github.com/mit-pdos/gokv/cachekv *)
From New.golang Require Import defn.
Require Export New.code.github_com.mit_pdos.gokv.grove_ffi.
Require Export New.code.github_com.mit_pdos.gokv.kv.
Require Export New.code.github_com.tchajed.marshal.
Require Export New.code.sync.

Definition cachekv : go_string := "github.com/mit-pdos/gokv/cachekv".

From New Require Import grove_prelude.
Module cachekv.
Section code.


Definition cacheValue : go_type := structT [
  "v" :: stringT;
  "l" :: uint64T
].

Definition CacheKv : go_type := structT [
  "kv" :: kv.KvCput;
  "mu" :: ptrT;
  "cache" :: mapT stringT cacheValue
].

(* go: clerk.go:24:6 *)
Definition DecodeValue : val :=
  rec: "DecodeValue" "v" :=
    exception_do (let: "v" := (mem.alloc "v") in
    let: "e" := (mem.alloc (type.zero_val #sliceT)) in
    let: "$r0" := (string.to_bytes (![#stringT] "v")) in
    do:  ("e" <-[#sliceT] "$r0");;;
    let: "vBytes" := (mem.alloc (type.zero_val #sliceT)) in
    let: "l" := (mem.alloc (type.zero_val #uint64T)) in
    let: ("$ret0", "$ret1") := (let: "$a0" := (![#sliceT] "e") in
    (func_call #marshal.marshal #"ReadInt"%go) "$a0") in
    let: "$r0" := "$ret0" in
    let: "$r1" := "$ret1" in
    do:  ("l" <-[#uint64T] "$r0");;;
    do:  ("vBytes" <-[#sliceT] "$r1");;;
    return: (let: "$l" := (![#uint64T] "l") in
     let: "$v" := (string.from_bytes (![#sliceT] "vBytes")) in
     struct.make #cacheValue [{
       "v" ::= "$v";
       "l" ::= "$l"
     }])).

(* go: clerk.go:33:6 *)
Definition EncodeValue : val :=
  rec: "EncodeValue" "c" :=
    exception_do (let: "c" := (mem.alloc "c") in
    let: "e" := (mem.alloc (type.zero_val #sliceT)) in
    let: "$r0" := (slice.make2 #byteT #(W64 0)) in
    do:  ("e" <-[#sliceT] "$r0");;;
    let: "$r0" := (let: "$a0" := (![#sliceT] "e") in
    let: "$a1" := (![#uint64T] (struct.field_ref #cacheValue #"l"%go "c")) in
    (func_call #marshal.marshal #"WriteInt"%go) "$a0" "$a1") in
    do:  ("e" <-[#sliceT] "$r0");;;
    let: "$r0" := (let: "$a0" := (![#sliceT] "e") in
    let: "$a1" := (string.to_bytes (![#stringT] (struct.field_ref #cacheValue #"v"%go "c"))) in
    (func_call #marshal.marshal #"WriteBytes"%go) "$a0" "$a1") in
    do:  ("e" <-[#sliceT] "$r0");;;
    return: (string.from_bytes (![#sliceT] "e"))).

(* go: clerk.go:40:6 *)
Definition max : val :=
  rec: "max" "a" "b" :=
    exception_do (let: "b" := (mem.alloc "b") in
    let: "a" := (mem.alloc "a") in
    (if: (![#uint64T] "a") > (![#uint64T] "b")
    then return: (![#uint64T] "a")
    else do:  #());;;
    return: (![#uint64T] "b")).

(* go: clerk.go:47:6 *)
Definition Make : val :=
  rec: "Make" "kv" :=
    exception_do (let: "kv" := (mem.alloc "kv") in
    return: (mem.alloc (let: "$kv" := (![#kv.KvCput] "kv") in
     let: "$mu" := (mem.alloc (type.zero_val #sync.Mutex)) in
     let: "$cache" := (map.make #stringT #cacheValue) in
     struct.make #CacheKv [{
       "kv" ::= "$kv";
       "mu" ::= "$mu";
       "cache" ::= "$cache"
     }]))).

(* go: clerk.go:55:19 *)
Definition CacheKv__Get : val :=
  rec: "CacheKv__Get" "k" "key" :=
    exception_do (let: "k" := (mem.alloc "k") in
    let: "key" := (mem.alloc "key") in
    do:  ((method_call #sync #"Mutex'ptr" #"Lock" (![#ptrT] (struct.field_ref #CacheKv #"mu"%go (![#ptrT] "k")))) #());;;
    let: "ok" := (mem.alloc (type.zero_val #boolT)) in
    let: "cv" := (mem.alloc (type.zero_val #cacheValue)) in
    let: ("$ret0", "$ret1") := (map.get (![type.mapT #stringT #cacheValue] (struct.field_ref #CacheKv #"cache"%go (![#ptrT] "k"))) (![#stringT] "key")) in
    let: "$r0" := "$ret0" in
    let: "$r1" := "$ret1" in
    do:  ("cv" <-[#cacheValue] "$r0");;;
    do:  ("ok" <-[#boolT] "$r1");;;
    let: "high" := (mem.alloc (type.zero_val #uint64T)) in
    let: ("$ret0", "$ret1") := ((func_call #grove_ffi.grove_ffi #"GetTimeRange"%go) #()) in
    let: "$r0" := "$ret0" in
    let: "$r1" := "$ret1" in
    do:  "$r0";;;
    do:  ("high" <-[#uint64T] "$r1");;;
    (if: (![#boolT] "ok") && ((![#uint64T] "high") < (![#uint64T] (struct.field_ref #cacheValue #"l"%go "cv")))
    then
      do:  ((method_call #sync #"Mutex'ptr" #"Unlock" (![#ptrT] (struct.field_ref #CacheKv #"mu"%go (![#ptrT] "k")))) #());;;
      return: (![#stringT] (struct.field_ref #cacheValue #"v"%go "cv"))
    else do:  #());;;
    do:  (let: "$a0" := (![type.mapT #stringT #cacheValue] (struct.field_ref #CacheKv #"cache"%go (![#ptrT] "k"))) in
    let: "$a1" := (![#stringT] "key") in
    map.delete "$a0" "$a1");;;
    do:  ((method_call #sync #"Mutex'ptr" #"Unlock" (![#ptrT] (struct.field_ref #CacheKv #"mu"%go (![#ptrT] "k")))) #());;;
    return: (struct.field_get #cacheValue "v" (let: "$a0" := (let: "$a0" := (![#stringT] "key") in
     (interface.get #"Get"%go (![#kv.KvCput] (struct.field_ref #CacheKv #"kv"%go (![#ptrT] "k")))) "$a0") in
     (func_call #cachekv.cachekv #"DecodeValue"%go) "$a0"))).

(* go: clerk.go:69:19 *)
Definition CacheKv__GetAndCache : val :=
  rec: "CacheKv__GetAndCache" "k" "key" "cachetime" :=
    exception_do (let: "k" := (mem.alloc "k") in
    let: "cachetime" := (mem.alloc "cachetime") in
    let: "key" := (mem.alloc "key") in
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "enc" := (mem.alloc (type.zero_val #stringT)) in
      let: "$r0" := (let: "$a0" := (![#stringT] "key") in
      (interface.get #"Get"%go (![#kv.KvCput] (struct.field_ref #CacheKv #"kv"%go (![#ptrT] "k")))) "$a0") in
      do:  ("enc" <-[#stringT] "$r0");;;
      let: "old" := (mem.alloc (type.zero_val #cacheValue)) in
      let: "$r0" := (let: "$a0" := (![#stringT] "enc") in
      (func_call #cachekv.cachekv #"DecodeValue"%go) "$a0") in
      do:  ("old" <-[#cacheValue] "$r0");;;
      let: "latest" := (mem.alloc (type.zero_val #uint64T)) in
      let: ("$ret0", "$ret1") := ((func_call #grove_ffi.grove_ffi #"GetTimeRange"%go) #()) in
      let: "$r0" := "$ret0" in
      let: "$r1" := "$ret1" in
      do:  "$r0";;;
      do:  ("latest" <-[#uint64T] "$r1");;;
      let: "newLeaseExpiration" := (mem.alloc (type.zero_val #uint64T)) in
      let: "$r0" := (let: "$a0" := ((![#uint64T] "latest") + (![#uint64T] "cachetime")) in
      let: "$a1" := (![#uint64T] (struct.field_ref #cacheValue #"l"%go "old")) in
      (func_call #cachekv.cachekv #"max"%go) "$a0" "$a1") in
      do:  ("newLeaseExpiration" <-[#uint64T] "$r0");;;
      let: "resp" := (mem.alloc (type.zero_val #stringT)) in
      let: "$r0" := (let: "$a0" := (![#stringT] "key") in
      let: "$a1" := (![#stringT] "enc") in
      let: "$a2" := (let: "$a0" := (let: "$v" := (![#stringT] (struct.field_ref #cacheValue #"v"%go "old")) in
      let: "$l" := (![#uint64T] "newLeaseExpiration") in
      struct.make #cacheValue [{
        "v" ::= "$v";
        "l" ::= "$l"
      }]) in
      (func_call #cachekv.cachekv #"EncodeValue"%go) "$a0") in
      (interface.get #"ConditionalPut"%go (![#kv.KvCput] (struct.field_ref #CacheKv #"kv"%go (![#ptrT] "k")))) "$a0" "$a1" "$a2") in
      do:  ("resp" <-[#stringT] "$r0");;;
      (if: (![#stringT] "resp") = #"ok"%go
      then
        do:  ((method_call #sync #"Mutex'ptr" #"Lock" (![#ptrT] (struct.field_ref #CacheKv #"mu"%go (![#ptrT] "k")))) #());;;
        let: "$r0" := (let: "$v" := (![#stringT] (struct.field_ref #cacheValue #"v"%go "old")) in
        let: "$l" := (![#uint64T] "newLeaseExpiration") in
        struct.make #cacheValue [{
          "v" ::= "$v";
          "l" ::= "$l"
        }]) in
        do:  (map.insert (![type.mapT #stringT #cacheValue] (struct.field_ref #CacheKv #"cache"%go (![#ptrT] "k"))) (![#stringT] "key") "$r0");;;
        break: #()
      else do:  #()));;;
    let: "ret" := (mem.alloc (type.zero_val #stringT)) in
    let: "$r0" := (struct.field_get #cacheValue "v" (Fst (map.get (![type.mapT #stringT #cacheValue] (struct.field_ref #CacheKv #"cache"%go (![#ptrT] "k"))) (![#stringT] "key")))) in
    do:  ("ret" <-[#stringT] "$r0");;;
    do:  ((method_call #sync #"Mutex'ptr" #"Unlock" (![#ptrT] (struct.field_ref #CacheKv #"mu"%go (![#ptrT] "k")))) #());;;
    return: (![#stringT] "ret")).

(* go: clerk.go:90:19 *)
Definition CacheKv__Put : val :=
  rec: "CacheKv__Put" "k" "key" "val" :=
    exception_do (let: "k" := (mem.alloc "k") in
    let: "val" := (mem.alloc "val") in
    let: "key" := (mem.alloc "key") in
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "enc" := (mem.alloc (type.zero_val #stringT)) in
      let: "$r0" := (let: "$a0" := (![#stringT] "key") in
      (interface.get #"Get"%go (![#kv.KvCput] (struct.field_ref #CacheKv #"kv"%go (![#ptrT] "k")))) "$a0") in
      do:  ("enc" <-[#stringT] "$r0");;;
      let: "leaseExpiration" := (mem.alloc (type.zero_val #uint64T)) in
      let: "$r0" := (struct.field_get #cacheValue "l" (let: "$a0" := (![#stringT] "enc") in
      (func_call #cachekv.cachekv #"DecodeValue"%go) "$a0")) in
      do:  ("leaseExpiration" <-[#uint64T] "$r0");;;
      let: "earliest" := (mem.alloc (type.zero_val #uint64T)) in
      let: ("$ret0", "$ret1") := ((func_call #grove_ffi.grove_ffi #"GetTimeRange"%go) #()) in
      let: "$r0" := "$ret0" in
      let: "$r1" := "$ret1" in
      do:  ("earliest" <-[#uint64T] "$r0");;;
      do:  "$r1";;;
      (if: (![#uint64T] "leaseExpiration") > (![#uint64T] "earliest")
      then continue: #()
      else do:  #());;;
      let: "resp" := (mem.alloc (type.zero_val #stringT)) in
      let: "$r0" := (let: "$a0" := (![#stringT] "key") in
      let: "$a1" := (![#stringT] "enc") in
      let: "$a2" := (let: "$a0" := (let: "$v" := (![#stringT] "val") in
      let: "$l" := #(W64 0) in
      struct.make #cacheValue [{
        "v" ::= "$v";
        "l" ::= "$l"
      }]) in
      (func_call #cachekv.cachekv #"EncodeValue"%go) "$a0") in
      (interface.get #"ConditionalPut"%go (![#kv.KvCput] (struct.field_ref #CacheKv #"kv"%go (![#ptrT] "k")))) "$a0" "$a1" "$a2") in
      do:  ("resp" <-[#stringT] "$r0");;;
      (if: (![#stringT] "resp") = #"ok"%go
      then break: #()
      else do:  #()));;;
    return: #()).

Definition vars' : list (go_string * go_type) := [].

Definition functions' : list (go_string * val) := [("DecodeValue"%go, DecodeValue); ("EncodeValue"%go, EncodeValue); ("max"%go, max); ("Make"%go, Make)].

Definition msets' : list (go_string * (list (go_string * val))) := [("cacheValue"%go, []); ("cacheValue'ptr"%go, []); ("CacheKv"%go, []); ("CacheKv'ptr"%go, [("Get"%go, CacheKv__Get); ("GetAndCache"%go, CacheKv__GetAndCache); ("Put"%go, CacheKv__Put)])].

#[global] Instance info' : PkgInfo cachekv.cachekv :=
  {|
    pkg_vars := vars';
    pkg_functions := functions';
    pkg_msets := msets';
    pkg_imported_pkgs := [sync.sync; grove_ffi.grove_ffi; kv.kv; marshal.marshal];
  |}.

Definition initialize' : val :=
  rec: "initialize'" <> :=
    globals.package_init cachekv.cachekv (λ: <>,
      exception_do (do:  marshal.initialize';;;
      do:  kv.initialize';;;
      do:  grove_ffi.initialize';;;
      do:  sync.initialize')
      ).

End code.
End cachekv.
