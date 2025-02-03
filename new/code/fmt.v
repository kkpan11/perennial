(* autogenerated from fmt *)
From New.golang Require Import defn.

Module fmt.
Section code.
Context `{ffi_syntax}.


Axiom ppFree'init : val.

Axiom space'init : val.

Axiom ssFree'init : val.

Axiom errComplex'init : val.

Axiom errBool'init : val.

Definition pkg_name' : go_string := "fmt".

Definition vars' : list (go_string * go_type) := [("ppFree"%go, sync.Pool); ("space"%go, sliceT); ("ssFree"%go, sync.Pool); ("errComplex"%go, error); ("errBool"%go, error)].

Definition functions' : list (go_string * val) := [].

Definition msets' : list (go_string * (list (go_string * val))) := [].

End code.
End fmt.
