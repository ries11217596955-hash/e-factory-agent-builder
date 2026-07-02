# USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_IMPLEMENT_V1

STATUS: CODEX_IMPLEMENTATION_TASK
MODE: PHASED_IMPLEMENTATION_WITH_SELF_CHECKS
RUNTIME_READY: false

## 0. Boundary

You are Codex acting as a bounded Builder tool/source teacher, not Builder brain and not proof by yourself.
Your output remains CODEX_DRAFT until Bridge/terminal validator passes.

No file writes before PREFLIGHT_PASS.
If preflight fails, write only the implementation report with BLOCKED_PREFLIGHT.

## 1. Required baseline

Repo root:
C:/Users/Azerbaijan/Downloads/e-factory-agent-builder

Branch:
thin-control

Required HEAD:
0391667e5c056eda67f2f24a350a57eabb7350a8

Required plan report:
operations/codex_handoff/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_PLAN_V1_REPORT.md

Required previous assets to inspect and reuse where appropriate:
- modules/invoke_useful_knowledge_ladder_candidate_generator_v1.ps1
- modules/invoke_useful_curriculum_school_supervisor_v1.ps1
- tests/accepted_atom_retention/USEFUL_KNOWLEDGE_LADDER_5000_PROOF_V1.json
- tests/accepted_atom_retention/USEFUL_CURRICULUM_SCHOOL_SUPERVISOR_V1_PROOF.json
- validators/validate_useful_curriculum_school_supervisor_v1_proof.ps1

Known unrelated dirty files must not be touched:
- AGENTS.md
- .autonomy_test/CHATGPT_AUTONOMY_TEST.md
- CODEX_CANARY_TASK.md
- CODEX_CANARY_RESULT.md
- CODEX_CLI_CANARY_RESULT.md
- CODEX_RUNNER_V0_1_TARGET_CANARY_RESULT.md
- operations/codex_handoff/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_PLAN_V1.md
- operations/codex_handoff/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_PLAN_V1_REPORT.md
- operations/codex_handoff/audit_useful_school_30k_with_comprehension_and_delta_plan_v1.ps1
- operations/codex_handoff/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_IMPLEMENT_V1.md
- operations/codex_handoff/audit_useful_school_30k_with_comprehension_and_delta_implementation_v1.ps1

## 2. Goal

Implement a bounded V1 lab school package that proves the mechanics of:

before exam -> 30K useful school run -> atom comprehension exam -> digest -> compact competence deltas -> promotion gate -> after exam -> delta proof.

Important truth boundary:
This is PROVEN_LAB mechanics if validator passes.
This is not PROVEN_LIVE.
This is not runtime_ready.
This is not proof of free-life autonomy.

## 3. Required files to create/change

Create exactly these four implementation files:

1. modules/invoke_useful_school_30k_with_comprehension_and_delta_v1.ps1
2. tests/accepted_atom_retention/run_useful_school_30k_with_comprehension_and_delta_v1_proof.ps1
3. tests/accepted_atom_retention/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_V1_PROOF.json
4. validators/validate_useful_school_30k_with_comprehension_and_delta_v1_proof.ps1

Also create exactly one Codex implementation report:

5. operations/codex_handoff/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_IMPLEMENT_V1_REPORT.md

Do not edit any existing file unless it is one of the five paths above.
Do not commit.
Do not push.
Do not clean repo.

## 4. Implementation requirements

### Phase 1: PREFLIGHT

Before writing files:
- confirm repo root, branch, HEAD;
- confirm plan report exists;
- inspect required previous assets;
- inspect git status;
- confirm only allowed baseline dirty files plus allowed output paths are present;
- if conflict exists, return BLOCKED_PREFLIGHT and do not write implementation files.

Report must include:
Files changed before PREFLIGHT_PASS: NO

### Phase 2: Module

The module must expose a function with a stable name:
Invoke-UsefulSchool30KWithComprehensionAndDeltaV1

It must be parameterized:
- TargetAcceptedCount default 30000;
- ChunkSize default 5000;
- SubchunkSize default 100;
- DomainCount 10;
- MinimumRejectedTotal default at least 3000.

It must produce a compact proof object. Do not dump 30000 raw atoms into the proof JSON.

