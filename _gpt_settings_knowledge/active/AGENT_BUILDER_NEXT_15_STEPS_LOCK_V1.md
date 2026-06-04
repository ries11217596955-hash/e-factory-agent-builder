# AGENT_BUILDER_NEXT_15_STEPS_LOCK_V1

## 2026-06-03 Status Override

**Status:** SUPERSEDED_ROUTE_REFERENCE / DO_NOT_USE_AS_CURRENT_PHASE_ROUTE

This file is kept for historical route memory only.

It describes an older PHASE78→PHASE90 route. Fresh project evidence has advanced far beyond that path:
- PHASE159 newborn reflex core accepted;
- PHASE160 live daemon bootstrap accepted;
- PHASE160 post-commit runnability repair accepted;
- PHASE160 live observer console repair accepted at `6903d7b`;
- PHASE160 live self-growth duty loop expansion validated but not accepted yet.

Do not continue from the old STEP list in this file.

Current operating direction:
```text
close PHASE160 live self-growth duty loop acceptance
→ run owner-supervised live self-growth session
→ create next route lock version from fresh proof
```

Required next route artifact:
```text
AGENT_BUILDER_NEXT_15_STEPS_LOCK_V2
```

Until V2 exists, recover current route from:
- latest terminal/GitHub evidence;
- accepted proof/report files;
- current repo HEAD;
- `EF_ACTIVE_DIRECTIONS.md`;
- `EF_EXECUTION_SYSTEM.md`;
- `EF_LIVE_SELF_DEVELOPMENT_LOOP_V1.md`.

---

## Archived Original Content Below


## Document Status

**File type:** GPT Knowledge / Project Route Lock  
**Status:** ACTIVE_ROUTE_LOCK  
**Owner:** E-Factory Owner  
**Assistant role:** E-Factory Control GPT  
**Active line:** AGENT_BUILDER / SELF_BUILD  
**Current baseline:** PHASE78 is accepted, committed, pushed, and locally clean after diagnostics cleanup.  
**Accepted baseline commit:** `ba7f928 Close PHASE78 self knowledge runtime proof`  
**Route version:** V1  
**Rule:** This document governs the next 15 Agent Builder steps until completed or explicitly replaced by `AGENT_BUILDER_NEXT_15_STEPS_LOCK_V2`.

---

## 0. Why This File Exists

The project had a recurring problem: after every strong idea, the direction could shift. That created risk of drift, repeated replanning, and micro-patching.

This file prevents drift.

It defines the next 15 steps as a locked execution route.

A new idea does **not** silently change the route.  
A new idea must be placed into the current step, a later locked step, or a formal `ROUTE_CHANGE_REQUEST`.

---

## 1. Current Proven State

PHASE78 is completed and accepted.

PHASE78 means:

Builder can describe itself from repo artifacts.

Accepted evidence from the PHASE78 close:

- `reports/self_knowledge/BUILDER_SELF_DESCRIBE_REPORT.json`
- `reports/self_knowledge/BUILDER_SELF_DESCRIBE_SUMMARY.md`
- `proofs/self_knowledge/AGENT_BUILDER_SELF_KNOWLEDGE_SYSTEM_FULL_CONTRACT_V1.json`
- `reports/phase78/PHASE78_RUNTIME_REPAIR_TASK_REPORT.md`
- `TASK_QUEUE.json` has `active_task_id = NONE`
- PHASE78 task is `COMPLETED`
- `GENESIS_STATE.json` includes `agent_builder_self_knowledge_system_full_contract_v1`
- `CAPABILITY_ROADMAP.json` marks PHASE78 as completed
- commit and push completed: `ba7f928`

Meaning:

Builder has a mirror.  
Builder can say who it is, what repo it is, what exists, what is missing, what is proven, what is candidate, and what should be built next.

But Builder does **not yet** have the full mechanism to acquire materials, classify them, wrap them as operations, generate self-build programs, admit programs, and execute its own generated programs under the new architecture.

This route builds that mechanism.

---

## 2. Main Doctrine For This Route

**Full contract first. Phased execution second.**

This route is not MVP.  
This route is not a minimal starter.  
This route creates a full architectural skeleton first, then fills it step by step.

Allowed:

- bounded phased execution;
- manual first scout pass;
- Codex preparing Builder self-build packs;
- terminal proof packs;
- Builder runtime execution;
- owner approval gates;
- reference-only external research.

