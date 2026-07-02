# REAL_DELTA_SCHOOL_ORGAN_V1_STAGE1_IMPLEMENTATION_TASK

Status: CODEX_TASK_READY_FOR_PREFLIGHT_ONLY

## Purpose

Implement Stage-1 lab mechanics for `REAL_DELTA_SCHOOL_ORGAN_V1` from the accepted adapter/wiring plan.

Stage-1 is not full runtime intelligence, not accepted-core mutation, not 30K, and not map positive update. It is a small parametric runner and validator set proving that `CandidateFeedPath` + `TargetAccepted` can drive useful atom acceptance mechanics with real-delta invariants.

## Mandatory PREFLIGHT rule

No file writes before `PREFLIGHT_PASS`.

Codex must first report exactly one of:

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

## Current proven context

- `REAL_DELTA_SCHOOL_ORGAN_V1_ADAPTER_WIRING_PLAN.md` exists and is `CODEX_DRAFT` from a prior bounded Codex run.
- `REAL_DELTA_SCHOOL_ORGAN_V1_ADAPTER_WIRING_PLAN_REPORT.md` reports `PREFLIGHT_PASS` and `PASS_STATIC_HANDOFF_CONTENT`.
- `REAL_DELTA_SCHOOL_ORGAN_V1_PASSPORT_CONTRACT` is valid.
- `REAL_DELTA_SCHOOL_EXISTING_BODY_SCAN_V1` is valid.
- `REAL_DELTA_SCHOOL_CYCLE_V1` is lab proof only, not live intelligence.
- `REAL_DELTA_SCHOOL_CYCLE_V1_REVIEW` is held-out review with limitations, not live runtime proof.
- `REAL_DELTA_SCHOOL_SCALE_GATE_V1` is `SUPERSEDED_WRONG_DIRECTION`; do not continue it.
- `runtime_ready=false`.

## Exact read list

Codex may read only these files unless it declares `BLOCKED_PREFLIGHT` and requests an explicit expanded read list:

