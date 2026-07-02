# USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_PLAN_V1_REPORT

STATUS: PREFLIGHT_PASS
TASK_MODE: PLAN_ONLY
FILES_CHANGED_BEFORE_PREFLIGHT_PASS: NO
FILES_CREATED_OR_CHANGED:
- operations/codex_handoff/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_PLAN_V1_REPORT.md
PLAN_REPORT_PATH: operations/codex_handoff/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_PLAN_V1_REPORT.md
30K_EXECUTED: NO
RUNTIME_READY: false
OWNER_DECISION_REQUIRED: YES

## Preflight Status

This report is a CODEX_DRAFT planning artifact. It is not proof that the 30K school exists, ran, or improved Builder behavior.

Repo context seen:

```text
repo_root: C:/Users/Azerbaijan/Downloads/e-factory-agent-builder
branch: thin-control
head: 0391667e5c056eda67f2f24a350a57eabb7350a8
origin: https://github.com/ries11217596955-hash/e-factory-agent-builder.git
remote_identity_contains: e-factory-agent-builder
```

Required markers found:

```text
CAPABILITY_ROADMAP.json
GENESIS_STATE.json
TASK_QUEUE.json
packs/registry.json
orchestrator/run.ps1
AGENTS.md
```

Dirty state observed before writing this report:

```text
M AGENTS.md
?? .autonomy_test/
?? CODEX_CANARY_RESULT.md
?? CODEX_CANARY_TASK.md
?? CODEX_CLI_CANARY_RESULT.md
?? CODEX_RUNNER_V0_1_TARGET_CANARY_RESULT.md
?? operations/codex_handoff/
```

Dirty files were treated as non-blocking because this plan task is restricted to one new allowed output file and no unrelated dirty file is read as proof or modified.

No files changed before PREFLIGHT_PASS.

No execution of 30K was performed in this planning phase.

## Files Inspected

Required task and guidance:

```text
AGENTS.md
operations/codex_handoff/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_PLAN_V1.md
operations/codex_handoff/audit_useful_school_30k_with_comprehension_and_delta_plan_v1.ps1
```

Repo identity and context:

```text
README.md
AGENT_MISSION.md
CAPABILITY_ROADMAP.json
GENESIS_STATE.json
TASK_QUEUE.json
orchestrator/run.ps1
```

Required reuse assets:

```text
modules/invoke_useful_knowledge_ladder_candidate_generator_v1.ps1
tests/accepted_atom_retention/USEFUL_KNOWLEDGE_LADDER_5000_PROOF_V1.json
modules/invoke_useful_curriculum_school_supervisor_v1.ps1
tests/accepted_atom_retention/USEFUL_CURRICULUM_SCHOOL_SUPERVISOR_V1_PROOF.json
validators/validate_useful_curriculum_school_supervisor_v1_proof.ps1
```

Large proof files were inspected through structured summaries after raw output proved too large for a bounded planning read.

## Task Understanding

The future target is `USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_V1`.

The planned system must demonstrate measurable improvement:

```text
lesson/source candidates
-> intake gate
-> accepted atoms
-> comprehension exam
-> understood atoms
-> digest
-> compact competence delta
-> validation exam
-> promoted active competence state
-> next chunk processed using the promoted state
```

The planning output must make it impossible to claim success from `accepted_total = 30000` alone. A PASS must require comprehension, application, digest, promotion, before/after improvement, and zero critical regression.

## Out Of Scope For This Planning Task

```text
30K execution
candidate pack creation
source module edits
validator edits
registry edits
AGENTS.md edits
canary/autonomy file edits
runtime stub edits
legacy cleanup
commits
pushes
runtime_ready promotion
```

## A. Goal And Non-Goals

Learning means all of the following are true:

1. Useful candidates are admitted through a gate that rejects duplicate, weak, unsafe, conflicting, and non-actionable material.
2. Accepted atoms are tested for operational comprehension, not merely stored.
3. Understood atoms are applied to concrete Builder decisions and anti-applied where they must not govern.
4. Understood atoms are compacted into small competence deltas with evidence boundaries and rollback rules.
5. Deltas are promoted only after validation shows before/after or chunk-local improvement and zero critical regression.
6. Later chunks are processed with the active competence state produced by previously promoted deltas.
7. The final proof shows stronger decisions after school than before school.

Non-learning includes:

