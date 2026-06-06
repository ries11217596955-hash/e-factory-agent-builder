# PHASE161H Execution Plan

## Reused PHASE161E Modules

- `modules/invoke_builder_self_map_refresh_after_acceptance_001.ps1`
- `modules/inspect_builder_self_map_refresh_readiness_001.ps1`
- `modules/write_builder_self_map_memory_report_001.ps1`
- `modules/build_builder_accepted_change_memory_snapshot_001.ps1`
- `modules/validate_builder_acceptance_self_map_refresh_contract_001.ps1`

PHASE161H orchestrates these existing organs. It does not create another map generator.

## Acceptance Pipeline Sequence

1. Verify repository identity, branch, protected-state policy, and runtime staging safety.
2. Run the functional validator when provided.
3. Stage only explicitly allowed functional paths.
4. Commit and push the functional change.
5. Fetch and verify the remote functional commit.
6. Run PHASE161E refresh with the functional commit as `accepted_subject_head`.
7. Validate `SELF_KNOWLEDGE_READY`.
8. Stage only explicitly allowed refresh artifacts.
9. Commit and push refreshed self-map artifacts.
10. Fetch and verify the final remote commit.
11. Write a delivery record that distinguishes both commits.

## Functional Commit Versus Refresh Commit

The functional commit is the accepted subject described by the map. The refresh commit contains derived memory artifacts. The refresh commit does not become a new refresh subject, preventing self-hash recursion.

Before the refresh commit exists:

- `accepted_subject_head` is the functional commit hash.
- `map_artifact_commit_pending=true`.

After the refresh commit, its hash is reported in pipeline delivery without requiring another refresh.

## Automatic Refresh, Not Passive Stale Detection

The normal real-mode path invokes refresh immediately after the functional commit is remotely verified. Completion is denied unless the refresh contract reports:

- `map_refresh_status=SELF_KNOWLEDGE_READY`
- `self_knowledge_ready=true`
- `map_is_ready_for_next_decision=true`

Dry-run inspects and proves the intended two-commit sequence without committing, pushing, or running a mutating refresh.

## Future Codex Usage

Future accepted-change tasks should call the pipeline with:

- phase and accepted-phase identifiers;
- functional and refresh commit messages;
- exact functional and refresh allowlists;
- a validator command;
- real mode only after phase validation passes.

Dry-run is used by validators to prove policy and allowlist behavior.

## Safety Checks

- Repo identity files exist.
- Current branch is expected.
- Protected files are not modified unless explicitly included in the functional allowlist.
- `runtime_sessions` is never staged.
- Functional and refresh staged sets are subsets of their allowlists.
- Validator succeeds before functional commit.
- Push/fetch verification succeeds after each commit.
- Refresh contract succeeds before refresh commit.
- Final local and remote heads match.

## Never Staged By Default

- `TASK_QUEUE.json`
- `GENESIS_STATE.json`
- `CAPABILITY_ROADMAP.json`
- `packs/registry.json`
- `orchestrator/run.ps1`
- `runtime_sessions/`
- route locks

Explicit protected promotion remains a separately approved phase, not a pipeline default.

## What Will Not Be Modified

PHASE161H does not modify protected state, route locks, orchestrator flow, package dependencies, external agents, runtime outputs, or PHASE161D classifier logic.
