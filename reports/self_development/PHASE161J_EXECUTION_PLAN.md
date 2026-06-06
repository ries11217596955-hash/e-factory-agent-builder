# PHASE161J Execution Plan

## Current Recommendation Defect

The current memory report selects `GAP_PROTECTED_STATE_PROMOTION_BLOCKED` and recommends reviewing a protected-state candidate. That recommendation is stale: PHASE161F created the candidate, PHASE161G1 reviewed it, and PHASE161G2 applied the two approved bounded references. The remaining TASK_QUEUE, packs registry, and orchestrator scopes are explicitly delayed or rejected, not the current top action.

## Completed Recommendation Detection

The selector will use accepted proof/result files rather than phase-name inference alone:

- PHASE161F manifest/proof means the candidate exists.
- PHASE161G1 compatibility proof and delayed-scope file mean review is complete and blocked scopes are explicit.
- PHASE161G2 apply result/proof means the approved GENESIS_STATE and CAPABILITY_ROADMAP references were applied.

These markers block the old generic protected-promotion recommendation. TASK_QUEUE remains delayed, packs registry remains delayed, and orchestrator remains rejected.

## Priority Logic

Candidates are classified by the required ordered priority taxonomy. Within a class, deterministic scoring uses:

- active-route impact;
- safety impact;
- evidence/live-proof gap;
- owner-approval dependency;
- historical-only penalty.

Deletion and broad connection work receive low priority unless a current safety or route failure proves them necessary. The expected current selection is a bounded active-route exhaustion and live-evidence reconciliation because the active PHASE161 route lock still requires exhaustion evidence before any route change.

## Organism Health Logic

Health is derived from current route coherence, protected-state cleanliness, self-knowledge readiness, evidence honesty, active-path parser/stub findings, and route-relevant blockers:

- `CRITICAL`: protected conflict, route drift, active corruption, active parser failure, runtime staging, or false live claim.
- `BLOCKED`: a required current-route organ or owner decision prevents progress.
- `DEGRADED`: the route works but lacks important required live/consumer proof.
- `WATCH`: no blocker, but route-relevant governance or evidence debt remains.
- `HEALTHY`: no critical/blocking/active-path issues and only optional or historical work remains.

Historical artifacts alone do not lower health.

## Refresh Integration

PHASE161J extends the existing PHASE161E refresh sequence after body-map generation:

1. inspect organism health;
2. select the next action;
3. enrich `SELF_MODEL_ACTIVE_MAP.json`;
4. write the memory report using the selector and health outputs.

The PHASE161I GitHub push workflow remains the remote trigger. Its explicit refresh allowlist must be extended for the two new generated outputs; otherwise the accepted remote refresh would correctly reject them as unexpected.

## Memory Report

The report will show:

- organism health and score;
- one recommended next macro-step;
- why it wins;
- why deletion, connecting everything, and repairing all stubs do not win;
- completed recommendations that were suppressed;
- delayed/blocked scopes and optional improvements.

## Files To Change

- Add selector, health inspector, selector contract validator, and selector report writer modules.
- Add PHASE161J policy and validator.
- Extend PHASE161E refresh and memory writer.
- Extend PHASE161I workflow allowlist for generated selector/health outputs.
- Regenerate only the PHASE161J recommendation, health, active-map, memory, and required phase proof/report artifacts during local validation.

## What Will Not Be Modified

No protected state, queue, registry, orchestrator, route lock, package, runtime session, historical artifact, or external agent will be modified or deleted. PHASE161J will not apply delayed candidates or silently change the active route.
