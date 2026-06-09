# GENESIS MASTER PLAN

## Purpose

This file defines the approved construction route for E-Factory Agent Builder.

The agent must follow this plan during `SELF_BUILD`.

A self-build PASS is valid when the agent itself:
- reads the active task from repo truth;
- selects a repo-defined execution pack from the pack registry;
- launches that pack through the local PowerShell/Bash execution layer;
- validates the pack result;
- advances state only after proof.

The standing model is:

`repo truth → pack registry → local pack executor → validators → state transition`

---

# PHASE 0 — Repository Genesis
## Gate
`REPO_GENESIS_READY = PASS`

---

# PHASE 1 — Self-Build Control Core
## Gate
`SELF_BUILD_CONTROL_CORE_READY = PASS`

---

# PHASE 2 — Self-Build Execution Substrate
## Gate
`SELF_BUILD_EXECUTION_SUBSTRATE_READY = PASS`

---

# PHASE 3 — Serial Self-Build Pack Executor

## Goal
Enable the agent to self-execute repo-defined build packs through the local terminal layer.

## Required capabilities
- read the active queue task;
- read a pack registry;
- select the pack bound to the active task;
- execute the pack through PowerShell/Bash;
- emit orchestrator proof;
- stop on pack failure;
- prove the model by self-running the next registered pack.

## Gate
`SERIAL_SELF_BUILD_PACK_EXECUTOR_READY = PASS`

---

# PHASE 4 — Self-Validation and Release Gates

## Goal
Prove that self-build truth does not drift after the pack executor has self-run a registered build pack.

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
- self-build is claimed without pack-executor proof.
