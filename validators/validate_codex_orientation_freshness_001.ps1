param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-GitValue {
    param(
        [string]$Root,
        [string[]]$Arguments,
        [switch]$Optional
    )

    $output = @(& git -C $Root @Arguments 2>$null)
    if ($LASTEXITCODE -ne 0) {
        if ($Optional) {
            return $null
        }
        throw "git $($Arguments -join ' ') failed."
    }
    return (($output -join "`n").Trim())
}

function Write-Utf8File {
    param(
        [string]$Path,
        [string]$Content
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
}

$root = (Resolve-Path $RepoRoot).Path
$errors = [System.Collections.Generic.List[string]]::new()

function Assert-Condition {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        $script:errors.Add($Message)
    }
}

$generatedFiles = @(
    "docs/codex/CODEX_REPO_MAP.md",
    "docs/codex/CODEX_EVIDENCE_INDEX.md",
    "docs/codex/CODEX_CURRENT_STATE_THIN.json"
)
$repoMapPath = Join-Path $root $generatedFiles[0]
$evidenceIndexPath = Join-Path $root $generatedFiles[1]
$currentStatePath = Join-Path $root $generatedFiles[2]
$agentsPath = Join-Path $root "AGENTS.md"
$activeRouteLock = "route_locks/AGENT_BUILDER_NEXT_15_STEPS_LOCK_V2.md"

foreach ($relativePath in $generatedFiles) {
    Assert-Condition -Condition (Test-Path -LiteralPath (Join-Path $root $relativePath)) -Message "Missing generated file: $relativePath"
}

$branch = Get-GitValue -Root $root -Arguments @("branch", "--show-current")
$head = Get-GitValue -Root $root -Arguments @("rev-parse", "HEAD")
$origin = Get-GitValue -Root $root -Arguments @(
    "rev-parse",
    "--verify",
    "origin/phase110-idempotent-autonomy-trial-runtime"
) -Optional
$headEqualsOrigin = (-not [string]::IsNullOrWhiteSpace($origin)) -and ($head -eq $origin)

$state = $null
if (Test-Path -LiteralPath $currentStatePath) {
    try {
        $state = Get-Content -LiteralPath $currentStatePath -Raw | ConvertFrom-Json
    }
    catch {
        $errors.Add("CODEX_CURRENT_STATE_THIN.json is not valid JSON: $($_.Exception.Message)")
    }
}

$repoMap = if (Test-Path -LiteralPath $repoMapPath) {
    Get-Content -LiteralPath $repoMapPath -Raw
}
else {
    ""
}
$evidenceIndex = if (Test-Path -LiteralPath $evidenceIndexPath) {
    Get-Content -LiteralPath $evidenceIndexPath -Raw
}
else {
    ""
}
$agents = if (Test-Path -LiteralPath $agentsPath) {
    Get-Content -LiteralPath $agentsPath -Raw
}
else {
    ""
}

$expectedReadFirst = @(
    "AGENTS.md",
    "README.md",
    $activeRouteLock,
    "CAPABILITY_ROADMAP.json",
    "GENESIS_STATE.json",
    "TASK_QUEUE.json",
    "packs/registry.json",
    "orchestrator/run.ps1"
)
$expectedSkipRules = @(
    "reports/**",
    "proofs/**",
    "self_build_programs/**/canonical_trials/**",
    "self_build_programs/**/dry_runs/**",
    "self_build_programs/**/promotions/**",
    "runtime_sessions/**",
    "zz_MUSORKA_DO_NOT_READ_BY_CODEX/**"
)

$routeLockPresent = Test-Path -LiteralPath (Join-Path $root $activeRouteLock)
$currentStateThinPresent = Test-Path -LiteralPath $currentStatePath
$repoMapPresent = Test-Path -LiteralPath $repoMapPath
$evidenceIndexPresent = Test-Path -LiteralPath $evidenceIndexPath
$agentsBudgetBlockPresent = $agents.Contains("<!-- CODEX_CONTEXT_BUDGET_START -->") -and
    $agents.Contains("<!-- CODEX_CONTEXT_BUDGET_END -->")
