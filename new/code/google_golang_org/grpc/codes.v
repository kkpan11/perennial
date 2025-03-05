(* autogenerated from google.golang.org/grpc/codes *)
From New.golang Require Import defn.
Require Export New.code.fmt.
Require Export New.code.strconv.

Module codes.
Section code.
Context `{ffi_syntax}.


Definition Code : go_type := uint32T.

Definition Unauthenticated : expr := #(W32 16).

Definition DataLoss : expr := #(W32 15).

Definition Unavailable : expr := #(W32 14).

Definition Internal : expr := #(W32 13).

Definition Unimplemented : expr := #(W32 12).

Definition OutOfRange : expr := #(W32 11).

Definition Aborted : expr := #(W32 10).

Definition FailedPrecondition : expr := #(W32 9).

Definition ResourceExhausted : expr := #(W32 8).

Definition PermissionDenied : expr := #(W32 7).

Definition AlreadyExists : expr := #(W32 6).

Definition NotFound : expr := #(W32 5).

Definition DeadlineExceeded : expr := #(W32 4).

Definition InvalidArgument : expr := #(W32 3).

Definition Unknown : expr := #(W32 2).

Definition Canceled : expr := #(W32 1).

Definition OK : expr := #(W32 0).

(* go: code_string.go:23:15 *)
Definition Code__String : val :=
  rec: "Code__String" "c" <> :=
    exception_do (let: "c" := (ref_ty Code "c") in
    let: "$sw" := (![Code] "c") in
    (if: "$sw" = OK
    then return: (#"OK"%go)
    else
      (if: "$sw" = Canceled
      then return: (#"Canceled"%go)
      else
        (if: "$sw" = Unknown
        then return: (#"Unknown"%go)
        else
          (if: "$sw" = InvalidArgument
          then return: (#"InvalidArgument"%go)
          else
            (if: "$sw" = DeadlineExceeded
            then return: (#"DeadlineExceeded"%go)
            else
              (if: "$sw" = NotFound
              then return: (#"NotFound"%go)
              else
                (if: "$sw" = AlreadyExists
                then return: (#"AlreadyExists"%go)
                else
                  (if: "$sw" = PermissionDenied
                  then return: (#"PermissionDenied"%go)
                  else
                    (if: "$sw" = ResourceExhausted
                    then return: (#"ResourceExhausted"%go)
                    else
                      (if: "$sw" = FailedPrecondition
                      then return: (#"FailedPrecondition"%go)
                      else
                        (if: "$sw" = Aborted
                        then return: (#"Aborted"%go)
                        else
                          (if: "$sw" = OutOfRange
                          then return: (#"OutOfRange"%go)
                          else
                            (if: "$sw" = Unimplemented
                            then return: (#"Unimplemented"%go)
                            else
                              (if: "$sw" = Internal
                              then return: (#"Internal"%go)
                              else
                                (if: "$sw" = Unavailable
                                then return: (#"Unavailable"%go)
                                else
                                  (if: "$sw" = DataLoss
                                  then return: (#"DataLoss"%go)
                                  else
                                    (if: "$sw" = Unauthenticated
                                    then return: (#"Unauthenticated"%go)
                                    else
                                      return: ((#"Code("%go + (let: "$a0" := (to_u64 (![Code] "c")) in
                                       let: "$a1" := #(W64 10) in
                                       (func_call #strconv.pkg_name' #"FormatInt"%go) "$a0" "$a1")) + #")"%go))))))))))))))))))).

Definition _maxCode : Z := 17.

Definition pkg_name' : go_string := "google.golang.org/grpc/codes".

(* UnmarshalJSON unmarshals b into the Code.

   go: codes.go:219:16 *)
Definition Code__UnmarshalJSON : val :=
  rec: "Code__UnmarshalJSON" "c" "b" :=
    exception_do (let: "c" := (ref_ty ptrT "c") in
    let: "b" := (ref_ty sliceT "b") in
    (if: (string.from_bytes (![sliceT] "b")) = #"null"%go
    then return: (#interface.nil)
    else do:  #());;;
    (if: (![ptrT] "c") = #null
    then
      return: (let: "$a0" := #"nil receiver passed to UnmarshalJSON"%go in
       let: "$a1" := #slice.nil in
       (func_call #fmt.pkg_name' #"Errorf"%go) "$a0" "$a1")
    else do:  #());;;
    (let: "err" := (ref_ty error (zero_val error)) in
    let: "ci" := (ref_ty uint64T (zero_val uint64T)) in
    let: ("$ret0", "$ret1") := (let: "$a0" := (string.from_bytes (![sliceT] "b")) in
    let: "$a1" := #(W64 10) in
    let: "$a2" := #(W64 32) in
    (func_call #strconv.pkg_name' #"ParseUint"%go) "$a0" "$a1" "$a2") in
    let: "$r0" := "$ret0" in
    let: "$r1" := "$ret1" in
    do:  ("ci" <-[uint64T] "$r0");;;
    do:  ("err" <-[error] "$r1");;;
    (if: interface.eq (![error] "err") #interface.nil
    then
      (if: (![uint64T] "ci") ≥ #(W64 _maxCode)
      then
        return: (let: "$a0" := #"invalid code: %q"%go in
         let: "$a1" := ((let: "$sl0" := (interface.make #""%go #"uint64"%go (![uint64T] "ci")) in
         slice.literal interfaceT ["$sl0"])) in
         (func_call #fmt.pkg_name' #"Errorf"%go) "$a0" "$a1")
      else do:  #());;;
      let: "$r0" := (to_u32 (![uint64T] "ci")) in
      do:  ((![ptrT] "c") <-[Code] "$r0");;;
      return: (#interface.nil)
    else do:  #()));;;
    (let: "ok" := (ref_ty boolT (zero_val boolT)) in
    let: "jc" := (ref_ty Code (zero_val Code)) in
    let: ("$ret0", "$ret1") := (map.get (![mapT stringT Code] (globals.get #pkg_name' #"strToCode"%go)) (string.from_bytes (![sliceT] "b"))) in
    let: "$r0" := "$ret0" in
    let: "$r1" := "$ret1" in
    do:  ("jc" <-[Code] "$r0");;;
    do:  ("ok" <-[boolT] "$r1");;;
    (if: ![boolT] "ok"
    then
      let: "$r0" := (![Code] "jc") in
      do:  ((![ptrT] "c") <-[Code] "$r0");;;
      return: (#interface.nil)
    else do:  #()));;;
    return: (let: "$a0" := #"invalid code: %q"%go in
     let: "$a1" := ((let: "$sl0" := (interface.make #""%go #"string"%go (string.from_bytes (![sliceT] "b"))) in
     slice.literal interfaceT ["$sl0"])) in
     (func_call #fmt.pkg_name' #"Errorf"%go) "$a0" "$a1")).

Definition vars' : list (go_string * go_type) := [("strToCode"%go, mapT stringT Code)].

Definition functions' : list (go_string * val) := [].

Definition msets' : list (go_string * (list (go_string * val))) := [("Code"%go, [("String"%go, Code__String)]); ("Code'ptr"%go, [("String"%go, (λ: "$recvAddr",
                 method_call #pkg_name' #"Code" #"String" (![Code] "$recvAddr")
                 )%V); ("UnmarshalJSON"%go, Code__UnmarshalJSON)])].

Definition initialize' : val :=
  rec: "initialize'" <> :=
    globals.package_init pkg_name' vars' functions' msets' (λ: <>,
      exception_do (do:  fmt.initialize';;;
      do:  strconv.initialize';;;
      let: "$r0" := ((let: "$v0" := OK in
      let: "$k0" := #"""OK"""%go in
      let: "$v1" := Canceled in
      let: "$k1" := #"""CANCELLED"""%go in
      let: "$v2" := Unknown in
      let: "$k2" := #"""UNKNOWN"""%go in
      let: "$v3" := InvalidArgument in
      let: "$k3" := #"""INVALID_ARGUMENT"""%go in
      let: "$v4" := DeadlineExceeded in
      let: "$k4" := #"""DEADLINE_EXCEEDED"""%go in
      let: "$v5" := NotFound in
      let: "$k5" := #"""NOT_FOUND"""%go in
      let: "$v6" := AlreadyExists in
      let: "$k6" := #"""ALREADY_EXISTS"""%go in
      let: "$v7" := PermissionDenied in
      let: "$k7" := #"""PERMISSION_DENIED"""%go in
      let: "$v8" := ResourceExhausted in
      let: "$k8" := #"""RESOURCE_EXHAUSTED"""%go in
      let: "$v9" := FailedPrecondition in
      let: "$k9" := #"""FAILED_PRECONDITION"""%go in
      let: "$v10" := Aborted in
      let: "$k10" := #"""ABORTED"""%go in
      let: "$v11" := OutOfRange in
      let: "$k11" := #"""OUT_OF_RANGE"""%go in
      let: "$v12" := Unimplemented in
      let: "$k12" := #"""UNIMPLEMENTED"""%go in
      let: "$v13" := Internal in
      let: "$k13" := #"""INTERNAL"""%go in
      let: "$v14" := Unavailable in
      let: "$k14" := #"""UNAVAILABLE"""%go in
      let: "$v15" := DataLoss in
      let: "$k15" := #"""DATA_LOSS"""%go in
      let: "$v16" := Unauthenticated in
      let: "$k16" := #"""UNAUTHENTICATED"""%go in
      map.literal Code [("$k0", "$v0"); ("$k1", "$v1"); ("$k2", "$v2"); ("$k3", "$v3"); ("$k4", "$v4"); ("$k5", "$v5"); ("$k6", "$v6"); ("$k7", "$v7"); ("$k8", "$v8"); ("$k9", "$v9"); ("$k10", "$v10"); ("$k11", "$v11"); ("$k12", "$v12"); ("$k13", "$v13"); ("$k14", "$v14"); ("$k15", "$v15"); ("$k16", "$v16")])) in
      do:  ((globals.get #pkg_name' #"strToCode"%go) <-[mapT stringT Code] "$r0"))
      ).

End code.
End codes.
