# PHASE160E Full Long-Lived Runner Candidate Workspace Promotion Task Lifecycle

line: AGENT_BUILDER_SELF_DEVELOPMENT
mode: VERIFY
status: PREPARED_FOR_VALIDATION

## Objective

Promote the live growth runner from task intake only to a full semi-automatic session contour with immutable run identity, runtime guard, candidate workspace, promotion bundle, owner review gate, task lifecycle receipts, backlog advancement, plan item advancement, and final handoff summary.

## Scope

- Add runtime identity and guard inspection.
- Add session-local candidate workspace generation.
- Add promotion bundle finalization.
- Wire daemon, console, and observer to PHASE160E fields.
- Validate with a live daemon smoke run and proof pack.

## Boundaries

- Candidate output is not accepted code.
- Owner stop, check, promotion, commit, and restart are required before any candidate becomes accepted.
- No commit, push, branch switch, protected accepted-state mutation, or external-agent production is allowed.
- Runtime outputs must not be staged.

## Validation

```powershell
.\validators\validate_phase160e_full_long_lived_runner_candidate_workspace_promotion_task_lifecycle_v1.ps1 -RepoRoot .
```

## Expected Result

```text
PHASE160E_FULL_LONG_LIVED_RUNNER_CANDIDATE_WORKSPACE_PROMOTION_TASK_LIFECYCLE_VALIDATE_RESULT=PASS
RUN_MANIFEST_WRITTEN=True
RUN_HEAD_LOCKED=True
LIVE_REPO_GUARD_PASS=True
CANDIDATE_WORKSPACE_CREATED=True
CANDIDATE_BUNDLE_CREATED=True
PROMOTION_BUNDLE_CREATED=True
OWNER_REVIEW_SUMMARY_CREATED=True
ACTIVE_TASK_MOVED_TO_WAITING_PROMOTION=True
BACKLOG_ADVANCED=True
PLAN_ITEM_ADVANCED=True
NO_LIVE_REPO_CODE_MUTATION=True
NO_COMMIT_PERFORMED=True
NO_PUSH_PERFORMED=True
NO_BRANCH_SWITCH=True
PROTECTED_STATE_MUTATED=False
RUNTIME_OUTPUTS_STAGED=False
```
