(* autogenerated from github.com/mit-pdos/pav/marshalutil *)
From Perennial.goose_lang Require Import prelude.
From Goose Require github_com.tchajed.marshal.

Section code.
Context `{ext_ty: ext_types}.

Definition ReadBool: val :=
  rec: "ReadBool" "b0" :=
    let: "b" := ref_to (slice.T byteT) "b0" in
    (if: (slice.len (![slice.T byteT] "b")) < #1
    then (#false, slice.nil, #true)
    else
      let: ("data", "b2") := marshal.ReadBool (![slice.T byteT] "b") in
      ("data", "b2", #false)).

Definition ReadConstBool: val :=
  rec: "ReadConstBool" "b0" "cst" :=
    let: "b" := ref_to (slice.T byteT) "b0" in
    let: (("res", "b"), "err") := ReadBool (![slice.T byteT] "b") in
    (if: "err"
    then (slice.nil, #true)
    else
      (if: "res" ≠ "cst"
      then (slice.nil, #true)
      else (![slice.T byteT] "b", #false))).

Definition ReadInt: val :=
  rec: "ReadInt" "b0" :=
    let: "b" := ref_to (slice.T byteT) "b0" in
    (if: (slice.len (![slice.T byteT] "b")) < #8
    then (#0, slice.nil, #true)
    else
      let: ("data", "b") := marshal.ReadInt (![slice.T byteT] "b") in
      ("data", ![slice.T byteT] "b", #false)).

Definition ReadConstInt: val :=
  rec: "ReadConstInt" "b0" "cst" :=
    let: "b" := ref_to (slice.T byteT) "b0" in
    let: (("res", "b"), "err") := ReadInt (![slice.T byteT] "b") in
    (if: "err"
    then (slice.nil, #true)
    else
      (if: "res" ≠ "cst"
      then (slice.nil, #true)
      else (![slice.T byteT] "b", #false))).

Definition ReadByte: val :=
  rec: "ReadByte" "b0" :=
    let: "b" := ref_to (slice.T byteT) "b0" in
    (if: (slice.len (![slice.T byteT] "b")) < #1
    then (#(U8 0), slice.nil, #true)
    else
      let: ("data", "b") := marshal.ReadBytes (![slice.T byteT] "b") #1 in
      (SliceGet byteT "data" #0, ![slice.T byteT] "b", #false)).

Definition ReadConstByte: val :=
  rec: "ReadConstByte" "b0" "cst" :=
    let: "b" := ref_to (slice.T byteT) "b0" in
    let: (("res", "b"), "err") := ReadByte (![slice.T byteT] "b") in
    (if: "err"
    then (slice.nil, #true)
    else
      (if: "res" ≠ "cst"
      then (slice.nil, #true)
      else (![slice.T byteT] "b", #false))).

Definition WriteByte: val :=
  rec: "WriteByte" "b0" "data" :=
    let: "b" := ref_to (slice.T byteT) "b0" in
    "b" <-[slice.T byteT] (marshal.WriteBytes (![slice.T byteT] "b") (SliceSingleton "data"));;
    ![slice.T byteT] "b".

Definition ReadBytes: val :=
  rec: "ReadBytes" "b0" "length" :=
    let: "b" := ref_to (slice.T byteT) "b0" in
    (if: (slice.len (![slice.T byteT] "b")) < "length"
    then (slice.nil, slice.nil, #true)
    else
      let: ("data", "b") := marshal.ReadBytes (![slice.T byteT] "b") "length" in
      ("data", ![slice.T byteT] "b", #false)).

Definition ReadSlice1D: val :=
  rec: "ReadSlice1D" "b0" :=
    let: "b" := ref_to (slice.T byteT) "b0" in
    let: (("length", "b"), "err") := ReadInt (![slice.T byteT] "b") in
    (if: "err"
    then (slice.nil, slice.nil, "err")
    else
      let: (("data", "b"), "err") := ReadBytes (![slice.T byteT] "b") "length" in
      (if: "err"
      then (slice.nil, slice.nil, "err")
      else ("data", ![slice.T byteT] "b", #false))).

Definition WriteSlice1D: val :=
  rec: "WriteSlice1D" "b0" "data" :=
    let: "b" := ref_to (slice.T byteT) "b0" in
    "b" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "b") (slice.len "data"));;
    "b" <-[slice.T byteT] (marshal.WriteBytes (![slice.T byteT] "b") "data");;
    ![slice.T byteT] "b".

Definition ReadSlice2D: val :=
  rec: "ReadSlice2D" "b0" :=
    let: "b" := ref_to (slice.T byteT) "b0" in
    let: (("length", "b"), "err") := ReadInt (![slice.T byteT] "b") in
    (if: "err"
    then (slice.nil, slice.nil, "err")
    else
      let: "data0" := ref (zero_val (slice.T (slice.T byteT))) in
      let: "err0" := ref (zero_val boolT) in
      let: "i" := ref (zero_val uint64T) in
      Skip;;
      (for: (λ: <>, (![uint64T] "i") < "length"); (λ: <>, "i" <-[uint64T] ((![uint64T] "i") + #1)) := λ: <>,
        let: "data1" := ref (zero_val (slice.T byteT)) in
        let: "err1" := ref (zero_val boolT) in
        let: (("0_ret", "1_ret"), "2_ret") := ReadSlice1D (![slice.T byteT] "b") in
        "data1" <-[slice.T byteT] "0_ret";;
        "b" <-[slice.T byteT] "1_ret";;
        "err1" <-[boolT] "2_ret";;
        (if: ![boolT] "err1"
        then
          "err0" <-[boolT] (![boolT] "err1");;
          Continue
        else
          "data0" <-[slice.T (slice.T byteT)] (SliceAppend (slice.T byteT) (![slice.T (slice.T byteT)] "data0") (![slice.T byteT] "data1"));;
          Continue));;
      (if: ![boolT] "err0"
      then (slice.nil, slice.nil, ![boolT] "err0")
      else (![slice.T (slice.T byteT)] "data0", ![slice.T byteT] "b", #false))).

Definition WriteSlice2D: val :=
  rec: "WriteSlice2D" "b0" "data" :=
    let: "b" := ref_to (slice.T byteT) "b0" in
    "b" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "b") (slice.len "data"));;
    ForSlice (slice.T byteT) <> "data1" "data"
      ("b" <-[slice.T byteT] (WriteSlice1D (![slice.T byteT] "b") "data1"));;
    ![slice.T byteT] "b".

Definition ReadSlice3D: val :=
  rec: "ReadSlice3D" "b0" :=
    let: "b" := ref_to (slice.T byteT) "b0" in
    let: (("length", "b"), "err") := ReadInt (![slice.T byteT] "b") in
    (if: "err"
    then (slice.nil, slice.nil, "err")
    else
      let: "data0" := ref (zero_val (slice.T (slice.T (slice.T byteT)))) in
      let: "err0" := ref (zero_val boolT) in
      let: "i" := ref (zero_val uint64T) in
      Skip;;
      (for: (λ: <>, (![uint64T] "i") < "length"); (λ: <>, "i" <-[uint64T] ((![uint64T] "i") + #1)) := λ: <>,
        let: "data1" := ref (zero_val (slice.T (slice.T byteT))) in
        let: "err1" := ref (zero_val boolT) in
        let: (("0_ret", "1_ret"), "2_ret") := ReadSlice2D (![slice.T byteT] "b") in
        "data1" <-[slice.T (slice.T byteT)] "0_ret";;
        "b" <-[slice.T byteT] "1_ret";;
        "err1" <-[boolT] "2_ret";;
        (if: ![boolT] "err1"
        then
          "err0" <-[boolT] (![boolT] "err1");;
          Continue
        else
          "data0" <-[slice.T (slice.T (slice.T byteT))] (SliceAppend (slice.T (slice.T byteT)) (![slice.T (slice.T (slice.T byteT))] "data0") (![slice.T (slice.T byteT)] "data1"));;
          Continue));;
      (if: ![boolT] "err0"
      then (slice.nil, slice.nil, ![boolT] "err0")
      else (![slice.T (slice.T (slice.T byteT))] "data0", ![slice.T byteT] "b", #false))).

Definition WriteSlice3D: val :=
  rec: "WriteSlice3D" "b0" "data" :=
    let: "b" := ref_to (slice.T byteT) "b0" in
    "b" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "b") (slice.len "data"));;
    ForSlice (slice.T (slice.T byteT)) <> "data1" "data"
      ("b" <-[slice.T byteT] (WriteSlice2D (![slice.T byteT] "b") "data1"));;
    ![slice.T byteT] "b".

End code.