```text
raw accepted atom count
counter-only generated records
mechanical templates with no decision change
Codex output treated as proof
stored lessons with no exam
exam answers with no digest
digest records with no promotion gate
promotion without regression checks
after-score claims without frozen before exam
runtime_ready promotion
```

## B. Existing Assets And Reuse Map

`modules/invoke_useful_knowledge_ladder_candidate_generator_v1.ps1`

- Reuse the 10-domain ladder vocabulary as one source of teacher material.
- Reuse candidate fields: `atom_id`, `domain`, `ladder_level`, `concept`, `trigger`, `rule`, `anti_pattern`, `decision_use`, `validator_hint`, `reuse_tags`, `quality_class`.
- Reuse reject classes: useful, duplicate, low_quality, conflict_or_unsafe.
- Do not reuse it as the whole school, because the future system needs comprehension, digest, promotion, and delta proof.

`tests/accepted_atom_retention/USEFUL_KNOWLEDGE_LADDER_5000_PROOF_V1.json`

- Proven summary observed: schema `useful_knowledge_ladder_5000_proof_v1`, status PASS, 5000 accepted, 500 rejected, retrieval PASS, decision reuse sample PASS, cleanup survival PASS, `runtime_ready=false`.
- Reuse as baseline evidence that the useful ladder atom shape can produce accepted and rejected material.
- Do not treat the 5K proof as a 30K comprehension or improvement proof.

`modules/invoke_useful_curriculum_school_supervisor_v1.ps1`

- Reuse chunk/cycle/subchunk/checkpoint concepts.
- Reuse baseline-file hash preservation pattern.
- Reuse stop-on-fail, resume token, retrieval, and decision reuse reporting shape.
- Extend with before exam, comprehension exam, digest, compact delta, promotion, and after exam.

`tests/accepted_atom_retention/USEFUL_CURRICULUM_SCHOOL_SUPERVISOR_V1_PROOF.json`

- Proven summary observed: schema `useful_curriculum_school_supervisor_v1_proof`, status PASS, 3 cycles, 30 subchunks, 3000 accepted, 600 rejected, checkpoint PASS, resume PASS, stop-on-fail PASS, retrieval PASS, decision reuse PASS, active stubs unchanged, `runtime_ready=false`, legacy runner unused.
- Reuse as the supervisor baseline for chunking discipline.
- Do not treat it as comprehension, delta, or 30K proof.

`validators/validate_useful_curriculum_school_supervisor_v1_proof.ps1`

- Reuse validator style: strict top-level assertions, exact counts, no runtime overclaim, no `PROVEN_LIVE`, no legacy runner, non-empty atom fields, duplicate detection, domain coverage, and scenario decision checks.
- Extend validator requirements to fail raw-count-only success.

Existing handoff audit:

- `operations/codex_handoff/audit_useful_school_30k_with_comprehension_and_delta_plan_v1.ps1` validates this report exists and includes plan-only signals.
- It is a report audit only, not a runtime proof.

Legacy path rule:

```text
Do not revive old legacy 5K, 30K, or 300K runners as the core path.
Only reuse proven concepts through new, bounded modules and validators.
```

## C. Source/Teacher Candidate Pack Design

Codex and source material may act as teacher material, not as Builder brain and not as proof. A source pack is an input batch that the Builder must reject, accept, understand, digest, or quarantine.

Candidate pack requirements:

```text
pack_id
pack_schema
source_kind
source_policy
source_material_refs
source_material_hashes
teacher_prompt_hash
generated_utc
intended_chunk_id
lesson_count
concept_count
candidate_count
reject_trap_count
conflict_hint_count
runtime_ready=false
```

Each pack must contain:

- lessons: bounded operational teaching units.
- concepts: reusable Builder concepts with domain and trigger.
- atom candidates: possible accepted atoms with rule, anti-pattern, and decision use.
- anti-patterns: examples of what must be rejected or avoided.
- application cases: where the atom should change or guard a decision.
- anti-application cases: where the atom must not be used.
- conflict hints: likely collisions with existing rules, route locks, proof status, source governance, or runtime boundaries.

Candidate pack guardrails:

- Codex text is `teacher_material`, never `proof`.
- Every candidate must declare why it could be useful and why it could be rejected.
- Every pack must include deliberate weak/duplicate/unsafe/conflicting traps to prove the gate is active.
- A validator must fail packs that are counter-only or mechanically templated.
- A validator must fail packs where lesson text, concept text, atom text, and application cases are identical except for serial numbers.

