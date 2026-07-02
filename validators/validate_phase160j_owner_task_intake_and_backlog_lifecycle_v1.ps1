param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160JValidatePath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160JValidateRepoRoot {
  param([string]$RepoRootParameter)
  if (-not [string]::IsNullOrWhiteSpace($RepoRootParameter) -and $RepoRootParameter -ne ".") {
    return Normalize-Phase160JValidatePath -Path $RepoRootParameter
  }
  $scriptRoot = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRoot) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRoot = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
    throw "PHASE160J_VALIDATE_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160JValidatePath -Path (Join-Path $scriptRoot "..")
}

function Resolve-Phase160JValidatePath {
  param([string]$Root, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $Root $Path))
}

function ConvertTo-Phase160JValidateRelativePath {
  param([string]$Root, [string]$FullPath)
  $rootFull = Normalize-Phase160JValidatePath -Path $Root
  $pathFull = Normalize-Phase160JValidatePath -Path $FullPath
  if ($pathFull -eq $rootFull) {
    return "."
  }
  if (-not $pathFull.StartsWith($rootFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "PHASE160J_VALIDATE_PATH_OUTSIDE_REPO=$FullPath"
  }
  return ($pathFull.Substring($rootFull.Length + 1) -replace "\\", "/")
}

function Assert-Phase160JValidatePathInside {
  param([string]$Root, [string]$Path)
  $rootFull = Normalize-Phase160JValidatePath -Path $Root
  $pathFull = Normalize-Phase160JValidatePath -Path (Resolve-Phase160JValidatePath -Root $Root -Path $Path)
  if (-not ($pathFull -eq $rootFull -or $pathFull.StartsWith($rootFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase))) {
    throw "PHASE160J_VALIDATE_PATH_OUTSIDE_REPO=$Path"
  }
  return $pathFull
}

function Write-Phase160JValidateJsonFile {
  param([string]$Path, [object]$Object, [int]$Depth = 100)
  $directory = Split-Path -Path $Path -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  $json = ($Object | ConvertTo-Json -Depth $Depth) -replace "`r`n", "`n"
  if (-not $json.EndsWith("`n")) {
    $json += "`n"
  }
  [System.IO.File]::WriteAllText($Path, $json, [System.Text.UTF8Encoding]::new($false))
}

function Write-Phase160JValidateTextFile {
  param([string]$Path, [string]$Text)
  $directory = Split-Path -Path $Path -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  if (-not $Text.EndsWith("`n")) {
    $Text += "`n"
  }
  [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Read-Phase160JValidateJson {
  param([string]$Root, [string]$Path)
  $fullPath = Resolve-Phase160JValidatePath -Root $Root -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160J_VALIDATE_MISSING_JSON=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase160JValidateJsonSafeFull {
  param([string]$Path)
  try {
    if (-not (Test-Path -LiteralPath $Path)) {
      return $null
    }
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
  } catch {
    return $null
  }
}

function Assert-Phase160JValidateTrue {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $true) {
    throw "PHASE160J_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase160JValidateFalse {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $false) {
    throw "PHASE160J_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase160JValidateEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160J_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase160JValidateContains {
  param([object[]]$Values, [string]$Expected, [string]$Name)
  if (@($Values | Where-Object { [string]$_ -eq $Expected }).Count -lt 1) {
    throw "PHASE160J_VALIDATE_MISSING_VALUE=$Name expected=$Expected"
  }
}

function Assert-Phase160JValidateParserClean {
  param([string]$Path)
  $tokens = $null
  $parseErrors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors) | Out-Null
  if ($parseErrors.Count -gt 0) {
    throw "PHASE160J_VALIDATE_PARSE_ERROR=$Path message=$($parseErrors[0].Message)"
  }
}

function Get-Phase160JValidateFileHashes {
  param([string]$Root, [string[]]$Paths)
  $hashes = @{}
  foreach ($path in $Paths) {
    $fullPath = Resolve-Phase160JValidatePath -Root $Root -Path $path
    if (Test-Path -LiteralPath $fullPath) {
      $hashes[$path] = (Get-FileHash -LiteralPath $fullPath -Algorithm SHA256).Hash
    } else {
      $hashes[$path] = "MISSING"
    }
  }
  return $hashes
}

function Get-Phase160JValidateRemoteHeadSafe {
  param([string]$Branch)
  $remoteHead = (git rev-parse --short "origin/$Branch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    return "UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Remove-Phase160JValidateOutput {
  param([string]$Root, [string]$Path)
  $fullPath = Assert-Phase160JValidatePathInside -Root $Root -Path $Path
  $relative = ConvertTo-Phase160JValidateRelativePath -Root $Root -FullPath $fullPath
  if (-not ($relative -match "^runtime_sessions/live_growth/PHASE160J_")) {
    throw "PHASE160J_VALIDATE_REFUSE_DELETE=$relative"
  }
  if (Test-Path -LiteralPath $fullPath) {
    Remove-Item -LiteralPath $fullPath -Recurse -Force
  }
}

function Invoke-Phase160JValidateScriptJson {
  param([string]$Root, [string]$ScriptPath, [string[]]$Arguments)
  $scriptFull = Resolve-Phase160JValidatePath -Root $Root -Path $ScriptPath
  $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File $scriptFull @Arguments 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160J_VALIDATE_SCRIPT_FAILED script=$ScriptPath output=$($output -join ' | ')"
  }
  return ($output -join "`n") | ConvertFrom-Json
}

function Invoke-Phase160JValidateScriptText {
  param([string]$Root, [string]$ScriptPath, [string[]]$Arguments)
  $scriptFull = Resolve-Phase160JValidatePath -Root $Root -Path $ScriptPath
  $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File $scriptFull @Arguments 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160J_VALIDATE_SCRIPT_FAILED script=$ScriptPath output=$($output -join ' | ')"
  }
  return $output
}

function New-Phase160JValidateSessionFixture {
  param([string]$Root, [string]$SessionRoot, [string]$RunId, [string]$Branch, [string]$Head)
  Remove-Phase160JValidateOutput -Root $Root -Path $SessionRoot
  $sessionFull = Resolve-Phase160JValidatePath -Root $Root -Path $SessionRoot
  foreach ($directory in @(
    $sessionFull,
    (Join-Path $sessionFull "teacher_inbox"),
    (Join-Path $sessionFull "teacher_outbox"),
    (Join-Path $sessionFull "teacher_digest"),
    (Join-Path $sessionFull "teacher_consumed"),
    (Join-Path $sessionFull "teacher_quarantine"),
    (Join-Path $sessionFull "task_backlog"),
    (Join-Path $sessionFull "active_task"),
    (Join-Path $sessionFull "task_lifecycle"),
    (Join-Path $sessionFull "candidate_workspace/candidate_bundles"),
    (Join-Path $sessionFull "candidate_workspace/candidate_queue"),
    (Join-Path $sessionFull "promotion_bundle"),
    (Join-Path $sessionFull "blocker_queue")
  )) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  Write-Phase160JValidateJsonFile -Path (Join-Path $sessionFull "run_manifest.json") -Object ([ordered]@{
    run_manifest_status = "PASS"
    run_id = $RunId
    branch = $Branch
    run_head = $Head
    current_head = $Head
    head_match = $true
    commit_allowed = $false
    push_allowed = $false
    branch_switch_allowed = $false
    protected_state_mutation_allowed = $false
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Write-Phase160JValidateJsonFile -Path (Join-Path $sessionFull "runtime_guard.json") -Object ([ordered]@{
    status = "PASS"
    run_id = $RunId
    run_head = $Head
    current_head = $Head
    head_match = $true
    candidate_production_enabled = $true
    allowed_runtime_output_count = 0
    allowed_tracked_runtime_sample_change = $false
    unsafe_tracked_code_mutation_count = 0
    protected_state_mutation_count = 0
    blocked_reasons = @()
    checked_at = (Get-Date).ToUniversalTime().ToString("o")
  })
}

function New-Phase160JValidateSafeOwnerTask {
  param([string]$TaskId)
  return [ordered]@{
    event_type = "owner_live_task_injection"
    task_id = $TaskId
    source = "owner"
    priority = "high"
    owner_goal = "Repair owner task intake and backlog lifecycle without accepted repo mutation."
    desired_next_gap = "OWNER_TASK_INTAKE_BACKLOG_REPAIR_GAP"
    expected_outputs = @("normalized owner task", "backlog lifecycle evidence")
    safety_rules = [ordered]@{
      repo_commit_allowed = $false
      repo_push_allowed = $false
      branch_switch_allowed = $false
      live_repo_file_mutation_allowed = $false
      protected_state_mutation_allowed = $false
      accepted_repo_mutation_allowed = $false
      runtime_session_only = $true
      owner_promotion_required = $true
    }
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  }
}

function Write-Phase160JValidateInboxTask {
  param([string]$Root, [string]$SessionRoot, [string]$FileName, [object]$Task)
  $path = Resolve-Phase160JValidatePath -Root $Root -Path (Join-Path $SessionRoot "teacher_inbox/$FileName")
  Write-Phase160JValidateJsonFile -Path $path -Object $Task
}

function Invoke-Phase160JValidateDuty {
  param([string]$Root, [string]$SessionRoot, [int]$DutyIndex = 1)
  return Invoke-Phase160JValidateScriptJson -Root $Root -ScriptPath "modules/invoke_builder_live_self_growth_duty_step_001.ps1" -Arguments @(
    "-SessionRoot", $SessionRoot,
    "-DutyIndex", [string]$DutyIndex,
    "-TickNumber", [string]$DutyIndex,
    "-MaxCandidateBytes", "8192"
  )
}

function New-Phase160JValidateCandidatePayload {
  param([string]$CandidateId, [bool]$Unsafe = $false, [bool]$Placeholder = $false)
  if ($Placeholder) {
    return "placeholder payload for $CandidateId"
  }
  $unsafeLine = if ($Unsafe) { "`n`ngit commit -m `"unsafe candidate mutation request`"`n" } else { "" }
  return @"
param(
  [string]`$InputPath = "",
  [string]`$OutputPath = ""
)

`$ErrorActionPreference = "Stop"

function Invoke-Phase160JCandidateFixturePayload {
  param([string]`$CandidateId)
  `$signals = @(
    "real_module_payload_executed",
    "candidate_validation_plan_required",
    "owner_promotion_gate_required",
    "runtime_session_only"
  )
  return [ordered]@{
    status = "PASS"
    candidate_id = `$CandidateId
    signals = `$signals
    accepted_code_written = `$false
    repo_mutation_performed = `$false
  }
}

Invoke-Phase160JCandidateFixturePayload -CandidateId "$CandidateId" | ConvertTo-Json -Depth 20
$unsafeLine
"@
}

function New-Phase160JValidateValidatorPayload {
  param([string]$CandidateId, [string]$ModuleTarget)
  return @"
param(
  [string]`$RepoRoot = "."
)

`$ErrorActionPreference = "Stop"

function Assert-Phase160JCandidateFixtureTrue {
  param([object]`$Actual, [string]`$Name)
  if (`$Actual -ne `$true) {
    throw "PHASE160J_CANDIDATE_FIXTURE_FLAG_NOT_TRUE=`$Name actual=`$Actual"
  }
}

Assert-Phase160JCandidateFixtureTrue -Actual `$true -Name "candidate_fixture_validator_parseable"
Write-Host "PHASE160J_CANDIDATE_FIXTURE_VALIDATE_RESULT=PASS"
"@
}

function New-Phase160JValidateCandidateFixture {
  param(
    [string]$Root,
    [string]$SessionRoot,
    [string]$CandidateId,
    [string]$ModuleTarget,
    [bool]$Unsafe = $false,
    [bool]$Placeholder = $false
  )
  $sessionFull = Resolve-Phase160JValidatePath -Root $Root -Path $SessionRoot
  $candidateDir = Join-Path $sessionFull "candidate_workspace/candidate_bundles/$CandidateId"
  New-Item -ItemType Directory -Force -Path (Join-Path $candidateDir "proposed_patch_or_file_payloads/modules"), (Join-Path $candidateDir "proposed_patch_or_file_payloads/validators") | Out-Null
  $validatorTarget = "validators/validate_$CandidateId`_v1.ps1"
  $modulePayloadPath = "proposed_patch_or_file_payloads/modules/$([System.IO.Path]::GetFileName($ModuleTarget))"
  $validatorPayloadPath = "proposed_patch_or_file_payloads/validators/$([System.IO.Path]::GetFileName($validatorTarget))"
  Write-Phase160JValidateTextFile -Path (Join-Path $candidateDir $modulePayloadPath) -Text (New-Phase160JValidateCandidatePayload -CandidateId $CandidateId -Unsafe $Unsafe -Placeholder $Placeholder)
  Write-Phase160JValidateTextFile -Path (Join-Path $candidateDir $validatorPayloadPath) -Text (New-Phase160JValidateValidatorPayload -CandidateId $CandidateId -ModuleTarget $ModuleTarget)
  Write-Phase160JValidateJsonFile -Path (Join-Path $candidateDir "candidate_manifest.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = $CandidateId
    source_task_id = "PHASE160J_QUALITY_COMPAT_TASK"
    source = "owner_task"
    source_plan_item_id = "NONE"
    created_from_run_head = "fixture"
    run_id = Split-Path -Path $SessionRoot -Leaf
    owner_goal = "PHASE160J quality compatibility candidate."
    desired_next_gap = "QUALITY_GATE_COMPATIBILITY"
    proposed_file_paths = @($ModuleTarget)
    proposed_validator_paths = @($validatorTarget)
    proposed_payload_paths = @($modulePayloadPath, $validatorPayloadPath)
    owner_approval_required = $true
    owner_promotion_gate_required = $true
    candidate_output_is_not_accepted_code = $true
    repo_mutation_performed = $false
    commit_performed = $false
    push_performed = $false
    branch_switch_performed = $false
    protected_state_mutated = $false
    decision = "CANDIDATE_DRAFT"
    quality_gate_enabled = $true
    owner_promotion_allowed = $false
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Write-Phase160JValidateJsonFile -Path (Join-Path $candidateDir "proposed_files.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = $CandidateId
    proposed_file_paths = @($ModuleTarget)
    proposed_validator_paths = @($validatorTarget)
    proposed_payloads = @(
      [ordered]@{ kind = "module"; target_path = $ModuleTarget; payload_path = $modulePayloadPath; parse_required = $true; required = $true },
      [ordered]@{ kind = "validator"; target_path = $validatorTarget; payload_path = $validatorPayloadPath; parse_required = $true; required = $true }
    )
    accepted_code_written = $false
  })
  Write-Phase160JValidateJsonFile -Path (Join-Path $candidateDir "candidate_validation_plan.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = $CandidateId
    validators_required_before_acceptance = @($validatorTarget)
    materialization_parse_check_required = $true
    owner_review_required = $true
  })
  Write-Phase160JValidateJsonFile -Path (Join-Path $candidateDir "candidate_risk_review.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = $CandidateId
    accepted_state_mutated = $false
    repo_mutation_performed = $false
  })
  Write-Phase160JValidateJsonFile -Path (Join-Path $candidateDir "candidate_status.json") -Object ([ordered]@{
    status = "CANDIDATE_DRAFT"
    quality_status = "CANDIDATE_DRAFT"
    candidate_id = $CandidateId
    owner_promotion_allowed = $false
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  return ConvertTo-Phase160JValidateRelativePath -Root $Root -FullPath $candidateDir
}

function Assert-Phase160JRuntimeOutputsNotStaged {
  $stagedRuntime = @(git diff --cached --name-only -- runtime_sessions)
  if ($stagedRuntime.Count -gt 0) {
    throw "PHASE160J_VALIDATE_RUNTIME_OUTPUTS_STAGED=$($stagedRuntime -join '; ')"
  }
}

$resolvedRoot = Resolve-Phase160JValidateRepoRoot -RepoRootParameter $RepoRoot
$pushed = $false

try {
  Push-Location $resolvedRoot
  $pushed = $true

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160JValidatePath -Root $resolvedRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $branchBefore = (git branch --show-current).Trim()
  $headBefore = (git rev-parse --short HEAD).Trim()
  $remoteBefore = Get-Phase160JValidateRemoteHeadSafe -Branch $branchBefore
  $runStamp = Get-Date -Format "yyyyMMddHHmmssfff"
  $protectedPaths = @("TASK_QUEUE.json", "GENESIS_STATE.json", "CAPABILITY_ROADMAP.json", "packs/registry.json", "orchestrator/run.ps1")
  $protectedBefore = Get-Phase160JValidateFileHashes -Root $resolvedRoot -Paths $protectedPaths

  $touchedPs1 = @(
    "modules/normalize_builder_owner_live_task_001.ps1",
    "modules/classify_builder_owner_live_task_safety_001.ps1",
    "modules/enqueue_builder_owner_task_backlog_001.ps1",
    "modules/promote_builder_backlog_task_to_active_001.ps1",
    "modules/inspect_builder_owner_task_lifecycle_state_001.ps1",
    "modules/invoke_builder_live_self_growth_duty_step_001.ps1",
    "modules/invoke_builder_candidate_workspace_step_001.ps1",
    "modules/start_builder_live_growth_daemon_001.ps1",
    "modules/watch_builder_live_console_001.ps1",
    "modules/watch_builder_live_growth_session_observer_001.ps1",
    "validators/validate_phase160j_owner_task_intake_and_backlog_lifecycle_v1.ps1"
  )
  foreach ($path in $touchedPs1) {
    Assert-Phase160JValidateParserClean -Path (Resolve-Phase160JValidatePath -Root $resolvedRoot -Path $path)
  }

  . (Resolve-Phase160JValidatePath -Root $resolvedRoot -Path "modules/normalize_builder_owner_live_task_001.ps1")
  . (Resolve-Phase160JValidatePath -Root $resolvedRoot -Path "modules/classify_builder_owner_live_task_safety_001.ps1")
  . (Resolve-Phase160JValidatePath -Root $resolvedRoot -Path "modules/inspect_builder_owner_task_lifecycle_state_001.ps1")

  $safeTask = New-Phase160JValidateSafeOwnerTask -TaskId "PHASE160J_SAFE_OWNER_WITH_RULES_001"
  $safeNormalized = ConvertTo-Phase160JOwnerLiveTaskNormalized -Task ([pscustomobject]$safeTask) -ContentHash "safeowner000001" -RawFileName "safe.json"
  $safeClassification = Invoke-Phase160JOwnerTaskSafetyClassification -Task ([pscustomobject]$safeTask) -NormalizedTask $safeNormalized
  Assert-Phase160JValidateFalse -Actual ([bool]$safeClassification.quarantine_required) -Name "safe_owner_task_not_quarantined"
  Assert-Phase160JValidateContains -Values @("ACCEPT_SAFE_OWNER_TASK", "BACKLOG_SAFE_OWNER_TASK") -Expected ([string]$safeClassification.decision) -Name "safe_owner_task_decision_allowed"
  Assert-Phase160JValidateFalse -Actual ([string]$safeClassification.quarantine_reason -eq "unsafe_live_task_safety_rules") -Name "safe_owner_not_generic_quarantine"

  $unsafeCommitTask = New-Phase160JValidateSafeOwnerTask -TaskId "PHASE160J_UNSAFE_COMMIT_001"
  $unsafeCommitTask.safety_rules["repo_commit_allowed"] = $true
  $unsafeCommitNormalized = ConvertTo-Phase160JOwnerLiveTaskNormalized -Task ([pscustomobject]$unsafeCommitTask) -ContentHash "unsafecommit001" -RawFileName "unsafe_commit.json"
  $unsafeCommitClassification = Invoke-Phase160JOwnerTaskSafetyClassification -Task ([pscustomobject]$unsafeCommitTask) -NormalizedTask $unsafeCommitNormalized
  Assert-Phase160JValidateEquals -Actual ([string]$unsafeCommitClassification.decision) -Expected "QUARANTINE_UNSAFE_OWNER_TASK" -Name "unsafe_commit_decision"
  Assert-Phase160JValidateEquals -Actual ([string]$unsafeCommitClassification.quarantine_reason) -Expected "unsafe_commit_allowed" -Name "unsafe_commit_reason"
  Assert-Phase160JValidateFalse -Actual ([bool]$unsafeCommitClassification.backlog_allowed) -Name "unsafe_commit_not_backlog_allowed"

  $unsafeProtectedTask = New-Phase160JValidateSafeOwnerTask -TaskId "PHASE160J_UNSAFE_PROTECTED_001"
  $unsafeProtectedTask.safety_rules["protected_state_mutation_allowed"] = $true
  $unsafeProtectedNormalized = ConvertTo-Phase160JOwnerLiveTaskNormalized -Task ([pscustomobject]$unsafeProtectedTask) -ContentHash "unsafeprotect1" -RawFileName "unsafe_protected.json"
  $unsafeProtectedClassification = Invoke-Phase160JOwnerTaskSafetyClassification -Task ([pscustomobject]$unsafeProtectedTask) -NormalizedTask $unsafeProtectedNormalized
  Assert-Phase160JValidateEquals -Actual ([string]$unsafeProtectedClassification.quarantine_reason) -Expected "unsafe_protected_state_mutation_allowed" -Name "unsafe_protected_reason"

  $normalizationResultPath = Resolve-Phase160JValidatePath -Root $resolvedRoot -Path "reports/self_development/owner_task_intake_normalization_result.json"
  Write-Phase160JValidateJsonFile -Path $normalizationResultPath -Object ([ordered]@{
    status = "PASS"
    accepted_shapes = @("owner_goal_only", "owner_goal_expected_outputs", "owner_goal_safety_rules", "owner_goal_plan_items", "curriculum_program")
    safe_owner_task_normalized = $safeNormalized
    unsafe_commit_task_normalized = $unsafeCommitNormalized
    unsafe_protected_task_normalized = $unsafeProtectedNormalized
    generic_unsafe_safety_rules_false_quarantine_removed = $true
  })
  $classificationResultPath = Resolve-Phase160JValidatePath -Root $resolvedRoot -Path "reports/self_development/owner_task_safety_classification_result.json"
  Write-Phase160JValidateJsonFile -Path $classificationResultPath -Object ([ordered]@{
    status = "PASS"
    safe_owner_task_decision = [string]$safeClassification.decision
    unsafe_commit_task_decision = [string]$unsafeCommitClassification.decision
    unsafe_commit_reason = [string]$unsafeCommitClassification.quarantine_reason
    unsafe_protected_task_decision = [string]$unsafeProtectedClassification.decision
    unsafe_protected_reason = [string]$unsafeProtectedClassification.quarantine_reason
    generic_unsafe_live_task_safety_rules_used = $false
  })

  $activeBacklogSession = "runtime_sessions/live_growth/PHASE160J_ACTIVE_INTERNAL_BACKLOG_001_$runStamp"
  New-Phase160JValidateSessionFixture -Root $resolvedRoot -SessionRoot $activeBacklogSession -RunId "PHASE160J_ACTIVE_INTERNAL_BACKLOG_001_$runStamp" -Branch $branchBefore -Head $headBefore
  $activeBacklogFull = Resolve-Phase160JValidatePath -Root $resolvedRoot -Path $activeBacklogSession
  Write-Phase160JValidateJsonFile -Path (Join-Path $activeBacklogFull "active_task/active_task.json") -Object ([ordered]@{
    status = "ACTIVE"
    task_id = "PHASE160J_INTERNAL_ACTIVE_TASK_001"
    source = "internal_self_selected_goal"
    owner_goal = "Internal active task must remain active while owner task waits."
    desired_next_gap = "SELF_INITIATED_USEFUL_GOAL_SELECTION"
    internal_goal_id = "PHASE160J_INTERNAL_GOAL"
    internal_goal_name = "internal useful goal"
    active_owner_task = $false
    selected_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Write-Phase160JValidateJsonFile -Path (Join-Path $activeBacklogFull "task_lifecycle/active_task_state.json") -Object ([ordered]@{
    status = "WAITING_OWNER_PROMOTION"
    source = "internal_self_selected_goal"
    active_task_id = "PHASE160J_INTERNAL_ACTIVE_TASK_001"
    updated_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Write-Phase160JValidateInboxTask -Root $resolvedRoot -SessionRoot $activeBacklogSession -FileName "safe_owner_backlog.json" -Task (New-Phase160JValidateSafeOwnerTask -TaskId "PHASE160J_SAFE_OWNER_BACKLOG_001")
  $activeBacklogDuty = Invoke-Phase160JValidateDuty -Root $resolvedRoot -SessionRoot $activeBacklogSession
  $activeBacklogRecord = Read-Phase160JValidateJson -Root $resolvedRoot -Path "$activeBacklogSession/task_backlog/PHASE160J_SAFE_OWNER_BACKLOG_001.json"
  $activeTaskAfterBacklog = Read-Phase160JValidateJson -Root $resolvedRoot -Path "$activeBacklogSession/active_task/active_task.json"
  $ownerLifecycleBacklog = Get-Phase160JOwnerTaskLifecycleState -SessionRootFull $activeBacklogFull
  Assert-Phase160JValidateEquals -Actual ([string]$activeBacklogRecord.backlog_status) -Expected "BACKLOG_WAITING_ACTIVE_SLOT" -Name "safe_owner_backlog_status"
  Assert-Phase160JValidateEquals -Actual ([string]$activeTaskAfterBacklog.task_id) -Expected "PHASE160J_INTERNAL_ACTIVE_TASK_001" -Name "active_internal_task_retained"
  Assert-Phase160JValidateTrue -Actual ([int]$ownerLifecycleBacklog.owner_task_backlog_count -gt 0) -Name "owner_backlog_count_positive"
  Assert-Phase160JValidateFalse -Actual ([bool]$ownerLifecycleBacklog.owner_task_lost) -Name "owner_task_not_lost_behind_active"

  $noActiveSession = "runtime_sessions/live_growth/PHASE160J_NO_ACTIVE_ACCEPT_001_$runStamp"
  New-Phase160JValidateSessionFixture -Root $resolvedRoot -SessionRoot $noActiveSession -RunId "PHASE160J_NO_ACTIVE_ACCEPT_001_$runStamp" -Branch $branchBefore -Head $headBefore
  Write-Phase160JValidateInboxTask -Root $resolvedRoot -SessionRoot $noActiveSession -FileName "safe_owner_active.json" -Task (New-Phase160JValidateSafeOwnerTask -TaskId "PHASE160J_SAFE_OWNER_ACTIVE_001")
  $noActiveDuty = Invoke-Phase160JValidateDuty -Root $resolvedRoot -SessionRoot $noActiveSession -DutyIndex 2
  $activeOwnerTask = Read-Phase160JValidateJson -Root $resolvedRoot -Path "$noActiveSession/active_task/active_task.json"
  Assert-Phase160JValidateEquals -Actual ([string]$activeOwnerTask.task_id) -Expected "PHASE160J_SAFE_OWNER_ACTIVE_001" -Name "no_active_accepts_owner_task"
  Assert-Phase160JValidateTrue -Actual ([bool]$activeOwnerTask.active_owner_task) -Name "active_owner_task_true"

  $malformedSession = "runtime_sessions/live_growth/PHASE160J_MALFORMED_001_$runStamp"
  New-Phase160JValidateSessionFixture -Root $resolvedRoot -SessionRoot $malformedSession -RunId "PHASE160J_MALFORMED_001_$runStamp" -Branch $branchBefore -Head $headBefore
  $malformedPath = Resolve-Phase160JValidatePath -Root $resolvedRoot -Path "$malformedSession/teacher_inbox/malformed.json"
  Write-Phase160JValidateTextFile -Path $malformedPath -Text "{ this is malformed json"
  $malformedDuty = Invoke-Phase160JValidateDuty -Root $resolvedRoot -SessionRoot $malformedSession -DutyIndex 3
  $malformedQuarantine = @(Get-ChildItem -LiteralPath (Resolve-Phase160JValidatePath -Root $resolvedRoot -Path "$malformedSession/teacher_quarantine") -File -Filter "quarantine_*.json" | Select-Object -First 1)
  if ($malformedQuarantine.Count -lt 1) {
    throw "PHASE160J_VALIDATE_MALFORMED_QUARANTINE_MISSING"
  }
  $malformedRecord = Get-Content -LiteralPath $malformedQuarantine[0].FullName -Raw | ConvertFrom-Json
  Assert-Phase160JValidateEquals -Actual ([string]$malformedRecord.reason) -Expected "malformed_json" -Name "malformed_reason"

  $sourceSession = "runtime_sessions/live_growth/PHASE160J_SOURCE_ATTRIBUTION_001_$runStamp"
  New-Phase160JValidateSessionFixture -Root $resolvedRoot -SessionRoot $sourceSession -RunId "PHASE160J_SOURCE_ATTRIBUTION_001_$runStamp" -Branch $branchBefore -Head $headBefore
  $sourceFull = Resolve-Phase160JValidatePath -Root $resolvedRoot -Path $sourceSession
  Write-Phase160JValidateJsonFile -Path (Join-Path $sourceFull "active_task/active_task.json") -Object ([ordered]@{
    status = "ACTIVE"
    task_id = "PHASE160J_INTERNAL_SOURCE_TASK_001"
    source = "internal_self_selected_goal"
    owner_goal = "Build internal self-initiated useful goal candidate with truthful source attribution."
    desired_next_gap = "SELF_INITIATED_USEFUL_GOAL_SELECTION"
    internal_goal_id = "PHASE160J_INTERNAL_SOURCE_GOAL"
    internal_goal_name = "internal source attribution goal"
    expected_candidate_capabilities = @("SELF_INITIATED_USEFUL_GOAL_SELECTION", "candidate_bundle_creation", "runtime_guard_required")
    selected_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Write-Phase160JValidateJsonFile -Path (Join-Path $sourceFull "task_lifecycle/active_task_state.json") -Object ([ordered]@{
    status = "ACTIVE"
    source = "internal_self_selected_goal"
    active_task_id = "PHASE160J_INTERNAL_SOURCE_TASK_001"
    updated_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Write-Phase160JValidateJsonFile -Path (Join-Path $sourceFull "task_backlog/PHASE160J_BACKLOGGED_OWNER_SOURCE_TEST.json") -Object ([ordered]@{
    status = "BACKLOG"
    task_id = "PHASE160J_BACKLOGGED_OWNER_SOURCE_TEST"
    normalized_task_id = "PHASE160J_BACKLOGGED_OWNER_SOURCE_TEST"
    source = "owner"
    backlog_status = "BACKLOG_WAITING_ACTIVE_SLOT"
    blocked_by_active_task_id = "PHASE160J_INTERNAL_SOURCE_TASK_001"
    blocked_by_status = "ACTIVE"
    activation_conditions = @("active_task_slot_empty", "owner_promotion_or_restart_gate_required")
    owner_goal = "Backlogged owner task must not become internal candidate source."
    desired_next_gap = "OWNER_BACKLOG_SOURCE_TEST"
    priority = "high"
    plan_step_count = 0
    created_at = (Get-Date).ToUniversalTime().ToString("o")
    last_seen_at = (Get-Date).ToUniversalTime().ToString("o")
    attempts = 1
    next_action = "WAIT_FOR_ACTIVE_SLOT_AND_OWNER_PROMOTION_GATE"
  })
  $candidateWorkspace = Invoke-Phase160JValidateScriptJson -Root $resolvedRoot -ScriptPath "modules/invoke_builder_candidate_workspace_step_001.ps1" -Arguments @(
    "-SessionRoot", $sourceSession,
    "-RunId", "PHASE160J_SOURCE_ATTRIBUTION_001_$runStamp",
    "-DutyId", "duty_source",
    "-TickNumber", "1"
  )
  $promotionManifest = Read-Phase160JValidateJson -Root $resolvedRoot -Path "$sourceSession/promotion_bundle/promotion_manifest.json"
  Assert-Phase160JValidateContains -Values @($promotionManifest.source_tasks) -Expected "PHASE160J_INTERNAL_SOURCE_TASK_001" -Name "promotion_source_tasks_internal"
  Assert-Phase160JValidateFalse -Actual (@($promotionManifest.source_tasks | Where-Object { [string]$_ -eq "PHASE160J_BACKLOGGED_OWNER_SOURCE_TEST" }).Count -gt 0) -Name "backlogged_owner_not_source_task"
  $ownerBacklogAfterCandidate = Read-Phase160JValidateJson -Root $resolvedRoot -Path "$sourceSession/task_backlog/PHASE160J_BACKLOGGED_OWNER_SOURCE_TEST.json"
  Assert-Phase160JValidateEquals -Actual ([string]$ownerBacklogAfterCandidate.backlog_status) -Expected "BACKLOG_WAITING_ACTIVE_SLOT" -Name "owner_backlog_still_visible"

  $backlogLifecycleResultPath = Resolve-Phase160JValidatePath -Root $resolvedRoot -Path "reports/self_development/owner_task_backlog_lifecycle_result.json"
  Write-Phase160JValidateJsonFile -Path $backlogLifecycleResultPath -Object ([ordered]@{
    status = "PASS"
    active_internal_task_backlogged_owner_task = $true
    active_internal_task_id = [string]$activeTaskAfterBacklog.task_id
    owner_backlog_task_id = [string]$activeBacklogRecord.task_id
    owner_backlog_status = [string]$activeBacklogRecord.backlog_status
    no_active_task_accepted_owner_task = $true
    active_owner_task_id = [string]$activeOwnerTask.task_id
    owner_task_not_lost = $true
    malformed_task_reason = [string]$malformedRecord.reason
  })
  $sourceAttributionResultPath = Resolve-Phase160JValidatePath -Root $resolvedRoot -Path "reports/self_development/owner_task_source_attribution_result.json"
  Write-Phase160JValidateJsonFile -Path $sourceAttributionResultPath -Object ([ordered]@{
    status = "PASS"
    candidate_workspace_status = [string]$candidateWorkspace.status
    promotion_source_tasks = @($promotionManifest.source_tasks)
    internal_source_task_expected = "PHASE160J_INTERNAL_SOURCE_TASK_001"
    backlogged_owner_task_id = "PHASE160J_BACKLOGGED_OWNER_SOURCE_TEST"
    backlogged_owner_task_not_candidate_source = $true
    source_attribution_truthful = $true
  })

  $qualitySession = "runtime_sessions/live_growth/PHASE160J_Q_$runStamp"
  New-Phase160JValidateSessionFixture -Root $resolvedRoot -SessionRoot $qualitySession -RunId "PHASE160J_Q_$runStamp" -Branch $branchBefore -Head $headBefore
  $realCandidateDir = New-Phase160JValidateCandidateFixture -Root $resolvedRoot -SessionRoot $qualitySession -CandidateId "jreal" -ModuleTarget "modules/j_real.ps1"
  $placeholderCandidateDir = New-Phase160JValidateCandidateFixture -Root $resolvedRoot -SessionRoot $qualitySession -CandidateId "jph" -ModuleTarget "modules/j_placeholder.ps1" -Placeholder $true
  $unsafeCandidateDir = New-Phase160JValidateCandidateFixture -Root $resolvedRoot -SessionRoot $qualitySession -CandidateId "junsafe" -ModuleTarget "modules/j_unsafe.ps1" -Unsafe $true
  $realQuality = Invoke-Phase160JValidateScriptJson -Root $resolvedRoot -ScriptPath "modules/inspect_builder_candidate_quality_gate_001.ps1" -Arguments @("-CandidateDir", $realCandidateDir, "-SessionRoot", $qualitySession, "-RunId", "PHASE160J_Q_$runStamp")
  $placeholderQuality = Invoke-Phase160JValidateScriptJson -Root $resolvedRoot -ScriptPath "modules/inspect_builder_candidate_quality_gate_001.ps1" -Arguments @("-CandidateDir", $placeholderCandidateDir, "-SessionRoot", $qualitySession, "-RunId", "PHASE160J_Q_$runStamp")
  $unsafeQuality = Invoke-Phase160JValidateScriptJson -Root $resolvedRoot -ScriptPath "modules/inspect_builder_candidate_quality_gate_001.ps1" -Arguments @("-CandidateDir", $unsafeCandidateDir, "-SessionRoot", $qualitySession, "-RunId", "PHASE160J_Q_$runStamp")
  Assert-Phase160JValidateEquals -Actual ([string]$realQuality.quality_status) -Expected "CANDIDATE_READY" -Name "real_quality_candidate_ready"
  Assert-Phase160JValidateEquals -Actual ([string]$placeholderQuality.quality_status) -Expected "REVISION_REQUIRED" -Name "placeholder_quality_revision_required"
  Assert-Phase160JValidateContains -Values @("QUARANTINED", "BLOCKED") -Expected ([string]$unsafeQuality.quality_status) -Name "unsafe_quality_quarantined"

  $runtimeJsonRoots = @($activeBacklogSession, $noActiveSession, $malformedSession, $sourceSession, $qualitySession)
  foreach ($session in $runtimeJsonRoots) {
    $sessionFull = Resolve-Phase160JValidatePath -Root $resolvedRoot -Path $session
    foreach ($jsonFile in @(Get-ChildItem -LiteralPath $sessionFull -File -Filter "*.json" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "raw_*.json" })) {
      Get-Content -LiteralPath $jsonFile.FullName -Raw | ConvertFrom-Json | Out-Null
    }
  }

  $reportPath = Resolve-Phase160JValidatePath -Root $resolvedRoot -Path "reports/self_development/PHASE160J_OWNER_TASK_INTAKE_AND_BACKLOG_LIFECYCLE_REPORT.md"
  $proofPath = Resolve-Phase160JValidatePath -Root $resolvedRoot -Path "proofs/self_development/PHASE160J_OWNER_TASK_INTAKE_AND_BACKLOG_LIFECYCLE_PROOF.json"
  $routePath = Resolve-Phase160JValidatePath -Root $resolvedRoot -Path "route_change_requests/PHASE160J_OWNER_TASK_INTAKE_AND_BACKLOG_LIFECYCLE_REQUEST.md"
  $reportText = @(
    "# PHASE160J Owner Task Intake And Backlog Lifecycle Report",
    "",
    "ACTIVE_LINE: AGENT_BUILDER_SELF_DEVELOPMENT",
    "MODE: SELF_BUILD / VERIFY",
    "",
    "Validated safe owner task normalization, exact unsafe quarantine reasons, owner backlog behind an active internal task, no-active owner activation, malformed task rejection, source attribution truth, and PHASE160H1 quality-gate compatibility.",
    "",
    "Artifacts:",
    "- reports/self_development/owner_task_intake_normalization_result.json",
    "- reports/self_development/owner_task_safety_classification_result.json",
    "- reports/self_development/owner_task_backlog_lifecycle_result.json",
    "- reports/self_development/owner_task_source_attribution_result.json",
    "",
    "Result: PASS"
  ) -join "`n"
  Write-Phase160JValidateTextFile -Path $reportPath -Text $reportText
  Write-Phase160JValidateJsonFile -Path $proofPath -Object ([ordered]@{
    status = "PASS"
    phase = "PHASE160J_OWNER_TASK_INTAKE_AND_BACKLOG_LIFECYCLE_V1"
    active_line = "AGENT_BUILDER_SELF_DEVELOPMENT"
    mode = "SELF_BUILD"
    safe_owner_task_with_safety_rules_accepted_or_backlogged = $true
    unsafe_commit_task_quarantined = $true
    unsafe_protected_mutation_task_quarantined = $true
    active_internal_task_backlogs_owner_task = $true
    no_active_task_accepts_owner_task = $true
    owner_task_not_lost = $true
    source_attribution_truthful = $true
    generic_unsafe_safety_rules_false_quarantine_removed = $true
    phase160h1_quality_gate_compatibility_pass = $true
    artifacts = @(
      "reports/self_development/owner_task_intake_normalization_result.json",
      "reports/self_development/owner_task_safety_classification_result.json",
      "reports/self_development/owner_task_backlog_lifecycle_result.json",
      "reports/self_development/owner_task_source_attribution_result.json"
    )
    report = "reports/self_development/PHASE160J_OWNER_TASK_INTAKE_AND_BACKLOG_LIFECYCLE_REPORT.md"
    route_request = "route_change_requests/PHASE160J_OWNER_TASK_INTAKE_AND_BACKLOG_LIFECYCLE_REQUEST.md"
    accepted_state_mutated = $false
    protected_state_mutated = $false
    commit_performed = $false
    push_performed = $false
    branch_switch_performed = $false
    validated_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Write-Phase160JValidateTextFile -Path $routePath -Text (@(
    "# PHASE160J Owner Task Intake And Backlog Lifecycle Request",
    "",
    "Request: accept PHASE160J repair as the entrance-gate queue discipline before PHASE161 school.",
    "",
    "Scope remained AGENT_BUILDER_SELF_DEVELOPMENT. No external agents, no package installs, no commit, no push, no branch switch, and no protected state mutation.",
    "",
    "Validator: validators/validate_phase160j_owner_task_intake_and_backlog_lifecycle_v1.ps1"
  ) -join "`n")

  foreach ($path in @(
    "reports/self_development/owner_task_intake_normalization_result.json",
    "reports/self_development/owner_task_safety_classification_result.json",
    "reports/self_development/owner_task_backlog_lifecycle_result.json",
    "reports/self_development/owner_task_source_attribution_result.json",
    "proofs/self_development/PHASE160J_OWNER_TASK_INTAKE_AND_BACKLOG_LIFECYCLE_PROOF.json"
  )) {
    Read-Phase160JValidateJson -Root $resolvedRoot -Path $path | Out-Null
  }

  $protectedAfter = Get-Phase160JValidateFileHashes -Root $resolvedRoot -Paths $protectedPaths
  foreach ($path in $protectedPaths) {
    Assert-Phase160JValidateEquals -Actual $protectedAfter[$path] -Expected $protectedBefore[$path] -Name "protected_state_hash_$path"
  }
  Assert-Phase160JRuntimeOutputsNotStaged
  $branchAfter = (git branch --show-current).Trim()
  $headAfter = (git rev-parse --short HEAD).Trim()
  $remoteAfter = Get-Phase160JValidateRemoteHeadSafe -Branch $branchAfter
  Assert-Phase160JValidateEquals -Actual $branchAfter -Expected $branchBefore -Name "branch_unchanged"
  Assert-Phase160JValidateEquals -Actual $headAfter -Expected $headBefore -Name "head_unchanged_no_commit"
  Assert-Phase160JValidateEquals -Actual $remoteAfter -Expected $remoteBefore -Name "remote_head_unchanged_no_push"

  Write-Host "PHASE160J_OWNER_TASK_INTAKE_AND_BACKLOG_LIFECYCLE_VALIDATE_RESULT=PASS"
  Write-Host "SAFE_OWNER_TASK_WITH_SAFETY_RULES_ACCEPTED_OR_BACKLOGGED=True"
  Write-Host "UNSAFE_COMMIT_TASK_QUARANTINED=True"
  Write-Host "UNSAFE_PROTECTED_MUTATION_TASK_QUARANTINED=True"
  Write-Host "ACTIVE_INTERNAL_TASK_BACKLOGS_OWNER_TASK=True"
  Write-Host "NO_ACTIVE_TASK_ACCEPTS_OWNER_TASK=True"
  Write-Host "OWNER_TASK_NOT_LOST=True"
  Write-Host "SOURCE_ATTRIBUTION_TRUTHFUL=True"
  Write-Host "GENERIC_UNSAFE_SAFETY_RULES_FALSE_QUARANTINE_REMOVED=True"
  Write-Host "PHASE160H1_QUALITY_GATE_COMPATIBILITY_PASS=True"
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
