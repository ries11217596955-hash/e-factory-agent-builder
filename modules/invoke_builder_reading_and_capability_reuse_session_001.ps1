function Resolve-Phase149Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase149JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase149Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE149_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Write-Phase149JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase149Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  $json = ($Object | ConvertTo-Json -Depth $Depth) -replace "`r`n", "`n"
  if (-not $json.EndsWith("`n")) {
    $json += "`n"
  }

  [System.IO.File]::WriteAllText($fullPath, $json, [System.Text.UTF8Encoding]::new($false))
}

function Assert-Phase149Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE149_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase149False {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE149_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Invoke-BuilderReadingAndCapabilityReuseSession001 {
  param(
    [string]$RepoRoot,
    [string]$RunId = "PHASE149_READING_REUSE_SESSION_001"
  )

  $ErrorActionPreference = "Stop"
  Push-Location $RepoRoot

  try {
    $StepId = "PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_V1"
    $NextAllowedStep = "PHASE150_BUILDER_REUSE_BASED_MICRO_ORGAN_TRIAL_V1"
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

    foreach ($identityFile in @(
      "CAPABILITY_ROADMAP.json",
      "GENESIS_STATE.json",
      "TASK_QUEUE.json",
      "packs/registry.json",
      "orchestrator/run.ps1"
    )) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase149Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $Branch = (git branch --show-current).Trim()
    if ($Branch -eq "main") {
      throw "PHASE149_MAIN_BRANCH_FORBIDDEN"
    }
    Assert-Phase149Equals -Actual $Branch -Expected "phase110-idempotent-autonomy-trial-runtime" -Name "current_branch"
    $Head = (git rev-parse --short HEAD).Trim()
    Assert-Phase149Equals -Actual $Head -Expected "6741ee4" -Name "current_head"

    $ForbiddenBefore = @(git status --short --untracked-files=all -- `
      orchestrator/run.ps1 `
      route_locks `
      generated_agents `
      applied_agents `
      runtime_sessions/builder_life_loop/current `
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
    if ($ForbiddenBefore.Count -gt 0) {
      throw "PHASE149_FORBIDDEN_SCOPE_DIRTY_BEFORE=$($ForbiddenBefore -join '; ')"
    }

    $Phase148Proof = Read-Phase149JsonRequired -RepoRoot $RepoRoot -Path $Phase148ProofPath
    $Phase148Result = Read-Phase149JsonRequired -RepoRoot $RepoRoot -Path $Phase148ResultPath
    Assert-Phase149Equals -Actual $Phase148Proof.status -Expected "PASS" -Name "phase148_proof_status"
    Assert-Phase149Equals -Actual $Phase148Result.status -Expected "PASS" -Name "phase148_result_status"
    Assert-Phase149Equals -Actual $Phase148Proof.next_allowed_step -Expected $StepId -Name "phase148_proof_next_allowed_step"
    Assert-Phase149Equals -Actual $Phase148Result.next_allowed_step -Expected $StepId -Name "phase148_result_next_allowed_step"

    $SourcePolicy = Read-Phase149JsonRequired -RepoRoot $RepoRoot -Path $SourcePolicyPath
    Assert-Phase149Equals -Actual $SourcePolicy.default_trust -Expected $false -Name "source_policy_default_trust"
    Assert-Phase149Equals -Actual $SourcePolicy.external_fetch_allowed -Expected $false -Name "source_policy_external_fetch_allowed"
    Assert-Phase149Equals -Actual $SourcePolicy.install_allowed -Expected $false -Name "source_policy_install_allowed"
    Assert-Phase149Equals -Actual $SourcePolicy.executable_use_allowed -Expected $false -Name "source_policy_executable_use_allowed"

    $TrustedSources = Read-Phase149JsonRequired -RepoRoot $RepoRoot -Path $TrustedSourcesPath
    Assert-Phase149Equals -Actual $TrustedSources.trusted_source_count -Expected 0 -Name "trusted_source_count"
    Assert-Phase149Equals -Actual @($TrustedSources.trusted_sources).Count -Expected 0 -Name "trusted_sources_count"

    $CapabilityRegistry = Read-Phase149JsonRequired -RepoRoot $RepoRoot -Path $CapabilityRegistryPath
    Assert-Phase149Equals -Actual $CapabilityRegistry.status -Expected "PASS" -Name "capability_registry_status"
    $Capabilities = @($CapabilityRegistry.capabilities)
    if ($Capabilities.Count -lt 1) {
      throw "PHASE149_CAPABILITY_REGISTRY_EMPTY"
    }

    $SelectedCapability = @($Capabilities | Where-Object { $_.capability_id -eq "self_learning_memory" } | Select-Object -First 1)
    if ($SelectedCapability.Count -eq 0) {
      $SelectedCapability = @($Capabilities | Where-Object { $_.capability_id -eq "observation_runner" } | Select-Object -First 1)
    }
    if ($SelectedCapability.Count -ne 1) {
      throw "PHASE149_SELECTED_CAPABILITY_UNAVAILABLE"
    }
    $SelectedCapability = $SelectedCapability[0]
    $SelectedCapabilityId = $SelectedCapability.capability_id
    $SelectedCapabilityPath = "capability_shelf/capabilities/$SelectedCapabilityId.json"
    if (-not (Test-Path -LiteralPath (Resolve-Phase149Path -RepoRoot $RepoRoot -Path $SelectedCapabilityPath))) {
      throw "PHASE149_SELECTED_CAPABILITY_FILE_MISSING=$SelectedCapabilityPath"
    }
    $CapabilityDetail = Read-Phase149JsonRequired -RepoRoot $RepoRoot -Path $SelectedCapabilityPath

    $OperationContractPath = if ($SelectedCapabilityId -eq "self_learning_memory") {
      "capability_shelf/operation_contracts/read_learning_memory.json"
    } else {
      "capability_shelf/operation_contracts/start_observation_session.json"
    }
    $ReusableContractFound = Test-Path -LiteralPath (Resolve-Phase149Path -RepoRoot $RepoRoot -Path $OperationContractPath)
    $OperationContract = if ($ReusableContractFound) { Read-Phase149JsonRequired -RepoRoot $RepoRoot -Path $OperationContractPath } else { $null }
    $ValidatorOrExampleFound = (
      (Test-Path -LiteralPath (Resolve-Phase149Path -RepoRoot $RepoRoot -Path $CapabilityDetail.validator_reference)) -or
      (Test-Path -LiteralPath (Resolve-Phase149Path -RepoRoot $RepoRoot -Path $CapabilityDetail.example_usage_path))
    )
    $ExamplePath = "$($CapabilityDetail.example_usage_path)"
    $ValidatorReferencePath = "$($CapabilityDetail.validator_reference)"

    $SourcesRead = @(
      $Phase148ProofPath,
      $Phase148ResultPath,
      $SourcePolicyPath,
      $TrustedSourcesPath,
      $CapabilityRegistryPath,
      $SelectedCapabilityPath
    )
    if ($ReusableContractFound) { $SourcesRead += $OperationContractPath }
    if (Test-Path -LiteralPath (Resolve-Phase149Path -RepoRoot $RepoRoot -Path $ExamplePath)) { $SourcesRead += $ExamplePath }
    if (Test-Path -LiteralPath (Resolve-Phase149Path -RepoRoot $RepoRoot -Path $ValidatorReferencePath)) { $SourcesRead += $ValidatorReferencePath }

    $SessionTrace = [ordered]@{
      status = "PASS"
      session_id = $RunId
      step_id = $StepId
      selected_capability_id = $SelectedCapabilityId
      sources_read = $SourcesRead
      read_scope = "internal_repo_only"
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      accepted_state_mutated = $false
      external_agents_created = $false
      orchestrator_changed = $false
      route_lock_changed = $false
      current_runtime_changed = $false
      trusted_source_count = 0
      created_by = "BUILDER_RUNTIME"
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase149JsonFile -RepoRoot $RepoRoot -Path $SessionTracePath -Object $SessionTrace

    $CapabilityReuseSummary = [ordered]@{
      status = "PASS"
      session_id = $RunId
      step_id = $StepId
      selected_capability_id = $SelectedCapabilityId
      selected_capability_path = $SelectedCapabilityPath
      why_reused = "Capability shelf marks $SelectedCapabilityId as reusable for SELF_BUILD reading/reuse work, so Builder can absorb and reuse an existing organ instead of asking Codex to build a duplicate."
      not_rebuilt_reason = "Observation-first and reuse-first policy requires reading existing capability entries, operation contracts, examples, and validator references before creating any new organ."
      reusable_contract_found = [bool]$ReusableContractFound
      operation_contract_path = if ($ReusableContractFound) { $OperationContractPath } else { $null }
      operation_contract_id = if ($null -ne $OperationContract) { $OperationContract.operation_id } else { $null }
      validator_or_example_found = [bool]$ValidatorOrExampleFound
      validator_reference = $ValidatorReferencePath
      example_usage_path = $ExamplePath
      runtime_mutates_repo = [bool]$CapabilityDetail.runtime_mutates_repo
      safe_to_reuse = [bool]$CapabilityDetail.safe_to_reuse
      can_be_used_by_builder = [bool]$CapabilityDetail.can_be_used_by_builder
      accepted_state_mutated = $false
      external_agents_created = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase149JsonFile -RepoRoot $RepoRoot -Path $CapabilityReuseSummaryPath -Object $CapabilityReuseSummary

    $SourcePolicyReadSummary = [ordered]@{
      status = "PASS"
      session_id = $RunId
      step_id = $StepId
      source_policy_path = $SourcePolicyPath
      trusted_sources_path = $TrustedSourcesPath
      trusted_source_count = 0
      trusted_sources_empty = $true
      default_trust = $false
      external_fetch_allowed = $false
      install_allowed = $false
      executable_use_allowed = $false
      read_scope = "internal_repo_only"
      no_source_marked_trusted = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase149JsonFile -RepoRoot $RepoRoot -Path $SourcePolicyReadSummaryPath -Object $SourcePolicyReadSummary

    $LearningCard = [ordered]@{
      status = "PASS"
      card_id = "PHASE149_CAPABILITY_REUSE_LEARNING_CARD"
      step_id = $StepId
      session_id = $RunId
      lesson = "reuse existing capability before building new organ"
      selected_capability_id = $SelectedCapabilityId
      evidence_files = $SourcesRead
      absorption_status = "CANDIDATE_LEARNING_CARD"
      created_by = "BUILDER_RUNTIME"
      trusted_source_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      accepted_state_mutated = $false
      external_agents_created = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase149JsonFile -RepoRoot $RepoRoot -Path $LearningCardPath -Object $LearningCard

    $ReuseProposal = [ordered]@{
      status = "PASS"
      proposal_id = "PHASE149_REUSE_PROPOSAL"
      step_id = $StepId
      session_id = $RunId
      proposal_type = "CAPABILITY_REUSE"
      selected_capability_id = $SelectedCapabilityId
      promotion_required = $false
      accepted_state_change_requested = $false
      next_use_candidate = $true
      evidence_files = $SourcesRead
      created_by = "BUILDER_RUNTIME"
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      external_agents_created = $false
      accepted_state_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase149JsonFile -RepoRoot $RepoRoot -Path $ReuseProposalPath -Object $ReuseProposal

    $Common = [ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      phase148_verified = $true
      internal_sources_read = $true
      capability_registry_read = $true
      selected_capability_id = $SelectedCapabilityId
      capability_reuse_session_created = $true
      learning_card_created = $true
      reuse_proposal_created = $true
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      accepted_state_mutated = $false
      external_agents_created = $false
      orchestrator_changed = $false
      route_lock_changed = $false
      current_runtime_changed = $false
      trusted_source_count = 0
      selected_by = "BUILDER_RUNTIME"
      current_line = "SELF_BUILD"
      session_trace_path = $SessionTracePath
      capability_reuse_summary_path = $CapabilityReuseSummaryPath
      source_policy_read_summary_path = $SourcePolicyReadSummaryPath
      learning_card_path = $LearningCardPath
      reuse_proposal_path = $ReuseProposalPath
      next_allowed_step = $NextAllowedStep
    }

    $Result = [ordered]@{}
    foreach ($key in $Common.Keys) { $Result[$key] = $Common[$key] }
    $Result["result_id"] = "PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_RESULT"
    Write-Phase149JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $Result

    $Report = [ordered]@{
      status = "PASS"
      report_id = "PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_V1_REPORT"
      step_id = $StepId
      run_id = $RunId
      files_changed = @(
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
      files_read = $SourcesRead
      selected_capability_id = $SelectedCapabilityId
      selected_capability_path = $SelectedCapabilityPath
      operation_contract_path = if ($ReusableContractFound) { $OperationContractPath } else { $null }
      why_reused = $CapabilityReuseSummary.why_reused
      not_rebuilt_reason = $CapabilityReuseSummary.not_rebuilt_reason
      source_policy_fields_verified = @("default_trust","external_fetch_allowed","install_allowed","executable_use_allowed")
      trusted_sources_verified_empty = $true
      output_files = @(
        $SessionTracePath,
        $CapabilityReuseSummaryPath,
        $SourcePolicyReadSummaryPath,
        $LearningCardPath,
        $ReuseProposalPath,
        $ResultPath,
        $ReportPath,
        $ProofPath
      )
      risks = @(
        "PHASE149 proves controlled reading and reuse selection only; PHASE150 must prove reuse in a bounded micro-organ trial.",
        "Learning card remains candidate status and does not mutate accepted Builder state.",
        "Reuse proposal requests no state change and requires later proof before operational adoption."
      )
      cut_list = @(
        "No orchestrator change.",
        "No route lock change.",
        "No accepted PHASE142-PHASE148 artifact change.",
        "No TASK_QUEUE mutation.",
        "No generated_agents or applied_agents touch.",
        "No internet fetch.",
        "No dependency install.",
        "No external executable material use.",
        "No trusted source creation.",
        "No external agent production.",
        "No commit or push."
      )
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase149JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $Report

    $Proof = [ordered]@{}
    foreach ($key in $Common.Keys) { $Proof[$key] = $Common[$key] }
    $Proof["proof_id"] = $StepId
    $Proof["phase148_proof_path"] = $Phase148ProofPath
    $Proof["phase148_result_path"] = $Phase148ResultPath
    $Proof["source_policy_path"] = $SourcePolicyPath
    $Proof["trusted_sources_path"] = $TrustedSourcesPath
    $Proof["capability_registry_path"] = $CapabilityRegistryPath
    $Proof["result_path"] = $ResultPath
    $Proof["report_path"] = $ReportPath
    Write-Phase149JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $Proof

    return [pscustomobject][ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      selected_capability_id = $SelectedCapabilityId
      session_trace_path = $SessionTracePath
      learning_card_path = $LearningCardPath
      reuse_proposal_path = $ReuseProposalPath
      result_path = $ResultPath
      report_path = $ReportPath
      proof_path = $ProofPath
      next_allowed_step = $NextAllowedStep
    }
  } finally {
    Pop-Location
  }
}
