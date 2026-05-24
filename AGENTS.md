# AGENTS.md — e-factory-agent-builder

## Purpose

Execution discipline for work inside `e-factory-agent-builder`.

This file is for Codex, ChatGPT, CodeSpace, terminal operators, and future agents working in this repository.

It protects the repo from drift, wrong-repo execution, unsafe cleanup, shell confusion, and fake success claims.

## Product target

Build a self-constructing Agent Builder that:

1. first builds its own verified operating contour;
2. then builds other agents from formal specs.

This repo is not the website repo.
This repo is not the universal Site Auditor repo.
This repo is not the Video Agent runtime repo.

## Active lines

Do not hide different work under vague `Agent Builder` wording.

Use one of these lines:

- `AGENT_BUILDER_SELF_DEVELOPMENT`
- `AGENT_BUILDER_EXTERNAL_AGENT_PRODUCTION`
- `AGENT_BUILDER_REPO_CLEANUP`

### AGENT_BUILDER_SELF_DEVELOPMENT

Builder improves or repairs its own execution contour.

Use only when the bottleneck is internal Builder capability, queue handling, state handling, pack execution, proof generation, validator integration, or honest failure reporting.

### AGENT_BUILDER_EXTERNAL_AGENT_PRODUCTION

Builder produces external agents as inspectable assets.

Use only when the bottleneck is external-agent specification, package generation, validation, proof pack, generated-agent handoff, or reusable production pattern.

### AGENT_BUILDER_REPO_CLEANUP

Repo hygiene only.

Use when the task is to remove proven junk, update operator/Codex/CodeSpace instructions, or clean stale support files.

Cleanup is not self-development and not external-agent production.

## Active modes

- `SELF_BUILD`
- `BUILD_EXTERNAL_AGENT`
- `VERIFY`

Do not introduce a new mode during cleanup work.

## Repo identity gate

Before any serious launch, patch, cleanup, validation, or proof collection, verify the working folder contains:

- `CAPABILITY_ROADMAP.json`
- `GENESIS_STATE.json`
- `TASK_QUEUE.json`
- `packs/registry.json`
- `orchestrator/run.ps1`

If any are missing, stop with:

```text
STOP=WRONG_AGENT_BUILDER_REPO
```

Wrong repo is an operator boundary failure, not a runtime bug.

## Architecture law

- orchestrator owns flow only;
- modules own logic;
- contracts define accepted data;
- validators define PASS / FAIL;
- state files must not claim completion without validation evidence;
- chat is not source of truth;
- repo-defined plan is source of truth.

## Serial execution law

Do not drip-feed routine micro-steps.

When task scope is defined in repo truth:

1. read the plan;
2. read current state;
3. execute the next bounded tranche;
4. validate;
5. update state and queue only after evidence;
6. continue until hard stop.

## Terminal discipline

Before giving or running commands, identify the shell:

- PowerShell;
- Bash / Git Bash;
- CodeSpace Linux shell.

Do not mix Bash syntax with PowerShell.

PowerShell owner-facing blocks should prefer soft STOP markers:

```powershell
$Continue = $true
if (-not (Test-Path "CAPABILITY_ROADMAP.json")) {
  Write-Host "STOP=WRONG_AGENT_BUILDER_REPO"
  $Continue = $false
}
```

Avoid `exit` / `exit 1` in long owner-facing PowerShell blocks when a soft STOP is safer.

Bash blocks must not be given for PowerShell contexts unless explicitly marked as Git Bash / Bash.

## Codex discipline

Codex is for bounded patches after the scope is known.

Codex tasks must include:

- READ FIRST;
- OBJECTIVE;
- HUMAN MEANING;
- FILES ALLOWED;
- FORBIDDEN;
- VALIDATION;
- EXPECTED REPORT.

Every Codex task must include a terminal proof pack in the same response.

Do not accept:

```text
Proof pack will be provided later.
```

## Cleanup discipline

Cleanup is not refactor.
Cleanup is not product development.
Cleanup is not a reason to rewrite runtime.

Delete only proven junk:

- temporary local audit folders;
- local ZIPs;
- `.tmp`, `.bak`, `.old`, `.orig` files;
- OS/editor artifacts;
- scratch files with no registry, task, proof, report, workflow, or runtime reference.

Do not delete, move, rename, quarantine, or rewrite these during cleanup unless an explicit evidence-backed cleanup task proves they are obsolete:

- `CAPABILITY_ROADMAP.json`
- `GENESIS_STATE.json`
- `TASK_QUEUE.json`
- `packs/registry.json`
- `orchestrator/run.ps1`
- `packs/`
- `tasks/`
- `proofs/`
- `reports/`
- `runs/`
- `generated_agents/`
- `self_build_programs/`
- `applied_agents/`
- `contracts/`
- `modules/`
- `validators/`
- `.github/workflows/`

These paths are not junk by default.

## Hard stops

STOP if:

- required repo identity files are missing;
- plan does not define the next step;
- validator fails and root cause is unclear;
- a task would cross declared scope;
- self-development and external-agent production are mixed without explicit scope;
- external-agent-build is attempted before self-build readiness;
- state, roadmap, and queue contradict each other;
- cleanup would touch protected state/proof/runtime/generated paths without evidence.

## Proof discipline

Do not claim completion without matching evidence.

Use explicit states:

- PREPARED, NOT RUN
- CODEX CLAIMED, PROOF REQUIRED
- LOCAL PASS
- HOSTED PENDING
- HOSTED PASS
- CLEANUP ONLY
- RUNTIME PASS
- BLOCKED
- STOP

Proof examples:

- file claim -> diff, file read, or GitHub fetch;
- runtime claim -> terminal output, validator output, proof artifact;
- hosted claim -> workflow logs or hosted artifact;
- cleanup claim -> git status, diff, and exact deleted/changed file list.

## Forbidden drift

- no giant prompt as SSOT;
- no chaotic self-modification;
- no external agent generation before `SELF_BUILD_READY = PASS`;
- no fake PASS without validator evidence;
- no collapsing this repo back into Site Auditor;
- no broad refactor under cleanup wording;
- no deleting proof/state/queue/runtime/generated assets by filename guess;
- no Bash commands pasted as PowerShell;
- no local success claim when remote/main was not verified.