The proof object must include at least:
- schema = useful_school_30k_with_comprehension_and_delta_v1
- status = PASS when all checks pass
- target_accepted_count = 30000
- accepted_total = 30000
- rejected_total >= 3000
- chunk_count = 6
- subchunk_count = 300
- domain_count = 10
- before_exam_manifest_hash
- before_score
- after_score
- improved_case_count
- critical_regression_count
- proof_confusion_before
- proof_confusion_after
- unsafe_decision_before
- unsafe_decision_after
- understood_atom_total > 0
- not_understood_atom_total >= 0
- assimilated_atom_total > 0
- promoted_delta_count > 0
- quarantined_delta_count >= 0
- new_atoms_used_in_after_decisions > 0
- chunk_state_chain where chunk N input hash equals chunk N-1 output hash for N > 1
- reject classes: duplicate, low_quality, conflict_or_unsafe, non_actionable
- anti_mechanical_generation_checks with serial_pattern_guard, raw_dump_guard, accepted_count_only_guard
- legacy_runner_used = false
- codex_output_treated_as_proof = false
- runtime_ready = false

### Phase 3: Comprehension and digest mechanics

For each chunk summary, model these statuses:
CANDIDATE_ATOM, ACCEPTED_ATOM, UNDERSTOOD_ATOM, NOT_UNDERSTOOD_ATOM, ASSIMILATED_ATOM, PROMOTION_REJECTED.

Each chunk must show:
- accepted_count = 5000;
- rejected_count > 0;
- understood_count > 0;
- assimilated_count > 0;
- promoted_delta_count > 0;
- comprehension_sample_count > 0;
- each sample includes explain_back, apply, anti_apply, conflict_check, decision_delta, score, status.

Samples may be compact and bounded. Counts must prove the 30K run shape.

### Phase 4: Before/after exam mechanics

The module must create a frozen before exam manifest hash from stable exam case definitions.
The after exam must use the same manifest hash.
The proof must fail if:
- after_score <= before_score;
- improved_case_count <= 0;
- critical_regression_count > 0;
- unsafe_decision_after > unsafe_decision_before;
- proof_confusion_after > proof_confusion_before.

### Phase 5: Runner

The runner must import the module, run the default 30000 target proof, write the proof JSON to:
tests/accepted_atom_retention/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_V1_PROOF.json

Then it must invoke the validator.

The runner must print:
USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_STATUS=PASS
VALIDATION_PASS=USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_V1_PROVEN
RUNTIME_READY=false

### Phase 6: Validator

The validator must read the proof JSON and fail if any required metric is missing or invalid.
It must fail on:
- accepted_total != 30000;
- accepted_total without comprehension/delta metrics;
- after_score <= before_score;
- improved_case_count <= 0;
- critical_regression_count > 0;
- unsafe/proof confusion regression;
- promoted_delta_count <= 0;
- new_atoms_used_in_after_decisions <= 0;
- runtime_ready != false;
- legacy_runner_used != false;
- codex_output_treated_as_proof != false;
- chunk_state_chain broken;
- anti_mechanical_generation_checks missing or false;
- raw archive dump pattern in proof.

Validator must print:
VALIDATION_PASS=USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_V1_PROVEN
RUNTIME_READY=false

### Phase 7: Self-check and report

Run the runner and validator.
Write the implementation report with:
- STATUS: PASS | BLOCKED_PREFLIGHT | FAIL
- files inspected
- files created/changed
- commands run
- validation output
- final git status
- Files changed before PREFLIGHT_PASS: NO
- 30K_EXECUTED: YES only if runner actually produced accepted_total=30000 proof JSON
- RUNTIME_READY: false
- proof path
- validator status
- no commit/no push statement

## 5. Hard cut list

Do not:
- claim PROVEN_LIVE;
- set runtime_ready=true;
- edit AGENTS.md;
- edit registry/state/runtime stubs;
- clean repo;
- use old legacy 30K/300K runner as core path;
- produce raw 30000 atom JSON dump;
- accept Codex output as proof;
- commit or push.

## 6. Final response required in report

End report with exactly these fields:

STATUS:
TASK_MODE: PHASED_IMPLEMENTATION_WITH_SELF_CHECKS
FILES_CHANGED_BEFORE_PREFLIGHT_PASS:
FILES_CREATED_OR_CHANGED:
COMMANDS_RUN:
PROOF_PATH:
VALIDATOR_STATUS:
30K_EXECUTED:
RUNTIME_READY: false
COMMIT_DONE: NO
PUSH_DONE: NO
OWNER_DECISION_REQUIRED:

