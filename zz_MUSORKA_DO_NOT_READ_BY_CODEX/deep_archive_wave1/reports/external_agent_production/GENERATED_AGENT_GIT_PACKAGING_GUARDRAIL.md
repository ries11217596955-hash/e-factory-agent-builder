# Generated Agent Git Packaging Guardrail

## Status

ACTIVE.

## What happened

During PHASE73, Builder produced the second external agent:

generated_agents/runbook_executor_agent_v1/

The agent runtime validation passed, but the pack failed during git add because .gitignore blocked generated_agents/<agent_id>/.

## Corrected rule

generated_agents/ may contain both accepted product agents and old scratch/generated folders.

Therefore we do not open the whole folder.

We keep the broad ignore rule:

generated_agents/*

Then we explicitly allow accepted product agents:

generated_agents/remediation_intake_operator_agent_v1/
generated_agents/runbook_executor_agent_v1/

## Rule for future agents

Future Builder packs must not rely on the whole generated_agents folder being unignored.

When Builder produces a new accepted product agent, the pack must either:

1. add that exact agent folder with git add -f, or
2. update .gitignore with an explicit allow rule for that exact accepted agent folder.

Do not blindly unignore all generated_agents/*.

## Why this matters

This prevents old scratch/generated folders from polluting git status while still allowing accepted Builder-produced agents to be committed as product outputs.

The failure class is closed only when future packs handle the exact produced agent folder intentionally.
