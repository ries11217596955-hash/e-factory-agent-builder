param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160LValidatePath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160LValidateRepoRoot {
  param([string]$RepoRootParameter)
  if (-not [string]::IsNullOrWhiteSpace($RepoRootParameter) -and $RepoRootParameter -ne ".") {
    return Normalize-Phase160LValidatePath -Path $RepoRootParameter
  }
  $scriptRoot = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRoot) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRoot = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
    throw "PHASE160L_VALIDATE_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160LValidatePath -Path (Join-Path $scriptRoot "..")
}

function Resolve-Phase160LValidatePath {
  param([string]$Root, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $Root $Path))
}

function Read-Phase160LValidateText {
  param([string]$Root, [string]$Path)
  $fullPath = Resolve-Phase160LValidatePath -Root $Root -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160L_VALIDATE_MISSING_TEXT=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw
}

function Read-Phase160LValidateJson {
  param([string]$Root, [string]$Path)
  $fullPath = Resolve-Phase160LValidatePath -Root $Root -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160L_VALIDATE_MISSING_JSON=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Assert-Phase160LValidateTrue {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $true) {
    throw "PHASE160L_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase160LValidateEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160L_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase160LValidateParserClean {
  param([string]$Path)
  $tokens = $null
  $parseErrors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors) | Out-Null
  if ($parseErrors.Count -gt 0) {
    throw "PHASE160L_VALIDATE_PARSE_ERROR=$Path message=$($parseErrors[0].Message)"
  }
}

function Get-Phase160LValidateFileHashes {
  param([string]$Root, [string[]]$Paths)
  $hashes = @{}
  foreach ($path in $Paths) {
    $fullPath = Resolve-Phase160LValidatePath -Root $Root -Path $path
    if (Test-Path -LiteralPath $fullPath) {
      $hashes[$path] = (Get-FileHash -LiteralPath $fullPath -Algorithm SHA256).Hash
    } else {
      $hashes[$path] = "MISSING"
    }
  }
  return $hashes
}

