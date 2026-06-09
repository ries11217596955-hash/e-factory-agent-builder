# Runbook Executor Agent v1 Runbook

## When To Use

Use this agent when an operator has a runbook or procedure and needs a concrete execution checklist for a specific task, incident, or environment.

## Input

Prepare a JSON file with:

- `runbook_title`: short title of the runbook or instruction.
- `runbook_steps`: ordered list of runbook steps.
- `task_or_incident`: the concrete task or incident to apply the runbook to.
- `environment`: environment, system, repository, workflow, or service involved.
- `constraints`: operational boundaries, cautions, or restrictions.

## Run

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\run.ps1 -InputPath .\INPUT_EXAMPLE.json -OutputPath .\OUTPUT_EXAMPLE_RUNTIME.json
```

On success, the script prints:

```text
RUNBOOK_EXECUTOR_AGENT_STATUS=PASS
```

## Read The Result

Review:

- `execution_checklist` for the concrete action sequence.
- `risk_flags` for constraints and likely operational hazards.
- `required_evidence` for proof the operator should collect.
- `next_operator_action` for the immediate next step.

## Limits

The agent does not execute the runbook, call external services, change infrastructure, or create tickets. It structures the operator plan from supplied JSON only.
