# PHASE165S-D2B-R2 Summary State Sync

Status: PASS_INCOMPLETE_RESUMABLE

The live queue and resume state had advanced while the main proof, report, and final summary still described the earlier R1 repair cursor. R2 treats `queue_state.json` and `resume_state.json` as authoritative and refreshes all main reporting artifacts from those files without advancing or resetting the curriculum run.

## Current State

- Resume status: `RUNNING_READY_TO_RESUME`
- Summary status: `INCOMPLETE_RESUMABLE`
- Processed: `760`
- Accepted: `665`
- Remaining: `49240`
- Quarantined: `95`
- Denied: `0`
- Failed: `0`
- Recovered failures: `4`
- Summary counts match state: `true`
- Partial accepted surface detected: `false`
- Can resume: `true`

## Runner Hardening

- `-SyncSummaryOnly` refreshes state status, heartbeat, main proof, main report, and final summary without processing a candidate.
- Every numbered checkpoint now refreshes the main proof/report/final summary from the same current state snapshot.
- Every controlled exit already refreshes those artifacts and now normalizes a non-empty, failure-free stopped run to `RUNNING_READY_TO_RESUME`.
- Active checkpoints use `RUNNING_ACTIVE`; an inactive, safe cursor uses `INCOMPLETE_RESUMABLE`.

## Validator Boundary

The validator still fails on counter mismatch, active/resumable status mismatch, nonzero failures, partial accepted surfaces, or forbidden protected-state mutations. It returns `INCOMPLETE_RESUMABLE` only when state and summary counts match and the state is explicitly `RUNNING_READY_TO_RESUME`.

## Resume

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File modules/run_phase165s_d2b_big_curriculum_autonomous_learn_until_empty_001.ps1 -Resume
```
