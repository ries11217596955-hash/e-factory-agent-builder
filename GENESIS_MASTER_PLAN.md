# GENESIS MASTER PLAN

## Purpose

This file defines the approved construction route for E-Factory Agent Builder.

The agent must follow this plan during `SELF_BUILD`.

A self-build PASS is valid only after the system proves real build orchestration:
- it can read its own declared task;
- compile a bounded implementation brief for an execution backend;
- accept backend result evidence;
- validate the result;
- transition state only after validator proof.

A local serial pack written by the operator is bootstrap engineering, not self-building.

---

# PHASE 0 — Repository Genesis
## Goal
Create the canonical repository skeleton and genesis truth files.
## Gate
`REPO_GENESIS_READY = PASS`

---

# PHASE 1 — Self-Build Control Core
## Goal
Enable the agent to read and understand its own construction state.
## Gate
`SELF_BUILD_CONTROL_CORE_READY = PASS`

---

# PHASE 2 — Self-Build Execution Substrate
## Goal
Create the internal execution substrate that can:
- load approved task specs;
- dispatch controlled proof execution;
- run validators;
- emit run artifacts;
- update state/queue under validator control.

## Boundary
This phase proves execution plumbing, not autonomous/self-directed code construction.

## Gate
`SELF_BUILD_EXECUTION_SUBSTRATE_READY = PASS`

---

# PHASE 3 — Real Self-Build Backend Bridge
## Goal
Enable the agent to prepare and control a real self-build implementation move through an execution backend.

## Required capabilities
- read active self-build task spec;
- compile a bounded implementation brief from repo truth;
- emit backend handoff artifacts;
- define allowed files, forbidden scope, and required proof;
- ingest backend result evidence;
- refuse PASS if backend evidence is missing.

## Gate
`REAL_SELF_BUILD_BACKEND_BRIDGE_READY = PASS`

---

# PHASE 4 — Self-Validation and Release Gates
## Goal
Prove that self-build truth does not drift after real backend-bridge self-build proof exists.

## Gate
`SELF_BUILD_READY = PASS`

---

# PHASE 5 — External Agent Spec Intake
## Gate
`EXTERNAL_AGENT_SPEC_INTAKE_READY = PASS`

---

# PHASE 6 — External Agent Package Generator
## Gate
`EXTERNAL_AGENT_PACKAGE_GENERATOR_READY = PASS`

---

# PHASE 7 — First Proven External Agent
## Gate
`FIRST_EXTERNAL_AGENT_PROOF = PASS`

---

# GLOBAL STOP RULE

The agent must STOP if:
- the next build tranche is not declared;
- a validator fails and bounded repair is not evident;
- state files contradict each other;
- execution attempts to cross into a future phase before its gate is passed;
- self-build is claimed without backend-bridge evidence.
