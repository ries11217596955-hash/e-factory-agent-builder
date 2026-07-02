param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160KValidatePath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160KValidateRepoRoot {
  param([string]$RepoRootParameter)
  if (-not [string]::IsNullOrWhiteSpace($RepoRootParameter) -and $RepoRootParameter -ne ".") {
    return Normalize-Phase160KValidatePath -Path $RepoRootParameter
  }
  $scriptRoot = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRoot) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRoot = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
    throw "PHASE160K_VALIDATE_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160KValidatePath -Path (Join-Path $scriptRoot "..")
}

function Resolve-Phase160KValidatePath {
  param([string]$Root, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $Root $Path))
}

function ConvertTo-Phase160KValidateRelativePath {
  param([string]$Root, [string]$FullPath)
  $rootFull = Normalize-Phase160KValidatePath -Path $Root
  $pathFull = Normalize-Phase160KValidatePath -Path $FullPath
  if ($pathFull -eq $rootFull) {
    return "."
  }
  if (-not $pathFull.StartsWith($rootFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "PHASE160K_VALIDATE_PATH_OUTSIDE_REPO=$FullPath"
  }
  return ($pathFull.Substring($rootFull.Length + 1) -replace "\\", "/")
}

function Assert-Phase160KValidatePathInside {
  param([string]$Root, [string]$Path)
  $rootFull = Normalize-Phase160KValidatePath -Path $Root
  $pathFull = Normalize-Phase160KValidatePath -Path (Resolve-Phase160KValidatePath -Root $Root -Path $Path)
  if (-not ($pathFull -eq $rootFull -or $pathFull.StartsWith($rootFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase))) {
    throw "PHASE160K_VALIDATE_PATH_OUTSIDE_REPO=$Path"
  }
  return $pathFull
}

function Write-Phase160KValidateJsonFile {
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

function Write-Phase160KValidateTextFile {
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

function Read-Phase160KValidateJson {
  param([string]$Root, [string]$Path)
  $fullPath = Resolve-Phase160KValidatePath -Root $Root -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160K_VALIDATE_MISSING_JSON=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Assert-Phase160KValidateTrue {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $true) {
    throw "PHASE160K_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase160KValidateFalse {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $false) {
    throw "PHASE160K_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase160KValidateEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160K_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase160KValidateParserClean {
  param([string]$Path)
  $tokens = $null
  $parseErrors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors) | Out-Null
  if ($parseErrors.Count -gt 0) {
    throw "PHASE160K_VALIDATE_PARSE_ERROR=$Path message=$($parseErrors[0].Message)"
  }
}

function Get-Phase160KValidateFileHashes {
  param([string]$Root, [string[]]$Paths)
  $hashes = @{}
  foreach ($path in $Paths) {
    $fullPath = Resolve-Phase160KValidatePath -Root $Root -Path $path
    if (Test-Path -LiteralPath $fullPath) {
      $hashes[$path] = (Get-FileHash -LiteralPath $fullPath -Algorithm SHA256).Hash
    } else {
      $hashes[$path] = "MISSING"
    }
  }
  return $hashes
}

function Get-Phase160KValidateRemoteHeadSafe {
  param([string]$Branch)
  $remoteHead = (git rev-parse --short "origin/$Branch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    return "UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Remove-Phase160KValidateOutput {
  param([string]$Root, [string]$Path)
  $fullPath = Assert-Phase160KValidatePathInside -Root $Root -Path $Path
  $relative = ConvertTo-Phase160KValidateRelativePath -Root $Root -FullPath $fullPath
  if (-not ($relative -match "^runtime_sessions/live_growth/PHASE160K_" -or $relative -match "^runtime_sessions/live_growth_console/PHASE160K_")) {
    throw "PHASE160K_VALIDATE_REFUSE_DELETE=$relative"
  }
  if (Test-Path -LiteralPath $fullPath) {
    Remove-Item -LiteralPath $fullPath -Recurse -Force
  }
}

function Invoke-Phase160KValidateScriptJson {
  param([string]$Root, [string]$ScriptPath, [string[]]$Arguments)
  $scriptFull = Resolve-Phase160KValidatePath -Root $Root -Path $ScriptPath
  $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File $scriptFull @Arguments 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160K_VALIDATE_SCRIPT_FAILED script=$ScriptPath output=$($output -join ' | ')"
  }
  return ($output -join "`n") | ConvertFrom-Json
}

function Invoke-Phase160KValidateScriptText {
  param([string]$Root, [string]$ScriptPath, [string[]]$Arguments)
  $scriptFull = Resolve-Phase160KValidatePath -Root $Root -Path $ScriptPath
  $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File $scriptFull @Arguments 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160K_VALIDATE_SCRIPT_FAILED script=$ScriptPath output=$($output -join ' | ')"
  }
  return $output
}

function New-Phase160KValidateSessionFixture {
  param([string]$Root, [string]$SessionRoot, [string]$RunId, [string]$Branch, [string]$Head)
  Remove-Phase160KValidateOutput -Root $Root -Path $SessionRoot
  $sessionFull = Resolve-Phase160KValidatePath -Root $Root -Path $SessionRoot
  foreach ($directory in @(
    $sessionFull,
    (Join-Path $sessionFull "teacher_inbox"),
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
  Write-Phase160KValidateJsonFile -Path (Join-Path $sessionFull "run_manifest.json") -Object ([ordered]@{
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
  Write-Phase160KValidateJsonFile -Path (Join-Path $sessionFull "runtime_guard.json") -Object ([ordered]@{
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

function New-Phase160KValidateCandidateFixture {
  param(
    [string]$Root,
    [string]$SessionRoot,
    [string]$CandidateId,
    [string]$QualityKind = "real"
  )
  $sessionFull = Resolve-Phase160KValidatePath -Root $Root -Path $SessionRoot
  $candidateDir = Join-Path $sessionFull "candidate_workspace/candidate_bundles/$CandidateId"
  foreach ($directory in @(
    $candidateDir,
    (Join-Path $candidateDir "proposed_patch_or_file_payloads/modules"),
    (Join-Path $candidateDir "proposed_patch_or_file_payloads/validators")
  )) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  $moduleTarget = "modules/$CandidateId`_module.ps1"
  $validatorTarget = "validators/validate_$CandidateId`_v1.ps1"
  $modulePayloadPath = "proposed_patch_or_file_payloads/modules/$CandidateId`_module.ps1"
  $validatorPayloadPath = "proposed_patch_or_file_payloads/validators/validate_$CandidateId`_v1.ps1"
  $modulePayload = @"
param(
  [string]`$InputPath = "",
  [string]`$OutputPath = ""
)

`$ErrorActionPreference = "Stop"

function Invoke-Phase160KCandidateFixturePayload {
  param([string]`$CandidateId)
  `$signals = @(
    "canonical_quality_artifact_written",
    "materialization_parse_check_required",
    "owner_promotion_gate_required",
    "runtime_session_only"
  )
  return [ordered]@{
    status = "PASS"
    candidate_id = `$CandidateId
    signal_count = `$signals.Count
    signals = `$signals
    accepted_code_written = `$false
    repo_mutation_performed = `$false
  }
}

Invoke-Phase160KCandidateFixturePayload -CandidateId "$CandidateId" | ConvertTo-Json -Depth 20
"@
  $validatorPayload = @"
param(
  [string]`$RepoRoot = "."
)

`$ErrorActionPreference = "Stop"

function Assert-Phase160KCandidateFixtureTrue {
  param([object]`$Actual, [string]`$Name)
  if (`$Actual -ne `$true) {
    throw "PHASE160K_CANDIDATE_FIXTURE_FLAG_NOT_TRUE=`$Name actual=`$Actual"
  }
}

Assert-Phase160KCandidateFixtureTrue -Actual `$true -Name "candidate_fixture_validator_parseable"
Write-Host "PHASE160K_CANDIDATE_FIXTURE_VALIDATE_RESULT=PASS"
"@
  if ($QualityKind -eq "placeholder") {
    $modulePayload = "placeholder payload"
  }
  if ($QualityKind -eq "missing_validator") {
    $validatorPayloadPath = "NONE"
  }
  if ($QualityKind -eq "unsafe") {
    $modulePayload += "`n`ngit commit -m `"unsafe quality artifact fixture`"`ngit push`n"
  }
  Write-Phase160KValidateTextFile -Path (Join-Path $candidateDir $modulePayloadPath) -Text $modulePayload
  $payloadEntries = @(
    [ordered]@{ kind = "module"; target_path = $moduleTarget; payload_path = $modulePayloadPath; parse_required = $true; required = $true }
  )
  if ($validatorPayloadPath -ne "NONE") {
    Write-Phase160KValidateTextFile -Path (Join-Path $candidateDir $validatorPayloadPath) -Text $validatorPayload
    $payloadEntries += [ordered]@{ kind = "validator"; target_path = $validatorTarget; payload_path = $validatorPayloadPath; parse_required = $true; required = $true }
  }
  Write-Phase160KValidateJsonFile -Path (Join-Path $candidateDir "candidate_manifest.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = $CandidateId
    source_task_id = "PHASE160K_SOURCE_TASK_$CandidateId"
    source = "owner_task"
    created_from_run_head = "fixture"
    run_id = Split-Path -Path $SessionRoot -Leaf
    owner_goal = "Verify canonical quality artifact consistency without relying on owner_goal keywords."
    desired_next_gap = "QUALITY_ARTIFACT_NAMESPACE_AND_COUNTER_CONSISTENCY_GAP"
    proposed_file_paths = @($moduleTarget)
    proposed_validator_paths = if ($validatorPayloadPath -eq "NONE") { @() } else { @($validatorTarget) }
    proposed_payload_paths = @($payloadEntries | ForEach-Object { [string]$_.payload_path })
    owner_approval_required = $true
    owner_promotion_gate_required = $true
    candidate_output_is_not_accepted_code = $true
    repo_mutation_performed = $false
    commit_performed = $false
    push_performed = $false
    branch_switch_performed = $false
    protected_state_mutated = $false
    decision = "CANDIDATE_DRAFT"
    quality_status = "CANDIDATE_DRAFT"
    quality_gate_enabled = $true
    owner_promotion_allowed = $false
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Write-Phase160KValidateJsonFile -Path (Join-Path $candidateDir "proposed_files.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = $CandidateId
    proposed_file_paths = @($moduleTarget)
    proposed_validator_paths = if ($validatorPayloadPath -eq "NONE") { @() } else { @($validatorTarget) }
    proposed_payloads = @($payloadEntries)
    accepted_code_written = $false
  })
  Write-Phase160KValidateJsonFile -Path (Join-Path $candidateDir "candidate_validation_plan.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = $CandidateId
    validators_required_before_acceptance = if ($validatorPayloadPath -eq "NONE") { @() } else { @($validatorTarget) }
    materialization_parse_check_required = $true
    owner_review_required = $true
  })
  Write-Phase160KValidateJsonFile -Path (Join-Path $candidateDir "candidate_risk_review.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = $CandidateId
    accepted_state_mutated = $false
    repo_mutation_performed = $false
  })
  Write-Phase160KValidateJsonFile -Path (Join-Path $candidateDir "candidate_status.json") -Object ([ordered]@{
    status = "CANDIDATE_DRAFT"
    quality_status = "CANDIDATE_DRAFT"
    candidate_id = $CandidateId
    source_task_id = "PHASE160K_SOURCE_TASK_$CandidateId"
    owner_promotion_allowed = $false
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  return ConvertTo-Phase160KValidateRelativePath -Root $Root -FullPath $candidateDir
}

function New-Phase160KValidateSafeOwnerTask {
  param([string]$TaskId)
  return [ordered]@{
    event_type = "owner_live_task_injection"
    task_id = $TaskId
    source = "owner"
    priority = "high"
    owner_goal = "Verify PHASE160J1 owner task state aliases remain compatible with PHASE160K."
    desired_next_gap = "PHASE160J1_COMPATIBILITY_GAP"
    expected_outputs = @("owner backlog state aliases")
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

function Assert-Phase160KRuntimeOutputsNotStaged {
  $stagedRuntime = @(git diff --cached --name-only -- runtime_sessions)
  if ($stagedRuntime.Count -gt 0) {
    throw "PHASE160K_VALIDATE_RUNTIME_OUTPUTS_STAGED=$($stagedRuntime -join '; ')"
  }
}

$resolvedRoot = Resolve-Phase160KValidateRepoRoot -RepoRootParameter $RepoRoot
$pushed = $false

try {
  Push-Location $resolvedRoot
  $pushed = $true

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160KValidatePath -Root $resolvedRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $branchBefore = (git branch --show-current).Trim()
  $headBefore = (git rev-parse --short HEAD).Trim()
  $remoteBefore = Get-Phase160KValidateRemoteHeadSafe -Branch $branchBefore
  $runStamp = Get-Date -Format "yyyyMMddHHmmssfff"
  $protectedPaths = @("TASK_QUEUE.json", "GENESIS_STATE.json", "CAPABILITY_ROADMAP.json", "packs/registry.json", "orchestrator/run.ps1")
  $protectedBefore = Get-Phase160KValidateFileHashes -Root $resolvedRoot -Paths $protectedPaths

  $touchedPs1 = @(
    "modules/normalize_builder_candidate_quality_artifacts_001.ps1",
    "modules/inspect_builder_quality_decision_index_001.ps1",
    "modules/repair_builder_missing_quality_result_artifacts_001.ps1",
    "modules/inspect_builder_candidate_quality_gate_001.ps1",
    "modules/finalize_builder_promotion_bundle_001.ps1",
    "modules/invoke_builder_candidate_workspace_step_001.ps1",
    "modules/start_builder_live_growth_daemon_001.ps1",
    "modules/watch_builder_live_console_001.ps1",
    "modules/watch_builder_live_growth_session_observer_001.ps1",
    "modules/inspect_builder_owner_task_lifecycle_state_001.ps1",
    "validators/validate_phase160k_quality_artifact_consistency_v1.ps1"
  )
  foreach ($path in $touchedPs1) {
    Assert-Phase160KValidateParserClean -Path (Resolve-Phase160KValidatePath -Root $resolvedRoot -Path $path)
  }

  . (Resolve-Phase160KValidatePath -Root $resolvedRoot -Path "modules/inspect_builder_quality_decision_index_001.ps1")
  . (Resolve-Phase160KValidatePath -Root $resolvedRoot -Path "modules/inspect_builder_owner_task_lifecycle_state_001.ps1")

  $qualitySession = "runtime_sessions/live_growth/PHASE160K_Q_$runStamp"
  New-Phase160KValidateSessionFixture -Root $resolvedRoot -SessionRoot $qualitySession -RunId "PHASE160K_Q_$runStamp" -Branch $branchBefore -Head $headBefore
  $realCandidateDir = New-Phase160KValidateCandidateFixture -Root $resolvedRoot -SessionRoot $qualitySession -CandidateId "kreal" -QualityKind "real"
  $placeholderCandidateDir = New-Phase160KValidateCandidateFixture -Root $resolvedRoot -SessionRoot $qualitySession -CandidateId "kph" -QualityKind "placeholder"
  $unsafeCandidateDir = New-Phase160KValidateCandidateFixture -Root $resolvedRoot -SessionRoot $qualitySession -CandidateId "kunsafe" -QualityKind "unsafe"
  $missingValidatorCandidateDir = New-Phase160KValidateCandidateFixture -Root $resolvedRoot -SessionRoot $qualitySession -CandidateId "kmissv" -QualityKind "missing_validator"

  $realQuality = Invoke-Phase160KValidateScriptJson -Root $resolvedRoot -ScriptPath "modules/inspect_builder_candidate_quality_gate_001.ps1" -Arguments @("-CandidateDir", $realCandidateDir, "-SessionRoot", $qualitySession, "-RunId", "PHASE160K_Q_$runStamp")
  $placeholderQuality = Invoke-Phase160KValidateScriptJson -Root $resolvedRoot -ScriptPath "modules/inspect_builder_candidate_quality_gate_001.ps1" -Arguments @("-CandidateDir", $placeholderCandidateDir, "-SessionRoot", $qualitySession, "-RunId", "PHASE160K_Q_$runStamp")
  $unsafeQuality = Invoke-Phase160KValidateScriptJson -Root $resolvedRoot -ScriptPath "modules/inspect_builder_candidate_quality_gate_001.ps1" -Arguments @("-CandidateDir", $unsafeCandidateDir, "-SessionRoot", $qualitySession, "-RunId", "PHASE160K_Q_$runStamp")
  $missingValidatorQuality = Invoke-Phase160KValidateScriptJson -Root $resolvedRoot -ScriptPath "modules/inspect_builder_candidate_quality_gate_001.ps1" -Arguments @("-CandidateDir", $missingValidatorCandidateDir, "-SessionRoot", $qualitySession, "-RunId", "PHASE160K_Q_$runStamp")

  Assert-Phase160KValidateEquals -Actual ([string]$realQuality.quality_status) -Expected "CANDIDATE_READY" -Name "real_candidate_ready"
  Assert-Phase160KValidateEquals -Actual ([string]$placeholderQuality.quality_status) -Expected "REVISION_REQUIRED" -Name "placeholder_revision_required"
  Assert-Phase160KValidateEquals -Actual ([string]$missingValidatorQuality.quality_status) -Expected "REVISION_REQUIRED" -Name "missing_validator_revision_required"
  Assert-Phase160KValidateTrue -Actual (@("QUARANTINED", "BLOCKED") -contains [string]$unsafeQuality.quality_status) -Name "unsafe_quarantined_or_blocked"

  $realCanonical = Read-Phase160KValidateJson -Root $resolvedRoot -Path "$realCandidateDir/candidate_quality/quality_result.json"
  $placeholderCanonical = Read-Phase160KValidateJson -Root $resolvedRoot -Path "$placeholderCandidateDir/candidate_quality/quality_result.json"
  $unsafeCanonical = Read-Phase160KValidateJson -Root $resolvedRoot -Path "$unsafeCandidateDir/candidate_quality/quality_result.json"
  Assert-Phase160KValidateEquals -Actual ([string]$realCanonical.quality_status) -Expected "CANDIDATE_READY" -Name "real_canonical_ready"
  Assert-Phase160KValidateEquals -Actual ([string]$placeholderCanonical.quality_status) -Expected "REVISION_REQUIRED" -Name "placeholder_canonical_revision"
  Assert-Phase160KValidateTrue -Actual (@("QUARANTINED", "BLOCKED") -contains [string]$unsafeCanonical.quality_status) -Name "unsafe_canonical_quarantined"
  Assert-Phase160KValidateTrue -Actual ([bool]$realCanonical.real_module_payload_present -and [bool]$realCanonical.real_validator_payload_present) -Name "real_payloads_present"
  Assert-Phase160KValidateFalse -Actual ([bool]$placeholderCanonical.owner_promotion_allowed) -Name "placeholder_owner_promotion_false"

  $promotionResult = Invoke-Phase160KValidateScriptJson -Root $resolvedRoot -ScriptPath "modules/finalize_builder_promotion_bundle_001.ps1" -Arguments @("-SessionRoot", $qualitySession, "-RunId", "PHASE160K_Q_$runStamp")
  $promotionManifest = Read-Phase160KValidateJson -Root $resolvedRoot -Path "$qualitySession/promotion_bundle/promotion_manifest.json"
  Assert-Phase160KValidateEquals -Actual ([int]$promotionManifest.quality_result_file_count) -Expected ([int]$promotionManifest.quality_decision_count) -Name "promotion_quality_counts_match"
  Assert-Phase160KValidateEquals -Actual ([int]$promotionManifest.quality_result_file_count) -Expected 4 -Name "promotion_quality_file_count"
  Assert-Phase160KValidateEquals -Actual ([int]$promotionManifest.ready_candidate_count_after_quality) -Expected 1 -Name "promotion_ready_count"
  Assert-Phase160KValidateEquals -Actual ([string]$promotionManifest.promotion_status) -Expected "WAITING_OWNER_REVIEW" -Name "promotion_waiting_owner_review"
  Assert-Phase160KValidateEquals -Actual ([string]$promotionManifest.quality_artifact_consistency_status) -Expected "PASS" -Name "promotion_consistency_pass"

  $missingSession = "runtime_sessions/live_growth/PHASE160K_MISS_$runStamp"
  New-Phase160KValidateSessionFixture -Root $resolvedRoot -SessionRoot $missingSession -RunId "PHASE160K_MISS_$runStamp" -Branch $branchBefore -Head $headBefore
  $missingCandidateDir = New-Phase160KValidateCandidateFixture -Root $resolvedRoot -SessionRoot $missingSession -CandidateId "kmiss" -QualityKind "real"
  $missingCandidateFull = Resolve-Phase160KValidatePath -Root $resolvedRoot -Path $missingCandidateDir
  Remove-Item -LiteralPath (Join-Path $missingCandidateFull "candidate_quality") -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath (Join-Path $missingCandidateFull "quality_gate") -Recurse -Force -ErrorAction SilentlyContinue
  $missingManifest = Read-Phase160KValidateJson -Root $resolvedRoot -Path "$missingCandidateDir/candidate_manifest.json"
  $missingManifest.quality_status = "CANDIDATE_READY"
  $missingManifest.decision = "CANDIDATE_READY"
  $missingManifest.owner_promotion_allowed = $true
  Write-Phase160KValidateJsonFile -Path (Join-Path $missingCandidateFull "candidate_manifest.json") -Object $missingManifest
  Write-Phase160KValidateJsonFile -Path (Resolve-Phase160KValidatePath -Root $resolvedRoot -Path "$missingSession/promotion_bundle/promotion_manifest.json") -Object ([ordered]@{
    status = "PASS"
    promotion_status = "WAITING_OWNER_REVIEW"
    candidate_count = 1
    quality_decisions = @([ordered]@{ candidate_id = "kmiss"; quality_status = "CANDIDATE_READY"; owner_promotion_allowed = $true })
    quality_result_file_count = 0
    quality_decision_count = 1
    quality_artifact_consistency_status = "PASS"
    missing_quality_result_count = 0
    owner_promotion_allowed = $true
  })
  $missingIndex = Get-Phase160KQualityDecisionIndex -RepoRoot $resolvedRoot -SessionRootFull (Resolve-Phase160KValidatePath -Root $resolvedRoot -Path $missingSession)
  Assert-Phase160KValidateTrue -Actual ([int]$missingIndex.missing_quality_result_count -gt 0) -Name "missing_quality_result_detected"
  Assert-Phase160KValidateEquals -Actual ([string]$missingIndex.quality_artifact_consistency_status) -Expected "INCONSISTENT" -Name "missing_consistency_inconsistent"
  Assert-Phase160KValidateEquals -Actual ([string]$missingIndex.promotion_status) -Expected "BLOCKED_QUALITY_ARTIFACT_INCONSISTENCY" -Name "missing_waiting_owner_blocked"

  $mismatchSession = "runtime_sessions/live_growth/PHASE160K_MISM_$runStamp"
  New-Phase160KValidateSessionFixture -Root $resolvedRoot -SessionRoot $mismatchSession -RunId "PHASE160K_MISM_$runStamp" -Branch $branchBefore -Head $headBefore
  $mismatchCandidateDir = New-Phase160KValidateCandidateFixture -Root $resolvedRoot -SessionRoot $mismatchSession -CandidateId "kmism" -QualityKind "real"
  $mismatchQuality = Invoke-Phase160KValidateScriptJson -Root $resolvedRoot -ScriptPath "modules/inspect_builder_candidate_quality_gate_001.ps1" -Arguments @("-CandidateDir", $mismatchCandidateDir, "-SessionRoot", $mismatchSession, "-RunId", "PHASE160K_MISM_$runStamp")
  $mismatchFull = Resolve-Phase160KValidatePath -Root $resolvedRoot -Path $mismatchCandidateDir
  $mismatchManifest = Read-Phase160KValidateJson -Root $resolvedRoot -Path "$mismatchCandidateDir/candidate_manifest.json"
  $mismatchManifest.quality_status = "REVISION_REQUIRED"
  $mismatchManifest.decision = "REVISION_REQUIRED"
  $mismatchManifest.revision_required = $true
  $mismatchManifest.owner_promotion_allowed = $false
  Write-Phase160KValidateJsonFile -Path (Join-Path $mismatchFull "candidate_manifest.json") -Object $mismatchManifest
  $mismatchIndex = Get-Phase160KQualityDecisionIndex -RepoRoot $resolvedRoot -SessionRootFull (Resolve-Phase160KValidatePath -Root $resolvedRoot -Path $mismatchSession)
  Assert-Phase160KValidateTrue -Actual ([bool]$mismatchIndex.mismatch_detected) -Name "manifest_mismatch_detected"
  Assert-Phase160KValidateEquals -Actual ([string]$mismatchIndex.quality_artifact_consistency_status) -Expected "INCONSISTENT" -Name "mismatch_consistency_inconsistent"

  $daemonOutput = Invoke-Phase160KValidateScriptText -Root $resolvedRoot -ScriptPath "modules/start_builder_live_growth_daemon_001.ps1" -Arguments @("-SessionRoot", $qualitySession, "-RunId", "PHASE160K_Q_$runStamp", "-DurationSeconds", "1", "-TickIntervalSeconds", "1")
  $currentState = Read-Phase160KValidateJson -Root $resolvedRoot -Path "$qualitySession/current_state.json"
  Assert-Phase160KValidateEquals -Actual ([int]$currentState.quality_result_file_count) -Expected ([int]$promotionManifest.quality_result_file_count) -Name "current_state_quality_result_count"
  Assert-Phase160KValidateEquals -Actual ([int]$currentState.quality_decision_count) -Expected ([int]$promotionManifest.quality_decision_count) -Name "current_state_quality_decision_count"
  Assert-Phase160KValidateEquals -Actual ([int]$currentState.quality_ready_count) -Expected ([int]$promotionManifest.ready_candidate_count_after_quality) -Name "current_state_ready_count"
  Assert-Phase160KValidateEquals -Actual ([string]$currentState.quality_artifact_consistency_status) -Expected ([string]$promotionManifest.quality_artifact_consistency_status) -Name "current_state_consistency"

  $consoleRoot = "runtime_sessions/live_growth_console/PHASE160K_C_$runStamp"
  Remove-Phase160KValidateOutput -Root $resolvedRoot -Path $consoleRoot
  $consoleOutput = Invoke-Phase160KValidateScriptText -Root $resolvedRoot -ScriptPath "modules/watch_builder_live_console_001.ps1" -Arguments @("-SessionRoot", $qualitySession, "-RunId", "PHASE160K_Q_$runStamp", "-DurationSeconds", "1", "-PollIntervalSeconds", "1", "-ShowTailEvents", "0", "-ShowTailObserver", "0", "-ConsoleRunId", "PHASE160K_C_$runStamp", "-ConsoleRuntimeRoot", $consoleRoot)
  $consoleSample = Get-Content -LiteralPath (Resolve-Phase160KValidatePath -Root $resolvedRoot -Path "$consoleRoot/console_output_sample.txt") -Raw
  foreach ($token in @("QUALITY_RESULT_FILE_COUNT=", "QUALITY_DECISION_COUNT=", "QUALITY_ARTIFACT_CONSISTENCY=", "MISSING_QUALITY_RESULT_COUNT=", "QUALITY_READY_COUNT=", "REVISION_REQUIRED_COUNT=", "PROMOTION_BUNDLE_STATUS=")) {
    if ($consoleSample.IndexOf($token, [System.StringComparison]::Ordinal) -lt 0) {
      throw "PHASE160K_VALIDATE_CONSOLE_TOKEN_MISSING=$token"
    }
  }

  $observerResult = Invoke-Phase160KValidateScriptJson -Root $resolvedRoot -ScriptPath "modules/watch_builder_live_growth_session_observer_001.ps1" -Arguments @("-SessionRoot", $qualitySession, "-RunId", "PHASE160K_Q_$runStamp", "-DurationSeconds", "1", "-PollIntervalSeconds", "1", "-StaleAfterSeconds", "99")
  Assert-Phase160KValidateTrue -Actual ([bool]$observerResult.quality_result_files_exist_for_evaluated_candidates) -Name "observer_quality_results_exist"
  Assert-Phase160KValidateTrue -Actual ([bool]$observerResult.promotion_manifest_agrees_with_quality_results) -Name "observer_promotion_agrees"
  Assert-Phase160KValidateFalse -Actual ([bool]$observerResult.ready_candidate_without_quality_result_detected) -Name "observer_no_ready_without_quality_result"
  Assert-Phase160KValidateTrue -Actual ([bool]$observerResult.placeholder_still_blocked) -Name "observer_placeholder_blocked"
  Assert-Phase160KValidateTrue -Actual ([bool]$observerResult.unsafe_still_quarantined) -Name "observer_unsafe_quarantined"

  $ownerSession = "runtime_sessions/live_growth/PHASE160K_O_$runStamp"
  New-Phase160KValidateSessionFixture -Root $resolvedRoot -SessionRoot $ownerSession -RunId "PHASE160K_O_$runStamp" -Branch $branchBefore -Head $headBefore
  $ownerFull = Resolve-Phase160KValidatePath -Root $resolvedRoot -Path $ownerSession
  Write-Phase160KValidateJsonFile -Path (Join-Path $ownerFull "active_task/active_task.json") -Object ([ordered]@{
    status = "ACTIVE"
    task_id = "PHASE160K_INTERNAL_ACTIVE_TASK_001"
    source = "internal_self_selected_goal"
    owner_goal = "Internal task blocks owner task for PHASE160J1 compatibility."
    desired_next_gap = "SELF_INITIATED_USEFUL_GOAL_SELECTION"
    active_owner_task = $false
  })
  Write-Phase160KValidateJsonFile -Path (Join-Path $ownerFull "task_lifecycle/active_task_state.json") -Object ([ordered]@{
    status = "WAITING_OWNER_PROMOTION"
    active_task_id = "PHASE160K_INTERNAL_ACTIVE_TASK_001"
  })
  Write-Phase160KValidateJsonFile -Path (Join-Path $ownerFull "teacher_inbox/safe_owner.json") -Object (New-Phase160KValidateSafeOwnerTask -TaskId "PHASE160K_SAFE_OWNER_BACKLOG_001")
  $ownerDuty = Invoke-Phase160KValidateScriptJson -Root $resolvedRoot -ScriptPath "modules/invoke_builder_live_self_growth_duty_step_001.ps1" -Arguments @("-SessionRoot", $ownerSession, "-DutyIndex", "1", "-TickNumber", "1", "-MaxCandidateBytes", "8192")
  $ownerLifecycle = Get-Phase160JOwnerTaskLifecycleState -SessionRootFull $ownerFull
  Assert-Phase160KValidateEquals -Actual ([string]$ownerLifecycle.last_owner_task_intake_decision) -Expected "BACKLOG_SAFE_OWNER_TASK" -Name "owner_backlog_decision"
  Assert-Phase160KValidateFalse -Actual ([bool]$ownerLifecycle.owner_task_lost) -Name "owner_task_not_lost"
  Assert-Phase160KValidateEquals -Actual ([int]$ownerLifecycle.owner_task_backlog_count) -Expected 1 -Name "owner_backlog_count"

  $artifactConsistencyPath = Resolve-Phase160KValidatePath -Root $resolvedRoot -Path "reports/self_development/quality_artifact_consistency_result.json"
  $decisionIndexPath = Resolve-Phase160KValidatePath -Root $resolvedRoot -Path "reports/self_development/quality_decision_index_result.json"
  $manifestAlignmentPath = Resolve-Phase160KValidatePath -Root $resolvedRoot -Path "reports/self_development/quality_manifest_alignment_result.json"
  $promotionCounterPath = Resolve-Phase160KValidatePath -Root $resolvedRoot -Path "reports/self_development/quality_promotion_counter_result.json"
  Write-Phase160KValidateJsonFile -Path $artifactConsistencyPath -Object ([ordered]@{
    status = "PASS"
    ready_quality_result_written = Test-Path -LiteralPath (Resolve-Phase160KValidatePath -Root $resolvedRoot -Path "$realCandidateDir/candidate_quality/quality_result.json")
    revision_required_quality_result_written = Test-Path -LiteralPath (Resolve-Phase160KValidatePath -Root $resolvedRoot -Path "$placeholderCandidateDir/candidate_quality/quality_result.json")
    quarantined_quality_result_written = Test-Path -LiteralPath (Resolve-Phase160KValidatePath -Root $resolvedRoot -Path "$unsafeCandidateDir/candidate_quality/quality_result.json")
    no_owner_goal_keyword_false_pass = ([string]$placeholderCanonical.quality_status -eq "REVISION_REQUIRED")
  })
  Write-Phase160KValidateJsonFile -Path $decisionIndexPath -Object $missingIndex
  Write-Phase160KValidateJsonFile -Path $manifestAlignmentPath -Object $mismatchIndex
  Write-Phase160KValidateJsonFile -Path $promotionCounterPath -Object ([ordered]@{
    status = "PASS"
    quality_result_file_count = [int]$promotionManifest.quality_result_file_count
    quality_decision_count = [int]$promotionManifest.quality_decision_count
    ready_candidate_count_after_quality = [int]$promotionManifest.ready_candidate_count_after_quality
    current_state_quality_result_file_count = [int]$currentState.quality_result_file_count
    current_state_quality_decision_count = [int]$currentState.quality_decision_count
    current_state_quality_ready_count = [int]$currentState.quality_ready_count
    counters_match = $true
  })

  $reportPath = Resolve-Phase160KValidatePath -Root $resolvedRoot -Path "reports/self_development/PHASE160K_QUALITY_ARTIFACT_CONSISTENCY_REPORT.md"
  $proofPath = Resolve-Phase160KValidatePath -Root $resolvedRoot -Path "proofs/self_development/PHASE160K_QUALITY_ARTIFACT_CONSISTENCY_PROOF.json"
  $routePath = Resolve-Phase160KValidatePath -Root $resolvedRoot -Path "route_change_requests/PHASE160K_QUALITY_ARTIFACT_CONSISTENCY_REQUEST.md"
  Write-Phase160KValidateTextFile -Path $reportPath -Text (@(
    "# PHASE160K Quality Artifact Consistency Report",
    "",
    "ACTIVE_LINE: AGENT_BUILDER_SELF_DEVELOPMENT",
    "MODE: SELF_BUILD / VERIFY",
    "",
    "Canonical candidate_quality/quality_result.json artifacts now align quality gate, promotion manifest, current_state, console, and observer counters.",
    "",
    "Validated ready, revision-required, missing-validator, unsafe, missing-artifact, manifest-mismatch, current-state, console, observer, and PHASE160J1 owner task compatibility scenarios.",
    "",
    "Result: PASS"
  ) -join "`n")
  Write-Phase160KValidateJsonFile -Path $proofPath -Object ([ordered]@{
    status = "PASS"
    phase = "PHASE160K_QUALITY_ARTIFACT_CONSISTENCY_REPAIR_V1"
    active_line = "AGENT_BUILDER_SELF_DEVELOPMENT"
    mode = "SELF_BUILD"
    quality_result_file_written_for_ready_candidate = $true
    quality_result_file_written_for_revision_required = $true
    quality_result_file_written_for_quarantined = $true
    promotion_counters_match_quality_results = $true
    current_state_counters_match_promotion = $true
    missing_quality_result_detected = $true
    manifest_mismatch_detected = $true
    waiting_owner_review_blocked_when_quality_inconsistent = $true
    placeholder_still_revision_required = $true
    unsafe_still_quarantined = $true
    phase160j1_owner_task_state_compatibility_pass = $true
    no_owner_goal_keyword_false_pass = $true
    report_artifacts = @(
      "reports/self_development/quality_artifact_consistency_result.json",
      "reports/self_development/quality_decision_index_result.json",
      "reports/self_development/quality_manifest_alignment_result.json",
      "reports/self_development/quality_promotion_counter_result.json"
    )
    protected_state_mutated = $false
    commit_performed = $false
    push_performed = $false
    branch_switch_performed = $false
    validated_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Write-Phase160KValidateTextFile -Path $routePath -Text (@(
    "# PHASE160K Quality Artifact Consistency Request",
    "",
    "Request: accept PHASE160K as the canonical quality artifact and counter consistency repair before PHASE161.",
    "",
    "Scope remained AGENT_BUILDER_SELF_DEVELOPMENT. No external agents, no package installs, no commit, no push, no branch switch, and no protected state mutation.",
    "",
    "Validator: validators/validate_phase160k_quality_artifact_consistency_v1.ps1"
  ) -join "`n")

  foreach ($jsonPath in @(
    "reports/self_development/quality_artifact_consistency_result.json",
    "reports/self_development/quality_decision_index_result.json",
    "reports/self_development/quality_manifest_alignment_result.json",
    "reports/self_development/quality_promotion_counter_result.json",
    "proofs/self_development/PHASE160K_QUALITY_ARTIFACT_CONSISTENCY_PROOF.json"
  )) {
    Read-Phase160KValidateJson -Root $resolvedRoot -Path $jsonPath | Out-Null
  }

  $protectedAfter = Get-Phase160KValidateFileHashes -Root $resolvedRoot -Paths $protectedPaths
  foreach ($path in $protectedPaths) {
    Assert-Phase160KValidateEquals -Actual $protectedAfter[$path] -Expected $protectedBefore[$path] -Name "protected_state_hash_$path"
  }
  Assert-Phase160KRuntimeOutputsNotStaged
  $branchAfter = (git branch --show-current).Trim()
  $headAfter = (git rev-parse --short HEAD).Trim()
  $remoteAfter = Get-Phase160KValidateRemoteHeadSafe -Branch $branchAfter
  Assert-Phase160KValidateEquals -Actual $branchAfter -Expected $branchBefore -Name "branch_unchanged"
  Assert-Phase160KValidateEquals -Actual $headAfter -Expected $headBefore -Name "head_unchanged_no_commit"
  Assert-Phase160KValidateEquals -Actual $remoteAfter -Expected $remoteBefore -Name "remote_head_unchanged_no_push"

  Write-Host "PHASE160K_QUALITY_ARTIFACT_CONSISTENCY_VALIDATE_RESULT=PASS"
  Write-Host "QUALITY_RESULT_FILE_WRITTEN_FOR_READY_CANDIDATE=True"
  Write-Host "QUALITY_RESULT_FILE_WRITTEN_FOR_REVISION_REQUIRED=True"
  Write-Host "QUALITY_RESULT_FILE_WRITTEN_FOR_QUARANTINED=True"
  Write-Host "PROMOTION_COUNTERS_MATCH_QUALITY_RESULTS=True"
  Write-Host "CURRENT_STATE_COUNTERS_MATCH_PROMOTION=True"
  Write-Host "MISSING_QUALITY_RESULT_DETECTED=True"
  Write-Host "MANIFEST_MISMATCH_DETECTED=True"
  Write-Host "WAITING_OWNER_REVIEW_BLOCKED_WHEN_QUALITY_INCONSISTENT=True"
  Write-Host "PLACEHOLDER_STILL_REVISION_REQUIRED=True"
  Write-Host "UNSAFE_STILL_QUARANTINED=True"
  Write-Host "PHASE160J1_OWNER_TASK_STATE_COMPATIBILITY_PASS=True"
  Write-Host "NO_OWNER_GOAL_KEYWORD_FALSE_PASS=True"
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
