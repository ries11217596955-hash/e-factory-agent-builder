# Bridge Recovery Validation Plan

## Hosted validation

The PR must pass the Windows hosted workflow `Bridge Recovery Validate` before merge.

Required hosted checks:

- all `bridge/recovery/*.ps1` files parse with the PowerShell parser;
- JSON contracts parse;
- bootstrap `desired_state.json` ships with `enabled=false`;
- requested operations are limited to the named allowlist;
- remote desired state contains no executable command or secret fields;
- Recovery Agent contains no `Invoke-Expression` / `iex` path.

## Local validation — required before activation

Hosted PASS is not enough to activate recovery.

On the Owner PC:

1. run `bridge/recovery/bootstrap.ps1`;
2. confirm `local_config.json` points to the canonical repo;
3. configure a bounded Bridge start method (`bridge_service_name` or `bridge_start_script`);
4. keep remote desired state disabled for the first dry run;
5. verify a local recovery JSON report is written;
6. enable a new desired-state generation with `health_report` + `ensure_bridge`;
7. stop Bridge intentionally in a sandbox-safe moment;
8. verify Recovery Agent restores Bridge;
9. verify post-action `/health` succeeds;
10. verify the report proves before/action/after state.

## Promotion gate

Status remains:

`PREPARED_NOT_INSTALLED`

until PC-side bootstrap and the intentional Bridge-kill recovery drill both pass.

Do not merge an activation state (`enabled=true`) as the bootstrap default.
