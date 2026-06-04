param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160IValidatePath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160IValidateRepoRoot {
  param([string]$RepoRootParameter)
  if (-not [string]::IsNullOrWhiteSpace($RepoRootParameter) -and $RepoRootParameter -ne ".") {
    return Normalize-Phase160IValidatePath -Path $RepoRootParameter
  }
  $scriptRoot = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRoot) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRoot = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
    throw "PHASE160I_VALIDATE_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160IValidatePath -Path (Join-Path $scriptRoot "..")
}

function Resolve-Phase160IValidatePath {
  param([string]$Root, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $Root $Path))
}

function Read-Phase160IValidateJson {
  param([string]$Root, [string]$Path)
  $fullPath = Resolve-Phase160IValidatePath -Root $Root -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160I_VALIDATE_MISSING_JSON=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase160IValidateText {
  param([string]$Root, [string]$Path)
  $fullPath = Resolve-Phase160IValidatePath -Root $Root -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160I_VALIDATE_MISSING_TEXT=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw
}

function Assert-Phase160IValidateTrue {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $true) {
    throw "PHASE160I_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase160IValidateFalse {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $false) {
    throw "PHASE160I_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase160IValidateEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160I_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase160IValidateContains {
  param([object[]]$Values, [string]$Expected, [string]$Name)
  if (@($Values | Where-Object { [string]$_ -eq $Expected }).Count -lt 1) {
    throw "PHASE160I_VALIDATE_MISSING_VALUE=$Name expected=$Expected"
  }
}

function Assert-Phase160IValidateParserClean {
  param([string]$Path)
  $tokens = $null
  $parseErrors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors) | Out-Null
  if ($parseErrors.Count -gt 0) {
    throw "PHASE160I_VALIDATE_PARSE_ERROR=$Path message=$($parseErrors[0].Message)"
  }
}

function Get-Phase160IValidateHashes {
  param([string]$Root, [string[]]$Paths)
  $hashes = @{}
  foreach ($path in $Paths) {
    $fullPath = Resolve-Phase160IValidatePath -Root $Root -Path $path
    if (Test-Path -LiteralPath $fullPath) {
      $hashes[$path] = (Get-FileHash -LiteralPath $fullPath -Algorithm SHA256).Hash
    } else {
      $hashes[$path] = "MISSING"
    }
  }
  return $hashes
}

function Invoke-Phase160IValidateAuditModule {
  param([string]$Root, [string]$ScriptPath)
  $fullScript = Resolve-Phase160IValidatePath -Root $Root -Path $ScriptPath
  if (-not (Test-Path -LiteralPath $fullScript)) {
    throw "PHASE160I_VALIDATE_MODULE_MISSING=$ScriptPath"
  }
  $output = @(& $fullScript -RepoRoot $Root 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160I_VALIDATE_MODULE_FAILED=$ScriptPath output=$($output -join ' | ')"
  }
}

