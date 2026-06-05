# PHASE161C Execution Plan

## Scope

Line: `AGENT_BUILDER_SELF_DEVELOPMENT`

Mode: `VERIFY`

Goal: build a derived living body map and self-model sync artifact that reuses existing self-map, body, capability, registry, route, proof, and report organs without mutating protected state.

## Root Guard Result

- PWD: `C:\Users\vmammadov\Documents\e-factory-agent-builder`
- Branch: `phase110-idempotent-autonomy-trial-runtime`
- HEAD: `7ffea80880652315c21eaec2f75300ab9a8c0450`
- Required identity files present: `CAPABILITY_ROADMAP.json`, `GENESIS_STATE.json`, `TASK_QUEUE.json`, `packs/registry.json`, `orchestrator/run.ps1`
- Git status before PHASE161C changes: clean

## Existing Organs Found

Protected source-of-truth files:

- `CAPABILITY_ROADMAP.json`
- `GENESIS_STATE.json`
- `TASK_QUEUE.json`
- `packs/registry.json`
- `route_locks/ACTIVE_ROUTE_LOCK.json`

Reusable self-map and self-knowledge organs:

- `self_knowledge/BUILDER_SELF_MODEL.json`
- `self_model/BUILDER_SELF_MODEL.json`
- `self_knowledge/MODULE_INVENTORY.json`
- `self_knowledge/CAPABILITY_MANIFEST.json`
- `self_knowledge/ROADMAP_STATE.json`
- `modules/build_builder_self_knowledge.ps1`
- `modules/write_builder_self_describe_report.ps1`
- `contracts/self_knowledge/*.schema.json`

Reusable body and capability organs:

- `living_learning_environment/body/body_registry.json`
- `living_learning_environment/body/BUILDER_BODY_ORGAN_PACK_V1.json`
- `living_learning_environment/body/body_policy.json`
- `living_learning_environment/body/body_runtime_contract.json`
- `living_learning_environment/body/body_safety_boundaries.json`
- `living_learning_environment/body/organs/*.json`
- `capability_shelf/registry.json`
- `capability_shelf/capabilities/*.json`

Reusable gap/backlog context:

- `self_build_backlog/CAPABILITY_GAP_DETECTOR_V1.json`
- `self_build_backlog/CAPABILITY_GAP_INDEX_V1.json`
- `self_build_backlog/OWNER_ORDER_TO_GAP_MAP_V1.json`

## Current Source-of-Truth Candidate

The current PHASE161C active-map candidate will be:

- `reports/self_development/SELF_MODEL_ACTIVE_MAP.json`

Status: `DERIVED_FROM_EXISTING`

Reason: the repo already has body, self-model, capability, roadmap, and registry organs, but they are split and do not provide one current artifact with the required PHASE161C taxonomy, `why_status`, wiring graph, function inventory, stub inventory, orphan inventory, safety-sensitive operation signals, and self-model gap chain. Protected root state is read-only in this phase.

## Protected Read-Only Files

These files will be read but not modified:

- `TASK_QUEUE.json`
- `GENESIS_STATE.json`
- `CAPABILITY_ROADMAP.json`
- `packs/registry.json`
- `orchestrator/run.ps1`
- `route_locks/ACTIVE_ROUTE_LOCK.json`

If future updates are needed, PHASE161C will emit candidates only under `reports/self_development/protected_state_update_candidates/`.

## Reuse And Extension Strategy

The implementation will not create a blind parallel map. It will reuse discovered organs as source inputs and write a derived map in `reports/self_development`.

Existing modules such as `modules/build_builder_self_knowledge.ps1` are useful but insufficient because they do not generate the PHASE161C required wiring graph, taxonomy, gap chain, stub inventory, orphan inventory, or `why_status` fields. The safest approach is to create PHASE161C-specific map builder modules that read existing organs and generate derived artifacts without changing older accepted modules.

## Files Planned For Creation Or Change

New modules:

- `modules/discover_builder_existing_self_map_organs_001.ps1`
- `modules/build_builder_agent_body_map_001.ps1`
- `modules/inspect_builder_module_wiring_graph_001.ps1`
- `modules/classify_builder_agent_body_artifact_001.ps1`
- `modules/detect_builder_stub_placeholder_artifacts_001.ps1`
- `modules/detect_builder_orphaned_artifacts_001.ps1`
- `modules/build_builder_self_model_gap_chain_001.ps1`
- `modules/update_builder_self_model_active_map_001.ps1`
- `modules/inspect_builder_agent_body_map_freshness_001.ps1`

