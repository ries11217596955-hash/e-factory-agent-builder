# Runbook Executor Agent v1

Runbook Executor Agent v1 turns a runbook and a concrete task or incident into an operator-facing execution plan. It is a standalone external operator agent package and does not depend on Agent Builder internals at runtime.

## Inputs

The agent reads a JSON object with these required fields:

- `runbook_title`
- `runbook_steps`
- `task_or_incident`
- `environment`
- `constraints`

`runbook_steps` is an ordered list of instructions. `constraints` is a list of operational boundaries that should be surfaced as risks.

## Outputs

The agent writes a structured JSON object containing:

- `execution_checklist`
- `risk_flags`
- `required_evidence`
- `next_operator_action`
- `validation_status`

`validation_status` is `PASS` only after the input has been parsed, required fields have been checked, and output has been written.

## Run

From this folder:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\run.ps1 -InputPath .\INPUT_EXAMPLE.json -OutputPath .\OUTPUT_EXAMPLE_RUNTIME.json
```

The script uses only local PowerShell and JSON processing. It does not call external APIs.
