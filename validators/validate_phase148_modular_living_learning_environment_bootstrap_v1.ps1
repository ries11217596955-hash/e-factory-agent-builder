param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Resolve-Phase148ValidatorPath {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase148ValidatorJson {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase148ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE148_VALIDATE_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Read-Phase148ValidatorText {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase148ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE148_VALIDATE_MISSING_TEXT=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw
}

function Assert-Phase148ValidatorEquals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE148_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase148ValidatorTrue {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE148_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase148ValidatorFalse {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE148_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase148ValidatorAtLeast {
  param(
    [object]$Actual,
    [int]$Minimum,
    [string]$Name
  )

  if ([int]$Actual -lt $Minimum) {
    throw "PHASE148_VALIDATE_COUNT_TOO_LOW=$Name actual=$Actual minimum=$Minimum"
  }
}

function Assert-Phase148ValidatorContains {
  param(
    [string]$Text,
    [string]$Needle,
    [string]$Name
  )

  if (-not $Text.Contains($Needle)) {
    throw "PHASE148_VALIDATE_TEXT_MISSING=$Name needle=$Needle"
  }
}

function Get-Phase148StatusPath {
  param([string]$StatusLine)

  if ($StatusLine -match '^.. (.+)$') {
    return ($Matches[1] -replace '\\', '/')
  }
  return ($StatusLine -replace '\\', '/')
}

try {
  $StepId = "PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1"
  $RunId = "PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_001"
  $PreviousStep = "PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_V1"
  $PreviousFormalNextStep = "PHASE148_BUILDER_SELF_CORRECTION_RETENTION_TRIAL_V1"
  $NextAllowedStep = "PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_V1"
  $PreviousAcceptedHead = "cb43e79"

  $RepoRoot = Resolve-Phase148ValidatorPath -RepoRoot $RepoRoot -Path "."
  Push-Location $RepoRoot

  foreach ($identityFile in @(
    "CAPABILITY_ROADMAP.json",
    "GENESIS_STATE.json",
    "TASK_QUEUE.json",
    "packs/registry.json",
    "orchestrator/run.ps1"
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase148ValidatorPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  if ($Branch -eq "main") {
    throw "PHASE148_VALIDATE_MAIN_BRANCH_FORBIDDEN"
  }

  $Phase147ProofPath = "proofs/self_development/PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_V1.json"
  $RouteChangeRequestPath = "route_change_requests/PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1.md"
  $CapabilityRegistryPath = "capability_shelf/registry.json"
  $SourcePolicyPath = "source_registry/source_policy.json"
  $TrustedSourcesPath = "source_registry/trusted_sources.json"
  $AllowedSourcesPath = "source_registry/allowed_sources.json"
  $BlockedSourcesPath = "source_registry/blocked_sources.json"
  $SessionPolicyPath = "living_learning_environment/session_policy.json"
  $PromotionPolicyPath = "living_learning_environment/promotion_policy.json"
  $SandboxWritePolicyPath = "living_learning_environment/sandbox_write_policy.json"
  $ResultPath = "self_control/BUILDER_MODULAR_LIVING_LEARNING_ENVIRONMENT_RESULT.json"
  $ReportPath = "reports/self_development/PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1_REPORT.json"
  $ProofPath = "proofs/self_development/PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1.json"

  foreach ($requiredPath in @(
    "modules/invoke_builder_modular_living_learning_environment_bootstrap_001.ps1",
    "validators/validate_phase148_modular_living_learning_environment_bootstrap_v1.ps1",
    $Phase147ProofPath,
    $RouteChangeRequestPath,
    $CapabilityRegistryPath,
    $SourcePolicyPath,
    $TrustedSourcesPath,
    $AllowedSourcesPath,
    $BlockedSourcesPath,
    "source_registry/source_cards/README.md",
    $SessionPolicyPath,
    $PromotionPolicyPath,
    $SandboxWritePolicyPath,
    $ResultPath,
    $ReportPath,
    $ProofPath
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase148ValidatorPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE148_VALIDATE_MISSING_REQUIRED_PATH=$requiredPath"
    }
  }

  $AllowedExact = @(
    "modules/invoke_builder_modular_living_learning_environment_bootstrap_001.ps1",
    "validators/validate_phase148_modular_living_learning_environment_bootstrap_v1.ps1",
    $RouteChangeRequestPath,
    $ResultPath,
    $ReportPath,
    $ProofPath
  )
  $AllowedPrefixes = @(
    "capability_shelf/",
    "knowledge_library/",
    "source_registry/",
    "living_learning_environment/"
  )

  $StatusLines = @(git status --short --untracked-files=all)
  foreach ($line in $StatusLines) {
    $path = Get-Phase148StatusPath -StatusLine $line
    $allowed = $false
    if ($AllowedExact -contains $path) {
      $allowed = $true
    }
    foreach ($prefix in $AllowedPrefixes) {
      if ($path.StartsWith($prefix, [System.StringComparison]::Ordinal)) {
        $allowed = $true
      }
    }
    if (-not $allowed) {
      throw "PHASE148_VALIDATE_CHANGE_OUTSIDE_ALLOWED_SCOPE=$line"
    }
  }

  $ProtectedPhaseArtifacts = @(
    "proofs/self_development/PHASE142_BUILDER_NEXT_GAP_SELECTOR_RUNTIME_V1.json",
    "proofs/self_development/PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1.json",
    "proofs/self_development/PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_V1.json",
    "proofs/self_development/PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1.json",
    "proofs/self_development/PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_V1.json",
    $Phase147ProofPath,
    "reports/self_development/PHASE142_BUILDER_NEXT_GAP_SELECTOR_RUNTIME_V1_REPORT.json",
    "reports/self_development/PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1_REPORT.json",
    "reports/self_development/PHASE144_BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_V1_REPORT.json",
    "reports/self_development/PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1_REPORT.json",
    "reports/self_development/PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_V1_REPORT.json",
    "reports/self_development/PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_V1_REPORT.json",
    "self_control/BUILDER_NEXT_GAP_SELECTOR_RESULT.json",
    "self_control/BUILDER_CORRECTION_RESPONSE_TRIAL_RESULT.json",
    "self_control/BUILDER_BEHAVIOR_ADAPTATION_SCALE_TRIAL_RESULT.json",
    "self_control/BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_RESULT.json",
    "self_control/BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_RESULT.json",
    "self_control/BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_RESULT.json"
  )
  $ProtectedStatus = @(git status --short --untracked-files=all -- $ProtectedPhaseArtifacts 2>$null)
  if ($ProtectedStatus.Count -gt 0) {
    throw "PHASE148_VALIDATE_ACCEPTED_PHASE_ARTIFACTS_CHANGED=$($ProtectedStatus -join '; ')"
  }

  $CurrentRuntimeStatus = @(git status --short --untracked-files=all -- runtime_sessions/builder_life_loop/current 2>$null)
  if ($CurrentRuntimeStatus.Count -gt 0) {
    throw "PHASE148_VALIDATE_CURRENT_RUNTIME_ARTIFACTS_CHANGED=$($CurrentRuntimeStatus -join '; ')"
  }

  $ExistingTrialStatus = @(git status --short --untracked-files=all -- `
    runtime_sessions/builder_life_loop/observations `
    runtime_sessions/builder_life_loop/correction_trials `
    runtime_sessions/builder_life_loop/adaptation_trials `
    runtime_sessions/builder_life_loop/multi_session_trials `
    runtime_sessions/builder_life_loop/self_correction_trials 2>$null)
  if ($ExistingTrialStatus.Count -gt 0) {
    throw "PHASE148_VALIDATE_EXISTING_TRIAL_ARTIFACTS_CHANGED=$($ExistingTrialStatus -join '; ')"
  }

  $OrchestratorStatus = @(git status --short --untracked-files=all -- orchestrator/run.ps1 2>$null)
  if ($OrchestratorStatus.Count -gt 0) {
    throw "PHASE148_VALIDATE_ORCHESTRATOR_MODIFIED=$($OrchestratorStatus -join '; ')"
  }
  $RouteLocksStatus = @(git status --short --untracked-files=all -- route_locks 2>$null)
  if ($RouteLocksStatus.Count -gt 0) {
    throw "PHASE148_VALIDATE_ROUTE_LOCKS_MODIFIED=$($RouteLocksStatus -join '; ')"
  }
  $GeneratedStatus = @(git status --short --untracked-files=all -- generated_agents agent_catalog applied_agents 2>$null)
  if ($GeneratedStatus.Count -gt 0) {
    throw "PHASE148_VALIDATE_EXTERNAL_AGENT_SCOPE_CHANGED=$($GeneratedStatus -join '; ')"
  }

  $Phase147Proof = Read-Phase148ValidatorJson -RepoRoot $RepoRoot -Path $Phase147ProofPath
  Assert-Phase148ValidatorEquals -Actual $Phase147Proof.status -Expected "PASS" -Name "phase147_status"
  Assert-Phase148ValidatorEquals -Actual $Phase147Proof.next_allowed_step -Expected $PreviousFormalNextStep -Name "phase147_next_allowed_step"

  $RouteChangeText = Read-Phase148ValidatorText -RepoRoot $RepoRoot -Path $RouteChangeRequestPath
  Assert-Phase148ValidatorContains -Text $RouteChangeText -Needle "from: PHASE148_BUILDER_SELF_CORRECTION_RETENTION_TRIAL_V1" -Name "route_change_from"
  Assert-Phase148ValidatorContains -Text $RouteChangeText -Needle "to: PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1" -Name "route_change_to"
  Assert-Phase148ValidatorContains -Text $RouteChangeText -Needle "missing modular capability shelf, source registry, knowledge library, and living learning environment" -Name "route_change_reason"
  Assert-Phase148ValidatorContains -Text $RouteChangeText -Needle "deferred_step: PHASE148_BUILDER_SELF_CORRECTION_RETENTION_TRIAL_V1" -Name "route_change_deferred"

  $CapabilityRegistry = Read-Phase148ValidatorJson -RepoRoot $RepoRoot -Path $CapabilityRegistryPath
  Assert-Phase148ValidatorEquals -Actual $CapabilityRegistry.status -Expected "PASS" -Name "capability_registry_status"
  $Capabilities = @($CapabilityRegistry.capabilities)
  Assert-Phase148ValidatorAtLeast -Actual $Capabilities.Count -Minimum 10 -Name "reusable_capability_count"
  foreach ($capability in $Capabilities) {
    foreach ($requiredField in @(
      "capability_id",
      "status",
      "purpose",
      "owner_line",
      "existing_files",
      "read_paths",
      "write_paths",
      "forbidden_paths",
      "safe_to_reuse",
      "runtime_mutates_repo",
      "requires_owner_prompt",
      "requires_codex",
      "can_be_used_by_builder",
      "example_usage_path",
      "validator_reference",
      "known_risks",
      "promotion_requirements"
    )) {
      if (-not ($capability.PSObject.Properties.Name -contains $requiredField)) {
        throw "PHASE148_VALIDATE_CAPABILITY_FIELD_MISSING capability=$($capability.capability_id) field=$requiredField"
      }
    }
    if ($capability.status -notin @("READY","PARTIAL")) {
      throw "PHASE148_VALIDATE_CAPABILITY_STATUS_INVALID capability=$($capability.capability_id) status=$($capability.status)"
    }
    Assert-Phase148ValidatorEquals -Actual $capability.owner_line -Expected "SELF_BUILD" -Name "capability_owner_line"
    Assert-Phase148ValidatorFalse -Actual $capability.requires_owner_prompt -Name "capability_requires_owner_prompt"
    Assert-Phase148ValidatorFalse -Actual $capability.requires_codex -Name "capability_requires_codex"
    foreach ($existingFile in @($capability.existing_files)) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase148ValidatorPath -RepoRoot $RepoRoot -Path $existingFile))) {
        throw "PHASE148_VALIDATE_CAPABILITY_EXISTING_FILE_MISSING capability=$($capability.capability_id) file=$existingFile"
      }
    }
    foreach ($createdReference in @($capability.example_usage_path, $capability.validator_reference)) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase148ValidatorPath -RepoRoot $RepoRoot -Path $createdReference))) {
        throw "PHASE148_VALIDATE_CAPABILITY_REFERENCE_MISSING capability=$($capability.capability_id) file=$createdReference"
      }
    }
  }

  $RequiredCapabilities = @(
    "observation_runner",
    "life_loop_runner",
    "correction_inbox",
    "restore_state",
    "checkpoint_publish",
    "self_learning_memory",
    "observation_only_result",
    "self_correction_result",
    "material_governance",
    "pack_registry"
  )
  foreach ($requiredCapability in $RequiredCapabilities) {
    if (-not @($Capabilities | Where-Object { $_.capability_id -eq $requiredCapability })) {
      throw "PHASE148_VALIDATE_REQUIRED_CAPABILITY_MISSING=$requiredCapability"
    }
  }

  $OperationFiles = @(Get-ChildItem -LiteralPath (Resolve-Phase148ValidatorPath -RepoRoot $RepoRoot -Path "capability_shelf/operation_contracts") -Filter "*.json" -File)
  Assert-Phase148ValidatorAtLeast -Actual $OperationFiles.Count -Minimum 12 -Name "operation_contract_count"
  $RequiredOperations = @(
    "start_observation_session",
    "watch_observation_session",
    "stop_observation_session",
    "write_correction",
    "restore_state",
    "publish_checkpoint",
    "read_learning_memory",
    "read_material_catalog",
    "quarantine_material_candidate",
    "create_learning_card",
    "create_proposal",
    "create_module_request",
    "promote_candidate_to_builder_state"
  )
  $OperationIds = New-Object System.Collections.Generic.List[string]
  foreach ($operationFile in $OperationFiles) {
    $operationPath = ("capability_shelf/operation_contracts/" + $operationFile.Name)
    $operation = Read-Phase148ValidatorJson -RepoRoot $RepoRoot -Path $operationPath
    $OperationIds.Add($operation.operation_id) | Out-Null
    foreach ($requiredField in @(
      "operation_id",
      "purpose",
      "allowed_inputs",
      "allowed_outputs",
      "read_scope",
      "write_scope",
      "forbidden_scope",
      "proof_required",
      "owner_prompt_required",
      "codex_required",
      "safe_failure_behavior",
      "rollback_behavior",
      "validator_expectations"
    )) {
      if (-not ($operation.PSObject.Properties.Name -contains $requiredField)) {
        throw "PHASE148_VALIDATE_OPERATION_FIELD_MISSING operation=$($operation.operation_id) field=$requiredField"
      }
    }
    Assert-Phase148ValidatorFalse -Actual $operation.owner_prompt_required -Name "operation_owner_prompt_required"
    Assert-Phase148ValidatorFalse -Actual $operation.codex_required -Name "operation_codex_required"
  }
  foreach ($requiredOperation in $RequiredOperations) {
    if (-not ($OperationIds -contains $requiredOperation)) {
      throw "PHASE148_VALIDATE_REQUIRED_OPERATION_MISSING=$requiredOperation"
    }
  }

  foreach ($folder in @(
    "knowledge_library",
    "knowledge_library/internal",
    "knowledge_library/official_docs",
    "knowledge_library/reference_only",
    "knowledge_library/learning_cards",
    "knowledge_library/summaries",
    "knowledge_library/reading_sessions"
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase148ValidatorPath -RepoRoot $RepoRoot -Path $folder))) {
      throw "PHASE148_VALIDATE_KNOWLEDGE_LIBRARY_FOLDER_MISSING=$folder"
    }
  }
  foreach ($readmePath in @(
    "knowledge_library/README.md",
    "knowledge_library/internal/README.md",
    "knowledge_library/official_docs/README.md",
    "knowledge_library/reference_only/README.md",
    "knowledge_library/learning_cards/README.md",
    "knowledge_library/summaries/README.md"
  )) {
    $readme = Read-Phase148ValidatorText -RepoRoot $RepoRoot -Path $readmePath
    foreach ($needle in @("What Belongs Here","What Must Not Be Placed Here","Builder Read Rules","Provenance And Citation","Learning Cards","Summary Versus Trusted Knowledge")) {
      Assert-Phase148ValidatorContains -Text $readme -Needle $needle -Name "knowledge_readme_required_section"
    }
  }

  $SourcePolicy = Read-Phase148ValidatorJson -RepoRoot $RepoRoot -Path $SourcePolicyPath
  $TrustedSources = Read-Phase148ValidatorJson -RepoRoot $RepoRoot -Path $TrustedSourcesPath
  $AllowedSources = Read-Phase148ValidatorJson -RepoRoot $RepoRoot -Path $AllowedSourcesPath
  $BlockedSources = Read-Phase148ValidatorJson -RepoRoot $RepoRoot -Path $BlockedSourcesPath
  foreach ($artifact in @($SourcePolicy, $TrustedSources, $AllowedSources, $BlockedSources)) {
    Assert-Phase148ValidatorEquals -Actual $artifact.status -Expected "PASS" -Name "source_registry_artifact_status"
  }
  Assert-Phase148ValidatorFalse -Actual $SourcePolicy.default_trust -Name "source_policy_default_trust"
  Assert-Phase148ValidatorTrue -Actual $SourcePolicy.read_allowed_without_trust -Name "source_policy_read_allowed_without_trust"
  Assert-Phase148ValidatorFalse -Actual $SourcePolicy.runtime_use_allowed_without_admission -Name "source_policy_runtime_use_allowed_without_admission"
  Assert-Phase148ValidatorFalse -Actual $SourcePolicy.install_allowed -Name "source_policy_install_allowed"
  Assert-Phase148ValidatorFalse -Actual $SourcePolicy.external_fetch_allowed -Name "source_policy_external_fetch_allowed"
  Assert-Phase148ValidatorFalse -Actual $SourcePolicy.executable_use_allowed -Name "source_policy_executable_use_allowed"
  Assert-Phase148ValidatorTrue -Actual $SourcePolicy.wikipedia_reference_only_never_trusted_automatically -Name "source_policy_wikipedia_not_trusted"
  Assert-Phase148ValidatorTrue -Actual $SourcePolicy.official_docs_allowed_readable_not_trusted_until_source_card_and_policy_gate_pass -Name "source_policy_official_docs_not_trusted"
  Assert-Phase148ValidatorTrue -Actual $SourcePolicy.github_repos_allowed_readable_not_executable_until_quarantine_admission_proof -Name "source_policy_github_not_executable"
  Assert-Phase148ValidatorTrue -Actual $SourcePolicy.new_source_must_never_start_trusted -Name "source_policy_new_source_not_trusted"
  Assert-Phase148ValidatorEquals -Actual $TrustedSources.trusted_source_count -Expected 0 -Name "trusted_source_count"
  Assert-Phase148ValidatorFalse -Actual $AllowedSources.external_fetch_enabled -Name "allowed_sources_external_fetch_enabled"

  foreach ($blockedClass in @(
    "unknown_executable_downloads",
    "unlicensed_code_snippets",
    "random_blog_runtime_code",
    "package_install_without_policy",
    "source_without_provenance",
    "source_with_unclear_terms",
    "source_requiring_secret_or_login",
    "source_that_changes_builder_runtime_without_promotion"
  )) {
    if (-not (@($BlockedSources.blocked_source_classes) -contains $blockedClass)) {
      throw "PHASE148_VALIDATE_BLOCKED_SOURCE_CLASS_MISSING=$blockedClass"
    }
  }

  $SourceCards = @(Get-ChildItem -LiteralPath (Resolve-Phase148ValidatorPath -RepoRoot $RepoRoot -Path "source_registry/source_cards") -Filter "*.json" -File)
  foreach ($sourceCardFile in $SourceCards) {
    $sourceCard = Read-Phase148ValidatorJson -RepoRoot $RepoRoot -Path ("source_registry/source_cards/" + $sourceCardFile.Name)
    if ($sourceCard.trusted -eq $true -or "$($sourceCard.trust_status)" -eq "TRUSTED") {
      throw "PHASE148_VALIDATE_SOURCE_MARKED_TRUSTED_WITHOUT_PROOF=$($sourceCardFile.Name)"
    }
    Assert-Phase148ValidatorFalse -Actual $sourceCard.external_fetch_allowed -Name "source_card_external_fetch_allowed"
    Assert-Phase148ValidatorFalse -Actual $sourceCard.install_allowed -Name "source_card_install_allowed"
    Assert-Phase148ValidatorFalse -Actual $sourceCard.executable_use_allowed -Name "source_card_executable_use_allowed"
  }

  foreach ($folder in @(
    "living_learning_environment",
    "living_learning_environment/sandbox",
    "living_learning_environment/observations",
    "living_learning_environment/proposals",
    "living_learning_environment/reading_sessions",
    "living_learning_environment/module_requests",
    "living_learning_environment/promotion_candidates",
    "living_learning_environment/promotion_gates"
  )) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase148ValidatorPath -RepoRoot $RepoRoot -Path $folder))) {
      throw "PHASE148_VALIDATE_LIVING_ENVIRONMENT_FOLDER_MISSING=$folder"
    }
  }

  $SessionPolicy = Read-Phase148ValidatorJson -RepoRoot $RepoRoot -Path $SessionPolicyPath
  $PromotionPolicy = Read-Phase148ValidatorJson -RepoRoot $RepoRoot -Path $PromotionPolicyPath
  $SandboxWritePolicy = Read-Phase148ValidatorJson -RepoRoot $RepoRoot -Path $SandboxWritePolicyPath
  foreach ($policy in @($SessionPolicy, $PromotionPolicy, $SandboxWritePolicy)) {
    Assert-Phase148ValidatorEquals -Actual $policy.status -Expected "PASS" -Name "living_policy_status"
  }
  Assert-Phase148ValidatorTrue -Actual $SessionPolicy.observation_first_policy -Name "session_observation_first_policy"
  Assert-Phase148ValidatorTrue -Actual $SessionPolicy.reuse_first_policy -Name "session_reuse_first_policy"
  Assert-Phase148ValidatorTrue -Actual $SessionPolicy.codex_only_for_missing_tool_or_proven_defect -Name "session_codex_gate"
  Assert-Phase148ValidatorFalse -Actual $SessionPolicy.external_material_trust_allowed -Name "session_external_material_trust_allowed"
  Assert-Phase148ValidatorFalse -Actual $SessionPolicy.install_allowed -Name "session_install_allowed"
  Assert-Phase148ValidatorFalse -Actual $SessionPolicy.external_fetch_allowed -Name "session_external_fetch_allowed"
  Assert-Phase148ValidatorFalse -Actual $SessionPolicy.executable_material_use_allowed -Name "session_executable_material_use_allowed"
  Assert-Phase148ValidatorTrue -Actual $PromotionPolicy.promotion_gate_required -Name "promotion_gate_required"
  Assert-Phase148ValidatorTrue -Actual $PromotionPolicy.validator_required -Name "promotion_validator_required"
  Assert-Phase148ValidatorTrue -Actual $PromotionPolicy.proof_required -Name "promotion_proof_required"
  Assert-Phase148ValidatorFalse -Actual $PromotionPolicy.production_adoption_allowed -Name "promotion_production_adoption_allowed"
  Assert-Phase148ValidatorTrue -Actual $SandboxWritePolicy.builder_sandbox_write_scope_defined -Name "sandbox_write_scope_defined"
  if (-not (@($SandboxWritePolicy.write_freely_only_inside) -contains "living_learning_environment/sandbox")) {
    throw "PHASE148_VALIDATE_SANDBOX_WRITE_SCOPE_NOT_SANDBOX_ONLY"
  }
  Assert-Phase148ValidatorTrue -Actual $SandboxWritePolicy.promotion_gate_required_for_any_state_change -Name "sandbox_promotion_gate_required"

  $Result = Read-Phase148ValidatorJson -RepoRoot $RepoRoot -Path $ResultPath
  $Report = Read-Phase148ValidatorJson -RepoRoot $RepoRoot -Path $ReportPath
  $Proof = Read-Phase148ValidatorJson -RepoRoot $RepoRoot -Path $ProofPath
  foreach ($artifact in @($Result, $Report, $Proof)) {
    Assert-Phase148ValidatorEquals -Actual $artifact.status -Expected "PASS" -Name "phase148_artifact_status"
    Assert-Phase148ValidatorEquals -Actual $artifact.next_allowed_step -Expected $NextAllowedStep -Name "phase148_next_allowed_step"
  }

  foreach ($artifact in @($Result, $Proof)) {
    Assert-Phase148ValidatorTrue -Actual $artifact.route_change_request_created -Name "route_change_request_created"
    Assert-Phase148ValidatorTrue -Actual $artifact.capability_shelf_created -Name "capability_shelf_created"
    Assert-Phase148ValidatorTrue -Actual $artifact.knowledge_library_created -Name "knowledge_library_created"
    Assert-Phase148ValidatorTrue -Actual $artifact.source_registry_created -Name "source_registry_created"
    Assert-Phase148ValidatorTrue -Actual $artifact.living_learning_environment_created -Name "living_learning_environment_created"
    Assert-Phase148ValidatorAtLeast -Actual $artifact.reusable_capability_count -Minimum 10 -Name "artifact_reusable_capability_count"
    Assert-Phase148ValidatorAtLeast -Actual $artifact.operation_contract_count -Minimum 12 -Name "artifact_operation_contract_count"
    Assert-Phase148ValidatorEquals -Actual $artifact.trusted_source_count -Expected 0 -Name "artifact_trusted_source_count"
    Assert-Phase148ValidatorFalse -Actual $artifact.external_fetch_enabled -Name "artifact_external_fetch_enabled"
    Assert-Phase148ValidatorFalse -Actual $artifact.dependency_install_allowed -Name "artifact_dependency_install_allowed"
    Assert-Phase148ValidatorFalse -Actual $artifact.executable_material_use_allowed -Name "artifact_executable_material_use_allowed"
    Assert-Phase148ValidatorTrue -Actual $artifact.accepted_phase_artifacts_untouched -Name "accepted_phase_artifacts_untouched"
    Assert-Phase148ValidatorTrue -Actual $artifact.current_runtime_artifacts_untouched -Name "current_runtime_artifacts_untouched"
  }

  Assert-Phase148ValidatorFalse -Actual $Proof.runtime_executed -Name "proof_runtime_executed"
  Assert-Phase148ValidatorTrue -Actual $Proof.bootstrap_executed -Name "proof_bootstrap_executed"
  Assert-Phase148ValidatorEquals -Actual $Proof.current_line -Expected "SELF_BUILD" -Name "proof_current_line"
  Assert-Phase148ValidatorEquals -Actual $Proof.previous_accepted_head -Expected $PreviousAcceptedHead -Name "proof_previous_accepted_head"
  Assert-Phase148ValidatorEquals -Actual $Proof.previous_step -Expected $PreviousStep -Name "proof_previous_step"
  Assert-Phase148ValidatorEquals -Actual $Proof.previous_formal_next_step -Expected $PreviousFormalNextStep -Name "proof_previous_formal_next_step"
  Assert-Phase148ValidatorFalse -Actual $Proof.external_fetch_performed -Name "proof_external_fetch_performed"
  Assert-Phase148ValidatorFalse -Actual $Proof.dependency_install_performed -Name "proof_dependency_install_performed"
  Assert-Phase148ValidatorFalse -Actual $Proof.executable_materials_used -Name "proof_executable_materials_used"
  Assert-Phase148ValidatorFalse -Actual $Proof.external_agent_production_allowed -Name "proof_external_agent_production_allowed"
  Assert-Phase148ValidatorFalse -Actual $Proof.production_adoption_allowed -Name "proof_production_adoption_allowed"
  Assert-Phase148ValidatorFalse -Actual $Proof.generated_agents_changed -Name "proof_generated_agents_changed"
  Assert-Phase148ValidatorFalse -Actual $Proof.agent_catalog_changed -Name "proof_agent_catalog_changed"
  Assert-Phase148ValidatorFalse -Actual $Proof.applied_agents_changed -Name "proof_applied_agents_changed"
  Assert-Phase148ValidatorFalse -Actual $Proof.orchestrator_modified -Name "proof_orchestrator_modified"
  Assert-Phase148ValidatorFalse -Actual $Proof.route_locks_modified -Name "proof_route_locks_modified"
  Assert-Phase148ValidatorEquals -Actual $Proof.queue_after -Expected "NONE" -Name "proof_queue_after"

  Assert-Phase148ValidatorEquals -Actual $Result.step_id -Expected $StepId -Name "result_step_id"
  Assert-Phase148ValidatorEquals -Actual $Result.previous_formal_next_step -Expected $PreviousFormalNextStep -Name "result_previous_formal_next_step"
  Assert-Phase148ValidatorTrue -Actual $Result.builder_sandbox_write_scope_defined -Name "result_builder_sandbox_write_scope_defined"
  Assert-Phase148ValidatorTrue -Actual $Result.promotion_gate_required -Name "result_promotion_gate_required"
  Assert-Phase148ValidatorTrue -Actual $Result.codex_only_for_missing_tool_or_proven_defect -Name "result_codex_gate"
  Assert-Phase148ValidatorTrue -Actual $Result.observation_first_policy -Name "result_observation_first_policy"
  Assert-Phase148ValidatorTrue -Actual $Result.reuse_first_policy -Name "result_reuse_first_policy"
  Assert-Phase148ValidatorEquals -Actual $Result.selected_next_gap -Expected $NextAllowedStep -Name "result_selected_next_gap"
  Assert-Phase148ValidatorEquals -Actual $Result.selected_by -Expected "BUILDER_RUNTIME_OR_ROUTE_CHANGE_POLICY" -Name "result_selected_by"

  foreach ($missingClosed in @("capability_shelf","knowledge_library","source_registry")) {
    if (-not (@($Report.missing_infra_closed) -contains $missingClosed)) {
      throw "PHASE148_VALIDATE_REPORT_MISSING_INFRA_CLOSED=$missingClosed"
    }
  }
  Assert-Phase148ValidatorTrue -Actual $Report.living_environment_created -Name "report_living_environment_created"
  Assert-Phase148ValidatorEquals -Actual $Report.deferred_formal_step -Expected $PreviousFormalNextStep -Name "report_deferred_formal_step"

  $Queue = Read-Phase148ValidatorJson -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
  Assert-Phase148ValidatorEquals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

  Write-Host "PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_VALIDATE_RESULT=PASS"
  Write-Host "CAPABILITY_SHELF_CREATED=True"
  Write-Host "KNOWLEDGE_LIBRARY_CREATED=True"
  Write-Host "SOURCE_REGISTRY_CREATED=True"
  Write-Host "LIVING_LEARNING_ENVIRONMENT_CREATED=True"
  Write-Host "REUSABLE_CAPABILITY_COUNT=$($Capabilities.Count)"
  Write-Host "OPERATION_CONTRACT_COUNT=$($OperationFiles.Count)"
  Write-Host "TRUSTED_SOURCE_COUNT=0"
  Write-Host "EXTERNAL_FETCH_ENABLED=False"
  Write-Host "DEPENDENCY_INSTALL_ALLOWED=False"
  Write-Host "EXECUTABLE_MATERIAL_USE_ALLOWED=False"
  Write-Host "ACCEPTED_PHASE_ARTIFACTS_UNTOUCHED=True"
  Write-Host "CURRENT_RUNTIME_ARTIFACTS_UNTOUCHED=True"
  Write-Host "ORCHESTRATOR_MODIFIED=False"
  Write-Host "ROUTE_LOCKS_MODIFIED=False"
  Write-Host "NEXT_ALLOWED_STEP=PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_V1"
} catch {
  Write-Host "PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE148_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  Pop-Location
}
