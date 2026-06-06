# PHASE161G2 Execution Plan

## Allowed Protected Changes

Exactly two bounded top-level references are approved:

1. Add `protected_self_model_memory` from the accepted candidate to `GENESIS_STATE.json`.
2. Add `phase161e_self_map_auto_refresh` from the accepted candidate to `CAPABILITY_ROADMAP.json`.

No existing field or roadmap entry may be rewritten.

## Explicitly Blocked

- `TASK_QUEUE.json`
- `packs/registry.json`
- `orchestrator/run.ps1`
- all route locks
- `current_phase`
- `current_capability`
- `active_task_id`
- pack admission
- orchestrator flow
- validator-only-to-live promotion
- full body-map copy

## Pre-Hash Verification

The apply is allowed only when all five owner-provided SHA-256 values match:

- `GENESIS_STATE.json`: `2E42C007217F0B3ABAE6AB0817D1D6607175FBD3F30E3169884773EF17F6D20F`
- `CAPABILITY_ROADMAP.json`: `CAF5552F5630E8D9783213CDCDAEFBF55491181DD41CB778965720DA5BDCA1CA`
- `TASK_QUEUE.json`: `27220D7E169EDA9E60341B4A7A2817D3515DE8C8BB11DFC7C841A941FC01C4EC`
- `packs/registry.json`: `C3BBD8313FA46CA80298154964DC82431DB60525C485207C40D8059F8F88F760`
- `orchestrator/run.ps1`: `51AA1CBEB0339B2DF0CBA84606E414D9DFA7395DED7179CC5248B3C4BC5CC91D`

## Apply Order

1. Create byte-for-byte rollback snapshots for GENESIS_STATE and CAPABILITY_ROADMAP.
2. Record blocked-file and route-lock hashes.
3. Add the bounded GENESIS_STATE reference and validate.
4. Add the bounded CAPABILITY_ROADMAP reference and validate.
5. Verify blocked hashes, route locks, `current_phase`, `current_capability`, and `active_task_id`.
6. Run the PHASE161G2 validator.

## JSON Compatibility

Both protected JSON files must parse after apply. Existing top-level fields are compared with pre-apply snapshots. Candidate evidence boundaries and cautious statuses must remain unchanged.

## Rollback

On any apply or validation failure, restore exact snapshot bytes for both approved targets, verify the original hashes, and stop. No blocked file requires rollback because it must never be written.

## Post-G2 Self-Map Refresh

After G2 validation, commit, push, and remote verification, run the existing PHASE161E refresh against the G2 commit hash with:

- phase `PHASE161G2_APPLY_LIMITED_PROTECTED_SELF_MODEL_REFERENCES`
- trigger `refresh_self_map_after_g2_limited_protected_apply`

The refresh must not create further protected diffs.

## Two-Commit Strategy

- Commit 1: limited protected references and G2 evidence.
- Commit 2: refreshed PHASE161E2 map memory and final combined delivery.

Each commit is pushed and verified before continuing.

## Not Changed

No queue, registry, orchestrator, route-lock, runtime, deletion, dependency, external-agent, or unrelated source change is included.
