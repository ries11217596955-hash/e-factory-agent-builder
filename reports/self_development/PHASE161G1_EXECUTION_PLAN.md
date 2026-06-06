# PHASE161G1 Execution Plan

## Candidate Files Read

- `reports/self_development/protected_state_update_candidates/GENESIS_STATE_update_candidate.json`
- `reports/self_development/protected_state_update_candidates/CAPABILITY_ROADMAP_update_candidate.json`
- `reports/self_development/protected_state_update_candidates/TASK_QUEUE_update_candidate.json`
- `reports/self_development/protected_state_update_candidates/PHASE161F_PROMOTION_MANIFEST.json`
- `reports/self_development/protected_state_update_candidates/PHASE161F_RISK_REVIEW.json`
- `reports/self_development/protected_state_update_candidates/PHASE161F_PROTECTED_STATE_SYNC_PLAN.md`

## Protected Consumer Search Strategy

Search repository text for each protected filename and classify matches as:

- direct reader or runtime consumer;
- validator consumer;
- pack/payload historical implementation;
- report/proof/document reference;
- candidate or PHASE161G1 self-reference.

For executable PowerShell consumers, inspect access patterns for:

- `ConvertFrom-Json` parsing;
- named-property reads;
- exact top-level key counts;
- schema validation with additional-property rejection;
- whole-object equality or serialization assumptions;
- writes to protected state.

The compatibility matrix records evidence patterns and leaves unresolved strictness as `unknown`.

## GENESIS_STATE Compatibility Proof

The simulation will clone `GENESIS_STATE.json` in memory, add only the candidate `protected_self_model_memory` object, serialize and parse it, and prove:

- all existing top-level fields and values remain equal;
- `current_phase`, `current_capability`, readiness fields, and status claims remain unchanged;
- `evidence_boundary=DERIVED_MAP_REFERENCE_ONLY`;
- the metadata references PHASE161E readiness without reclassifying validator-only evidence as live proof;
- the protected file hash remains unchanged.

Decision is limited to `APPROVE_WITH_LIMITS` when direct consumers use tolerant named-property access and no strict extra-field rejection is found. Otherwise it is `DELAY`.

## CAPABILITY_ROADMAP Compatibility Proof

The simulation will clone `CAPABILITY_ROADMAP.json` in memory, add only the candidate `phase161e_self_map_auto_refresh` object, serialize and parse it, and prove:

- all existing roadmap fields and entries remain equal;
- no completed capability status changes;
- candidate status remains `ACCEPTED_EVIDENCE_REFERENCE_CANDIDATE`;
- `protected_promotion_status=OWNER_REVIEW_REQUIRED`;
- no validator-only evidence is promoted to live evidence;
- the protected file hash remains unchanged.

Decision is limited to `APPROVE_WITH_LIMITS` when no strict extra-field rejection is found. Otherwise it is `DELAY`.

## Delayed And Blocked Scope

- `TASK_QUEUE.json`: `DELAY`. Queue structure affects scheduling and requires separate queue-consumer and alias compatibility proof.
- `packs/registry.json`: `DELAY`. No real pack exists and an entry would create false admission/wiring.
- `orchestrator/run.ps1`: `REJECT`. No flow change is justified; orchestration requires a separately proven acceptance hook.

## Future Limited Apply Scope

A later `PHASE161G2_APPLY_LIMITED_PROTECTED_SELF_MODEL_REFERENCES` may apply only:

- `GENESIS_STATE.json.protected_self_model_memory`;
- `CAPABILITY_ROADMAP.json.phase161e_self_map_auto_refresh`;

and only when each PHASE161G1 decision is `APPROVE_WITH_LIMITS`, pre-apply hashes match, owner approval is explicit, rollback copies exist, and post-apply consumer checks pass.

## What Will Not Change

- No protected file.
- No candidate apply.
- No `current_phase`, `current_capability`, readiness, active task, route lock, pack admission, or orchestrator flow change.
- No validator-only evidence promotion.
- No full body-map copy.
- No runtime output staging.