Forbidden:

- jumping directly to external agent production;
- installing random tools without catalog, quarantine, policy, and proof;
- letting Codex directly build external agents instead of Builder;
- claiming capability from chat memory;
- marking materials as trusted without admission;
- marking PASS without runtime proof;
- using large frameworks as the core before governance exists;
- changing the route without route-change protocol.

---

## 3. Strict Role Split

### Owner

The Owner:

- defines mission;
- approves route changes;
- reviews proof/report;
- approves risky material admission;
- decides whether to continue, stop, or change direction.

### E-Factory Control GPT

The GPT:

- keeps the route;
- explains before serious stages;
- writes Codex tasks;
- writes terminal proof packs;
- performs Manual Scout Pass 001;
- stops drift;
- converts failures into Control Book candidates.

### Codex

Codex may:

- repair Builder;
- extend Builder;
- prepare self-build packs;
- implement bounded scoped changes after root cause is known.

Codex must not:

- replace Builder in external-agent production;
- mark runtime proof as done without terminal/validator evidence;
- perform broad rewrites without scoped proof.

### Builder

Builder must:

- execute self-build through runtime;
- update state and queue honestly;
- write proof/report;
- return queue to clean state;
- eventually generate and execute its own self-build programs.

### Terminal

Terminal proves local truth:

- git status;
- runtime output;
- validator output;
- proof/report existence;
- commit/push.

### GitHub / GitHub Actions

GitHub is remote truth:

- pushed commits;
- workflow runs;
- artifacts;
- PRs;
- remote file state.

---

## 4. Route Change Rule

A new idea does not silently change the route.

Use this exact format:

```text
ROUTE_CHANGE_REQUEST

PROPOSED_CHANGE:
WHY_CURRENT_ROUTE_IS_INSUFFICIENT:
AFFECTED_STEP:
RISK:
WHAT_IS_DELAYED:
NEW_PROOF_REQUIRED:
OWNER_APPROVAL:
```

Without accepted `ROUTE_CHANGE_REQUEST`, continue the locked route.

---

## 5. New Chat Migration Rule

When moving to a new chat, the Owner may paste the full prior chat and say:

```text
Сделай глубокий анализ этого чата, пойми наши проблемы, пойми, чего мы достигли, чего мы доказали, и продолжим дальше.
```

The GPT must not continue execution immediately.

First response must produce a `DEEP_RECOVERY_REPORT`.

### Required `DEEP_RECOVERY_REPORT`

The report must include:

1. Active line.
2. What the pasted artifact is.
3. Timeline of major events.
4. Proven achievements.
5. Claims not yet proven.
6. Current route-lock file and active step.
7. Current repo baseline if evidenced.
8. Last accepted proof/commit if evidenced.
9. Dirty or unknown state.
10. Current risks.
11. Next strongest move.
12. Cut list.
13. What must be verified by terminal/GitHub/repo artifact before execution.

### Migration rule

A pasted chat transcript is a recovery artifact.  
It is not current repo truth.

After migration, no execution pack is allowed until the GPT separates:

- proof;
- claim;
- unknown;
- next safe action.

---

## 6. Repo Style Must Be Preserved

Use current Builder repo style:

```text
packs/
tasks/
modules/
contracts/
reports/
proofs/
self_knowledge/
generated_agents/
applied_agents/
orchestrator/
self_build_programs/
```

New systems must fit this style:

```text
contracts/materials/
materials/
modules/materials/
reports/materials/
proofs/materials/
contracts/operations/
operations/
modules/operations/
reports/operations/
proofs/operations/
contracts/self_development/
modules/self_development/
reports/self_development/
proofs/self_development/
```

Do not create parallel architecture roots unless approved by route change.

---

## 7. Completion Standard For Every Step

Every step must end with:

- created or changed files;
- validation command;
- proof/report;
- queue clean if runtime was involved;
- clear next step;
- commit/push when accepted.

No status language without evidence.

Forbidden phrases without proof:

- done;
- fixed;
- works;
- ready;
- completed;
- clean;
- synced;
- accepted.

Accepted proof types:

- terminal output;
- validator PASS;
- proof/report file;
- git diff;
- commit hash;
- pushed remote state;
- workflow run/artifact;
- current repo file.

---

