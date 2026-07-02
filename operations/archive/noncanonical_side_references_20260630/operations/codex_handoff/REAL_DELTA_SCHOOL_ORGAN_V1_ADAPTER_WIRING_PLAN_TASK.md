# REAL_DELTA_SCHOOL_ORGAN_V1_ADAPTER_WIRING_PLAN_TASK

Status: CODEX_TASK_READY_FOR_PREFLIGHT_ONLY

## Purpose

Create a bounded adapter/wiring plan for `REAL_DELTA_SCHOOL_ORGAN_V1` that connects existing components into one parametric school organ contract.

This task is not to implement the runner yet. It is to produce a precise wiring plan and smallest safe implementation proposal.

## Current proven context

- `AGENTS.md` is the active Codex command file.
- `REAL_DELTA_SCHOOL_EXISTING_BODY_SCAN_V1` is valid.
- `REAL_DELTA_SCHOOL_ORGAN_V1_PASSPORT_CONTRACT` is valid.
- `REAL_DELTA_SCHOOL_CYCLE_V1` is lab real-delta harness proof only, not live intelligence.
- `REAL_DELTA_SCHOOL_CYCLE_V1_REVIEW` is held-out review with limitations, not live runtime proof.
- `REAL_DELTA_SCHOOL_SCALE_GATE_V1` is `SUPERSEDED_WRONG_DIRECTION`; do not continue it.
- `runtime_ready=false`.

## Mandatory PREFLIGHT rule

No file writes before `PREFLIGHT_PASS`.

Codex must first report:

```text
STATUS: PREFLIGHT_PASS
```

or:

```text
STATUS: BLOCKED_PREFLIGHT
```

If blocked, Codex must not modify files.

Final report must include:

```text
Files changed before PREFLIGHT_PASS: YES/NO
Expected: NO
```

## Exact read list

Codex may read only these files unless it declares `BLOCKED_PREFLIGHT` and asks for an explicit expanded read list:

```text
AGENTS.md
operations/overnight_school/REAL_DELTA_SCHOOL_EXISTING_BODY_SCAN_V1.json
operations/overnight_school/validate_real_delta_school_existing_body_scan_v1.ps1
operations/overnight_school/REAL_DELTA_SCHOOL_ORGAN_V1_PASSPORT.json
operations/overnight_school/REAL_DELTA_SCHOOL_ORGAN_V1_PARAMETRIC_CONTRACT.json
operations/overnight_school/validate_real_delta_school_organ_v1_passport_contract.ps1
operations/overnight_school/REAL_DELTA_SCHOOL_CYCLE_V1_REQUIREMENT.json
operations/overnight_school/run_real_delta_school_cycle_v1.ps1
operations/overnight_school/validate_real_delta_school_cycle_v1.ps1
operations/overnight_school/run_real_delta_school_cycle_v1_review.ps1
operations/overnight_school/validate_real_delta_school_cycle_v1_review.ps1
operations/overnight_school/run_useful_school_30k_full_process_v1.ps1
operations/overnight_school/validate_useful_school_30k_full_process_v1.ps1
validators/validate_candidate_intake_report_contract_v1.ps1
validators/validate_phase162_atom_accept_readiness_gate_v1.ps1
validators/validate_phase162_atom_executed_use_proof_v1.ps1
validators/validate_phase162_atom_usefulness_safety_blockers_v1.ps1
validators/validate_phase165s_c1_lesson_to_atom_bridge_v1.ps1
modules/invoke_useful_curriculum_school_supervisor_v1.ps1
modules/write_builder_lesson_result_001.ps1
modules/normalize_builder_lesson_batch_001.ps1
modules/invoke_phase162_controller_consume_controlled_accept_candidate_batch_001.ps1
operations/self_map/invoke_self_map_auto_update_trigger_v1.ps1
operations/self_map/validate_self_map_auto_update_trigger_v1.ps1
```

## Hard cut list

Do not read:

```text
zz_MUSORKA_DO_NOT_READ_BY_CODEX/**
operations/quarantine/**
operations/self_map/SELF_UPDATING_BODY_CAPABILITY_MAP_STATE_V1.json
operations/self_map/SELF_UPDATING_BODY_CAPABILITY_MAP_AUTO_UPDATE_V1_REPORT.json
operations/self_map/SELF_MAP_AUTO_UPDATE_TRIGGER_V1_EVENTS.jsonl
```

Do not ingest the whole repo.
Do not use `grep -R` or recursive full-repo scans.
Do not run 30K.
Do not continue or repair `REAL_DELTA_SCHOOL_SCALE_GATE_V1`.
Do not claim live intelligence or runtime readiness.

## Allowed output/write scope

If and only if `PREFLIGHT_PASS` is declared, Codex may write only:

```text
operations/codex_handoff/REAL_DELTA_SCHOOL_ORGAN_V1_ADAPTER_WIRING_PLAN.md
operations/codex_handoff/REAL_DELTA_SCHOOL_ORGAN_V1_ADAPTER_WIRING_PLAN_REPORT.md
```

No source code implementation files are allowed in this task.
No validators may be created in this task.
No existing files may be modified in this task.

## Required plan content

The wiring plan must include:

1. Purpose of the adapter/wiring layer.
2. Existing components reused, mapped to lifecycle stages.
3. Parametric invocation contract:
   - `CandidateFeedPath`
   - `TargetAccepted`
   - `BatchSize`
   - `ProofMode`
   - `MapAggregationLevel`
   - `ResumeFromCheckpoint`
   - `CandidateSourceMode`
4. Proposed lifecycle sequence:
   - candidate feed received
   - candidate intake validated
   - curriculum ladder built
   - before exam recorded
   - lesson comprehension recorded
   - after exam recorded
   - causal use checked
   - anti-cheat negative tests passed
   - accepted/rejected atoms written
   - batch/capability digest written
   - map updated at rollup only
5. What existing file/function/script should be reused for each stage.
6. Gaps that require a later implementation task.
7. Exact future implementation cut-list.
8. Exact future validator cut-list.
9. Proof boundary: lab only, runtime_ready=false.
10. Risks and blockers.
11. Why this avoids duplicate school construction.
12. Why N is a parameter, not architecture.
13. Why atom/subchunk events must not update the map.

## Required final report

Codex final report must include:

```text
STATUS: PREFLIGHT_PASS | BLOCKED_PREFLIGHT
Files changed before PREFLIGHT_PASS: YES/NO
Files read:
Files changed:
Out-of-scope respected: YES/NO
Whole repo scan avoided: YES/NO
zz_MUSORKA avoided: YES/NO
operations/quarantine avoided: YES/NO
30K run avoided: YES/NO
REAL_DELTA_SCHOOL_SCALE_GATE_V1 avoided: YES/NO
runtime_ready claimed true: YES/NO
Validation performed:
Remaining blockers:
```