```text
AGENTS.md
operations/codex_handoff/REAL_DELTA_SCHOOL_ORGAN_V1_ADAPTER_WIRING_PLAN.md
operations/codex_handoff/REAL_DELTA_SCHOOL_ORGAN_V1_ADAPTER_WIRING_PLAN_REPORT.md
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
CAPABILITY_ROADMAP.json
GENESIS_STATE.json
TASK_QUEUE.json
packs/registry.json
orchestrator/run.ps1
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
Do not use recursive full-repo scans.
Do not run 30K.
Do not continue or repair `REAL_DELTA_SCHOOL_SCALE_GATE_V1`.
Do not mutate accepted core.
Do not call positive self-map update.
Do not claim live intelligence or runtime readiness.

## Allowed output/write scope

If and only if `PREFLIGHT_PASS` is declared, Codex may create only these new files:

```text
operations/overnight_school/run_real_delta_school_organ_v1.ps1
operations/overnight_school/validate_real_delta_school_organ_v1_candidate_feed_contract.ps1
operations/overnight_school/validate_real_delta_school_organ_v1_run_output_contract.ps1
operations/overnight_school/validate_real_delta_school_organ_v1_small_proof.ps1
operations/overnight_school/REAL_DELTA_SCHOOL_ORGAN_V1_SAMPLE_FEED.json
tests/accepted_atom_retention/REAL_DELTA_SCHOOL_ORGAN_V1_SMALL_PROOF.json
operations/codex_handoff/REAL_DELTA_SCHOOL_ORGAN_V1_STAGE1_IMPLEMENTATION_REPORT.md
```

No existing files may be modified.
No commits or pushes.
No generated self-map state/report/log reads.

## Required Stage-1 runner behavior

Create `operations/overnight_school/run_real_delta_school_organ_v1.ps1` with parameters:

```text
-CandidateFeedPath <string>
-TargetAccepted <int>
-BatchSize <int> default 5
-ProofPath <string> default tests/accepted_atom_retention/REAL_DELTA_SCHOOL_ORGAN_V1_SMALL_PROOF.json
-ProofMode <full|small> default small
-CandidateSourceMode <OWNER_SUPPLIED|SELF_PRACTICE_DERIVED|FAILURE_DERIVED|QUARANTINE_DERIVED|REPO_CHANGE_DERIVED> default OWNER_SUPPLIED
-ResumeFromCheckpoint <switch>
```

Runner requirements:

1. Use `TargetAccepted` as parameter; do not hardcode 5 as architecture.
2. Validate `CandidateFeedPath` through the new feed validator before accepting candidates.
3. Require at least `TargetAccepted` valid candidates or fail with clear error.
4. Produce proof schema `real_delta_school_organ_v1_small_proof`.
5. Set proof label `PROVEN_LAB_PARAMETRIC_ORGAN_STAGE1_NOT_RUNTIME_INTELLIGENCE`.
6. Set `runtime_ready=false` and never set `runtime_ready=true`.
7. Record run params: `candidate_feed_path`, `target_accepted`, `batch_size`, `proof_mode`, `candidate_source_mode`, `resume_from_checkpoint`.
8. Accept exactly `TargetAccepted` candidates in the small proof run.
9. Each accepted atom must include id/domain/concept/useful_for/comprehension/before_score/after_score/improved/causal_atom_link/retrieval_used/accepted.
10. Require `after_score > before_score`, `improved=true`, `retrieval_used=true`, causal link to current atom id.
11. Include batch digest/checkpoint summary, not map update.
12. Include map rollup policy proof with atom/subchunk should_update=false and no positive map invocation.
13. Include negative tests all `BLOCKED`: count-only false pass, duplicate candidate, runtime_ready overclaim, scale-gate route, atom map update, subchunk map update.
14. Include protected hashes before/after for `CAPABILITY_ROADMAP.json`, `GENESIS_STATE.json`, `TASK_QUEUE.json`, `packs/registry.json`, `orchestrator/run.ps1`; changed list must be empty.
15. Do not mutate accepted core.
16. Do not run 30K.

## Required candidate feed schema

Create `operations/overnight_school/REAL_DELTA_SCHOOL_ORGAN_V1_SAMPLE_FEED.json` with schema:

```text
real_delta_school_organ_v1_candidate_feed
```

Required top-level fields:

```text
schema
candidate_source_mode
runtime_ready
candidates
```

Each candidate must include:

```text
candidate_id
domain
concept
useful_for
lesson
before_answer
after_answer
anti_apply
expected_use
```

Sample feed must contain at least 5 non-identical candidates across multiple domains.

## Required validators

### Candidate feed contract validator

`validate_real_delta_school_organ_v1_candidate_feed_contract.ps1` must validate the feed schema, required top-level fields, required candidate fields, non-duplicate candidate ids, non-identical useful concepts, `runtime_ready=false`, candidate count >= optional `-MinCandidates`.

### Run output contract validator

`validate_real_delta_school_organ_v1_run_output_contract.ps1` must validate proof schema/status/proof_label/run params/runtime_ready=false/protected hashes unchanged/accepted_total equals target_accepted/no rejected accepted as true/no scale-gate route/no 30K.

### Small proof validator

`validate_real_delta_school_organ_v1_small_proof.ps1` must run both feed and output validators and also validate per-atom real-delta invariants, negative tests, map rollup suppression, batch digest/checkpoint summary, and absence of literal `runtime_ready=true` in the proof.

## Required validation run

After implementation, Codex must run:

```powershell
& operations/overnight_school/validate_real_delta_school_organ_v1_candidate_feed_contract.ps1 -FeedPath operations/overnight_school/REAL_DELTA_SCHOOL_ORGAN_V1_SAMPLE_FEED.json -MinCandidates 5
& operations/overnight_school/run_real_delta_school_organ_v1.ps1 -CandidateFeedPath operations/overnight_school/REAL_DELTA_SCHOOL_ORGAN_V1_SAMPLE_FEED.json -TargetAccepted 5 -BatchSize 5 -ProofMode small -CandidateSourceMode OWNER_SUPPLIED
& operations/overnight_school/validate_real_delta_school_organ_v1_run_output_contract.ps1 -ProofPath tests/accepted_atom_retention/REAL_DELTA_SCHOOL_ORGAN_V1_SMALL_PROOF.json
& operations/overnight_school/validate_real_delta_school_organ_v1_small_proof.ps1 -FeedPath operations/overnight_school/REAL_DELTA_SCHOOL_ORGAN_V1_SAMPLE_FEED.json -ProofPath tests/accepted_atom_retention/REAL_DELTA_SCHOOL_ORGAN_V1_SMALL_PROOF.json
```

Expected output must include:

```text
VALIDATION_PASS=REAL_DELTA_SCHOOL_ORGAN_V1_CANDIDATE_FEED_CONTRACT_VALID
REAL_DELTA_SCHOOL_ORGAN_V1_RUN=PASS
VALIDATION_PASS=REAL_DELTA_SCHOOL_ORGAN_V1_RUN_OUTPUT_CONTRACT_VALID
VALIDATION_PASS=REAL_DELTA_SCHOOL_ORGAN_V1_SMALL_PROOF_VALID
RUNTIME_READY=false
```

## Required final report

Codex final report must include:

```text
STATUS: PREFLIGHT_PASS | BLOCKED_PREFLIGHT
Files changed before PREFLIGHT_PASS: YES/NO
Files read:
Files changed:
Validation commands run:
Validation result:
Out-of-scope respected: YES/NO
Whole repo scan avoided: YES/NO
zz_MUSORKA avoided: YES/NO
operations/quarantine avoided: YES/NO
30K run avoided: YES/NO
REAL_DELTA_SCHOOL_SCALE_GATE_V1 avoided: YES/NO
accepted core mutated: YES/NO
positive self-map update called: YES/NO
runtime_ready claimed true: YES/NO
Remaining blockers:
RUNTIME_READY=false
```