# LOCKED NEXT 15 STEPS

---

## STEP 1 — PHASE78 Acceptance Baseline

**Status:** COMPLETED.

### Purpose

Lock the current proven baseline.

### Meaning

Builder can describe itself from repo evidence.

### Required evidence

Already accepted:

- self-knowledge report exists;
- self-knowledge summary exists;
- self-knowledge proof exists;
- PHASE78 repair report exists;
- validator PASS;
- queue clean;
- commit/push complete.

### Accepted commit

```text
ba7f928 Close PHASE78 self knowledge runtime proof
```

### Do not do

- do not redo PHASE78 unless regression appears;
- do not re-open PHASE78 for unrelated improvements.

### Next allowed step

STEP 2.

---

## STEP 2 — Route Lock V1 Stored

### Purpose

Store this route so the project stops drifting.

### Meaning

The route becomes a GPT Knowledge / repo planning artifact.

### Who does it

Owner uploads this file to GPT Knowledge.  
Codex or terminal may also add it to repo if the Owner wants repo copy.

### Primary output

```text
AGENT_BUILDER_NEXT_15_STEPS_LOCK_V1.md
```

### Recommended repo output

```text
reports/planning/AGENT_BUILDER_NEXT_15_STEPS_LOCK_V1.md
```

### Acceptance proof

- file is uploaded to GPT Knowledge or added to repo;
- the GPT acknowledges this as active route lock;
- if added to repo: commit/push exists.

### Do not do

- do not begin PHASE79 before this route is stored;
- do not start Material Scout;
- do not install tools;
- do not build external agents.

### Next allowed step

STEP 3.

---

## STEP 3 — PHASE79 Material Acquisition Bootstrap Contract V1

### Purpose

Create the formal skeleton for Builder to receive and manage external building materials.

### Meaning

Builder should not only say “I need modules.”  
Builder needs a structure to receive materials, classify them, quarantine them, and create reports/proofs.

This is not full Material Scout yet.  
This is material acquisition bootstrap.

### Who does it

Codex prepares the self-build pack.  
Builder executes it through runtime.  
Terminal proves it.

### Required outputs

```text
contracts/materials/material_request.schema.json
contracts/materials/material_candidate.schema.json
contracts/materials/material_catalog.schema.json
contracts/materials/manual_scout_pass.schema.json

materials/MATERIAL_CATALOG.json
materials/inbox/.gitkeep
materials/catalog/.gitkeep
materials/quarantine/.gitkeep
materials/trusted/.gitkeep
materials/rejected/.gitkeep
materials/reference_only/.gitkeep

modules/materials/import_manual_scout_pass.ps1
modules/materials/write_material_catalog_report.ps1

reports/materials/MATERIAL_ACQUISITION_BOOTSTRAP_REPORT.json
proofs/materials/MATERIAL_ACQUISITION_BOOTSTRAP_V1.json

packs/PHASE79_MATERIAL_ACQUISITION_BOOTSTRAP_V1/
tasks/TASK_MATERIAL_ACQUISITION_BOOTSTRAP_V1_001.json
```

### Required statuses

Material statuses:

```text
DISCOVERED
CANDIDATE
QUARANTINED
WRAPPED
TESTED
TRUSTED
REJECTED
REFERENCE_ONLY
OWNER_APPROVAL_REQUIRED
```

Usage modes:

```text
USE_AS_TOOL
WRAP_ONLY
COPY_WITH_ATTRIBUTION
ADAPT
REIMPLEMENT
REFERENCE_ONLY
ASK_PERMISSION
REJECT
```

Source risk levels:

```text
LOW
MEDIUM
HIGH
FORBIDDEN
UNKNOWN
```

Material types:

```text
CLI
LIBRARY
TEMPLATE
WORKFLOW
DOCKER_IMAGE
POLICY
SCHEMA
EXAMPLE
RESEARCH_REFERENCE
SERVICE
```

### Acceptance proof

- Builder runtime executes PHASE79;
- material folders exist;
- schemas parse;
- catalog exists;
- report/proof exists;
- queue returns to NONE;
- validator PASS;
- commit/push.

### Do not do

- do not search automatically;
- do not install tools;
- do not mark anything TRUSTED;
- do not create full Scout;
- do not build external agents.

### Next allowed step

STEP 4.

---

## STEP 4 — Manual Scout Pass 001

