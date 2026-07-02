# PHASE160D Live Task Intake Queue Digest Plan Binding Request

status: PREPARED
line: AGENT_BUILDER_SELF_DEVELOPMENT
mode: VERIFY

## Root Gap

LIVE_TASK_INBOX_TO_MACRO_CYCLE_BINDING_GAP

## Requested Change

Add a session-local live task intake organ that consumes `teacher_inbox` task envelopes, writes task digests, quarantines unsafe notes, writes backlog records for non-active valid tasks, splits long plans into `plan_items`, selects one active task, and binds that active task into macro gap ranking and candidate generation.

## Scope

- `modules/invoke_builder_live_self_growth_duty_step_001.ps1`
- `modules/start_builder_live_growth_daemon_001.ps1`
- `modules/watch_builder_live_console_001.ps1`
- `modules/watch_builder_live_growth_session_observer_001.ps1`
- `validators/validate_phase160d_live_task_intake_queue_digest_plan_binding_v1.ps1`
- `reports/self_development/PHASE160D_LIVE_TASK_INTAKE_QUEUE_DIGEST_PLAN_BINDING_REPORT.md`
- `proofs/self_development/PHASE160D_LIVE_TASK_INTAKE_QUEUE_DIGEST_PLAN_BINDING_PROOF.json`

## Safety Boundary

- Runtime session only.
- No accepted state mutation.
- No accepted memory mutation.
- No self-model mutation.
- No repo commit.
- No external-agent production.
- No dependency install or external fetch.

## Validation

```powershell
.\validators\validate_phase160d_live_task_intake_queue_digest_plan_binding_v1.ps1 -RepoRoot .
```