$exactPathRulePresent = $repoMap.Contains("Exact-Path Evidence Rule") -and
    $repoMap.Contains("exact proof or report path") -and
    $evidenceIndex.Contains("Exact-Path Evidence Rule")
$phase165oProofPaths = @(
    "proofs/self_development/PHASE165O_GUARDED_PROMOTION_APPLY_FOR_REUSABLE_SELF_BUILD_ORGAN_V1.json",
    "proofs/self_development/PHASE165O_POST_PROMOTION_STATE_VERIFY_AND_CLOSE_V1.json"
)
$phase165pBudgetProofPath = "proofs/self_development/PHASE165P_CODEX_CONTEXT_BUDGET_AGENTS_UPDATE_V1.json"
$phase165oProofPathsPresent = @($phase165oProofPaths | Where-Object {
    -not $evidenceIndex.Contains($_)
}).Count -eq 0
$phase165pBudgetProofPathPresent = $evidenceIndex.Contains($phase165pBudgetProofPath)

$readFirstPresent = $false
$skipRulesPresent = $false
if ($null -ne $state) {
    Assert-Condition -Condition ([string]$state.head -eq $head) -Message "Thin state HEAD does not equal actual git HEAD."
    Assert-Condition -Condition ([string]$state.branch -eq $branch) -Message "Thin state branch does not equal actual git branch."
    Assert-Condition -Condition ([string]$state.active_route_lock -eq $activeRouteLock) -Message "Thin state active route lock is incorrect."

    $actualReadFirst = @($state.read_first | ForEach-Object { [string]$_ })
    $readFirstPresent = ($actualReadFirst.Count -gt 0) -and (@($expectedReadFirst | Where-Object {
        $actualReadFirst -notcontains $_
    }).Count -eq 0)

    $actualSkipRules = @($state.codex_skip_rules | ForEach-Object { [string]$_ })
    $skipRulesPresent = ($actualSkipRules.Count -gt 0) -and (@($expectedSkipRules | Where-Object {
        $actualSkipRules -notcontains $_
    }).Count -eq 0)
}

Assert-Condition -Condition $routeLockPresent -Message "Active route lock is missing."
Assert-Condition -Condition $readFirstPresent -Message "Required read-first list is missing or incomplete."
Assert-Condition -Condition $skipRulesPresent -Message "Required Codex skip rules are missing or incomplete."
Assert-Condition -Condition $exactPathRulePresent -Message "Exact-path evidence rule is missing."
Assert-Condition -Condition $phase165oProofPathsPresent -Message "PHASE165O proof paths are missing from the evidence index."
Assert-Condition -Condition $phase165pBudgetProofPathPresent -Message "PHASE165P budget proof path is missing from the evidence index."
Assert-Condition -Condition $agentsBudgetBlockPresent -Message "AGENTS.md Codex Context Budget block is missing."

$protectedFiles = [ordered]@{
    task_queue_mutated = "TASK_QUEUE.json"
    genesis_state_mutated = "GENESIS_STATE.json"
    capability_roadmap_mutated = "CAPABILITY_ROADMAP.json"
    registry_mutated = "packs/registry.json"
    route_lock_mutated = $activeRouteLock
    orchestrator_mutated = "orchestrator/run.ps1"
}
$mutationResults = @{}
foreach ($field in $protectedFiles.Keys) {
    $relativePath = $protectedFiles[$field]
    $changed = Get-GitValue -Root $root -Arguments @("diff", "--name-only", "HEAD", "--", $relativePath)
    $mutated = -not [string]::IsNullOrWhiteSpace($changed)
    $mutationResults[$field] = $mutated
    Assert-Condition -Condition (-not $mutated) -Message "Protected file was mutated: $relativePath"
}

$validationPassed = $errors.Count -eq 0
$status = if ($validationPassed) { "PASS" } else { "FAIL" }
$nextRequiredAction = if ($validationPassed) {
    "PHASE165P_CODEX_ORIENTATION_AUTO_REFRESH_ACCEPTANCE_COMMIT"
}
else {
    "PHASE165P_CODEX_ORIENTATION_AUTO_REFRESH_TRIAGE"
}

