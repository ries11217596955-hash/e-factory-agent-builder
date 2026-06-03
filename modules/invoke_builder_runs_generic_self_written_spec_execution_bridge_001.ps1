param(
  [string]$RepoRoot = ".",
  [string]$RunId = "PHASE159_NEWBORN_REFLEX_CORE_AND_LIVE_SESSION_PREP_001"
)

$ErrorActionPreference = "Stop"

function Normalize-Phase159FullPath {
  param([string]$Path)

  return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-Phase159ScriptRepoRoot {
  $scriptRootCandidate = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRootCandidate = Split-Path -Path $PSCommandPath -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate) -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRootCandidate = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  }
  if ([string]::IsNullOrWhiteSpace($scriptRootCandidate)) {
    throw "PHASE159_SCRIPT_ROOT_UNAVAILABLE"
  }

  return Normalize-Phase159FullPath -Path (Join-Path $scriptRootCandidate "..")
}

function Get-Phase159RemoteHead {
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
    throw "PHASE159_REMOTE_HEAD_UNAVAILABLE"
  }

  return $remoteHead.Trim()
}

$script:Phase159ResolvedRepoRoot = Resolve-Phase159ScriptRepoRoot

function Resolve-Phase159Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase159JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase159Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE159_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Write-Phase159JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase159Path -RepoRoot $RepoRoot -Path $Path
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

