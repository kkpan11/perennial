(* autogenerated from github.com/goose-lang/std *)
From Perennial.goose_lang Require Import prelude.

Section code.
Context `{ext_ty: ext_types}.

(* Assert(b) panics if b doesn't hold *)
Definition Assert: val :=
  rec: "Assert" "b" :=
    (if: (~ "b")
    then
      Panic "assertion failure";;
      #()
    else #()).

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

(* MulNoOverflow returns true if x * y does not overflow *)
Definition MulNoOverflow: val :=
  rec: "MulNoOverflow" "x" "y" :=
    (if: ("x" = #0) || ("y" = #0)
    then #true
    else "x" ≤ (((#1 ≪ #64) - #1) `quot` "y")).

(* MulAssumeNoOverflow returns x * y, `Assume`ing that this does not overflow.

   *Use with care* - if the assumption is violated this function will panic. *)
Definition MulAssumeNoOverflow: val :=
  rec: "MulAssumeNoOverflow" "x" "y" :=
    control.impl.Assume (MulNoOverflow "x" "y");;
    "x" * "y".

(* JoinHandle is a mechanism to wait for a goroutine to finish. Calling `Join()`
   on the handle returned by `Spawn(f)` will wait for f to finish. *)
Definition JoinHandle := struct.decl [
  "mu" :: ptrT;
  "done" :: boolT;
  "cond" :: ptrT
].

Definition newJoinHandle: val :=
  rec: "newJoinHandle" <> :=
    let: "mu" := newMutex #() in
    let: "cond" := NewCond "mu" in
    struct.new JoinHandle [
      "mu" ::= "mu";
      "done" ::= #false;
      "cond" ::= "cond"
    ].

Definition JoinHandle__finish: val :=
  rec: "JoinHandle__finish" "h" :=
    Mutex__Lock (struct.loadF JoinHandle "mu" "h");;
    struct.storeF JoinHandle "done" "h" #true;;
    Cond__Signal (struct.loadF JoinHandle "cond" "h");;
    Mutex__Unlock (struct.loadF JoinHandle "mu" "h");;
    #().

(* Spawn runs `f` in a parallel goroutine and returns a handle to wait for
   it to finish.

   Due to Goose limitations we do not return anything from the function, but it
   could return an `interface{}` value or be generic in the return value with
   essentially the same implementation, replacing `done` with a pointer to the
   result value. *)
Definition Spawn: val :=
  rec: "Spawn" "f" :=
    let: "h" := newJoinHandle #() in
    Fork ("f" #();;
          JoinHandle__finish "h");;
    "h".

Definition JoinHandle__Join: val :=
  rec: "JoinHandle__Join" "h" :=
    Mutex__Lock (struct.loadF JoinHandle "mu" "h");;
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      (if: struct.loadF JoinHandle "done" "h"
      then
        struct.storeF JoinHandle "done" "h" #false;;
        Break
      else
        Cond__Wait (struct.loadF JoinHandle "cond" "h");;
        Continue));;
    Mutex__Unlock (struct.loadF JoinHandle "mu" "h");;
    #().

(* Multipar runs op(0) ... op(num-1) in parallel and waits for them all to finish.

   Implementation note: does not use a done channel (which is the standard
   pattern in Go) because this is not supported by Goose. Instead uses mutexes
   and condition variables since these are modeled in Goose *)
Definition Multipar: val :=
  rec: "Multipar" "num" "op" :=
    let: "num_left" := ref_to uint64T "num" in
    let: "num_left_mu" := newMutex #() in
    let: "num_left_cond" := NewCond "num_left_mu" in
    let: "i" := ref_to uint64T #0 in
    (for: (λ: <>, (![uint64T] "i") < "num"); (λ: <>, "i" <-[uint64T] ((![uint64T] "i") + #1)) := λ: <>,
      let: "i" := ![uint64T] "i" in
      Fork ("op" "i";;
            Mutex__Lock "num_left_mu";;
            "num_left" <-[uint64T] ((![uint64T] "num_left") - #1);;
            Cond__Signal "num_left_cond";;
            Mutex__Unlock "num_left_mu");;
      Continue);;
    Mutex__Lock "num_left_mu";;
    Skip;;
    (for: (λ: <>, (![uint64T] "num_left") > #0); (λ: <>, Skip) := λ: <>,
      Cond__Wait "num_left_cond";;
      Continue);;
    Mutex__Unlock "num_left_mu";;
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

(* Shuffle shuffles the elements of xs in place, using a Fisher-Yates shuffle. *)
Definition Shuffle: val :=
  rec: "Shuffle" "xs" :=
    (if: (slice.len "xs") = #0
    then #()
    else
      let: "i" := ref_to uint64T ((slice.len "xs") - #1) in
      (for: (λ: <>, (![uint64T] "i") > #0); (λ: <>, "i" <-[uint64T] ((![uint64T] "i") - #1)) := λ: <>,
        let: "j" := (rand.RandomUint64 #()) `rem` ((![uint64T] "i") + #1) in
        let: "temp" := SliceGet uint64T "xs" (![uint64T] "i") in
        SliceSet uint64T "xs" (![uint64T] "i") (SliceGet uint64T "xs" "j");;
        SliceSet uint64T "xs" "j" "temp";;
        Continue);;
      #()).

(* Permutation returns a random permutation of the integers 0, ..., n-1, using a
   Fisher-Yates shuffle. *)
Definition Permutation: val :=
  rec: "Permutation" "n" :=
    let: "order" := NewSlice uint64T "n" in
    let: "i" := ref_to uint64T #0 in
    (for: (λ: <>, (![uint64T] "i") < "n"); (λ: <>, "i" <-[uint64T] ((![uint64T] "i") + #1)) := λ: <>,
      SliceSet uint64T "order" (![uint64T] "i") (![uint64T] "i");;
      Continue);;
    Shuffle "order";;
    "order".

End code.
