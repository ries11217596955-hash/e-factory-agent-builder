# PHASE165S-D2B Big Curriculum Autonomous Learning

Status: RUNNING_ACTIVE

D2A material remains raw and untrusted until each candidate passes the existing school acceptance path. D2B does not manually wave batches; one process advances one candidate at a time through C2B and the PHASE162 accepted-core executor until the queue is empty or `STOP_SIGNAL` appears.

Processed: 13300 / 50000
Accepted: 12146
Quarantined: 1154
Denied: 0
Skipped duplicates: 0
Failed: 0
Queue empty: False

## Resume

Remove `reports/self_development/phase165s_d2b_big_curriculum_autonomous_learning/STOP_SIGNAL` if present, then run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File modules/run_phase165s_d2b_big_curriculum_autonomous_learn_until_empty_001.ps1 -Resume
```

## Validate

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File validators/validate_phase165s_d2b_big_curriculum_autonomous_learning_v1.ps1
```

## Next Required Action

WAIT_FOR_ACTIVE_D2B_RUN_OR_USE_STOP_SIGNAL
