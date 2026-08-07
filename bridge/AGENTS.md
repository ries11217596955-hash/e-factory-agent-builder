# AGENTS.md — Local Bridge / Recovery Plane

## Purpose

This folder contains the Local Bridge and its independent recovery plane.

Bridge = hands and eyes through a structured API.
Recovery Agent = a separate local watchdog that can restore Bridge when Bridge itself is unavailable.

Neither component is the Builder brain.

## Hard separation

- `bridge/` may execute and report.
- `bridge/recovery/` may only restore a bounded declared operating state.
- Recovery Agent must not depend on Bridge being alive.
- Recovery Agent must not accept arbitrary shell commands from remote state.
- Project strategy, route selection, acceptance, memory and Owner authority stay outside Bridge.

## Public repository rule

This repository is public.

Therefore:

- NEVER commit plaintext secrets, API tokens, tunnel credentials, passwords or private keys.
- NEVER attach a general-purpose self-hosted GitHub runner on the Owner PC to this public repository.
- Remote recovery instructions must be declarative and bounded.
- Secret values must be referenced by local secure-store key name, never embedded in repo files.

## Recovery authority

Allowed recovery operations are limited to named handlers such as:

- `health_report`
- `ensure_bridge`
- `ensure_tunnel`
- `ensure_repo_remote`
- `ensure_github_cli`
- `restart_bridge`
- `restart_tunnel`
- `rollback_bridge`

Forbidden:

- arbitrary command strings from JSON/YAML/issue text;
- arbitrary PowerShell/Bash received remotely;
- arbitrary file deletion;
- commit/push of product code from Recovery Agent;
- mutation of Builder state/queue/proofs;
- secret export.

## Required proof

Every recovery cycle must write a local report with:

- timestamp;
- desired-state version;
- requested operation;
- operation actually attempted;
- health before/after;
- exit/result status;
- files/services/processes touched;
- error detail;
- rollback status when relevant.

Do not claim recovery without a successful health check after the action.

## Implementation discipline

Before changing recovery behavior:

1. inspect current Bridge and repo state;
2. keep changes inside `bridge/` unless the task explicitly expands scope;
3. add or update validation;
4. preserve a rollback path;
5. report `PREPARED_NOT_RUN` when local execution proof is absent.
