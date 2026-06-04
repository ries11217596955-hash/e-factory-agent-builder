param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Normalize-Phase160H1FullPath {
  param([string]$Path)
  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase160H1RepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE160H1_VALIDATE_SCRIPT_ROOT_UNAVAILABLE"
  }
  return Normalize-Phase160H1FullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Resolve-Phase160H1Path {
  param([string]$RepoRoot, [string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Assert-Phase160H1PathInsideRepo {
  param([string]$RepoRoot, [string]$Path)
  $root = Normalize-Phase160H1FullPath -Path $RepoRoot
  $full = Normalize-Phase160H1FullPath -Path (Resolve-Phase160H1Path -RepoRoot $RepoRoot -Path $Path)
  if (-not ($full -eq $root -or $full.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase))) {
    throw "PHASE160H1_VALIDATE_PATH_OUTSIDE_REPO=$Path"
  }
  return $full
}

function ConvertTo-Phase160H1RelativePath {
  param([string]$RepoRoot, [string]$FullPath)
  $root = Normalize-Phase160H1FullPath -Path $RepoRoot
  $full = Normalize-Phase160H1FullPath -Path $FullPath
  if ($full -eq $root) {
    return "."
  }
  if (-not $full.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "PHASE160H1_VALIDATE_PATH_OUTSIDE_REPO=$FullPath"
  }
  return ($full.Substring($root.Length + 1) -replace "\\", "/")
}

function Write-Phase160H1JsonFile {
  param([string]$Path, [object]$Object, [int]$Depth = 100)
  $directory = Split-Path -Path $Path -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    [System.IO.Directory]::CreateDirectory($directory) | Out-Null
  }
  $json = ($Object | ConvertTo-Json -Depth $Depth) -replace "`r`n", "`n"
  if (-not $json.EndsWith("`n")) {
    $json += "`n"
  }
  [System.IO.File]::WriteAllText($Path, $json, [System.Text.UTF8Encoding]::new($false))
}

function Write-Phase160H1TextFile {
  param([string]$Path, [string]$Text)
  $directory = Split-Path -Path $Path -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    [System.IO.Directory]::CreateDirectory($directory) | Out-Null
  }
  if (-not $Text.EndsWith("`n")) {
    $Text += "`n"
  }
  [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Read-Phase160H1Json {
  param([string]$RepoRoot, [string]$Path)
  $fullPath = Resolve-Phase160H1Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE160H1_VALIDATE_MISSING_JSON=$Path"
  }
  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Assert-Phase160H1Equals {
  param([object]$Actual, [object]$Expected, [string]$Name)
  if ($Actual -ne $Expected) {
    throw "PHASE160H1_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase160H1True {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $true) {
    throw "PHASE160H1_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase160H1False {
  param([object]$Actual, [string]$Name)
  if ($Actual -ne $false) {
    throw "PHASE160H1_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase160H1AtLeast {
  param([object]$Actual, [int]$Minimum, [string]$Name)
  if ([int]$Actual -lt $Minimum) {
    throw "PHASE160H1_VALIDATE_COUNT_TOO_LOW=$Name actual=$Actual minimum=$Minimum"
  }
}

function Assert-Phase160H1ParserClean {
  param([string]$Path)
  $tokens = $null
  $parseErrors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors) | Out-Null
  if ($parseErrors.Count -gt 0) {
    throw "PHASE160H1_VALIDATE_PARSE_ERROR=$Path message=$($parseErrors[0].Message)"
  }
}

function Remove-Phase160H1Output {
  param([string]$RepoRoot, [string]$Path)
  $full = Assert-Phase160H1PathInsideRepo -RepoRoot $RepoRoot -Path $Path
  if (Test-Path -LiteralPath $full) {
    Remove-Item -LiteralPath $full -Recurse -Force
  }
}

function Get-Phase160H1FileHashes {
  param([string]$RepoRoot, [string[]]$Paths)
  $hashes = @{}
  foreach ($path in $Paths) {
    $full = Resolve-Phase160H1Path -RepoRoot $RepoRoot -Path $path
    if (Test-Path -LiteralPath $full) {
      $hashes[$path] = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
    } else {
      $hashes[$path] = "MISSING"
    }
  }
  return $hashes
}

function Get-Phase160H1RemoteHeadSafe {
  param([string]$Branch)
  $remoteHead = (git rev-parse --short "origin/$Branch" 2>$null)
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    return "UNAVAILABLE"
  }
  return $remoteHead.Trim()
}

function Assert-Phase160H1RuntimeOutputsNotStaged {
  $stagedRuntime = @(git diff --cached --name-only -- runtime_sessions)
  if ($stagedRuntime.Count -gt 0) {
    throw "PHASE160H1_VALIDATE_RUNTIME_OUTPUTS_STAGED=$($stagedRuntime -join '; ')"
  }
}

function Assert-Phase160H1RuntimeJsonClean {
  param([string]$RepoRoot, [string[]]$SessionRoots)
  foreach ($sessionRoot in $SessionRoots) {
    $full = Resolve-Phase160H1Path -RepoRoot $RepoRoot -Path $sessionRoot
    if (-not (Test-Path -LiteralPath $full)) {
      continue
    }
    foreach ($jsonFile in @(Get-ChildItem -LiteralPath $full -File -Filter "*.json" -Recurse -ErrorAction SilentlyContinue)) {
      try {
        Get-Content -LiteralPath $jsonFile.FullName -Raw | ConvertFrom-Json | Out-Null
      } catch {
        throw "PHASE160H1_VALIDATE_RUNTIME_JSON_PARSE_ERROR=$($jsonFile.FullName) message=$($_.Exception.Message)"
      }
    }
  }
}

function Invoke-Phase160H1ScriptJson {
  param([string]$RepoRoot, [string]$ScriptPath, [string[]]$Arguments)
  $fullScript = Resolve-Phase160H1Path -RepoRoot $RepoRoot -Path $ScriptPath
  $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File $fullScript @Arguments 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    throw "PHASE160H1_VALIDATE_SCRIPT_FAILED script=$ScriptPath output=$($output -join ' | ')"
  }
  return ($output -join "`n") | ConvertFrom-Json
}

function New-Phase160H1SessionFixture {
  param([string]$RepoRoot, [string]$SessionRoot, [string]$RunId, [string]$Branch, [string]$Head)
  $sessionFull = Resolve-Phase160H1Path -RepoRoot $RepoRoot -Path $SessionRoot
  New-Item -ItemType Directory -Force -Path $sessionFull, (Join-Path $sessionFull "candidate_workspace/candidate_bundles"), (Join-Path $sessionFull "candidate_workspace/candidate_queue"), (Join-Path $sessionFull "promotion_bundle"), (Join-Path $sessionFull "active_task"), (Join-Path $sessionFull "task_lifecycle"), (Join-Path $sessionFull "blocker_queue") | Out-Null
  Write-Phase160H1JsonFile -Path (Join-Path $sessionFull "run_manifest.json") -Object ([ordered]@{
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
  Write-Phase160H1JsonFile -Path (Join-Path $sessionFull "runtime_guard.json") -Object ([ordered]@{
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

function New-Phase160H1RealModuleText {
  param([string]$CandidateId)
  return @"
param(
  [string]`$InputPath = "",
  [string]`$OutputPath = ""
)

`$ErrorActionPreference = "Stop"

function Invoke-Phase160H1FixturePayload {
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

`$result = Invoke-Phase160H1FixturePayload -CandidateId "$CandidateId"
if (-not [string]::IsNullOrWhiteSpace(`$OutputPath)) {
  `$directory = Split-Path -Path `$OutputPath -Parent
  if (`$directory -and -not (Test-Path -LiteralPath `$directory)) {
    [System.IO.Directory]::CreateDirectory(`$directory) | Out-Null
  }
  `$json = (`$result | ConvertTo-Json -Depth 20) -replace "`r`n", "`n"
  if (-not `$json.EndsWith("`n")) { `$json += "`n" }
  [System.IO.File]::WriteAllText(`$OutputPath, `$json, [System.Text.UTF8Encoding]::new(`$false))
}
`$result | ConvertTo-Json -Depth 20
"@
}

function New-Phase160H1RealValidatorText {
  param([string]$CandidateId, [string]$ModuleTarget)
  return @"
param(
  [string]`$PayloadRoot = "."
)

`$ErrorActionPreference = "Stop"

function Assert-Phase160H1FixtureTrue {
  param([object]`$Actual, [string]`$Name)
  if (`$Actual -ne `$true) {
    throw "PHASE160H1_FIXTURE_ASSERT_TRUE_FAILED=`$Name actual=`$Actual"
  }
}

function Assert-Phase160H1FixtureParse {
  param([string]`$Path)
  `$tokens = `$null
  `$parseErrors = `$null
  [System.Management.Automation.Language.Parser]::ParseFile(`$Path, [ref]`$tokens, [ref]`$parseErrors) | Out-Null
  if (`$parseErrors.Count -gt 0) {
    throw "PHASE160H1_FIXTURE_PARSE_FAILED=`$Path message=`$(`$parseErrors[0].Message)"
  }
}

`$modulePath = Join-Path `$PayloadRoot "$ModuleTarget"
Assert-Phase160H1FixtureTrue -Actual (Test-Path -LiteralPath `$modulePath) -Name "module_payload_exists"
Assert-Phase160H1FixtureParse -Path `$modulePath
`$text = Get-Content -LiteralPath `$modulePath -Raw
Assert-Phase160H1FixtureTrue -Actual (`$text -match "real_module_payload_executed") -Name "real_module_execution_signal"
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

function New-Phase160H1CandidateFixture {
  param(
    [string]$RepoRoot,
    [string]$SessionRoot,
    [string]$CandidateId,
    [string]$OwnerGoal,
    [string]$Scenario,
    [string]$ModuleTarget,
    [string]$ValidatorTarget,
    [string]$ModuleText,
    [string]$ValidatorText
  )
  $sessionFull = Resolve-Phase160H1Path -RepoRoot $RepoRoot -Path $SessionRoot
  $candidateDir = Join-Path $sessionFull "candidate_workspace/candidate_bundles/$CandidateId"
  $modulePayloadPath = "proposed_patch_or_file_payloads/modules/{0}" -f (Split-Path -Path $ModuleTarget -Leaf)
  $validatorPayloadPath = "proposed_patch_or_file_payloads/validators/{0}" -f (Split-Path -Path $ValidatorTarget -Leaf)
  Write-Phase160H1TextFile -Path (Join-Path $candidateDir $modulePayloadPath) -Text $ModuleText
  Write-Phase160H1TextFile -Path (Join-Path $candidateDir $validatorPayloadPath) -Text $ValidatorText
  $payloadEntries = @(
    [ordered]@{
      kind = "module"
      target_path = $ModuleTarget
      payload_path = $modulePayloadPath
      parse_required = $true
      required = $true
    },
    [ordered]@{
      kind = "validator"
      target_path = $ValidatorTarget
      payload_path = $validatorPayloadPath
      parse_required = $true
      required = $true
    }
  )
  Write-Phase160H1JsonFile -Path (Join-Path $candidateDir "candidate_manifest.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = $CandidateId
    source_task_id = "PHASE160H1_$Scenario"
    source = "owner_task"
    source_plan_item_id = "NONE"
    created_from_run_head = (git rev-parse --short HEAD).Trim()
    run_id = Split-Path -Path $SessionRoot -Leaf
    target_area = "phase160h1_payload_writer_fixture"
    owner_goal = $OwnerGoal
    desired_next_gap = "PHASE160H1_PAYLOAD_WRITER_DIRECTORY_CREATION"
    proposed_file_paths = @($ModuleTarget)
    proposed_validator_paths = @($ValidatorTarget)
    acceptance_validator_needed = @($ValidatorTarget)
    proposed_payload_paths = @($modulePayloadPath, $validatorPayloadPath)
    proposed_module_payload_path = $modulePayloadPath
    proposed_validator_payload_path = $validatorPayloadPath
    owner_approval_required = $true
    owner_promotion_gate_required = $true
    candidate_output_is_not_accepted_code = $true
    repo_mutation_performed = $false
    commit_performed = $false
    push_performed = $false
    branch_switch_performed = $false
    protected_state_mutated = $false
    decision = "CANDIDATE_READY"
    quality_gate_enabled = $true
    owner_promotion_allowed = $true
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  Write-Phase160H1JsonFile -Path (Join-Path $candidateDir "proposed_files.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = $CandidateId
    proposed_file_paths = @($ModuleTarget)
    proposed_validator_paths = @($ValidatorTarget)
    proposed_payloads = @($payloadEntries)
    proposed_module_payload_path = $modulePayloadPath
    proposed_validator_payload_path = $validatorPayloadPath
    proposed_only = $true
    accepted_code_written = $false
  })
  Write-Phase160H1JsonFile -Path (Join-Path $candidateDir "candidate_validation_plan.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = $CandidateId
    validators_required_before_acceptance = @($ValidatorTarget)
    proposed_validator_paths = @($ValidatorTarget)
    proposed_module_payload_path = $modulePayloadPath
    proposed_validator_payload_path = $validatorPayloadPath
    materialization_parse_check_required = $true
    owner_review_required = $true
  })
  Write-Phase160H1JsonFile -Path (Join-Path $candidateDir "candidate_risk_review.json") -Object ([ordered]@{
    status = "PASS"
    candidate_id = $CandidateId
    repo_mutation_performed = $false
    accepted_state_mutated = $false
    risks = @("fixture candidate for quality gate validation")
    mitigations = @("quality gate must decide promotion eligibility")
  })
  Write-Phase160H1JsonFile -Path (Join-Path $candidateDir "candidate_status.json") -Object ([ordered]@{
    status = "CANDIDATE_READY"
    quality_status = "CANDIDATE_READY"
    candidate_id = $CandidateId
    owner_promotion_allowed = $true
    promotion_status = "WAITING_OWNER_REVIEW"
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  return ConvertTo-Phase160H1RelativePath -RepoRoot $RepoRoot -FullPath $candidateDir
}

function Invoke-Phase160H1QualityAndFinalize {
  param([string]$RepoRoot, [string]$SessionRoot, [string]$RunId, [string]$CandidateDir)
  $quality = Invoke-Phase160H1ScriptJson -RepoRoot $RepoRoot -ScriptPath "modules/inspect_builder_candidate_quality_gate_001.ps1" -Arguments @("-CandidateDir", $CandidateDir, "-SessionRoot", $SessionRoot, "-RunId", $RunId)
  $promotion = Invoke-Phase160H1ScriptJson -RepoRoot $RepoRoot -ScriptPath "modules/finalize_builder_promotion_bundle_001.ps1" -Arguments @("-SessionRoot", $SessionRoot, "-RunId", $RunId)
  return [pscustomobject][ordered]@{
    quality = $quality
    promotion = $promotion
  }
}

$Pushed = $false

try {
  $RepoRootParameter = $RepoRoot
  $RepoRoot = Resolve-Phase160H1RepoRoot
  Push-Location $RepoRoot
  $Pushed = $true
  if ($RepoRootParameter -ne "." -and (Normalize-Phase160H1FullPath -Path $RepoRootParameter) -ne $RepoRoot) {
    throw "PHASE160H1_VALIDATE_REPO_ROOT_PARAMETER_MISMATCH=$RepoRootParameter"
  }

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase160H1Path -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
  $ExpectedHead = "7587aaf"
  $Branch = (git branch --show-current).Trim()
  $Head = (git rev-parse --short HEAD).Trim()
  $RemoteHead = Get-Phase160H1RemoteHeadSafe -Branch $ExpectedBranch
  Assert-Phase160H1Equals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
  Assert-Phase160H1Equals -Actual $Head -Expected $ExpectedHead -Name "accepted_head"

  $RepairId = "PHASE160H1_PAYLOAD_WRITER_DIRECTORY_CREATION_REPAIR_V1"
  $WriterRunId = "p160h1_writer"
  $WriterSessionRoot = "runtime_sessions/live_growth/$WriterRunId"
  $QualityRunId = "p160h1_quality"
  $QualitySessionRoot = "runtime_sessions/live_growth/$QualityRunId"
  $ReportPath = "reports/self_development/PHASE160H1_PAYLOAD_WRITER_DIRECTORY_CREATION_REPORT.md"
  $ProofPath = "proofs/self_development/PHASE160H1_PAYLOAD_WRITER_DIRECTORY_CREATION_PROOF.json"
  $RouteRequestPath = "route_change_requests/PHASE160H1_PAYLOAD_WRITER_DIRECTORY_CREATION_REQUEST.md"
  $ProtectedPaths = @("TASK_QUEUE.json", "GENESIS_STATE.json", "CAPABILITY_ROADMAP.json", "packs/registry.json", "orchestrator/run.ps1")
  $TouchedScripts = @(
    "modules/invoke_builder_candidate_workspace_step_001.ps1",
    "modules/test_builder_candidate_payload_materialization_001.ps1",
    "modules/inspect_builder_candidate_quality_gate_001.ps1",
    "validators/validate_phase160h1_payload_writer_directory_creation_v1.ps1"
  )
  foreach ($script in $TouchedScripts) {
    Assert-Phase160H1ParserClean -Path (Resolve-Phase160H1Path -RepoRoot $RepoRoot -Path $script)
  }

  $ProtectedHashesBefore = Get-Phase160H1FileHashes -RepoRoot $RepoRoot -Paths $ProtectedPaths
  foreach ($runtimePath in @($WriterSessionRoot, $QualitySessionRoot)) {
    Remove-Phase160H1Output -RepoRoot $RepoRoot -Path $runtimePath
  }

  New-Phase160H1SessionFixture -RepoRoot $RepoRoot -SessionRoot $WriterSessionRoot -RunId $WriterRunId -Branch $Branch -Head $Head
  $writerSessionFull = Resolve-Phase160H1Path -RepoRoot $RepoRoot -Path $WriterSessionRoot
  Write-Phase160H1JsonFile -Path (Join-Path $writerSessionFull "active_task/active_task.json") -Object ([ordered]@{
    status = "ACTIVE"
    task_id = "PAYLOAD_WRITER_NESTED_PATHS"
    source = "owner"
    priority = "high"
    owner_goal = "Generate nested real module and validator payload files with parent directories created by the payload writer."
    desired_next_gap = "PHASE160H1_PAYLOAD_WRITER_DIRECTORY_CREATION"
    created_at = (Get-Date).ToUniversalTime().ToString("o")
  })
  $WriterStep = Invoke-Phase160H1ScriptJson -RepoRoot $RepoRoot -ScriptPath "modules/invoke_builder_candidate_workspace_step_001.ps1" -Arguments @("-SessionRoot", $WriterSessionRoot, "-RunId", $WriterRunId, "-DutyId", "phase160h1_payload_writer", "-TickNumber", "1")
  Assert-Phase160H1True -Actual $WriterStep.quality_gate_enabled -Name "writer_quality_gate_enabled"
  Assert-Phase160H1AtLeast -Actual $WriterStep.quality_ready_count -Minimum 1 -Name "writer_quality_ready_count"

  $candidateManifests = @(Get-ChildItem -LiteralPath (Resolve-Phase160H1Path -RepoRoot $RepoRoot -Path "$WriterSessionRoot/candidate_workspace/candidate_bundles") -File -Filter "candidate_manifest.json" -Recurse | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json })
  Assert-Phase160H1AtLeast -Actual $candidateManifests.Count -Minimum 1 -Name "writer_candidate_manifest_count"
  $generatedCandidateManifest = $candidateManifests[0]
  $generatedCandidateDir = Resolve-Phase160H1Path -RepoRoot $RepoRoot -Path "$WriterSessionRoot/candidate_workspace/candidate_bundles/$($generatedCandidateManifest.candidate_id)"
  $generatedProposedFiles = Read-Phase160H1Json -RepoRoot $RepoRoot -Path "$WriterSessionRoot/candidate_workspace/candidate_bundles/$($generatedCandidateManifest.candidate_id)/proposed_files.json"
  $modulePayload = @($generatedProposedFiles.proposed_payloads | Where-Object { [string]$_.kind -eq "module" } | Select-Object -First 1)[0]
  $validatorPayload = @($generatedProposedFiles.proposed_payloads | Where-Object { [string]$_.kind -eq "validator" } | Select-Object -First 1)[0]
  Assert-Phase160H1True -Actual ($null -ne $modulePayload) -Name "writer_module_payload_entry"
  Assert-Phase160H1True -Actual ($null -ne $validatorPayload) -Name "writer_validator_payload_entry"
  $modulePayloadFullPath = Join-Path $generatedCandidateDir ([string]$modulePayload.payload_path)
  $validatorPayloadFullPath = Join-Path $generatedCandidateDir ([string]$validatorPayload.payload_path)
  Assert-Phase160H1True -Actual (Test-Path -LiteralPath $modulePayloadFullPath) -Name "nested_module_payload_file_exists"
  Assert-Phase160H1True -Actual (Test-Path -LiteralPath $validatorPayloadFullPath) -Name "nested_validator_payload_file_exists"
  Assert-Phase160H1True -Actual (Test-Path -LiteralPath (Split-Path -Path $modulePayloadFullPath -Parent)) -Name "module_payload_parent_exists"
  Assert-Phase160H1True -Actual (Test-Path -LiteralPath (Split-Path -Path $validatorPayloadFullPath -Parent)) -Name "validator_payload_parent_exists"
  Assert-Phase160H1True -Actual ([bool]$generatedCandidateManifest.payload_parent_directories_created) -Name "writer_parent_directories_created_by_helper"

  $writerQuality = Read-Phase160H1Json -RepoRoot $RepoRoot -Path "$WriterSessionRoot/candidate_workspace/candidate_bundles/$($generatedCandidateManifest.candidate_id)/quality_gate/quality_gate_result.json"
  $writerMaterialization = Read-Phase160H1Json -RepoRoot $RepoRoot -Path "$WriterSessionRoot/candidate_workspace/candidate_bundles/$($generatedCandidateManifest.candidate_id)/quality_gate/materialization_result.json"
  Assert-Phase160H1Equals -Actual $writerQuality.quality_status -Expected "CANDIDATE_READY" -Name "writer_real_candidate_ready"
  Assert-Phase160H1True -Actual $writerQuality.materialization_parse_check_pass -Name "writer_quality_parse_check"
  Assert-Phase160H1Equals -Actual $writerMaterialization.status -Expected "PASS" -Name "writer_materialization_pass"
  Assert-Phase160H1True -Actual $writerMaterialization.parser_checks_pass -Name "writer_materialization_parser_checks"

  New-Phase160H1SessionFixture -RepoRoot $RepoRoot -SessionRoot $QualitySessionRoot -RunId $QualityRunId -Branch $Branch -Head $Head
  $placeholderCandidateDir = New-Phase160H1CandidateFixture -RepoRoot $RepoRoot -SessionRoot $QualitySessionRoot -CandidateId "c_h1_ph" -OwnerGoal "Target path with accepted candidate marker must require revision." -Scenario "placeholder" -ModuleTarget "modules/p160h1_accepted_candidate_placeholder.ps1" -ValidatorTarget "validators/validate_p160h1_placeholder.ps1" -ModuleText (New-Phase160H1RealModuleText -CandidateId "c_h1_ph") -ValidatorText (New-Phase160H1RealValidatorText -CandidateId "c_h1_ph" -ModuleTarget "modules/p160h1_accepted_candidate_placeholder.ps1")
  $PlaceholderResult = Invoke-Phase160H1QualityAndFinalize -RepoRoot $RepoRoot -SessionRoot $QualitySessionRoot -RunId $QualityRunId -CandidateDir $placeholderCandidateDir
  Assert-Phase160H1Equals -Actual $PlaceholderResult.quality.quality_status -Expected "REVISION_REQUIRED" -Name "placeholder_revision_required"
  Assert-Phase160H1False -Actual ([string]$PlaceholderResult.quality.quality_status -eq "CANDIDATE_READY") -Name "placeholder_not_ready"
  Assert-Phase160H1False -Actual ([string]$PlaceholderResult.promotion.promotion_bundle_status -eq "WAITING_OWNER_REVIEW") -Name "placeholder_not_waiting_owner_review"

  $realCandidateDir = New-Phase160H1CandidateFixture -RepoRoot $RepoRoot -SessionRoot $QualitySessionRoot -CandidateId "c_h1_real" -OwnerGoal "Real payload candidate may become ready." -Scenario "real" -ModuleTarget "modules/p160h1_real_payload.ps1" -ValidatorTarget "validators/validate_p160h1_real_payload.ps1" -ModuleText (New-Phase160H1RealModuleText -CandidateId "c_h1_real") -ValidatorText (New-Phase160H1RealValidatorText -CandidateId "c_h1_real" -ModuleTarget "modules/p160h1_real_payload.ps1")
  $RealResult = Invoke-Phase160H1QualityAndFinalize -RepoRoot $RepoRoot -SessionRoot $QualitySessionRoot -RunId $QualityRunId -CandidateDir $realCandidateDir
  Assert-Phase160H1Equals -Actual $RealResult.quality.quality_status -Expected "CANDIDATE_READY" -Name "real_quality_ready"
  Assert-Phase160H1True -Actual $RealResult.quality.materialization_parse_check_pass -Name "real_materialization_parse_pass"

  $unsafeModuleText = (New-Phase160H1RealModuleText -CandidateId "c_h1_unsafe") + "`n`ngit push origin HEAD`n"
  $unsafeCandidateDir = New-Phase160H1CandidateFixture -RepoRoot $RepoRoot -SessionRoot $QualitySessionRoot -CandidateId "c_h1_unsafe" -OwnerGoal "Unsafe mutation request must not be promoted." -Scenario "unsafe" -ModuleTarget "modules/p160h1_unsafe_payload.ps1" -ValidatorTarget "validators/validate_p160h1_unsafe_payload.ps1" -ModuleText $unsafeModuleText -ValidatorText (New-Phase160H1RealValidatorText -CandidateId "c_h1_unsafe" -ModuleTarget "modules/p160h1_unsafe_payload.ps1")
  $UnsafeResult = Invoke-Phase160H1QualityAndFinalize -RepoRoot $RepoRoot -SessionRoot $QualitySessionRoot -RunId $QualityRunId -CandidateDir $unsafeCandidateDir
  Assert-Phase160H1True -Actual (@("QUARANTINED", "BLOCKED") -contains [string]$UnsafeResult.quality.quality_status) -Name "unsafe_quarantined_or_blocked"

  Assert-Phase160H1RuntimeJsonClean -RepoRoot $RepoRoot -SessionRoots @($WriterSessionRoot, $QualitySessionRoot)
  $BranchAfter = (git branch --show-current).Trim()
  $HeadAfter = (git rev-parse --short HEAD).Trim()
  $RemoteHeadAfter = Get-Phase160H1RemoteHeadSafe -Branch $ExpectedBranch
  Assert-Phase160H1Equals -Actual $BranchAfter -Expected $Branch -Name "branch_after"
  Assert-Phase160H1Equals -Actual $HeadAfter -Expected $Head -Name "head_after"
  Assert-Phase160H1Equals -Actual $RemoteHeadAfter -Expected $RemoteHead -Name "remote_head_after"
  $ProtectedHashesAfter = Get-Phase160H1FileHashes -RepoRoot $RepoRoot -Paths $ProtectedPaths
  foreach ($path in $ProtectedPaths) {
    Assert-Phase160H1Equals -Actual $ProtectedHashesAfter[$path] -Expected $ProtectedHashesBefore[$path] -Name "protected_hash:$path"
  }
  Assert-Phase160H1RuntimeOutputsNotStaged

  $Proof = [ordered]@{
    status = "PASS"
    acceptance_language = "PHASE160H1_PAYLOAD_WRITER_DIRECTORY_CREATION_VALIDATE_RESULT=PASS"
    repair_id = $RepairId
    branch = $Branch
    local_head = $Head
    remote_head = $RemoteHead
    parser_checks_pass = $true
    nested_module_payload_write_pass = $true
    nested_validator_payload_write_pass = $true
    parent_directories_created = $true
    real_payload_candidate_ready = $true
    materialization_parse_check_pass = $true
    placeholder_still_revision_required = $true
    unsafe_still_quarantined = $true
    no_protected_state_mutation = $true
    runtime_outputs_staged = $false
    no_commit_performed = $true
    no_push_performed = $true
    no_branch_switch = $true
    generated_candidate_id = [string]$generatedCandidateManifest.candidate_id
    module_payload_path = ConvertTo-Phase160H1RelativePath -RepoRoot $RepoRoot -FullPath $modulePayloadFullPath
    validator_payload_path = ConvertTo-Phase160H1RelativePath -RepoRoot $RepoRoot -FullPath $validatorPayloadFullPath
    report_path = $ReportPath
    proof_path = $ProofPath
    route_request_path = $RouteRequestPath
    validated_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Phase160H1JsonFile -Path (Resolve-Phase160H1Path -RepoRoot $RepoRoot -Path $ProofPath) -Object $Proof

  $ReportLines = @(
    "# PHASE160H1 Payload Writer Directory Creation Report",
    "",
    "status: PASS",
    "repair_id: $RepairId",
    "line: AGENT_BUILDER_SELF_DEVELOPMENT",
    "mode: VERIFY",
    "",
    "## Result",
    "PHASE160H1_PAYLOAD_WRITER_DIRECTORY_CREATION_VALIDATE_RESULT=PASS",
    "NESTED_MODULE_PAYLOAD_WRITE_PASS=True",
    "NESTED_VALIDATOR_PAYLOAD_WRITE_PASS=True",
    "PARENT_DIRECTORIES_CREATED=True",
    "REAL_PAYLOAD_CANDIDATE_READY=True",
    "MATERIALIZATION_PARSE_CHECK_PASS=True",
    "PLACEHOLDER_STILL_REVISION_REQUIRED=True",
    "UNSAFE_STILL_QUARANTINED=True",
    "NO_PROTECTED_STATE_MUTATION=True",
    "RUNTIME_OUTPUTS_STAGED=False",
    "NO_COMMIT_PERFORMED=True",
    "NO_PUSH_PERFORMED=True",
    "NO_BRANCH_SWITCH=True",
    "",
    "## Proof Summary",
    "- Generated candidate: $($generatedCandidateManifest.candidate_id)",
    "- Module payload: $($Proof.module_payload_path)",
    "- Validator payload: $($Proof.validator_payload_path)",
    "- Real candidate quality status: $($RealResult.quality.quality_status)",
    "- Placeholder quality status: $($PlaceholderResult.quality.quality_status)",
    "- Unsafe quality status: $($UnsafeResult.quality.quality_status)",
    "",
    "## Validation Command",
    '```powershell',
    ".\validators\validate_phase160h1_payload_writer_directory_creation_v1.ps1 -RepoRoot .",
    '```',
    "",
    "## Boundaries",
    "- No TASK_QUEUE, GENESIS_STATE, CAPABILITY_ROADMAP, packs/registry, or orchestrator edits.",
    "- Candidate payloads stayed under runtime_sessions.",
    "- No external-agent production, dependency install, internet use, commit, push, or branch switch.",
    "- Runtime outputs were not staged."
  )
  Write-Phase160H1TextFile -Path (Resolve-Phase160H1Path -RepoRoot $RepoRoot -Path $ReportPath) -Text ($ReportLines -join "`n")

  $RouteLines = @(
    "# PHASE160H1 Payload Writer Directory Creation Request",
    "",
    "repair_id: $RepairId",
    "line: AGENT_BUILDER_SELF_DEVELOPMENT",
    "mode: VERIFY",
    "validator: validators/validate_phase160h1_payload_writer_directory_creation_v1.ps1",
    "report: $ReportPath",
    "proof: $ProofPath",
    "",
    "## Route Change",
    "- Candidate payload writes now create parent directories directly before writing files.",
    "- Failed payload writes emit a clear BLOCKED artifact with candidate_id, failed_path, reason, parent directory status, and next_action.",
    "- PHASE160H quality gate behavior remains intact for real, placeholder, and unsafe candidates.",
    "",
    "## Acceptance",
    "PHASE160H1_PAYLOAD_WRITER_DIRECTORY_CREATION_VALIDATE_RESULT=PASS"
  )
  Write-Phase160H1TextFile -Path (Resolve-Phase160H1Path -RepoRoot $RepoRoot -Path $RouteRequestPath) -Text ($RouteLines -join "`n")

  Assert-Phase160H1True -Actual (Test-Path -LiteralPath (Resolve-Phase160H1Path -RepoRoot $RepoRoot -Path $ReportPath)) -Name "report_created"
  Assert-Phase160H1True -Actual (Test-Path -LiteralPath (Resolve-Phase160H1Path -RepoRoot $RepoRoot -Path $ProofPath)) -Name "proof_created"
  Assert-Phase160H1True -Actual (Test-Path -LiteralPath (Resolve-Phase160H1Path -RepoRoot $RepoRoot -Path $RouteRequestPath)) -Name "route_request_created"

  Write-Host "PHASE160H1_PAYLOAD_WRITER_DIRECTORY_CREATION_VALIDATE_RESULT=PASS"
  Write-Host "NESTED_MODULE_PAYLOAD_WRITE_PASS=True"
  Write-Host "NESTED_VALIDATOR_PAYLOAD_WRITE_PASS=True"
  Write-Host "PARENT_DIRECTORIES_CREATED=True"
  Write-Host "REAL_PAYLOAD_CANDIDATE_READY=True"
  Write-Host "MATERIALIZATION_PARSE_CHECK_PASS=True"
  Write-Host "PLACEHOLDER_STILL_REVISION_REQUIRED=True"
  Write-Host "UNSAFE_STILL_QUARANTINED=True"
  Write-Host "NO_PROTECTED_STATE_MUTATION=True"
  Write-Host "RUNTIME_OUTPUTS_STAGED=False"
  Write-Host "NO_COMMIT_PERFORMED=True"
  Write-Host "NO_PUSH_PERFORMED=True"
  Write-Host "NO_BRANCH_SWITCH=True"
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