$proof = [ordered]@{
    phase = "PHASE165P_CODEX_ORIENTATION_AUTO_REFRESH_ORGAN_V1"
    created_utc = [DateTime]::UtcNow.ToString("o")
    status = $status
    validation_passed = [bool]$validationPassed
    errors = @($errors)
    generated_files = $generatedFiles
    branch = $branch
    head = $head
    origin = $origin
    head_equals_origin = [bool]$headEqualsOrigin
    route_lock_present = [bool]$routeLockPresent
    current_state_thin_present = [bool]$currentStateThinPresent
    repo_map_present = [bool]$repoMapPresent
    evidence_index_present = [bool]$evidenceIndexPresent
    agents_budget_block_present = [bool]$agentsBudgetBlockPresent
    skip_rules_present = [bool]$skipRulesPresent
    exact_path_rule_present = [bool]$exactPathRulePresent
    phase165o_proof_paths_present = [bool]$phase165oProofPathsPresent
    phase165p_budget_proof_path_present = [bool]$phase165pBudgetProofPathPresent
    task_queue_mutated = [bool]$mutationResults["task_queue_mutated"]
    genesis_state_mutated = [bool]$mutationResults["genesis_state_mutated"]
    capability_roadmap_mutated = [bool]$mutationResults["capability_roadmap_mutated"]
    registry_mutated = [bool]$mutationResults["registry_mutated"]
    route_lock_mutated = [bool]$mutationResults["route_lock_mutated"]
    orchestrator_mutated = [bool]$mutationResults["orchestrator_mutated"]
    orchestrator_run = $false
    external_fetch_or_install = $false
    codex_used = $true
    next_required_action = $nextRequiredAction
}

$reportLines = @(
    "# PHASE165P Codex Orientation Auto-Refresh Organ",
    "",
    "- Status: **$status**",
    "- Validation passed: ``$($validationPassed.ToString().ToLowerInvariant())``",
    "- Branch: ``$branch``",
    "- HEAD: ``$head``",
    "- Origin: ``$(if ($origin) { $origin } else { 'UNAVAILABLE' })``",
    "- HEAD equals origin: ``$($headEqualsOrigin.ToString().ToLowerInvariant())``",
    "- Active route lock present: ``$($routeLockPresent.ToString().ToLowerInvariant())``",
    "- Orchestrator run: ``false``",
    "- External fetch or install: ``false``",
    "",
    "## Generated Files",
    ""
)
$reportLines += $generatedFiles | ForEach-Object { "- ``$_``" }
$reportLines += @(
    "",
    "## Protected File Mutation Checks",
    ""
)
foreach ($field in $protectedFiles.Keys) {
    $reportLines += "- ``$($protectedFiles[$field])`` mutated: ``$($mutationResults[$field].ToString().ToLowerInvariant())``"
}
$reportLines += @(
    "",
    "## Validation Errors",
    ""
)
if ($errors.Count -eq 0) {
    $reportLines += "- None."
}
else {
    $reportLines += $errors | ForEach-Object { "- $_" }
}
$reportLines += @(
    "",
    "## Next Required Action",
    "",
    "``$nextRequiredAction``",
    ""
)

$proofPath = Join-Path $root "proofs/self_development/PHASE165P_CODEX_ORIENTATION_AUTO_REFRESH_ORGAN_V1.json"
$reportPath = Join-Path $root "reports/self_development/PHASE165P_CODEX_ORIENTATION_AUTO_REFRESH_ORGAN_V1.md"
Write-Utf8File -Path $proofPath -Content ($proof | ConvertTo-Json -Depth 20)
Write-Utf8File -Path $reportPath -Content ($reportLines -join "`n")

Write-Host "CODEX_ORIENTATION_VALIDATION=$status"
Write-Host "PROOF_PATH=proofs/self_development/PHASE165P_CODEX_ORIENTATION_AUTO_REFRESH_ORGAN_V1.json"
Write-Host "REPORT_PATH=reports/self_development/PHASE165P_CODEX_ORIENTATION_AUTO_REFRESH_ORGAN_V1.md"
Write-Host "NEXT_REQUIRED_ACTION=$nextRequiredAction"

if (-not $validationPassed) {
    throw "Codex orientation freshness validation failed: $($errors -join '; ')"
}

[pscustomobject]$proof
