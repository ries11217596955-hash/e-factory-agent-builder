# CODEX_CURRICULUM_CANONICAL_RUNNER_V1

Status: ACTIVE_OWNER_ENTRYPOINT_CANDIDATE
Runtime ready: false

## Owner interface

```powershell
operations/school/curriculum/canonical_runner/run_codex_curriculum_school_v1.ps1 -TargetAccepted <N> -RunKind <Test|Real>
```

Owner supplies only:

- `TargetAccepted`: requested candidate/atom budget N.
- `RunKind`: `Test` or `Real`.

## Scheduler law

```text
TargetAccepted = N
ChunkSize = 5000
BatchSize = 100
```

The runner must divide N into chunks of 5000 and batches of 100. Last chunk/batch may be smaller. N is a run budget, not proof of learning.

## Boundary

This V1 installs the canonical two-parameter scheduler/gate for the Codex curriculum path. It proves schedule/gate behavior and blocks Real. It does not yet execute all Codex batches automatically.

## Required execution path after scheduler

```text
for each chunk:
  for each batch:
    Codex produces batch candidates by contract
    contract validator runs
    accepted candidates digest through school
    bad candidates quarantine
  chunk checkpoint
final:
  active repo-body decision-use proof
  scale gate report
```