New validator:

- `validators/validate_phase161c_agent_body_map_reuse_and_self_model_sync_v1.ps1`

Derived map artifacts:

- `reports/self_development/agent_body_map.json`
- `reports/self_development/agent_body_map.md`
- `reports/self_development/module_wiring_graph.json`
- `reports/self_development/function_inventory.json`
- `reports/self_development/stub_placeholder_inventory.json`
- `reports/self_development/orphaned_artifact_inventory.json`
- `reports/self_development/self_model_gap_chain.json`
- `reports/self_development/SELF_MODEL_ACTIVE_MAP.json`
- `reports/self_development/agent_body_map_update_report.md`
- `reports/self_development/safe_repair_candidates_from_body_map.json`
- `reports/self_development/unsafe_debt_backlog_from_body_map.json`

Documentation and delivery artifacts:

- `docs/PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC.md`
- `reports/self_development/PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC_REPORT.md`
- `proofs/self_development/PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC_PROOF.json`
- `route_change_requests/PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC_REQUEST.md`
- `reports/self_development/PHASE161C_AGENT_BODY_MAP_REUSE_AND_SELF_MODEL_SYNC_CODEX_DELIVERY.md`

## Why Each Change Is Needed

- Discovery module: makes existing map organ discovery repeatable instead of only chat-reported.
- Body-map builder: produces the derived active map and required inventories from existing repo organs.
- Wiring graph inspector: exposes module, validator, schema, proof, report, route, and protected-state relationships.
- Artifact classifier: centralizes PHASE161C taxonomy and `why_status` reasoning.
- Stub detector: identifies placeholders, empty files, and weak validators without deleting anything.
- Orphan detector: identifies present artifacts with weak or missing references while marking `safe_to_delete_now=false`.
- Gap-chain builder: explains why the next connection is blocked and what dependency chain remains.
- Active map updater: writes the derived `SELF_MODEL_ACTIVE_MAP.json` without mutating protected state.
- Freshness inspector: checks whether derived map artifacts still match source inputs.
- Validator: proves required files, JSON parseability, parser checks, classifications, evidence fields, and protected-state cleanliness.

## What Will Not Be Changed

- No protected state mutation.
- No `TASK_QUEUE.json`, `GENESIS_STATE.json`, `CAPABILITY_ROADMAP.json`, `packs/registry.json`, or `orchestrator/run.ps1` edits.
- No branch switch, commit, or push.
- No package install.
- No internet.
- No runtime output staging.
- No deletion or renaming of existing files.
- No full architecture rewrite.

## Validator Strategy

The validator will:

1. Run root guard.
2. Verify this execution plan and discovery JSON exist and parse.
3. Snapshot protected-state hashes.
4. Parser-check new and touched PowerShell files.
5. Run the body-map builder.
6. Verify all required JSON and Markdown artifacts exist.
7. Parse all generated JSON artifacts.
8. Verify map role is `DERIVED_FROM_EXISTING`.
9. Verify every meaningful map item has required fields and every non-active or uncertain item has `why_status`.
10. Verify active wired proven items have evidence paths.
11. Verify graph nodes and edges include edge type, confidence, and evidence pattern.
12. Verify stub, orphan, safe repair, unsafe debt, and gap-chain outputs are present.
13. Verify protected-state hashes remain unchanged.
14. Verify `runtime_sessions` outputs are not staged.
15. Write report, proof, route request, and delivery artifacts.

## Rollback And Safety Notes

PHASE161C creates derived artifacts and new modules only. Protected state remains untouched. If validation fails, repair should be limited to the PHASE161C modules and derived artifacts listed above. Existing self-model, self-knowledge, body registry, capability shelf, route lock, and root state files should remain intact unless owner explicitly approves a later protected-state update.

## Remaining Work After PHASE161C

- Owner review of the derived map as active-map candidate.
- Optional protected-state update request if the owner wants `SELF_MODEL_ACTIVE_MAP.json` promoted beyond `reports/self_development`.
- Follow-up implementation of safe repair candidates identified by the gap chain.
