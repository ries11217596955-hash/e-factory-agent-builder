param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [Parameter(Mandatory=$true)]$Delivery,
  [string]$OutputPath = 'reports/self_development/PHASE161I_ACCEPT_BASELINE_COMMIT_PUSH_DELIVERY.md'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path $RepoRoot).Path
$full = Join-Path $root $OutputPath
$dir = Split-Path -Parent $full
if ($dir -and -not (Test-Path -LiteralPath $dir)) {
  New-Item -ItemType Directory -Path $dir | Out-Null
}

@(
  '# PHASE161I Accept Baseline Commit Push Delivery',
  '',
  ('Root guard: `{0}`' -f $Delivery.root_guard),
  ('Validator: `{0}`' -f $Delivery.validator),
  ('Workflow commit: `{0}`' -f $Delivery.workflow_commit),
  ('Workflow push: `{0}`' -f $Delivery.workflow_push),
  ('Remote auto refresh: `{0}`' -f $Delivery.remote_auto_refresh),
  ('Auto-refresh commit: `{0}`' -f $Delivery.auto_refresh_commit),
  ('Accepted subject head: `{0}`' -f $Delivery.accepted_subject_head),
  ('Map refresh status: `{0}`' -f $Delivery.map_refresh_status),
  ('Self knowledge ready: `{0}`' -f $Delivery.self_knowledge_ready),
  ('Map ready for next decision: `{0}`' -f $Delivery.map_ready_for_next_decision),
  ('Protected state mutated: `{0}`' -f $Delivery.protected_state_mutated),
  ('Runtime outputs staged: `{0}`' -f $Delivery.runtime_outputs_staged),
  ('Final recommendation: `{0}`' -f $Delivery.final_recommendation)
) | Set-Content -LiteralPath $full -Encoding UTF8

$full
