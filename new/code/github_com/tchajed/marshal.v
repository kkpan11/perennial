(* autogenerated from github.com/tchajed/marshal *)
From New.golang Require Import defn.
From New.code Require github_com.goose_lang.primitive.
From New.code Require github_com.goose_lang.std.

Section code.
Context `{ffi_syntax}.

Definition Enc : go_type := structT [
  "b" :: sliceT byteT;
  "off" :: ptrT
]%struct.

(* go: marshal.go:63:16 *)
Definition Enc__Finish : val :=
  rec: "Enc__Finish" "enc" <> :=
    exception_do (let: "enc" := (ref_ty Enc "enc") in
    return: (![sliceT byteT] (struct.field_ref Enc "b" "enc"))).

(* go: marshal.go:49:6 *)
Definition bool2byte : val :=
  rec: "bool2byte" "b" :=
    exception_do (let: "b" := (ref_ty boolT "b") in
    (if: ![boolT] "b"
    then return: (#(U8 1))
    else return: (#(U8 0)))).

(* go: marshal.go:57:16 *)
Definition Enc__PutBool : val :=
  rec: "Enc__PutBool" "enc" "b" :=
    exception_do (let: "enc" := (ref_ty Enc "enc") in
    let: "b" := (ref_ty boolT "b") in
    let: "off" := (ref_ty uint64T (zero_val uint64T)) in
    let: "$r0" := (![uint64T] (![ptrT] (struct.field_ref Enc "off" "enc"))) in
    do:  ("off" <-[uint64T] "$r0");;;
    let: "$r0" := (let: "$a0" := (![boolT] "b") in
    bool2byte "$a0") in
    do:  ((slice.elem_ref byteT (![sliceT byteT] (struct.field_ref Enc "b" "enc")) (![uint64T] "off")) <-[byteT] "$r0");;;
    do:  ((![ptrT] (struct.field_ref Enc "off" "enc")) <-[uint64T] ((![uint64T] (![ptrT] (struct.field_ref Enc "off" "enc"))) + #1))).

(* go: marshal.go:43:16 *)
Definition Enc__PutBytes : val :=
  rec: "Enc__PutBytes" "enc" "b" :=
    exception_do (let: "enc" := (ref_ty Enc "enc") in
    let: "b" := (ref_ty (sliceT byteT) "b") in
    let: "off" := (ref_ty uint64T (zero_val uint64T)) in
    let: "$r0" := (![uint64T] (![ptrT] (struct.field_ref Enc "off" "enc"))) in
    do:  ("off" <-[uint64T] "$r0");;;
    let: "n" := (ref_ty uint64T (zero_val uint64T)) in
    let: "$r0" := (let: "$a0" := (let: "$s" := (![sliceT byteT] (struct.field_ref Enc "b" "enc")) in
    slice.slice byteT "$s" (![uint64T] "off") (slice.len "$s")) in
    let: "$a1" := (![sliceT byteT] "b") in
    (slice.copy byteT) "$a0" "$a1") in
    do:  ("n" <-[uint64T] "$r0");;;
    do:  ((![ptrT] (struct.field_ref Enc "off" "enc")) <-[uint64T] ((![uint64T] (![ptrT] (struct.field_ref Enc "off" "enc"))) + (![uint64T] "n")))).

(* go: marshal.go:25:16 *)
Definition Enc__PutInt : val :=
  rec: "Enc__PutInt" "enc" "x" :=
    exception_do (let: "enc" := (ref_ty Enc "enc") in
    let: "x" := (ref_ty uint64T "x") in
    let: "off" := (ref_ty uint64T (zero_val uint64T)) in
    let: "$r0" := (![uint64T] (![ptrT] (struct.field_ref Enc "off" "enc"))) in
    do:  ("off" <-[uint64T] "$r0");;;
    do:  (let: "$a0" := (let: "$s" := (![sliceT byteT] (struct.field_ref Enc "b" "enc")) in
    slice.slice byteT "$s" (![uint64T] "off") (slice.len "$s")) in
    let: "$a1" := (![uint64T] "x") in
    primitive.UInt64Put "$a0" "$a1");;;
    do:  ((![ptrT] (struct.field_ref Enc "off" "enc")) <-[uint64T] ((![uint64T] (![ptrT] (struct.field_ref Enc "off" "enc"))) + #8))).

(* go: marshal.go:31:16 *)
Definition Enc__PutInt32 : val :=
  rec: "Enc__PutInt32" "enc" "x" :=
    exception_do (let: "enc" := (ref_ty Enc "enc") in
    let: "x" := (ref_ty uint32T "x") in
    let: "off" := (ref_ty uint64T (zero_val uint64T)) in
    let: "$r0" := (![uint64T] (![ptrT] (struct.field_ref Enc "off" "enc"))) in
    do:  ("off" <-[uint64T] "$r0");;;
    do:  (let: "$a0" := (let: "$s" := (![sliceT byteT] (struct.field_ref Enc "b" "enc")) in
    slice.slice byteT "$s" (![uint64T] "off") (slice.len "$s")) in
    let: "$a1" := (![uint32T] "x") in
    primitive.UInt32Put "$a0" "$a1");;;
    do:  ((![ptrT] (struct.field_ref Enc "off" "enc")) <-[uint64T] ((![uint64T] (![ptrT] (struct.field_ref Enc "off" "enc"))) + #4))).

(* go: marshal.go:37:16 *)
Definition Enc__PutInts : val :=
  rec: "Enc__PutInts" "enc" "xs" :=
    exception_do (let: "enc" := (ref_ty Enc "enc") in
    let: "xs" := (ref_ty (sliceT uint64T) "xs") in
    do:  (let: "$range" := (![sliceT uint64T] "xs") in
    slice.for_range uint64T "$range" (λ: <> "x",
      let: "x" := ref_ty uint64T "x" in
      do:  (let: "$a0" := (![uint64T] "x") in
      (Enc__PutInt (![Enc] "enc")) "$a0")))).

Definition Enc__mset : list (string * val) := [
  ("Finish", Enc__Finish%V);
  ("PutBool", Enc__PutBool%V);
  ("PutBytes", Enc__PutBytes%V);
  ("PutInt", Enc__PutInt%V);
  ("PutInt32", Enc__PutInt32%V);
  ("PutInts", Enc__PutInts%V)
].

Definition Enc__mset_ptr : list (string * val) := [
  ("Finish", (λ: "$recvAddr",
    Enc__Finish (![Enc] "$recvAddr")
    )%V);
  ("PutBool", (λ: "$recvAddr",
    Enc__PutBool (![Enc] "$recvAddr")
    )%V);
  ("PutBytes", (λ: "$recvAddr",
    Enc__PutBytes (![Enc] "$recvAddr")
    )%V);
  ("PutInt", (λ: "$recvAddr",
    Enc__PutInt (![Enc] "$recvAddr")
    )%V);
  ("PutInt32", (λ: "$recvAddr",
    Enc__PutInt32 (![Enc] "$recvAddr")
    )%V);
  ("PutInts", (λ: "$recvAddr",
    Enc__PutInts (![Enc] "$recvAddr")
    )%V)
].

(* go: marshal.go:13:6 *)
Definition NewEncFromSlice : val :=
  rec: "NewEncFromSlice" "b" :=
    exception_do (let: "b" := (ref_ty (sliceT byteT) "b") in
    return: (struct.make Enc [{
       "b" ::= ![sliceT byteT] "b";
       "off" ::= ref_ty uint64T (zero_val uint64T)
     }])).

(* go: marshal.go:20:6 *)
Definition NewEnc : val :=
  rec: "NewEnc" "sz" :=
    exception_do (let: "sz" := (ref_ty uint64T "sz") in
    let: "b" := (ref_ty (sliceT byteT) (zero_val (sliceT byteT))) in
    let: "$r0" := (slice.make2 byteT (![uint64T] "sz")) in
    do:  ("b" <-[sliceT byteT] "$r0");;;
    return: (let: "$a0" := (![sliceT byteT] "b") in
     NewEncFromSlice "$a0")).

Definition Dec : go_type := structT [
  "b" :: sliceT byteT;
  "off" :: ptrT
]%struct.

(* go: marshal.go:105:16 *)
Definition Dec__GetBool : val :=
  rec: "Dec__GetBool" "dec" <> :=
    exception_do (let: "dec" := (ref_ty Dec "dec") in
    let: "off" := (ref_ty uint64T (zero_val uint64T)) in
    let: "$r0" := (![uint64T] (![ptrT] (struct.field_ref Dec "off" "dec"))) in
    do:  ("off" <-[uint64T] "$r0");;;
    do:  ((![ptrT] (struct.field_ref Dec "off" "dec")) <-[uint64T] ((![uint64T] (![ptrT] (struct.field_ref Dec "off" "dec"))) + #1));;;
    (if: (![byteT] (slice.elem_ref byteT (![sliceT byteT] (struct.field_ref Dec "b" "dec")) (![uint64T] "off"))) = #(U8 0)
    then return: (#false)
    else return: (#true))).

(* go: marshal.go:98:16 *)
Definition Dec__GetBytes : val :=
  rec: "Dec__GetBytes" "dec" "num" :=
    exception_do (let: "dec" := (ref_ty Dec "dec") in
    let: "num" := (ref_ty uint64T "num") in
    let: "off" := (ref_ty uint64T (zero_val uint64T)) in
    let: "$r0" := (![uint64T] (![ptrT] (struct.field_ref Dec "off" "dec"))) in
    do:  ("off" <-[uint64T] "$r0");;;
    let: "b" := (ref_ty (sliceT byteT) (zero_val (sliceT byteT))) in
    let: "$r0" := (let: "$s" := (![sliceT byteT] (struct.field_ref Dec "b" "dec")) in
    slice.slice byteT "$s" (![uint64T] "off") ((![uint64T] "off") + (![uint64T] "num"))) in
    do:  ("b" <-[sliceT byteT] "$r0");;;
    do:  ((![ptrT] (struct.field_ref Dec "off" "dec")) <-[uint64T] ((![uint64T] (![ptrT] (struct.field_ref Dec "off" "dec"))) + (![uint64T] "num")));;;
    return: (![sliceT byteT] "b")).

(* go: marshal.go:78:16 *)
Definition Dec__GetInt : val :=
  rec: "Dec__GetInt" "dec" <> :=
    exception_do (let: "dec" := (ref_ty Dec "dec") in
    let: "off" := (ref_ty uint64T (zero_val uint64T)) in
    let: "$r0" := (![uint64T] (![ptrT] (struct.field_ref Dec "off" "dec"))) in
    do:  ("off" <-[uint64T] "$r0");;;
    do:  ((![ptrT] (struct.field_ref Dec "off" "dec")) <-[uint64T] ((![uint64T] (![ptrT] (struct.field_ref Dec "off" "dec"))) + #8));;;
    return: (let: "$a0" := (let: "$s" := (![sliceT byteT] (struct.field_ref Dec "b" "dec")) in
     slice.slice byteT "$s" (![uint64T] "off") (slice.len "$s")) in
     primitive.UInt64Get "$a0")).

(* go: marshal.go:84:16 *)
Definition Dec__GetInt32 : val :=
  rec: "Dec__GetInt32" "dec" <> :=
    exception_do (let: "dec" := (ref_ty Dec "dec") in
    let: "off" := (ref_ty uint64T (zero_val uint64T)) in
    let: "$r0" := (![uint64T] (![ptrT] (struct.field_ref Dec "off" "dec"))) in
    do:  ("off" <-[uint64T] "$r0");;;
    do:  ((![ptrT] (struct.field_ref Dec "off" "dec")) <-[uint64T] ((![uint64T] (![ptrT] (struct.field_ref Dec "off" "dec"))) + #4));;;
    return: (let: "$a0" := (let: "$s" := (![sliceT byteT] (struct.field_ref Dec "b" "dec")) in
     slice.slice byteT "$s" (![uint64T] "off") (slice.len "$s")) in
     primitive.UInt32Get "$a0")).

(* go: marshal.go:90:16 *)
Definition Dec__GetInts : val :=
  rec: "Dec__GetInts" "dec" "num" :=
    exception_do (let: "dec" := (ref_ty Dec "dec") in
    let: "num" := (ref_ty uint64T "num") in
    let: "xs" := (ref_ty (sliceT uint64T) (zero_val (sliceT uint64T))) in
    (let: "i" := (ref_ty uint64T (zero_val uint64T)) in
    let: "$r0" := #0 in
    do:  ("i" <-[uint64T] "$r0");;;
    (for: (λ: <>, (![uint64T] "i") < (![uint64T] "num")); (λ: <>, do:  ("i" <-[uint64T] ((![uint64T] "i") + #1))) := λ: <>,
      let: "$r0" := (let: "$a0" := (![sliceT uint64T] "xs") in
      let: "$a1" := ((let: "$sl0" := ((Dec__GetInt (![Dec] "dec")) #()) in
      slice.literal uint64T ["$sl0"])) in
      (slice.append (sliceT uint64T)) "$a0" "$a1") in
      do:  ("xs" <-[sliceT uint64T] "$r0")));;;
    return: (![sliceT uint64T] "xs")).

Definition Dec__mset : list (string * val) := [
  ("GetBool", Dec__GetBool%V);
  ("GetBytes", Dec__GetBytes%V);
  ("GetInt", Dec__GetInt%V);
  ("GetInt32", Dec__GetInt32%V);
  ("GetInts", Dec__GetInts%V)
].

Definition Dec__mset_ptr : list (string * val) := [
  ("GetBool", (λ: "$recvAddr",
    Dec__GetBool (![Dec] "$recvAddr")
    )%V);
  ("GetBytes", (λ: "$recvAddr",
    Dec__GetBytes (![Dec] "$recvAddr")
    )%V);
  ("GetInt", (λ: "$recvAddr",
    Dec__GetInt (![Dec] "$recvAddr")
    )%V);
  ("GetInt32", (λ: "$recvAddr",
    Dec__GetInt32 (![Dec] "$recvAddr")
    )%V);
  ("GetInts", (λ: "$recvAddr",
    Dec__GetInts (![Dec] "$recvAddr")
    )%V)
].

(* go: marshal.go:74:6 *)
Definition NewDec : val :=
  rec: "NewDec" "b" :=
    exception_do (let: "b" := (ref_ty (sliceT byteT) "b") in
    return: (struct.make Dec [{
       "b" ::= ![sliceT byteT] "b";
       "off" ::= ref_ty uint64T (zero_val uint64T)
     }])).

(* go: stateless.go:8:6 *)
Definition compute_new_cap : val :=
  rec: "compute_new_cap" "old_cap" "min_cap" :=
    exception_do (let: "min_cap" := (ref_ty uint64T "min_cap") in
    let: "old_cap" := (ref_ty uint64T "old_cap") in
    let: "new_cap" := (ref_ty uint64T ((![uint64T] "old_cap") * #2)) in
    (if: (![uint64T] "new_cap") < (![uint64T] "min_cap")
    then
      let: "$r0" := (![uint64T] "min_cap") in
      do:  ("new_cap" <-[uint64T] "$r0")
    else do:  #());;;
    return: (![uint64T] "new_cap")).

(* Grow a slice to have at least `additional` unused bytes in the capacity.
   Runtime-check against overflow.

   go: stateless.go:19:6 *)
Definition reserve : val :=
  rec: "reserve" "b" "additional" :=
    exception_do (let: "additional" := (ref_ty uint64T "additional") in
    let: "b" := (ref_ty (sliceT byteT) "b") in
    let: "min_cap" := (ref_ty uint64T (zero_val uint64T)) in
    let: "$r0" := (let: "$a0" := (let: "$a0" := (![sliceT byteT] "b") in
    slice.len "$a0") in
    let: "$a1" := (![uint64T] "additional") in
    std.SumAssumeNoOverflow "$a0" "$a1") in
    do:  ("min_cap" <-[uint64T] "$r0");;;
    (if: (let: "$a0" := (![sliceT byteT] "b") in
    slice.cap "$a0") < (![uint64T] "min_cap")
    then
      let: "new_cap" := (ref_ty uint64T (zero_val uint64T)) in
      let: "$r0" := (let: "$a0" := (let: "$a0" := (![sliceT byteT] "b") in
      slice.cap "$a0") in
      let: "$a1" := (![uint64T] "min_cap") in
      compute_new_cap "$a0" "$a1") in
      do:  ("new_cap" <-[uint64T] "$r0");;;
      let: "dest" := (ref_ty (sliceT byteT) (zero_val (sliceT byteT))) in
      let: "$r0" := (slice.make3 byteT (let: "$a0" := (![sliceT byteT] "b") in
      slice.len "$a0") (![uint64T] "new_cap")) in
      do:  ("dest" <-[sliceT byteT] "$r0");;;
      do:  (let: "$a0" := (![sliceT byteT] "dest") in
      let: "$a1" := (![sliceT byteT] "b") in
      (slice.copy byteT) "$a0" "$a1");;;
      return: (![sliceT byteT] "dest")
    else return: (![sliceT byteT] "b"))).

(* go: stateless.go:40:6 *)
Definition ReadInt : val :=
  rec: "ReadInt" "b" :=
    exception_do (let: "b" := (ref_ty (sliceT byteT) "b") in
    let: "i" := (ref_ty uint64T (zero_val uint64T)) in
    let: "$r0" := (let: "$a0" := (![sliceT byteT] "b") in
    primitive.UInt64Get "$a0") in
    do:  ("i" <-[uint64T] "$r0");;;
    return: (![uint64T] "i", let: "$s" := (![sliceT byteT] "b") in
     slice.slice byteT "$s" #8 (slice.len "$s"))).

(* go: stateless.go:45:6 *)
Definition ReadInt32 : val :=
  rec: "ReadInt32" "b" :=
    exception_do (let: "b" := (ref_ty (sliceT byteT) "b") in
    let: "i" := (ref_ty uint32T (zero_val uint32T)) in
    let: "$r0" := (let: "$a0" := (![sliceT byteT] "b") in
    primitive.UInt32Get "$a0") in
    do:  ("i" <-[uint32T] "$r0");;;
    return: (![uint32T] "i", let: "$s" := (![sliceT byteT] "b") in
     slice.slice byteT "$s" #4 (slice.len "$s"))).

(* ReadBytes reads `l` bytes from b and returns (bs, rest)

   go: stateless.go:51:6 *)
Definition ReadBytes : val :=
  rec: "ReadBytes" "b" "l" :=
    exception_do (let: "l" := (ref_ty uint64T "l") in
    let: "b" := (ref_ty (sliceT byteT) "b") in
    let: "s" := (ref_ty (sliceT byteT) (zero_val (sliceT byteT))) in
    let: "$r0" := (let: "$s" := (![sliceT byteT] "b") in
    slice.slice byteT "$s" #0 (![uint64T] "l")) in
    do:  ("s" <-[sliceT byteT] "$r0");;;
    return: (![sliceT byteT] "s", let: "$s" := (![sliceT byteT] "b") in
     slice.slice byteT "$s" (![uint64T] "l") (slice.len "$s"))).

(* Like ReadBytes, but avoids keeping the source slice [b] alive.

   go: stateless.go:57:6 *)
Definition ReadBytesCopy : val :=
  rec: "ReadBytesCopy" "b" "l" :=
    exception_do (let: "l" := (ref_ty uint64T "l") in
    let: "b" := (ref_ty (sliceT byteT) "b") in
    let: "s" := (ref_ty (sliceT byteT) (zero_val (sliceT byteT))) in
    let: "$r0" := (slice.make2 byteT (![uint64T] "l")) in
    do:  ("s" <-[sliceT byteT] "$r0");;;
    do:  (let: "$a0" := (![sliceT byteT] "s") in
    let: "$a1" := (let: "$s" := (![sliceT byteT] "b") in
    slice.slice byteT "$s" #0 (![uint64T] "l")) in
    (slice.copy byteT) "$a0" "$a1");;;
    return: (![sliceT byteT] "s", let: "$s" := (![sliceT byteT] "b") in
     slice.slice byteT "$s" (![uint64T] "l") (slice.len "$s"))).

(* go: stateless.go:63:6 *)
Definition ReadBool : val :=
  rec: "ReadBool" "b" :=
    exception_do (let: "b" := (ref_ty (sliceT byteT) "b") in
    let: "x" := (ref_ty boolT (zero_val boolT)) in
    let: "$r0" := ((![byteT] (slice.elem_ref byteT (![sliceT byteT] "b") #0)) ≠ #(U8 0)) in
    do:  ("x" <-[boolT] "$r0");;;
    return: (![boolT] "x", let: "$s" := (![sliceT byteT] "b") in
     slice.slice byteT "$s" #1 (slice.len "$s"))).

(* go: stateless.go:68:6 *)
Definition ReadLenPrefixedBytes : val :=
  rec: "ReadLenPrefixedBytes" "b" :=
    exception_do (let: "b" := (ref_ty (sliceT byteT) "b") in
    let: "b2" := (ref_ty (sliceT byteT) (zero_val (sliceT byteT))) in
    let: "l" := (ref_ty uint64T (zero_val uint64T)) in
    let: ("$ret0", "$ret1") := (let: "$a0" := (![sliceT byteT] "b") in
    ReadInt "$a0") in
    let: "$r0" := "$ret0" in
    let: "$r1" := "$ret1" in
    do:  ("l" <-[uint64T] "$r0");;;
    do:  ("b2" <-[sliceT byteT] "$r1");;;
    let: "b3" := (ref_ty (sliceT byteT) (zero_val (sliceT byteT))) in
    let: "bs" := (ref_ty (sliceT byteT) (zero_val (sliceT byteT))) in
    let: ("$ret0", "$ret1") := (let: "$a0" := (![sliceT byteT] "b2") in
    let: "$a1" := (![uint64T] "l") in
    ReadBytes "$a0" "$a1") in
    let: "$r0" := "$ret0" in
    let: "$r1" := "$ret1" in
    do:  ("bs" <-[sliceT byteT] "$r0");;;
    do:  ("b3" <-[sliceT byteT] "$r1");;;
    return: (![sliceT byteT] "bs", ![sliceT byteT] "b3")).

(* WriteInt appends i in little-endian format to b, returning the new slice.

   go: stateless.go:77:6 *)
Definition WriteInt : val :=
  rec: "WriteInt" "b" "i" :=
    exception_do (let: "i" := (ref_ty uint64T "i") in
    let: "b" := (ref_ty (sliceT byteT) "b") in
    let: "b2" := (ref_ty (sliceT byteT) (zero_val (sliceT byteT))) in
    let: "$r0" := (let: "$a0" := (![sliceT byteT] "b") in
    let: "$a1" := #8 in
    reserve "$a0" "$a1") in
    do:  ("b2" <-[sliceT byteT] "$r0");;;
    let: "off" := (ref_ty intT (zero_val intT)) in
    let: "$r0" := (let: "$a0" := (![sliceT byteT] "b2") in
    slice.len "$a0") in
    do:  ("off" <-[intT] "$r0");;;
    let: "b3" := (ref_ty (sliceT byteT) (zero_val (sliceT byteT))) in
    let: "$r0" := (let: "$s" := (![sliceT byteT] "b2") in
    slice.slice byteT "$s" #0 ((![intT] "off") + #8)) in
    do:  ("b3" <-[sliceT byteT] "$r0");;;
    do:  (let: "$a0" := (let: "$s" := (![sliceT byteT] "b3") in
    slice.slice byteT "$s" (![intT] "off") (slice.len "$s")) in
    let: "$a1" := (![uint64T] "i") in
    primitive.UInt64Put "$a0" "$a1");;;
    return: (![sliceT byteT] "b3")).

(* WriteInt32 appends 32-bit integer i in little-endian format to b, returning the new slice.

   go: stateless.go:87:6 *)
Definition WriteInt32 : val :=
  rec: "WriteInt32" "b" "i" :=
    exception_do (let: "i" := (ref_ty uint32T "i") in
    let: "b" := (ref_ty (sliceT byteT) "b") in
    let: "b2" := (ref_ty (sliceT byteT) (zero_val (sliceT byteT))) in
    let: "$r0" := (let: "$a0" := (![sliceT byteT] "b") in
    let: "$a1" := #4 in
    reserve "$a0" "$a1") in
    do:  ("b2" <-[sliceT byteT] "$r0");;;
    let: "off" := (ref_ty intT (zero_val intT)) in
    let: "$r0" := (let: "$a0" := (![sliceT byteT] "b2") in
    slice.len "$a0") in
    do:  ("off" <-[intT] "$r0");;;
    let: "b3" := (ref_ty (sliceT byteT) (zero_val (sliceT byteT))) in
    let: "$r0" := (let: "$s" := (![sliceT byteT] "b2") in
    slice.slice byteT "$s" #0 ((![intT] "off") + #4)) in
    do:  ("b3" <-[sliceT byteT] "$r0");;;
    do:  (let: "$a0" := (let: "$s" := (![sliceT byteT] "b3") in
    slice.slice byteT "$s" (![intT] "off") (slice.len "$s")) in
    let: "$a1" := (![uint32T] "i") in
    primitive.UInt32Put "$a0" "$a1");;;
    return: (![sliceT byteT] "b3")).

(* Append data to b, returning the new slice.

   go: stateless.go:96:6 *)
Definition WriteBytes : val :=
  rec: "WriteBytes" "b" "data" :=
    exception_do (let: "data" := (ref_ty (sliceT byteT) "data") in
    let: "b" := (ref_ty (sliceT byteT) "b") in
    return: (let: "$a0" := (![sliceT byteT] "b") in
     let: "$a1" := (![sliceT byteT] "data") in
     (slice.append (sliceT byteT)) "$a0" "$a1")).

(* go: stateless.go:100:6 *)
Definition WriteBool : val :=
  rec: "WriteBool" "b" "x" :=
    exception_do (let: "x" := (ref_ty boolT "x") in
    let: "b" := (ref_ty (sliceT byteT) "b") in
    (if: ![boolT] "x"
    then
      return: (let: "$a0" := (![sliceT byteT] "b") in
       let: "$a1" := ((let: "$sl0" := #(U8 1) in
       slice.literal byteT ["$sl0"])) in
       (slice.append (sliceT byteT)) "$a0" "$a1")
    else
      return: (let: "$a0" := (![sliceT byteT] "b") in
       let: "$a1" := ((let: "$sl0" := #(U8 0) in
       slice.literal byteT ["$sl0"])) in
       (slice.append (sliceT byteT)) "$a0" "$a1"))).

(* go: stateless.go:108:6 *)
Definition WriteLenPrefixedBytes : val :=
  rec: "WriteLenPrefixedBytes" "b" "bs" :=
    exception_do (let: "bs" := (ref_ty (sliceT byteT) "bs") in
    let: "b" := (ref_ty (sliceT byteT) "b") in
    let: "b2" := (ref_ty (sliceT byteT) (zero_val (sliceT byteT))) in
    let: "$r0" := (let: "$a0" := (![sliceT byteT] "b") in
    let: "$a1" := (let: "$a0" := (![sliceT byteT] "bs") in
    slice.len "$a0") in
    WriteInt "$a0" "$a1") in
    do:  ("b2" <-[sliceT byteT] "$r0");;;
    return: (let: "$a0" := (![sliceT byteT] "b2") in
     let: "$a1" := (![sliceT byteT] "bs") in
     WriteBytes "$a0" "$a1")).

End code.
