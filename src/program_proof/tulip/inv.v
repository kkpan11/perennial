From Perennial.program_proof Require Import grove_prelude.
From Perennial.program_proof.tulip Require Import base.
From Perennial.program_proof.tulip Require Export inv_txnsys inv_key inv_group inv_replica.
  
Section inv.
  Context `{!heapGS Σ, !tulip_ghostG Σ}.
  (* TODO: remove this once we have real defintions for resources. *)
  Implicit Type (γ : tulip_names).

  Definition sysNS := nroot .@ "sys".
  Definition distxNS := sysNS .@ "distx".
  Definition tsNS := sysNS .@ "ts".

  Definition distx_inv γ p : iProp Σ :=
    (* txn invariants *)
    "Htxnsys"   ∷ txnsys_inv γ p ∗
    (* keys invariants *)
    "Hkeys"     ∷ ([∗ set] key ∈ keys_all, key_inv γ key) ∗
    (* groups invariants *)
    "Hgroups"   ∷ ([∗ set] gid ∈ gids_all, group_inv γ gid) ∗
    (* replica invariants *)
    "Hreplicas" ∷ ([∗ set] gid ∈ gids_all, [∗ set] rid ∈ rids_all, replica_inv γ gid rid).

  #[global]
  Instance distx_inv_timeless γ p :
    Timeless (distx_inv γ p).
  Admitted.

  Definition know_distx_inv γ p : iProp Σ :=
    inv distxNS (distx_inv γ p).

End inv.
