# PHASE160F Full Self-Initiated Goal Selection Live Candidate Production

line: AGENT_BUILDER_SELF_DEVELOPMENT
mode: VERIFY
status: PREPARED_FOR_VALIDATION

## Objective

Build the full live self-growth organ that binds active tasks to candidate workspace production and lets Builder select a useful internal goal when no external task exists.

## Scope

- Enable `-EnableCandidateWorkspacePromotion` as the live active-task to candidate production path.
- Add self-diagnosis, useful-goal ranking, self-selected internal active task creation, candidate bundle production, promotion bundle update, owner review summary, and live observer/console fields.
- Validate owner-task, no-teacher self-initiated, and unsafe-task regression scenarios.

## Boundaries

- Candidate payloads remain session-local under `runtime_sessions`.
- Candidate output is not accepted code.
- Owner review, promotion, commit, and restart are required before accepted activation.
- No commit, push, branch switch, protected accepted-state mutation, external tools, internet, package install, or external-agent production.

## Validation

```powershell
.\validators\validate_phase160f_full_self_initiated_goal_selection_live_candidate_production_v1.ps1 -RepoRoot .
```

## Expected Result

```text
PHASE160F_FULL_SELF_INITIATED_GOAL_SELECTION_LIVE_CANDIDATE_PRODUCTION_VALIDATE_RESULT=PASS
OWNER_META_TASK_TO_CANDIDATE_PASS=True
SELF_INITIATED_INTERNAL_TASK_TO_CANDIDATE_PASS=True
CANDIDATE_WORKSPACE_PROMOTION_ENABLED=True
LIVE_ACTIVE_TASK_BOUND_TO_CANDIDATE_PRODUCTION=True
SELF_INITIATED_GOAL_SELECTED=True
INTERNAL_ACTIVE_TASK_CREATED=True
SELF_SELECTED_CANDIDATE_BUNDLE_CREATED=True
CANDIDATE_PAYLOAD_WRITTEN=True
PROMOTION_BUNDLE_CREATED=True
OWNER_REVIEW_SUMMARY_CREATED=True
ACTIVE_TASK_MOVED_TO_WAITING_OWNER_PROMOTION=True
NO_TEACHER_INBOX_REQUIRED_FOR_SELF_INITIATED_GOAL=True
LIVE_REPO_GUARD_PASS=True
RUN_HEAD_MATCH=True
NO_COMMIT_PERFORMED=True
NO_PUSH_PERFORMED=True
NO_BRANCH_SWITCH=True
PROTECTED_STATE_MUTATED=False
RUNTIME_OUTPUTS_STAGED=False
```
