# NEXT PC HANDOFF - PHASE160D READY

## Important

This handoff is path-independent.

On the next PC, do NOT assume this path:

```text
C:\Users\Azerbaijan\Documents\e-factory-agent-builder
```

Instead, open PowerShell/VS Code terminal inside the actual cloned repo folder on that PC.

The restore check below uses:

```powershell
$RepoRoot = (Get-Location).Path
```

## Current accepted baseline

```text
Branch: phase110-idempotent-autonomy-trial-runtime
Accepted HEAD before this handoff fix: c510bcb
Previous accepted engineering HEAD: 25c9bb6 Fix PHASE160C live macro run binding
```

## What was proven

```text
OWNER_SUPERVISED_MACRO_SELF_GROWTH_RUN=PASS
FULL_MACRO_CYCLES_OBSERVED=3
TOTAL_DUTIES=23
LEDGER_COUNT=23
FINAL_STATE_STATUS=STOPPED
STOP_FLAG_SEEN=True
SAFE_STOP=True
ACCEPTED_STATE_MUTATED=False
ACCEPTED_MEMORY_MUTATED=False
ACCEPTED_SELF_MODEL_MUTATED=False
```

Builder completed 3 full session-local macro self-growth cycles:

```text
SELF_OBSERVE_MAP_REFRESH
-> CAPABILITY_INVENTORY_DIFF
-> GAP_RANK_AND_SELECT
-> SELF_CHANGE_CANDIDATE_GENERATE
-> SANDBOX_DRY_RUN
-> VALIDATE_AND_DECIDE
-> EXPERIENCE_ABSORB_AND_NEXT_GOAL
```

## Evidence archives

Runtime evidence archives were saved outside repo on the old PC only.
They are NOT required for next-PC continuation unless manually copied.

## Next strongest move

```text
PHASE160D_AGENT_CHALLENGE_EXPERIENCE_ABSORPTION_GATE_001
```

First try Builder, not Codex.

Goal:

```text
Can Builder convert an Owner task into a session-local absorption gate candidate?
```

Success signs:

```text
EXPERIENCE_ABSORPTION_GATE appears in artifact/ledger
PROMOTE / ARCHIVE / QUARANTINE / OWNER_APPROVAL appear
accepted_memory_mutated=false
decision=KEEP_SESSION_LOCAL or OWNER_DECISION_REQUIRED
```

If Builder cannot bind Owner task to macro-growth target, then create bounded Codex repair for:

```text
TASK_INTAKE_TO_MACRO_GROWTH_BINDING_GAP
```

## Do not do next

- Do not run PHASE161.
- Do not commit runtime_sessions.
- Do not mutate TASK_QUEUE.json.
- Do not mutate GENESIS_STATE.json.
- Do not mutate CAPABILITY_ROADMAP.json.
- Do not mutate packs/registry.json.
- Do not mutate orchestrator/run.ps1.
- Do not call Codex first unless Agent Challenge fails.

## Next PC restore check

On the next PC, first open terminal inside the actual repo folder, then run:

```powershell
$RepoRoot = (Get-Location).Path

"NEXT_PC_RESTORE_CHECK_START"
"REPO_ROOT=$RepoRoot"

"REPO_MARKERS_START"
Test-Path .\CAPABILITY_ROADMAP.json
Test-Path .\GENESIS_STATE.json
Test-Path .\TASK_QUEUE.json
Test-Path .\packs\registry.json
Test-Path .\orchestrator\run.ps1
"REPO_MARKERS_END"

git fetch origin
git switch phase110-idempotent-autonomy-trial-runtime
git pull --ff-only origin phase110-idempotent-autonomy-trial-runtime

"BRANCH=$(git branch --show-current)"
"LOCAL_HEAD=$(git rev-parse --short HEAD)"
"REMOTE_HEAD=$(git rev-parse --short origin/$(git branch --show-current))"

"STATUS_START"
git status --short
"STATUS_END"

"KEY_FILES_START"
Test-Path .\modules\start_builder_live_growth_daemon_001.ps1
Test-Path .\modules\watch_builder_live_growth_session_observer_001.ps1
Test-Path .\modules\watch_builder_live_console_001.ps1
Test-Path .\modules\invoke_builder_live_self_growth_duty_step_001.ps1
Test-Path .\validators\validate_phase160b_macro_self_growth_ignition_v1.ps1
Test-Path .\validators\validate_phase160c_live_macro_run_binding_v1.ps1
Test-Path .\reports\self_development\NEXT_PC_HANDOFF_PHASE160D_READY_2026_06_03.md
"KEY_FILES_END"

"NEXT_PC_RESTORE_CHECK_END"
```

Expected:

```text
LOCAL_HEAD = REMOTE_HEAD
git status --short is empty
all repo markers = True
all key files = True
```
