# Access Capability Matrix

Status date: 2026-08-07

## Current verified remote capabilities

| Capability | Current status | Evidence / meaning |
|---|---|---|
| Direct GitHub repo read | PASS | ChatGPT GitHub integration can fetch canonical repo files |
| Direct GitHub repo write | PASS | Recovery work branch/files were created through GitHub integration |
| Branch / PR control | PASS | `bridge-recovery-bootstrap-v1`, `recovery-control`, PR #2 created |
| GitHub Actions inspect/retry surface | PARTIAL | integration exposes workflow run/job/artifact inspection and retry functions |
| Direct workflow dispatch from current ChatGPT GitHub surface | NOT AVAILABLE | no dispatch action exposed in current connector tool surface |
| Local PC shell | NOT AVAILABLE | no live PC/terminal bridge is exposed to this ChatGPT session |
| Local PC filesystem/process/service control | NOT AVAILABLE | depends on Local Bridge / Recovery Agent installation |
| Local Bridge GPT Action | NOT AVAILABLE | no Bridge Action is exposed in the current ChatGPT tool surface |
| Recovery Agent | PREPARED_NOT_INSTALLED | code/config/bootstrap prepared in PR branch; no Windows runtime proof yet |
| Local `git` / `gh` credentials | UNKNOWN | requires PC-side observation |
| Tunnel/external Bridge URL | UNKNOWN | requires PC-side observation |
| Codex CLI through PC | UNKNOWN | requires PC-side observation |

## Target redundancy

### If Direct GitHub remains alive

GitHub -> `recovery-control/desired_state.json` -> outbound-polling Recovery Agent on PC -> restore Bridge/tunnel -> regain PC execution.

### If Local Bridge remains alive

Bridge -> local PowerShell/git/gh -> repo + GitHub API/Actions -> direct GitHub connector becomes optional for capability continuity.

### If only Owner local access remains

Run `bridge/recovery/bootstrap.ps1` -> reinstall Recovery Agent -> restore Bridge -> restore remote control.

## Missing before "iron recovery" can be claimed

1. PC-side Recovery Agent installed and scheduled/service-backed.
2. Bridge has a deterministic start/health contract.
3. Bridge is reachable through a stable authenticated Action endpoint.
4. Bridge exposes bounded local `git` / `gh` / Actions operations.
5. Tunnel restore is implemented and proven.
6. Kill/recovery drills pass with proof artifacts.
7. Last-known-good Bridge rollback is implemented and proven.
8. Optional physical-power layer defined if remote recovery must include a powered-off PC.

## Non-goal

We do not require every UI connector to be restorable automatically. We require the underlying capability to remain recoverable through another trusted plane.