function Get-Phase160LValidateRemoteHeadSafe {
  param([string]$Branch)
  $remoteHead = (git rev-parse --short "origin/$Branch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    return "UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Assert-Phase160LRuntimeOutputsNotStaged {
  $stagedRuntime = @(git diff --cached --name-only -- runtime_sessions)
  if ($stagedRuntime.Count -gt 0) {
    throw "PHASE160L_VALIDATE_RUNTIME_OUTPUTS_STAGED=$($stagedRuntime -join '; ')"
  }
}

function Invoke-Phase160LJsonScript {
  param([string]$Root, [string]$ScriptPath, [string[]]$Arguments = @())
  $scriptFull = Resolve-Phase160LValidatePath -Root $Root -Path $ScriptPath
  $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File $scriptFull -RepoRoot $Root @Arguments 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160L_VALIDATE_SCRIPT_FAILED=$ScriptPath output=$($output -join ' | ')"
  }
  return ($output -join "`n") | ConvertFrom-Json
}

$resolvedRoot = Resolve-Phase160LValidateRepoRoot -RepoRootParameter $RepoRoot
$pushed = $false

try {
  Push-Location $resolvedRoot
  $pushed = $true

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160LValidatePath -Root $resolvedRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $branchBefore = (git branch --show-current).Trim()
  $headBefore = (git rev-parse --short HEAD).Trim()
  $headFullBefore = (git rev-parse HEAD).Trim()
  $remoteBefore = Get-Phase160LValidateRemoteHeadSafe -Branch $branchBefore
  $protectedPaths = @("TASK_QUEUE.json", "GENESIS_STATE.json", "CAPABILITY_ROADMAP.json", "packs/registry.json", "orchestrator/run.ps1")
  $protectedBefore = Get-Phase160LValidateFileHashes -Root $resolvedRoot -Paths $protectedPaths

  $newActiveLockPath = "route_locks/AGENT_BUILDER_NEXT_15_STEPS_LOCK_V3_PHASE161_BATCH_SCHOOL_PREP.md"
  $indexPath = "route_locks/ACTIVE_ROUTE_LOCK.json"
  $reportPath = "reports/self_development/PHASE160L_ROUTE_LOCK_SUPERSESSION_REPORT.md"
  $proofPath = "proofs/self_development/PHASE160L_ROUTE_LOCK_SUPERSESSION_PROOF.json"
  $routeRequestPath = "route_change_requests/PHASE160L_ROUTE_LOCK_SUPERSESSION_REQUEST.md"
  $touchedPs1 = @(
    "modules/inspect_builder_route_lock_status_001.ps1",
    "modules/inspect_builder_active_route_lock_001.ps1",
    "validators/validate_phase160l_route_lock_supersession_v1.ps1"
  )
  foreach ($path in $touchedPs1) {
    Assert-Phase160LValidateParserClean -Path (Resolve-Phase160LValidatePath -Root $resolvedRoot -Path $path)
  }

  $routeStatus = Invoke-Phase160LJsonScript -Root $resolvedRoot -ScriptPath "modules/inspect_builder_route_lock_status_001.ps1" -Arguments @("-NoWrite")
  $activeStatus = Invoke-Phase160LJsonScript -Root $resolvedRoot -ScriptPath "modules/inspect_builder_active_route_lock_001.ps1"
  $index = Read-Phase160LValidateJson -Root $resolvedRoot -Path $indexPath
  $proof = Read-Phase160LValidateJson -Root $resolvedRoot -Path $proofPath
  $activeText = Read-Phase160LValidateText -Root $resolvedRoot -Path $newActiveLockPath
  $reportText = Read-Phase160LValidateText -Root $resolvedRoot -Path $reportPath
  $routeRequestText = Read-Phase160LValidateText -Root $resolvedRoot -Path $routeRequestPath
  $oldV2Text = Read-Phase160LValidateText -Root $resolvedRoot -Path "AGENT_BUILDER_NEXT_15_STEPS_LOCK_V2_R2.md"
  $oldV3Text = Read-Phase160LValidateText -Root $resolvedRoot -Path "route_locks/AGENT_BUILDER_NEXT_15_STEPS_LOCK_V3_SELF_PACK_AUTHOR.md"
  $oldV1Text = Read-Phase160LValidateText -Root $resolvedRoot -Path "reports/planning/AGENT_BUILDER_NEXT_15_STEPS_LOCK_V1.md"

  Assert-Phase160LValidateTrue -Actual ([bool]$routeStatus.old_route_lock_superseded) -Name "old_route_lock_superseded"
  Assert-Phase160LValidateTrue -Actual ([bool]$routeStatus.exactly_one_active_route_lock) -Name "exactly_one_active_route_lock"
  Assert-Phase160LValidateEquals -Actual ([string]$routeStatus.active_route_lock_file) -Expected $newActiveLockPath -Name "active_route_lock_file"
  Assert-Phase160LValidateEquals -Actual ([string]$activeStatus.active_route_lock_file) -Expected $newActiveLockPath -Name "active_inspector_file"
  Assert-Phase160LValidateEquals -Actual ([string]$activeStatus.declared_status) -Expected "ACTIVE_ROUTE_LOCK" -Name "new_lock_declared_status"
  Assert-Phase160LValidateEquals -Actual ([string]$index.active_route_lock_file) -Expected $newActiveLockPath -Name "index_active_file"
  Assert-Phase160LValidateEquals -Actual ([string]$index.active_route_lock_status) -Expected "ACTIVE_ROUTE_LOCK" -Name "index_active_status"
  Assert-Phase160LValidateEquals -Actual ([string]$index.next_target_phase) -Expected "PHASE161_BATCH_SCHOOL_FOUNDATION" -Name "index_next_target_phase"
  Assert-Phase160LValidateTrue -Actual ([bool]$index.owner_approval_required_for_route_change) -Name "index_owner_approval"
  Assert-Phase160LValidateTrue -Actual ([bool]$index.no_silent_route_change) -Name "index_no_silent_route_change"
  Assert-Phase160LValidateEquals -Actual ([string]$index.route_baseline_head) -Expected $headFullBefore -Name "index_route_baseline_head_current"
  Assert-Phase160LValidateEquals -Actual ([string]$index.owner_accepted_baseline_head) -Expected "dae5450" -Name "index_owner_accepted_head"

  foreach ($needle in @(
    "status: ACTIVE_ROUTE_LOCK",
    "baseline_head_expected: dae5450 or later current HEAD detected by validator",
    "active_line: AGENT_BUILDER_SELF_DEVELOPMENT",
    "strategic_target: PHASE161_BATCH_SCHOOL_FOUNDATION",
    "route_principle: no single-symptom repair; batch readiness first"
  )) {
    if ($activeText.IndexOf($needle, [System.StringComparison]::Ordinal) -lt 0) {
      throw "PHASE160L_VALIDATE_ACTIVE_LOCK_TOKEN_MISSING=$needle"
    }
  }

  $stepCount = @([regex]::Matches($activeText, "(?m)^\s*\d+\.\s+\S.+$")).Count
  Assert-Phase160LValidateTrue -Actual ($stepCount -ge 10 -and $stepCount -le 15) -Name "active_lock_10_to_15_steps"
  foreach ($requiredStepToken in @(
    "PHASE160K_LIVE_QUALITY_CONSISTENCY_RECHECK",
    "PHASE160L_ROUTE_LOCK_STATUS_SURFACE",
    "PHASE161_CURRICULUM_PACK_SCHEMA",
    "PHASE161_LESSON_TASK_BATCH_INTAKE_FORMAT",
    "PHASE161_SESSION_LOCAL_BATCH_RUNNER_LOOP",
    "PHASE161_FAILURE_CLUSTERING",
    "PHASE161_MORNING_REVIEW_REPORT",
    "PHASE161_LESSON_RETRY_REVISION_LOOP",
    "PHASE161_OWNER_PROGRAM_INTERNAL_CURRICULUM_PRIORITY_RULES",
    "PHASE161_NO_PROGRAM_SELF_DEVELOPMENT_ROUTE_SELECTION",
    "PHASE161_OVERNIGHT_STOP_ARCHIVE_CLEAN_PROTOCOL",
    "PHASE161_LIVE_BATCH_SCHOOL_SMOKE_TEST",
    "PHASE161_ROUTE_LOCK_EXHAUSTION_DETECTION",
    "PHASE162_ROUTE_LOCK_GENERATION_REQUEST"
  )) {
    if ($activeText.IndexOf($requiredStepToken, [System.StringComparison]::Ordinal) -lt 0) {
      throw "PHASE160L_VALIDATE_REQUIRED_STEP_MISSING=$requiredStepToken"
    }
  }

  if ($oldV2Text -match "(?im)^\s*Status\s*:\s*ACTIVE_ROUTE_LOCK\s*$") {
    throw "PHASE160L_VALIDATE_OLD_V2_STILL_ACTIVE"
  }
  if ($oldV3Text -match "(?im)^\s*status\s*:\s*ACTIVE_ROUTE_LOCK\s*$") {
    throw "PHASE160L_VALIDATE_OLD_V3_STILL_ACTIVE"
  }
  if ($oldV1Text -match "(?im)^\s*Status\s*:\s*ACTIVE_ROUTE_LOCK\s*$") {
    throw "PHASE160L_VALIDATE_OLD_V1_STILL_ACTIVE"
  }
  foreach ($oldText in @($oldV2Text, $oldV3Text)) {
    if ($oldText.IndexOf("SUPERSEDED_BY_PHASE160L_ROUTE_LOCK_SUPERSESSION_REPAIR", [System.StringComparison]::Ordinal) -lt 0) {
      throw "PHASE160L_VALIDATE_OLD_LOCK_SUPERSESSION_MARKER_MISSING"
    }
  }
  if ($oldV1Text.IndexOf("Status: ARCHIVED_REFERENCE", [System.StringComparison]::Ordinal) -lt 0) {
    throw "PHASE160L_VALIDATE_OLD_V1_ARCHIVE_MARKER_MISSING"
  }

  foreach ($reportNeedle in @("Old Lock Classification", "why old lock is superseded", "PHASE161_BATCH_SCHOOL_FOUNDATION", "What Is Not Being Built Yet", "How Owner Verifies")) {
    if ($reportText.IndexOf($reportNeedle, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
      throw "PHASE160L_VALIDATE_REPORT_TOKEN_MISSING=$reportNeedle"
    }
  }
  if ($routeRequestText.IndexOf("PHASE161_BATCH_SCHOOL_FOUNDATION", [System.StringComparison]::Ordinal) -lt 0) {
    throw "PHASE160L_VALIDATE_ROUTE_REQUEST_MISSING_PHASE161"
  }
  Assert-Phase160LValidateTrue -Actual ([bool]$proof.old_route_lock_superseded) -Name "proof_old_superseded"
  Assert-Phase160LValidateTrue -Actual ([bool]$proof.exactly_one_active_route_lock) -Name "proof_exactly_one_active"
  Assert-Phase160LValidateEquals -Actual ([string]$proof.new_active_route_lock) -Expected $newActiveLockPath -Name "proof_new_active_lock"
  Assert-Phase160LValidateEquals -Actual ([int]$proof.locked_step_count) -Expected $stepCount -Name "proof_step_count"

  $protectedAfter = Get-Phase160LValidateFileHashes -Root $resolvedRoot -Paths $protectedPaths
  foreach ($path in $protectedPaths) {
    Assert-Phase160LValidateEquals -Actual $protectedAfter[$path] -Expected $protectedBefore[$path] -Name "protected_state_hash_$path"
  }
  $protectedStatus = @(git status --short --untracked-files=all -- TASK_QUEUE.json GENESIS_STATE.json CAPABILITY_ROADMAP.json packs/registry.json orchestrator/run.ps1 2>$null)
  Assert-Phase160LValidateEquals -Actual $protectedStatus.Count -Expected 0 -Name "protected_state_status_clean"
  Assert-Phase160LRuntimeOutputsNotStaged

  $branchAfter = (git branch --show-current).Trim()
  $headAfter = (git rev-parse --short HEAD).Trim()
  $remoteAfter = Get-Phase160LValidateRemoteHeadSafe -Branch $branchAfter
  Assert-Phase160LValidateEquals -Actual $branchAfter -Expected $branchBefore -Name "branch_unchanged"
  Assert-Phase160LValidateEquals -Actual $headAfter -Expected $headBefore -Name "head_unchanged_no_commit"
  Assert-Phase160LValidateEquals -Actual $remoteAfter -Expected $remoteBefore -Name "remote_head_unchanged_no_push"

  Write-Host "PHASE160L_ROUTE_LOCK_SUPERSESSION_VALIDATE_RESULT=PASS"
  Write-Host "OLD_ROUTE_LOCK_SUPERSEDED=True"
  Write-Host "EXACTLY_ONE_ACTIVE_ROUTE_LOCK=True"
  Write-Host "NEW_ACTIVE_ROUTE_LOCK_CREATED=True"
  Write-Host "ACTIVE_ROUTE_LOCK_POINTS_TO_PHASE161=True"
  Write-Host "ACTIVE_ROUTE_LOCK_HAS_10_TO_15_STEPS=True"
  Write-Host "ACTIVE_ROUTE_LOCK_INDEX_CREATED=True"
  Write-Host "NO_SILENT_ROUTE_CHANGE=True"
  Write-Host "REPORT_CREATED=True"
  Write-Host "PROOF_CREATED=True"
  Write-Host "ROUTE_REQUEST_CREATED=True"
  Write-Host "NO_PROTECTED_STATE_MUTATION=True"
  Write-Host "RUNTIME_OUTPUTS_STAGED=False"
  Write-Host "NO_COMMIT_PERFORMED=True"
  Write-Host "NO_PUSH_PERFORMED=True"
  Write-Host "NO_BRANCH_SWITCH=True"
} catch {
  Write-Host "PHASE160L_ROUTE_LOCK_SUPERSESSION_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE160L_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  if ($pushed) {
    Pop-Location
  }
}
