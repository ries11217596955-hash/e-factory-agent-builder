# PHASE165S-D2B-R1 Post-Execution Visibility Recovery

Status: PASS_RECOVERED_INCOMPLETE_RESUMABLE

D2B did not fail as a concept. One candidate reached the PHASE162 execution path, but the executor rolled back after a file-access failure and the candidate was visible in none of the three accepted surfaces.

## Failed Candidate

- Candidate: `PHASE165S_D2A_material_catalogue_provenance_source_ladder_content_hash_requirement_atom_reuse_next_cycle_reuse`
- Atom: `d2a.requirement_atom.material_catalogue_provenance_source_ladder.content_hash.reuse.next_cycle_reuse.v1`
- Visibility before recovery: memory `0`, self-map `0`, registry `0`
- Decision: quarantine as not accepted and advance the cursor

The failed candidate was not added to accepted memory, the active self-map, or the registry. Accepted count remains `627`.

## Recovery Boundary

A zero-surface post-execution visibility failure is recoverable. The runner now writes both failure and recovery evidence, records a dynamic quarantine, does not increment accepted count, and advances the cursor exactly once.

A partial accepted surface remains blocked. The runner reports `BLOCKED_PARTIAL_ACCEPTED_SURFACE`, and the validator reports `BLOCKED_PARTIAL_ACCEPTED_SURFACE_RECONCILIATION_REQUIRED` instead of resuming.

## Reconciled State

- Resume status: `RUNNING_READY_TO_RESUME`
- Processed: `693`
- Remaining: `49307`
- Accepted: `627`
- Quarantined: `66`
- Failed: `0`
- Recovered failures: `4`
- Dynamic quarantines: `1`
- Validator: `INCOMPLETE_RESUMABLE`

## Resume

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File modules/run_phase165s_d2b_big_curriculum_autonomous_learn_until_empty_001.ps1 -Resume
```

The run resumes at shard index `1`, line index `193`; it does not restart from zero or reprocess the quarantined candidate.
