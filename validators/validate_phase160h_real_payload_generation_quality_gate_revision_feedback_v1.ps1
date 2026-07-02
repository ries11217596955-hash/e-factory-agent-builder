param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160HFullPath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160HRepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE160H_VALIDATE_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160HFullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Resolve-Phase160HPath {
  param([string]$RepoRoot, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Assert-Phase160HPathInsideRepo {
  param([string]$RepoRoot, [string]$Path)
  $root = Normalize-Phase160HFullPath -Path $RepoRoot
  $full = Normalize-Phase160HFullPath -Path (Resolve-Phase160HPath -RepoRoot $RepoRoot -Path $Path)
  if (-not ($full -eq $root -or $full.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase))) {
    throw "PHASE160H_VALIDATE_PATH_OUTSIDE_REPO=$Path"
  }
  return $full
}

function ConvertTo-Phase160HRelativePath {
  param([string]$RepoRoot, [string]$FullPath)
  $root = Normalize-Phase160HFullPath -Path $RepoRoot
  $full = Normalize-Phase160HFullPath -Path $FullPath
  if ($full -eq $root) {
    return "."
  }
  if (-not $full.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "PHASE160H_VALIDATE_PATH_OUTSIDE_REPO=$FullPath"
  }
  return ($full.Substring($root.Length + 1) -replace "\\", "/")
}

function Write-Phase160HJsonFile {
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

function Write-Phase160HTextFile {
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

function Read-Phase160HJson {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160HPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160H_VALIDATE_MISSING_JSON=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase160HText {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160HPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160H_VALIDATE_MISSING_TEXT=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw
}

function Assert-Phase160HEquals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160H_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase160HTrue {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $true) {
    throw "PHASE160H_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase160HFalse {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $false) {
    throw "PHASE160H_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase160HAtLeast {
  param([object]$Actual, [int]$Minimum, [string]$Name)
  if ([int]$Actual -lt $Minimum) {
    throw "PHASE160H_VALIDATE_COUNT_TOO_LOW=$Name actual=$Actual minimum=$Minimum"
  }
}

function Assert-Phase160HParserClean {
  param([string]$Path)
  $tokens = $null
  $parseErrors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors) | Out-Null
  if ($parseErrors.Count -gt 0) {
    throw "PHASE160H_VALIDATE_PARSE_ERROR=$Path message=$($parseErrors[0].Message)"
  }
}

function Remove-Phase160HOutput {
  param([string]$RepoRoot, [string]$Path)
  $full = Assert-Phase160HPathInsideRepo -RepoRoot $RepoRoot -Path $Path
  if (Test-Path -LiteralPath $full) {
    Remove-Item -LiteralPath $full -Recurse -Force
  }
}

function Get-Phase160HRemoteHead {
  param([string]$ExpectedBranch)
  $remoteHead = (git rev-parse --short "origin/$ExpectedBranch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    throw "PHASE160H_VALIDATE_REMOTE_HEAD_UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Get-Phase160HFileHashes {
  param([string]$RepoRoot, [string[]]$Paths)
  $hashes = @{}
  foreach ($path in $Paths) {
    $full = Resolve-Phase160HPath -RepoRoot $RepoRoot -Path $path
    if (Test-Path -LiteralPath $full) {
      $hashes[$path] = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
    } else {
      $hashes[$path] = "MISSING"
    }
  }
  return $hashes
}

function Assert-Phase160HRuntimeOutputsNotStaged {
  $stagedRuntime = @(git diff --cached --name-only -- runtime_sessions)
  if ($stagedRuntime.Count -gt 0) {
    throw "PHASE160H_VALIDATE_RUNTIME_OUTPUTS_STAGED=$($stagedRuntime -join '; ')"
  }
}

function Assert-Phase160HRuntimeJsonClean {
  param([string]$RepoRoot, [string[]]$SessionRoots)
  foreach ($sessionRoot in $SessionRoots) {
    $full = Resolve-Phase160HPath -RepoRoot $RepoRoot -Path $sessionRoot
    if (-not (Test-Path -LiteralPath $full)) {
      continue
    }
    foreach ($jsonFile in @(Get-ChildItem -LiteralPath $full -File -Filter "*.json" -Recurse -ErrorAction SilentlyContinue)) {
      try {
        Get-Content -LiteralPath $jsonFile.FullName -Raw | ConvertFrom-Json | Out-Null
      } catch {
        throw "PHASE160H_VALIDATE_RUNTIME_JSON_PARSE_ERROR=$($jsonFile.FullName) message=$($_.Exception.Message)"
      }
    }
  }
}

function Invoke-Phase160HScriptJson {
  param([string]$RepoRoot, [string]$ScriptPath, [string[]]$Arguments)
  $fullScript = Resolve-Phase160HPath -RepoRoot $RepoRoot -Path $ScriptPath
  $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File $fullScript @Arguments 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160H_VALIDATE_SCRIPT_FAILED script=$ScriptPath output=$($output -join ' | ')"
  }
  return ($output -join "`n") | ConvertFrom-Json
}

function New-Phase160HSessionFixture {
  param([string]$RepoRoot, [string]$SessionRoot, [string]$RunId, [string]$Branch, [string]$Head)
  $sessionFull = Resolve-Phase160HPath -RepoRoot $RepoRoot -Path $SessionRoot
  New-Item -ItemType Directory -Force -Path $sessionFull, (Join-Path $sessionFull "candidate_workspace/candidate_bundles"), (Join-Path $sessionFull "candidate_workspace/candidate_queue"), (Join-Path $sessionFull "candidate_workspace/candidate_quarantine"), (Join-Path $sessionFull "promotion_bundle"), (Join-Path $sessionFull "active_task"), (Join-Path $sessionFull "task_lifecycle"), (Join-Path $sessionFull "blocker_queue") | Out-Null
  Write-Phase160HJsonFile -Path (Join-Path $sessionFull "run_manifest.json") -Object ([ordered]@{
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
  Write-Phase160HJsonFile -Path (Join-Path $sessionFull "runtime_guard.json") -Object ([ordered]@{
    status = "PASS"
    run_id = $RunId
    run_head = $Head
    current_head = $Head
    head_match = $true
    candidate_production_enabled = $true
    allowed_runtime_output_count = 0
    unsafe_tracked_code_mutation_count = 0
    protected_state_mutation_count = 0
    blocked_reasons = @()
    checked_at = (Get-Date).ToUniversalTime().ToString("o")
  })
}

function New-Phase160HRealModuleText {
  param([string]$CandidateId)
  return @"
param(
  [string]`$InputPath = "",
  [string]`$OutputPath = ""
)

`$ErrorActionPreference = "Stop"

function Invoke-Phase160HFixturePayload {
  param([string]`$CandidateId)
  `$signals = @(
    "real_module_payload_executed",
    "candidate_validation_plan_required",
    "owner_promotion_gate_preserved",
    "runtime_session_only"
  )
  return [pscustomobject][ordered]@{
    status = "PASS"
    candidate_id = `$CandidateId
    execution_signals = `$signals
    accepted_code_written = `$false
    repo_mutation_performed = `$false
    commit_performed = `$false
    push_performed = `$false
    branch_switch_performed = `$false
    protected_state_mutated = `$false
    executed_at = (Get-Date).ToUniversalTime().ToString("o")
  }
}

`$result = Invoke-Phase160HFixturePayload -CandidateId "$CandidateId"
if (-not [string]::IsNullOrWhiteSpace(`$OutputPath)) {
  `$directory = Split-Path -Path `$OutputPath -Parent
  if (`$directory -and -not (Test-Path -LiteralPath `$directory)) {
    New-Item -ItemType Directory -Force -Path `$directory | Out-Null
  }
  `$json = (`$result | ConvertTo-Json -Depth 20) -replace "`r`n", "`n"
  if (-not `$json.EndsWith("`n")) { `$json += "`n" }
  [System.IO.File]::WriteAllText(`$OutputPath, `$json, [System.Text.UTF8Encoding]::new(`$false))
}
`$result | ConvertTo-Json -Depth 20
"@
}

function New-Phase160HRealValidatorText {
  param([string]$CandidateId, [string]$ModuleTarget)
  return @"
param(
  [string]`$PayloadRoot = "."
)

`$ErrorActionPreference = "Stop"

function Assert-Phase160HFixtureTrue {
  param([object]`$Actual, [string]`$Name)
  if (`$Actual -ne `$true) {
    throw "PHASE160H_FIXTURE_ASSERT_TRUE_FAILED=`$Name actual=`$Actual"
  }
}

function Assert-Phase160HFixtureParse {
  param([string]`$Path)
  `$tokens = `$null
  `$parseErrors = `$null
  [System.Management.Automation.Language.Parser]::ParseFile(`$Path, [ref]`$tokens, [ref]`$parseErrors) | Out-Null
  if (`$parseErrors.Count -gt 0) {
    throw "PHASE160H_FIXTURE_PARSE_FAILED=`$Path message=`$(`$parseErrors[0].Message)"
  }
}

`$modulePath = Join-Path `$PayloadRoot "$ModuleTarget"
Assert-Phase160HFixtureTrue -Actual (Test-Path -LiteralPath `$modulePath) -Name "module_payload_exists"
Assert-Phase160HFixtureParse -Path `$modulePath
`$text = Get-Content -LiteralPath `$modulePath -Raw
Assert-Phase160HFixtureTrue -Actual (`$text -match "real_module_payload_executed") -Name "real_module_execution_signal"
[pscustomobject][ordered]@{
  status = "PASS"
  candidate_id = "$CandidateId"
  module_payload_exists = `$true
  module_payload_parse_pass = `$true
  owner_promotion_gate_preserved = `$true
  accepted_code_written = `$false
  commit_performed = `$false
  push_performed = `$false
  branch_switch_performed = `$false
  protected_state_mutated = `$false
  validated_at = (Get-Date).ToUniversalTime().ToString("o")
} | ConvertTo-Json -Depth 20
"@
}

function New-Phase160HCandidateFixture {
  param(
    [string]$RepoRoot,
    [string]$SessionRoot,
    [string]$CandidateId,
    [string]$OwnerGoal,
    [string]$Scenario,
    [string]$ModuleTarget = "",
    [string]$ValidatorTarget = "",
    [string]$ModuleText = "",
    [string]$ValidatorText = "",
    [switch]$MissingValidatorPayload,
    [switch]$NoProposedPayloads
  )
  $sessionFull = Resolve-Phase160HPath -RepoRoot $RepoRoot -Path $SessionRoot
  $candidateDir = Join-Path $sessionFull "candidate_workspace/candidate_bundles/$CandidateId"
  New-Item -ItemType Directory -Force -Path $candidateDir, (Join-Path $candidateDir "proposed_patch_or_file_payloads/modules"), (Join-Path $candidateDir "proposed_patch_or_file_payloads/validators") | Out-Null
  if ([string]::IsNullOrWhiteSpace($ModuleTarget)) {
    $ModuleTarget = "modules/invoke_phase160h_${CandidateId}_candidate.ps1"
  }
  if ([string]::IsNullOrWhiteSpace($ValidatorTarget)) {
    $ValidatorTarget = "validators/validate_phase160h_${CandidateId}_candidate.ps1"
  }
  $modulePayloadPath = "proposed_patch_or_file_payloads/modules/{0}" -f (Split-Path -Path $ModuleTarget -Leaf)
  $validatorPayloadPath = "proposed_patch_or_file_payloads/validators/{0}" -f (Split-Path -Path $ValidatorTarget -Leaf)
  $modulePayloadFullPath = Join-Path $candidateDir ($modulePayloadPath -replace "/", [System.IO.Path]::DirectorySeparatorChar)
  $validatorPayloadFullPath = Join-Path $candidateDir ($validatorPayloadPath -replace "/", [System.IO.Path]::DirectorySeparatorChar)
  if (-not $NoProposedPayloads) {
    Write-Phase160HTextFile -Path $modulePayloadFullPath -Text $ModuleText
    if (-not $MissingValidatorPayload) {
      Write-Phase160HTextFile -Path $validatorPayloadFullPath -Text $ValidatorText
    }
  } else {
    Write-Phase160HJsonFile -Path (Join-Path $candidateDir "proposed_patch_or_file_payloads/payload.json") -Object ([ordered]@{
      status = "PASS"
      candidate_id = $CandidateId
      scenario = $Scenario
      proposed_module_payload = [ordered]@{ marker_only = $true }
      proposed_validator_payload = [ordered]@{ marker_only = $true }
    })
  }
  $payloadEntries = @()
  if (-not $NoProposedPayloads) {
    $payloadEntries += [ordered]@{
      kind = "module"
      target_path = $ModuleTarget
      payload_path = $modulePayloadPath
      parse_required = $true
      required = $true
    }
    if (-not $MissingValidatorPayload) {
      $payloadEntries += [ordered]@{
        kind = "validator"
        target_path = $ValidatorTarget
        payload_path = $validatorPayloadPath
        parse_required = $true
        required = $true
      }
    }
  }
  Write-Phase160HJsonFile -Path (Join-Path $candidateDir "candidate_manifest.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = $CandidateId
    source_task_id = "PHASE160H_$Scenario"
    source = "owner_task"
    source_plan_item_id = "NONE"
    source_internal_goal_id = "NONE"
    source_internal_goal_name = "NONE"
    created_from_run_head = (git rev-parse --short HEAD).Trim()
    run_id = Split-Path -Path $SessionRoot -Leaf
    target_area = "phase160h_quality_gate_fixture"
    owner_goal = $OwnerGoal
    desired_next_gap = "PHASE160H_REAL_PAYLOAD_QUALITY_GATE"
    proposed_file_paths = @($ModuleTarget)
    proposed_validator_paths = if ($MissingValidatorPayload) { @() } else { @($ValidatorTarget) }
    acceptance_validator_needed = if ($MissingValidatorPayload) { @() } else { @($ValidatorTarget) }
    owner_approval_required = $true
    owner_promotion_gate_required = $true
    candidate_output_is_not_accepted_code = $true
    repo_mutation_performed = $false
    commit_performed = $false
    push_performed = $false
    branch_switch_performed = $false
    protected_state_mutated = $false
    decision = "CANDIDATE_READY"
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Write-Phase160HJsonFile -Path (Join-Path $candidateDir "proposed_files.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = $CandidateId
    proposed_file_paths = @($ModuleTarget)
    proposed_validator_paths = if ($MissingValidatorPayload) { @() } else { @($ValidatorTarget) }
    proposed_payloads = @($payloadEntries)
    proposed_only = $true
    accepted_code_written = $false
  })
  Write-Phase160HJsonFile -Path (Join-Path $candidateDir "candidate_validation_plan.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = $CandidateId
    validators_required_before_acceptance = if ($MissingValidatorPayload) { @() } else { @($ValidatorTarget) }
    materialization_parse_check_required = $true
    owner_review_required = $true
  })
  Write-Phase160HJsonFile -Path (Join-Path $candidateDir "candidate_risk_review.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = $CandidateId
    repo_mutation_performed = $false
    accepted_state_mutated = $false
    risks = @("fixture candidate for quality gate validation")
    mitigations = @("quality gate must decide promotion eligibility")
  })
  Write-Phase160HJsonFile -Path (Join-Path $candidateDir "candidate_status.json") -Object ([ordered]@{
    status = "CANDIDATE_READY"
    candidate_id = $CandidateId
    owner_promotion_allowed = $true
    promotion_status = "WAITING_OWNER_REVIEW"
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  return ConvertTo-Phase160HRelativePath -RepoRoot $RepoRoot -FullPath $candidateDir
}

function Invoke-Phase160HQualityAndFinalize {
  param([string]$RepoRoot, [string]$SessionRoot, [string]$RunId, [string]$CandidateDir)
  $quality = Invoke-Phase160HScriptJson -RepoRoot $RepoRoot -ScriptPath "modules/inspect_builder_candidate_quality_gate_001.ps1" -Arguments @("-CandidateDir", $CandidateDir, "-SessionRoot", $SessionRoot, "-RunId", $RunId)
  $promotion = Invoke-Phase160HScriptJson -RepoRoot $RepoRoot -ScriptPath "modules/finalize_builder_promotion_bundle_001.ps1" -Arguments @("-SessionRoot", $SessionRoot, "-RunId", $RunId)
  return [pscustomobject][ordered]@{
    quality = $quality
    promotion = $promotion
  }
}

$Pushed = $false

try {
  $RepoRootParameter = $RepoRoot
  $RepoRoot = Resolve-Phase160HRepoRoot
  Push-Location $RepoRoot
  $Pushed = $true
  if ($RepoRootParameter -ne "." -and (Normalize-Phase160HFullPath -Path $RepoRootParameter) -ne $RepoRoot) {
    throw "PHASE160H_VALIDATE_REPO_ROOT_PARAMETER_MISMATCH=$RepoRootParameter"
  }

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160HPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
  $Branch = (git branch --show-current).Trim()
  Assert-Phase160HEquals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  $RemoteHead = Get-Phase160HRemoteHead -ExpectedBranch $ExpectedBranch
  Assert-Phase160HEquals -Actual $Head -Expected $RemoteHead -Name "current_synced_repo_head"

  $RepairId = "PHASE160H_REAL_PAYLOAD_GENERATION_QUALITY_GATE_AND_REVISION_FEEDBACK_MACRO_REPAIR_V1"
  $RuntimeRoot = "runtime_sessions/live_growth/p160h_qg"
  $GeneratorRunId = "p160h_gen"
  $GeneratorSessionRoot = "runtime_sessions/live_growth/$GeneratorRunId"
  $RevisionRunId = "p160h_rev"
  $RevisionSessionRoot = "runtime_sessions/live_growth/$RevisionRunId"
  $ConsoleRunId = "p160h_console"
  $ConsoleRuntimeRoot = "runtime_sessions/live_growth_console/$ConsoleRunId"
  $ReportPath = "reports/self_development/PHASE160H_REAL_PAYLOAD_GENERATION_QUALITY_GATE_REVISION_FEEDBACK_REPORT.md"
  $ProofPath = "proofs/self_development/PHASE160H_REAL_PAYLOAD_GENERATION_QUALITY_GATE_REVISION_FEEDBACK_PROOF.json"
  $RouteRequestPath = "route_change_requests/PHASE160H_REAL_PAYLOAD_GENERATION_QUALITY_GATE_REVISION_FEEDBACK_REQUEST.md"
  $ProtectedPaths = @("TASK_QUEUE.json", "GENESIS_STATE.json", "CAPABILITY_ROADMAP.json", "packs/registry.json", "orchestrator/run.ps1")
  $TouchedScripts = @(
    "modules/invoke_builder_candidate_workspace_step_001.ps1",
    "modules/finalize_builder_promotion_bundle_001.ps1",
    "modules/watch_builder_live_console_001.ps1",
    "modules/watch_builder_live_growth_session_observer_001.ps1",
    "modules/start_builder_live_growth_daemon_001.ps1",
    "modules/inspect_builder_candidate_quality_gate_001.ps1",
    "modules/invoke_builder_candidate_revision_request_001.ps1",
    "modules/test_builder_candidate_payload_materialization_001.ps1",
    "validators/validate_phase160h_real_payload_generation_quality_gate_revision_feedback_v1.ps1"
  )
  foreach ($script in $TouchedScripts) {
    Assert-Phase160HParserClean -Path (Resolve-Phase160HPath -RepoRoot $RepoRoot -Path $script)
  }

  $ProtectedHashesBefore = Get-Phase160HFileHashes -RepoRoot $RepoRoot -Paths $ProtectedPaths
  foreach ($runtimePath in @($RuntimeRoot, $GeneratorSessionRoot, $RevisionSessionRoot, $ConsoleRuntimeRoot)) {
    Remove-Phase160HOutput -RepoRoot $RepoRoot -Path $runtimePath
  }

  $ScenarioResults = @{}
  $scenarioSpecs = @(
    [ordered]@{ key = "placeholder"; run_id = "p160h_ph"; candidate_id = "c_ph"; module_target = "modules/p160h_accepted_candidate_placeholder.ps1"; missing_validator = $false; empty = $false; unsafe = $false; no_payloads = $false; owner_goal = "Placeholder path must fail even with real text." },
    [ordered]@{ key = "empty"; run_id = "p160h_empty"; candidate_id = "c_empty"; module_target = "modules/p160h_empty.ps1"; missing_validator = $false; empty = $true; unsafe = $false; no_payloads = $false; owner_goal = "Empty payload candidate must fail." },
    [ordered]@{ key = "missing_validator"; run_id = "p160h_missval"; candidate_id = "c_missval"; module_target = "modules/p160h_missval.ps1"; missing_validator = $true; empty = $false; unsafe = $false; no_payloads = $false; owner_goal = "Missing validator payload must fail." },
    [ordered]@{ key = "real"; run_id = "p160h_real"; candidate_id = "c_real"; module_target = "modules/p160h_real.ps1"; missing_validator = $false; empty = $false; unsafe = $false; no_payloads = $false; owner_goal = "Real module and validator payload may be ready." },
    [ordered]@{ key = "unsafe"; run_id = "p160h_unsafe"; candidate_id = "c_unsafe"; module_target = "modules/p160h_unsafe.ps1"; missing_validator = $false; empty = $false; unsafe = $true; no_payloads = $false; owner_goal = "Unsafe mutation request must be quarantined." },
    [ordered]@{ key = "regression"; run_id = "p160h_reg"; candidate_id = "c_reg"; module_target = "modules/p160h_reg_accepted_candidate_placeholder.ps1"; missing_validator = $false; empty = $false; unsafe = $false; no_payloads = $true; owner_goal = "PHASE160H failed pattern had marker-only payload." },
    [ordered]@{ key = "keyword_false_pass"; run_id = "p160h_kw"; candidate_id = "c_kw"; module_target = "modules/p160h_kw.ps1"; missing_validator = $false; empty = $false; unsafe = $false; no_payloads = $true; owner_goal = "owner_goal says real module payload validator CANDIDATE_READY but files are absent." }
  )

  foreach ($spec in $scenarioSpecs) {
    $sessionRoot = "$RuntimeRoot/$($spec.run_id)"
    New-Phase160HSessionFixture -RepoRoot $RepoRoot -SessionRoot $sessionRoot -RunId ([string]$spec.run_id) -Branch $Branch -Head $Head
    $candidateId = [string]$spec.candidate_id
    $moduleText = if ([bool]$spec.empty) { "" } elseif ([bool]$spec.unsafe) { (New-Phase160HRealModuleText -CandidateId $candidateId) + "`n`ngit commit -m `"unsafe candidate mutation request`"`n" } else { New-Phase160HRealModuleText -CandidateId $candidateId }
    $validatorTarget = "validators/validate_phase160h_$candidateId.ps1"
    $validatorText = if ([bool]$spec.empty) { "" } else { New-Phase160HRealValidatorText -CandidateId $candidateId -ModuleTarget ([string]$spec.module_target) }
    $candidateDir = New-Phase160HCandidateFixture -RepoRoot $RepoRoot -SessionRoot $sessionRoot -CandidateId $candidateId -OwnerGoal ([string]$spec.owner_goal) -Scenario ([string]$spec.key) -ModuleTarget ([string]$spec.module_target) -ValidatorTarget $validatorTarget -ModuleText $moduleText -ValidatorText $validatorText -MissingValidatorPayload:([bool]$spec.missing_validator) -NoProposedPayloads:([bool]$spec.no_payloads)
    $ScenarioResults[[string]$spec.key] = Invoke-Phase160HQualityAndFinalize -RepoRoot $RepoRoot -SessionRoot $sessionRoot -RunId ([string]$spec.run_id) -CandidateDir $candidateDir
  }

  Assert-Phase160HEquals -Actual $ScenarioResults["placeholder"].quality.quality_status -Expected "REVISION_REQUIRED" -Name "placeholder_revision_required"
  Assert-Phase160HFalse -Actual ([string]$ScenarioResults["placeholder"].quality.quality_status -eq "CANDIDATE_READY") -Name "placeholder_not_ready"
  Assert-Phase160HFalse -Actual ([string]$ScenarioResults["placeholder"].promotion.promotion_bundle_status -eq "WAITING_OWNER_REVIEW") -Name "placeholder_not_waiting_owner_review"
  Assert-Phase160HEquals -Actual $ScenarioResults["empty"].quality.quality_status -Expected "REVISION_REQUIRED" -Name "empty_revision_required"
  Assert-Phase160HEquals -Actual $ScenarioResults["missing_validator"].quality.quality_status -Expected "REVISION_REQUIRED" -Name "missing_validator_revision_required"
  Assert-Phase160HEquals -Actual $ScenarioResults["real"].quality.quality_status -Expected "CANDIDATE_READY" -Name "real_candidate_ready"
  Assert-Phase160HEquals -Actual $ScenarioResults["real"].promotion.promotion_bundle_status -Expected "WAITING_OWNER_REVIEW" -Name "real_candidate_waiting_owner_review"
  Assert-Phase160HTrue -Actual $ScenarioResults["real"].quality.materialization_parse_check_pass -Name "real_materialization_parse_pass"
  Assert-Phase160HTrue -Actual (@("QUARANTINED", "BLOCKED") -contains [string]$ScenarioResults["unsafe"].quality.quality_status) -Name "unsafe_quarantined_or_blocked"
  Assert-Phase160HEquals -Actual $ScenarioResults["regression"].quality.quality_status -Expected "REVISION_REQUIRED" -Name "regression_revision_required"
  Assert-Phase160HFalse -Actual ([string]$ScenarioResults["regression"].promotion.promotion_bundle_status -eq "WAITING_OWNER_REVIEW") -Name "regression_not_waiting"
  Assert-Phase160HEquals -Actual $ScenarioResults["keyword_false_pass"].quality.quality_status -Expected "REVISION_REQUIRED" -Name "keyword_false_pass_revision_required"
  Assert-Phase160HFalse -Actual ([string]$ScenarioResults["keyword_false_pass"].promotion.promotion_bundle_status -eq "WAITING_OWNER_REVIEW") -Name "keyword_false_pass_not_waiting"
  Assert-Phase160HTrue -Actual (Test-Path -LiteralPath (Resolve-Phase160HPath -RepoRoot $RepoRoot -Path ([string]$ScenarioResults["placeholder"].quality.revision_request_path))) -Name "revision_request_created"

  New-Phase160HSessionFixture -RepoRoot $RepoRoot -SessionRoot $GeneratorSessionRoot -RunId $GeneratorRunId -Branch $Branch -Head $Head
  $generatorSessionFull = Resolve-Phase160HPath -RepoRoot $RepoRoot -Path $GeneratorSessionRoot
  Write-Phase160HJsonFile -Path (Join-Path $generatorSessionFull "active_task/active_task.json") -Object ([ordered]@{
    status = "ACTIVE"
    task_id = "REAL_PAYLOAD_TASK"
    source = "owner"
    priority = "high"
    owner_goal = "Generate a real module payload and validator payload by default."
    desired_next_gap = "REAL_PAYLOAD_GENERATION_GATE"
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  $GeneratorStep = Invoke-Phase160HScriptJson -RepoRoot $RepoRoot -ScriptPath "modules/invoke_builder_candidate_workspace_step_001.ps1" -Arguments @("-SessionRoot", $GeneratorSessionRoot, "-RunId", $GeneratorRunId, "-DutyId", "phase160h_generator", "-TickNumber", "1")
  Assert-Phase160HTrue -Actual $GeneratorStep.quality_gate_enabled -Name "generator_quality_gate_enabled"
  Assert-Phase160HAtLeast -Actual $GeneratorStep.quality_ready_count -Minimum 1 -Name "generator_quality_ready_count"
  $generatedCandidateManifest = @(Get-ChildItem -LiteralPath (Resolve-Phase160HPath -RepoRoot $RepoRoot -Path "$GeneratorSessionRoot/candidate_workspace/candidate_bundles") -File -Filter "candidate_manifest.json" -Recurse | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json } | Select-Object -First 1)[0]
  $generatedProposedFiles = Read-Phase160HJson -RepoRoot $RepoRoot -Path "$GeneratorSessionRoot/candidate_workspace/candidate_bundles/$($generatedCandidateManifest.candidate_id)/proposed_files.json"
  Assert-Phase160HAtLeast -Actual @($generatedProposedFiles.proposed_payloads).Count -Minimum 2 -Name "generator_proposed_payload_entries"
  Assert-Phase160HTrue -Actual (@($generatedProposedFiles.proposed_payloads | Where-Object { [string]$_.kind -eq "module" }).Count -ge 1) -Name "generator_module_payload_entry"
  Assert-Phase160HTrue -Actual (@($generatedProposedFiles.proposed_payloads | Where-Object { [string]$_.kind -eq "validator" }).Count -ge 1) -Name "generator_validator_payload_entry"
  Assert-Phase160HFalse -Actual (@($generatedCandidateManifest.proposed_file_paths | Where-Object { [string]$_ -match "placeholder|accepted_candidate_placeholder" }).Count -gt 0) -Name "generator_no_placeholder_path"

  New-Phase160HSessionFixture -RepoRoot $RepoRoot -SessionRoot $RevisionSessionRoot -RunId $RevisionRunId -Branch $Branch -Head $Head
  $revisionSessionFull = Resolve-Phase160HPath -RepoRoot $RepoRoot -Path $RevisionSessionRoot
  Write-Phase160HJsonFile -Path (Join-Path $revisionSessionFull "active_task/active_task.json") -Object ([ordered]@{
    status = "ACTIVE"
    task_id = "REVFEED"
    source = "owner"
    priority = "high"
    owner_goal = "Retry candidate generation using revision feedback."
    desired_next_gap = "REVISION_FEEDBACK_GATE"
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  $failedBaseDir = New-Phase160HCandidateFixture -RepoRoot $RepoRoot -SessionRoot $RevisionSessionRoot -CandidateId "cand_REVFEED" -OwnerGoal "Existing failed candidate requiring revision." -Scenario "revision_feedback_seed" -ModuleTarget "modules/revfb_accepted_candidate_placeholder.ps1" -ValidatorTarget "validators/val_revfb.ps1" -ModuleText (New-Phase160HRealModuleText -CandidateId "cand_REVFEED") -ValidatorText (New-Phase160HRealValidatorText -CandidateId "cand_REVFEED" -ModuleTarget "modules/revfb_accepted_candidate_placeholder.ps1")
  $null = Invoke-Phase160HScriptJson -RepoRoot $RepoRoot -ScriptPath "modules/inspect_builder_candidate_quality_gate_001.ps1" -Arguments @("-CandidateDir", $failedBaseDir, "-SessionRoot", $RevisionSessionRoot, "-RunId", $RevisionRunId)
  $RevisionStep = Invoke-Phase160HScriptJson -RepoRoot $RepoRoot -ScriptPath "modules/invoke_builder_candidate_workspace_step_001.ps1" -Arguments @("-SessionRoot", $RevisionSessionRoot, "-RunId", $RevisionRunId, "-DutyId", "phase160h_revision_feedback", "-TickNumber", "1")
  $retryManifest = @(Get-ChildItem -LiteralPath (Resolve-Phase160HPath -RepoRoot $RepoRoot -Path "$RevisionSessionRoot/candidate_workspace/candidate_bundles") -File -Filter "candidate_manifest.json" -Recurse | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json } | Where-Object { [string]$_.candidate_id -match "retry_01" } | Select-Object -First 1)[0]
  Assert-Phase160HTrue -Actual ($null -ne $retryManifest) -Name "retry_candidate_created"
  Assert-Phase160HTrue -Actual $retryManifest.revision_feedback_considered -Name "revision_feedback_considered"
  Assert-Phase160HAtLeast -Actual @($retryManifest.consumed_revision_feedback.what_failed).Count -Minimum 1 -Name "revision_feedback_consumed"
  Assert-Phase160HAtLeast -Actual $RevisionStep.quality_ready_count -Minimum 1 -Name "revision_retry_ready"

  $ObserveResult = Invoke-Phase160HScriptJson -RepoRoot $RepoRoot -ScriptPath "modules/watch_builder_live_growth_session_observer_001.ps1" -Arguments @("-SessionRoot", $GeneratorSessionRoot, "-DurationSeconds", "2", "-PollIntervalSeconds", "1")
  Remove-Phase160HOutput -RepoRoot $RepoRoot -Path $ConsoleRuntimeRoot
  $ConsoleOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File (Resolve-Phase160HPath -RepoRoot $RepoRoot -Path "modules/watch_builder_live_console_001.ps1") -SessionRoot $GeneratorSessionRoot -DurationSeconds 2 -PollIntervalSeconds 1 -ConsoleRunId $ConsoleRunId -ConsoleRuntimeRoot $ConsoleRuntimeRoot 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160H_VALIDATE_CONSOLE_FAILED output=$($ConsoleOutput -join ' | ')"
  }
  $ConsoleSample = Read-Phase160HText -RepoRoot $RepoRoot -Path "$ConsoleRuntimeRoot/console_output_sample.txt"
  foreach ($requiredConsoleField in @("QUALITY_GATE_ENABLED=", "QUALITY_READY_COUNT=", "REVISION_REQUIRED_COUNT=", "DRAFT_CANDIDATE_COUNT=", "QUARANTINED_CANDIDATE_COUNT=", "LAST_QUALITY_DECISION=", "LAST_REVISION_REQUEST=", "OWNER_PROMOTION_ALLOWED=", "PROMOTION_BUNDLE_STATUS=")) {
    Assert-Phase160HTrue -Actual ($ConsoleSample -match [regex]::Escape($requiredConsoleField)) -Name "console_field:$requiredConsoleField"
  }
  Assert-Phase160HTrue -Actual $ObserveResult.quality_gate_enabled -Name "observer_quality_gate_enabled"
  Assert-Phase160HAtLeast -Actual $ObserveResult.quality_ready_count -Minimum 1 -Name "observer_quality_ready_count"

  Assert-Phase160HRuntimeJsonClean -RepoRoot $RepoRoot -SessionRoots @($RuntimeRoot, $GeneratorSessionRoot, $RevisionSessionRoot, $ConsoleRuntimeRoot)
  $BranchAfter = (git branch --show-current).Trim()
  $HeadAfter = (git rev-parse --short HEAD).Trim()
  $RemoteHeadAfter = Get-Phase160HRemoteHead -ExpectedBranch $ExpectedBranch
  Assert-Phase160HEquals -Actual $BranchAfter -Expected $Branch -Name "branch_after"
  Assert-Phase160HEquals -Actual $HeadAfter -Expected $Head -Name "head_after"
  Assert-Phase160HEquals -Actual $RemoteHeadAfter -Expected $RemoteHead -Name "remote_head_after"
  $ProtectedHashesAfter = Get-Phase160HFileHashes -RepoRoot $RepoRoot -Paths $ProtectedPaths
  foreach ($path in $ProtectedPaths) {
    Assert-Phase160HEquals -Actual $ProtectedHashesAfter[$path] -Expected $ProtectedHashesBefore[$path] -Name "protected_hash:$path"
  }
  Assert-Phase160HRuntimeOutputsNotStaged

  $Proof = [ordered]@{
    status = "PASS"
    acceptance_language = "PHASE160H_REAL_PAYLOAD_GENERATION_QUALITY_GATE_REVISION_FEEDBACK_VALIDATE_RESULT=PASS"
    repair_id = $RepairId
    branch = $Branch
    local_head = $Head
    remote_head = $RemoteHead
    parser_checks_pass = $true
    real_payload_generation_enabled = $true
    placeholder_candidate_revision_required = $true
    empty_payload_revision_required = $true
    missing_validator_payload_revision_required = $true
    real_module_and_validator_payload_ready = $true
    unsafe_candidate_quarantined = $true
    revision_request_created = $true
    revision_feedback_to_generator_enabled = $true
    promotion_waiting_owner_review_only_for_quality_ready = $true
    owner_promotion_blocked_for_weak_candidates = $true
    materialization_parse_check_pass = $true
    no_owner_goal_keyword_false_pass = $true
    live_repo_guard_pass = $true
    run_head_match = $true
    no_commit_performed = $true
    no_push_performed = $true
    no_branch_switch = $true
    protected_state_mutated = $false
    runtime_outputs_staged = $false
    generated_candidate_id = [string]$generatedCandidateManifest.candidate_id
    retry_candidate_id = [string]$retryManifest.candidate_id
    console_runtime_root = $ConsoleRuntimeRoot
    report_path = $ReportPath
    proof_path = $ProofPath
    route_request_path = $RouteRequestPath
    validated_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Phase160HJsonFile -Path (Resolve-Phase160HPath -RepoRoot $RepoRoot -Path $ProofPath) -Object $Proof

  $ReportLines = @(
    "# PHASE160H Real Payload Generation, Quality Gate, And Revision Feedback Report",
    "",
    "status: PASS",
    "repair_id: $RepairId",
    "line: AGENT_BUILDER_SELF_DEVELOPMENT",
    "mode: VERIFY",
    "",
    "## Result",
    "PHASE160H_REAL_PAYLOAD_GENERATION_QUALITY_GATE_REVISION_FEEDBACK_VALIDATE_RESULT=PASS",
    "REAL_PAYLOAD_GENERATION_ENABLED=True",
    "PLACEHOLDER_CANDIDATE_REVISION_REQUIRED=True",
    "EMPTY_PAYLOAD_REVISION_REQUIRED=True",
    "MISSING_VALIDATOR_PAYLOAD_REVISION_REQUIRED=True",
    "REAL_MODULE_AND_VALIDATOR_PAYLOAD_READY=True",
    "UNSAFE_CANDIDATE_QUARANTINED=True",
    "REVISION_REQUEST_CREATED=True",
    "REVISION_FEEDBACK_TO_GENERATOR_ENABLED=True",
    "PROMOTION_WAITING_OWNER_REVIEW_ONLY_FOR_QUALITY_READY=True",
    "OWNER_PROMOTION_BLOCKED_FOR_WEAK_CANDIDATES=True",
    "MATERIALIZATION_PARSE_CHECK_PASS=True",
    "NO_OWNER_GOAL_KEYWORD_FALSE_PASS=True",
    "LIVE_REPO_GUARD_PASS=True",
    "RUN_HEAD_MATCH=True",
    "NO_COMMIT_PERFORMED=True",
    "NO_PUSH_PERFORMED=True",
    "NO_BRANCH_SWITCH=True",
    "PROTECTED_STATE_MUTATED=False",
    "RUNTIME_OUTPUTS_STAGED=False",
    "",
    "## Proof Summary",
    "- Generated candidate: $($generatedCandidateManifest.candidate_id)",
    "- Retry candidate: $($retryManifest.candidate_id)",
    "- Real payload promotion status: $($ScenarioResults["real"].promotion.promotion_bundle_status)",
    "- Unsafe quality status: $($ScenarioResults["unsafe"].quality.quality_status)",
    "- Console quality fields present: True",
    "- Observer quality fields present: True",
    "",
    "## Validation Command",
    '```powershell',
    ".\validators\validate_phase160h_real_payload_generation_quality_gate_revision_feedback_v1.ps1 -RepoRoot .",
    '```',
    "",
    "## Boundaries",
    "- No TASK_QUEUE, GENESIS_STATE, CAPABILITY_ROADMAP, packs/registry, or orchestrator edits.",
    "- Candidate payloads stayed under runtime_sessions.",
    "- No external-agent production, dependency install, internet use, commit, push, or branch switch.",
    "- Runtime outputs were not staged."
  )
  Write-Phase160HTextFile -Path (Resolve-Phase160HPath -RepoRoot $RepoRoot -Path $ReportPath) -Text ($ReportLines -join "`n")

  $RouteLines = @(
    "# PHASE160H Real Payload Generation Quality Gate Revision Feedback Request",
    "",
    "repair_id: $RepairId",
    "line: AGENT_BUILDER_SELF_DEVELOPMENT",
    "mode: VERIFY",
    "validator: validators/validate_phase160h_real_payload_generation_quality_gate_revision_feedback_v1.ps1",
    "report: $ReportPath",
    "proof: $ProofPath",
    "",
    "## Route Change",
    "- Candidate generator now writes real proposed module and validator payload files.",
    "- Candidate quality gate materializes and parse-checks payloads before promotion eligibility.",
    "- Revision request artifacts feed failure reasons back into bounded retry generation.",
    "- Promotion waits for owner review only when ready_candidate_count_after_quality is greater than zero.",
    "",
    "## Acceptance",
    "PHASE160H_REAL_PAYLOAD_GENERATION_QUALITY_GATE_REVISION_FEEDBACK_VALIDATE_RESULT=PASS"
  )
  Write-Phase160HTextFile -Path (Resolve-Phase160HPath -RepoRoot $RepoRoot -Path $RouteRequestPath) -Text ($RouteLines -join "`n")

  Assert-Phase160HTrue -Actual (Test-Path -LiteralPath (Resolve-Phase160HPath -RepoRoot $RepoRoot -Path $ReportPath)) -Name "report_created"
  Assert-Phase160HTrue -Actual (Test-Path -LiteralPath (Resolve-Phase160HPath -RepoRoot $RepoRoot -Path $ProofPath)) -Name "proof_created"
  Assert-Phase160HTrue -Actual (Test-Path -LiteralPath (Resolve-Phase160HPath -RepoRoot $RepoRoot -Path $RouteRequestPath)) -Name "route_request_created"

  Write-Host "PHASE160H_REAL_PAYLOAD_GENERATION_QUALITY_GATE_REVISION_FEEDBACK_VALIDATE_RESULT=PASS"
  Write-Host "REAL_PAYLOAD_GENERATION_ENABLED=True"
  Write-Host "PLACEHOLDER_CANDIDATE_REVISION_REQUIRED=True"
  Write-Host "EMPTY_PAYLOAD_REVISION_REQUIRED=True"
  Write-Host "MISSING_VALIDATOR_PAYLOAD_REVISION_REQUIRED=True"
  Write-Host "REAL_MODULE_AND_VALIDATOR_PAYLOAD_READY=True"
  Write-Host "UNSAFE_CANDIDATE_QUARANTINED=True"
  Write-Host "REVISION_REQUEST_CREATED=True"
  Write-Host "REVISION_FEEDBACK_TO_GENERATOR_ENABLED=True"
  Write-Host "PROMOTION_WAITING_OWNER_REVIEW_ONLY_FOR_QUALITY_READY=True"
  Write-Host "OWNER_PROMOTION_BLOCKED_FOR_WEAK_CANDIDATES=True"
  Write-Host "MATERIALIZATION_PARSE_CHECK_PASS=True"
  Write-Host "NO_OWNER_GOAL_KEYWORD_FALSE_PASS=True"
  Write-Host "LIVE_REPO_GUARD_PASS=True"
  Write-Host "RUN_HEAD_MATCH=True"
  Write-Host "NO_COMMIT_PERFORMED=True"
  Write-Host "NO_PUSH_PERFORMED=True"
  Write-Host "NO_BRANCH_SWITCH=True"
  Write-Host "PROTECTED_STATE_MUTATED=False"
  Write-Host "RUNTIME_OUTPUTS_STAGED=False"
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
