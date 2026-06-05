# Agent Body Map

Status: `DERIVED_FROM_EXISTING`

This PHASE161C map reuses existing protected state, self-knowledge, self-model, body registry, capability shelf, route locks, modules, validators, reports, proofs, docs, packs, and orchestrator files. It is a derived active-map candidate, not a replacement for protected source-of-truth state.

Artifacts scanned: 1361
Graph nodes: 1361
Graph edges: 3808
Function inventory entries: 579
Stub or placeholder entries: 52
Orphan candidates: 0

## Important Gaps

- $(@{gap_id=GAP_PROTECTED_STATE_PROMOTION_BLOCKED; why_status=Protected state files are source-of-truth but read-only in PHASE161C, so the active self-model must remain derived until owner approves promotion.; blocking_dependency_chain=System.Object[]; recommended_next_action=Review derived SELF_MODEL_ACTIVE_MAP.json and approve a later protected-state update candidate if desired.; safe_to_repair_now=False}.gap_id): Protected state files are source-of-truth but read-only in PHASE161C, so the active self-model must remain derived until owner approves promotion.
- $(@{gap_id=GAP_SPLIT_SELF_MODEL_ORGANS; why_status=Self-model, self-knowledge, body registry, and capability shelf exist in separate places and were not one current body map.; blocking_dependency_chain=System.Object[]; recommended_next_action=Use PHASE161C derived map as synchronization layer.; safe_to_repair_now=True}.gap_id): Self-model, self-knowledge, body registry, and capability shelf exist in separate places and were not one current body map.
- $(@{gap_id=GAP_VALIDATOR_ONLY_EVIDENCE; why_status=Some artifacts have validator or report references but no live/runtime proof marker, so they cannot be called live-proven.; blocking_dependency_chain=System.Object[]; recommended_next_action=Separate validator-proven from live-proven in future acceptance tasks.; safe_to_repair_now=True}.gap_id): Some artifacts have validator or report references but no live/runtime proof marker, so they cannot be called live-proven.
- $(@{gap_id=GAP_ORPHANED_PRESENT_ARTIFACTS; why_status=Static scan found present artifacts with no detected caller, route, validator, report, or proof reference.; blocking_dependency_chain=System.Object[]; recommended_next_action=Classify orphans before any cleanup; do not delete in PHASE161C.; safe_to_repair_now=False}.gap_id): Static scan found present artifacts with no detected caller, route, validator, report, or proof reference.
- $(@{gap_id=GAP_STUB_PLACEHOLDER_ARTIFACTS; why_status=Placeholder or near-empty artifacts exist and should not be mistaken for active organs.; blocking_dependency_chain=System.Object[]; recommended_next_action=Repair only when tied to a specific accepted route.; safe_to_repair_now=False}.gap_id): Placeholder or near-empty artifacts exist and should not be mistaken for active organs.
- $(@{gap_id=GAP_SAFETY_SENSITIVE_OPERATIONS_REQUIRE_REVIEW; why_status=Some scripts contain git, deletion, runtime-write, or protected-write signals; they need explicit safety review before reuse.; blocking_dependency_chain=System.Object[]; recommended_next_action=Keep risky candidates in unsafe debt backlog.; safe_to_repair_now=False}.gap_id): Some scripts contain git, deletion, runtime-write, or protected-write signals; they need explicit safety review before reuse.
