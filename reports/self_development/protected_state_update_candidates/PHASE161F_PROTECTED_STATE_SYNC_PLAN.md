# PHASE161F Protected State Sync Plan

This package proposes synchronization references only. It does not modify protected source-of-truth files.

## Proposed Synchronization

- `GENESIS_STATE.json`: add a bounded `protected_self_model_memory` reference to accepted PHASE161E readiness and evidence paths.
- `CAPABILITY_ROADMAP.json`: add a PHASE161E accepted evidence reference without changing existing completion claims.
- `TASK_QUEUE.json`: add a non-active owner review task without changing `active_task_id`.
- `packs/registry.json`: no change recommended because no pack was created.
- `orchestrator/run.ps1`: no change recommended without a separately proven acceptance workflow hook.

## Do Not Synchronize

- Full `agent_body_map.json` payloads.
- Validator-only evidence as live evidence.
- Historical or superseded artifacts as active organs.
- Current phase, current task, readiness, route, pack, or orchestrator behavior changes.

## Later Approved Validation

Verify exact pre-apply hashes, apply one target at a time, parse JSON, run target consumers and validators, confirm route/task invariants, run PHASE161E refresh, and compare post-apply map evidence.

## Why Candidate Only

Protected state owns execution truth. Promotion requires explicit owner approval and a separate apply phase with rollback evidence.
