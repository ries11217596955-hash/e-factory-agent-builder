# Agent Body Map

Status: `DERIVED_FROM_EXISTING`

This PHASE161C map reuses existing protected state, self-knowledge, self-model, body registry, capability shelf, route locks, modules, validators, reports, proofs, docs, packs, and orchestrator files. It is a derived active-map candidate, not a replacement for protected source-of-truth state.

Artifacts scanned: 1644
Graph nodes: 1644
Graph edges: 4926
Function inventory entries: 652
Stub or placeholder entries: 2
False-positive stub entries: 89
Orphan candidates: 250
Historical reference entries: 204
Superseded entries: 1

## Important Gaps

- $(@{gap_id=GAP_PROTECTED_STATE_PROMOTION_BLOCKED; why_status=Protected state files are source-of-truth but read-only in PHASE161C, so the active self-model must remain derived until owner approves promotion.; blocking_dependency_chain=System.Object[]; recommended_next_action=Review derived SELF_MODEL_ACTIVE_MAP.json and approve a later protected-state update candidate if desired.; safe_to_repair_now=False}.gap_id): Protected state files are source-of-truth but read-only in PHASE161C, so the active self-model must remain derived until owner approves promotion.
- $(@{gap_id=GAP_SPLIT_SELF_MODEL_ORGANS; why_status=Self-model, self-knowledge, body registry, and capability shelf exist in separate places and were not one current body map.; blocking_dependency_chain=System.Object[]; recommended_next_action=Use PHASE161C derived map as synchronization layer.; safe_to_repair_now=True}.gap_id): Self-model, self-knowledge, body registry, and capability shelf exist in separate places and were not one current body map.
- $(@{gap_id=GAP_VALIDATOR_ONLY_EVIDENCE; why_status=Artifacts with validator/proof/report references must remain separated from live-runtime proven artifacts until current wiring and live evidence are present.; blocking_dependency_chain=System.Object[]; recommended_next_action=Use live_evidence_separation_index.json before promoting any artifact to active live-proven.; safe_to_repair_now=True}.gap_id): Artifacts with validator/proof/report references must remain separated from live-runtime proven artifacts until current wiring and live evidence are present.
- $(@{gap_id=GAP_ORPHANED_PRESENT_ARTIFACTS; why_status=PHASE161D now exposes disconnected and historical artifacts rather than suppressing them through broad proof/report matching.; blocking_dependency_chain=System.Object[]; recommended_next_action=Inspect orphaned_artifact_inventory.json and historical_reference_inventory.json before any cleanup.; safe_to_repair_now=False}.gap_id): PHASE161D now exposes disconnected and historical artifacts rather than suppressing them through broad proof/report matching.
- $(@{gap_id=GAP_STUB_PLACEHOLDER_ARTIFACTS; why_status=Stub detection must distinguish executable not-implemented behavior from documentation that merely discusses placeholder rules.; blocking_dependency_chain=System.Object[]; recommended_next_action=Use stub_false_positive_inventory.json before opening repair tasks.; safe_to_repair_now=False}.gap_id): Stub detection must distinguish executable not-implemented behavior from documentation that merely discusses placeholder rules.
- $(@{gap_id=GAP_ROUTE_SUPERSESSION_PROPAGATION; why_status=Route-lock supersession must be propagated into artifact status so old route locks are not reported as current active organs.; blocking_dependency_chain=System.Object[]; recommended_next_action=Keep superseded artifacts as historical evidence unless owner approves route change or archive policy.; safe_to_repair_now=True}.gap_id): Route-lock supersession must be propagated into artifact status so old route locks are not reported as current active organs.
- $(@{gap_id=GAP_SAFETY_SENSITIVE_OPERATIONS_REQUIRE_REVIEW; why_status=Some scripts contain git, deletion, runtime-write, or protected-write signals; they need explicit safety review before reuse.; blocking_dependency_chain=System.Object[]; recommended_next_action=Keep risky candidates in unsafe debt backlog.; safe_to_repair_now=False}.gap_id): Some scripts contain git, deletion, runtime-write, or protected-write signals; they need explicit safety review before reuse.