Proposed pack schema:

```json
{
  "schema": "useful_school_teacher_candidate_pack_v1",
  "pack_id": "string",
  "chunk_id": "chunk_01",
  "source_kind": "codex_teacher_material|repo_source_material|owner_supplied_material",
  "source_is_proof": false,
  "source_material_refs": ["string"],
  "source_material_sha256": ["string"],
  "teacher_prompt_sha256": "string",
  "lessons": [
    {
      "lesson_id": "string",
      "domain": "string",
      "objective": "string",
      "operational_lesson": "string",
      "risk_boundary": "string"
    }
  ],
  "concepts": [
    {
      "concept_id": "string",
      "lesson_id": "string",
      "trigger": "string",
      "core_rule": "string",
      "anti_pattern": "string"
    }
  ],
  "atom_candidates": [
    {
      "candidate_id": "string",
      "concept_id": "string",
      "atom_id": "string",
      "quality_class_hint": "useful|duplicate|low_quality|conflict_or_unsafe",
      "trigger": "string",
      "rule": "string",
      "constraints": ["string"],
      "evidence_boundary": "string",
      "anti_pattern": "string",
      "decision_use": "string",
      "application_cases": ["string"],
      "anti_application_cases": ["string"],
      "conflict_hints": ["string"],
      "validator_hint": "string",
      "reuse_tags": ["string"]
    }
  ],
  "runtime_ready": false
}
```

## D. Before Exam Design

The before exam is frozen before any 30K training starts. It measures current weaknesses and creates the baseline for later delta proof.

Required coverage:

```text
proof-level confusion
dirty repo risk
chunk/checkpoint decisions
Codex-as-proof mistakes
school/free-life/300K layer mixing
stop/retry/continue decisions
source governance
runtime_ready overclaim
legacy runner temptation
promotion/quarantine decisions
```

Before exam pack rules:

- The exam manifest is created before training.
- The manifest stores SHA256 of every question, answer rubric, scoring rule, and case fixture.
- The after exam must use the same manifest or an explicitly paired equivalent form whose pairing hash was frozen before training.
- If the manifest changes after chunk 01 starts, final proof is FAIL.

Before exam result schema:

```json
{
  "schema": "useful_school_before_exam_result_v1",
  "exam_manifest_path": "tests/accepted_atom_retention/USEFUL_SCHOOL_30K_BEFORE_EXAM_MANIFEST_V1.json",
  "exam_manifest_sha256": "string",
  "generated_before_training": true,
  "case_count": 0,
  "score_total": 0,
  "score_possible": 0,
  "before_score": 0.0,
  "proof_confusion_before": 0,
  "unsafe_decision_before": 0,
  "critical_regression_count": 0,
  "case_results": [
    {
      "case_id": "string",
      "category": "proof_confusion|dirty_repo|checkpoint|codex_boundary|layer_mixing|stop_retry_continue|source_governance",
      "prompt_sha256": "string",
      "expected_decision_class": "string",
      "actual_decision_class": "string",
      "score": 0,
      "critical_failure": false
    }
  ],
  "runtime_ready": false
}
```

## E. Atom Comprehension Exam Design

Every accepted atom receives a comprehension record. Promotion can only use atoms whose status reaches `UNDERSTOOD_ATOM`.

Required statuses:

```text
CANDIDATE_ATOM
ACCEPTED_ATOM
UNDERSTOOD_ATOM
NOT_UNDERSTOOD_ATOM
ASSIMILATED_ATOM
PROMOTION_REJECTED
```

Comprehension answer requirements:

1. Explain back in Builder operational wording.
2. Apply the atom to a concrete Builder decision.
3. Anti-apply where the atom must not be used.
4. Check conflict against existing rules and active competence state.
5. State the decision delta: naive decision -> governed decision.
6. Produce score and status.

Scoring proposal:

```text
explain_back: 0-2
apply_case: 0-2
anti_apply_case: 0-2
conflict_check: 0-2
decision_delta: 0-2
evidence_boundary: 0-2
maximum_score: 12
UNDERSTOOD_ATOM threshold: score >= 10 and no critical field failure
NOT_UNDERSTOOD_ATOM: score < 10 or critical conflict/evidence failure
ASSIMILATED_ATOM: UNDERSTOOD_ATOM included in a promoted competence delta
PROMOTION_REJECTED: understood but excluded by digest/promotion regression or conflict gate
```