### Purpose

Create the first curated stockpile of candidate materials manually.

### Meaning

Full Scout does not exist yet, so E-Factory Control GPT performs the first manual scout pass.

This is not automatic acquisition.  
This is a controlled input file for Builder.

### Who does it

GPT researches and prepares the list.  
Owner reviews.  
Codex or terminal may save the file.

### Required outputs

```text
materials/inbox/MANUAL_SCOUT_PASS_001.json
reports/materials/MANUAL_SCOUT_PASS_001.md
```

### Initial candidate categories

1. JSON schema validation.
2. Python schema fallback.
3. Template rendering.
4. SBOM generation.
5. Vulnerability scanning.
6. License detection.
7. Policy gate.
8. Task runner.
9. GitHub Actions utility.
10. Docker/base image reference.
11. Security score/reference.
12. Package/dependency metadata reference.

### Initial candidate list

```text
Ajv
jsonschema
Copier
Syft
Grype
Trivy
OSV-Scanner
OPA
Conftest
go-task
Licensee
ScanCode Toolkit as deep mode
OSS Review Toolkit as later/deep mode
deps.dev as reference
OpenSSF Scorecard as reference/tool
SPDX tools/reference
Docker Official Images
```

### Required fields per candidate

```text
material_id
name
category
source_url
source_type
official_source
license
usage_mode_recommendation
risk_initial
platform_fit
windows_fit
github_actions_fit
reason_to_include
reason_not_to_trust_yet
first_test_command
admission_notes
```

### Acceptance proof

- manual scout pass file exists;
- markdown summary exists;
- no material is marked TRUSTED;
- every item has usage mode and risk;
- commit/push if saved in repo.

### Do not do

- do not install tools;
- do not copy external source code;
- do not import into production;
- do not call this complete material governance.

### Next allowed step

STEP 5.

---

## STEP 5 — PHASE80 Manual Scout Pass Import V1

### Purpose

Builder reads `MANUAL_SCOUT_PASS_001` and creates structured material catalog entries.

### Meaning

Builder starts acting like a material stockpile manager.

### Who does it

Builder runtime.

### Required outputs

```text
materials/MATERIAL_CATALOG.json
materials/catalog/MANUAL_SCOUT_PASS_001_CATALOG.json
reports/materials/MANUAL_SCOUT_PASS_001_IMPORT_REPORT.json
proofs/materials/MANUAL_SCOUT_PASS_IMPORT_V1.json
```

### Required behavior

- read manual scout pass;
- validate against schema;
- create catalog records;
- assign status: DISCOVERED, CANDIDATE, or REFERENCE_ONLY;
- reject forbidden/high-risk sources;
- do not install anything;
- do not mark TRUSTED;
- record missing metadata;
- recommend first admission batch.

### Acceptance proof

- runtime PASS;
- catalog updated;
- report/proof exists;
- queue NONE;
- validator PASS;
- commit/push.

### Do not do

- do not build wrappers;
- do not install tools;
- do not auto-download code;
- do not build external agents.

### Next allowed step

STEP 6.

---

## STEP 6 — PHASE81 Material Admission Policy V1

### Purpose

Define rules for moving materials from candidate to quarantine, trusted, reference-only, rejected, or owner-approval-required.

### Meaning

Builder needs policy before it uses materials.

### Who does it

Codex prepares pack.  
Builder executes.

### Required outputs

```text
contracts/materials/material_policy.schema.json
materials/MATERIAL_POLICY.json
modules/materials/evaluate_material_policy.ps1
reports/materials/MATERIAL_POLICY_V1_REPORT.json
proofs/materials/MATERIAL_POLICY_V1.json
```

### Policy must classify

- permissive licenses;
- copyleft licenses;
- unknown licenses;
- no-license materials;
- official tools;
- package registry tools;
- random archives;
- high-risk sources;
- runtime tools needing secrets;
- tools modifying repo;
- tools requiring cloud accounts;
- heavy frameworks.

### Default policy

```text
Official CLI with permissive license -> CANDIDATE_FOR_QUARANTINE
Package registry with permissive license -> CANDIDATE
Unknown license -> REFERENCE_ONLY or ASK_PERMISSION
GPL/AGPL -> OWNER_APPROVAL_REQUIRED
Random dump / warez / torrent -> REJECT or ISOLATED_RESEARCH_ONLY
LLM agent frameworks -> REFERENCE_ONLY until governance ready
```

