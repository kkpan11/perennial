(* autogenerated from github.com/mit-pdos/perennial-examples/async_durable_alloc *)
From Perennial.goose_lang Require Import prelude.
From Perennial.goose_lang Require Import ffi.async_disk_prelude.

(* Allocator uses a bit map to allocate and free numbers. Bit 0
   corresponds to number 0, bit 1 to 1, and so on. *)
Definition Alloc := struct.decl [
  "d" :: disk.Disk;
  "mu" :: ptrT;
  "addr" :: uint64T;
  "next" :: uint64T;
  "bitmap" :: slice.T byteT;
  "dirty" :: boolT
].

(* MkAlloc initializes with a bitmap. *)
Definition MkAlloc: val :=
  rec: "MkAlloc" "d" "addr" :=
    let: "bitmap" := disk.Read "addr" in
    let: "a" := struct.new Alloc [
      "d" ::= "d";
      "mu" ::= lock.new #();
      "addr" ::= "addr";
      "next" ::= #0;
      "bitmap" ::= "bitmap";
      "dirty" ::= #false
    ] in
    "a".

Definition Alloc__MarkUsed: val :=
  rec: "Alloc__MarkUsed" "a" "bn" :=
    lock.acquire (struct.loadF Alloc "mu" "a");;
    let: "byte" := "bn" `quot` #8 in
    let: "bit" := "bn" `rem` #8 in
    SliceSet byteT (struct.loadF Alloc "bitmap" "a") "byte" (SliceGet byteT (struct.loadF Alloc "bitmap" "a") "byte" `or` (#(U8 1)) ≪ "bit");;
    struct.storeF Alloc "dirty" "a" #true;;
    lock.release (struct.loadF Alloc "mu" "a");;
    #().

Definition Alloc__incNext: val :=
  rec: "Alloc__incNext" "a" :=
    struct.storeF Alloc "next" "a" (struct.loadF Alloc "next" "a" + #1);;
    (if: struct.loadF Alloc "next" "a" ≥ slice.len (struct.loadF Alloc "bitmap" "a") * #8
    then struct.storeF Alloc "next" "a" #0
    else #());;
    struct.loadF Alloc "next" "a".

(* Returns a free number in the bitmap *)
Definition Alloc__allocBit: val :=
  rec: "Alloc__allocBit" "a" :=
    let: "num" := ref (zero_val uint64T) in
    lock.acquire (struct.loadF Alloc "mu" "a");;
    "num" <-[uint64T] Alloc__incNext "a";;
    let: "start" := ![uint64T] "num" in
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "bit" := (![uint64T] "num") `rem` #8 in
      let: "byte" := (![uint64T] "num") `quot` #8 in
      (if: (SliceGet byteT (struct.loadF Alloc "bitmap" "a") "byte" `and` (#(U8 1)) ≪ "bit") = #(U8 0)
      then
        SliceSet byteT (struct.loadF Alloc "bitmap" "a") "byte" (SliceGet byteT (struct.loadF Alloc "bitmap" "a") "byte" `or` (#(U8 1)) ≪ "bit");;
        struct.storeF Alloc "dirty" "a" #true;;
        Break
      else
        "num" <-[uint64T] Alloc__incNext "a";;
        (if: (![uint64T] "num" = "start")
        then
          "num" <-[uint64T] #0;;
          Break
        else Continue)));;
    lock.release (struct.loadF Alloc "mu" "a");;
    ![uint64T] "num".

Definition Alloc__freeBit: val :=
  rec: "Alloc__freeBit" "a" "bn" :=
    lock.acquire (struct.loadF Alloc "mu" "a");;
    let: "byte" := "bn" `quot` #8 in
    let: "bit" := "bn" `rem` #8 in
    SliceSet byteT (struct.loadF Alloc "bitmap" "a") "byte" (SliceGet byteT (struct.loadF Alloc "bitmap" "a") "byte" `and` ~ ((#(U8 1)) ≪ "bit"));;
    struct.storeF Alloc "dirty" "a" #true;;
    lock.release (struct.loadF Alloc "mu" "a");;
    #().

Definition Alloc__AllocNum: val :=
  rec: "Alloc__AllocNum" "a" :=
    let: "num" := Alloc__allocBit "a" in
    "num".

Definition Alloc__FreeNum: val :=
  rec: "Alloc__FreeNum" "a" "num" :=
    (if: ("num" = #0)
    then Panic "FreeNum"
    else #());;
    Alloc__freeBit "a" "num";;
    #().

Definition Alloc__Flush: val :=
  rec: "Alloc__Flush" "a" :=
    lock.acquire (struct.loadF Alloc "mu" "a");;
    (if: struct.loadF Alloc "dirty" "a"
    then
      disk.Write (struct.loadF Alloc "addr" "a") (struct.loadF Alloc "bitmap" "a");;
      struct.storeF Alloc "dirty" "a" #false
    else #());;
    lock.release (struct.loadF Alloc "mu" "a");;
    #().

Definition popCnt: val :=
  rec: "popCnt" "b" :=
    let: "count" := ref (zero_val uint64T) in
    let: "x" := ref_to byteT "b" in
    let: "i" := ref_to uint64T #0 in
    (for: (λ: <>, ![uint64T] "i" < #8); (λ: <>, "i" <-[uint64T] ![uint64T] "i" + #1) := λ: <>,
      "count" <-[uint64T] ![uint64T] "count" + to_u64 (![byteT] "x" `and` #(U8 1));;
      "x" <-[byteT] (![byteT] "x") ≫ #1;;
      Continue);;
    ![uint64T] "count".

Definition Alloc__NumFree: val :=
  rec: "Alloc__NumFree" "a" :=
    lock.acquire (struct.loadF Alloc "mu" "a");;
    let: "total" := #8 * slice.len (struct.loadF Alloc "bitmap" "a") in
    let: "count" := ref (zero_val uint64T) in
    ForSlice byteT <> "b" (struct.loadF Alloc "bitmap" "a")
      ("count" <-[uint64T] ![uint64T] "count" + popCnt "b");;
    lock.release (struct.loadF Alloc "mu" "a");;
    "total" - ![uint64T] "count".
