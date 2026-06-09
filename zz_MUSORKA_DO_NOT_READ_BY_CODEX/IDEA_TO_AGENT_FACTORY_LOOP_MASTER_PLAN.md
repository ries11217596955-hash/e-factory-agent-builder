# IDEA-TO-AGENT FACTORY LOOP v1

## Purpose

Upgrade Agent Builder from:

production spec → external agent package

to:

raw operator idea
→ Agent Spec Architect
→ production external agent spec
→ Agent Builder
→ generated external agent package.

---

# PHASE 18 — Architect → Spec Handoff v1

## Goal
Create a reusable execution module that:
- builds Agent Spec Architect through the existing factory;
- runs it on a raw idea request;
- extracts `production_spec_draft`;
- validates the draft as a production external-agent spec;
- writes the derived spec artifact.

## Gate
`ARCHITECT_TO_SPEC_HANDOFF_V1_READY = PASS`

---

# PHASE 19 — BUILD_FROM_RAW_IDEA Mode v1

## Goal
Expose direct factory mode:

`orchestrator/run.ps1 -Mode BUILD_FROM_RAW_IDEA`

This mode must:
- consume a raw idea request;
- invoke the Agent Spec Architect handoff;
- build the derived target agent through `BUILD_EXTERNAL_AGENT` internals;
- emit a structured report.

## Gate
`BUILD_FROM_RAW_IDEA_MODE_V1_READY = PASS`

---

# PHASE 20 — First Idea-to-Agent Factory Proof v1

## Goal
Prove end-to-end that one raw idea can become one generated operational agent without manual spec authoring.

## Gate
`IDEA_TO_AGENT_FACTORY_PROOF_V1 = PASS`
