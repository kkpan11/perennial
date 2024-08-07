(* autogenerated from github.com/goose-lang/std *)
From Perennial.goose_lang Require Import prelude.

Section code.
Context `{ext_ty: ext_types}.
Local Coercion Var' s: expr := Var s.

(* BytesEqual returns if the two byte slices are equal. *)
Definition BytesEqual: val :=
  rec: "BytesEqual" "x" "y" :=
    let: "xlen" := slice.len "x" in
    (if: "xlen" ≠ (slice.len "y")
    then #false
    else
      let: "i" := ref_to uint64T #0 in
      let: "retval" := ref_to boolT #true in
      Skip;;
      (for: (λ: <>, (![uint64T] "i") < "xlen"); (λ: <>, Skip) := λ: <>,
        (if: (SliceGet byteT "x" (![uint64T] "i")) ≠ (SliceGet byteT "y" (![uint64T] "i"))
        then
          "retval" <-[boolT] #false;;
          Break
        else
          "i" <-[uint64T] ((![uint64T] "i") + #1);;
          Continue));;
      ![boolT] "retval").

(* See the [reference].

   [reference]: https://pkg.go.dev/bytes#Clone *)
Definition BytesClone: val :=
  rec: "BytesClone" "b" :=
    (if: "b" = slice.nil
    then slice.nil
    else SliceAppendSlice byteT (NewSlice byteT #0) "b").

(* SliceSplit splits xs at n into two slices.

   The capacity of the first slice overlaps with the second, so afterward it is
   no longer safe to append to the first slice.

   TODO: once goose supports it, make this function generic in the slice element
   type *)
Definition SliceSplit: val :=
  rec: "SliceSplit" "xs" "n" :=
    (SliceTake "xs" "n", SliceSkip byteT "xs" "n").

(* Returns true if x + y does not overflow *)
Definition SumNoOverflow: val :=
  rec: "SumNoOverflow" "x" "y" :=
    ("x" + "y") ≥ "x".

(* SumAssumeNoOverflow returns x + y, `Assume`ing that this does not overflow.

   *Use with care* - if the assumption is violated this function will panic. *)
Definition SumAssumeNoOverflow: val :=
  rec: "SumAssumeNoOverflow" "x" "y" :=
    control.impl.Assume (SumNoOverflow "x" "y");;
    "x" + "y".

(* Multipar runs op(0) ... op(num-1) in parallel and waits for them all to finish.

   Implementation note: does not use a done channel (which is the standard
   pattern in Go) because this is not supported by Goose. Instead uses mutexes
   and condition variables since these are modeled in Goose *)
Definition Multipar: val :=
  rec: "Multipar" "num" "op" :=
    let: "num_left" := ref_to uint64T "num" in
    let: "num_left_mu" := lock.new #() in
    let: "num_left_cond" := lock.newCond "num_left_mu" in
    let: "i" := ref_to uint64T #0 in
    (for: (λ: <>, (![uint64T] "i") < "num"); (λ: <>, "i" <-[uint64T] ((![uint64T] "i") + #1)) := λ: <>,
      let: "i" := ![uint64T] "i" in
      Fork ("op" "i";;
            lock.acquire "num_left_mu";;
            "num_left" <-[uint64T] ((![uint64T] "num_left") - #1);;
            lock.condSignal "num_left_cond";;
            lock.release "num_left_mu");;
      Continue);;
    lock.acquire "num_left_mu";;
    Skip;;
    (for: (λ: <>, (![uint64T] "num_left") > #0); (λ: <>, Skip) := λ: <>,
      lock.condWait "num_left_cond";;
      Continue);;
    lock.release "num_left_mu";;
    #().

(* Skip is a no-op that can be useful in proofs.

   Occasionally a proof may need to open an invariant and perform a ghost update
   across a step in the operational semantics. The GooseLang model may not have
   a convenient step, but it is always sound to insert more. Calling std.Skip()
   is a simple way to do so - the model always requires one step to reduce this
   application to a value. *)
Definition Skip: val :=
  rec: "Skip" <> :=
    #().

End code.
