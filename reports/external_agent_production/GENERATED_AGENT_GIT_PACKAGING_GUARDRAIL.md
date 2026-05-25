# Generated Agent Git Packaging Guardrail

## Status

ACTIVE.

## What happened

During PHASE73, Builder produced the second external agent:

generated_agents/runbook_executor_agent_v1/

The agent runtime validation passed, but the pack failed during git add because .gitignore blocked generated_agents/<agent_id>/ folders.

## Root cause

The previous .gitignore rule ignored generated agent folders:

generated_agents/*

That rule was useful when generated outputs were disposable, but it is wrong now because generated agents are product outputs of Builder.

## Fix

The ignore rule for generated_agents/* was removed.

Generated agents must be committed as product artifacts when Builder produces them.

## Why this matters

Future agents should not require manual recovery with:

git add -f generated_agents/<agent_id>

Builder must be able to produce an agent, validate it, commit it, and push it without manual git recovery.

## Rule

Do not ignore:

generated_agents/<agent_id>/

Generated agents are accepted product outputs, not temporary runtime junk.
