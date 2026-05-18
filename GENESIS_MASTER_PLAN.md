# GENESIS MASTER PLAN

## Purpose

This file defines the approved construction route for E-Factory Agent Builder.

The agent must follow this plan during `SELF_BUILD`.

---

# PHASE 0 — Repository Genesis

## Goal
Create the canonical repository skeleton and genesis truth files.

## Required outputs
- README
- AGENTS
- mission
- master plan
- roadmap
- genesis state
- task queue
- contracts folder
- orchestrator folder
- modules folder
- validators folder
- specs template folder
- runs folder
- generated agents folder

## Gate
`REPO_GENESIS_READY = PASS`

---

# PHASE 1 — Self-Build Control Core

## Goal
Enable the agent to read and understand its own construction state.

## Required capabilities
- read genesis plan;
- read state;
- read queue;
- choose next capability;
- choose next task;
- emit decision object.

## Gate
`SELF_BUILD_CONTROL_CORE_READY = PASS`

---

# PHASE 2 — Self-Build Execution Loop

## Goal
Enable the agent to execute approved self-build tasks and move through the roadmap.

## Required capabilities
- execute build task;
- run validators;
- emit run report;
- update state;
- update task queue;
- continue serially when safe.

## Gate
`SELF_BUILD_EXECUTION_LOOP_READY = PASS`

---

# PHASE 3 — Self-Validation and Release Gates

## Goal
Prove that self-build truth does not drift.

## Required validation
- roadmap ↔ state alignment;
- state ↔ task queue alignment;
- PASS requires validator evidence;
- run report ↔ physical artifacts alignment;
- fail-runs produce diagnostic artifacts.

## Gate
`SELF_BUILD_READY = PASS`

---

# PHASE 4 — External Agent Spec Intake

## Goal
Accept and validate formal specifications for new agents.

## Required inputs
- mission;
- input contract;
- output contract;
- capability requirements;
- validation requirements;
- forbidden scope.

## Gate
`EXTERNAL_AGENT_SPEC_INTAKE_READY = PASS`

---

# PHASE 5 — External Agent Package Generator

## Goal
Generate a structured starter repository for a new agent.

## Required output
- README;
- AGENTS;
- mission;
- contracts;
- orchestrator;
- modules scaffold;
- validators scaffold;
- task report.

## Gate
`EXTERNAL_AGENT_PACKAGE_GENERATOR_READY = PASS`

---

# PHASE 6 — First Proven External Agent

## Goal
Prove the factory by building one real external agent.

## Selected first proof agent
`Spec-to-Template Agent`

## Gate
`FIRST_EXTERNAL_AGENT_PROOF = PASS`

---

# GLOBAL STOP RULE

The agent must STOP if:
- the next build tranche is not declared;
- a validator fails and bounded repair is not evident;
- state files contradict each other;
- execution attempts to cross into a future phase before its gate is passed.
