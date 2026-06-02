function Resolve-Phase148Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase148JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase148Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE148_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Write-Phase148JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase148Path -RepoRoot $RepoRoot -Path $Path
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

function Write-Phase148TextFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [string]$Content
  )

  $fullPath = Resolve-Phase148Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  if (-not $Content.EndsWith("`n")) {
    $Content += "`n"
  }

  [System.IO.File]::WriteAllText($fullPath, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Assert-Phase148Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE148_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase148True {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $true) {
    throw "PHASE148_FLAG_NOT_TRUE=$Name actual=$Actual"
  }
}

function Assert-Phase148False {
  param(
    [object]$Actual,
    [string]$Name
  )

  if ($Actual -ne $false) {
    throw "PHASE148_FLAG_NOT_FALSE=$Name actual=$Actual"
  }
}

function New-Phase148Capability {
  param(
    [string]$CapabilityId,
    [string]$Status,
    [string]$Purpose,
    [string[]]$ExistingFiles,
    [string[]]$ReadPaths,
    [string[]]$WritePaths,
    [string[]]$ForbiddenPaths,
    [bool]$SafeToReuse,
    [bool]$RuntimeMutatesRepo,
    [bool]$CanBeUsedByBuilder,
    [string[]]$KnownRisks,
    [string[]]$PromotionRequirements
  )

  return [ordered]@{
    capability_id = $CapabilityId
    status = $Status
    purpose = $Purpose
    owner_line = "SELF_BUILD"
    existing_files = $ExistingFiles
    read_paths = $ReadPaths
    write_paths = $WritePaths
    forbidden_paths = $ForbiddenPaths
    safe_to_reuse = $SafeToReuse
    runtime_mutates_repo = $RuntimeMutatesRepo
    requires_owner_prompt = $false
    requires_codex = $false
    can_be_used_by_builder = $CanBeUsedByBuilder
    example_usage_path = "capability_shelf/usage_examples/$CapabilityId.json"
    validator_reference = "capability_shelf/validators/$CapabilityId.json"
    known_risks = $KnownRisks
    promotion_requirements = $PromotionRequirements
  }
}

function New-Phase148OperationContract {
  param(
    [string]$OperationId,
    [string]$Purpose,
    [object[]]$AllowedInputs,
    [object[]]$AllowedOutputs,
    [string[]]$ReadScope,
    [string[]]$WriteScope,
    [string[]]$ForbiddenScope,
    [bool]$ProofRequired,
    [string]$SafeFailureBehavior,
    [string]$RollbackBehavior,
    [string[]]$ValidatorExpectations
  )

  return [ordered]@{
    operation_id = $OperationId
    purpose = $Purpose
    allowed_inputs = $AllowedInputs
    allowed_outputs = $AllowedOutputs
    read_scope = $ReadScope
    write_scope = $WriteScope
    forbidden_scope = $ForbiddenScope
    proof_required = $ProofRequired
    owner_prompt_required = $false
    codex_required = $false
    safe_failure_behavior = $SafeFailureBehavior
    rollback_behavior = $RollbackBehavior
    validator_expectations = $ValidatorExpectations
  }
}

function New-Phase148Readme {
  param(
    [string]$Title,
    [string]$Belongs,
    [string]$MustNot
  )

  return @(
    "# $Title",
    "",
    "## What Belongs Here",
    $Belongs,
    "",
    "## What Must Not Be Placed Here",
    $MustNot,
    "",
    "## Builder Read Rules",
    "Builder may read this area as governed reference material. Reading does not imply trust, execution rights, dependency admission, or production adoption.",
    "",
    "## Provenance And Citation",
    "Every item read from this area must retain source path, author or origin when known, creation or capture date when known, license or terms status when known, and use scope. Summaries must cite the source cards or internal paths they rely on.",
    "",
    "## Learning Cards",
    "A learning card is created only from cited evidence. It must include card_id, source_paths, summary, learned_rule, limits, risk_notes, created_by, and status. A learning card can guide Builder behavior only after validator-backed promotion.",
    "",
    "## Summary Versus Trusted Knowledge",
    "A summary is a compressed reading note. Trusted knowledge is a promoted, validator-backed artifact. Summaries are not trusted knowledge by default."
  ) -join "`n"
}

