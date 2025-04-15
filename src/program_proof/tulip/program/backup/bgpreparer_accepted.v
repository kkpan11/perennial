From Perennial.program_proof.tulip.program Require Import prelude.
From Perennial.program_proof.tulip.program.backup Require Import bgpreparer_repr.

Section program.
  Context `{!heapGS Σ, !tulip_ghostG Σ}.

  (* Rather weak spec as it's used only in a performance optimization. *)
  Theorem wp_BackupGroupPreparer__accepted (gpp : loc) (rid : u64) phase rk ts gid γ :
    {{{ own_backup_gpreparer_srespm gpp phase rk ts gid γ }}}
      BackupGroupPreparer__accepted #gpp #rid
    {{{ (accepted : bool), RET #accepted; own_backup_gpreparer_srespm gpp phase rk ts gid γ }}}.
  Proof.
    (*@ func (gpp *BackupGroupPreparer) accepted(rid uint64) bool {             @*)
    (*@     _, accepted := gpp.srespm[rid]                                      @*)
    (*@     return accepted                                                     @*)
    (*@ }                                                                       @*)
  Admitted.

End program.
