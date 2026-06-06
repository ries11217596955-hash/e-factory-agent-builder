# PHASE161F Execution Plan

## Objective

Prepare an owner-reviewable protected self-model promotion candidate without modifying protected source-of-truth files.

## Protected Files Read

- `TASK_QUEUE.json`
- `GENESIS_STATE.json`
- `CAPABILITY_ROADMAP.json`
- `packs/registry.json`
- `orchestrator/run.ps1`

These files are read for structure, size, and SHA-256 identity only. They remain read-only.

## Promotion Sources

- `reports/self_development/SELF_MODEL_ACTIVE_MAP.json`
- `reports/self_development/self_map_memory_report.md`
- `reports/self_development/self_map_refresh_after_acceptance_result.json`
- `reports/self_development/accepted_change_memory_snapshot.json`
- `reports/self_development/live_evidence_separation_index.json`
- `reports/self_development/self_model_gap_chain.json`
- `reports/self_development/agent_body_map.json`
- `proofs/self_development/PHASE161E_SELF_MAP_AUTO_REFRESH_PROOF.json`
- `route_locks/ACTIVE_ROUTE_LOCK.json`
- the active route-lock file referenced by that index

## Proposed Synchronization

Candidate metadata proposes:

- `GENESIS_STATE.json`: add a bounded derived self-model memory reference and readiness record.
- `CAPABILITY_ROADMAP.json`: add a PHASE161E self-map refresh capability evidence reference, without changing existing capability completion claims.
- `TASK_QUEUE.json`: add a future owner-approved review task for protected self-model promotion, without changing the current active task.
- `packs/registry.json`: add no pack automatically; record that PHASE161E is a module/report memory capability rather than an admitted pack.
- `orchestrator/run.ps1`: no direct change recommended. Future integration should remain an explicit acceptance workflow hook outside this candidate phase unless stronger flow evidence is approved.

The candidate excludes bulk body-map data, validator-only evidence promoted as live evidence, historical artifacts, and any automatic protected-state completion claims.

## Why Direct Mutation Is Not Performed

Protected state is repository source of truth. The derived map is ready for decisions but promotion changes ownership and compatibility contracts. Owner approval and a separate apply phase are required before any protected file may change.

## Candidate Format

Each JSON candidate records:

- target path and current identity
- source self-map head
- proposed update type
- proposed fields or sections
- reason and risk
- owner approval gate
- rollback note
- required validation

The orchestrator candidate is Markdown and defaults to no change.

## Risk Review

High risk:

- changing current phase, current task, readiness booleans, or orchestration flow
- copying all derived artifacts into protected state

Medium risk:

- adding new metadata sections that downstream strict schema consumers may not accept

Low risk:

- retaining candidate references under `reports/self_development/protected_state_update_candidates`

Rejected changes are recorded explicitly.

## Dry-Run Validation

The simulator:

1. Parses every JSON candidate.
2. Copies protected targets into a temporary directory.
3. Simulates adding a reserved candidate metadata envelope to the copies only.
4. Re-parses simulated JSON.
5. Verifies original hashes are unchanged.
6. Writes `PHASE161F_DRY_RUN_APPLY_RESULT.json`.

## Rollback Strategy

No protected rollback is needed in PHASE161F because no protected file is changed. A future approved apply phase must capture pre-apply hashes and copies, apply one target at a time, validate after each target, and restore exact pre-apply bytes on failure.

## Files To Create Or Update

Create the PHASE161F candidate builder, target inspector, risk writer, dry-run simulator, contract validator, phase validator, manifest, candidate files, risk review, rollback plan, report, proof, route request, Codex delivery, and accept delivery.

Update only the derived `SELF_MODEL_ACTIVE_MAP.json` with candidate identity/status/path fields.

## What Will Not Change

- No protected file content.
- No current task or route lock.
- No existing capability completion claim.
- No pack admission.
- No orchestrator behavior.
- No PHASE161D classifier behavior.
- No PHASE161E refresh behavior.
- No runtime output staging.
