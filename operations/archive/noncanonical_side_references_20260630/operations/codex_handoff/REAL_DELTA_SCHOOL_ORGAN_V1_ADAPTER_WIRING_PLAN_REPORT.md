# REAL_DELTA_SCHOOL_ORGAN_V1 Adapter Wiring Plan Report

Status: CODEX_DRAFT
Preflight decision: PREFLIGHT_PASS
Files changed before PREFLIGHT_PASS: NO
Runtime readiness: runtime_ready=false

## Task Understanding

Create a bounded adapter/wiring plan for `REAL_DELTA_SCHOOL_ORGAN_V1` that connects existing components into one parametric school organ contract. This task is documentation and proposal only. It does not implement a runner, create validators, modify existing files, run 30K, continue `REAL_DELTA_SCHOOL_SCALE_GATE_V1`, or claim live runtime readiness.

## Scope Used

In scope:

- map existing components to lifecycle stages
- define the parametric invocation contract
- identify gaps and future implementation/validator cut-lists
- state lab-only proof boundary
- explain duplicate prevention, N-as-parameter, and rollup-only map policy
- write only the two handoff Markdown files

Out of scope:

- source implementation
- validator implementation
- edits to existing files
- proof/runtime execution
- 30K execution
- quarantine restore or quarantine reads
- self-map state/report/event-log reads
- live runtime or accepted-core mutation

## Files Read

- `AGENTS.md`
- `operations/overnight_school/REAL_DELTA_SCHOOL_EXISTING_BODY_SCAN_V1.json`
- `operations/overnight_school/validate_real_delta_school_existing_body_scan_v1.ps1`
- `operations/overnight_school/REAL_DELTA_SCHOOL_ORGAN_V1_PASSPORT.json`
- `operations/overnight_school/REAL_DELTA_SCHOOL_ORGAN_V1_PARAMETRIC_CONTRACT.json`
- `operations/overnight_school/validate_real_delta_school_organ_v1_passport_contract.ps1`
- `operations/overnight_school/REAL_DELTA_SCHOOL_CYCLE_V1_REQUIREMENT.json`
- `operations/overnight_school/run_real_delta_school_cycle_v1.ps1`
- `operations/overnight_school/validate_real_delta_school_cycle_v1.ps1`
- `operations/overnight_school/run_real_delta_school_cycle_v1_review.ps1`
- `operations/overnight_school/validate_real_delta_school_cycle_v1_review.ps1`
- `operations/overnight_school/run_useful_school_30k_full_process_v1.ps1`
- `operations/overnight_school/validate_useful_school_30k_full_process_v1.ps1`
- `validators/validate_candidate_intake_report_contract_v1.ps1`
- `validators/validate_phase162_atom_accept_readiness_gate_v1.ps1`
- `validators/validate_phase162_atom_executed_use_proof_v1.ps1`
- `validators/validate_phase162_atom_usefulness_safety_blockers_v1.ps1`
- `validators/validate_phase165s_c1_lesson_to_atom_bridge_v1.ps1`
- `modules/invoke_useful_curriculum_school_supervisor_v1.ps1`
- `modules/write_builder_lesson_result_001.ps1`
- `modules/normalize_builder_lesson_batch_001.ps1`
- `modules/invoke_phase162_controller_consume_controlled_accept_candidate_batch_001.ps1`
- `operations/self_map/invoke_self_map_auto_update_trigger_v1.ps1`
- `operations/self_map/validate_self_map_auto_update_trigger_v1.ps1`

## Files Changed

- `operations/codex_handoff/REAL_DELTA_SCHOOL_ORGAN_V1_ADAPTER_WIRING_PLAN.md`
- `operations/codex_handoff/REAL_DELTA_SCHOOL_ORGAN_V1_ADAPTER_WIRING_PLAN_REPORT.md`

## Preflight Evidence

- Repo root resolved to the current workspace.
- Branch resolved to `thin-control`.
- Origin URL contains `e-factory-agent-builder`.
- Required identity markers exist.
- The two allowed output targets did not exist before `PREFLIGHT_PASS`.
- Worktree had untracked workspace files, but no pre-existing target handoff files were modified by this task.

## Key Findings

- The body scan says no new school organ should be built from scratch.
- The passport and parametric contract already define the organ boundary and invocation shape.
- `REAL_DELTA_SCHOOL_CYCLE_V1` is a lab real-delta harness, not live intelligence.
- `REAL_DELTA_SCHOOL_CYCLE_V1_REVIEW` is held-out scripted review with limitations, not live runtime proof.
- `run_useful_school_30k_full_process_v1.ps1` is reusable only as scale/checkpoint/storage precedent and was not run.
- `REAL_DELTA_SCHOOL_SCALE_GATE_V1` remains superseded wrong direction.
- Some existing scripts contain old absolute `Set-Location` paths, so the future runner should use repo-root wrappers or explicitly authorized portability fixes.
- The self-map trigger blocks `atom` and `subchunk` aggregation levels and should be used only through rollup digests.

## Validation Plan For This Handoff

The bounded validation for this task is static artifact validation only:

- confirm both handoff files exist
- confirm required plan sections are present
- confirm `runtime_ready=false` appears
- confirm no claim sets `runtime_ready` to true
- confirm no disallowed implementation/source files were changed by this task

## Remaining Blockers For Future Implementation

- Build a portable parametric runner.
- Build a generic candidate feed validator.
- Define and validate the unified run output contract.
- Define strict `ProofMode` semantics.
- Add map rollup suppression tests without reading protected generated map state unless explicitly authorized.
- Prove any future runner with small bounded lab proof before larger runs.

## Boundary Confirmation

- Out-of-scope respected: YES
- Whole repo scan avoided: YES
- `zz_MUSORKA_DO_NOT_READ_BY_CODEX` avoided: YES
- `operations/quarantine` avoided: YES
- 30K run avoided: YES
- `REAL_DELTA_SCHOOL_SCALE_GATE_V1` avoided: YES
- `runtime_ready` claimed true: NO
