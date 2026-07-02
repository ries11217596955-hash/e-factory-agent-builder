# SCHOOL_CANONICAL_RUN_CONTRACT_V1

Status: ENTRYPOINT_TEST_IMPLEMENTED_REAL_BLOCKED
Runtime ready: false

## Owner interface

The school must expose one owner-facing launch shape only:

```powershell
operations/school/run_agent_school.ps1 -TargetAccepted <N> -RunKind <Test|Real>
```

Owner inputs:

- `TargetAccepted`: required positive integer. This is the requested number of accepted atoms.
- `RunKind`: required enum: `Test` or `Real`.

No other owner-facing school modes are allowed.

Forbidden owner-facing modes:

- diagnostic_100
- runtime_1000
- full_30k_lab
- validate_only
- large_n_mode
- special_1000_mode
- REAL_DELTA_STAGE1
- any per-number launch path

Those names may exist only as historical proof labels, internal validators, or archived references. They must not be presented as the school interface.

## Internal scheduler law

The school internally schedules work like this:

```text
TargetAccepted = N
ChunkSize = 5000
BatchSize = 100
```

Examples:

```text
N=30000  -> 6 chunks of 5000 -> 300 batches of 100
N=300000 -> 60 chunks of 5000 -> 3000 batches of 100
```

If `N` is not divisible by 5000 or 100, the last chunk/batch may be smaller. This does not create a new mode.

`N` is a parameter, not architecture.

There must be no separate school for 100, 1000, 5000, 30000, 300000, or any other number.

## Test vs Real

### Test

`RunKind=Test` means lab/sandbox execution.

Allowed:

- use existing school/acceptance mechanics
- use runtime delta / sandbox / temp stores
- generate diagnostic proof
- run validators
- expose exact gap where accepted atoms fail to become active behavior

Not allowed:

- mutate live accepted-core surfaces
- claim live intelligence
- set `runtime_ready=true`
- bulk-write accepted atoms into repo-controlled monolithic JSON surfaces

### Real

`RunKind=Real` means real accepted-atom absorption.

Required before Real is permitted:

- canonical accepted atom retention/storage path exists
- compact/durable store manifest/index validators pass in current environment
- active retrieval index exists
- decision reuse proof passes on clean/known working tree
- behavior delta proof exists
- rollback/checkpoint contract exists
- Owner explicitly authorizes Real run

Until those gates pass, Real must block safely and explain the missing gates.

## Canonical route

The canonical internal route is:

```text
Owner command
-> run_agent_school.ps1
-> scheduler: chunks 5000 / batches 100
-> existing school / curriculum / useful ladder mechanics
-> Phase162 / Phase165 acceptance where applicable
-> accepted atom retention / compact durable storage
-> retrieval
-> decision reuse
-> behavior delta proof
```

Current status of route components:

```text
Owner entrypoint: PROVEN_LAB_WRAPPER`r`nSchool mechanics: PROVEN_LAB
Batch 100: PROVEN_LAB
Runtime 1000: PROVEN_LAB
30K full process: PROVEN_LAB_MECHANICS
RuntimeDeltaOnly bloat control: PROVEN_LAB
Durable compact storage: PROVEN_LAB_FIXTURE
Decision reuse: PROVEN_LAB_AFTER_SIDE_CLEANUP
Real active absorption: NOT_PROVEN
runtime_ready=false
```

Fresh diagnostic evidence:

```text
operations/reports/EXISTING_SCHOOL_ABSORPTION_VALIDATOR_REFRESH_V3.json
PASS: batch_100, runtime_1000, memory_delta_isolation, 30k_stress, 30k_full_process
REPAIRED: durable_retrieval_100, compact_bridge, small_durable_store, reuse_decision
```

## Deduplication rule

Cleanup must converge to this owner-facing truth:

```text
There is one school launch command.
Owner gives N and Test/Real.
Everything else is internal, supporting, archived, quarantined, or superseded.
```

Existing runners and validators must be classified before deletion:

