# PHASE161E Execution Plan

## Scope

PHASE161E builds the accepted-change memory refresh loop:

`ACCEPTED_CHANGE -> SELF_MAP_REFRESH -> SELF_KNOWLEDGE_READY`

This phase does not create a new body-map system. It reuses the PHASE161D hardened classifier and derived map outputs, then adds acceptance-memory metadata and a self-memory report.

## Reused PHASE161C/D Modules

- `modules/build_builder_agent_body_map_001.ps1`: reused as the central body-map generator and classifier.
- `modules/update_builder_self_model_active_map_001.ps1`: kept as existing direct builder wrapper; PHASE161E adds an acceptance-specific wrapper instead of replacing it.
- `modules/inspect_builder_agent_body_map_freshness_001.ps1`: kept as read-only map artifact presence inspector; PHASE161E avoids making passive stale detection the main behavior.

## Accepted-Change Detection

The refresh module accepts `AcceptedSubjectHead` explicitly. It also records `generated_from_worktree_head` from `git rev-parse HEAD`. This separates the functional baseline being described from the uncommitted refresh artifacts being prepared.

## Refresh After Accepted Commit

`modules/invoke_builder_self_map_refresh_after_acceptance_001.ps1` will:

1. Run `build_builder_agent_body_map_001.ps1 -Build`.
2. Read regenerated PHASE161D outputs.
3. Add acceptance-memory fields to `SELF_MODEL_ACTIVE_MAP.json`.
4. Write `self_map_refresh_after_acceptance_result.json`.
5. Write `self_map_memory_report.md`.
6. Write `accepted_change_memory_snapshot.json`.

## Avoiding Passive Stale Behavior

Successful refresh writes:

- `map_refresh_status=SELF_KNOWLEDGE_READY`
- `self_knowledge_ready=true`
- `map_is_ready_for_next_decision=true`

If map artifacts are generated before their own commit, this is recorded as `map_artifact_commit_pending=true`, not as stale.

## Avoiding Self-Hash Recursion

The map distinguishes:

- `accepted_subject_head`: accepted functional/code baseline described by the map.
- `generated_from_worktree_head`: HEAD at generation time.
- `map_artifact_head`: commit containing refreshed artifacts, when known later.
- `map_artifact_commit_pending`: true during pre-commit refresh validation.

## SELF_MODEL_ACTIVE_MAP Fields

PHASE161E will add or ensure:

- `self_map_refresh_policy_id`
- `accepted_subject_head`
- `generated_from_worktree_head`
- `map_artifact_head`
- `map_artifact_commit_pending`
- `map_refresh_status`
- `self_knowledge_ready`
- `map_is_ready_for_next_decision`
- `memory_report_path`
- `refresh_result_path`
- `next_decision_reason`
- `recommended_next_learning_tasks`

## Future Acceptance Use

Future acceptance tasks should call:

```powershell
pwsh -NoProfile -File modules/invoke_builder_self_map_refresh_after_acceptance_001.ps1 -AcceptedSubjectHead <accepted_head> -AcceptedPhase <phase> -TriggerReason accepted_baseline
```

Then run the phase validator before commit/push.

## Files To Create Or Change

Create:

- `modules/invoke_builder_self_map_refresh_after_acceptance_001.ps1`
- `modules/inspect_builder_self_map_refresh_readiness_001.ps1`
- `modules/write_builder_self_map_memory_report_001.ps1`
- `modules/build_builder_accepted_change_memory_snapshot_001.ps1`
- `modules/validate_builder_acceptance_self_map_refresh_contract_001.ps1`
- `validators/validate_phase161e_self_map_auto_refresh_after_acceptance_v1.ps1`
- `reports/self_development/self_map_refresh_policy.json`
- `reports/self_development/self_map_refresh_after_acceptance_result.json`
- `reports/self_development/self_map_memory_report.md`
- `reports/self_development/accepted_change_memory_snapshot.json`
- `reports/self_development/PHASE161E_SELF_MAP_AUTO_REFRESH_REPORT.md`
- `proofs/self_development/PHASE161E_SELF_MAP_AUTO_REFRESH_PROOF.json`
- `route_change_requests/PHASE161E_SELF_MAP_AUTO_REFRESH_REQUEST.md`
- `reports/self_development/PHASE161E_SELF_MAP_AUTO_REFRESH_CODEX_DELIVERY.md`
- `reports/self_development/PHASE161E_ACCEPT_BASELINE_COMMIT_PUSH_DELIVERY.md`

Update regenerated map outputs under `reports/self_development`, including `SELF_MODEL_ACTIVE_MAP.json`.

## What Will Not Be Modified

Protected source-of-truth files remain read-only:

- `TASK_QUEUE.json`
- `GENESIS_STATE.json`
- `CAPABILITY_ROADMAP.json`
- `packs/registry.json`
- `orchestrator/run.ps1`

No runtime outputs are staged. No packages are installed. No deletion, body repair pack, external agent, or protected-state promotion is included.

## Validation Strategy

The validator will prove parser health, run the refresh module against accepted HEAD `a8f72a12ee931da0a8146da40259c38b3ea65438`, inspect the acceptance refresh contract, confirm memory report and snapshot exist, confirm gap chains and live evidence separation remain present, confirm active/proven counts do not regress to PHASE161C over-optimistic counts, and confirm protected state plus runtime staging safety.
