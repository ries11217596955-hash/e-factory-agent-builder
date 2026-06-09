# GITHUB ACTION EXECUTION SURFACE CONTRACT v1

## Purpose

The Builder already self-builds, builds external agents, and synthesizes next serial programs.
But it still behaves as a terminal-first product.

SP-N14 establishes the next operational standard:
1. The Builder itself must be manually launchable from GitHub Actions.
2. Every generated external agent package must include a GitHub Actions launch delivery artifact.
3. Validators must treat the Action surface as part of operational completeness.

# PHASE 51 — Builder GitHub Action Manual Run Surface v1
Gate:
BUILDER_GITHUB_ACTION_MANUAL_RUN_SURFACE_V1_READY = PASS

# PHASE 52 — Generated Agent Action Launch Contract v1
Gate:
GENERATED_AGENT_ACTION_LAUNCH_CONTRACT_V1_READY = PASS

# PHASE 53 — Action-Ready Generated Agent Proof v1
Gate:
ACTION_READY_GENERATED_AGENT_PROOF_V1 = PASS
