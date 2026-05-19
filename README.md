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

Agent Builder has already proven the baseline readiness gates recorded in repo truth:

- `SELF_BUILD_READY = PASS`
- `EXTERNAL_AGENT_BUILD_READY = PASS`
- `FIRST_EXTERNAL_AGENT_PROOF = PASS`
- GitHub Actions self-build surface exists.
- Generated external agents carry a GitHub Actions launch delivery artifact.

Current verification contour:

- `PHASE_54`
- `owner_visible_self_build_acceptance_v1`
- active task: `TASK_OWNER_VISIBLE_SELF_BUILD_ACCEPTANCE_V1_001`

This contour accepts the owner-visible loop next: first run Self-Build from the GitHub Action to consume the PHASE54 pack, then run Build From Raw Idea from GitHub Actions to generate a real external agent package from the canonical raw idea fixture.

## Source of truth

- `AGENT_MISSION.md`
- `GENESIS_MASTER_PLAN.md`
- `CAPABILITY_ROADMAP.json`
- `GENESIS_STATE.json`
- `TASK_QUEUE.json`

## Absolute rule

The agent must not transition into external-agent generation unless:

`SELF_BUILD_READY = PASS`

That gate is currently true in `GENESIS_STATE.json`; runtime proof artifacts remain the source of truth for each later acceptance claim.
