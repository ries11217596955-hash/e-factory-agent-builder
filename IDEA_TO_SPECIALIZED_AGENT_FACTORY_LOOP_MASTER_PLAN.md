# IDEA-TO-SPECIALIZED-AGENT FACTORY LOOP v1

## Purpose

Upgrade Agent Builder from:

raw idea
→ production spec
→ operational baseline agent

to:

raw idea
→ production spec
→ specialization resolver
→ repo-defined specialization overlay
→ operational specialized agent.

---

# PHASE 21 — Specialization Overlay Resolution v1

## Goal
Create a reusable resolver that maps derived production-agent identity into a bounded repo-defined specialization profile.

Proof profile:
- `audit_agent` → `audit_agent_v1`

The overlay must make the target generated agent behavior observably non-baseline.

## Gate
`SPECIALIZATION_OVERLAY_RESOLUTION_V1_READY = PASS`

---

# PHASE 22 — BUILD_FROM_RAW_IDEA_SPECIALIZED Mode v1

## Goal
Expose direct factory mode:

`orchestrator/run.ps1 -Mode BUILD_FROM_RAW_IDEA_SPECIALIZED`

This mode must:
- consume raw idea;
- invoke Agent Spec Architect handoff;
- resolve a specialization overlay from derived spec;
- build the target agent with that overlay;
- emit a structured specialized-build report.

## Gate
`BUILD_FROM_RAW_IDEA_SPECIALIZED_MODE_V1_READY = PASS`

---

# PHASE 23 — Idea-to-Specialized-Agent Factory Proof v1

## Goal
Prove end-to-end that:
- one raw idea;
- becomes one derived spec;
- receives one matched specialization overlay;
- becomes one operational specialized agent;
- emits specialized runtime behavior, not baseline behavior.

## Gate
`IDEA_TO_SPECIALIZED_AGENT_FACTORY_PROOF_V1 = PASS`
