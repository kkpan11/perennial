(* autogenerated from awol *)
From Perennial.Goose Require Import base.

(* 10 is completely arbitrary *)
Definition MaxTxnWrites : uint64 := 10.

Definition logLength : uint64 := 1 + 2 * MaxTxnWrites.

Module Log.
  Record t {model:GoModel} := mk {
    cache: Map Block;
    length: ptr uint64;
  }.
  Arguments mk {model}.
  Global Instance t_zero {model:GoModel} : HasGoZero t := mk (zeroValue _) (zeroValue _).
End Log.

Definition intToBlock {model:GoModel} (a:uint64) : proc Block :=
  b <- Data.newSlice byte Disk.BlockSize;
  _ <- Data.uint64Put b a;
  Ret b.

Definition blockToInt {model:GoModel} (v:Block) : proc uint64 :=
  a <- Data.uint64Get v;
  Ret a.

(* New initializes a fresh log *)
Definition New {model:GoModel} : proc Log.t :=
  diskSize <- Disk.size;
  _ <- if uint64_le diskSize logLength
  then
    _ <- Data.panic;
    Ret tt
  else Ret tt;
  cache <- Data.newMap Block;
  header <- intToBlock 0;
  _ <- Disk.write 0 header;
  lengthPtr <- Data.newPtr uint64;
  _ <- Data.writePtr lengthPtr 0;
  Ret {| Log.cache := cache;
         Log.length := lengthPtr; |}.

(* BeginTxn allocates space for a new transaction in the log.

   Returns true if the allocation succeeded. *)
Definition BeginTxn {model:GoModel} (l:Log.t) : proc bool :=
  length <- Data.readPtr l.(Log.length);
  if length == 0
  then Ret true
  else Ret false.

(* Read from the logical disk.

   Reads must go through the log to return committed but un-applied writes. *)
Definition Read {model:GoModel} (l:Log.t) (a:uint64) : proc Block :=
  let! (v, ok) <- Data.mapGet l.(Log.cache) a;
  if ok
  then Ret v
  else
    dv <- Disk.read (logLength + a);
    Ret dv.

Definition Size {model:GoModel} (l:Log.t) : proc uint64 :=
  sz <- Disk.size;
  Ret (sz - logLength).

(* Write to the disk through the log. *)
Definition Write {model:GoModel} (l:Log.t) (a:uint64) (v:Block) : proc unit :=
  length <- Data.readPtr l.(Log.length);
  _ <- if uint64_ge length MaxTxnWrites
  then
    _ <- Data.panic;
    Ret tt
  else Ret tt;
  aBlock <- intToBlock a;
  let nextAddr := 1 + 2 * length in
  _ <- Disk.write nextAddr aBlock;
  _ <- Disk.write (nextAddr + 1) v;
  _ <- Data.mapAlter l.(Log.cache) a (fun _ => Some v);
  Data.writePtr l.(Log.length) (length + 1).

(* Commit the current transaction. *)
Definition Commit {model:GoModel} (l:Log.t) : proc unit :=
  length <- Data.readPtr l.(Log.length);
  header <- intToBlock length;
  Disk.write 0 header.

Definition getLogEntry {model:GoModel} (logOffset:uint64) : proc (uint64 * Block) :=
  let diskAddr := 1 + 2 * logOffset in
  aBlock <- Disk.read diskAddr;
  a <- blockToInt aBlock;
  v <- Disk.read (diskAddr + 1);
  Ret (a, v).

Definition applyLog {model:GoModel} (length:uint64) : proc unit :=
  Loop (fun i =>
        if compare_to Lt i length
        then
          let! (a, v) <- getLogEntry i;
          _ <- Disk.write (logLength + a) v;
          Continue (i + 1)
        else LoopRet tt) 0.

Definition clearLog {model:GoModel} : proc unit :=
  header <- intToBlock 0;
  Disk.write 0 header.

(* Apply all the committed transactions.

   Frees all the space in the log. *)
Definition Apply {model:GoModel} (l:Log.t) : proc unit :=
  length <- Data.readPtr l.(Log.length);
  _ <- applyLog length;
  _ <- clearLog;
  Data.writePtr l.(Log.length) 0.

(* Open recovers the log following a crash or shutdown *)
Definition Open {model:GoModel} : proc Log.t :=
  header <- Disk.read 0;
  length <- blockToInt header;
  _ <- applyLog length;
  _ <- clearLog;
  cache <- Data.newMap Block;
  lengthPtr <- Data.newPtr uint64;
  _ <- Data.writePtr lengthPtr 0;
  Ret {| Log.cache := cache;
         Log.length := lengthPtr; |}.