function Invoke-BuilderModularLivingLearningEnvironmentBootstrap001 {
  param(
    [string]$RepoRoot,
    [string]$RunId = "PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_001"
  )

  $ErrorActionPreference = "Stop"
  Push-Location $RepoRoot

  try {
    $StepId = "PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1"
    $PreviousStep = "PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_V1"
    $PreviousFormalNextStep = "PHASE148_BUILDER_SELF_CORRECTION_RETENTION_TRIAL_V1"
    $NextAllowedStep = "PHASE149_BUILDER_READING_AND_CAPABILITY_REUSE_SESSION_V1"
    $PreviousAcceptedHead = "cb43e79"
    $RouteChangeReason = "PHASE142-PHASE147 proved observation, correction, memory, multi-session learning, observation-only running, and self-correction. The next bottleneck is not another atomic trial; it is missing modular capability shelf, source registry, knowledge library, and living learning environment."
    $DeferredStepReason = "PHASE148_BUILDER_SELF_CORRECTION_RETENTION_TRIAL_V1 is deferred and may be reintroduced inside the living learning environment as a reusable retention check."

    foreach ($identityFile in @(
      "CAPABILITY_ROADMAP.json",
      "GENESIS_STATE.json",
      "TASK_QUEUE.json",
      "packs/registry.json",
      "orchestrator/run.ps1"
    )) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase148Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $Branch = (git branch --show-current).Trim()
    if ($Branch -eq "main") {
      throw "PHASE148_MAIN_BRANCH_FORBIDDEN"
    }
    Assert-Phase148Equals -Actual $Branch -Expected "phase110-idempotent-autonomy-trial-runtime" -Name "current_branch"
    $Head = (git rev-parse --short HEAD).Trim()
    Assert-Phase148Equals -Actual $Head -Expected $PreviousAcceptedHead -Name "current_head"

    $Phase147ProofPath = "proofs/self_development/PHASE147_BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_V1.json"
    $Phase147ResultPath = "self_control/BUILDER_OBSERVATION_DRIVEN_SELF_CORRECTION_RESULT.json"
    $Phase147Proof = Read-Phase148JsonRequired -RepoRoot $RepoRoot -Path $Phase147ProofPath
    Assert-Phase148Equals -Actual $Phase147Proof.status -Expected "PASS" -Name "phase147_status"
    Assert-Phase148Equals -Actual $Phase147Proof.next_allowed_step -Expected $PreviousFormalNextStep -Name "phase147_next_allowed_step"

    $Queue = Read-Phase148JsonRequired -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
    Assert-Phase148Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

    $ForbiddenBefore = @(git status --short --untracked-files=all -- `
      orchestrator/run.ps1 `
      route_locks `
      generated_agents `
      agent_catalog `
      applied_agents `
      runtime_sessions/builder_life_loop/current `
      runtime_sessions/builder_life_loop/observations `
      runtime_sessions/builder_life_loop/correction_trials `
      runtime_sessions/builder_life_loop/adaptation_trials `
      runtime_sessions/builder_life_loop/multi_session_trials `
      runtime_sessions/builder_life_loop/self_correction_trials 2>$null)
    if ($ForbiddenBefore.Count -gt 0) {
      throw "PHASE148_FORBIDDEN_SCOPE_DIRTY_BEFORE=$($ForbiddenBefore -join '; ')"
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
      $Phase147ResultPath
    )

    $FilesRead = @(
      $Phase147ProofPath,
      $Phase147ResultPath,
      "tools/start_builder_observation_session.ps1",
      "tools/watch_builder_observation_session.ps1",
      "tools/stop_builder_observation_session.ps1",
      "tools/start_builder_life_loop.ps1",
      "tools/watch_builder_life_loop.ps1",
      "tools/stop_builder_life_loop.ps1",
      "tools/write_builder_life_loop_correction.ps1",
      "tools/restore_agent_builder_state.ps1",
      "tools/publish_builder_life_loop_checkpoint.ps1",
      "self_control/BUILDER_MULTI_SESSION_LEARNING_MEMORY.json",
      "materials/MATERIAL_CATALOG.json",
      "materials/MATERIAL_QUARANTINE_EVALUATION_RESULTS.json",
      "materials/MATERIAL_POLICY.json",
      "materials/MATERIAL_USE_POLICY.json",
      "packs/registry.json"
    )
    foreach ($readPath in $FilesRead) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase148Path -RepoRoot $RepoRoot -Path $readPath))) {
        throw "PHASE148_EXPECTED_READ_PATH_MISSING=$readPath"
      }
    }

    $ForbiddenPaths = @(
      "proofs/self_development/PHASE142-PHASE147",
      "reports/self_development/PHASE142-PHASE147",
      "self_control/accepted_phase_results",
      "runtime_sessions/builder_life_loop/current",
      "runtime_sessions/builder_life_loop/existing_trials",
      "generated_agents",
      "agent_catalog",
      "applied_agents",
      "route_locks",
      "orchestrator/run.ps1"
    )
    $PromotionRequirements = @(
      "validator PASS",
      "proof artifact",
      "no forbidden scope changes",
      "promotion gate record",
      "explicit next_allowed_step"
    )

    $Capabilities = @(
      New-Phase148Capability -CapabilityId "observation_runner" -Status "READY" -Purpose "Start, watch, and stop bounded observation-only sessions without allowing supervisor-authored task decisions." -ExistingFiles @("tools/start_builder_observation_session.ps1","tools/watch_builder_observation_session.ps1","tools/stop_builder_observation_session.ps1","modules/invoke_builder_observation_only_live_runner_001.ps1") -ReadPaths @("self_control/BUILDER_MULTI_SESSION_LEARNING_MEMORY.json","proofs/self_development/PHASE145_BUILDER_AUTONOMOUS_MULTI_SESSION_LEARNING_TRIAL_V1.json") -WritePaths @("runtime_sessions/builder_life_loop/observations/<new_session_id>") -ForbiddenPaths $ForbiddenPaths -SafeToReuse $true -RuntimeMutatesRepo $true -CanBeUsedByBuilder $true -KnownRisks @("Can create observation artifacts; must use new session ids only.","Does not decide tasks for Builder.") -PromotionRequirements $PromotionRequirements
      New-Phase148Capability -CapabilityId "life_loop_runner" -Status "PARTIAL" -Purpose "Operate the existing life loop tooling only under explicit policy and never as an unrestricted production route." -ExistingFiles @("tools/start_builder_life_loop.ps1","tools/watch_builder_life_loop.ps1","tools/stop_builder_life_loop.ps1") -ReadPaths @("self_control","packs/registry.json") -WritePaths @("living_learning_environment/sandbox/life_loop_sessions/<session_id>") -ForbiddenPaths $ForbiddenPaths -SafeToReuse $true -RuntimeMutatesRepo $true -CanBeUsedByBuilder $true -KnownRisks @("Legacy tooling may touch current runtime state; PHASE148 only registers it behind sandbox and promotion policy.","Requires validation before live current-state use.") -PromotionRequirements $PromotionRequirements
      New-Phase148Capability -CapabilityId "correction_inbox" -Status "READY" -Purpose "Record bounded correction requests for Builder to inspect and apply only inside governed sessions." -ExistingFiles @("tools/write_builder_life_loop_correction.ps1") -ReadPaths @("living_learning_environment/proposals","living_learning_environment/module_requests") -WritePaths @("living_learning_environment/sandbox/corrections","living_learning_environment/observations/<session_id>") -ForbiddenPaths $ForbiddenPaths -SafeToReuse $true -RuntimeMutatesRepo $true -CanBeUsedByBuilder $true -KnownRisks @("Corrections are not automatically trusted or promoted.","Correction application requires proof.") -PromotionRequirements $PromotionRequirements
      New-Phase148Capability -CapabilityId "restore_state" -Status "READY" -Purpose "Restore Builder state only from repo-approved checkpoint material after validation." -ExistingFiles @("tools/restore_agent_builder_state.ps1") -ReadPaths @("living_learning_environment/promotion_gates","proofs/self_development") -WritePaths @("living_learning_environment/sandbox/restore_dry_runs") -ForbiddenPaths $ForbiddenPaths -SafeToReuse $true -RuntimeMutatesRepo $true -CanBeUsedByBuilder $true -KnownRisks @("Direct restore can mutate state; PHASE148 permits dry-run planning only.","Promotion gate required before state writes.") -PromotionRequirements $PromotionRequirements
      New-Phase148Capability -CapabilityId "checkpoint_publish" -Status "READY" -Purpose "Publish checkpoint summaries for reading and observation without changing accepted phase artifacts." -ExistingFiles @("tools/publish_builder_life_loop_checkpoint.ps1") -ReadPaths @("living_learning_environment/observations","runtime_sessions/builder_life_loop/observations") -WritePaths @("living_learning_environment/sandbox/checkpoints","living_learning_environment/promotion_candidates") -ForbiddenPaths $ForbiddenPaths -SafeToReuse $true -RuntimeMutatesRepo $true -CanBeUsedByBuilder $true -KnownRisks @("Checkpoint publication is evidence packaging, not acceptance.","Published checkpoints need validator review before promotion.") -PromotionRequirements $PromotionRequirements
      New-Phase148Capability -CapabilityId "self_learning_memory" -Status "READY" -Purpose "Read accumulated multi-session learning memory as reusable context without mutating it during bootstrap." -ExistingFiles @("self_control/BUILDER_MULTI_SESSION_LEARNING_MEMORY.json") -ReadPaths @("self_control/BUILDER_MULTI_SESSION_LEARNING_MEMORY.json") -WritePaths @("knowledge_library/learning_cards","living_learning_environment/reading_sessions/<session_id>") -ForbiddenPaths $ForbiddenPaths -SafeToReuse $true -RuntimeMutatesRepo $false -CanBeUsedByBuilder $true -KnownRisks @("Memory can be stale or overfit; reading requires provenance and retention checks.","Bootstrap does not modify memory.") -PromotionRequirements $PromotionRequirements
      New-Phase148Capability -CapabilityId "observation_only_result" -Status "READY" -Purpose "Reuse PHASE146 observation-only proof and result as evidence for observation-first learning." -ExistingFiles @("proofs/self_development/PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_V1.json","self_control/BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_RESULT.json") -ReadPaths @("proofs/self_development/PHASE146_BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_V1.json","self_control/BUILDER_OBSERVATION_ONLY_LIVE_RUNNER_RESULT.json","runtime_sessions/builder_life_loop/observations/LIVE_OBSERVE_AFTER_PHASE146_001") -WritePaths @("knowledge_library/summaries","living_learning_environment/observations") -ForbiddenPaths $ForbiddenPaths -SafeToReuse $true -RuntimeMutatesRepo $false -CanBeUsedByBuilder $true -KnownRisks @("Observation evidence is descriptive; it does not grant runtime authority.","Existing observation folders are read-only.") -PromotionRequirements $PromotionRequirements
      New-Phase148Capability -CapabilityId "self_correction_result" -Status "READY" -Purpose "Reuse PHASE147 self-correction result as evidence for Builder-authored correction patterns." -ExistingFiles @($Phase147ProofPath,$Phase147ResultPath,"modules/invoke_builder_observation_driven_self_correction_trial_001.ps1","validators/validate_phase147_builder_observation_driven_self_correction_trial_v1.ps1") -ReadPaths @($Phase147ProofPath,$Phase147ResultPath,"runtime_sessions/builder_life_loop/self_correction_trials/PHASE147_OBSERVATION_DRIVEN_SELF_CORRECTION_TRIAL_001") -WritePaths @("knowledge_library/learning_cards","living_learning_environment/promotion_candidates") -ForbiddenPaths $ForbiddenPaths -SafeToReuse $true -RuntimeMutatesRepo $false -CanBeUsedByBuilder $true -KnownRisks @("Self-correction retention is deferred; PHASE149+ must prove reuse in live reading sessions.","Existing PHASE147 artifacts are read-only.") -PromotionRequirements $PromotionRequirements
      New-Phase148Capability -CapabilityId "material_governance" -Status "READY" -Purpose "Read material policy and catalog to prevent blind trust, installs, fetches, executable use, and runtime adoption." -ExistingFiles @("materials/MATERIAL_CATALOG.json","materials/MATERIAL_QUARANTINE_EVALUATION_RESULTS.json","materials/MATERIAL_POLICY.json","materials/MATERIAL_USE_POLICY.json") -ReadPaths @("materials/MATERIAL_CATALOG.json","materials/MATERIAL_QUARANTINE_EVALUATION_RESULTS.json","materials/MATERIAL_POLICY.json","materials/MATERIAL_USE_POLICY.json","source_registry") -WritePaths @("source_registry/source_cards","living_learning_environment/module_requests") -ForbiddenPaths $ForbiddenPaths -SafeToReuse $true -RuntimeMutatesRepo $false -CanBeUsedByBuilder $true -KnownRisks @("Reference-only material can be mistaken for trusted material; policy forbids trust by default.","No external fetch or install is enabled.") -PromotionRequirements $PromotionRequirements
      New-Phase148Capability -CapabilityId "pack_registry" -Status "READY" -Purpose "Read pack registry as the repo-native map of known Builder capabilities without adding routes during bootstrap." -ExistingFiles @("packs/registry.json") -ReadPaths @("packs/registry.json") -WritePaths @("capability_shelf/summaries","living_learning_environment/reading_sessions/<session_id>") -ForbiddenPaths $ForbiddenPaths -SafeToReuse $true -RuntimeMutatesRepo $false -CanBeUsedByBuilder $true -KnownRisks @("Registry reading is not permission to execute packs.","New execution routes remain out of scope.") -PromotionRequirements $PromotionRequirements
    )

    $Operations = @(
      New-Phase148OperationContract -OperationId "start_observation_session" -Purpose "Start a bounded observation-only session under a new session id." -AllowedInputs @("session_id","max_cycles","checkpoint_every","sleep_seconds") -AllowedOutputs @("heartbeat","decision_trace","observation_ledger","session_summary") -ReadScope @("self_control/BUILDER_MULTI_SESSION_LEARNING_MEMORY.json","proofs/self_development") -WriteScope @("runtime_sessions/builder_life_loop/observations/<new_session_id>") -ForbiddenScope $ForbiddenPaths -ProofRequired $true -SafeFailureBehavior "Stop before writing if prior proof or session id is invalid." -RollbackBehavior "Remove only the newly created observation session folder after operator review." -ValidatorExpectations @("new session id","selected_by BUILDER_RUNTIME","lifecycle_authority OBSERVATION_RUNNER_ONLY")
      New-Phase148OperationContract -OperationId "watch_observation_session" -Purpose "Read observation-only artifacts without mutating them." -AllowedInputs @("session_id","iterations") -AllowedOutputs @("latest heartbeat","summary view") -ReadScope @("runtime_sessions/builder_life_loop/observations/<session_id>") -WriteScope @() -ForbiddenScope $ForbiddenPaths -ProofRequired $false -SafeFailureBehavior "Report missing session and stop." -RollbackBehavior "No rollback; read-only." -ValidatorExpectations @("no writes","current runtime not read")
      New-Phase148OperationContract -OperationId "stop_observation_session" -Purpose "Request stop for a bounded observation session by writing a stop marker only in that session." -AllowedInputs @("session_id","reason") -AllowedOutputs @("STOP_REQUESTED marker") -ReadScope @("runtime_sessions/builder_life_loop/observations/<session_id>") -WriteScope @("runtime_sessions/builder_life_loop/observations/<session_id>/STOP_REQUESTED") -ForbiddenScope $ForbiddenPaths -ProofRequired $true -SafeFailureBehavior "Fail if session path is missing or outside observations." -RollbackBehavior "Remove only the stop marker if written in error and no session consumed it." -ValidatorExpectations @("marker in requested session only","no current writes")
      New-Phase148OperationContract -OperationId "write_correction" -Purpose "Write a correction request for Builder to inspect in a governed session." -AllowedInputs @("correction_id","message","source","scope") -AllowedOutputs @("correction record") -ReadScope @("living_learning_environment/proposals") -WriteScope @("living_learning_environment/sandbox/corrections") -ForbiddenScope $ForbiddenPaths -ProofRequired $true -SafeFailureBehavior "Create no record if provenance or scope is missing." -RollbackBehavior "Supersede with a correction cancellation record inside sandbox." -ValidatorExpectations @("correction is not automatically applied","Builder remains decision author")
      New-Phase148OperationContract -OperationId "restore_state" -Purpose "Plan or perform state restore only after checkpoint proof and promotion gate." -AllowedInputs @("checkpoint_id","proof_path","dry_run") -AllowedOutputs @("restore plan","restore proof") -ReadScope @("living_learning_environment/promotion_gates","proofs/self_development") -WriteScope @("living_learning_environment/sandbox/restore_dry_runs") -ForbiddenScope $ForbiddenPaths -ProofRequired $true -SafeFailureBehavior "Default to dry-run and stop without a promotion gate." -RollbackBehavior "Use previous checkpoint proof; never infer rollback from chat." -ValidatorExpectations @("promotion gate required","no accepted artifact rewrite in bootstrap")
      New-Phase148OperationContract -OperationId "publish_checkpoint" -Purpose "Package a checkpoint summary from observed Builder artifacts." -AllowedInputs @("source_session","checkpoint_id","summary") -AllowedOutputs @("checkpoint publication record") -ReadScope @("living_learning_environment/observations","runtime_sessions/builder_life_loop/observations") -WriteScope @("living_learning_environment/sandbox/checkpoints","living_learning_environment/promotion_candidates") -ForbiddenScope $ForbiddenPaths -ProofRequired $true -SafeFailureBehavior "Do not publish if source artifact is missing." -RollbackBehavior "Mark candidate superseded; do not delete evidence." -ValidatorExpectations @("source cited","promotion candidate only")
      New-Phase148OperationContract -OperationId "read_learning_memory" -Purpose "Read existing Builder learning memory for reuse-first sessions." -AllowedInputs @("memory_path","read_purpose") -AllowedOutputs @("reading note","learning card candidate") -ReadScope @("self_control/BUILDER_MULTI_SESSION_LEARNING_MEMORY.json") -WriteScope @("knowledge_library/learning_cards","living_learning_environment/reading_sessions") -ForbiddenScope $ForbiddenPaths -ProofRequired $false -SafeFailureBehavior "Stop if memory file is missing or not PASS." -RollbackBehavior "Delete only the new reading-session note before promotion." -ValidatorExpectations @("memory not mutated","provenance retained")
      New-Phase148OperationContract -OperationId "read_material_catalog" -Purpose "Read material governance files as constraints, not trust grants." -AllowedInputs @("catalog_path","policy_path") -AllowedOutputs @("material reading summary") -ReadScope @("materials/MATERIAL_CATALOG.json","materials/MATERIAL_POLICY.json","materials/MATERIAL_USE_POLICY.json") -WriteScope @("knowledge_library/summaries","source_registry/source_cards") -ForbiddenScope $ForbiddenPaths -ProofRequired $false -SafeFailureBehavior "Stop if policy files are missing." -RollbackBehavior "Supersede generated summary; do not change material policy." -ValidatorExpectations @("trusted_source_count remains zero","no install/fetch/execute")
      New-Phase148OperationContract -OperationId "quarantine_material_candidate" -Purpose "Record a future quarantine request for a candidate source without using it." -AllowedInputs @("source_card_id","candidate_reason","risk_notes") -AllowedOutputs @("module_request or quarantine proposal") -ReadScope @("source_registry/source_cards","materials/MATERIAL_POLICY.json") -WriteScope @("living_learning_environment/module_requests","living_learning_environment/proposals") -ForbiddenScope $ForbiddenPaths -ProofRequired $true -SafeFailureBehavior "Create request only; do not fetch, install, execute, or trust." -RollbackBehavior "Close request as rejected/superseded." -ValidatorExpectations @("no trusted material","no executable use")
      New-Phase148OperationContract -OperationId "create_learning_card" -Purpose "Create a cited learning card from internal or allowed reference material." -AllowedInputs @("source_paths","summary","learned_rule","limits","risk_notes") -AllowedOutputs @("learning_card") -ReadScope @("knowledge_library","source_registry","self_control") -WriteScope @("knowledge_library/learning_cards") -ForbiddenScope $ForbiddenPaths -ProofRequired $true -SafeFailureBehavior "Do not write card without provenance." -RollbackBehavior "Mark card superseded; retain cited evidence." -ValidatorExpectations @("source_paths populated","status candidate or PASS_BY_VALIDATOR")
      New-Phase148OperationContract -OperationId "create_proposal" -Purpose "Create a Builder proposal without applying it to accepted state." -AllowedInputs @("proposal_id","evidence","change_summary","risk") -AllowedOutputs @("proposal record") -ReadScope @("knowledge_library","capability_shelf","living_learning_environment/observations") -WriteScope @("living_learning_environment/proposals") -ForbiddenScope $ForbiddenPaths -ProofRequired $true -SafeFailureBehavior "Proposal remains draft if evidence is missing." -RollbackBehavior "Close proposal as rejected or superseded; do not edit accepted state." -ValidatorExpectations @("proposal does not mutate production","promotion gate required")
      New-Phase148OperationContract -OperationId "create_module_request" -Purpose "Request Codex or tooling only after missing organ or proven defect evidence exists." -AllowedInputs @("module_request_id","missing_tool_or_defect","evidence_paths") -AllowedOutputs @("module_request record") -ReadScope @("living_learning_environment/observations","validators","proofs") -WriteScope @("living_learning_environment/module_requests") -ForbiddenScope $ForbiddenPaths -ProofRequired $true -SafeFailureBehavior "Reject request without evidence." -RollbackBehavior "Close request as not needed if reuse capability exists." -ValidatorExpectations @("codex_only_for_missing_tool_or_proven_defect true","reuse-first checked")
      New-Phase148OperationContract -OperationId "promote_candidate_to_builder_state" -Purpose "Move a sandbox/proposal candidate toward Builder state only through validator/proof and explicit promotion gate." -AllowedInputs @("candidate_id","validator_path","proof_path","promotion_gate_id") -AllowedOutputs @("promotion gate decision") -ReadScope @("living_learning_environment/promotion_candidates","living_learning_environment/promotion_gates") -WriteScope @("living_learning_environment/promotion_gates") -ForbiddenScope $ForbiddenPaths -ProofRequired $true -SafeFailureBehavior "Default DENY without validator PASS and proof." -RollbackBehavior "Promotion gate records reversal plan before any future state write." -ValidatorExpectations @("promotion_gate_required true","accepted state unchanged in bootstrap")
    )

    $FilesCreated = New-Object System.Collections.Generic.List[string]
    function Write-TrackedJson {
      param([string]$Path, [object]$Object)
      Write-Phase148JsonFile -RepoRoot $RepoRoot -Path $Path -Object $Object
      $FilesCreated.Add($Path) | Out-Null
    }
    function Write-TrackedText {
      param([string]$Path, [string]$Content)
      Write-Phase148TextFile -RepoRoot $RepoRoot -Path $Path -Content $Content
      $FilesCreated.Add($Path) | Out-Null
    }

    $RouteChangeText = @(
      "# PHASE148 Modular Living Learning Environment Bootstrap",
      "",
      "status: PASS",
      "from: PHASE148_BUILDER_SELF_CORRECTION_RETENTION_TRIAL_V1",
      "to: PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1",
      "reason: $RouteChangeReason",
      "deferred_step: $PreviousFormalNextStep",
      "deferred_step_reason: $DeferredStepReason",
      "",
      "This is a method and route bootstrap, not an orchestrator route change. It creates reusable shelves, source policy, knowledge structure, and a sandboxed living learning environment while leaving routed runtime behavior unchanged.",
      "",
      "Safety: no internet fetch, no dependency install, no executable material use, no material trust, no production adoption, no external agent production, no accepted PHASE142-PHASE147 artifact mutation, and no current runtime mutation."
    ) -join "`n"
    Write-TrackedText -Path "route_change_requests/PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1.md" -Content $RouteChangeText

    Write-TrackedText -Path "capability_shelf/README.md" -Content @(
      "# Capability Shelf",
      "",
      "The capability shelf catalogs reusable Builder organs that already exist in this repo or are available as governed local structures.",
      "",
      "It is an index, not an execution grant. Builder must read capability entries, inspect existing files, use operation contracts, and pass validators before any promotion.",
      "",
      "Capability entries must preserve read scope, write scope, forbidden scope, known risks, and promotion requirements. Missing tools are requested through living_learning_environment/module_requests, not invented in place."
    ) -join "`n"

    foreach ($capability in $Capabilities) {
      Write-TrackedJson -Path "capability_shelf/capabilities/$($capability.capability_id).json" -Object $capability
      Write-TrackedJson -Path $capability.example_usage_path -Object ([ordered]@{
        status = "PASS"
        capability_id = $capability.capability_id
        example_id = "$($capability.capability_id)_example_usage_v1"
        builder_flow = @(
          "Read capability entry.",
          "Check existing_files exist.",
          "Use only declared read_paths and write_paths.",
          "Stop on forbidden_paths.",
          "Create proposal or learning card before promotion."
        )
        no_runtime_execution_granted = $true
      })
      Write-TrackedJson -Path $capability.validator_reference -Object ([ordered]@{
        status = "PASS"
        capability_id = $capability.capability_id
        validator_id = "$($capability.capability_id)_capability_shelf_validator_reference_v1"
        expectations = @(
          "existing_files exist",
          "forbidden_paths are not touched",
          "requires_owner_prompt is false unless proven",
          "requires_codex is false unless a missing tool or proven defect is documented",
          "promotion_requirements are satisfied before state adoption"
        )
      })
    }

    $Registry = [ordered]@{
      status = "PASS"
      registry_id = "PHASE148_CAPABILITY_SHELF_REGISTRY_V1"
      step_id = $StepId
      owner_line = "SELF_BUILD"
      reusable_capability_count = $Capabilities.Count
      capabilities = $Capabilities
      next_allowed_step = $NextAllowedStep
    }
    Write-TrackedJson -Path "capability_shelf/registry.json" -Object $Registry

    foreach ($operation in $Operations) {
      Write-TrackedJson -Path "capability_shelf/operation_contracts/$($operation.operation_id).json" -Object $operation
    }

    $KnowledgeReadmes = [ordered]@{
      "knowledge_library/README.md" = @("Knowledge Library","Internal Builder-readable notes, source-indexed summaries, learning cards, and provenance records.","Do not place trusted runtime code, copied external articles, executable downloads, secrets, or uncited claims here.")
      "knowledge_library/internal/README.md" = @("Internal Knowledge","Repo-native docs, proof summaries, validated reports, and Builder-owned notes sourced from local artifacts.","Do not place external material here unless it is summarized with provenance and routed to reference_only or official_docs.")
      "knowledge_library/official_docs/README.md" = @("Official Docs References","Summaries and source cards for official documentation that may be read as reference-only material.","Do not mark official docs trusted, copy large external text, install packages, or run examples from docs.")
      "knowledge_library/reference_only/README.md" = @("Reference Only Knowledge","Non-trusted reference summaries such as encyclopedic or public explanatory material with provenance.","Do not treat reference-only material as runtime authority, trusted code, or production policy.")
      "knowledge_library/learning_cards/README.md" = @("Learning Cards","Small cited cards that extract a Builder behavior lesson from local or allowed reference evidence.","Do not create cards without source paths, risk notes, and status. Do not let cards mutate Builder state directly.")
      "knowledge_library/summaries/README.md" = @("Summaries","Compressed reading notes that preserve provenance and limits.","Do not confuse summaries with trusted knowledge or validator-passed capability.")
      "knowledge_library/reading_sessions/.gitkeep" = @("","","")
    }
    foreach ($entry in $KnowledgeReadmes.GetEnumerator()) {
      if ($entry.Key.EndsWith(".gitkeep")) {
        Write-TrackedText -Path $entry.Key -Content ""
      } else {
        Write-TrackedText -Path $entry.Key -Content (New-Phase148Readme -Title $entry.Value[0] -Belongs $entry.Value[1] -MustNot $entry.Value[2])
      }
    }

    $SourcePolicy = [ordered]@{
      status = "PASS"
      policy_id = "PHASE148_SOURCE_POLICY_V1"
      default_trust = $false
      read_allowed_without_trust = $true
      read_allowed_without_trust_scope = @("allowed","reference_only")
      runtime_use_allowed_without_admission = $false
      install_allowed = $false
      external_fetch_allowed = $false
      executable_use_allowed = $false
      source_must_have = @("provenance","license","terms","risk","use_scope")
      wikipedia_reference_only_never_trusted_automatically = $true
      official_docs_allowed_readable_not_trusted_until_source_card_and_policy_gate_pass = $true
      github_repos_allowed_readable_not_executable_until_quarantine_admission_proof = $true
      new_source_initial_status_values = @("candidate","reference_only")
      new_source_must_never_start_trusted = $true
      next_allowed_step = $NextAllowedStep
    }
    Write-TrackedJson -Path "source_registry/source_policy.json" -Object $SourcePolicy
    Write-TrackedJson -Path "source_registry/trusted_sources.json" -Object ([ordered]@{
      status = "PASS"
      trusted_sources = @()
      trusted_source_count = 0
      reason = "no external source is trusted during bootstrap"
      next_allowed_step = $NextAllowedStep
    })
    Write-TrackedJson -Path "source_registry/allowed_sources.json" -Object ([ordered]@{
      status = "PASS"
      allowed_source_classes = @(
        "internal_repo_docs",
        "local_knowledge_library",
        "official_documentation_reference",
        "official_repository_reference",
        "package_registry_metadata_reference",
        "license_reference",
        "security_advisory_reference",
        "wikipedia_reference_only"
      )
      external_fetch_enabled = $false
      next_allowed_step = $NextAllowedStep
    })
    Write-TrackedJson -Path "source_registry/blocked_sources.json" -Object ([ordered]@{
      status = "PASS"
      blocked_source_classes = @(
        "unknown_executable_downloads",
        "unlicensed_code_snippets",
        "random_blog_runtime_code",
        "package_install_without_policy",
        "source_without_provenance",
        "source_with_unclear_terms",
        "source_requiring_secret_or_login",
        "source_that_changes_builder_runtime_without_promotion"
      )
      next_allowed_step = $NextAllowedStep
    })
    Write-TrackedText -Path "source_registry/source_cards/README.md" -Content @(
      "# Source Cards",
      "",
      "Source cards describe candidate or reference-only sources. They never create trust by themselves.",
      "",
      "Each card must include provenance, license, terms, risk, use_scope, source_class, trust_status, external_fetch_allowed, install_allowed, executable_use_allowed, and admission_requirements.",
      "",
      "Official docs may be readable references. GitHub repositories may be readable references. Wikipedia is reference-only. No source can become runtime material without quarantine, admission, proof, and promotion."
    ) -join "`n"

    $SourceCards = @(
      [ordered]@{ source_card_id = "internal_repo_docs"; source_class = "internal_repo_docs"; trust_status = "candidate"; provenance = "local repository"; license = "repo-local"; terms = "repo governance"; risk = "low"; use_scope = "read local docs and artifacts"; external_fetch_allowed = $false; install_allowed = $false; executable_use_allowed = $false },
      [ordered]@{ source_card_id = "official_documentation_reference"; source_class = "official_documentation_reference"; trust_status = "reference_only"; provenance = "official documentation when manually supplied or separately governed"; license = "must be recorded per source"; terms = "must be recorded per source"; risk = "medium"; use_scope = "read and summarize with citation"; external_fetch_allowed = $false; install_allowed = $false; executable_use_allowed = $false },
      [ordered]@{ source_card_id = "official_repository_reference"; source_class = "official_repository_reference"; trust_status = "reference_only"; provenance = "official repository metadata only after policy gate"; license = "must be recorded"; terms = "must be recorded"; risk = "medium"; use_scope = "reference only, no execution"; external_fetch_allowed = $false; install_allowed = $false; executable_use_allowed = $false },
      [ordered]@{ source_card_id = "wikipedia_reference_only"; source_class = "wikipedia_reference_only"; trust_status = "reference_only"; provenance = "encyclopedic reference"; license = "must cite source license"; terms = "must cite source terms"; risk = "medium"; use_scope = "orientation only"; external_fetch_allowed = $false; install_allowed = $false; executable_use_allowed = $false }
    )
    foreach ($card in $SourceCards) {
      $card["status"] = "PASS"
      $card["trusted"] = $false
      $card["next_allowed_step"] = $NextAllowedStep
      Write-TrackedJson -Path "source_registry/source_cards/$($card.source_card_id).json" -Object $card
    }

    $LivingReadmes = [ordered]@{
      "living_learning_environment/README.md" = "A sandboxed home for Builder to read, observe, propose, request modules, and prepare promotion candidates without mutating accepted Builder state."
      "living_learning_environment/sandbox/README.md" = "Builder may write freely here and in specific session folders. Nothing here is accepted state until a promotion gate passes."
      "living_learning_environment/observations/README.md" = "Observation summaries and reading notes go here. Existing runtime_sessions remain protected read-only evidence."
      "living_learning_environment/proposals/README.md" = "Builder proposals go here. A proposal cannot apply itself to production files or accepted state."
      "living_learning_environment/reading_sessions/README.md" = "Reading sessions cite capability shelf, source registry, knowledge library, and internal proofs."
      "living_learning_environment/module_requests/README.md" = "Requests for Codex or new modules go here only after a missing tool or proven defect is documented."
      "living_learning_environment/promotion_candidates/README.md" = "Validated candidates can be staged here before any state adoption."
      "living_learning_environment/promotion_gates/README.md" = "Promotion gates record validator/proof requirements and explicit acceptance boundaries."
    }
    foreach ($entry in $LivingReadmes.GetEnumerator()) {
      Write-TrackedText -Path $entry.Key -Content @(
        "# $([System.IO.Path]::GetFileName((Split-Path -Path $entry.Key -Parent)))",
        "",
        $entry.Value,
        "",
        "Builder must observe first, reuse existing capability second, and request Codex only when evidence shows a missing organ or proven defect.",
        "",
        "No internet fetch, dependency install, executable material use, external material trust, production adoption, external agent production, accepted artifact rewrite, current runtime mutation, route lock change, or orchestrator route change is allowed from this environment."
      ) -join "`n"
    }

    Write-TrackedJson -Path "living_learning_environment/session_policy.json" -Object ([ordered]@{
      status = "PASS"
      policy_id = "PHASE148_LIVING_LEARNING_SESSION_POLICY_V1"
      builder_may_read = @("source_registry","knowledge_library","capability_shelf","proofs/self_development","reports/self_development")
      builder_may_write_freely_only_inside = @("living_learning_environment/sandbox","living_learning_environment/reading_sessions/<session_id>","living_learning_environment/observations/<session_id>")
      builder_may_create_proposals = $true
      builder_cannot_apply_proposals_directly = $true
      builder_may_request_modules = $true
      codex_only_for_missing_tool_or_proven_defect = $true
      observation_first_policy = $true
      reuse_first_policy = $true
      external_material_trust_allowed = $false
      install_allowed = $false
      external_fetch_allowed = $false
      executable_material_use_allowed = $false
      production_file_modification_allowed = $false
      next_allowed_step = $NextAllowedStep
    })
    Write-TrackedJson -Path "living_learning_environment/promotion_policy.json" -Object ([ordered]@{
      status = "PASS"
      policy_id = "PHASE148_LIVING_LEARNING_PROMOTION_POLICY_V1"
      promotion_gate_required = $true
      validator_required = $true
      proof_required = $true
      explicit_promotion_gate_required = $true
      sandbox_or_proposal_cannot_mutate_builder_state_directly = $true
      accepted_phase_artifacts_read_only = $true
      current_runtime_artifacts_read_only = $true
      production_adoption_allowed = $false
      next_allowed_step = $NextAllowedStep
    })
    Write-TrackedJson -Path "living_learning_environment/sandbox_write_policy.json" -Object ([ordered]@{
      status = "PASS"
      policy_id = "PHASE148_SANDBOX_WRITE_POLICY_V1"
      builder_sandbox_write_scope_defined = $true
      write_freely_only_inside = @("living_learning_environment/sandbox")
      session_write_scope = @("living_learning_environment/reading_sessions/<session_id>","living_learning_environment/observations/<session_id>")
      forbidden_write_scope = $ForbiddenPaths
      promotion_gate_required_for_any_state_change = $true
      next_allowed_step = $NextAllowedStep
    })

    $ReusableCapabilityCount = $Capabilities.Count
    $OperationContractCount = $Operations.Count
    $TrustedSourceCount = 0
    $ResultPath = "self_control/BUILDER_MODULAR_LIVING_LEARNING_ENVIRONMENT_RESULT.json"
    $ReportPath = "reports/self_development/PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1_REPORT.json"
    $ProofPath = "proofs/self_development/PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1.json"

    $Result = [ordered]@{
      status = "PASS"
      step_id = $StepId
      previous_formal_next_step = $PreviousFormalNextStep
      route_change_request_created = $true
      capability_shelf_created = $true
      knowledge_library_created = $true
      source_registry_created = $true
      living_learning_environment_created = $true
      reusable_capability_count = $ReusableCapabilityCount
      operation_contract_count = $OperationContractCount
      trusted_source_count = $TrustedSourceCount
      external_fetch_enabled = $false
      dependency_install_allowed = $false
      executable_material_use_allowed = $false
      builder_sandbox_write_scope_defined = $true
      promotion_gate_required = $true
      codex_only_for_missing_tool_or_proven_defect = $true
      observation_first_policy = $true
      reuse_first_policy = $true
      accepted_phase_artifacts_untouched = $true
      current_runtime_artifacts_untouched = $true
      selected_next_gap = $NextAllowedStep
      selected_by = "BUILDER_RUNTIME_OR_ROUTE_CHANGE_POLICY"
      next_allowed_step = $NextAllowedStep
    }
    Write-TrackedJson -Path $ResultPath -Object $Result

    $Report = [ordered]@{
      status = "PASS"
      report_id = "PHASE148_MODULAR_LIVING_LEARNING_ENVIRONMENT_BOOTSTRAP_V1_REPORT"
      step_id = $StepId
      run_id = $RunId
      files_created = @($FilesCreated.ToArray()) + @($ReportPath, $ProofPath)
      files_read = $FilesRead
      files_protected = $ProtectedPhaseArtifacts + @(
        "runtime_sessions/builder_life_loop/current",
        "runtime_sessions/builder_life_loop/observations",
        "runtime_sessions/builder_life_loop/correction_trials",
        "runtime_sessions/builder_life_loop/adaptation_trials",
        "runtime_sessions/builder_life_loop/multi_session_trials",
        "runtime_sessions/builder_life_loop/self_correction_trials",
        "orchestrator/run.ps1",
        "route_locks",
        "generated_agents",
        "agent_catalog",
        "applied_agents"
      )
      capabilities_registered = @($Capabilities | ForEach-Object { $_.capability_id })
      operation_contracts_created = @($Operations | ForEach-Object { $_.operation_id })
      missing_infra_closed = @("capability_shelf","knowledge_library","source_registry")
      living_environment_created = $true
      route_change_reason = $RouteChangeReason
      deferred_formal_step = $PreviousFormalNextStep
      deferred_formal_step_reason = $DeferredStepReason
      remaining_risks = @(
        "The living environment is a foundation only; PHASE149 must prove Builder can read and reuse it in a bounded session.",
        "Registered capabilities are governed references and contracts, not automatic runtime permissions.",
        "External source reading remains disabled for this bootstrap; future source admission must be separately proven."
      )
      cut_list = @(
        "No orchestrator route change.",
        "No route_locks change.",
        "No accepted PHASE142-PHASE147 artifact change.",
        "No runtime_sessions/current change.",
        "No existing trial folder change.",
        "No external agents.",
        "No generated_agents, agent_catalog, or applied_agents change.",
        "No internet fetch.",
        "No dependency install.",
        "No executable material use.",
        "No trusted external source.",
        "No production adoption.",
        "No commit or push."
      )
      next_allowed_step = $NextAllowedStep
    }
    Write-TrackedJson -Path $ReportPath -Object $Report

    $Proof = [ordered]@{
      status = "PASS"
      proof_id = $StepId
      step_id = $StepId
      run_id = $RunId
      runtime_executed = $false
      bootstrap_executed = $true
      current_line = "SELF_BUILD"
      previous_accepted_head = $PreviousAcceptedHead
      previous_step = $PreviousStep
      previous_formal_next_step = $PreviousFormalNextStep
      route_change_request_created = $true
      capability_shelf_created = $true
      knowledge_library_created = $true
      source_registry_created = $true
      living_learning_environment_created = $true
      reusable_capability_count = $ReusableCapabilityCount
      operation_contract_count = $OperationContractCount
      trusted_source_count = $TrustedSourceCount
      external_fetch_performed = $false
      external_fetch_enabled = $false
      dependency_install_performed = $false
      dependency_install_allowed = $false
      executable_materials_used = $false
      executable_material_use_allowed = $false
      accepted_phase_artifacts_untouched = $true
      current_runtime_artifacts_untouched = $true
      external_agent_production_allowed = $false
      production_adoption_allowed = $false
      generated_agents_changed = $false
      agent_catalog_changed = $false
      applied_agents_changed = $false
      orchestrator_modified = $false
      route_locks_modified = $false
      queue_after = "NONE"
      route_change_reason = $RouteChangeReason
      deferred_formal_step = $PreviousFormalNextStep
      result_path = $ResultPath
      report_path = $ReportPath
      next_allowed_step = $NextAllowedStep
    }
    Write-TrackedJson -Path $ProofPath -Object $Proof

    return [pscustomobject][ordered]@{
      status = "PASS"
      step_id = $StepId
      run_id = $RunId
      route_change_request_created = $true
      capability_shelf_created = $true
      knowledge_library_created = $true
      source_registry_created = $true
      living_learning_environment_created = $true
      reusable_capability_count = $ReusableCapabilityCount
      operation_contract_count = $OperationContractCount
      trusted_source_count = $TrustedSourceCount
      external_fetch_enabled = $false
      dependency_install_allowed = $false
      executable_material_use_allowed = $false
      result_path = $ResultPath
      report_path = $ReportPath
      proof_path = $ProofPath
      next_allowed_step = $NextAllowedStep
    }
  } finally {
    Pop-Location
  }
}