### Acceptance proof

- sample candidate evaluations exist;
- policy report exists;
- proof exists;
- queue NONE;
- commit/push.

### Do not do

- do not require OPA yet;
- simple policy JSON + PowerShell evaluator is acceptable;
- do not install large tools;
- do not build agents.

### Next allowed step

STEP 7.

---

## STEP 7 — PHASE82 First Material Quarantine Trial V1

### Purpose

Move first selected candidates into quarantine records.

### Meaning

Builder prepares materials but still does not trust them.

### Who does it

Builder runtime.

### First trial candidates

```text
Ajv
jsonschema
Copier
OSV-Scanner or Syft
OPA/Conftest as candidate
```

### Required outputs

```text
materials/quarantine/<material_id>/MATERIAL_CARD.json
materials/quarantine/<material_id>/SOURCE_NOTES.md
materials/quarantine/<material_id>/ADMISSION_CHECKLIST.json
reports/materials/FIRST_QUARANTINE_TRIAL_REPORT.json
proofs/materials/FIRST_QUARANTINE_TRIAL_V1.json
```

### Required behavior

- create quarantine cards;
- record source and license;
- record candidate install command;
- record first smoke test plan;
- record policy decision;
- record missing data.

### Acceptance proof

- quarantine cards exist;
- no production installation;
- report/proof exists;
- queue NONE;
- commit/push.

### Do not do

- do not install 50 tools;
- do not run arbitrary downloads;
- do not modify PATH/global environment;
- do not mark trusted.

### Next allowed step

STEP 8.

---

## STEP 8 — PHASE83 Operation Contract Skeleton V1

### Purpose

Create formal operation system skeleton.

### Meaning

Materials are only useful if Builder can use them through controlled operations.

### Who does it

Codex prepares pack.  
Builder executes.

### Required outputs

```text
contracts/operations/operation.schema.json
contracts/operations/operation_result.schema.json
operations/operation_registry.json
modules/operations/register_operation.ps1
modules/operations/run_operation.ps1
reports/operations/OPERATION_CONTRACT_SKELETON_REPORT.json
proofs/operations/OPERATION_CONTRACT_SKELETON_V1.json
```

### Required operation fields

```text
operation_id
version
purpose
input_schema
output_schema
runner
allowed_side_effects
forbidden_side_effects
required_materials
proof_requirements
rollback_notes
security_notes
status
```

### Acceptance proof

- operation registry exists;
- sample no-op operation exists;
- validator PASS;
- queue NONE;
- commit/push.

### Do not do

- do not implement all operations;
- do not use external tools yet;
- do not build agents.

### Next allowed step

STEP 9.

---

## STEP 9 — PHASE84 First Wrapper Operation Contracts V1

### Purpose

Define operation wrappers around first materials.

### Meaning

External tools must be accessed through controlled wrappers, not random commands.

### Who does it

Builder runtime.

### First operation contracts

```text
validate_json_schema
render_template_bundle
generate_sbom
scan_vulnerabilities
evaluate_material_policy
write_material_report
write_proof
```

### Required outputs

```text
operations/validate_json_schema/operation.json
operations/render_template_bundle/operation.json
operations/generate_sbom/operation.json
operations/scan_vulnerabilities/operation.json
operations/evaluate_material_policy/operation.json
operations/write_material_report/operation.json
operations/write_proof/operation.json
reports/operations/FIRST_WRAPPER_OPERATION_CONTRACTS_REPORT.json
proofs/operations/FIRST_WRAPPER_OPERATION_CONTRACTS_V1.json
```

### Acceptance proof

- operation contracts validate;
- registry updated;
- no external tool execution required yet;
- queue NONE;
- commit/push.

### Do not do

- do not install all tools;
- do not mark operations runtime-proven unless they run;
- do not build external agent.

### Next allowed step

STEP 10.

---

## STEP 10 — PHASE85 First Tool Smoke Install Trial V1

### Purpose

Install and smoke-test a small first tool batch in controlled mode.

### Meaning

This is the first real material use, but still controlled.

### Who does it

Terminal/Builder depending on implementation.  
Owner approves installs.  
Codex may prepare scripts.

### First batch

```text
jsonschema or Ajv
Copier
OSV-Scanner or Syft
simple policy evaluator or Conftest
```