Comprehension schema:

```json
{
  "schema": "useful_school_atom_comprehension_exam_v1",
  "chunk_id": "chunk_01",
  "subchunk_id": "chunk_01_subchunk_001",
  "atom_id": "string",
  "input_status": "ACCEPTED_ATOM",
  "explain_back": "string",
  "application_case": "string",
  "anti_application_case": "string",
  "conflict_check": {
    "status": "PASS|FAIL",
    "checked_against_state_hash": "string",
    "conflicts": []
  },
  "decision_delta": {
    "naive_decision": "string",
    "governed_decision": "string",
    "changed_or_guarded": true
  },
  "scores": {
    "explain_back": 0,
    "apply_case": 0,
    "anti_apply_case": 0,
    "conflict_check": 0,
    "decision_delta": 0,
    "evidence_boundary": 0,
    "total": 0,
    "possible": 12
  },
  "output_status": "UNDERSTOOD_ATOM|NOT_UNDERSTOOD_ATOM",
  "runtime_ready": false
}
```

## F. Digest And Compact Competence Delta Design

The digest converts understood atoms into small active competence deltas. A delta is not a raw archive dump and must not copy all atom text.

Digest rules:

- Group understood atoms by trigger, decision boundary, and conflict surface.
- Extract a small number of operational rules per chunk.
- Store source atom references, counts, and hashes, not raw atom archives.
- Exclude NOT_UNDERSTOOD_ATOM from digest.
- Mark understood but risky atoms as PROMOTION_REJECTED when they cannot safely compact.

Competence delta requirements:

```text
trigger
rule
constraints
evidence boundary
anti-pattern
validator hint
rollback/quarantine boundary
source atom refs or source atom hash
chunk id and active state input hash
```

Delta schema:

```json
{
  "schema": "useful_school_compact_competence_delta_v1",
  "delta_id": "string",
  "chunk_id": "chunk_01",
  "active_state_input_hash": "string",
  "source_understood_atom_count": 0,
  "source_atom_id_sample": ["string"],
  "source_atom_set_sha256": "string",
  "trigger": "string",
  "rule": "string",
  "constraints": ["string"],
  "evidence_boundary": "string",
  "anti_pattern": "string",
  "validator_hint": "string",
  "rollback_boundary": "string",
  "quarantine_boundary": "string",
  "max_size_bytes": 16384,
  "raw_archive_dump": false,
  "runtime_ready": false
}
```

## G. Promotion Gate Design

A compact competence delta becomes active only after validation. Promotion must be reversible and quarantinable.

Promotion requirements:

```text
delta schema valid
source atom set traceable to accepted and understood atoms
before/after or chunk-local exam improvement present
critical_regression_count = 0
unsafe_decision_after <= unsafe_decision_before
proof_confusion_after <= proof_confusion_before
runtime_ready remains false
no PROVEN_LIVE without live proof
no Codex output treated as proof
```

Promotion results:

- `PROMOTED`: delta becomes part of the active competence state for the next chunk.
- `QUARANTINED`: delta is stored as rejected promotion evidence and cannot influence later chunks.
- `ROLLBACK_REQUIRED`: active state must revert to previous hash.
- `PROMOTION_REJECTED`: atom or digest cannot be promoted safely.

Promotion schema:

```json
{
  "schema": "useful_school_promotion_gate_result_v1",
  "chunk_id": "chunk_01",
  "delta_id": "string",
  "active_state_input_hash": "string",
  "active_state_output_hash": "string",
  "promotion_status": "PROMOTED|QUARANTINED|ROLLBACK_REQUIRED",
  "chunk_local_before_score": 0.0,
  "chunk_local_after_score": 0.0,
  "improved_case_count": 0,
  "critical_regression_count": 0,
  "proof_confusion_before": 0,
  "proof_confusion_after": 0,
  "unsafe_decision_before": 0,
  "unsafe_decision_after": 0,
  "rollback_plan": "string",
  "quarantine_path": "string",
  "validator_status": "PASS|FAIL",
  "runtime_ready": false
}
```

## H. 30K Chunked Execution Design

Future execution target:

```text
chunk_count: 6
accepted_per_chunk: 5000
subchunk_size: 100
subchunks_per_chunk: 50
accepted_total: 30000
checkpoint: after every chunk
runtime_ready: false
```

Chunk flow:

1. Load active competence state hash.
2. Load teacher/source candidate packs for the chunk.
3. Intake candidates and reject weak, duplicate, unsafe, conflicting, and non-actionable material.
4. Admit exactly 5000 useful accepted atoms for the chunk.
5. Run comprehension exam for accepted atoms.
6. Mark UNDERSTOOD_ATOM or NOT_UNDERSTOOD_ATOM.
7. Digest understood atoms into compact competence deltas.
8. Run chunk-local validation exam.
9. Promote safe deltas or quarantine failed deltas.
10. Write chunk checkpoint with state input/output hashes.
11. Next chunk uses the promoted active competence state from prior chunks.

Key stronger-state requirement:

- Chunk 01 uses the frozen baseline active state.
- Chunk 02 uses chunk 01 promoted state if chunk 01 promotion passed.
- Chunk 03 uses chunk 02 promoted state if chunk 02 promotion passed.
- If a chunk has no promoted delta, default action is STOP with FAIL for the 30K proof, because the next chunk would not be processed by a stronger state.
- Owner may later authorize a diagnostic continuation, but that continuation cannot be claimed as the 30K improvement proof.

Chunk proof schema:

```json
{
  "schema": "useful_school_30k_chunk_proof_v1",
  "chunk_id": "chunk_01",
  "chunk_index": 1,
  "active_state_input_hash": "string",
  "teacher_pack_manifest_sha256": "string",
  "candidate_total": 0,
  "accepted_total": 5000,
  "rejected_total": 0,
  "duplicate_rejected_count": 0,
  "low_quality_rejected_count": 0,
  "conflict_or_unsafe_rejected_count": 0,
  "non_actionable_rejected_count": 0,
  "subchunk_size": 100,
  "subchunk_count": 50,
  "comprehension_exam_status": "PASS|FAIL",
  "understood_atom_count": 0,
  "not_understood_atom_count": 0,
  "digest_status": "PASS|FAIL",
  "competence_delta_count": 0,
  "promoted_delta_count": 0,
  "quarantined_delta_count": 0,
  "chunk_local_before_score": 0.0,
  "chunk_local_after_score": 0.0,
  "critical_regression_count": 0,
  "active_state_output_hash": "string",
  "checkpoint_status": "PASS|FAIL",
  "runtime_ready": false
}
```

## I. After Exam And Delta Proof Design

The after exam uses the frozen before exam manifest or its pre-hashed paired form. It must show measurable improvement without critical regression.

Required metrics:

```text
before_score
after_score
improved_case_count
critical_regression_count
proof_confusion_before
proof_confusion_after
unsafe_decision_before
unsafe_decision_after
new_atoms_used_in_after_decisions
promoted_delta_count
quarantined_delta_count
runtime_ready=false
```

After exam proof schema:

```json
{
  "schema": "useful_school_after_exam_delta_proof_v1",
  "before_exam_manifest_sha256": "string",
  "after_exam_manifest_sha256": "string",
  "same_or_paired_exam_manifest": true,
  "before_score": 0.0,
  "after_score": 0.0,
  "improved_case_count": 0,
  "critical_regression_count": 0,
  "proof_confusion_before": 0,
  "proof_confusion_after": 0,
  "unsafe_decision_before": 0,
  "unsafe_decision_after": 0,
  "new_atoms_used_in_after_decisions": [
    {
      "case_id": "string",
      "atom_ids": ["string"],
      "delta_ids": ["string"],
      "decision_change": "string"
    }
  ],
  "promoted_delta_count": 0,
  "quarantined_delta_count": 0,
  "runtime_ready": false
}
```

Final 30K proof schema:

```json
{
  "schema": "useful_school_30k_with_comprehension_and_delta_v1_proof",
  "status": "PASS|FAIL|BLOCKED",
  "final_status": "USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_V1_PROVEN|FAILED|BLOCKED",
  "repo_root": "string",
  "branch": "thin-control",
  "head": "string",
  "before_exam_manifest_sha256": "string",
  "chunk_count": 6,
  "accepted_total": 30000,
  "candidate_total": 0,
  "rejected_total": 0,
  "understood_atom_total": 0,
  "not_understood_atom_total": 0,
  "assimilated_atom_total": 0,
  "competence_delta_total": 0,
  "promoted_delta_count": 0,
  "quarantined_delta_count": 0,
  "before_score": 0.0,
  "after_score": 0.0,
  "improved_case_count": 0,
  "critical_regression_count": 0,
  "proof_confusion_before": 0,
  "proof_confusion_after": 0,
  "unsafe_decision_before": 0,
  "unsafe_decision_after": 0,
  "new_atoms_used_in_after_decisions": [],
  "chunks": [],
  "active_state_initial_hash": "string",
  "active_state_final_hash": "string",
  "codex_output_treated_as_proof": false,
  "counter_only_or_mechanical_templates_detected": false,
  "proven_live_claim_present": false,
  "runtime_ready": false
}
```

