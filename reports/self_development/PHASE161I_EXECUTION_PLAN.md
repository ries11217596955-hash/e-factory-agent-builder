# PHASE161I Execution Plan

## Why PHASE161H Is Not Sufficient

PHASE161H enforces `FUNCTIONAL_COMMIT -> SELF_MAP_REFRESH -> REFRESH_COMMIT` only when a caller uses the repository acceptance pipeline module. A direct manual commit and push can bypass that local orchestration. PHASE161I adds a branch push workflow so accepted-branch memory refresh is a remote repository behavior.

## GitHub Push Auto-Refresh

The workflow triggers on pushes to `phase110-idempotent-autonomy-trial-runtime`, checks out the pushed branch with full history, and uses the pushed SHA as `accepted_subject_head`. On `windows-latest`, it invokes a narrow wrapper around the existing PHASE161E refresh module, validates `SELF_KNOWLEDGE_READY`, stages only explicit derived map artifacts, commits them, and pushes to the same branch.

## Recursion Prevention

The workflow skips commits whose message contains `[self-map-refresh]`. The generated commit message is `Refresh self-map after push [self-map-refresh]`. GitHub also does not normally create another workflow run from a push made with the repository `GITHUB_TOKEN`. No PAT or external token is used.

## Token And Permissions

The workflow declares `contents: write`. Checkout uses the standard repository token through `actions/checkout`; push uses the checkout credential. The workflow never reads a PAT, custom secret, or external token.

## Accepted Subject Head

For a non-refresh push, `${{ github.sha }}` is passed to the wrapper as `AcceptedSubjectHead`. The wrapper confirms that the checked-out `HEAD` matches this value before regenerating memory. The refresh commit describes that functional push and is not a new refresh subject.

## Commit Allowlist

The workflow may stage only derived self-map outputs under `reports/self_development`, including:

- `SELF_MODEL_ACTIVE_MAP.json`
- body map, wiring, inventory, gap, evidence, historical, superseded, and stub outputs
- self-map refresh result, memory report, policy, and accepted-change snapshot
- `PHASE161I_AUTO_REFRESH_AFTER_PUSH_RESULT.json`

The allowlist also includes map-builder derived summaries that PHASE161E currently regenerates, such as classifier hardening and safe-repair candidate outputs. No wildcard staging is allowed.

## Files Never Modified Or Staged

- `TASK_QUEUE.json`
- `GENESIS_STATE.json`
- `CAPABILITY_ROADMAP.json`
- `packs/registry.json`
- `orchestrator/run.ps1`
- `route_locks/`
- `runtime_sessions/`

The wrapper records protected hashes before refresh and verifies them afterward. The workflow rejects protected, route-lock, runtime, or non-allowlisted changes before commit.

## Validation And Remote Proof

The local validator checks parser status, policy fields, YAML trigger/permissions/marker/token rules, explicit staging, wrapper behavior against the current HEAD, and absence of commit/push/branch switch. After the functional workflow commit is pushed, Codex fetches the remote branch every 20 seconds for up to 10 minutes. Acceptance requires a later remote commit with the refresh marker, the three required result artifacts, and `SELF_KNOWLEDGE_READY` for the functional commit SHA.

## Rollback And Failure Behavior

The workflow does not commit when refresh or contract validation fails. A failed remote run leaves the functional commit visible but PHASE161I unaccepted. The workflow commit can be reverted independently; protected state is outside its write surface.

## Files To Create

- `.github/workflows/self-map-auto-refresh-after-push.yml`
- `modules/invoke_builder_github_push_self_map_auto_refresh_001.ps1`
- `modules/validate_builder_github_push_self_map_auto_refresh_workflow_001.ps1`
- `modules/write_builder_github_push_self_map_auto_refresh_delivery_001.ps1`
- `validators/validate_phase161i_github_push_self_map_auto_refresh_workflow_v1.ps1`
- `reports/self_development/github_push_self_map_auto_refresh_policy.json`
- PHASE161I report, proof, route request, Codex delivery, and acceptance delivery

## What Will Not Be Changed

PHASE161I does not alter protected state, route locks, orchestrator behavior, PHASE161D classification criteria, PHASE161E map generation, package dependencies, external agents, or runtime session content.
