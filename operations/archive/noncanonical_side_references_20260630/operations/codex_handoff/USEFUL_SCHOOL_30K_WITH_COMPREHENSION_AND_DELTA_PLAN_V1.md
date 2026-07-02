# USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_PLAN_V1

STATUS: CODEX_PLAN_EXPANSION_TASK
MODE: PLAN_ONLY_FIRST
AUTHOR: ChatGPT via Bridge
RUNTIME_READY: false

## 0. Purpose

Design the next Builder school system so that learning means measurable improvement, not just storing 30,000 records.

Target architecture:

lesson/source candidates -> intake gate -> accepted atoms -> comprehension exam -> understood atoms -> digest -> compact competence delta -> validation exam -> promoted active competence state -> next chunk processed stronger than the previous chunk.

This task is NOT permission to run a 30K school execution yet.
This task is NOT permission to modify existing runtime stubs, old legacy runners, registry, or AGENTS.md.
This task is the planning phase only.

## 1. Current proven baseline

Repo path:
C:/Users/Azerbaijan/Downloads/e-factory-agent-builder

Branch:
thin-control

Required current HEAD before planning:
0391667e5c056eda67f2f24a350a57eabb7350a8

Proven remote-synced work available:
- USEFUL_KNOWLEDGE_LADDER_5000_PROOF_V1: useful ladder, 5000 accepted, 500 rejected, retrieval PASS, decision reuse PASS, runtime_ready=false.
- USEFUL_CURRICULUM_SCHOOL_SUPERVISOR_V1: 3 cycles, 30 subchunks, 3000 accepted, 600 rejected, checkpoint PASS, resume PASS, stop-on-fail PASS, retrieval PASS, decision reuse PASS, runtime_ready=false.

Known local unrelated dirty files may exist and must not be touched by this planning task:
- AGENTS.md
- CODEX_CANARY_TASK.md
- CODEX_CANARY_RESULT.md
- .autonomy_test/CHATGPT_AUTONOMY_TEST.md

## 2. Master goal

Create an implementation plan for:

USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_V1

The system must prove that after school the Builder is at least a little stronger, not merely larger.

The future execution target is:
- 30,000 useful accepted atoms.
- Codex/source-generated candidate packs are allowed as teacher/source material, but Codex is not the brain and not proof.
- Builder school gate must reject weak, duplicate, unsafe, conflicting, or non-actionable candidates.
- Every chunk must include comprehension exam and digest/promotion logic.
- Improvement must be measured by before/after exams and delta proof.
- runtime_ready must remain false.

## 3. Required plan headers to expand

Codex must expand each header below into concrete implementation details.

### A. Goal and non-goals
Explain exactly what counts as learning and what does not.
Learning is not accepted_atoms_count alone.
Learning requires comprehension, application, digest, active competence delta, and before/after improvement without critical regression.

### B. Existing assets and reuse map
Identify which existing files/modules/proofs should be reused.
At minimum inspect:
- modules/invoke_useful_knowledge_ladder_candidate_generator_v1.ps1
- tests/accepted_atom_retention/USEFUL_KNOWLEDGE_LADDER_5000_PROOF_V1.json
- modules/invoke_useful_curriculum_school_supervisor_v1.ps1
- tests/accepted_atom_retention/USEFUL_CURRICULUM_SCHOOL_SUPERVISOR_V1_PROOF.json
- validators/validate_useful_curriculum_school_supervisor_v1_proof.ps1
Do not revive old legacy 5K/30K/300K runners as the core path.

### C. Source/teacher candidate pack design
Design how Codex/source material should generate useful candidate packs without becoming Builder brain.
Candidate packs must include lessons, concepts, atom candidates, anti-patterns, application cases, anti-application cases, and conflict hints.

### D. Before exam design
Design a frozen before-exam pack that measures current weaknesses before training.
It must cover proof-level confusion, dirty repo risk, chunk/checkpoint decisions, Codex-as-proof mistakes, school/free-life/300K layer mixing, stop/retry/continue decisions, and source governance.
The exam must have a hash or manifest so it cannot silently change after training.