### Required outputs

```text
reports/materials/FIRST_TOOL_SMOKE_INSTALL_REPORT.json
proofs/materials/FIRST_TOOL_SMOKE_INSTALL_V1.json
operations/*/smoke_result.json
```

### Required per tool

- version command;
- source;
- license note;
- install method;
- smoke test;
- uninstall/rollback note;
- whether global or local;
- trust status.

### Acceptance proof

- version captured;
- smoke command passes;
- report/proof exists;
- no secrets;
- queue clean if runtime involved;
- commit/push.

### Do not do

- do not install 50 tools;
- do not install heavy ORT/ScanCode yet;
- do not modify system globally without approval;
- do not mark full material governance complete.

### Next allowed step

STEP 11.

---

## STEP 11 — PHASE86 Operation Runtime V1

### Purpose

Make Builder execute first operations through operation registry.

### Meaning

Builder should call registered operations, not random scripts.

### Who does it

Builder runtime.

### Required outputs

```text
modules/operations/invoke_registered_operation.ps1
reports/operations/OPERATION_RUNTIME_V1_REPORT.json
proofs/operations/OPERATION_RUNTIME_V1.json
```

### First runtime operations

```text
validate_json_schema
evaluate_material_policy
write_proof
```

### Acceptance proof

- operation invocation works;
- operation result schema produced;
- failed operation produces failure report, not fake PASS;
- queue NONE;
- commit/push.

### Do not do

- do not expose unrestricted command execution;
- do not build external agents.

### Next allowed step

STEP 12.

---

## STEP 12 — PHASE87 Self-Development Decision Kernel V1

### Purpose

Builder decides what to build next based on self-knowledge, material catalog, material policy, and operation registry.

### Meaning

This is the decision brain, but only after materials and operations foundation exists.

### Who does it

Builder runtime.

### Inputs

```text
reports/self_knowledge/BUILDER_SELF_DESCRIBE_REPORT.json
materials/MATERIAL_CATALOG.json
materials/MATERIAL_POLICY.json
operations/operation_registry.json
```

### Required outputs

```text
contracts/self_development/self_development_decision.schema.json
modules/self_development/choose_next_self_build_gap.ps1
reports/self_development/NEXT_SELF_BUILD_GAP_REPORT.json
reports/self_development/NEXT_SELF_BUILD_GAP_SUMMARY.md
proofs/self_development/SELF_DEVELOPMENT_DECISION_KERNEL_V1.json
```

### Report must contain

- current self state;
- missing foundation gaps;
- ranked gaps;
- selected gap;
- why this gap now;
- build/buy/adapt decision;
- required materials;
- required operations;
- risk;
- proof plan;
- what not to do.

### Acceptance proof

- Builder selects next gap from evidence;
- not just chat opinion;
- report/proof exists;
- queue NONE;
- commit/push.

### Do not do

- do not execute selected gap yet;
- do not build external agents;
- do not let Codex choose silently.

### Next allowed step

STEP 13.

---

## STEP 13 — PHASE88 Self-Build Program Generator V1

### Purpose

Builder turns selected gap into executable self-build program seed.

### Meaning

Builder begins preparing its own next build.

### Who does it

Builder runtime.

### Required outputs

```text
contracts/self_build_programs/self_build_program.schema.json
modules/self_build_programs/generate_self_build_program.ps1
self_build_programs/planned/<program_id>/PROGRAM.json
self_build_programs/planned/<program_id>/README.md
reports/self_build_programs/SELF_BUILD_PROGRAM_GENERATOR_V1_REPORT.json
proofs/self_build_programs/SELF_BUILD_PROGRAM_GENERATOR_V1.json
```

### Program must include

- program_id;
- source gap report;
- target capability;
- required operations;
- required materials;
- planned tasks;
- planned packs;
- proof plan;
- owner approval need;
- admission status.

### Acceptance proof

- program generated from decision report;
- program validates;
- not admitted automatically unless policy permits;
- queue NONE;
- commit/push.

### Do not do

- do not execute generated program;
- do not skip admission;
- do not build external agents.

### Next allowed step

STEP 14.

---

## STEP 14 — PHASE89 Generated Self-Build Program Admission V1

### Purpose

Builder checks whether generated self-build program is safe to enter live queue.

### Meaning

