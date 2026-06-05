# PHASE161D Execution Plan

## Scope

Line: `AGENT_BUILDER_SELF_DEVELOPMENT`

Mode: `VERIFY`

Goal: harden the accepted PHASE161C body map classifier so it separates live wiring, current route wiring, validator proof, proof/report references, historical references, superseded artifacts, disconnected artifacts, real stubs, false-positive stub signals, and protected/risk-locked files.

## Root Guard Result

- PWD: `C:\Users\vmammadov\Documents\e-factory-agent-builder`
- Branch: `phase110-idempotent-autonomy-trial-runtime`
- HEAD: `c27dcf95253ae54a7492b54760b5988d078f023a`
- Required identity files present: `CAPABILITY_ROADMAP.json`, `GENESIS_STATE.json`, `TASK_QUEUE.json`, `packs/registry.json`, `orchestrator/run.ps1`
- Git status before PHASE161D changes: clean

## PHASE161C Modules Reused Or Extended

PHASE161D extends the existing PHASE161C map system rather than creating a parallel map:

- `modules/build_builder_agent_body_map_001.ps1`
- `modules/classify_builder_agent_body_artifact_001.ps1`
- `modules/inspect_builder_module_wiring_graph_001.ps1`
- `modules/detect_builder_stub_placeholder_artifacts_001.ps1`
- `modules/detect_builder_orphaned_artifacts_001.ps1`
- `modules/build_builder_self_model_gap_chain_001.ps1`
- `modules/update_builder_self_model_active_map_001.ps1`
- `modules/inspect_builder_agent_body_map_freshness_001.ps1`

Most changes are concentrated in `modules/build_builder_agent_body_map_001.ps1`, because it owns scan inputs, evidence paths, primary status, derived map outputs, stub inventory, orphan inventory, gap chain, safe repair candidates, and unsafe debt.

## Why PHASE161C Over-Classified

PHASE161C marked too many artifacts as active/proven because it treated broad proof/report/phase references as wiring evidence. Historical pack payloads and old reports could become `ACTIVE_WIRED_PROVEN` if they shared a phase hint and proof file, even when no current daemon, active route, or runner called them.

PHASE161C also treated any occurrence of words such as `placeholder` as a real stub signal. That catches some real stubs, but it also misclassifies documentation and explanatory text that mentions placeholder rules.

PHASE161C did not propagate route-lock supersession into artifact status, so `SUPERSEDED=0` even though `route_locks/ACTIVE_ROUTE_LOCK.json` explicitly lists superseded route locks.

## New Evidence Taxonomy

Every artifact will expose:

- `evidence_type`
- `evidence_strength`
- `evidence_basis`
- `live_evidence_paths`
- `validator_evidence_paths`
- `proof_evidence_paths`
- `report_reference_paths`
- `historical_reference_paths`
- `current_wiring_signals`
- `superseded_by`
- `stub_false_positive`

Evidence types:

- `LIVE_RUNTIME_PROVEN`
- `CURRENT_DAEMON_WIRED`
- `CURRENT_ROUTE_WIRED`
- `CURRENT_RUNNER_WIRED`
- `VALIDATOR_PROVEN`
- `PROOF_JSON_PROVEN`
- `REPORT_REFERENCED`
- `HISTORICAL_REFERENCE_ONLY`
- `SUPERSEDED_BY_ROUTE_LOCK`
- `DISCONNECTED_NOT_WIRED`
- `REAL_STUB_OR_PLACEHOLDER`
- `FALSE_POSITIVE_STUB_SIGNAL`
- `PROTECTED_RISK_LOCKED`
- `UNKNOWN_NEEDS_REVIEW`

Evidence strength:

- `LIVE_STRONG`
- `CURRENT_WIRED_STRONG`
- `VALIDATOR_MEDIUM`
- `PROOF_MEDIUM`
- `REPORT_WEAK`
- `HISTORICAL_WEAK`
- `SUPERSEDED_STRONG`
- `DISCONNECTED_WEAK`
- `RISK_LOCKED_STRONG`
- `UNKNOWN_WEAK`

## New Active And Proven Criteria

An artifact is `ACTIVE_WIRED_PROVEN` only when it has current wiring and live runtime proof, or current route/daemon/runner wiring plus direct proof evidence.

An artifact is `ACTIVE_WIRED_UNPROVEN` when it is current daemon/route/runner wired but lacks proof.

An artifact is `PRESENT_WIRED_TO_VALIDATOR_ONLY` when validator evidence exists but no current live/route/daemon/runner wiring exists.

An artifact is `PROOF_NO_LIVE_EVIDENCE` when proof JSON exists but no live runtime evidence and no current wiring exists.

An artifact is `PRESENT_NOT_WIRED` when it has no current wiring and only report/reference/historical evidence, or no evidence.

Historical pack payloads must not be called active unless current route, daemon, or runner references them directly.

## Stub False-Positive Rules

Raw keyword matching is no longer enough. Real stub classification requires a behavior-level signal such as:

- `throw "not implemented"`
- `TODO` or `FIXME` in executable code context
- explicit `stub` marker in a short/non-behavior artifact
- empty or near-empty executable artifact
- validator that only prints pass without meaningful checks

Documentation or reports that merely discuss words like `placeholder` are classified as `FALSE_POSITIVE_STUB_SIGNAL` unless they are near-empty or explicitly declare themselves unimplemented.

## Supersession Propagation Strategy

PHASE161D reads `route_locks/ACTIVE_ROUTE_LOCK.json` and the active route lock file. Artifacts named in `superseded_route_locks`, `archived_reference_locks`, or the active route lock `supersedes:` section are classified with `evidence_type=SUPERSEDED_BY_ROUTE_LOCK`, `evidence_strength=SUPERSEDED_STRONG`, and `primary_status=SUPERSEDED`.

The derived output `reports/self_development/superseded_artifact_inventory.json` records the propagated supersession evidence.

## Validation Strategy

The validator will:

1. Run root guard.
2. Verify `PHASE161D_EXECUTION_PLAN.md` exists.
3. Snapshot protected state hashes.
4. Parser-check touched PHASE161C modules and the PHASE161D validator.
5. Run the reused PHASE161C body-map builder.
6. Verify every artifact has `evidence_type`, `evidence_strength`, and evidence separation fields.
7. Verify `ACTIVE_WIRED_PROVEN` is reduced from PHASE161C's suspicious `842`.
8. Verify `PRESENT_NOT_WIRED` or historical/disconnected inventory is non-zero.
9. Verify route-lock supersession is propagated into `superseded_artifact_inventory.json`.
10. Verify false-positive stub inventory exists and includes explanatory-text cases.
11. Verify live evidence separation output exists.
12. Verify protected state and runtime staging remain clean.
13. Write report, proof, route request, and delivery artifacts.

## What Will Not Be Modified

- No protected state mutation.
- No edits to `TASK_QUEUE.json`, `GENESIS_STATE.json`, `CAPABILITY_ROADMAP.json`, `packs/registry.json`, or `orchestrator/run.ps1`.
- No file deletion.
- No module rename.
- No architecture rewrite.
- No package install.
- No internet.
- No external agents.
- No commit or push without owner approval.
