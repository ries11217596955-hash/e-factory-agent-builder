# MAP_PATCH_CANDIDATE_V1

Status: PATCH_CANDIDATE_CREATED_NOT_APPLIED
Proof label: MAP_PATCH_CANDIDATE_NOT_MAP_MUTATION
Runtime ready: false

## Purpose
Stop the loop of rebuilding 100 / 1000 / 5000 / 30000 proof runners by making built capabilities and missing gaps visible in the existing body/capability map.

## Important boundary
- This file does not patch CAPABILITY_ROADMAP.json, GENESIS_STATE.json, TASK_QUEUE.json, or packs/registry.json.
- This is a review candidate only.
- No PROVEN_LIVE claim. No runtime_ready promotion.

## Proposed capability/gap entries

| capability | evidence | maturity | map action | must not repeat |
|---|---|---|---|---|
| compact_atom_storage_and_controlled_reuse_foundation | PROVEN_LAB_FOUNDATION_REMOTE_SYNCED_EARLIER | L0_STORAGE_L1_RETRIEVAL_L2_CONTROLLED_USE | UPSERT_OR_MERGE_EXISTING_FOUNDATION_ENTRY | do not build another storage/retrieval micro-runner unless regression suspected |
| legacy_ephemeral_1000_lane | LEGACY_BLOCKED | FAILED_OBSOLETE | MARK_BLOCKED_LEGACY_DO_NOT_ROUTE | do not repeat 1000 candidate test on this lane |
| useful_knowledge_ladder_5000 | PROVEN_LAB | SOURCE_LADDER_AND_ACCEPTANCE_GATE_HARNESS | UPSERT_CAPABILITY_AS_LAB_HARNESS_NOT_ORGAN | do not build another 5K ladder proof until this entry is represented in map |
| useful_curriculum_school_supervisor_v1 | PROVEN_LAB | SCHOOL_SUPERVISOR_HARNESS | UPSERT_CAPABILITY_AS_LAB_HARNESS_NOT_ORGAN | do not build another school supervisor; reuse this harness |
| useful_school_30k_full_process_v1 | PROVEN_LAB_MECHANICS_ONLY | COUNT_SCALE_PROCESS_HARNESS_NOT_LEARNING | ADD_AS_HARNESS_AND_EXPLICITLY_DOWNGRADE_REAL_LEARNING_CLAIM | do not run another 30K scale proof as next step |
| interrupted_codex_impl_v1_quarantine | QUARANTINED_CODEX_DRAFT_NOT_ACCEPTED | SAFETY_HYGIENE | KEEP_OUT_OF_ACTIVE_CAPABILITY_MAP_OR_MARK_QUARANTINE_ONLY | do not inspect/resurrect unless Owner explicitly decides |
| active_memory_runtime_use_and_real_delta_exam | NOT_PROVEN | MISSING_CORE_GAP | ADD_AS_EXPLICIT_NEXT_GAP_WITH_NO_RUNTIME_READY | blocks further 100/1000/5K/30K count-only runners |

## Next after review
Apply a minimal map patch only after review. The patch must let Builder answer: what exists, what is lab-only, what is legacy-blocked, what is quarantined, what is still NOT_PROVEN.
