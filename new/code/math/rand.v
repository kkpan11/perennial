(* autogenerated from math/rand *)
From New.golang Require Import defn.

Module rand.
Section code.
Context `{ffi_syntax}.


Axiom ke'init : val.

Axiom we'init : val.

Axiom fe'init : val.

Axiom kn'init : val.

Axiom wn'init : val.

Axiom fn'init : val.

Axiom randautoseed'init : val.

Axiom randseednop'init : val.

Axiom rngCooked'init : val.

Definition pkg_name' : go_string := "math/rand".

Definition vars' : list (go_string * go_type) := [].

Definition functions' : list (go_string * val) := [].

Definition msets' : list (go_string * (list (go_string * val))) := [].

Axiom _'init : val.

Definition initialize' : val :=
  rec: "initialize'" <> :=
    globals.package_init pkg_name' vars' functions' msets' (λ: <>,
      exception_do (do:  (ke'init #());;;
      do:  (we'init #());;;
      do:  (fe'init #());;;
      do:  (kn'init #());;;
      do:  (wn'init #());;;
      do:  (fn'init #());;;
      do:  (randautoseed'init #());;;
      do:  (randseednop'init #());;;
      do:  (rngCooked'init #()))
      ).

End code.
End rand.
