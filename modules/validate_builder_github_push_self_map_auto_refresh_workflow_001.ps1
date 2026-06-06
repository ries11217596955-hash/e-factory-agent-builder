param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$WorkflowPath = '.github/workflows/self-map-auto-refresh-after-push.yml'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Assert-GitHubWorkflow {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

$root = (Resolve-Path $RepoRoot).Path
$full = Join-Path $root $WorkflowPath
Assert-GitHubWorkflow (Test-Path -LiteralPath $full) 'GitHub self-map refresh workflow missing.'
$text = Get-Content -LiteralPath $full -Raw

Assert-GitHubWorkflow ($text -match '(?m)^name:\s*Self Map Auto Refresh After Push\s*$') 'Workflow name missing.'
Assert-GitHubWorkflow ($text -match '(?ms)^on:\s*\r?\n\s+push:\s*\r?\n\s+branches:\s*\r?\n\s+-\s+phase110-idempotent-autonomy-trial-runtime') 'Accepted branch push trigger missing.'
Assert-GitHubWorkflow ($text -match '(?ms)^permissions:\s*\r?\n\s+contents:\s*write') 'contents: write permission missing.'
Assert-GitHubWorkflow ($text -match 'actions/checkout@') 'Checkout action missing.'
Assert-GitHubWorkflow ($text -match 'fetch-depth:\s*0') 'Full history checkout missing.'
Assert-GitHubWorkflow ($text -match 'ref:\s*\$\{\{\s*github\.sha\s*\}\}') 'Workflow does not checkout the exact pushed SHA.'
Assert-GitHubWorkflow ($text -match 'persist-credentials:\s*true') 'Checkout credentials are not retained for GITHUB_TOKEN push.'
Assert-GitHubWorkflow ($text -match 'invoke_builder_github_push_self_map_auto_refresh_001\.ps1') 'Refresh wrapper is not called.'
Assert-GitHubWorkflow ($text -match '\[self-map-refresh\]') 'Recursion prevention marker missing.'
Assert-GitHubWorkflow ($text -match 'Refresh self-map after push \[self-map-refresh\]') 'Refresh commit message missing.'
Assert-GitHubWorkflow ($text -match 'SELF_KNOWLEDGE_READY') 'SELF_KNOWLEDGE_READY verification missing.'
Assert-GitHubWorkflow ($text -match 'self_knowledge_ready') 'self_knowledge_ready verification missing.'
Assert-GitHubWorkflow ($text -match 'map_is_ready_for_next_decision') 'Next-decision readiness verification missing.'
Assert-GitHubWorkflow ($text -match 'git add -- \$Path') 'Explicit path staging missing.'
Assert-GitHubWorkflow ($text -notmatch '(?m)^\s*git\s+add\s+(-A|\.)\s*$') 'Broad git staging is forbidden.'
Assert-GitHubWorkflow ($text -match 'runtime_sessions') 'runtime_sessions staging guard missing.'
Assert-GitHubWorkflow ($text -match 'TASK_QUEUE\.json') 'Protected-state staging guard missing.'
Assert-GitHubWorkflow ($text -match 'route_locks') 'Route-lock staging guard missing.'
Assert-GitHubWorkflow ($text -notmatch '(?i)(PERSONAL_ACCESS_TOKEN|PAT_TOKEN|secrets\.[A-Za-z0-9_]*PAT|GH_PAT)') 'Workflow references a PAT.'
Assert-GitHubWorkflow ($text -notmatch '(?i)curl|Invoke-WebRequest|Invoke-RestMethod') 'Workflow performs external network access outside GitHub actions/git.'

$allowedMatch = [regex]::Match($text, '(?ms)\$Allowed\s*=\s*@\((.*?)^\s{10}\)')
Assert-GitHubWorkflow ($allowedMatch.Success) 'Explicit refresh allowlist block missing.'
$allowedPaths = @([regex]::Matches($allowedMatch.Groups[1].Value, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
$forbidden = @(
  'TASK_QUEUE.json',
  'GENESIS_STATE.json',
  'CAPABILITY_ROADMAP.json',
  'packs/registry.json',
  'orchestrator/run.ps1'
)
Assert-GitHubWorkflow (@($allowedPaths | Where-Object { $_ -in $forbidden }).Count -eq 0) 'Protected file is present in refresh allowlist.'
Assert-GitHubWorkflow (@($allowedPaths | Where-Object { $_ -like 'runtime_sessions*' }).Count -eq 0) 'runtime_sessions is present in refresh allowlist.'
Assert-GitHubWorkflow (@($allowedPaths | Where-Object { $_ -like 'route_locks*' }).Count -eq 0) 'Route lock is present in refresh allowlist.'
Assert-GitHubWorkflow ($allowedPaths -contains 'reports/self_development/PHASE161I_AUTO_REFRESH_AFTER_PUSH_RESULT.json') 'Workflow result is missing from refresh allowlist.'

$wrapperPath = Join-Path $root 'modules/invoke_builder_github_push_self_map_auto_refresh_001.ps1'
Assert-GitHubWorkflow (Test-Path -LiteralPath $wrapperPath) 'GitHub push refresh wrapper missing.'
$wrapperText = Get-Content -LiteralPath $wrapperPath -Raw
Assert-GitHubWorkflow ($wrapperText -match 'Get-FileHash') 'Wrapper does not hash protected files.'
Assert-GitHubWorkflow ($wrapperText -match 'validate_builder_acceptance_self_map_refresh_contract_001\.ps1') 'Wrapper does not validate the PHASE161E refresh contract.'
Assert-GitHubWorkflow ($wrapperText -match 'SELF_KNOWLEDGE_READY') 'Wrapper does not require SELF_KNOWLEDGE_READY.'

[pscustomobject]@{
  result = 'PASS'
  workflow_path = $WorkflowPath
  branch_trigger_configured = $true
  contents_write_permission = $true
  recursion_guard_configured = $true
  refresh_wrapper_called = $true
  protected_state_not_stageable = $true
  runtime_sessions_not_stageable = $true
  self_knowledge_ready_required = $true
  pat_used = $false
  allowed_refresh_path_count = $allowedPaths.Count
}
