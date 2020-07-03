(** Just testing which admits are needed by some top-level theorems *)
From Perennial.program_proof.examples Require Import
     replicated_block_proof single_inode_proof dir_proof.

Print Assumptions replicated_block_proof.OpenRead_adequate.
Print Assumptions single_inode_proof.wpc_Open.
Print Assumptions single_inode_proof.wpc_Read.
Print Assumptions single_inode_proof.wpc_Append.
Print Assumptions dir_proof.wpc_Open.
Print Assumptions dir_proof.wpc_Read.
Print Assumptions dir_proof.wpc_Append.
