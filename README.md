# E-Factory Agent Builder

## Purpose

Canonical repository for the Agent Builder line.

This system has two sequential functions:

1. **SELF_BUILD**  
   Build itself from a repo-defined genesis plan through validated staged capability packs.

2. **BUILD_EXTERNAL_AGENT**  
   After self-build readiness is proven, construct other agents from formal specifications.

## Product boundary

This repository is not an extension of Site Auditor V3.  
It is a separate AGENTOPS product line that reuses proven architectural discipline:

- orchestrator-first;
- contract-first;
- module-owned logic;
- validator-gated releases;
- artifact truth;
- serial execution packs.

## Current stage

Genesis stage: `PHASE_0 — Repository Genesis`

Current active task:
- `TASK_REPO_GENESIS_001`

## Source of truth

- `AGENT_MISSION.md`
- `GENESIS_MASTER_PLAN.md`
- `CAPABILITY_ROADMAP.json`
- `GENESIS_STATE.json`
- `TASK_QUEUE.json`

## Absolute rule

The agent must not transition into building external agents until:

`SELF_BUILD_READY = PASS`
