(* autogenerated by goose axiom generator; do not modify *)
From New.golang Require Import defn.

Section axioms.
Context `{ffi_syntax}.

Axiom ParseBool : val.
Axiom FormatBool : val.
Axiom AppendBool : val.
Axiom ParseComplex : val.
Axiom ParseFloat : val.
Axiom ErrRange : (go_string * go_string).
Axiom ErrSyntax : (go_string * go_string).
Axiom NumError : go_type.
Axiom NumError__mset : list (go_string * val).
Axiom NumError__mset_ptr : list (go_string * val).
Axiom NumError__Error : val.
Axiom NumError__Unwrap : val.
Axiom IntSize : Z.
Axiom ParseUint : val.
Axiom ParseInt : val.
Axiom Atoi : val.
Axiom FormatComplex : val.
Axiom decimal__String : val.
Axiom decimal__Assign : val.
Axiom decimal__Shift : val.
Axiom decimal__Round : val.
Axiom decimal__RoundDown : val.
Axiom decimal__RoundUp : val.
Axiom decimal__RoundedInteger : val.
Axiom FormatFloat : val.
Axiom AppendFloat : val.
Axiom FormatUint : val.
Axiom FormatInt : val.
Axiom Itoa : val.
Axiom AppendInt : val.
Axiom AppendUint : val.
Axiom Quote : val.
Axiom AppendQuote : val.
Axiom QuoteToASCII : val.
Axiom AppendQuoteToASCII : val.
Axiom QuoteToGraphic : val.
Axiom AppendQuoteToGraphic : val.
Axiom QuoteRune : val.
Axiom AppendQuoteRune : val.
Axiom QuoteRuneToASCII : val.
Axiom AppendQuoteRuneToASCII : val.
Axiom QuoteRuneToGraphic : val.
Axiom AppendQuoteRuneToGraphic : val.
Axiom CanBackquote : val.
Axiom UnquoteChar : val.
Axiom QuotedPrefix : val.
Axiom Unquote : val.
Axiom IsPrint : val.
Axiom IsGraphic : val.
Axiom initialize' : val.
End axioms.
