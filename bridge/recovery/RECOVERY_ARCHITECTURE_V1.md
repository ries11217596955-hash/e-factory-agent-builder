# Recovery Architecture V1

## Goal

Preserve operational capability when one access path fails.

The target is not "every connector contains every secret". The target is:

> if one trusted control path remains available, it can restore equivalent access to PC execution, repository operations, GitHub Actions and Bridge health without manual reconstruction of the whole stack.

## Control planes

### Plane A — Direct GitHub control

Available to ChatGPT through the connected GitHub integration.

Capabilities:

- read/write repository files;
- create branches/PRs;
- inspect commits;
- inspect/retry GitHub Actions where supported.

Recovery role:

- publish bounded desired-state changes;
- repair recovery code/config;
- inspect proof artifacts;
- act even when Bridge/tunnel is dead.

### Plane B — Local Bridge control

Future GPT Action / structured API exposed by Local Bridge.

Capabilities target:

- PC health;
- PowerShell/process/service/task execution through named modes;
- filesystem/report access;
- git/gh operations;
- GitHub Actions operations through `gh`/API;
- Codex handoff;
- logs/artifacts.

Recovery role:

- when direct GitHub integration is unavailable, Bridge provides repo and Actions capability from the PC;
- can repair local GitHub CLI/auth/config and Bridge-side components.

### Plane C — Local Recovery Agent

Independent Windows process/scheduled task. It must not depend on Bridge.

It periodically reads a bounded desired-state file from a trusted repository ref and applies only hard-coded recovery handlers.

Capabilities target:

- health check Bridge and tunnel;
- start/restart Bridge;
- start/restart tunnel;
- verify repo remote/root;
- verify `git` / `gh` availability;
- rollback Bridge to last-known-good package;
- write recovery proof report.

It MUST NOT execute arbitrary remotely supplied shell text.

### Plane D — Owner local bootstrap

One PowerShell bootstrap command/script from the repo can reinstall the Recovery Agent and reconstruct local Bridge prerequisites after local damage.

This is the cold-start path, not the normal recovery path.

## Recovery matrix

| Failure | Remaining channel | Recovery path |
|---|---|---|
| Bridge process dead | GitHub | publish desired state -> Recovery Agent -> restart Bridge -> health proof |
| Tunnel dead | GitHub | desired state -> Recovery Agent -> restart tunnel -> external health proof |
| Direct GitHub connector unavailable | Bridge | use local `git`/`gh`/GitHub API through Bridge |
| Local repo remote broken | Bridge | `ensure_repo_remote` -> verify fetch/status |
| GitHub CLI broken | Bridge or Recovery Agent | reinstall/repair bounded tool path -> auth check |
| Bridge code damaged | GitHub | pin last-known-good revision/package -> Recovery Agent rollback |
| Recovery Agent damaged but Bridge alive | Bridge | reinstall/register Recovery Agent |
| Bridge + Recovery Agent both damaged | Owner local | run bootstrap from repo/local recovery copy |
| PC offline/powered off | GitHub only | software recovery cannot power hardware; requires separate remote-power/WoL layer if needed |

## Trust model

1. Repository contains no plaintext secrets.
2. Remote desired state contains operation names and versions, not command strings.
3. Local secrets stay in OS-backed secure storage or another dedicated secret manager.
4. Recovery Agent is allowed to consume local secret references but never export secret values.
5. Every repair has health-before / action / health-after proof.
6. Last-known-good revision/package is explicit and rollback-capable.

## Desired-state contract

`bridge/recovery/desired_state.json` is declarative.

Minimum fields:

- `schema_version`
- `generation`
- `enabled`
- `requested_operations[]`
- `bridge.target_ref`
- `bridge.health_url`
- `tunnel.enabled`
- `repo.expected_remote`
- `proof.output_dir`

Rules:

- `generation` must monotonically increase for a new instruction set;
- unknown operations are rejected;
- arbitrary command/script fields are forbidden;
- the same generation is idempotent;
- success requires post-action health proof.

## Current capability audit

Verified now:

- canonical repo: `ries11217596955-hash/e-factory-agent-builder`;
- direct GitHub integration: read/write access available;
- canonical repo is public;
- root `AGENTS.md` exists;
- a dedicated Bridge implementation was not found at `bridge/AGENTS.md` on the active phase branch before this work;
- no separate PC/Bridge Action is available in the current ChatGPT tool surface.

Therefore the immediate bottleneck is PC-side execution/recovery, not repository access.

## V1 build order

1. Land Recovery Plane contract and bounded desired state.
2. Implement Recovery Agent with local proof logging.
3. Implement Bridge health/start/stop contract.
4. Install Recovery Agent as a Windows scheduled task/service and prove it survives Bridge failure.
5. Add tunnel restore.
6. Expose Bridge OpenAPI to GPT Action.
7. Add `git`/`gh`/Actions capability through Bridge.
8. Run destructive recovery drills in sandbox only: kill Bridge, kill tunnel, break repo remote, rollback Bridge.
9. Promote only after proof pack.

## Cut

Do not add a self-hosted GitHub runner to the public canonical repo.
Do not use Gmail/Drive/chat text as an executable command bus in V1.
Do not store secrets in repository files.
Do not make Recovery Agent a second autonomous agent.
