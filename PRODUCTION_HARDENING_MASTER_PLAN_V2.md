# PRODUCTION HARDENING MASTER PLAN v2

## Purpose

This plan corrects an over-claimed production status and upgrades Agent Builder from:

`production-style proof conveyor`

to:

`operational baseline agent factory`

## Honesty rule

A production-ready factory claim is invalid if generated agents still contain:
- RUN_NOT_IMPLEMENTED execution paths;
- decorative validators that always print PASS;
- no real input → processing → output execution;
- no operational package validation harness.

---

# PHASE 13 — Production Truth Reset v2

## Goal
Correct over-claimed production readiness and explicitly record the detected weaknesses.

## Gate
`PRODUCTION_TRUTH_RESET_V2_READY = PASS`

---

# PHASE 14 — Real Generated Agent Runtime v2

## Goal
Generated agents must contain a real baseline runtime:
- request/result contracts;
- operational RUN mode;
- real module invocation;
- structured output file;
- non-decorative internal package validator.

## Gate
`REAL_GENERATED_AGENT_RUNTIME_V2_READY = PASS`

---

# PHASE 15 — Operational Validation Harness v2

## Goal
The factory must operationally validate generated agents by:
- checking required files;
- running the generated package validator;
- running generated orchestrator RUN mode;
- parsing and verifying produced output.

## Gate
`OPERATIONAL_VALIDATION_HARNESS_V2_READY = PASS`

---

# PHASE 16 — BUILD_EXTERNAL_AGENT Mode v2

## Goal
The direct build mode must:
- validate the production spec;
- generate the agent package;
- run the operational harness;
- emit a structured build report.

## Gate
`FACTORY_BUILD_EXTERNAL_AGENT_MODE_V2_READY = PASS`

---

# PHASE 17 — Operational Factory Proof v2

## Goal
Prove the upgraded factory end to end on a fresh operational proof agent.

## Gate
`OPERATIONAL_FACTORY_PROOF_V2 = PASS`