function Get-Phase160IValidateRemoteHeadSafe {
  param([string]$Branch)
  $remoteHead = (git rev-parse --short "origin/$Branch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    return "UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Assert-Phase160IValidateRuntimeOutputsNotStaged {
  $stagedRuntime = @(git diff --cached --name-only -- runtime_sessions)
  if ($stagedRuntime.Count -gt 0) {
    throw "PHASE160I_VALIDATE_RUNTIME_OUTPUTS_STAGED=$($stagedRuntime -join '; ')"
  }
}

$resolvedRoot = Resolve-Phase160IValidateRepoRoot -RepoRootParameter $RepoRoot
$pushed = $false

try {
  Push-Location $resolvedRoot
  $pushed = $true

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160IValidatePath -Root $resolvedRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $branchBefore = (git branch --show-current).Trim()
  $headBefore = (git rev-parse --short HEAD).Trim()
  $remoteBefore = Get-Phase160IValidateRemoteHeadSafe -Branch $branchBefore
  $protectedPaths = @("TASK_QUEUE.json", "GENESIS_STATE.json", "CAPABILITY_ROADMAP.json", "packs/registry.json", "orchestrator/run.ps1")
  $protectedBefore = Get-Phase160IValidateHashes -Root $resolvedRoot -Paths $protectedPaths

  $newPs1Files = @(
    "modules/inspect_builder_live_task_intake_lifecycle_001.ps1",
    "modules/inspect_builder_active_task_backlog_lifecycle_001.ps1",
    "modules/inspect_builder_quality_artifact_consistency_001.ps1",
    "modules/inspect_builder_route_lock_status_001.ps1",
    "modules/inspect_builder_long_run_batch_readiness_001.ps1",
    "validators/validate_phase160i_long_run_lifecycle_audit_v1.ps1"
  )
  foreach ($path in $newPs1Files) {
    Assert-Phase160IValidateParserClean -Path (Resolve-Phase160IValidatePath -Root $resolvedRoot -Path $path)
  }

  Invoke-Phase160IValidateAuditModule -Root $resolvedRoot -ScriptPath "modules/inspect_builder_live_task_intake_lifecycle_001.ps1"
  Invoke-Phase160IValidateAuditModule -Root $resolvedRoot -ScriptPath "modules/inspect_builder_active_task_backlog_lifecycle_001.ps1"
  Invoke-Phase160IValidateAuditModule -Root $resolvedRoot -ScriptPath "modules/inspect_builder_quality_artifact_consistency_001.ps1"
  Invoke-Phase160IValidateAuditModule -Root $resolvedRoot -ScriptPath "modules/inspect_builder_route_lock_status_001.ps1"
  Invoke-Phase160IValidateAuditModule -Root $resolvedRoot -ScriptPath "modules/inspect_builder_long_run_batch_readiness_001.ps1"

  $stagePaths = @(
    "reports/self_development/stage_01_owner_task_intake_audit.json",
    "reports/self_development/stage_02_active_task_backlog_audit.json",
    "reports/self_development/stage_03_candidate_source_attribution_audit.json",
    "reports/self_development/stage_04_quality_artifact_consistency_audit.json",
    "reports/self_development/stage_05_promotion_truthfulness_audit.json",
    "reports/self_development/stage_06_route_lock_status_audit.json",
    "reports/self_development/stage_07_overnight_batch_readiness_audit.json",
    "reports/self_development/stage_08_repair_package_plan.json"
  )
  $stages = @{}
  foreach ($path in $stagePaths) {
    $stages[$path] = Read-Phase160IValidateJson -Root $resolvedRoot -Path $path
  }

  $stage01 = $stages["reports/self_development/stage_01_owner_task_intake_audit.json"]
  $stage02 = $stages["reports/self_development/stage_02_active_task_backlog_audit.json"]
  $stage03 = $stages["reports/self_development/stage_03_candidate_source_attribution_audit.json"]
  $stage04 = $stages["reports/self_development/stage_04_quality_artifact_consistency_audit.json"]
  $stage05 = $stages["reports/self_development/stage_05_promotion_truthfulness_audit.json"]
  $stage06 = $stages["reports/self_development/stage_06_route_lock_status_audit.json"]
  $stage07 = $stages["reports/self_development/stage_07_overnight_batch_readiness_audit.json"]
  $stage08 = $stages["reports/self_development/stage_08_repair_package_plan.json"]

  Assert-Phase160IValidateTrue -Actual ([bool]$stage01.unsafe_live_task_safety_rules.detected) -Name "unsafe_live_task_safety_rules_detected"
  Assert-Phase160IValidateTrue -Actual ([bool]$stage01.unsafe_live_task_safety_rules.safe_owner_training_task_falsely_quarantined) -Name "safe_owner_training_task_falsely_quarantined"
  Assert-Phase160IValidateContains -Values @($stage02.classifications) -Expected "ACTIVE_TASK_BLOCKS_OWNER_TASK" -Name "active_task_blocks_owner_task"
  Assert-Phase160IValidateContains -Values @($stage02.classifications) -Expected "OWNER_TASK_BACKLOGGED" -Name "owner_task_backlogged"
  Assert-Phase160IValidateFalse -Actual ([bool]$stage02.owner_task_state.owner_task_lost) -Name "owner_task_lost"
  Assert-Phase160IValidateTrue -Actual ([bool]$stage03.candidate_source_attribution.candidate_came_from_internal_phase160f_task) -Name "candidate_came_from_internal_phase160f_task"
  Assert-Phase160IValidateFalse -Actual ([bool]$stage03.candidate_source_attribution.injected_owner_task_influenced_candidate) -Name "injected_owner_task_influenced_candidate"
  Assert-Phase160IValidateTrue -Actual ([bool]$stage03.promotion_manifest_source_truth.quarantined_owner_task_must_not_appear_as_executed_source) -Name "source_attribution_truth"
  Assert-Phase160IValidateTrue -Actual ([bool]$stage04.quality_result_count_issue.detected) -Name "quality_artifact_consistency_issue_detected"
  Assert-Phase160IValidateEquals -Actual ([string]$stage04.quality_result_count_issue.classification) -Expected "CHECKER_WEAKNESS_LEGACY_PATH_MISMATCH" -Name "quality_artifact_consistency_classification"
  Assert-Phase160IValidateTrue -Actual ([bool]$stage05.promotion_truthfulness.waiting_owner_review_allowed_only_for_quality_ready) -Name "promotion_waiting_owner_review_truth"
  Assert-Phase160IValidateTrue -Actual ([bool]$stage06.old_route_lock_status_detected) -Name "old_route_lock_status_detected"
  if ([string]$stage06.recommendation -notmatch "PHASE161") {
    throw "PHASE160I_VALIDATE_ROUTE_RECOMMENDATION_MISSING_PHASE161"
  }
  Assert-Phase160IValidateFalse -Actual ([bool]$stage07.overnight_batch_school_ready) -Name "overnight_batch_school_ready"
  if (@($stage07.phase161_blockers).Count -lt 1) {
    throw "PHASE160I_VALIDATE_PHASE161_BLOCKERS_MISSING"
  }
  $packageIds = @($stage08.packages | ForEach-Object { [string]$_.package_id })
  foreach ($requiredPackage in @(
    "TASK_INTAKE_SCHEMA_AND_SAFETY_RULES_REPAIR",
    "ACTIVE_TASK_BACKLOG_LIFECYCLE_REPAIR",
    "QUALITY_ARTIFACT_CONSISTENCY_REPAIR",
    "ROUTE_LOCK_SUPERSESSION_REPAIR",
    "PHASE161_BATCH_SCHOOL_FOUNDATION"
  )) {
    Assert-Phase160IValidateContains -Values $packageIds -Expected $requiredPackage -Name "repair_package_ids"
  }
  $dependencyOrder = @($stage08.dependency_order)
  if ($dependencyOrder.Count -ne 5) {
    throw "PHASE160I_VALIDATE_REPAIR_PACKAGE_DEPENDENCY_ORDER_INVALID"
  }

  $reportText = Read-Phase160IValidateText -Root $resolvedRoot -Path "reports/self_development/PHASE160I_LONG_RUN_LIFECYCLE_AUDIT_REPORT.md"
  if ($reportText -notmatch "STAGE \| EXPECTED \| OBSERVED \| ROOT_CAUSE \| REPAIR_PACKAGE \| BLOCKS_PHASE161") {
    throw "PHASE160I_VALIDATE_REPORT_TABLE_MISSING"
  }
  $proof = Read-Phase160IValidateJson -Root $resolvedRoot -Path "proofs/self_development/PHASE160I_LONG_RUN_LIFECYCLE_AUDIT_PROOF.json"
  Assert-Phase160IValidateTrue -Actual ([bool]$proof.phase161_blockers_identified) -Name "proof_phase161_blockers_identified"
  Assert-Phase160IValidateTrue -Actual ([bool]$proof.repair_package_plan_created) -Name "proof_repair_package_plan_created"
  $routeText = Read-Phase160IValidateText -Root $resolvedRoot -Path "route_change_requests/PHASE160I_LONG_RUN_LIFECYCLE_AUDIT_REQUEST.md"
  if ($routeText -notmatch "PHASE161") {
    throw "PHASE160I_VALIDATE_ROUTE_REQUEST_MISSING_PHASE161"
  }

  $protectedAfter = Get-Phase160IValidateHashes -Root $resolvedRoot -Paths $protectedPaths
  foreach ($path in $protectedPaths) {
    Assert-Phase160IValidateEquals -Actual $protectedAfter[$path] -Expected $protectedBefore[$path] -Name "protected_state_hash_$path"
  }
  Assert-Phase160IValidateRuntimeOutputsNotStaged

  $branchAfter = (git branch --show-current).Trim()
  $headAfter = (git rev-parse --short HEAD).Trim()
  $remoteAfter = Get-Phase160IValidateRemoteHeadSafe -Branch $branchAfter
  Assert-Phase160IValidateEquals -Actual $branchAfter -Expected $branchBefore -Name "branch_unchanged"
  Assert-Phase160IValidateEquals -Actual $headAfter -Expected $headBefore -Name "head_unchanged_no_commit"
  Assert-Phase160IValidateEquals -Actual $remoteAfter -Expected $remoteBefore -Name "remote_head_unchanged_no_push"

  Write-Host "PHASE160I_LONG_RUN_LIFECYCLE_AUDIT_VALIDATE_RESULT=PASS"
  Write-Host "OWNER_TASK_INTAKE_AUDITED=True"
  Write-Host "UNSAFE_LIVE_TASK_SAFETY_RULES_ROOT_CAUSE_RECORDED=True"
  Write-Host "ACTIVE_TASK_BACKLOG_LIFECYCLE_AUDITED=True"
  Write-Host "CANDIDATE_SOURCE_ATTRIBUTION_AUDITED=True"
  Write-Host "QUALITY_ARTIFACT_CONSISTENCY_AUDITED=True"
  Write-Host "PROMOTION_TRUTHFULNESS_AUDITED=True"
  Write-Host "ROUTE_LOCK_STATUS_AUDITED=True"
  Write-Host "OVERNIGHT_BATCH_READINESS_AUDITED=True"
  Write-Host "REPAIR_PACKAGE_PLAN_CREATED=True"
  Write-Host "PHASE161_BLOCKERS_IDENTIFIED=True"
  Write-Host "NO_PROTECTED_STATE_MUTATION=True"
  Write-Host "RUNTIME_OUTPUTS_STAGED=False"
  Write-Host "NO_COMMIT_PERFORMED=True"
  Write-Host "NO_PUSH_PERFORMED=True"
  Write-Host "NO_BRANCH_SWITCH=True"
} finally {
  if ($pushed) {
    Pop-Location
  }
}
