$ErrorActionPreference = "Continue"
$Ok = $true

function Mark-Fail {
  param([string]$Message)
  Write-Output "FAIL=$Message"
  $script:Ok = $false
}

function Read-JsonOrFail {
  param([string]$Path)

  try {
    if (-not (Test-Path -LiteralPath $Path)) {
      Mark-Fail "MISSING=$Path"
      return $null
    }
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
  } catch {
    Mark-Fail "JSON_PARSE_FAIL=$Path :: $($_.Exception.Message)"
    return $null
  }
}

function Test-PropertyExists {
  param(
    [object]$Object,
    [string]$Name
  )

  if ($null -eq $Object) {
    return $false
  }

  return $null -ne ($Object.PSObject.Properties | Where-Object { $_.Name -eq $Name } | Select-Object -First 1)
}

function Get-PropertyValue {
  param(
    [object]$Object,
    [string]$Name
  )

  if ($null -eq $Object) {
    return $null
  }

  $property = $Object.PSObject.Properties | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
  if ($null -eq $property) {
    return $null
  }

  return $property.Value
}

function Assert-Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    Mark-Fail "$Name`_UNEXPECTED=$Actual EXPECTED=$Expected"
  }
}

function Assert-True {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    Mark-Fail "$Name`_NOT_TRUE=$Actual"
  }
}

function Assert-False {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    Mark-Fail "$Name`_NOT_FALSE=$Actual"
  }
}

function Assert-FalseProperty {
  param(
    [object]$Object,
    [string]$PropertyName,
    [string]$Context
  )

  if (Test-PropertyExists -Object $Object -Name $PropertyName) {
    $value = Get-PropertyValue -Object $Object -Name $PropertyName
    if ($value -ne $false) {
      Mark-Fail "$Context`_$PropertyName`_NOT_FALSE=$value"
    }
  }
}

function Assert-NoForbiddenFlags {
  param(
    [object]$Object,
    [string]$Context
  )

  foreach ($propertyName in @(
    "external_agent_production_allowed",
    "production_adoption_allowed",
    "external_fetch_performed",
    "dependency_install_performed",
    "executable_materials_used",
    "dependency_install_allowed",
    "external_fetch_allowed",
    "executable_use_allowed",
    "codex_authored",
    "codex_authored_generated_pack"
  )) {
    Assert-FalseProperty -Object $Object -PropertyName $propertyName -Context $Context
  }
}

function Assert-TextContains {
  param(
    [string]$Text,
    [string]$Needle,
    [string]$Name
  )

  if ($Text -notmatch [regex]::Escape($Needle)) {
    Mark-Fail "$Name`_TEXT_MISSING=$Needle"
  }
}

$StepId = "PHASE139_BUILD_BUILDER_SELF_PACK_AUTHOR_CONVEYOR_V1"
$RunId = "PHASE139_BUILDER_SELF_PACK_AUTHOR_CONVEYOR_001"
$GeneratedPackStepId = "PHASE139A_BUILDER_GENERATED_SELF_LEARNING_LOOP_SEED_V1"
$PreviousStepId = "PHASE138D_OWNER_APPROVED_SANDBOX_BRANCH_MERGE_V1"
$PreviousNextAllowedStep = "PHASE139_DELEGATED_AUTONOMY_POLICY_ENFORCEMENT_V1"
$NextAllowed = "PHASE140_BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_V1"
$RouteLockId = "AGENT_BUILDER_NEXT_15_STEPS_LOCK_V3_SELF_PACK_AUTHOR"

$PreviousProofPath = "proofs/self_development/${PreviousStepId}.json"
$RouteLockPath = "route_locks/${RouteLockId}.md"
$RouteRebaseDecisionPath = "self_control/ROUTE_REBASE_DECISION_PHASE139_SELF_PACK_AUTHOR.json"
$ConveyorResultPath = "self_control/BUILDER_SELF_PACK_AUTHOR_CONVEYOR_RESULT.json"
$AdmissionPath = "self_control/BUILDER_GENERATED_SELF_BUILD_PACK_ADMISSION.json"
$GeneratedPackPath = "self_build_programs/generated/${GeneratedPackStepId}.json"
$OutputPath = "self_build_batch/autonomy_trials/$StepId/BUILDER_SELF_PACK_AUTHOR_CONVEYOR_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$RuntimeLogPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RUNTIME_LOG.txt"
$GeneratedPackResultPath = "self_build_batch/autonomy_trials/$GeneratedPackStepId/${GeneratedPackStepId}_RESULT.json"
$GeneratedPackRuntimeLogPath = "self_build_batch/autonomy_trials/$GeneratedPackStepId/${GeneratedPackStepId}_RUNTIME_LOG.txt"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"

foreach ($path in @(
  "modules/invoke_builder_self_pack_author_conveyor_001.ps1",
  "orchestrator/run.ps1",
  $PreviousProofPath,
  $RouteLockPath,
  $RouteRebaseDecisionPath,
  $ConveyorResultPath,
  $AdmissionPath,
  $GeneratedPackPath,
  $OutputPath,
  $ResultPath,
  $RuntimeLogPath,
  $GeneratedPackResultPath,
  $GeneratedPackRuntimeLogPath,
  $ReportPath,
  $ProofPath
)) {
  if (-not (Test-Path -LiteralPath $path)) {
    Mark-Fail "MISSING=$path"
  } else {
    Write-Output "EXISTS=$path"
  }
}

$PreviousProof = Read-JsonOrFail -Path $PreviousProofPath
$RouteRebaseDecision = Read-JsonOrFail -Path $RouteRebaseDecisionPath
$ConveyorResult = Read-JsonOrFail -Path $ConveyorResultPath
$Admission = Read-JsonOrFail -Path $AdmissionPath
$GeneratedPack = Read-JsonOrFail -Path $GeneratedPackPath
$Output = Read-JsonOrFail -Path $OutputPath
$Result = Read-JsonOrFail -Path $ResultPath
$GeneratedPackResult = Read-JsonOrFail -Path $GeneratedPackResultPath
$Report = Read-JsonOrFail -Path $ReportPath
$Proof = Read-JsonOrFail -Path $ProofPath
$Queue = Read-JsonOrFail -Path "TASK_QUEUE.json"

try {
  $RouteLockText = Get-Content -LiteralPath $RouteLockPath -Raw
  Assert-TextContains -Text $RouteLockText -Needle "SELF_PACK_AUTHOR" -Name "ROUTE_LOCK"
  Assert-TextContains -Text $RouteLockText -Needle "Builder must author next self-build packs" -Name "ROUTE_LOCK"
  if ($RouteLockText -notmatch "Codex.*fallback only") {
    Mark-Fail "ROUTE_LOCK_TEXT_MISSING=Codex fallback only"
  }
} catch {
  Mark-Fail "ROUTE_LOCK_READ_FAIL=$($_.Exception.Message)"
}

try {
  $RuntimeLog = Get-Content -LiteralPath $RuntimeLogPath -Raw
  foreach ($requiredSignal in @(
    "BUILDER_SELF_PACK_AUTHOR_CONVEYOR=PHASE139_BUILDER_SELF_PACK_AUTHOR_CONVEYOR_001",
    "SELF_PACK_AUTHOR_STATUS=PASS",
    "BUILDER_GENERATED_PACK_COUNT=1",
    "BUILDER_GENERATED_PACK_ID=PHASE139A_BUILDER_GENERATED_SELF_LEARNING_LOOP_SEED_V1",
    "GENERATED_PACK_AUTHOR=BUILDER_RUNTIME",
    "CODEX_AUTHORED_GENERATED_PACK=False",
    "CODEX_BOOTSTRAP_USED=True",
    "GENERATED_PACK_ADMITTED=True",
    "GENERATED_PACK_EXECUTED=True",
    "EXTERNAL_AGENT_PRODUCTION_ALLOWED=False",
    "MATERIAL_TRUSTED_COUNT=0",
    "MATERIAL_EXTERNAL_FETCH_PERFORMED=False",
    "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=False",
    "MATERIAL_EXECUTABLE_USED=False",
    "SELF_PACK_AUTHOR_NEXT_STEP=PHASE140_BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_V1",
    "STATUS=PASS_STOPPED_BUILDER_SELF_PACK_AUTHOR_CONVEYOR_BUILT"
  )) {
    if ($RuntimeLog -notmatch [regex]::Escape($requiredSignal)) {
      Mark-Fail "RUNTIME_LOG_SIGNAL_MISSING=$requiredSignal"
    } else {
      Write-Output "RUNTIME_LOG_SIGNAL_PRESENT=$requiredSignal"
    }
  }
} catch {
  Mark-Fail "RUNTIME_LOG_READ_FAIL=$($_.Exception.Message)"
}

try {
  $GeneratedRuntimeLog = Get-Content -LiteralPath $GeneratedPackRuntimeLogPath -Raw
  foreach ($requiredSignal in @(
    "GENERATED_SELF_BUILD_PACK=PHASE139A_BUILDER_GENERATED_SELF_LEARNING_LOOP_SEED_V1",
    "GENERATED_PACK_EXECUTION_STATUS=PASS",
    "EXECUTED_BY=BUILDER_RUNTIME",
    "GENERATED_PACK_EXECUTED=True",
    "EXTERNAL_AGENT_CREATED=False"
  )) {
    if ($GeneratedRuntimeLog -notmatch [regex]::Escape($requiredSignal)) {
      Mark-Fail "GENERATED_RUNTIME_LOG_SIGNAL_MISSING=$requiredSignal"
    } else {
      Write-Output "GENERATED_RUNTIME_LOG_SIGNAL_PRESENT=$requiredSignal"
    }
  }
} catch {
  Mark-Fail "GENERATED_RUNTIME_LOG_READ_FAIL=$($_.Exception.Message)"
}

try {
  $ExternalAgentStatus = @(git status --short --untracked-files=all -- generated_agents agent_catalog 2>$null)
  if ($ExternalAgentStatus.Count -gt 0) {
    Mark-Fail "EXTERNAL_AGENT_FOLDER_CREATED_OR_TOUCHED=$($ExternalAgentStatus -join '; ')"
  } else {
    Write-Output "EXTERNAL_AGENT_SCOPE_STATUS=CLEAN"
  }
} catch {
  Mark-Fail "EXTERNAL_AGENT_SCOPE_STATUS_READ_FAIL=$($_.Exception.Message)"
}

if ($null -ne $PreviousProof) {
  Write-Output "PREVIOUS_PROOF_STATUS=$($PreviousProof.status)"
  Write-Output "PREVIOUS_PROOF_NEXT=$($PreviousProof.next_allowed_step)"
  Assert-Equals -Actual $PreviousProof.status -Expected "PASS" -Name "PREVIOUS_PROOF_STATUS"
  Assert-True -Actual $PreviousProof.terminal_merge_executed -Name "PREVIOUS_PROOF_TERMINAL_MERGE_EXECUTED"
  Assert-True -Actual $PreviousProof.owner_standing_delegation_used -Name "PREVIOUS_PROOF_OWNER_STANDING_DELEGATION_USED"
  Assert-False -Actual $PreviousProof.interactive_owner_prompt_used -Name "PREVIOUS_PROOF_INTERACTIVE_OWNER_PROMPT_USED"
  Assert-False -Actual $PreviousProof.production_adoption_allowed -Name "PREVIOUS_PROOF_PRODUCTION_ADOPTION_ALLOWED"
  Assert-Equals -Actual $PreviousProof.trusted_material_count -Expected 0 -Name "PREVIOUS_PROOF_TRUSTED_COUNT"
  Assert-False -Actual $PreviousProof.external_fetch_performed -Name "PREVIOUS_PROOF_EXTERNAL_FETCH_PERFORMED"
  Assert-False -Actual $PreviousProof.dependency_install_performed -Name "PREVIOUS_PROOF_DEPENDENCY_INSTALL_PERFORMED"
  Assert-False -Actual $PreviousProof.executable_materials_used -Name "PREVIOUS_PROOF_EXECUTABLE_MATERIALS_USED"
  Assert-Equals -Actual $PreviousProof.next_allowed_step -Expected $PreviousNextAllowedStep -Name "PREVIOUS_PROOF_NEXT_ALLOWED_STEP"
}

if ($null -ne $RouteRebaseDecision) {
  Assert-Equals -Actual $RouteRebaseDecision.status -Expected "PASS" -Name "ROUTE_REBASE_STATUS"
  Assert-Equals -Actual $RouteRebaseDecision.reason -Expected "owner clarified main objective is self-reproduction/self-learning/self-development" -Name "ROUTE_REBASE_REASON"
  Assert-Equals -Actual $RouteRebaseDecision.previous_next_allowed_step -Expected $PreviousNextAllowedStep -Name "ROUTE_REBASE_PREVIOUS_NEXT"
  Assert-Equals -Actual $RouteRebaseDecision.new_step -Expected $StepId -Name "ROUTE_REBASE_NEW_STEP"
  Assert-Equals -Actual $RouteRebaseDecision.route_lock_used -Expected $RouteLockId -Name "ROUTE_REBASE_ROUTE_LOCK"
  Assert-False -Actual $RouteRebaseDecision.external_agent_production_allowed -Name "ROUTE_REBASE_EXTERNAL_AGENT_PRODUCTION_ALLOWED"
}

if ($null -ne $GeneratedPack) {
  Assert-Equals -Actual $GeneratedPack.status -Expected "BUILDER_RUNTIME_AUTHORED" -Name "GENERATED_PACK_STATUS"
  Assert-Equals -Actual $GeneratedPack.step_id -Expected $GeneratedPackStepId -Name "GENERATED_PACK_STEP_ID"
  Assert-Equals -Actual $GeneratedPack.author -Expected "BUILDER_RUNTIME" -Name "GENERATED_PACK_AUTHOR"
  Assert-Equals -Actual $GeneratedPack.authorship_status -Expected "BUILDER_RUNTIME_AUTHORED" -Name "GENERATED_PACK_AUTHORSHIP_STATUS"
  Assert-False -Actual $GeneratedPack.codex_authored -Name "GENERATED_PACK_CODEX_AUTHORED"
  Assert-Equals -Actual $GeneratedPack.purpose -Expected "Seed the next self-learning loop after self-pack authorship is proven" -Name "GENERATED_PACK_PURPOSE"
  Assert-Equals -Actual $GeneratedPack.line -Expected "SELF_BUILD" -Name "GENERATED_PACK_LINE"
  Assert-False -Actual $GeneratedPack.external_agent_production_allowed -Name "GENERATED_PACK_EXTERNAL_AGENT_PRODUCTION_ALLOWED"
  Assert-False -Actual $GeneratedPack.dependency_install_allowed -Name "GENERATED_PACK_DEPENDENCY_INSTALL_ALLOWED"
  Assert-False -Actual $GeneratedPack.external_fetch_allowed -Name "GENERATED_PACK_EXTERNAL_FETCH_ALLOWED"
  Assert-False -Actual $GeneratedPack.executable_use_allowed -Name "GENERATED_PACK_EXECUTABLE_USE_ALLOWED"
  if (@($GeneratedPack.expected_outputs).Count -lt 2) {
    Mark-Fail "GENERATED_PACK_EXPECTED_OUTPUTS_TOO_SMALL=$(@($GeneratedPack.expected_outputs).Count)"
  }
  if ($null -eq $GeneratedPack.validator_contract) {
    Mark-Fail "GENERATED_PACK_VALIDATOR_CONTRACT_MISSING"
  }
  if ($null -eq $GeneratedPack.proof_contract) {
    Mark-Fail "GENERATED_PACK_PROOF_CONTRACT_MISSING"
  }
}

if ($null -ne $Admission) {
  Assert-Equals -Actual $Admission.status -Expected "PASS" -Name "ADMISSION_STATUS"
  Assert-Equals -Actual $Admission.admitted_pack -Expected $GeneratedPackStepId -Name "ADMISSION_ADMITTED_PACK"
  Assert-Equals -Actual $Admission.admitted_by -Expected "BUILDER_RUNTIME" -Name "ADMISSION_ADMITTED_BY"
  Assert-Equals -Actual $Admission.admission_reason -Expected "generated pack is SELF_BUILD only and safe" -Name "ADMISSION_REASON"
  Assert-NoForbiddenFlags -Object $Admission -Context "ADMISSION"
}

if ($null -ne $GeneratedPackResult) {
  Assert-Equals -Actual $GeneratedPackResult.status -Expected "PASS" -Name "GENERATED_PACK_RESULT_STATUS"
  Assert-Equals -Actual $GeneratedPackResult.step_id -Expected $GeneratedPackStepId -Name "GENERATED_PACK_RESULT_STEP_ID"
  Assert-Equals -Actual $GeneratedPackResult.executed_by -Expected "BUILDER_RUNTIME" -Name "GENERATED_PACK_RESULT_EXECUTED_BY"
  Assert-True -Actual $GeneratedPackResult.generated_pack_executed -Name "GENERATED_PACK_RESULT_EXECUTED"
  Assert-False -Actual $GeneratedPackResult.external_agent_created -Name "GENERATED_PACK_RESULT_EXTERNAL_AGENT_CREATED"
  Assert-NoForbiddenFlags -Object $GeneratedPackResult -Context "GENERATED_PACK_RESULT"
}

if ($null -ne $ConveyorResult) {
  Assert-Equals -Actual $ConveyorResult.status -Expected "PASS" -Name "CONVEYOR_RESULT_STATUS"
  Assert-Equals -Actual $ConveyorResult.conveyor_id -Expected $RunId -Name "CONVEYOR_ID"
  Assert-Equals -Actual $ConveyorResult.builder_generated_pack_count -Expected 1 -Name "CONVEYOR_BUILDER_GENERATED_PACK_COUNT"
  Assert-True -Actual $ConveyorResult.generated_pack_admitted -Name "CONVEYOR_GENERATED_PACK_ADMITTED"
  Assert-True -Actual $ConveyorResult.generated_pack_executed -Name "CONVEYOR_GENERATED_PACK_EXECUTED"
  Assert-Equals -Actual $ConveyorResult.generated_pack_author -Expected "BUILDER_RUNTIME" -Name "CONVEYOR_GENERATED_PACK_AUTHOR"
  Assert-False -Actual $ConveyorResult.codex_authored_generated_pack -Name "CONVEYOR_CODEX_AUTHORED_GENERATED_PACK"
  Assert-True -Actual $ConveyorResult.codex_bootstrap_used -Name "CONVEYOR_CODEX_BOOTSTRAP_USED"
  Assert-Equals -Actual $ConveyorResult.trusted_material_count -Expected 0 -Name "CONVEYOR_TRUSTED_COUNT"
  Assert-NoForbiddenFlags -Object $ConveyorResult -Context "CONVEYOR_RESULT"
}

foreach ($artifactSpec in @(
  @{ Name = "OUTPUT"; Object = $Output },
  @{ Name = "RESULT"; Object = $Result },
  @{ Name = "REPORT"; Object = $Report },
  @{ Name = "PROOF"; Object = $Proof }
)) {
  $artifactName = $artifactSpec.Name
  $artifact = $artifactSpec.Object
  if ($null -eq $artifact) {
    continue
  }

  Write-Output "$artifactName`_STATUS=$($artifact.status)"
  Write-Output "$artifactName`_NEXT_ALLOWED_STEP=$($artifact.next_allowed_step)"
  Assert-Equals -Actual $artifact.status -Expected "PASS" -Name "$artifactName`_STATUS"
  Assert-Equals -Actual $artifact.next_allowed_step -Expected $NextAllowed -Name "$artifactName`_NEXT_ALLOWED_STEP"
  Assert-NoForbiddenFlags -Object $artifact -Context $artifactName
}

if ($null -ne $Proof) {
  Assert-True -Actual $Proof.runtime_executed -Name "PROOF_RUNTIME_EXECUTED"
  Assert-True -Actual $Proof.builder_runtime_invoked -Name "PROOF_BUILDER_RUNTIME_INVOKED"
  Assert-True -Actual $Proof.route_rebase_decision_created -Name "PROOF_ROUTE_REBASE_DECISION_CREATED"
  Assert-Equals -Actual $Proof.builder_generated_pack_count -Expected 1 -Name "PROOF_BUILDER_GENERATED_PACK_COUNT"
  Assert-Equals -Actual $Proof.generated_pack_id -Expected $GeneratedPackStepId -Name "PROOF_GENERATED_PACK_ID"
  Assert-Equals -Actual $Proof.generated_pack_author -Expected "BUILDER_RUNTIME" -Name "PROOF_GENERATED_PACK_AUTHOR"
  Assert-False -Actual $Proof.codex_authored_generated_pack -Name "PROOF_CODEX_AUTHORED_GENERATED_PACK"
  Assert-True -Actual $Proof.codex_bootstrap_used -Name "PROOF_CODEX_BOOTSTRAP_USED"
  Assert-True -Actual $Proof.generated_pack_admitted -Name "PROOF_GENERATED_PACK_ADMITTED"
  Assert-True -Actual $Proof.generated_pack_executed -Name "PROOF_GENERATED_PACK_EXECUTED"
  Assert-Equals -Actual $Proof.current_line -Expected "SELF_BUILD" -Name "PROOF_CURRENT_LINE"
  Assert-False -Actual $Proof.external_agent_production_allowed -Name "PROOF_EXTERNAL_AGENT_PRODUCTION_ALLOWED"
  Assert-False -Actual $Proof.production_adoption_allowed -Name "PROOF_PRODUCTION_ADOPTION_ALLOWED"
  Assert-Equals -Actual $Proof.trusted_material_count -Expected 0 -Name "PROOF_TRUSTED_COUNT"
  Assert-False -Actual $Proof.external_fetch_performed -Name "PROOF_EXTERNAL_FETCH_PERFORMED"
  Assert-False -Actual $Proof.dependency_install_performed -Name "PROOF_DEPENDENCY_INSTALL_PERFORMED"
  Assert-False -Actual $Proof.executable_materials_used -Name "PROOF_EXECUTABLE_MATERIALS_USED"
  Assert-Equals -Actual $Proof.queue_after -Expected "NONE" -Name "PROOF_QUEUE_AFTER"
  Assert-False -Actual $Proof.main_touched -Name "PROOF_MAIN_TOUCHED"
  Assert-Equals -Actual $Proof.next_allowed_step -Expected $NextAllowed -Name "PROOF_NEXT_ALLOWED_STEP"
}

if ($null -ne $Queue) {
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"
  Assert-Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "TASK_QUEUE_ACTIVE_TASK_ID"
}

if ($Ok -eq $true) {
  Write-Output "PHASE139_BUILDER_SELF_PACK_AUTHOR_CONVEYOR_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE139_BUILDER_SELF_PACK_AUTHOR_CONVEYOR_VALIDATE_RESULT=FAIL"
}

if ($Ok -ne $true) {
  throw "PHASE139 validation failed."
}