## J. Reports And Validators

Machine-readable reports required in the later implementation phase:

```text
tests/accepted_atom_retention/USEFUL_SCHOOL_30K_BEFORE_EXAM_MANIFEST_V1.json
tests/accepted_atom_retention/USEFUL_SCHOOL_30K_BEFORE_EXAM_RESULT_V1.json
tests/accepted_atom_retention/USEFUL_SCHOOL_30K_CHUNK_01_PROOF_V1.json
tests/accepted_atom_retention/USEFUL_SCHOOL_30K_CHUNK_02_PROOF_V1.json
tests/accepted_atom_retention/USEFUL_SCHOOL_30K_CHUNK_03_PROOF_V1.json
tests/accepted_atom_retention/USEFUL_SCHOOL_30K_CHUNK_04_PROOF_V1.json
tests/accepted_atom_retention/USEFUL_SCHOOL_30K_CHUNK_05_PROOF_V1.json
tests/accepted_atom_retention/USEFUL_SCHOOL_30K_CHUNK_06_PROOF_V1.json
tests/accepted_atom_retention/USEFUL_SCHOOL_30K_AFTER_EXAM_DELTA_PROOF_V1.json
tests/accepted_atom_retention/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_V1_PROOF.json
```

Validators required in the later implementation phase:

```text
validators/validate_useful_school_teacher_candidate_pack_v1.ps1
validators/validate_useful_school_before_exam_v1.ps1
validators/validate_useful_school_atom_comprehension_v1.ps1
validators/validate_useful_school_compact_delta_v1.ps1
validators/validate_useful_school_promotion_gate_v1.ps1
validators/validate_useful_school_chunk_proof_v1.ps1
validators/validate_useful_school_final_delta_proof_v1.ps1
```

Validators must fail if:

- `accepted_total` is present but comprehension and delta metrics are missing.
- `PROVEN_LIVE` appears without live proof.
- `runtime_ready=true`.
- Codex output is treated as proof.
- 30K is produced by counter-only or mechanical templates.
- No before/after delta is measured.
- `critical_regression_count` is greater than zero.
- before exam manifest hash is missing or changed after training starts.
- any chunk after the first lacks the expected active state input hash from previous promotion.
- a chunk proceeds after failed promotion without explicitly marking final proof FAIL or diagnostic-only.
- promoted delta count is zero.
- after score is not greater than before score.
- unsafe decisions or proof confusion increase.

## Proposed Files For Later Implementation

Create later:

```text
modules/new_useful_school_teacher_candidate_pack_v1.ps1
modules/invoke_useful_school_candidate_intake_gate_v1.ps1
modules/invoke_useful_school_before_exam_v1.ps1
modules/invoke_useful_school_atom_comprehension_exam_v1.ps1
modules/invoke_useful_school_digest_competence_delta_v1.ps1
modules/invoke_useful_school_promotion_gate_v1.ps1
modules/invoke_useful_school_30k_supervisor_v1.ps1
validators/validate_useful_school_teacher_candidate_pack_v1.ps1
validators/validate_useful_school_before_exam_v1.ps1
validators/validate_useful_school_atom_comprehension_v1.ps1
validators/validate_useful_school_compact_delta_v1.ps1
validators/validate_useful_school_promotion_gate_v1.ps1
validators/validate_useful_school_chunk_proof_v1.ps1
validators/validate_useful_school_final_delta_proof_v1.ps1
tests/accepted_atom_retention/USEFUL_SCHOOL_30K_BEFORE_EXAM_MANIFEST_V1.json
tests/accepted_atom_retention/USEFUL_SCHOOL_30K_BEFORE_EXAM_RESULT_V1.json
tests/accepted_atom_retention/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_V1_PROOF.json
```

Change later only if explicitly scoped:

```text
packs/registry.json
TASK_QUEUE.json
CAPABILITY_ROADMAP.json
GENESIS_STATE.json
```

Do not change later without explicit Owner scope:

```text
AGENTS.md
.runtime/**
proofs/**
raw_shards/**
accepted-core/**
settings/**
route locks
legacy runners
canary/autonomy files
```

## Phase-By-Phase Implementation Plan

Phase 0 - preflight and route lock:

- Verify repo root, branch, remote, and required markers.
- Verify baseline HEAD expected by the implementation task.
- Verify no protected dirty file is in the implementation write set.
- Verify the implementation task explicitly allows each file to be changed.

Validation command:

```powershell
git rev-parse --show-toplevel
git branch --show-current
git rev-parse HEAD
git remote get-url origin
git status --short
```

Phase 1 - teacher/source pack contract:

- Define teacher candidate pack schema.
- Include lessons, concepts, atom candidates, anti-patterns, application cases, anti-application cases, and conflict hints.
- Add validator to reject source-as-proof, missing hashes, counter-only templates, and weak candidate fields.

Validation command:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\validators\validate_useful_school_teacher_candidate_pack_v1.ps1 -PackPath .\tests\accepted_atom_retention\USEFUL_SCHOOL_30K_TEACHER_PACK_SAMPLE_V1.json
```

Phase 2 - frozen before exam:

- Create before exam manifest and result runner.
- Freeze manifest hash before any chunk processing.
- Cover proof confusion, dirty repo risk, checkpoint decisions, Codex-as-proof mistakes, layer mixing, stop/retry/continue, and source governance.

Validation command:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\validators\validate_useful_school_before_exam_v1.ps1 -ManifestPath .\tests\accepted_atom_retention\USEFUL_SCHOOL_30K_BEFORE_EXAM_MANIFEST_V1.json -ResultPath .\tests\accepted_atom_retention\USEFUL_SCHOOL_30K_BEFORE_EXAM_RESULT_V1.json
```

Phase 3 - candidate intake gate:

- Extend useful ladder and curriculum patterns into a 30K candidate intake gate.
- Reject duplicate, low-quality, unsafe/conflicting, and non-actionable candidates.
- Preserve accepted atom field quality and domain coverage.

Validation command:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\validators\validate_useful_school_chunk_proof_v1.ps1 -ProofPath .\tests\accepted_atom_retention\USEFUL_SCHOOL_30K_CHUNK_01_PROOF_V1.json -Stage intake
```

Phase 4 - comprehension exam:

- Run comprehension exams for accepted atoms.
- Produce UNDERSTOOD_ATOM and NOT_UNDERSTOOD_ATOM records.
- Fail if comprehension metrics are missing or if accepted count is used as the success proxy.

Validation command:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\validators\validate_useful_school_atom_comprehension_v1.ps1 -ChunkProofPath .\tests\accepted_atom_retention\USEFUL_SCHOOL_30K_CHUNK_01_PROOF_V1.json
```

Phase 5 - digest and competence delta:

- Digest understood atoms into compact competence deltas.
- Enforce size and raw-dump boundaries.
- Include trigger, rule, constraints, evidence boundary, anti-pattern, validator hint, and rollback/quarantine boundary.

Validation command:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\validators\validate_useful_school_compact_delta_v1.ps1 -ChunkProofPath .\tests\accepted_atom_retention\USEFUL_SCHOOL_30K_CHUNK_01_PROOF_V1.json
```

Phase 6 - promotion gate:

- Run chunk-local validation exam.
- Promote deltas only with improvement and zero critical regression.
- Quarantine unsafe deltas and preserve rollback path.

Validation command:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\validators\validate_useful_school_promotion_gate_v1.ps1 -ChunkProofPath .\tests\accepted_atom_retention\USEFUL_SCHOOL_30K_CHUNK_01_PROOF_V1.json
```

Phase 7 - six chunk 30K supervised school:

- Execute 6 chunks of 5000 accepted atoms.
- Use subchunks of 100 inside each chunk.
- Write checkpoint after every chunk.
- Feed promoted active state from prior chunk into the next chunk.
- Stop if a chunk cannot promote a delta.

Owner-terminal command only, not for Codex attached waiting:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\modules\invoke_useful_school_30k_supervisor_v1.ps1 -ChunkCount 6 -AcceptedPerChunk 5000 -SubchunkSize 100 -ProofPath .\tests\accepted_atom_retention\USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_V1_PROOF.json
```

Phase 8 - after exam and final delta proof:

- Run after exam using frozen manifest.
- Compute before/after score and regression metrics.
- Prove after decisions cite promoted deltas or new understood atoms.
- Final validator fails raw-count-only success.

Validation command:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\validators\validate_useful_school_final_delta_proof_v1.ps1 -ProofPath .\tests\accepted_atom_retention\USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_V1_PROOF.json
```