This is the gate between planning and actual self-building.

### Who does it

Builder runtime.

### Required outputs

```text
contracts/self_build_programs/program_admission.schema.json
modules/self_build_programs/evaluate_program_admission.ps1
reports/self_build_programs/PROGRAM_ADMISSION_REPORT.json
proofs/self_build_programs/PROGRAM_ADMISSION_V1.json
```

### Admission checks

- program schema valid;
- required operations exist;
- required materials available or candidate;
- no forbidden tools;
- proof plan exists;
- rollback plan exists;
- owner approval status;
- queue clean.

### Acceptance proof

- admission PASS/FAIL is justified;
- if PASS, program can be queued;
- if FAIL, gap report created;
- queue NONE;
- commit/push.

### Do not do

- do not execute program without admission;
- do not fake admission;
- do not build external agents.

### Next allowed step

STEP 15.

---

## STEP 15 — PHASE90 Builder Executes Own Generated Self-Build Program V1

### Purpose

Builder executes a self-build program it generated or admitted.

### Meaning

This is the first strong proof of self-building under the new architecture.

### Who does it

Builder runtime.

### Required outputs

```text
admitted task added to queue
pack executed
target capability created
proof/report created
queue returns to NONE
reports/self_build_programs/GENERATED_SELF_BUILD_EXECUTION_REPORT.json
proofs/self_build_programs/GENERATED_SELF_BUILD_EXECUTION_V1.json
```

### Acceptance proof

- Builder selected or admitted program;
- Builder executed through runtime;
- output capability exists;
- validator PASS;
- queue clean;
- commit/push.

### Do not do

- do not build external agents unless route change approved;
- do not bypass runtime;
- do not let Codex execute instead of Builder.

### Meaning of completion

This is the first strong self-build loop:

```text
Builder knows itself
-> Builder has material catalog
-> Builder has material policy
-> Builder has operation skeleton
-> Builder chooses next gap
-> Builder generates program
-> Builder admits program
-> Builder executes program
-> Builder proves result
```

---

## 8. After Step 15

After STEP 15 completes, create:

```text
AGENT_BUILDER_NEXT_15_STEPS_LOCK_V2
```

Likely next route block:

- Material Scout V1;
- stronger wrappers;
- full Operation System hardening;
- Material Governance v2 with OPA/Conftest;
- first trusted material batch;
- external agent readiness gate;
- external agent production under new standard.

These are not active until V2 is written and accepted.

---

## 9. Current Forbidden Shortcuts

Until this route reaches Step 15, do not:

- create a new external agent as the main goal;
- install a large stack of 50 tools into production;
- let Scout search automatically;
- use LangGraph/CrewAI/AutoGen/Ruflo as core;
- mark materials trusted without policy/proof;
- jump from PHASE78 directly to Material Scout;
- skip material catalog;
- skip operation registry;
- skip generated program admission;
- let Codex replace Builder in self-build execution.

---

## 10. Current Allowed Manual Work

Allowed:

- GPT may perform Manual Scout Pass 001.
- Owner may approve/reject material candidates.
- Codex may prepare self-build packs.
- Terminal may run validation and runtime.
- GitHub may store proof through commits/actions.

Not allowed:

- manual work pretending to be Builder runtime proof.

---

## 11. Settings / Knowledge Rule

Large route plans belong in GPT Knowledge as versioned documents.

Do not paste the full route into the short GPT Instructions field.

GPT Instructions should only contain a short rule:

```text
Always follow the latest AGENT_BUILDER_NEXT_15_STEPS_LOCK_V*.md from Knowledge.
If a new idea conflicts with the route, create ROUTE_CHANGE_REQUEST.
Do not continue execution after chat migration until DEEP_RECOVERY_REPORT is produced.
```

---

## 12. Default Next Step From Current State

Current state after PHASE78:

```text
NEXT ACTIVE STEP:
STEP 2 — store this route lock into GPT Knowledge and optionally repo.
```

After STEP 2:

```text
STEP 3 — PHASE79 Material Acquisition Bootstrap Contract V1.
```

Do not start STEP 3 before STEP 2 is stored.

---

## 13. Final Rule

This document is the active route lock.

If uncertain, do not invent a new route.

Return to:

1. Current step.
2. Required outputs.
3. Proof.
4. Cut list.
5. Next allowed step.
