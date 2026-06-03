param(
  [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Normalize-Phase159ValidatorFullPath {
  param([string]$Path)

  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase159ValidatorScriptRepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE159_VALIDATE_SCRIPT_ROOT_UNAVAILABLE"
  }

  return Normalize-Phase159ValidatorFullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Get-Phase159ValidatorRemoteHead {
  param([string]$ExpectedBranch)

  $remoteRef = "origin/$ExpectedBranch"
  $remoteHead = (git rev-parse --short $remoteRef 2>$null)
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($remoteHead)) {
    $upstreamRef = (git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null)
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($upstreamRef)) {
      $remoteHead = (git rev-parse --short $upstreamRef.Trim() 2>$null)
    }
  }
  if ([string]::IsNullOrWhiteSpace($remoteHead)) {
    throw "PHASE159_VALIDATE_REMOTE_HEAD_UNAVAILABLE"
  }

  return $remoteHead.Trim()
}

$script:Phase159ValidatorResolvedRepoRoot = Resolve-Phase159ValidatorScriptRepoRoot

function Resolve-Phase159ValidatorPath {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase159ValidatorJson {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase159ValidatorPath -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE159_VALIDATE_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Assert-Phase159ValidatorEquals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE159_VALIDATE_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase159ValidatorTrue {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE159_VALIDATE_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase159ValidatorFalse {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE159_VALIDATE_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase159ValidatorContains {
  param(
    [object[]]$Values,
    [string]$Expected,
    [string]$Name
  )

  if (-not (@($Values) -contains $Expected)) {
    throw "PHASE159_VALIDATE_EXPECTED_VALUE_MISSING=$Name expected=$Expected"
  }
}

function Assert-Phase159ValidatorFlagsFalse {
  param(
    [object]$Artifact,
    [string[]]$Flags,
    [string]$Name
  )

  foreach ($flag in $Flags) {
    Assert-Phase159ValidatorFalse -Actual $Artifact.$flag -Name "${Name}:$flag"
  }
}

function Get-Phase159StatusPath {
  param([string]$StatusLine)

  if ($StatusLine -match '^.. (.+)$') {
    return ($Matches[1] -replace '\\', '/')
  }
  return ($StatusLine -replace '\\', '/')
}

function Assert-Phase159ProofFields {
  param(
    [object]$Artifact,
    [string]$Name
  )

  Assert-Phase159ValidatorEquals -Actual $Artifact.status -Expected "PASS" -Name "${Name}:status"
  Assert-Phase159ValidatorEquals -Actual $Artifact.step_id -Expected "PHASE159_BUILDER_RUNS_GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_V1" -Name "${Name}:step_id"
  Assert-Phase159ValidatorEquals -Actual $Artifact.run_id -Expected "PHASE159_NEWBORN_REFLEX_CORE_AND_LIVE_SESSION_PREP_001" -Name "${Name}:run_id"
  foreach ($flag in @(
    "phase158_verified",
    "generic_execution_bridge_proven",
    "generic_spec_sandbox_execution_result_created",
    "generic_spec_execution_validated",
    "capability_inventory_created",
    "self_map_snapshot_created",
    "newborn_reflex_core_created",
    "heartbeat_reflex_proven",
    "self_map_read_reflex_proven",
    "action_selection_reflex_proven",
    "sandbox_execution_reflex_proven",
    "validation_reflex_proven",
    "memory_event_reflex_proven",
    "next_action_decision_reflex_proven",
    "help_request_reflex_prepared",
    "teacher_channels_prepared",
    "live_session_skeleton_created",
    "two_step_newborn_reflex_proven",
    "step_002_started_from_step_001_next_action",
    "daemon_mode_prepared",
    "safe_stop"
  )) {
    Assert-Phase159ValidatorTrue -Actual $Artifact.$flag -Name "${Name}:$flag"
  }
  Assert-Phase159ValidatorEquals -Actual $Artifact.step_001_selected_action -Expected "REFRESH_CAPABILITY_INVENTORY_FROM_PROOFS" -Name "${Name}:step_001_selected_action"
  Assert-Phase159ValidatorEquals -Actual $Artifact.step_001_validation_status -Expected "PASS" -Name "${Name}:step_001_validation_status"
  Assert-Phase159ValidatorEquals -Actual $Artifact.step_002_selected_action -Expected "PREPARE_LIVE_SESSION_CHANNELS" -Name "${Name}:step_002_selected_action"
  Assert-Phase159ValidatorEquals -Actual $Artifact.step_002_validation_status -Expected "PASS" -Name "${Name}:step_002_validation_status"
  Assert-Phase159ValidatorFalse -Actual $Artifact.phase_specific_entrypoint_required -Name "${Name}:phase_specific_entrypoint_required"
  Assert-Phase159ValidatorFalse -Actual $Artifact.codex_required_for_phase159_entrypoint -Name "${Name}:codex_required_for_phase159_entrypoint"
  Assert-Phase159ValidatorFalse -Actual $Artifact.live_daemon_started -Name "${Name}:live_daemon_started"
  Assert-Phase159ValidatorFlagsFalse -Artifact $Artifact -Flags @("accepted_state_mutated", "accepted_memory_mutated", "accepted_self_model_mutated", "capability_shelf_mutated", "body_pack_mutated", "external_fetch_performed", "dependency_install_performed", "arbitrary_code_execution_used", "external_agents_created") -Name $Name
  Assert-Phase159ValidatorEquals -Actual $Artifact.queue_after -Expected "NONE" -Name "${Name}:queue_after"
  Assert-Phase159ValidatorFalse -Actual $Artifact.codex_needed_for_next_step -Name "${Name}:codex_needed_for_next_step"
  Assert-Phase159ValidatorEquals -Actual $Artifact.next_allowed_step -Expected "PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_V1" -Name "${Name}:next_allowed_step"
}

$Pushed = $false

try {
  $StepId = "PHASE159_BUILDER_RUNS_GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_V1"
  $RunId = "PHASE159_NEWBORN_REFLEX_CORE_AND_LIVE_SESSION_PREP_001"
  $NextAllowedStep = "PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_V1"
  $Phase158StepId = "PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_V1"
  $Phase158RunId = "PHASE158_REVIEWED_SELF_GAP_SKILL_REUSE_TRIAL_001"
  $RuntimeRoot = "runtime_sessions/newborn_reflex/$RunId"
  $RouteAlignmentPath = "route_change_requests/PHASE159_NEWBORN_REFLEX_CORE_AND_LIVE_SESSION_PREP_ALIGNMENT_REQUEST.md"
  $ModulePath = "modules/invoke_builder_runs_generic_self_written_spec_execution_bridge_001.ps1"
  $ValidatorPath = "validators/validate_phase159_builder_runs_generic_self_written_spec_execution_bridge_v1.ps1"
  $QueuePath = "TASK_QUEUE.json"
  $ResultPath = "self_control/BUILDER_NEWBORN_REFLEX_CORE_AND_LIVE_SESSION_PREP_RESULT.json"
  $ReportPath = "reports/self_development/PHASE159_BUILDER_RUNS_GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_V1_REPORT.json"
  $ProofPath = "proofs/self_development/PHASE159_BUILDER_RUNS_GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_V1.json"

  $PhaseProofPaths = @(
    "proofs/self_development/PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_V1.json",
    "proofs/self_development/PHASE153_BUILDER_VALIDATES_SANDBOX_SELF_BUILD_RESULT_AND_LEARNS_V1.json",
    "proofs/self_development/PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_V1.json",
    "proofs/self_development/PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_V1.json",
    "proofs/self_development/PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1.json",
    "proofs/self_development/PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1.json",
    "proofs/self_development/PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_V1.json"
  )

  $Phase158ProofPath = "proofs/self_development/PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_V1.json"
  $Phase158BridgePaths = @(
    "living_learning_environment/reuse_trials/$Phase158RunId/generic_spec_execution_request.json",
    "living_learning_environment/reuse_trials/$Phase158RunId/generic_spec_execution_admission.json",
    "living_learning_environment/reuse_trials/$Phase158RunId/generic_spec_sandbox_execution_result.json",
    "living_learning_environment/reuse_trials/$Phase158RunId/generic_spec_execution_validation_result.json"
  )

  $SessionBootPath = "$RuntimeRoot/session_boot.json"
  $Phase158BridgeReadPath = "$RuntimeRoot/phase158_bridge_read.json"
  $SelfMapSnapshotPath = "$RuntimeRoot/self_map_snapshot.json"
  $CapabilityInventoryPath = "$RuntimeRoot/capability_inventory.json"
  $ProvenCapabilitiesPath = "$RuntimeRoot/proven_capabilities.json"
  $SandboxCandidatesPath = "$RuntimeRoot/sandbox_candidates.json"
  $AdmittedBoundedReusePath = "$RuntimeRoot/admitted_bounded_reuse.json"
  $GenericBridgeRuntimeCheckPath = "$RuntimeRoot/generic_bridge_runtime_check.json"
  $NewbornReflexCorePath = "$RuntimeRoot/newborn_reflex_core.json"
  $HeartbeatPath = "$RuntimeRoot/heartbeat_0001.json"
  $Step001ActionSelectionPath = "$RuntimeRoot/step_001/action_selection.json"
  $Step001ActionExecutionResultPath = "$RuntimeRoot/step_001/action_execution_result.json"
  $Step001ValidationResultPath = "$RuntimeRoot/step_001/validation_result.json"
  $Step001MemoryEventPath = "$RuntimeRoot/step_001/memory_event.json"
  $Step001NextActionDecisionPath = "$RuntimeRoot/step_001/next_action_decision.json"
  $Step002ActionSelectionPath = "$RuntimeRoot/step_002/action_selection.json"
  $Step002ActionExecutionResultPath = "$RuntimeRoot/step_002/action_execution_result.json"
  $Step002ValidationResultPath = "$RuntimeRoot/step_002/validation_result.json"
  $Step002MemoryEventPath = "$RuntimeRoot/step_002/memory_event.json"
  $TeacherChannelContractPath = "$RuntimeRoot/teacher_channel_contract.json"
  $TeacherInboxReadmePath = "$RuntimeRoot/teacher_inbox/README.json"
  $TeacherOutboxReadmePath = "$RuntimeRoot/teacher_outbox/README.json"
  $BlockerQueueReadmePath = "$RuntimeRoot/blocker_queue/README.json"
  $HelpRequestContractPath = "$RuntimeRoot/help_request_contract.json"
  $LiveSessionSkeletonPath = "$RuntimeRoot/live_session_skeleton.json"
  $ObserverSnapshotContractPath = "$RuntimeRoot/observer_snapshot_contract.json"
  $StopPolicyPath = "$RuntimeRoot/stop_policy.json"
  $SessionSummaryPath = "$RuntimeRoot/session_summary.json"

  $RuntimeOutputs = @(
    $SessionBootPath,
    $Phase158BridgeReadPath,
    $SelfMapSnapshotPath,
    $CapabilityInventoryPath,
    $ProvenCapabilitiesPath,
    $SandboxCandidatesPath,
    $AdmittedBoundedReusePath,
    $GenericBridgeRuntimeCheckPath,
    $NewbornReflexCorePath,
    $HeartbeatPath,
    $Step001ActionSelectionPath,
    $Step001ActionExecutionResultPath,
    $Step001ValidationResultPath,
    $Step001MemoryEventPath,
    $Step001NextActionDecisionPath,
    $Step002ActionSelectionPath,
    $Step002ActionExecutionResultPath,
    $Step002ValidationResultPath,
    $Step002MemoryEventPath,
    $TeacherChannelContractPath,
    $TeacherInboxReadmePath,
    $TeacherOutboxReadmePath,
    $BlockerQueueReadmePath,
    $HelpRequestContractPath,
    $LiveSessionSkeletonPath,
    $ObserverSnapshotContractPath,
    $StopPolicyPath,
    $SessionSummaryPath,
    $ResultPath,
    $ReportPath,
    $ProofPath
  )
  $AllowedExact = @($RouteAlignmentPath, $ModulePath, $ValidatorPath) + $RuntimeOutputs

  $RepoRootParameter = $RepoRoot
  $RepoRoot = $script:Phase159ValidatorResolvedRepoRoot
  if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = Resolve-Phase159ValidatorScriptRepoRoot
  }
  $RepoRoot = Normalize-Phase159ValidatorFullPath -Path $RepoRoot
  Push-Location $RepoRoot
  $Pushed = $true
  Write-Host "PHASE159_VALIDATE_RESOLVED_REPO_ROOT=$RepoRoot"
  if ($RepoRootParameter -ne "." -and (Normalize-Phase159ValidatorFullPath -Path $RepoRootParameter) -ne $RepoRoot) {
    Write-Host "PHASE159_VALIDATE_REPO_ROOT_PARAMETER_IGNORED=$RepoRootParameter"
  }

  foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase159ValidatorPath -RepoRoot $RepoRoot -Path $identityFile))) {
      throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
    }
  }

  $Branch = (git branch --show-current).Trim()
  if ($Branch -eq "main") {
    throw "PHASE159_VALIDATE_MAIN_BRANCH_FORBIDDEN"
  }
  Assert-Phase159ValidatorEquals -Actual $Branch -Expected "phase110-idempotent-autonomy-trial-runtime" -Name "current_branch"
  $Head = (git rev-parse --short HEAD).Trim()
  Assert-Phase159ValidatorEquals -Actual $Head -Expected "fc7b49a" -Name "current_head"
  $RemoteHead = Get-Phase159ValidatorRemoteHead -ExpectedBranch "phase110-idempotent-autonomy-trial-runtime"
  Assert-Phase159ValidatorEquals -Actual $RemoteHead -Expected "fc7b49a" -Name "remote_head"
  $GitTopLevel = Normalize-Phase159ValidatorFullPath -Path (git rev-parse --show-toplevel).Trim()
  Assert-Phase159ValidatorEquals -Actual $GitTopLevel -Expected $RepoRoot -Name "git_top_level"

  $RequiredPaths = @($RouteAlignmentPath, $ModulePath, $ValidatorPath, $QueuePath) + $PhaseProofPaths + $Phase158BridgePaths + $RuntimeOutputs
  foreach ($requiredPath in $RequiredPaths) {
    if (-not (Test-Path -LiteralPath (Resolve-Phase159ValidatorPath -RepoRoot $RepoRoot -Path $requiredPath))) {
      throw "PHASE159_VALIDATE_MISSING_REQUIRED_PATH=$requiredPath"
    }
  }

  $StatusLines = @(git status --short --untracked-files=all)
  foreach ($line in $StatusLines) {
    $path = Get-Phase159StatusPath -StatusLine $line
    if (-not ($AllowedExact -contains $path)) {
      throw "PHASE159_VALIDATE_CHANGE_OUTSIDE_ALLOWED_SCOPE=$line"
    }
  }

  $ProtectedStatus = @(git status --short --untracked-files=all -- `
    orchestrator/run.ps1 `
    TASK_QUEUE.json `
    GENESIS_STATE.json `
    CAPABILITY_ROADMAP.json `
    packs/registry.json `
    capability_shelf `
    living_learning_environment/body `
    living_learning_environment/self_growth_runtime `
    route_locks `
    generated_agents `
    applied_agents `
    .github/workflows `
    package.json `
    package-lock.json `
    pnpm-lock.yaml `
    yarn.lock `
    requirements.txt `
    pyproject.toml `
    poetry.lock 2>$null)
  if ($ProtectedStatus.Count -gt 0) {
    throw "PHASE159_VALIDATE_PROTECTED_SCOPE_CHANGED=$($ProtectedStatus -join '; ')"
  }

  foreach ($phaseProofPath in $PhaseProofPaths) {
    $PhaseProof = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $phaseProofPath
    Assert-Phase159ValidatorEquals -Actual $PhaseProof.status -Expected "PASS" -Name "$phaseProofPath:status"
    Assert-Phase159ValidatorEquals -Actual $PhaseProof.queue_after -Expected "NONE" -Name "$phaseProofPath:queue_after"
    Assert-Phase159ValidatorFalse -Actual $PhaseProof.codex_needed_for_next_step -Name "$phaseProofPath:codex_needed_for_next_step"
  }

  $Phase158Proof = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $Phase158ProofPath
  Assert-Phase159ValidatorEquals -Actual $Phase158Proof.step_id -Expected $Phase158StepId -Name "phase158_step_id"
  Assert-Phase159ValidatorEquals -Actual $Phase158Proof.next_allowed_step -Expected $StepId -Name "phase158_next_allowed_step"
  Assert-Phase159ValidatorTrue -Actual $Phase158Proof.generic_execution_bridge_proven -Name "phase158_generic_execution_bridge_proven"
  Assert-Phase159ValidatorTrue -Actual $Phase158Proof.generic_spec_sandbox_execution_result_created -Name "phase158_generic_spec_sandbox_execution_result_created"
  Assert-Phase159ValidatorTrue -Actual $Phase158Proof.generic_spec_execution_validated -Name "phase158_generic_spec_execution_validated"
  Assert-Phase159ValidatorFalse -Actual $Phase158Proof.phase_specific_entrypoint_required -Name "phase158_phase_specific_entrypoint_required"
  Assert-Phase159ValidatorFalse -Actual $Phase158Proof.codex_required_for_phase159_entrypoint -Name "phase158_codex_required_for_phase159_entrypoint"

  $GenericRequest = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $Phase158BridgePaths[0]
  $GenericAdmission = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $Phase158BridgePaths[1]
  $GenericResult = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $Phase158BridgePaths[2]
  $GenericValidation = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $Phase158BridgePaths[3]
  foreach ($BridgeArtifact in @($GenericRequest, $GenericAdmission, $GenericResult, $GenericValidation)) {
    Assert-Phase159ValidatorEquals -Actual $BridgeArtifact.status -Expected "PASS" -Name "phase158_bridge_status"
    Assert-Phase159ValidatorEquals -Actual $BridgeArtifact.next_allowed_step -Expected $StepId -Name "phase158_bridge_next_allowed_step"
    Assert-Phase159ValidatorFalse -Actual $BridgeArtifact.phase_specific_entrypoint_required -Name "phase158_bridge_phase_specific"
    Assert-Phase159ValidatorFalse -Actual $BridgeArtifact.codex_required_for_phase159_entrypoint -Name "phase158_bridge_codex_required"
  }
  Assert-Phase159ValidatorTrue -Actual $GenericAdmission.admitted_for_generic_sandbox_execution -Name "phase158_admitted_for_generic_sandbox_execution"
  Assert-Phase159ValidatorTrue -Actual $GenericResult.generic_executor_path_used -Name "phase158_generic_executor_path_used"
  Assert-Phase159ValidatorTrue -Actual $GenericValidation.generic_execution_bridge_proven -Name "phase158_validation_generic_execution_bridge_proven"

  $SessionBoot = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $SessionBootPath
  Assert-Phase159ValidatorEquals -Actual $SessionBoot.repo_identity_gate_result -Expected "PASS" -Name "session_boot_repo_identity_gate_result"
  Assert-Phase159ValidatorEquals -Actual $SessionBoot.resolved_repo_root -Expected $RepoRoot -Name "session_boot_resolved_repo_root"
  Assert-Phase159ValidatorEquals -Actual $SessionBoot.git_top_level -Expected $GitTopLevel -Name "session_boot_git_top_level"
  Assert-Phase159ValidatorEquals -Actual $SessionBoot.head -Expected $Head -Name "session_boot_head"
  Assert-Phase159ValidatorEquals -Actual $SessionBoot.local_head -Expected $Head -Name "session_boot_local_head"
  Assert-Phase159ValidatorEquals -Actual $SessionBoot.remote_head -Expected $RemoteHead -Name "session_boot_remote_head"
  Assert-Phase159ValidatorEquals -Actual $SessionBoot.queue_active_task_id -Expected "NONE" -Name "session_boot_queue"
  Assert-Phase159ValidatorFalse -Actual $SessionBoot.live_daemon_started -Name "session_boot_live_daemon_started"

  $BridgeRead = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $Phase158BridgeReadPath
  Assert-Phase159ValidatorTrue -Actual $BridgeRead.phase158_verified -Name "bridge_read_phase158_verified"
  Assert-Phase159ValidatorTrue -Actual $BridgeRead.generic_execution_bridge_proven -Name "bridge_read_generic_execution_bridge_proven"
  Assert-Phase159ValidatorFalse -Actual $BridgeRead.codex_required_for_phase159_entrypoint -Name "bridge_read_codex_required"

  $SelfMap = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $SelfMapSnapshotPath
  Assert-Phase159ValidatorTrue -Actual $SelfMap.self_map_snapshot_created -Name "self_map_snapshot_created"
  Assert-Phase159ValidatorEquals -Actual $SelfMap.source_proof_count -Expected 7 -Name "self_map_source_proof_count"

  $CapabilityInventory = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $CapabilityInventoryPath
  Assert-Phase159ValidatorTrue -Actual $CapabilityInventory.capability_inventory_created -Name "capability_inventory_created"
  Assert-Phase159ValidatorEquals -Actual $CapabilityInventory.capability_count -Expected 7 -Name "capability_inventory_count"

  $ProvenCapabilities = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $ProvenCapabilitiesPath
  Assert-Phase159ValidatorEquals -Actual $ProvenCapabilities.proven_capability_count -Expected 7 -Name "proven_capability_count"

  $SandboxCandidates = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $SandboxCandidatesPath
  Assert-Phase159ValidatorEquals -Actual $SandboxCandidates.sandbox_candidate_count -Expected 3 -Name "sandbox_candidate_count"
  Assert-Phase159ValidatorEquals -Actual $SandboxCandidates.sandbox_candidate_decision -Expected "KEEP_AS_VALIDATED_SANDBOX_CANDIDATES" -Name "sandbox_candidate_decision"
  Assert-Phase159ValidatorFalse -Actual $SandboxCandidates.skill_candidates_promoted -Name "sandbox_candidates_promoted"
  Assert-Phase159ValidatorFalse -Actual $SandboxCandidates.accepted_capability_created -Name "sandbox_candidates_accepted_capability_created"

  $AdmittedReuse = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $AdmittedBoundedReusePath
  Assert-Phase159ValidatorEquals -Actual $AdmittedReuse.reuse_decision -Expected "ADMIT_PHASE156_CANDIDATES_FOR_BOUNDED_SANDBOX_REUSE" -Name "admitted_reuse_decision"
  Assert-Phase159ValidatorEquals -Actual $AdmittedReuse.allowed_scope -Expected "sandbox_only" -Name "admitted_reuse_scope"
  Assert-Phase159ValidatorTrue -Actual $AdmittedReuse.admitted_for_bounded_reuse -Name "admitted_reuse_flag"

  $BridgeRuntimeCheck = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $GenericBridgeRuntimeCheckPath
  Assert-Phase159ValidatorTrue -Actual $BridgeRuntimeCheck.phase158_verified -Name "generic_bridge_runtime_phase158_verified"
  Assert-Phase159ValidatorTrue -Actual $BridgeRuntimeCheck.generic_execution_bridge_proven -Name "generic_bridge_runtime_bridge_proven"
  Assert-Phase159ValidatorFalse -Actual $BridgeRuntimeCheck.phase_specific_entrypoint_required -Name "generic_bridge_runtime_phase_specific"
  Assert-Phase159ValidatorFalse -Actual $BridgeRuntimeCheck.live_daemon_started -Name "generic_bridge_runtime_live_daemon_started"

  $Core = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $NewbornReflexCorePath
  foreach ($flag in @("heartbeat_reflex", "self_map_read_reflex", "action_selection_reflex", "sandbox_execution_reflex", "validation_reflex", "memory_event_reflex", "next_action_decision_reflex", "help_request_reflex", "teacher_inbox_reflex", "safe_stop_reflex")) {
    Assert-Phase159ValidatorTrue -Actual $Core.$flag -Name "newborn_reflex_core_$flag"
  }
  Assert-Phase159ValidatorFalse -Actual $Core.live_daemon_started -Name "newborn_reflex_core_live_daemon_started"

  $Heartbeat = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $HeartbeatPath
  Assert-Phase159ValidatorTrue -Actual $Heartbeat.heartbeat_reflex_proven -Name "heartbeat_reflex_proven"
  Assert-Phase159ValidatorFalse -Actual $Heartbeat.live_daemon_started -Name "heartbeat_live_daemon_started"

  $Step001Selection = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $Step001ActionSelectionPath
  Assert-Phase159ValidatorEquals -Actual $Step001Selection.selected_action -Expected "REFRESH_CAPABILITY_INVENTORY_FROM_PROOFS" -Name "step001_selected_action"

  $Step001Execution = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $Step001ActionExecutionResultPath
  Assert-Phase159ValidatorEquals -Actual $Step001Execution.status -Expected "PASS" -Name "step001_execution_status"
  Assert-Phase159ValidatorTrue -Actual $Step001Execution.capability_inventory_created -Name "step001_capability_inventory_created"
  Assert-Phase159ValidatorTrue -Actual $Step001Execution.self_map_snapshot_created -Name "step001_self_map_snapshot_created"
  Assert-Phase159ValidatorFlagsFalse -Artifact $Step001Execution -Flags @("accepted_state_mutated", "accepted_memory_mutated", "accepted_self_model_mutated", "capability_shelf_mutated", "body_pack_mutated", "external_fetch_performed", "dependency_install_performed", "arbitrary_code_execution_used", "external_agents_created") -Name "step001_execution"

  $Step001Validation = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $Step001ValidationResultPath
  Assert-Phase159ValidatorEquals -Actual $Step001Validation.status -Expected "PASS" -Name "step001_validation_status_file"
  Assert-Phase159ValidatorEquals -Actual $Step001Validation.validation_status -Expected "PASS" -Name "step001_validation_status"
  Assert-Phase159ValidatorEquals -Actual $Step001Validation.next_action -Expected "PREPARE_LIVE_SESSION_CHANNELS" -Name "step001_validation_next_action"

  $Step001Memory = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $Step001MemoryEventPath
  Assert-Phase159ValidatorEquals -Actual $Step001Memory.status -Expected "PASS" -Name "step001_memory_status"
  Assert-Phase159ValidatorFalse -Actual $Step001Memory.accepted_memory_mutated -Name "step001_memory_accepted_memory_mutated"

  $Step001NextAction = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $Step001NextActionDecisionPath
  Assert-Phase159ValidatorEquals -Actual $Step001NextAction.status -Expected "PASS" -Name "step001_next_action_status"
  Assert-Phase159ValidatorEquals -Actual $Step001NextAction.next_action -Expected "PREPARE_LIVE_SESSION_CHANNELS" -Name "step001_next_action"

  $Step002Selection = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $Step002ActionSelectionPath
  Assert-Phase159ValidatorEquals -Actual $Step002Selection.status -Expected "PASS" -Name "step002_selection_status"
  Assert-Phase159ValidatorEquals -Actual $Step002Selection.selected_action -Expected $Step001NextAction.next_action -Name "step002_derives_from_step001_next_action"
  Assert-Phase159ValidatorTrue -Actual $Step002Selection.started_from_step_001_next_action -Name "step002_started_from_step001_next_action"

  $TeacherChannel = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $TeacherChannelContractPath
  Assert-Phase159ValidatorEquals -Actual $TeacherChannel.channel_type -Expected "file_based" -Name "teacher_channel_type"
  Assert-Phase159ValidatorEquals -Actual $TeacherChannel.execution_scope -Expected "sandbox_only" -Name "teacher_channel_scope"
  Assert-Phase159ValidatorFalse -Actual $TeacherChannel.live_daemon_started -Name "teacher_channel_live_daemon_started"

  $TeacherInbox = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $TeacherInboxReadmePath
  $TeacherOutbox = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $TeacherOutboxReadmePath
  $BlockerQueue = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $BlockerQueueReadmePath
  Assert-Phase159ValidatorEquals -Actual $TeacherInbox.status -Expected "PASS" -Name "teacher_inbox_status"
  Assert-Phase159ValidatorEquals -Actual $TeacherOutbox.status -Expected "PASS" -Name "teacher_outbox_status"
  Assert-Phase159ValidatorEquals -Actual $BlockerQueue.status -Expected "PASS" -Name "blocker_queue_status"

  $HelpRequest = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $HelpRequestContractPath
  Assert-Phase159ValidatorEquals -Actual $HelpRequest.channel_type -Expected "file_based" -Name "help_request_channel_type"
  Assert-Phase159ValidatorTrue -Actual $HelpRequest.help_request_reflex_prepared -Name "help_request_reflex_prepared"
  Assert-Phase159ValidatorFalse -Actual $HelpRequest.live_daemon_started -Name "help_request_live_daemon_started"

  $Step002Execution = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $Step002ActionExecutionResultPath
  Assert-Phase159ValidatorEquals -Actual $Step002Execution.status -Expected "PASS" -Name "step002_execution_status"
  Assert-Phase159ValidatorEquals -Actual $Step002Execution.selected_action -Expected "PREPARE_LIVE_SESSION_CHANNELS" -Name "step002_execution_selected_action"
  Assert-Phase159ValidatorTrue -Actual $Step002Execution.started_from_step_001_next_action -Name "step002_execution_started_from_step001"
  Assert-Phase159ValidatorTrue -Actual $Step002Execution.teacher_channels_prepared -Name "step002_teacher_channels_prepared"
  Assert-Phase159ValidatorTrue -Actual $Step002Execution.blocker_queue_prepared -Name "step002_blocker_queue_prepared"
  Assert-Phase159ValidatorTrue -Actual $Step002Execution.help_request_contract_created -Name "step002_help_request_contract_created"
  Assert-Phase159ValidatorFalse -Actual $Step002Execution.live_daemon_started -Name "step002_execution_live_daemon_started"
  Assert-Phase159ValidatorFlagsFalse -Artifact $Step002Execution -Flags @("accepted_state_mutated", "accepted_memory_mutated", "accepted_self_model_mutated", "capability_shelf_mutated", "body_pack_mutated", "external_fetch_performed", "dependency_install_performed", "arbitrary_code_execution_used", "external_agents_created") -Name "step002_execution"

  $Step002Validation = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $Step002ValidationResultPath
  Assert-Phase159ValidatorEquals -Actual $Step002Validation.status -Expected "PASS" -Name "step002_validation_status_file"
  Assert-Phase159ValidatorEquals -Actual $Step002Validation.validation_status -Expected "PASS" -Name "step002_validation_status"
  Assert-Phase159ValidatorTrue -Actual $Step002Validation.started_from_step_001_next_action -Name "step002_validation_started_from_step001"
  Assert-Phase159ValidatorFalse -Actual $Step002Validation.live_daemon_started -Name "step002_validation_live_daemon_started"

  $Step002Memory = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $Step002MemoryEventPath
  Assert-Phase159ValidatorEquals -Actual $Step002Memory.status -Expected "PASS" -Name "step002_memory_status"
  Assert-Phase159ValidatorFalse -Actual $Step002Memory.accepted_memory_mutated -Name "step002_memory_accepted_memory_mutated"
  Assert-Phase159ValidatorEquals -Actual $Step002Memory.next_action -Expected "PREPARE_LIVE_GROWTH_DAEMON_BOOTSTRAP" -Name "step002_memory_next_action"

  $LiveSessionSkeleton = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $LiveSessionSkeletonPath
  Assert-Phase159ValidatorTrue -Actual $LiveSessionSkeleton.daemon_mode_prepared -Name "live_session_daemon_mode_prepared"
  Assert-Phase159ValidatorTrue -Actual $LiveSessionSkeleton.terminal_1_builder_loop -Name "live_session_terminal_1_builder_loop"
  Assert-Phase159ValidatorTrue -Actual $LiveSessionSkeleton.terminal_2_observer_loop -Name "live_session_terminal_2_observer_loop"
  Assert-Phase159ValidatorEquals -Actual $LiveSessionSkeleton.heartbeat_interval_seconds -Expected 30 -Name "live_session_heartbeat_interval"
  Assert-Phase159ValidatorEquals -Actual $LiveSessionSkeleton.tick_interval_seconds -Expected 30 -Name "live_session_tick_interval"
  Assert-Phase159ValidatorTrue -Actual $LiveSessionSkeleton.stop_flag_supported -Name "live_session_stop_flag_supported"
  Assert-Phase159ValidatorTrue -Actual $LiveSessionSkeleton.teacher_inbox_supported -Name "live_session_teacher_inbox_supported"
  Assert-Phase159ValidatorTrue -Actual $LiveSessionSkeleton.teacher_outbox_supported -Name "live_session_teacher_outbox_supported"
  Assert-Phase159ValidatorTrue -Actual $LiveSessionSkeleton.blocker_queue_supported -Name "live_session_blocker_queue_supported"
  Assert-Phase159ValidatorFalse -Actual $LiveSessionSkeleton.live_daemon_started -Name "live_session_live_daemon_started"

  $ObserverSnapshot = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $ObserverSnapshotContractPath
  Assert-Phase159ValidatorEquals -Actual $ObserverSnapshot.execution_scope -Expected "sandbox_only" -Name "observer_snapshot_scope"
  Assert-Phase159ValidatorFalse -Actual $ObserverSnapshot.live_daemon_started -Name "observer_snapshot_live_daemon_started"

  $StopPolicy = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $StopPolicyPath
  Assert-Phase159ValidatorTrue -Actual $StopPolicy.safe_stop -Name "stop_policy_safe_stop"
  Assert-Phase159ValidatorTrue -Actual $StopPolicy.stop_flag_supported -Name "stop_policy_stop_flag_supported"
  Assert-Phase159ValidatorFalse -Actual $StopPolicy.live_daemon_started -Name "stop_policy_live_daemon_started"

  $SessionSummary = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $SessionSummaryPath
  Assert-Phase159ValidatorEquals -Actual $SessionSummary.status -Expected "PASS" -Name "session_summary_status"
  Assert-Phase159ValidatorTrue -Actual $SessionSummary.two_step_newborn_reflex_proven -Name "session_summary_two_step"
  Assert-Phase159ValidatorFalse -Actual $SessionSummary.live_daemon_started -Name "session_summary_live_daemon_started"

  $Result = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $ResultPath
  $Report = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $ReportPath
  $Proof = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $ProofPath
  Assert-Phase159ProofFields -Artifact $Result -Name "result"
  Assert-Phase159ProofFields -Artifact $Proof -Name "proof"
  Assert-Phase159ValidatorEquals -Actual $Proof.resolved_repo_root -Expected $RepoRoot -Name "proof_resolved_repo_root"
  Assert-Phase159ValidatorEquals -Actual $Proof.local_head -Expected $Head -Name "proof_local_head"
  Assert-Phase159ValidatorEquals -Actual $Proof.remote_head -Expected $RemoteHead -Name "proof_remote_head"

  Assert-Phase159ValidatorEquals -Actual $Report.status -Expected "PASS" -Name "report_status"
  Assert-Phase159ValidatorEquals -Actual $Report.repo_identity_gate_result -Expected "PASS" -Name "report_repo_identity_gate_result"
  Assert-Phase159ValidatorEquals -Actual $Report.root_cause -Expected "child is not prepared for live daemon mode" -Name "report_root_cause"
  Assert-Phase159ValidatorEquals -Actual $Report.exact_wrong_root_source_found -Expected "RepoRoot defaulted to '.', then Resolve-Phase159Path and Push-Location used the caller working directory; callers in a stale clone made git rev-parse read that clone." -Name "report_wrong_root_source"
  Assert-Phase159ValidatorEquals -Actual $Report.resolved_repo_root -Expected $RepoRoot -Name "report_resolved_repo_root"
  Assert-Phase159ValidatorEquals -Actual $Report.local_head -Expected $Head -Name "report_local_head"
  Assert-Phase159ValidatorEquals -Actual $Report.remote_head -Expected $RemoteHead -Name "report_remote_head"
  Assert-Phase159ValidatorEquals -Actual $Report.module_path -Expected $ModulePath -Name "report_module_path"
  Assert-Phase159ValidatorEquals -Actual $Report.validator_path -Expected $ValidatorPath -Name "report_validator_path"
  Assert-Phase159ValidatorEquals -Actual $Report.expected_run_command -Expected ".\modules\invoke_builder_runs_generic_self_written_spec_execution_bridge_001.ps1" -Name "report_run_command"
  Assert-Phase159ValidatorEquals -Actual $Report.expected_validator_command -Expected ".\validators\validate_phase159_builder_runs_generic_self_written_spec_execution_bridge_v1.ps1 -RepoRoot ." -Name "report_validator_command"
  foreach ($runtimePath in $RuntimeOutputs) {
    Assert-Phase159ValidatorContains -Values @($Report.runtime_outputs_created_by_module) -Expected $runtimePath -Name "report_runtime_outputs"
    Assert-Phase159ValidatorContains -Values @($Proof.runtime_outputs_created_by_module) -Expected $runtimePath -Name "proof_runtime_outputs"
  }

  $Queue = Read-Phase159ValidatorJson -RepoRoot $RepoRoot -Path $QueuePath
  Assert-Phase159ValidatorEquals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

  Write-Host "PHASE159_BUILDER_RUNS_GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_VALIDATE_RESULT=PASS"
  Write-Host "RESOLVED_REPO_ROOT=$RepoRoot"
  Write-Host "LOCAL_HEAD=$Head"
  Write-Host "REMOTE_HEAD=$RemoteHead"
  Write-Host "PHASE158_VERIFIED=True"
  Write-Host "GENERIC_EXECUTION_BRIDGE_PROVEN=True"
  Write-Host "CODEX_REQUIRED_FOR_PHASE159_ENTRYPOINT=False"
  Write-Host "CAPABILITY_INVENTORY_CREATED=True"
  Write-Host "SELF_MAP_SNAPSHOT_CREATED=True"
  Write-Host "NEWBORN_REFLEX_CORE_CREATED=True"
  Write-Host "HEARTBEAT_REFLEX_PROVEN=True"
  Write-Host "TWO_STEP_NEWBORN_REFLEX_PROVEN=True"
  Write-Host "STEP_001_SELECTED_ACTION=REFRESH_CAPABILITY_INVENTORY_FROM_PROOFS"
  Write-Host "STEP_001_VALIDATION_STATUS=PASS"
  Write-Host "STEP_002_STARTED_FROM_STEP_001_NEXT_ACTION=True"
  Write-Host "STEP_002_SELECTED_ACTION=PREPARE_LIVE_SESSION_CHANNELS"
  Write-Host "STEP_002_VALIDATION_STATUS=PASS"
  Write-Host "TEACHER_CHANNELS_PREPARED=True"
  Write-Host "HELP_REQUEST_REFLEX_PREPARED=True"
  Write-Host "LIVE_SESSION_SKELETON_CREATED=True"
  Write-Host "DAEMON_MODE_PREPARED=True"
  Write-Host "LIVE_DAEMON_STARTED=False"
  Write-Host "QUEUE_AFTER=NONE"
  Write-Host "CODEX_NEEDED_FOR_NEXT_STEP=False"
  Write-Host "NEXT_ALLOWED_STEP=PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_V1"
} catch {
  Write-Host "PHASE159_BUILDER_RUNS_GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_VALIDATE_RESULT=FAIL"
  Write-Host "PHASE159_VALIDATE_ERROR=$($_.Exception.Message)"
  throw
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