## Stop Conditions

Stop before mutation if:

```text
repo root mismatch
branch mismatch
HEAD mismatch for scoped implementation task
origin URL does not contain e-factory-agent-builder
required markers missing
task scope permits protected file edits without explicit authorization
target file list is unclear
baseline proof missing or not PASS
```

Stop during future execution if:

```text
teacher pack hash missing
before exam manifest changes
intake gate accepts duplicate or unsafe candidates
accepted_total advances without comprehension metrics
UNDERSTOOD_ATOM count is zero for a chunk
digest emits raw archive dump
promotion has critical regression
promotion count is zero for a chunk
next chunk cannot use the prior promoted state
PROVEN_LIVE appears without live proof
runtime_ready becomes true
Codex output is marked as proof
validator needs a retry loop not explicitly authorized
```

Stop after failed proof:

```text
report exact failing validator
report files changed
do not patch and rerun unless ALLOW_CODEX_VALIDATION_LOOP=true
return Owner command or detached runtime details
```

## PASS, BLOCKED, FAIL Criteria

PREFLIGHT_PASS for this planning task:

```text
repo root correct
branch thin-control
HEAD 0391667e5c056eda67f2f24a350a57eabb7350a8
origin contains e-factory-agent-builder
required markers present
allowed output path only
baseline assets inspected
no files changed before PREFLIGHT_PASS
30K not executed
```

BLOCKED_PREFLIGHT for this planning task:

```text
repo/branch/head/remote mismatch
required markers missing
allowed output conflict that cannot be safely resolved
baseline proof missing
baseline proof not PASS
task requires protected mutation outside allowed output
validation impossible within plan-only scope
```

FAIL for later implementation proof:

```text
accepted_total = 30000 but comprehension or delta fields missing
before_score or after_score missing
after_score <= before_score
improved_case_count = 0
critical_regression_count > 0
proof_confusion_after > proof_confusion_before
unsafe_decision_after > unsafe_decision_before
promoted_delta_count = 0
new_atoms_used_in_after_decisions missing or empty
runtime_ready=true
Codex output treated as proof
counter-only or mechanical template detected
PROVEN_LIVE appears without live proof
legacy runner used as core path
```

PASS for later implementation proof:

```text
all six chunks validate
accepted_total = 30000
rejected_total > 0 with duplicate, low-quality, unsafe/conflicting, and non-actionable rejection evidence
comprehension exams present
understood_atom_total > 0
assimilated_atom_total > 0
digest emits compact deltas, not raw dumps
promoted_delta_count > 0
quarantined_delta_count recorded, even if zero
before exam manifest hash unchanged
after_score > before_score
improved_case_count > 0
critical_regression_count = 0
proof_confusion_after <= proof_confusion_before
unsafe_decision_after <= unsafe_decision_before
after decisions cite new atoms or promoted deltas
next chunk state input hash equals prior promoted state output hash
runtime_ready=false
```

## Risks

- A generated pack could look diverse while still being mechanically templated; validator needs semantic duplication and serial-number pattern checks.
- Full comprehension for 30000 atoms is large; implementation may need bounded per-subchunk storage and compact summaries while preserving auditability.
- Digest compression could overfit to exam cases; final validator should require unseen or held-out application cases.
- Promotion may accidentally become a route/state mutation; implementation must keep active competence state scoped to school proof unless Owner explicitly promotes repo state.
- Continuing after failed promotion would weaken the stronger-next-chunk guarantee; default should be stop and FAIL.
- Large JSON proofs can become unwieldy; validators should read structured summaries and samples without hiding required metrics.

## Limitations

This report does not implement modules, validators, candidate packs, runtime stubs, or proof files.

This report does not prove that Builder improved.

This report does not authorize a 30K run.

`runtime_ready` remains false.

## Current Planning Validation

Planned local validation for this report:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\operations\codex_handoff\audit_useful_school_30k_with_comprehension_and_delta_plan_v1.ps1
```

Expected result:

```text
VALIDATION_PASS=USEFUL_SCHOOL_30K_PLAN_REPORT_V1_AUDITED
RUNTIME_READY=false
```