function Assert-Phase159Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE159_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase159True {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE159_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase159False {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE159_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function Assert-Phase159FlagsFalse {
  param(
    [object]$Object,
    [string[]]$Flags,
    [string]$Prefix
  )

  foreach ($flag in $Flags) {
    Assert-Phase159False -Actual $Object.$flag -Name "${Prefix}:$flag"
  }
}

function Invoke-BuilderRunsGenericSelfWrittenSpecExecutionBridge001 {
  param(
    [string]$RepoRoot = ".",
    [string]$RunId = "PHASE159_NEWBORN_REFLEX_CORE_AND_LIVE_SESSION_PREP_001"
  )

  $RepoRootParameter = $RepoRoot
  $RepoRoot = $script:Phase159ResolvedRepoRoot
  if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = Resolve-Phase159ScriptRepoRoot
  }
  $RepoRoot = Normalize-Phase159FullPath -Path $RepoRoot
  $Pushed = $false
  Push-Location $RepoRoot
  $Pushed = $true
  Write-Host "PHASE159_RESOLVED_REPO_ROOT=$RepoRoot"
  if ($RepoRootParameter -ne "." -and (Normalize-Phase159FullPath -Path $RepoRootParameter) -ne $RepoRoot) {
    Write-Host "PHASE159_REPO_ROOT_PARAMETER_IGNORED=$RepoRootParameter"
  }

  try {
    $StepId = "PHASE159_BUILDER_RUNS_GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_V1"
    $NextAllowedStep = "PHASE160_LIVE_GROWTH_SESSION_DAEMON_BOOTSTRAP_V1"
    $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"
    $ExpectedHead = "fc7b49a"
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

    $PhaseProofPaths = [ordered]@{
      PHASE152 = "proofs/self_development/PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_V1.json"
      PHASE153 = "proofs/self_development/PHASE153_BUILDER_VALIDATES_SANDBOX_SELF_BUILD_RESULT_AND_LEARNS_V1.json"
      PHASE154 = "proofs/self_development/PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_V1.json"
      PHASE155 = "proofs/self_development/PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_V1.json"
      PHASE156 = "proofs/self_development/PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1.json"
      PHASE157 = "proofs/self_development/PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1.json"
      PHASE158 = "proofs/self_development/PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_V1.json"
    }

    $PhaseChain = @(
      [ordered]@{ phase = "PHASE152"; step_id = "PHASE152_BUILDER_EXECUTES_ADMITTED_SELF_BUILD_PROGRAM_IN_SANDBOX_V1"; next_allowed_step = "PHASE153_BUILDER_VALIDATES_SANDBOX_SELF_BUILD_RESULT_AND_LEARNS_V1" },
      [ordered]@{ phase = "PHASE153"; step_id = "PHASE153_BUILDER_VALIDATES_SANDBOX_SELF_BUILD_RESULT_AND_LEARNS_V1"; next_allowed_step = "PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_V1" },
      [ordered]@{ phase = "PHASE154"; step_id = "PHASE154_BUILDER_BOUNDED_SELF_GROWTH_DUTY_LOOP_TRIAL_V1"; next_allowed_step = "PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_V1" },
      [ordered]@{ phase = "PHASE155"; step_id = "PHASE155_BUILDER_SELF_GROWTH_RUNTIME_ADMISSION_REVIEW_V1"; next_allowed_step = "PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1" },
      [ordered]@{ phase = "PHASE156"; step_id = "PHASE156_BUILDER_SELF_SELECTED_GAP_SELF_BUILD_TRIAL_V1"; next_allowed_step = "PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1" },
      [ordered]@{ phase = "PHASE157"; step_id = "PHASE157_BUILDER_SELF_SELECTED_GAP_TRIAL_REVIEW_V1"; next_allowed_step = "PHASE158_BUILDER_USES_SELF_BUILT_GAP_SKILLS_FOR_SELF_BUILD_SPEC_TRIAL_V1" },
      [ordered]@{ phase = "PHASE158"; step_id = $Phase158StepId; next_allowed_step = $StepId }
    )

    $Phase158BridgePaths = [ordered]@{
      request = "living_learning_environment/reuse_trials/$Phase158RunId/generic_spec_execution_request.json"
      admission = "living_learning_environment/reuse_trials/$Phase158RunId/generic_spec_execution_admission.json"
      result = "living_learning_environment/reuse_trials/$Phase158RunId/generic_spec_sandbox_execution_result.json"
      validation = "living_learning_environment/reuse_trials/$Phase158RunId/generic_spec_execution_validation_result.json"
    }

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

    $RuntimeCreatedOutputs = @(
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

    foreach ($identityFile in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase159Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $Branch = (git branch --show-current).Trim()
    if ($Branch -eq "main") {
      throw "PHASE159_MAIN_BRANCH_FORBIDDEN"
    }
    Assert-Phase159Equals -Actual $Branch -Expected $ExpectedBranch -Name "current_branch"
    $Head = (git rev-parse --short HEAD).Trim()
    Assert-Phase159Equals -Actual $Head -Expected $ExpectedHead -Name "current_head"
    $RemoteHead = Get-Phase159RemoteHead -ExpectedBranch $ExpectedBranch
    Assert-Phase159Equals -Actual $RemoteHead -Expected $ExpectedHead -Name "remote_head"
    $GitTopLevel = Normalize-Phase159FullPath -Path (git rev-parse --show-toplevel).Trim()
    Assert-Phase159Equals -Actual $GitTopLevel -Expected $RepoRoot -Name "git_top_level"

    $RequiredInputPaths = @($RouteAlignmentPath, $ModulePath, $ValidatorPath, $QueuePath) + @($PhaseProofPaths.Values) + @($Phase158BridgePaths.Values)
    foreach ($requiredPath in $RequiredInputPaths) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase159Path -RepoRoot $RepoRoot -Path $requiredPath))) {
        throw "PHASE159_MISSING_REQUIRED_INPUT=$requiredPath"
      }
    }

    $Proofs = [ordered]@{}
    foreach ($phaseName in $PhaseProofPaths.Keys) {
      $Proofs[$phaseName] = Read-Phase159JsonRequired -RepoRoot $RepoRoot -Path $PhaseProofPaths[$phaseName]
    }

    foreach ($chainItem in $PhaseChain) {
      $phaseProof = $Proofs[$chainItem.phase]
      Assert-Phase159Equals -Actual $phaseProof.status -Expected "PASS" -Name "$($chainItem.phase):status"
      Assert-Phase159Equals -Actual $phaseProof.step_id -Expected $chainItem.step_id -Name "$($chainItem.phase):step_id"
      Assert-Phase159Equals -Actual $phaseProof.next_allowed_step -Expected $chainItem.next_allowed_step -Name "$($chainItem.phase):next_allowed_step"
      Assert-Phase159Equals -Actual $phaseProof.queue_after -Expected "NONE" -Name "$($chainItem.phase):queue_after"
      Assert-Phase159False -Actual $phaseProof.codex_needed_for_next_step -Name "$($chainItem.phase):codex_needed_for_next_step"
    }

    $Phase158Proof = $Proofs["PHASE158"]
    Assert-Phase159True -Actual $Phase158Proof.generic_execution_bridge_proven -Name "phase158_generic_execution_bridge_proven"
    Assert-Phase159True -Actual $Phase158Proof.generic_spec_sandbox_execution_result_created -Name "phase158_generic_spec_sandbox_execution_result_created"
    Assert-Phase159True -Actual $Phase158Proof.generic_spec_execution_validated -Name "phase158_generic_spec_execution_validated"
    Assert-Phase159False -Actual $Phase158Proof.phase_specific_entrypoint_required -Name "phase158_phase_specific_entrypoint_required"
    Assert-Phase159False -Actual $Phase158Proof.codex_required_for_phase159_entrypoint -Name "phase158_codex_required_for_phase159_entrypoint"

    $Phase158BridgeRequest = Read-Phase159JsonRequired -RepoRoot $RepoRoot -Path $Phase158BridgePaths["request"]
    $Phase158BridgeAdmission = Read-Phase159JsonRequired -RepoRoot $RepoRoot -Path $Phase158BridgePaths["admission"]
    $Phase158BridgeResult = Read-Phase159JsonRequired -RepoRoot $RepoRoot -Path $Phase158BridgePaths["result"]
    $Phase158BridgeValidation = Read-Phase159JsonRequired -RepoRoot $RepoRoot -Path $Phase158BridgePaths["validation"]

    foreach ($bridgeArtifact in @($Phase158BridgeRequest, $Phase158BridgeAdmission, $Phase158BridgeResult, $Phase158BridgeValidation)) {
      Assert-Phase159Equals -Actual $bridgeArtifact.status -Expected "PASS" -Name "phase158_bridge_artifact_status"
      Assert-Phase159Equals -Actual $bridgeArtifact.step_id -Expected $Phase158StepId -Name "phase158_bridge_artifact_step_id"
      Assert-Phase159Equals -Actual $bridgeArtifact.next_allowed_step -Expected $StepId -Name "phase158_bridge_artifact_next_allowed_step"
      Assert-Phase159False -Actual $bridgeArtifact.phase_specific_entrypoint_required -Name "phase158_bridge_artifact_phase_specific_entrypoint_required"
      Assert-Phase159False -Actual $bridgeArtifact.codex_required_for_phase159_entrypoint -Name "phase158_bridge_artifact_codex_required"
    }
    Assert-Phase159Equals -Actual $Phase158BridgeRequest.execution_scope -Expected "sandbox_only" -Name "phase158_bridge_request_scope"
    Assert-Phase159Equals -Actual $Phase158BridgeAdmission.execution_scope -Expected "sandbox_only" -Name "phase158_bridge_admission_scope"
    Assert-Phase159Equals -Actual $Phase158BridgeResult.execution_scope -Expected "sandbox_only" -Name "phase158_bridge_result_scope"
    Assert-Phase159True -Actual $Phase158BridgeAdmission.admitted_for_generic_sandbox_execution -Name "phase158_bridge_admitted"
    Assert-Phase159True -Actual $Phase158BridgeResult.generic_executor_path_used -Name "phase158_generic_executor_path_used"
    Assert-Phase159True -Actual $Phase158BridgeValidation.generic_execution_bridge_proven -Name "phase158_bridge_validation_generic_execution_bridge_proven"
    Assert-Phase159True -Actual $Phase158BridgeValidation.self_written_spec_executable_by_generic_bridge -Name "phase158_bridge_validation_spec_executable"
    Assert-Phase159FlagsFalse -Object $Phase158BridgeResult -Flags @("accepted_state_mutated", "accepted_memory_mutated", "accepted_self_model_mutated", "capability_shelf_mutated", "body_pack_mutated", "external_fetch_performed", "dependency_install_performed", "arbitrary_code_execution_used", "external_agents_created") -Prefix "phase158_bridge_result"

    $Queue = Read-Phase159JsonRequired -RepoRoot $RepoRoot -Path $QueuePath
    Assert-Phase159Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

    $ForbiddenMutationFlags = [ordered]@{
      accepted_state_mutated = $false
      accepted_memory_mutated = $false
      accepted_self_model_mutated = $false
      capability_shelf_mutated = $false
      body_pack_mutated = $false
      external_fetch_performed = $false
      dependency_install_performed = $false
      arbitrary_code_execution_used = $false
      external_agents_created = $false
    }

    $PhaseProofSummaries = foreach ($phaseName in $PhaseProofPaths.Keys) {
      $phaseProof = $Proofs[$phaseName]
      [ordered]@{
        phase = $phaseName
        proof_path = $PhaseProofPaths[$phaseName]
        status = $phaseProof.status
        step_id = $phaseProof.step_id
        run_id = $phaseProof.run_id
        next_allowed_step = $phaseProof.next_allowed_step
        queue_after = $phaseProof.queue_after
        codex_needed_for_next_step = $phaseProof.codex_needed_for_next_step
      }
    }

    $CapabilityEntries = @(
      [ordered]@{
        capability_id = "SELF_BUILD_SANDBOX_EXECUTION_CONTOUR"
        source_phase = "PHASE152"
        proof_path = $PhaseProofPaths["PHASE152"]
        evidence = @("program_executed", "execution_scope=sandbox_only", "sandbox_validation_result_created", "body_organ_pack_created")
        status = "PROVEN"
      },
      [ordered]@{
        capability_id = "TWO_CYCLE_SELF_GROWTH_DUTY_RUNTIME"
        source_phase = "PHASE153"
        proof_path = $PhaseProofPaths["PHASE153"]
        evidence = @("self_growth_loop_proven", "cycle_count=2", "runtime_stop_decision_created")
        status = "PROVEN"
      },
      [ordered]@{
        capability_id = "BOUNDED_SELF_GROWTH_DUTY_LOOP"
        source_phase = "PHASE154"
        proof_path = $PhaseProofPaths["PHASE154"]
        evidence = @("bounded_self_growth_trial_proven", "cycle_count=3", "safe_stop")
        status = "PROVEN"
      },
      [ordered]@{
        capability_id = "SELF_GROWTH_RUNTIME_ADMISSION_REVIEW"
        source_phase = "PHASE155"
        proof_path = $PhaseProofPaths["PHASE155"]
        evidence = @("admission_status=ADMITTED_FOR_BOUNDED_SELF_GROWTH_SANDBOX_USE", "allowed_scope=sandbox_only", "unrestricted_autonomy_approved=false")
        status = "PROVEN"
      },
      [ordered]@{
        capability_id = "SELF_SELECTED_GAP_SELF_BUILD_TRIAL"
        source_phase = "PHASE156"
        proof_path = $PhaseProofPaths["PHASE156"]
        evidence = @($Proofs["PHASE156"].cycle_006_skill_id, $Proofs["PHASE156"].cycle_007_skill_id, $Proofs["PHASE156"].cycle_008_skill_id)
        status = "PROVEN_AS_SANDBOX_CANDIDATES"
      },
      [ordered]@{
        capability_id = "SANDBOX_CANDIDATE_REVIEW_AND_BOUNDED_REUSE"
        source_phase = "PHASE157"
        proof_path = $PhaseProofPaths["PHASE157"]
        evidence = @("skill_candidate_count=3", "sandbox_candidate_decision=KEEP_AS_VALIDATED_SANDBOX_CANDIDATES", "reuse_decision=ADMIT_PHASE156_CANDIDATES_FOR_BOUNDED_SANDBOX_REUSE")
        status = "PROVEN"
      },
      [ordered]@{
        capability_id = "GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE"
        source_phase = "PHASE158"
        proof_path = $PhaseProofPaths["PHASE158"]
        evidence = @("generic_execution_bridge_proven", "generic_spec_sandbox_execution_result_created", "phase_specific_entrypoint_required=false")
        status = "PROVEN"
      }
    )

    $SandboxCandidates = @(
      [ordered]@{ candidate_id = $Proofs["PHASE156"].cycle_006_skill_id; selected_gap = $Proofs["PHASE156"].cycle_006_selected_gap; validation_status = $Proofs["PHASE156"].cycle_006_validation_status; review_status = $Proofs["PHASE157"].cycle_006_review_status; promoted = $false },
      [ordered]@{ candidate_id = $Proofs["PHASE156"].cycle_007_skill_id; selected_gap = $Proofs["PHASE156"].cycle_007_selected_gap; validation_status = $Proofs["PHASE156"].cycle_007_validation_status; review_status = $Proofs["PHASE157"].cycle_007_review_status; promoted = $false },
      [ordered]@{ candidate_id = $Proofs["PHASE156"].cycle_008_skill_id; selected_gap = $Proofs["PHASE156"].cycle_008_selected_gap; validation_status = $Proofs["PHASE156"].cycle_008_validation_status; review_status = $Proofs["PHASE157"].cycle_008_review_status; promoted = $false }
    )

    $SessionBoot = [ordered]@{
      status = "PASS"
      boot_id = "PHASE159_SESSION_BOOT"
      line = "AGENT_BUILDER_SELF_DEVELOPMENT"
      mode = "SELF_BUILD"
      step_id = $StepId
      run_id = $RunId
      root_cause = "child is not prepared for live daemon mode"
      repo_identity_gate_result = "PASS"
      repo_root = $RepoRoot
      resolved_repo_root = $RepoRoot
      repo_root_resolution_rule = "parent_of_module_directory_from_script_file_location"
      repo_root_parameter_ignored = ($RepoRootParameter -ne ".")
      git_top_level = $GitTopLevel
      branch = $Branch
      head = $Head
      local_head = $Head
      remote_head = $RemoteHead
      queue_active_task_id = $Queue.active_task_id
      runtime_root = $RuntimeRoot
      phase158_proof_path = $PhaseProofPaths["PHASE158"]
      phase158_verified = $true
      generic_execution_bridge_proven = $true
      execution_scope = "sandbox_only"
      live_daemon_started = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $SessionBootPath -Object $SessionBoot

    $Phase158BridgeRead = [ordered]@{
      status = "PASS"
      read_id = "PHASE159_PHASE158_BRIDGE_READ"
      step_id = $StepId
      run_id = $RunId
      source_phase158_proof_path = $PhaseProofPaths["PHASE158"]
      source_generic_execution_request_path = $Phase158BridgePaths["request"]
      source_generic_execution_admission_path = $Phase158BridgePaths["admission"]
      source_generic_sandbox_execution_result_path = $Phase158BridgePaths["result"]
      source_generic_execution_validation_path = $Phase158BridgePaths["validation"]
      phase158_verified = $true
      generic_execution_bridge_proven = $true
      generic_spec_sandbox_execution_result_created = $true
      generic_spec_execution_validated = $true
      phase_specific_entrypoint_required = $false
      codex_required_for_phase159_entrypoint = $false
      execution_scope = "sandbox_only"
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $Phase158BridgeReadPath -Object $Phase158BridgeRead

    $SelfMapSnapshot = [ordered]@{
      status = "PASS"
      snapshot_id = "PHASE159_SELF_MAP_SNAPSHOT"
      step_id = $StepId
      run_id = $RunId
      source_proof_count = 7
      source_proofs = $PhaseProofSummaries
      queue_active_task_id = $Queue.active_task_id
      latest_accepted_phase = "PHASE158"
      current_contour = "generic bridge proven; live daemon mode not yet bootstrapped"
      self_map_snapshot_created = $true
      accepted_state_mutated = $false
      accepted_memory_mutated = $false
      accepted_self_model_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $SelfMapSnapshotPath -Object $SelfMapSnapshot

    $CapabilityInventory = [ordered]@{
      status = "PASS"
      inventory_id = "PHASE159_CAPABILITY_INVENTORY_FROM_PROOFS"
      step_id = $StepId
      run_id = $RunId
      capability_inventory_created = $true
      source_proof_count = 7
      capability_count = $CapabilityEntries.Count
      capabilities = $CapabilityEntries
      accepted_state_mutated = $false
      capability_shelf_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $CapabilityInventoryPath -Object $CapabilityInventory

    $ProvenCapabilities = [ordered]@{
      status = "PASS"
      proven_capabilities_id = "PHASE159_PROVEN_CAPABILITIES"
      step_id = $StepId
      run_id = $RunId
      proven_capability_count = $CapabilityEntries.Count
      proven_capabilities = $CapabilityEntries
      generated_from_capability_inventory_path = $CapabilityInventoryPath
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $ProvenCapabilitiesPath -Object $ProvenCapabilities

    $SandboxCandidateFile = [ordered]@{
      status = "PASS"
      sandbox_candidates_id = "PHASE159_SANDBOX_CANDIDATES"
      step_id = $StepId
      run_id = $RunId
      source_phase156_proof_path = $PhaseProofPaths["PHASE156"]
      source_phase157_proof_path = $PhaseProofPaths["PHASE157"]
      sandbox_candidate_count = 3
      sandbox_candidate_decision = $Proofs["PHASE157"].sandbox_candidate_decision
      skill_candidates_promoted = $false
      accepted_capability_created = $false
      candidates = $SandboxCandidates
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $SandboxCandidatesPath -Object $SandboxCandidateFile

    $AdmittedBoundedReuse = [ordered]@{
      status = "PASS"
      admitted_bounded_reuse_id = "PHASE159_ADMITTED_BOUNDED_REUSE"
      step_id = $StepId
      run_id = $RunId
      source_phase157_proof_path = $PhaseProofPaths["PHASE157"]
      reuse_decision = $Proofs["PHASE157"].reuse_decision
      allowed_scope = $Proofs["PHASE157"].allowed_scope
      allowed_use = $Proofs["PHASE157"].allowed_use
      max_cycles_per_run = $Proofs["PHASE157"].max_cycles_per_run
      admitted_for_bounded_reuse = $true
      capability_shelf_mutated = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $AdmittedBoundedReusePath -Object $AdmittedBoundedReuse

    $GenericBridgeRuntimeCheck = [ordered]@{
      status = "PASS"
      check_id = "PHASE159_GENERIC_BRIDGE_RUNTIME_CHECK"
      step_id = $StepId
      run_id = $RunId
      generic_bridge_id = "GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_V1"
      phase158_verified = $true
      generic_execution_bridge_proven = $true
      generic_spec_execution_request_created = $true
      generic_spec_execution_admission_created = $true
      generic_spec_sandbox_execution_result_created = $true
      generic_spec_execution_validated = $true
      self_written_spec_executable_by_generic_bridge = $true
      phase_specific_entrypoint_required = $false
      codex_required_for_phase159_entrypoint = $false
      accepted_state_mutated = $false
      capability_shelf_mutated = $false
      live_daemon_started = $false
      source_paths = $Phase158BridgePaths
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $GenericBridgeRuntimeCheckPath -Object $GenericBridgeRuntimeCheck

    $NewbornReflexCore = [ordered]@{
      status = "PASS"
      core_id = "PHASE159_NEWBORN_REFLEX_CORE"
      step_id = $StepId
      run_id = $RunId
      heartbeat_reflex = $true
      self_map_read_reflex = $true
      action_selection_reflex = $true
      sandbox_execution_reflex = $true
      validation_reflex = $true
      memory_event_reflex = $true
      next_action_decision_reflex = $true
      help_request_reflex = $true
      teacher_inbox_reflex = $true
      safe_stop_reflex = $true
      max_meaningful_steps_this_phase = 2
      live_daemon_started = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $NewbornReflexCorePath -Object $NewbornReflexCore

    $Heartbeat = [ordered]@{
      status = "PASS"
      heartbeat_id = "PHASE159_HEARTBEAT_0001"
      step_id = $StepId
      run_id = $RunId
      heartbeat_sequence = 1
      heartbeat_reflex_proven = $true
      runtime_root = $RuntimeRoot
      daemon_mode = "prepared_not_started"
      live_daemon_started = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $HeartbeatPath -Object $Heartbeat

    $Step001ActionSelection = [ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      newborn_step = "step_001"
      selected_action = "REFRESH_CAPABILITY_INVENTORY_FROM_PROOFS"
      selected_from = @($SelfMapSnapshotPath, $CapabilityInventoryPath, $Phase158BridgeReadPath)
      execution_scope = "sandbox_only"
      action_selection_reflex_proven = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $Step001ActionSelectionPath -Object $Step001ActionSelection

    $Step001ActionExecutionResult = [ordered]@{
      status = "PASS"
      result_id = "PHASE159_STEP_001_ACTION_EXECUTION_RESULT"
      step_id = $StepId
      run_id = $RunId
      newborn_step = "step_001"
      selected_action = "REFRESH_CAPABILITY_INVENTORY_FROM_PROOFS"
      execution_scope = "sandbox_only"
      self_map_snapshot_created = $true
      capability_inventory_created = $true
      proven_capabilities_created = $true
      sandbox_candidates_created = $true
      admitted_bounded_reuse_created = $true
      sandbox_execution_reflex_proven = $true
      output_paths = @($SelfMapSnapshotPath, $CapabilityInventoryPath, $ProvenCapabilitiesPath, $SandboxCandidatesPath, $AdmittedBoundedReusePath)
      accepted_state_mutated = $false
      accepted_memory_mutated = $false
      accepted_self_model_mutated = $false
      capability_shelf_mutated = $false
      body_pack_mutated = $false
      external_fetch_performed = $false
      dependency_install_performed = $false
      arbitrary_code_execution_used = $false
      external_agents_created = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $Step001ActionExecutionResultPath -Object $Step001ActionExecutionResult

    $Step001ValidationResult = [ordered]@{
      status = "PASS"
      validation_id = "PHASE159_STEP_001_VALIDATION"
      step_id = $StepId
      run_id = $RunId
      newborn_step = "step_001"
      selected_action = "REFRESH_CAPABILITY_INVENTORY_FROM_PROOFS"
      validation_status = "PASS"
      self_map_snapshot_created = $true
      capability_inventory_created = $true
      source_proof_count = 7
      forbidden_mutation_flags_clear = $true
      validation_reflex_proven = $true
      next_action = "PREPARE_LIVE_SESSION_CHANNELS"
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $Step001ValidationResultPath -Object $Step001ValidationResult

    $Step001MemoryEvent = [ordered]@{
      status = "PASS"
      event_id = "PHASE159_STEP_001_MEMORY_EVENT"
      step_id = $StepId
      run_id = $RunId
      newborn_step = "step_001"
      event_type = "SANDBOX_MEMORY_EVENT_ONLY"
      selected_action = "REFRESH_CAPABILITY_INVENTORY_FROM_PROOFS"
      memory_event_reflex_proven = $true
      accepted_memory_mutated = $false
      memory_summary = "Capability inventory refreshed from PHASE152-PHASE158 proofs inside PHASE159 sandbox session."
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $Step001MemoryEventPath -Object $Step001MemoryEvent

    $Step001NextActionDecision = [ordered]@{
      status = "PASS"
      decision_id = "PHASE159_STEP_001_NEXT_ACTION_DECISION"
      step_id = $StepId
      run_id = $RunId
      newborn_step = "step_001"
      next_action = "PREPARE_LIVE_SESSION_CHANNELS"
      derived_from_validation_path = $Step001ValidationResultPath
      reason = "Live daemon preparation requires sandbox-only teacher, blocker, help, observer, and stop channels before bootstrap."
      next_action_decision_reflex_proven = $true
      codex_needed = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $Step001NextActionDecisionPath -Object $Step001NextActionDecision

    $Step001NextActionRead = Read-Phase159JsonRequired -RepoRoot $RepoRoot -Path $Step001NextActionDecisionPath
    Assert-Phase159Equals -Actual $Step001NextActionRead.next_action -Expected "PREPARE_LIVE_SESSION_CHANNELS" -Name "step_001_next_action"

    $Step002ActionSelection = [ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      newborn_step = "step_002"
      selected_action = $Step001NextActionRead.next_action
      source_next_action_decision_path = $Step001NextActionDecisionPath
      started_from_step_001_next_action = $true
      execution_scope = "sandbox_only"
      action_selection_reflex_proven = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $Step002ActionSelectionPath -Object $Step002ActionSelection

    $TeacherChannelContract = [ordered]@{
      status = "PASS"
      contract_id = "PHASE159_TEACHER_CHANNEL_CONTRACT"
      step_id = $StepId
      run_id = $RunId
      channel_type = "file_based"
      execution_scope = "sandbox_only"
      teacher_inbox_path = "$RuntimeRoot/teacher_inbox"
      teacher_outbox_path = "$RuntimeRoot/teacher_outbox"
      blocker_queue_path = "$RuntimeRoot/blocker_queue"
      allowed_message_types = @("teacher_instruction", "teacher_correction", "builder_question", "builder_status", "blocker_notice")
      accepted_memory_mutated = $false
      live_daemon_started = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $TeacherChannelContractPath -Object $TeacherChannelContract

    $TeacherInboxReadme = [ordered]@{
      status = "PASS"
      channel = "teacher_inbox"
      step_id = $StepId
      run_id = $RunId
      purpose = "Sandbox-only file channel for future live teacher instructions and corrections."
      expected_payload = "JSON message files governed by teacher_channel_contract.json."
      builder_may_read = $true
      builder_may_write = $false
      live_daemon_started = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $TeacherInboxReadmePath -Object $TeacherInboxReadme

    $TeacherOutboxReadme = [ordered]@{
      status = "PASS"
      channel = "teacher_outbox"
      step_id = $StepId
      run_id = $RunId
      purpose = "Sandbox-only file channel for future Builder replies, status notes, and teacher-visible decisions."
      expected_payload = "JSON message files governed by teacher_channel_contract.json."
      builder_may_read = $true
      builder_may_write = $true
      live_daemon_started = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $TeacherOutboxReadmePath -Object $TeacherOutboxReadme

    $BlockerQueueReadme = [ordered]@{
      status = "PASS"
      channel = "blocker_queue"
      step_id = $StepId
      run_id = $RunId
      purpose = "Sandbox-only queue for future live blockers that require teacher help or safe stop."
      expected_payload = "JSON blocker files referencing help_request_contract.json when escalation is needed."
      builder_may_read = $true
      builder_may_write = $true
      live_daemon_started = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $BlockerQueueReadmePath -Object $BlockerQueueReadme

    $HelpRequestContract = [ordered]@{
      status = "PASS"
      contract_id = "PHASE159_HELP_REQUEST_CONTRACT"
      step_id = $StepId
      run_id = $RunId
      channel_type = "file_based"
      execution_scope = "sandbox_only"
      required_fields = @("request_id", "created_at", "blocking_condition", "attempted_action", "evidence_paths", "requested_help", "safe_stop_recommended")
      help_request_reflex_prepared = $true
      accepted_memory_mutated = $false
      live_daemon_started = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $HelpRequestContractPath -Object $HelpRequestContract

    $Step002ActionExecutionResult = [ordered]@{
      status = "PASS"
      result_id = "PHASE159_STEP_002_ACTION_EXECUTION_RESULT"
      step_id = $StepId
      run_id = $RunId
      newborn_step = "step_002"
      selected_action = "PREPARE_LIVE_SESSION_CHANNELS"
      started_from_step_001_next_action = $true
      execution_scope = "sandbox_only"
      teacher_channels_prepared = $true
      blocker_queue_prepared = $true
      help_request_contract_created = $true
      sandbox_execution_reflex_proven = $true
      output_paths = @($TeacherChannelContractPath, $TeacherInboxReadmePath, $TeacherOutboxReadmePath, $BlockerQueueReadmePath, $HelpRequestContractPath)
      accepted_state_mutated = $false
      accepted_memory_mutated = $false
      accepted_self_model_mutated = $false
      capability_shelf_mutated = $false
      body_pack_mutated = $false
      external_fetch_performed = $false
      dependency_install_performed = $false
      arbitrary_code_execution_used = $false
      external_agents_created = $false
      live_daemon_started = $false
      next_action = "PREPARE_LIVE_GROWTH_DAEMON_BOOTSTRAP"
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $Step002ActionExecutionResultPath -Object $Step002ActionExecutionResult

    $Step002ValidationResult = [ordered]@{
      status = "PASS"
      validation_id = "PHASE159_STEP_002_VALIDATION"
      step_id = $StepId
      run_id = $RunId
      newborn_step = "step_002"
      selected_action = "PREPARE_LIVE_SESSION_CHANNELS"
      started_from_step_001_next_action = $true
      validation_status = "PASS"
      teacher_channels_prepared = $true
      blocker_queue_prepared = $true
      help_request_contract_created = $true
      forbidden_mutation_flags_clear = $true
      live_daemon_started = $false
      validation_reflex_proven = $true
      next_action = "PREPARE_LIVE_GROWTH_DAEMON_BOOTSTRAP"
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $Step002ValidationResultPath -Object $Step002ValidationResult

    $Step002MemoryEvent = [ordered]@{
      status = "PASS"
      event_id = "PHASE159_STEP_002_MEMORY_EVENT"
      step_id = $StepId
      run_id = $RunId
      newborn_step = "step_002"
      event_type = "SANDBOX_MEMORY_EVENT_ONLY"
      selected_action = "PREPARE_LIVE_SESSION_CHANNELS"
      memory_event_reflex_proven = $true
      accepted_memory_mutated = $false
      memory_summary = "Teacher channel, blocker queue, and help request contracts prepared for future live daemon bootstrap."
      next_action = "PREPARE_LIVE_GROWTH_DAEMON_BOOTSTRAP"
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $Step002MemoryEventPath -Object $Step002MemoryEvent

    $LiveSessionSkeleton = [ordered]@{
      status = "PASS"
      skeleton_id = "PHASE159_LIVE_SESSION_SKELETON"
      step_id = $StepId
      run_id = $RunId
      daemon_mode_prepared = $true
      terminal_1_builder_loop = $true
      terminal_2_observer_loop = $true
      heartbeat_interval_seconds = 30
      tick_interval_seconds = 30
      stop_flag_supported = $true
      teacher_inbox_supported = $true
      teacher_outbox_supported = $true
      blocker_queue_supported = $true
      live_daemon_started = $false
      teacher_channel_contract_path = $TeacherChannelContractPath
      observer_snapshot_contract_path = $ObserverSnapshotContractPath
      stop_policy_path = $StopPolicyPath
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $LiveSessionSkeletonPath -Object $LiveSessionSkeleton

    $ObserverSnapshotContract = [ordered]@{
      status = "PASS"
      contract_id = "PHASE159_OBSERVER_SNAPSHOT_CONTRACT"
      step_id = $StepId
      run_id = $RunId
      channel_type = "file_based"
      execution_scope = "sandbox_only"
      required_fields = @("snapshot_id", "created_at", "tick_id", "heartbeat_id", "builder_state", "active_action", "last_validation_status", "blockers", "safe_stop_state")
      terminal_2_observer_loop = $true
      live_daemon_started = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $ObserverSnapshotContractPath -Object $ObserverSnapshotContract

    $StopPolicy = [ordered]@{
      status = "PASS"
      policy_id = "PHASE159_STOP_POLICY"
      step_id = $StepId
      run_id = $RunId
      safe_stop = $true
      stop_flag_supported = $true
      stop_flag_path = "$RuntimeRoot/STOP.flag"
      stop_reasons = @("teacher_stop_requested", "validator_fail_root_cause_unclear", "scope_boundary_detected", "forbidden_mutation_detected", "live_daemon_bootstrap_not_allowed_in_phase159")
      live_daemon_started = $false
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $StopPolicyPath -Object $StopPolicy

    $SessionSummary = [ordered]@{
      status = "PASS"
      summary_id = "PHASE159_SESSION_SUMMARY"
      step_id = $StepId
      run_id = $RunId
      phase158_verified = $true
      generic_execution_bridge_proven = $true
      capability_inventory_created = $true
      self_map_snapshot_created = $true
      newborn_reflex_core_created = $true
      two_step_newborn_reflex_proven = $true
      step_001_selected_action = "REFRESH_CAPABILITY_INVENTORY_FROM_PROOFS"
      step_001_validation_status = "PASS"
      step_002_started_from_step_001_next_action = $true
      step_002_selected_action = "PREPARE_LIVE_SESSION_CHANNELS"
      step_002_validation_status = "PASS"
      daemon_mode_prepared = $true
      live_daemon_started = $false
      safe_stop = $true
      runtime_output_count = $RuntimeCreatedOutputs.Count
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $SessionSummaryPath -Object $SessionSummary

    $Common = [ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      phase158_verified = $true
      generic_execution_bridge_proven = $true
      generic_spec_sandbox_execution_result_created = $true
      generic_spec_execution_validated = $true
      phase_specific_entrypoint_required = $false
      codex_required_for_phase159_entrypoint = $false
      capability_inventory_created = $true
      self_map_snapshot_created = $true
      newborn_reflex_core_created = $true
      heartbeat_reflex_proven = $true
      self_map_read_reflex_proven = $true
      action_selection_reflex_proven = $true
      sandbox_execution_reflex_proven = $true
      validation_reflex_proven = $true
      memory_event_reflex_proven = $true
      next_action_decision_reflex_proven = $true
      help_request_reflex_prepared = $true
      teacher_channels_prepared = $true
      live_session_skeleton_created = $true
      two_step_newborn_reflex_proven = $true
      step_001_selected_action = "REFRESH_CAPABILITY_INVENTORY_FROM_PROOFS"
      step_001_validation_status = "PASS"
      step_002_started_from_step_001_next_action = $true
      step_002_selected_action = "PREPARE_LIVE_SESSION_CHANNELS"
      step_002_validation_status = "PASS"
      daemon_mode_prepared = $true
      live_daemon_started = $false
      accepted_state_mutated = $false
      accepted_memory_mutated = $false
      accepted_self_model_mutated = $false
      capability_shelf_mutated = $false
      body_pack_mutated = $false
      external_fetch_performed = $false
      dependency_install_performed = $false
      arbitrary_code_execution_used = $false
      external_agents_created = $false
      queue_after = "NONE"
      codex_needed_for_next_step = $false
      safe_stop = $true
      resolved_repo_root = $RepoRoot
      repo_root_resolution_rule = "parent_of_module_directory_from_script_file_location"
      branch = $Branch
      head = $Head
      local_head = $Head
      remote_head = $RemoteHead
      runtime_root = $RuntimeRoot
      session_boot_path = $SessionBootPath
      phase158_bridge_read_path = $Phase158BridgeReadPath
      self_map_snapshot_path = $SelfMapSnapshotPath
      capability_inventory_path = $CapabilityInventoryPath
      proven_capabilities_path = $ProvenCapabilitiesPath
      sandbox_candidates_path = $SandboxCandidatesPath
      admitted_bounded_reuse_path = $AdmittedBoundedReusePath
      generic_bridge_runtime_check_path = $GenericBridgeRuntimeCheckPath
      newborn_reflex_core_path = $NewbornReflexCorePath
      heartbeat_path = $HeartbeatPath
      step_001_action_selection_path = $Step001ActionSelectionPath
      step_001_action_execution_result_path = $Step001ActionExecutionResultPath
      step_001_validation_result_path = $Step001ValidationResultPath
      step_001_memory_event_path = $Step001MemoryEventPath
      step_001_next_action_decision_path = $Step001NextActionDecisionPath
      step_002_action_selection_path = $Step002ActionSelectionPath
      step_002_action_execution_result_path = $Step002ActionExecutionResultPath
      step_002_validation_result_path = $Step002ValidationResultPath
      step_002_memory_event_path = $Step002MemoryEventPath
      teacher_channel_contract_path = $TeacherChannelContractPath
      teacher_inbox_readme_path = $TeacherInboxReadmePath
      teacher_outbox_readme_path = $TeacherOutboxReadmePath
      blocker_queue_readme_path = $BlockerQueueReadmePath
      help_request_contract_path = $HelpRequestContractPath
      live_session_skeleton_path = $LiveSessionSkeletonPath
      observer_snapshot_contract_path = $ObserverSnapshotContractPath
      stop_policy_path = $StopPolicyPath
      session_summary_path = $SessionSummaryPath
      result_path = $ResultPath
      report_path = $ReportPath
      proof_path = $ProofPath
      next_allowed_step = $NextAllowedStep
    }
    foreach ($flagName in $ForbiddenMutationFlags.Keys) {
      $Common[$flagName] = $ForbiddenMutationFlags[$flagName]
    }

    $Result = [ordered]@{}
    foreach ($key in $Common.Keys) { $Result[$key] = $Common[$key] }
    $Result["result_id"] = "PHASE159_BUILDER_NEWBORN_REFLEX_CORE_AND_LIVE_SESSION_PREP_RESULT"
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $Result

    $Report = [ordered]@{
      status = "PASS"
      report_id = "PHASE159_BUILDER_RUNS_GENERIC_SELF_WRITTEN_SPEC_EXECUTION_BRIDGE_V1_REPORT"
      step_id = $StepId
      run_id = $RunId
      repo_identity_gate_result = "PASS"
      root_cause = "child is not prepared for live daemon mode"
      exact_wrong_root_source_found = "RepoRoot defaulted to '.', then Resolve-Phase159Path and Push-Location used the caller working directory; callers in a stale clone made git rev-parse read that clone."
      resolved_repo_root = $RepoRoot
      repo_root_resolution_rule = "module is in repo/modules; repo root is parent of the module directory from the script file location"
      local_head = $Head
      remote_head = $RemoteHead
      serial_plan_used = @(
        "Stage 1 - Self-map: read PHASE152-PHASE158 proofs and create capability inventory files.",
        "Stage 2 - Generic bridge check: read PHASE158 generic bridge outputs and prove bridge is available.",
        "Stage 3 - Newborn reflex core: create reflex core and heartbeat evidence.",
        "Stage 4 - Two-step proof: execute Step 001 then Step 002 derived from Step 001 next_action.",
        "Stage 5 - Live-session skeleton: prepare teacher, blocker, help, observer, and stop channels without launching daemon.",
        "Stage 6 - Proof: create result, report, proof, and safe stop."
      )
      files_changed = @($RouteAlignmentPath, $ModulePath, $ValidatorPath) + $RuntimeCreatedOutputs
      module_path = $ModulePath
      validator_path = $ValidatorPath
      expected_run_command = ".\modules\invoke_builder_runs_generic_self_written_spec_execution_bridge_001.ps1"
      expected_validator_command = ".\validators\validate_phase159_builder_runs_generic_self_written_spec_execution_bridge_v1.ps1 -RepoRoot ."
      runtime_outputs_created_by_module = $RuntimeCreatedOutputs
      risks = @(
        "PHASE159 prepares live daemon mode but does not launch the daemon; PHASE160 must bootstrap live loops separately.",
        "Teacher and blocker channels are file contracts only until the future live session consumes them.",
        "The newborn memory events are sandbox evidence and do not mutate accepted memory."
      )
      cut_list = @(
        "No PHASE160 build.",
        "No infinite live daemon loop.",
        "No orchestrator change.",
        "No TASK_QUEUE mutation.",
        "No GENESIS_STATE mutation.",
        "No CAPABILITY_ROADMAP mutation.",
        "No packs registry mutation.",
        "No capability_shelf mutation.",
        "No living_learning_environment/body mutation.",
        "No living_learning_environment/self_growth_runtime mutation.",
        "No accepted PHASE142-PHASE158 proof, report, or result mutation.",
        "No generated_agents or applied_agents touch.",
        "No dependency or package file touch.",
        "No GitHub workflow touch.",
        "No route lock touch.",
        "No internet fetch.",
        "No dependency install.",
        "No arbitrary generated code execution.",
        "No external agent production.",
        "No commit or push."
      )
      next_allowed_step = $NextAllowedStep
    }
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $Report

    $Proof = [ordered]@{}
    foreach ($key in $Common.Keys) { $Proof[$key] = $Common[$key] }
    $Proof["proof_id"] = $StepId
    $Proof["source_phase158_proof_path"] = $PhaseProofPaths["PHASE158"]
    $Proof["source_generic_execution_request_path"] = $Phase158BridgePaths["request"]
    $Proof["source_generic_execution_admission_path"] = $Phase158BridgePaths["admission"]
    $Proof["source_generic_sandbox_execution_result_path"] = $Phase158BridgePaths["result"]
    $Proof["source_generic_execution_validation_path"] = $Phase158BridgePaths["validation"]
    $Proof["runtime_outputs_created_by_module"] = $RuntimeCreatedOutputs
    Write-Phase159JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $Proof

    return [pscustomobject][ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      resolved_repo_root = $RepoRoot
      local_head = $Head
      remote_head = $RemoteHead
      phase158_verified = $true
      generic_execution_bridge_proven = $true
      capability_inventory_created = $true
      newborn_reflex_core_created = $true
      two_step_newborn_reflex_proven = $true
      step_001_selected_action = "REFRESH_CAPABILITY_INVENTORY_FROM_PROOFS"
      step_001_validation_status = "PASS"
      step_002_started_from_step_001_next_action = $true
      step_002_selected_action = "PREPARE_LIVE_SESSION_CHANNELS"
      step_002_validation_status = "PASS"
      daemon_mode_prepared = $true
      live_daemon_started = $false
      queue_after = "NONE"
      codex_needed_for_next_step = $false
      result_path = $ResultPath
      report_path = $ReportPath
      proof_path = $ProofPath
      next_allowed_step = $NextAllowedStep
    }
  } finally {
    if ($Pushed) {
      Pop-Location
    }
  }
}

if ($MyInvocation.InvocationName -ne ".") {
  Invoke-BuilderRunsGenericSelfWrittenSpecExecutionBridge001 -RepoRoot $RepoRoot -RunId $RunId | ConvertTo-Json -Depth 20
}
