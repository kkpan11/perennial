(* autogenerated from github.com/goose-lang/std *)
From New.golang Require Import defn.
From New.code Require github_com.tchajed.goose.machine.
From New.code Require sync.

Section code.
Context `{ffi_syntax}.
Local Coercion Var' s: expr := Var s.

(* Test if the two byte slices are equal. *)
Definition BytesEqual : val :=
  rec: "BytesEqual" "x" "y" :=
    exception_do (let: "y" := ref_ty (sliceT byteT) "y" in
    let: "x" := ref_ty (sliceT byteT) "x" in
    let: "xlen" := ref_ty intT (zero_val intT) in
    let: "$a0" := slice.len (![sliceT byteT] "x") in
    do:  "xlen" <-[intT] "$a0";;;
    (if: (![intT] "xlen") ≠ (slice.len (![sliceT byteT] "y"))
    then
      return: (#false);;;
      do:  #()
    else do:  #());;;
    let: "i" := ref_ty uint64T #0 in
    let: "retval" := ref_ty boolT #true in
    (for: (λ: <>, (![uint64T] "i") < (![intT] "xlen")); (λ: <>, Skip) := λ: <>,
      (if: (![byteT] (slice.elem_ref byteT (![sliceT byteT] "x") (![uint64T] "i"))) ≠ (![byteT] (slice.elem_ref byteT (![sliceT byteT] "y") (![uint64T] "i")))
      then
        let: "$a0" := #false in
        do:  "retval" <-[boolT] "$a0";;;
        break: #();;;
        do:  #()
      else do:  #());;;
      do:  "i" <-[uint64T] ((![uint64T] "i") + #1);;;
      continue: #();;;
      do:  #());;;
    return: (![boolT] "retval");;;
    do:  #()).

(* See the [reference].

   [reference]: https://pkg.go.dev/bytes#Clone *)
Definition BytesClone : val :=
  rec: "BytesClone" "b" :=
    exception_do (let: "b" := ref_ty (sliceT byteT) "b" in
    (if: (![sliceT byteT] "b") = slice.nil
    then
      return: (slice.nil);;;
      do:  #()
    else do:  #());;;
    return: (slice.append byteT (slice.literal byteT []) (![sliceT byteT] "b"));;;
    do:  #()).

(* SliceSplit splits xs at n into two slices.

   The capacity of the first slice overlaps with the second, so afterward it is
   no longer safe to append to the first slice.

   TODO: once goose supports it, make this function generic in the slice element
   type *)
Definition SliceSplit : val :=
  rec: "SliceSplit" "xs" "n" :=
    exception_do (let: "n" := ref_ty uint64T "n" in
    let: "xs" := ref_ty (sliceT byteT) "xs" in
    return: (let: "$s" := ![sliceT byteT] "xs" in
     slice.slice byteT "$s" #0 (![uint64T] "n"), let: "$s" := ![sliceT byteT] "xs" in
     slice.slice byteT "$s" (![uint64T] "n") (slice.len "$s"));;;
    do:  #()).

(* Returns true if x + y does not overflow *)
Definition SumNoOverflow : val :=
  rec: "SumNoOverflow" "x" "y" :=
    exception_do (let: "y" := ref_ty uint64T "y" in
    let: "x" := ref_ty uint64T "x" in
    return: (((![uint64T] "x") + (![uint64T] "y")) ≥ (![uint64T] "x"));;;
    do:  #()).

(* Compute the sum of two numbers, `Assume`ing that this does not overflow.
   *Use with care*, assumptions are trusted and should be justified! *)
Definition SumAssumeNoOverflow : val :=
  rec: "SumAssumeNoOverflow" "x" "y" :=
    exception_do (let: "y" := ref_ty uint64T "y" in
    let: "x" := ref_ty uint64T "x" in
    do:  machine.Assume (SumNoOverflow (![uint64T] "x") (![uint64T] "y"));;;
    return: ((![uint64T] "x") + (![uint64T] "y"));;;
    do:  #()).

Definition Multipar : val :=
  rec: "Multipar" "num" "op" :=
    exception_do (let: "op" := ref_ty funcT "op" in
    let: "num" := ref_ty uint64T "num" in
    let: "num_left" := ref_ty uint64T (![uint64T] "num") in
    let: "num_left_mu" := ref_ty ptrT (zero_val ptrT) in
    let: "$a0" := ref_ty sync.Mutex (zero_val sync.Mutex) in
    do:  "num_left_mu" <-[ptrT] "$a0";;;
    let: "num_left_cond" := ref_ty ptrT (zero_val ptrT) in
    let: "$a0" := sync.NewCond (![ptrT] "num_left_mu") in
    do:  "num_left_cond" <-[ptrT] "$a0";;;
    (let: "i" := ref_ty uint64T (zero_val uint64T) in
    let: "$a0" := #0 in
    do:  "i" <-[uint64T] "$a0";;;
    (for: (λ: <>, (![uint64T] "i") < (![uint64T] "num")); (λ: <>, do:  "i" <-[uint64T] ((![uint64T] "i") + #1);;;
    #()) := λ: <>,
      let: "i" := ref_ty uint64T (zero_val uint64T) in
      let: "$a0" := ![uint64T] "i" in
      do:  "i" <-[uint64T] "$a0";;;
      let: "$go" := (λ: <>,
        do:  (![funcT] "op") (![uint64T] "i");;;
        do:  (sync.Mutex__Lock (![ptrT] "num_left_mu")) #();;;
        do:  "num_left" <-[uint64T] ((![uint64T] "num_left") - #1);;;
        do:  (sync.Cond__Signal (![ptrT] "num_left_cond")) #();;;
        do:  (sync.Mutex__Unlock (![ptrT] "num_left_mu")) #();;;
        do:  #()
        ) in
      do:  Fork ("$go" #());;;
      do:  #()));;;
    do:  (sync.Mutex__Lock (![ptrT] "num_left_mu")) #();;;
    (for: (λ: <>, (![uint64T] "num_left") > #0); (λ: <>, Skip) := λ: <>,
      do:  (sync.Cond__Wait (![ptrT] "num_left_cond")) #();;;
      do:  #());;;
    do:  (sync.Mutex__Unlock (![ptrT] "num_left_mu")) #();;;
    do:  #()).

End code.
