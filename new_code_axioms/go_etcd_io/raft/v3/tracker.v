(* autogenerated by goose axiom generator; do not modify *)
From New.golang Require Import defn.

Section axioms.
Context `{ffi_syntax}.

Axiom Inflights : go_type.
Axiom Inflights__mset : list (string * val).
Axiom Inflights__mset_ptr : list (string * val).
Axiom NewInflights : val.
Axiom Inflights__Clone : val.
Axiom Inflights__Add : val.
Axiom Inflights__FreeLE : val.
Axiom Inflights__Full : val.
Axiom Inflights__Count : val.
Axiom Progress : go_type.
Axiom Progress__mset : list (string * val).
Axiom Progress__mset_ptr : list (string * val).
Axiom Progress__ResetState : val.
Axiom Progress__BecomeProbe : val.
Axiom Progress__BecomeReplicate : val.
Axiom Progress__BecomeSnapshot : val.
Axiom Progress__SentEntries : val.
Axiom Progress__CanBumpCommit : val.
Axiom Progress__SentCommit : val.
Axiom Progress__MaybeUpdate : val.
Axiom Progress__MaybeDecrTo : val.
Axiom Progress__IsPaused : val.
Axiom Progress__String : val.
Axiom ProgressMap : go_type.
Axiom ProgressMap__mset : list (string * val).
Axiom ProgressMap__mset_ptr : list (string * val).
Axiom ProgressMap__String : val.
Axiom StateType : go_type.
Axiom StateType__mset : list (string * val).
Axiom StateType__mset_ptr : list (string * val).
Axiom StateProbe : expr.
Axiom StateReplicate : expr.
Axiom StateSnapshot : expr.
Axiom StateType__String : val.
Axiom Config : go_type.
Axiom Config__mset : list (string * val).
Axiom Config__mset_ptr : list (string * val).
Axiom Config__String : val.
Axiom Config__Clone : val.
Axiom ProgressTracker : go_type.
Axiom ProgressTracker__mset : list (string * val).
Axiom ProgressTracker__mset_ptr : list (string * val).
Axiom MakeProgressTracker : val.
Axiom ProgressTracker__ConfState : val.
Axiom ProgressTracker__IsSingleton : val.
Axiom matchAckIndexer__AckedIndex : val.
Axiom ProgressTracker__Committed : val.
Axiom ProgressTracker__Visit : val.
Axiom ProgressTracker__QuorumActive : val.
Axiom ProgressTracker__VoterNodes : val.
Axiom ProgressTracker__LearnerNodes : val.
Axiom ProgressTracker__ResetVotes : val.
Axiom ProgressTracker__RecordVote : val.
Axiom ProgressTracker__TallyVotes : val.

End axioms.