- KEEP_CANONICAL
- KEEP_INTERNAL_SUPPORT
- ARCHIVE_REFERENCE
- QUARANTINE_SIDE_PROBE
- SUPERSEDED_DO_NOT_RUN
- DELETE_CANDIDATE

REAL_DELTA_SCHOOL_ORGAN_V1_STAGE1 and related dry-run/resource-guard artifacts are not the canonical school unless Owner explicitly promotes them.

## Next implementation sequence

1. Clean/classify duplicate school routes without deleting evidence blindly.
2. Choose or regenerate canonical compact durable retention/storage path.
3. Make `operations/school/run_agent_school.ps1` as the only owner-facing entrypoint.
4. Wire it to existing proven mechanics through the 5000/100 scheduler.
5. Make `RunKind=Test` work first.
6. Keep `RunKind=Real` blocked until retention/storage/reuse/behavior gates pass.
7. Only then run an owner-selected `TargetAccepted` test, such as 100.

## Non-goals

This contract does not build a new school.
This contract does not prove Real absorption.
This contract does not make runtime ready.
This contract does not delete old files.
This contract defines the single owner-facing route that cleanup and implementation must converge toward.
## 2026-07-02 Digest-first absorption correction

The old phrase `accepted atom absorption` was too weak and is superseded.

Canonical vocabulary now is:

```text
RAW_CANDIDATE       = untrusted material
READY/STAGED_ATOM   = validator accepted shape, not intelligence
DIGESTED_KNOWLEDGE  = compact semantic memory cell usable after raw source deletion
ABSORBED            = DIGESTED_KNOWLEDGE only
```

A Real run must not mutate active route or claim intelligence by appending raw ready atoms.

Real absorption is permitted only after all gates pass:

```text
compact semantic digest organ exists
raw candidate -> semantic cell transform passes
lookup/use proof passes
raw source dependency is removed
repo growth budget is bounded
staging/proof bulk is disposable
```

Until then:

```text
RunKind=Test -> staging/probe only, no intelligence claim
RunKind=Real -> BLOCKED_DIGESTION_ORGAN_REQUIRED_V1
```

Old ready-lane route absorption is deprecated. It may not be used as proof that the agent became smarter.
## COMPACT_SEMANTIC_DIGESTION_ORGAN_V1

This is the production-shaped organ that turns staged material into compact semantic memory.

Required behavior:

```text
input raw/staged candidates
-> canonical semantic cells
-> merge duplicate concepts
-> build lookup index
-> remove raw source dependency
-> enforce size budget
-> prove route/ledger are not mutated by staging
```

The first validator may run on a small batch, but the organ contract is not a toy. It is the canonical gate before any future `RunKind=Real` can claim absorption.

Canonical scripts:

```text
operations/school/digestion/invoke_compact_semantic_digestion_organ_v1.ps1
operations/school/digestion/validate_compact_semantic_digestion_organ_v1.ps1
```
## Digest validation budget

The digest organ must not run expensive proof loops after every tiny step.

Validation tiers:

```text
Fast   = per digest guard: parse/status/raw-deleted/size/route unchanged/lookup smoke
Stable = periodic guard: Fast + dedup sample + broader lookup
Full   = promotion guard: Stable + negative/full scan style checks
```

Default runtime posture:

```text
every digest -> Fast
periodic threshold -> Stable
before Real promotion / large batch / owner-selected promotion -> Full
```

This preserves safety without making the agent slow by forcing full validation on every atom.
## FILE_ATOM_ABSORPTION_PIPELINE_V1

The production file absorption route is now:

```text
atom file
-> runtime staging copy
-> JSONL/intake validation
-> compact semantic digestion organ
-> compact memory + lookup index
-> staging raw deleted
-> original raw deleted only if it is runtime-owned and explicitly requested
-> route/ledger unchanged
```

`RunKind=Real` is wired to this pipeline. Real no longer means route append. Real means compact semantic digestion with raw-source dependency removed.