### E. Atom comprehension exam design
For accepted atoms or controlled samples, the Builder must answer:
- explain back in its own operational wording;
- apply to a concrete decision;
- anti-apply where the atom must not be used;
- conflict check with existing rules;
- decision delta: what naive decision changes into governed decision;
- score and status.
Statuses must include at least:
CANDIDATE_ATOM, ACCEPTED_ATOM, UNDERSTOOD_ATOM, NOT_UNDERSTOOD_ATOM, ASSIMILATED_ATOM, PROMOTION_REJECTED.

### F. Digest and compact competence delta design
Design how understood atoms are compressed into small active competence deltas.
A delta must not be a raw archive dump.
A delta must include trigger, rule, constraints, evidence boundary, anti-pattern, validator hint, and rollback/quarantine boundary.

### G. Promotion gate design
Design how a compact competence delta becomes active only after validation.
Promotion must require before/after or chunk-local exam improvement and zero critical regression.
Promotion must be reversible/quarantinable.

### H. 30K chunked execution design
Future execution should use 6 chunks x 5000 accepted atoms, subchunks of 100, with checkpoint after every chunk.
Each chunk after the first must be processed using the current promoted competence state from previous chunks.
This is the key requirement: next chunk must be handled by a stronger state, if prior delta passed promotion.

### I. After exam and delta proof design
Design after-exam and delta proof.
Metrics must include:
- before_score;
- after_score;
- improved_case_count;
- critical_regression_count;
- proof_confusion_before/after;
- unsafe_decision_before/after;
- new_atoms_used_in_after_decisions;
- promoted_delta_count;
- quarantined_delta_count;
- runtime_ready=false.

### J. Reports and validators
Design machine-readable reports and validators.
The final proof must make it impossible to claim success from raw count alone.
Validators must fail if:
- accepted_total is present but comprehension/delta metrics are missing;
- PROVEN_LIVE appears without live proof;
- runtime_ready=true;
- Codex output is treated as proof;
- 30K is produced by counter-only/mechanical templates;
- no before/after delta is measured;
- critical regressions exist.

## 4. Expected output of this planning task

Codex must create exactly one plan report file:

operations/codex_handoff/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_PLAN_V1_REPORT.md

The report must include:
- PREFLIGHT status;
- repo root/branch/head seen;
- files inspected;
- proposed files to create/change in the later implementation phase;
- phase-by-phase implementation plan;
- validation commands per phase;
- proof JSON schemas per phase;
- stop conditions;
- out-of-scope list;
- risk list;
- exact criteria for PASS/BLOCKED/FAIL;
- statement: no files changed before PREFLIGHT_PASS;
- statement: no execution of 30K performed in this planning phase.

## 5. Hard limits

During this PLAN_ONLY task Codex must NOT:
- run 30K;
- create candidate packs;
- modify existing source modules;
- modify validators outside the report;
- modify AGENTS.md;
- modify canary/autonomy files;
- commit;
- push;
- delete/move/cleanup legacy files;
- claim runtime_ready=true.

Allowed file to create in this planning task:
- operations/codex_handoff/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_PLAN_V1_REPORT.md

If any conflict, missing baseline proof, unsafe scope, or unclear repo state exists, return BLOCKED_PREFLIGHT and do not write the report unless the report is only a blocker report.

## 6. Required final status format in report

Codex must include:

STATUS: PREFLIGHT_PASS | BLOCKED_PREFLIGHT
TASK_MODE: PLAN_ONLY
FILES_CHANGED_BEFORE_PREFLIGHT_PASS: YES/NO
FILES_CREATED_OR_CHANGED:
PLAN_REPORT_PATH:
30K_EXECUTED: NO
RUNTIME_READY: false
OWNER_DECISION_REQUIRED:
