param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Resolve-Phase149ValidatorPath {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase149ValidatorJson {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase149ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE149_VALIDATE_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Assert-Phase149ValidatorEquals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE149_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase149ValidatorTrue {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE149_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase149ValidatorFalse {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE149_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Get-Phase149StatusPath {
  param([string]$StatusLine)

  if ($StatusLine -match '^.. (.+)$') {
    return ($Matches[1] -replace '\\', '/')
  }
  return ($StatusLine -replace '\\', '/')
}

try {
  $StepId = "PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_V1"
  $RunId = "PHASE149_READING_REUSE_SESSION_001"
  $NextAllowedStep = "PHASE150_BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_V1"
  $Phase148NextAllowedStep = "PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_V1"
  $Phase148ProofPath = "proofs/self_development/PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1.json"
  $Phase148ResultPath = "self_control/BUILDER_MODULAR_LIVING_LEARNING_ENVIRONMENT_RESULT.json"
  $SourcePolicyPath = "source_registry/source_policy.json"
  $TrustedSourcesPath = "source_registry/trusted_sources.json"
  $CapabilityRegistryPath = "capability_shelf/registry.json"
  $SessionRoot = "living_learning_environment/reading_sessions/$RunId"
  $SessionTracePath = "$SessionRoot/session_trace.json"
  $CapabilityReuseSummaryPath = "$SessionRoot/capability_reuse_summary.json"
  $SourcePolicyReadSummaryPath = "$SessionRoot/source_policy_read_summary.json"
  $LearningCardPath = "knowledge_library/learning_cards/PHASE149_CAPABILITY_REUSE_LEARNING_CARD.json"
  $ReuseProposalPath = "living_learning_environment/proposals/PHASE149_REUSE_PROPOSAL.json"
  $ResultPath = "self_control/BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_RESULT.json"
  $ReportPath = "reports/self_development/PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_V1_REPORT.json"
  $ProofPath = "proofs/self_development/PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_V1.json"

  $RepoRoot = Resolve-Phase149ValidatorPath -RepoRoot $RepoRoot -Path "."
  Push-Location $RepoRoot

  foreach ($identityFile in @(
    "CAPABILITY_ROADMAP.json",
    "GENESIS_STATE.json",
    "TASK_QUEUE.json",
    "packs/registry.json",
    "orchestrator/run.ps1"
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase149ValidatorPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  if ($Branch -eq "main") {
    throw "PHASE149_VALIDATE_MAIN_BRANCH_FORBIDDEN"
  }

  foreach ($requiredPath in @(
    "modules/invoke_builder_reading_and_capability_reuse_session_001.ps1",
    "validators/validate_phase149_builder_reading_and_capability_reuse_session_v1.ps1",
    $Phase148ProofPath,
    $Phase148ResultPath,
    $SourcePolicyPath,
    $TrustedSourcesPath,
    $CapabilityRegistryPath,
    $SessionTracePath,
    $CapabilityReuseSummaryPath,
    $SourcePolicyReadSummaryPath,
    $LearningCardPath,
    $ReuseProposalPath,
    $ResultPath,
    $ReportPath,
    $ProofPath
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase149ValidatorPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE149_VALIDATE_MISSING_REQUIRED_PATH=$requiredPath"
    }
  }

  $AllowedExact = @(
    "modules/invoke_builder_reading_and_capability_reuse_session_001.ps1",
    "validators/validate_phase149_builder_reading_and_capability_reuse_session_v1.ps1",
    $SessionTracePath,
    $CapabilityReuseSummaryPath,
    $SourcePolicyReadSummaryPath,
    $LearningCardPath,
    $ReuseProposalPath,
    $ResultPath,
    $ReportPath,
    $ProofPath
  )
  $StatusLines = @(git status --short --untracked-files=all)
  foreach ($line in $StatusLines) {
    $path = Get-Phase149StatusPath -StatusLine $line
    if (-not ($AllowedExact -contains $path)) {
      throw "PHASE149_VALIDATE_CHANGE_OUTSIDE_ALLOWED_SCOPE=$line"
    }
  }

  $ProtectedStatus = @(git status --short --untracked-files=all -- `
    orchestrator/run.ps1 `
    TASK_QUEUE.json `
    GENESIS_STATE.json `
    CAPABILITY_ROADMAP.json `
    packs/registry.json `
    route_locks `
    runtime_sessions/builder_life_loop/current `
    generated_agents `
    applied_agents `
    proofs/self_development/PHASE142_BUILDER_NEXT_GAP_SELECTOR_RUNTIME_V1.json `
    proofs/self_development/PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1.json `
    proofs/self_development/PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_V1.json `
    proofs/self_development/PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1.json `
    proofs/self_development/PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_V1.json `
    proofs/self_development/PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_V1.json `
    proofs/self_development/PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1.json `
    reports/self_development/PHASE142_BUILDER_NEXT_GAP_SELECTOR_RUNTIME_V1_REPORT.json `
    reports/self_development/PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1_REPORT.json `
    reports/self_development/PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_V1_REPORT.json `
    reports/self_development/PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1_REPORT.json `
    reports/self_development/PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_V1_REPORT.json `
    reports/self_development/PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_V1_REPORT.json `
    reports/self_development/PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1_REPORT.json 2>$null)
  if ($ProtectedStatus.Count -gt 0) {
    throw "PHASE149_VALIDATE_PROTECTED_SCOPE_CHANGED=$($ProtectedStatus -join '; ')"
  }

  $Phase148Proof = Read-Phase149ValidatorJson -RepoRoot $RepoRoot -Path $Phase148ProofPath
  $Phase148Result = Read-Phase149ValidatorJson -RepoRoot $RepoRoot -Path $Phase148ResultPath
  Assert-Phase149ValidatorEquals -Actual $Phase148Proof.status -Expected "PASS" -Name "phase148_proof_status"
  Assert-Phase149ValidatorEquals -Actual $Phase148Result.status -Expected "PASS" -Name "phase148_result_status"
  Assert-Phase149ValidatorEquals -Actual $Phase148Proof.next_allowed_step -Expected $Phase148NextAllowedStep -Name "phase148_proof_next_allowed_step"
  Assert-Phase149ValidatorEquals -Actual $Phase148Result.next_allowed_step -Expected $Phase148NextAllowedStep -Name "phase148_result_next_allowed_step"

  $SourcePolicy = Read-Phase149ValidatorJson -RepoRoot $RepoRoot -Path $SourcePolicyPath
  foreach ($field in @("default_trust","external_fetch_allowed","install_allowed","executable_use_allowed")) {
    if (-not ($SourcePolicy.PSObject.Properties.Name -contains $field)) {
      throw "PHASE149_VALIDATE_SOURCE_POLICY_FIELD_MISSING=$field"
    }
  }
  Assert-Phase149ValidatorFalse -Actual $SourcePolicy.default_trust -Name "source_policy_default_trust"
  Assert-Phase149ValidatorFalse -Actual $SourcePolicy.external_fetch_allowed -Name "source_policy_external_fetch_allowed"
  Assert-Phase149ValidatorFalse -Actual $SourcePolicy.install_allowed -Name "source_policy_install_allowed"
  Assert-Phase149ValidatorFalse -Actual $SourcePolicy.executable_use_allowed -Name "source_policy_executable_use_allowed"

  $TrustedSources = Read-Phase149ValidatorJson -RepoRoot $RepoRoot -Path $TrustedSourcesPath
  if (-not ($TrustedSources.PSObject.Properties.Name -contains "trusted_sources")) {
    throw "PHASE149_VALIDATE_TRUSTED_SOURCES_FIELD_MISSING=trusted_sources"
  }
  if (-not ($TrustedSources.PSObject.Properties.Name -contains "trusted_source_count")) {
    throw "PHASE149_VALIDATE_TRUSTED_SOURCES_FIELD_MISSING=trusted_source_count"
  }
  Assert-Phase149ValidatorEquals -Actual $TrustedSources.trusted_source_count -Expected 0 -Name "trusted_source_count"
  Assert-Phase149ValidatorEquals -Actual @($TrustedSources.trusted_sources).Count -Expected 0 -Name "trusted_sources_empty"

  $CapabilityRegistry = Read-Phase149ValidatorJson -RepoRoot $RepoRoot -Path $CapabilityRegistryPath
  Assert-Phase149ValidatorEquals -Actual $CapabilityRegistry.status -Expected "PASS" -Name "capability_registry_status"
  if (@($CapabilityRegistry.capabilities).Count -lt 1) {
    throw "PHASE149_VALIDATE_CAPABILITY_REGISTRY_EMPTY"
  }

  $SessionTrace = Read-Phase149ValidatorJson -RepoRoot $RepoRoot -Path $SessionTracePath
  $CapabilityReuseSummary = Read-Phase149ValidatorJson -RepoRoot $RepoRoot -Path $CapabilityReuseSummaryPath
  $SourcePolicyReadSummary = Read-Phase149ValidatorJson -RepoRoot $RepoRoot -Path $SourcePolicyReadSummaryPath
  $LearningCard = Read-Phase149ValidatorJson -RepoRoot $RepoRoot -Path $LearningCardPath
  $ReuseProposal = Read-Phase149ValidatorJson -RepoRoot $RepoRoot -Path $ReuseProposalPath
  $Result = Read-Phase149ValidatorJson -RepoRoot $RepoRoot -Path $ResultPath
  $Report = Read-Phase149ValidatorJson -RepoRoot $RepoRoot -Path $ReportPath
  $Proof = Read-Phase149ValidatorJson -RepoRoot $RepoRoot -Path $ProofPath

  foreach ($artifact in @($SessionTrace, $CapabilityReuseSummary, $SourcePolicyReadSummary, $LearningCard, $ReuseProposal, $Result, $Report, $Proof)) {
    Assert-Phase149ValidatorEquals -Actual $artifact.status -Expected "PASS" -Name "artifact_status"
    Assert-Phase149ValidatorEquals -Actual $artifact.next_allowed_step -Expected $NextAllowedStep -Name "artifact_next_allowed_step"
  }

  $SelectedCapabilityId = $Proof.selected_capability_id
  if ([string]::IsNullOrWhiteSpace($SelectedCapabilityId)) {
    throw "PHASE149_VALIDATE_SELECTED_CAPABILITY_ID_EMPTY"
  }
  $SelectedCapabilityPath = "capability_shelf/capabilities/$SelectedCapabilityId.json"
  if (-not (Test-Path -LiteralPath (Resolve-Phase149ValidatorPath -RepoRoot $RepoRoot -Path $SelectedCapabilityPath))) {
    throw "PHASE149_VALIDATE_SELECTED_CAPABILITY_FILE_MISSING=$SelectedCapabilityPath"
  }
  $SelectedCapability = Read-Phase149ValidatorJson -RepoRoot $RepoRoot -Path $SelectedCapabilityPath
  Assert-Phase149ValidatorEquals -Actual $SelectedCapability.capability_id -Expected $SelectedCapabilityId -Name "selected_capability_file_id"

  Assert-Phase149ValidatorEquals -Actual $SessionTrace.session_id -Expected $RunId -Name "session_trace_session_id"
  Assert-Phase149ValidatorEquals -Actual $SessionTrace.step_id -Expected $StepId -Name "session_trace_step_id"
  Assert-Phase149ValidatorEquals -Actual $SessionTrace.selected_capability_id -Expected $SelectedCapabilityId -Name "session_trace_selected_capability"
  Assert-Phase149ValidatorEquals -Actual $SessionTrace.read_scope -Expected "internal_repo_only" -Name "session_trace_read_scope"

  Assert-Phase149ValidatorEquals -Actual $CapabilityReuseSummary.selected_capability_id -Expected $SelectedCapabilityId -Name "reuse_summary_selected_capability"
  Assert-Phase149ValidatorTrue -Actual $CapabilityReuseSummary.reusable_contract_found -Name "reuse_summary_reusable_contract_found"
  Assert-Phase149ValidatorTrue -Actual $CapabilityReuseSummary.validator_or_example_found -Name "reuse_summary_validator_or_example_found"

  Assert-Phase149ValidatorEquals -Actual $SourcePolicyReadSummary.trusted_source_count -Expected 0 -Name "summary_trusted_source_count"
  Assert-Phase149ValidatorFalse -Actual $SourcePolicyReadSummary.external_fetch_allowed -Name "summary_external_fetch_allowed"
  Assert-Phase149ValidatorFalse -Actual $SourcePolicyReadSummary.install_allowed -Name "summary_install_allowed"
  Assert-Phase149ValidatorFalse -Actual $SourcePolicyReadSummary.executable_use_allowed -Name "summary_executable_use_allowed"

  Assert-Phase149ValidatorEquals -Actual $LearningCard.lesson -Expected "reuse existing capability before building new organ" -Name "learning_card_lesson"
  Assert-Phase149ValidatorEquals -Actual $LearningCard.selected_capability_id -Expected $SelectedCapabilityId -Name "learning_card_selected_capability"
  Assert-Phase149ValidatorEquals -Actual $LearningCard.absorption_status -Expected "CANDIDATE_LEARNING_CARD" -Name "learning_card_absorption_status"
  if (@($LearningCard.evidence_files).Count -lt 4) {
    throw "PHASE149_VALIDATE_LEARNING_CARD_EVIDENCE_TOO_SHORT"
  }

  Assert-Phase149ValidatorEquals -Actual $ReuseProposal.proposal_type -Expected "CAPABILITY_REUSE" -Name "reuse_proposal_type"
  Assert-Phase149ValidatorEquals -Actual $ReuseProposal.selected_capability_id -Expected $SelectedCapabilityId -Name "reuse_proposal_selected_capability"
  Assert-Phase149ValidatorFalse -Actual $ReuseProposal.promotion_required -Name "reuse_proposal_promotion_required"
  Assert-Phase149ValidatorFalse -Actual $ReuseProposal.accepted_state_change_requested -Name "reuse_proposal_accepted_state_change_requested"
  Assert-Phase149ValidatorTrue -Actual $ReuseProposal.next_use_candidate -Name "reuse_proposal_next_use_candidate"

  foreach ($artifact in @($SessionTrace, $LearningCard, $ReuseProposal, $Result, $Proof)) {
    Assert-Phase149ValidatorFalse -Actual $artifact.external_fetch_performed -Name "external_fetch_performed"
    Assert-Phase149ValidatorFalse -Actual $artifact.dependency_install_performed -Name "dependency_install_performed"
    Assert-Phase149ValidatorFalse -Actual $artifact.executable_materials_used -Name "executable_materials_used"
    Assert-Phase149ValidatorFalse -Actual $artifact.accepted_state_mutated -Name "accepted_state_mutated"
    Assert-Phase149ValidatorFalse -Actual $artifact.external_agents_created -Name "external_agents_created"
  }

  foreach ($artifact in @($SessionTrace, $Result, $Proof)) {
    Assert-Phase149ValidatorFalse -Actual $artifact.orchestrator_changed -Name "orchestrator_changed"
    Assert-Phase149ValidatorFalse -Actual $artifact.route_lock_changed -Name "route_lock_changed"
    Assert-Phase149ValidatorFalse -Actual $artifact.current_runtime_changed -Name "current_runtime_changed"
    Assert-Phase149ValidatorEquals -Actual $artifact.trusted_source_count -Expected 0 -Name "trusted_source_count"
  }

  Assert-Phase149ValidatorEquals -Actual $Proof.step_id -Expected $StepId -Name "proof_step_id"
  Assert-Phase149ValidatorEquals -Actual $Proof.run_id -Expected $RunId -Name "proof_run_id"
  Assert-Phase149ValidatorTrue -Actual $Proof.phase148_verified -Name "proof_phase148_verified"
  Assert-Phase149ValidatorTrue -Actual $Proof.internal_sources_read -Name "proof_internal_sources_read"
  Assert-Phase149ValidatorTrue -Actual $Proof.capability_registry_read -Name "proof_capability_registry_read"
  Assert-Phase149ValidatorTrue -Actual $Proof.capability_reuse_session_created -Name "proof_capability_reuse_session_created"
  Assert-Phase149ValidatorTrue -Actual $Proof.learning_card_created -Name "proof_learning_card_created"
  Assert-Phase149ValidatorTrue -Actual $Proof.reuse_proposal_created -Name "proof_reuse_proposal_created"

  $Queue = Read-Phase149ValidatorJson -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
  Assert-Phase149ValidatorEquals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

  Write-Host "PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_VALIDATE_RESULT=PASS"
  Write-Host "SELECTED_CAPABILITY_ID=$SelectedCapabilityId"
  Write-Host "CAPABILITY_REUSE_SESSION_CREATED=True"
  Write-Host "LEARNING_CARD_CREATED=True"
  Write-Host "REUSE_PROPOSAL_CREATED=True"
  Write-Host "TRUSTED_SOURCE_COUNT=0"
  Write-Host "EXTERNAL_FETCH_PERFORMED=False"
  Write-Host "DEPENDENCY_INSTALL_PERFORMED=False"
  Write-Host "EXECUTABLE_MATERIALS_USED=False"
  Write-Host "ACCEPTED_STATE_MUTATED=False"
  Write-Host "EXTERNAL_AGENTS_CREATED=False"
  Write-Host "ORCHESTRATOR_CHANGED=False"
  Write-Host "ROUTE_LOCK_CHANGED=False"
  Write-Host "CURRENT_RUNTIME_CHANGED=False"
  Write-Host "NEXT_ALLOWED_STEP=PHASE150_BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_V1"
} catch {
  Write-Host "PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE149_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  Pop-Location
}
