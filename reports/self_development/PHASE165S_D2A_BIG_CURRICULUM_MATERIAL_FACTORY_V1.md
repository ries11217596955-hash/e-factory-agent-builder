# PHASE165S-D2A Big Curriculum Material Factory

Status: PASS

## Boundary

This bank is raw staged curriculum material. It is not accepted memory, trusted knowledge, or an accepted atom set.

Codex generated material only. Builder must consume selected shards through school, the C2B guard, and the existing PHASE162 acceptance path before any atom can become accepted.

## Result

- Candidates: 50000
- Shards: 100
- Shard size: 500
- Safe candidates: 49800
- Quarantine-review candidates: 200
- Duplicate dedupe keys: 0
- Accepted atom ID collisions: 0
- Protected or accepted state dirty: False

## Generate

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File modules/generate_phase165s_d2a_big_curriculum_material_factory_001.ps1 -TargetCount 50000 -ShardSize 500
```

## Validate

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File validators/validate_phase165s_d2a_big_curriculum_material_factory_v1.ps1
```

## D2B Consumption

D2B should read the manifest, select bounded shard slices, preserve `trusted=false` and `accepted=false`, quarantine HIGH-risk records for review, deduplicate again at intake, and send only bounded candidates through school/C2B/PHASE162. It must not bulk-promote the bank or treat JSONL presence as learning.

## Next Required Action

PHASE165S_D2B_BIG_CURRICULUM_SCHOOL_WAVE_DRY_RUN_OR_AUTONOMOUS_RUN
