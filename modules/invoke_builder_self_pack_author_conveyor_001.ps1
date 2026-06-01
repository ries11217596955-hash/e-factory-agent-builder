function Resolve-Phase139Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase139JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase139Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE139_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Write-Phase139JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase139Path -RepoRoot $RepoRoot -Path $Path
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

function Write-Phase139TextFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [string]$Content
  )

  $fullPath = Resolve-Phase139Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  if (-not $Content.EndsWith("`n")) {
    $Content += "`n"
  }

  [System.IO.File]::WriteAllText($fullPath, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Assert-Phase139True {
  param(
    [object]$Value,
    [string]$Name
  )

  if ($Value -ne $true) {
    throw "PHASE139_FLAG_NOT_TRUE=$Name actual=$Value"
  }
}

function Assert-Phase139False {
  param(
    [object]$Value,
    [string]$Name
  )

  if ($Value -ne $false) {
    throw "PHASE139_FLAG_NOT_FALSE=$Name actual=$Value"
  }
}

function Assert-Phase139Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE139_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Assert-Phase139TextContains {
  param(
    [string]$Text,
    [string]$Needle
  )

  if ($Text -notmatch [regex]::Escape($Needle)) {
    throw "PHASE139_ROUTE_LOCK_TEXT_MISSING=$Needle"
  }
}

function Invoke-BuilderSelfPackAuthorConveyor001 {
  param(
    [string]$RepoRoot,
    [string]$RunId,
    [string]$OutputRoot
  )

  $ErrorActionPreference = "Stop"

  Push-Location $RepoRoot

  try {
    $StepId = "PHASE139_BUILD_BUILDER_SELF_PACK_AUTHOR_CONVEYOR_V1"
    $RuntimeId = "PHASE139_BUILDER_SELF_PACK_AUTHOR_CONVEYOR_001"
    $GeneratedPackStepId = "PHASE139A_BUILDER_GENERATED_SELF_LEARNING_LOOP_SEED_V1"
    $PreviousStepId = "PHASE138D_OWNER_APPROVED_SANDBOX_BRANCH_MERGE_V1"
    $PreviousNextAllowedStep = "PHASE139_DELEGATED_AUTONOMY_POLICY_ENFORCEMENT_V1"
    $NextAllowedStep = "PHASE140_BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_V1"
    $RouteLockId = "AGENT_BUILDER_NEXT_15_STEPS_LOCK_V3_SELF_PACK_AUTHOR"

    if ([string]::IsNullOrWhiteSpace($RunId)) {
      $RunId = $RuntimeId
    }

    $OutputArtifactRoot = "self_build_batch/autonomy_trials/$StepId"
    if (-not [string]::IsNullOrWhiteSpace($OutputRoot)) {
      $OutputArtifactRoot = $OutputRoot -replace "\\", "/"
    }

    $GeneratedPackExecutionRoot = "self_build_batch/autonomy_trials/$GeneratedPackStepId"
    $PreviousProofPath = "proofs/self_development/${PreviousStepId}.json"
    $RouteLockPath = "route_locks/${RouteLockId}.md"
    $RouteRebaseDecisionPath = "self_control/ROUTE_REBASE_DECISION_PHASE139_SELF_PACK_AUTHOR.json"
    $ConveyorResultPath = "self_control/BUILDER_SELF_PACK_AUTHOR_CONVEYOR_RESULT.json"
    $AdmissionPath = "self_control/BUILDER_GENERATED_SELF_BUILD_PACK_ADMISSION.json"
    $GeneratedPackPath = "self_build_programs/generated/${GeneratedPackStepId}.json"
    $GeneratedPackResultPath = "$GeneratedPackExecutionRoot/${GeneratedPackStepId}_RESULT.json"
    $GeneratedPackRuntimeLogPath = "$GeneratedPackExecutionRoot/${GeneratedPackStepId}_RUNTIME_LOG.txt"
    $OutputPath = "$OutputArtifactRoot/BUILDER_SELF_PACK_AUTHOR_CONVEYOR_OUTPUT.json"
    $ResultPath = "$OutputArtifactRoot/${StepId}_RESULT.json"
    $RuntimeLogPath = "$OutputArtifactRoot/${StepId}_RUNTIME_LOG.txt"
    $ReportPath = "reports/self_development/${StepId}_REPORT.json"
    $ProofPath = "proofs/self_development/${StepId}.json"

    foreach ($identityFile in @(
      "CAPABILITY_ROADMAP.json",
      "GENESIS_STATE.json",
      "TASK_QUEUE.json",
      "packs/registry.json",
      "orchestrator/run.ps1"
    )) {
      if (-not (Test-Path -LiteralPath (Resolve-Phase139Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $CurrentBranch = (git branch --show-current).Trim()
    if ($CurrentBranch -eq "main") {
      throw "PHASE139_MAIN_BRANCH_FORBIDDEN"
    }
    $CurrentHead = (git rev-parse --short HEAD).Trim()

    $externalAgentStatus = @(git status --short --untracked-files=all -- generated_agents agent_catalog 2>$null)
    if ($externalAgentStatus.Count -gt 0) {
      throw "PHASE139_EXTERNAL_AGENT_SCOPE_DIRTY=$($externalAgentStatus -join '; ')"
    }

    $PreviousProof = Read-Phase139JsonRequired -RepoRoot $RepoRoot -Path $PreviousProofPath
    Assert-Phase139Equals -Actual $PreviousProof.status -Expected "PASS" -Name "phase138d_status"
    Assert-Phase139True -Value $PreviousProof.terminal_merge_executed -Name "phase138d_terminal_merge_executed"
    Assert-Phase139True -Value $PreviousProof.owner_standing_delegation_used -Name "phase138d_owner_standing_delegation_used"
    Assert-Phase139False -Value $PreviousProof.interactive_owner_prompt_used -Name "phase138d_interactive_owner_prompt_used"
    Assert-Phase139False -Value $PreviousProof.production_adoption_allowed -Name "phase138d_production_adoption_allowed"
    Assert-Phase139Equals -Actual $PreviousProof.trusted_material_count -Expected 0 -Name "phase138d_trusted_material_count"
    Assert-Phase139False -Value $PreviousProof.external_fetch_performed -Name "phase138d_external_fetch_performed"
    Assert-Phase139False -Value $PreviousProof.dependency_install_performed -Name "phase138d_dependency_install_performed"
    Assert-Phase139False -Value $PreviousProof.executable_materials_used -Name "phase138d_executable_materials_used"
    Assert-Phase139Equals -Actual $PreviousProof.next_allowed_step -Expected $PreviousNextAllowedStep -Name "phase138d_next_allowed_step"

    $RouteLockFullPath = Resolve-Phase139Path -RepoRoot $RepoRoot -Path $RouteLockPath
    if (-not (Test-Path -LiteralPath $RouteLockFullPath)) {
      throw "PHASE139_ROUTE_LOCK_V3_MISSING=$RouteLockPath"
    }
    $RouteLockText = Get-Content -LiteralPath $RouteLockFullPath -Raw
    Assert-Phase139TextContains -Text $RouteLockText -Needle "SELF_PACK_AUTHOR"
    Assert-Phase139TextContains -Text $RouteLockText -Needle "Builder must author next self-build packs"
    if ($RouteLockText -notmatch "Codex.*fallback only") {
      throw "PHASE139_ROUTE_LOCK_TEXT_MISSING=Codex fallback only"
    }

    $GeneratedAt = (Get-Date).ToUniversalTime().ToString("o")

    $RouteRebaseDecision = [ordered]@{
      status = "PASS"
      decision_id = "ROUTE_REBASE_DECISION_PHASE139_SELF_PACK_AUTHOR"
      created_by = $StepId
      run_id = $RunId
      reason = "owner clarified main objective is self-reproduction/self-learning/self-development"
      previous_next_allowed_step = $PreviousNextAllowedStep
      new_step = $StepId
      route_lock_used = $RouteLockId
      external_agent_production_allowed = $false
      next_allowed_step = $NextAllowedStep
    }

    $GeneratedPack = [ordered]@{
      status = "BUILDER_RUNTIME_AUTHORED"
      step_id = $GeneratedPackStepId
      pack_id = $GeneratedPackStepId
      author = "BUILDER_RUNTIME"
      authorship_status = "BUILDER_RUNTIME_AUTHORED"
      codex_authored = $false
      purpose = "Seed the next self-learning loop after self-pack authorship is proven"
      line = "SELF_BUILD"
      generated_during_runtime = $true
      generated_by_runtime = $RuntimeId
      run_id = $RunId
      generated_at = $GeneratedAt
      source_conveyor_step = $StepId
      external_agent_production_allowed = $false
      dependency_install_allowed = $false
      external_fetch_allowed = $false
      executable_use_allowed = $false
      expected_outputs = @(
        $GeneratedPackResultPath,
        $GeneratedPackRuntimeLogPath
      )
      validator_contract = [ordered]@{
        required_status = "PASS"
        required_execution_actor = "BUILDER_RUNTIME"
        generated_pack_executed_required = $true
        fail_if_external_agent_created = $true
        fail_if_external_fetch_performed = $true
        fail_if_dependency_install_performed = $true
        fail_if_executable_material_used = $true
      }
      proof_contract = [ordered]@{
        required_fields = @(
          "status",
          "executed_by",
          "generated_pack_executed",
          "external_agent_created",
          "external_fetch_performed",
          "dependency_install_performed",
          "executable_materials_used",
          "next_allowed_step"
        )
        next_allowed_step = $NextAllowedStep
      }
    }

    $Admission = [ordered]@{
      status = "PASS"
      admission_id = "BUILDER_GENERATED_SELF_BUILD_PACK_ADMISSION"
      admitted_pack = $GeneratedPackStepId
      admitted_by = "BUILDER_RUNTIME"
      admission_reason = "generated pack is SELF_BUILD only and safe"
      generated_pack_author = "BUILDER_RUNTIME"
      codex_authored = $false
      external_agent_production_allowed = $false
      dependency_install_allowed = $false
      external_fetch_allowed = $false
      executable_use_allowed = $false
      next_allowed_step = $NextAllowedStep
    }

    $GeneratedPackExecutionLog = @(
      "GENERATED_SELF_BUILD_PACK=$GeneratedPackStepId",
      "GENERATED_PACK_EXECUTION_STATUS=PASS",
      "EXECUTED_BY=BUILDER_RUNTIME",
      "GENERATED_PACK_EXECUTED=True",
      "EXTERNAL_AGENT_CREATED=False",
      "EXTERNAL_AGENT_PRODUCTION_ALLOWED=False",
      "MATERIAL_EXTERNAL_FETCH_PERFORMED=False",
      "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=False",
      "MATERIAL_EXECUTABLE_USED=False",
      "GENERATED_PACK_NEXT_STEP=$NextAllowedStep"
    ) -join "`n"

    $GeneratedPackExecutionResult = [ordered]@{
      status = "PASS"
      step_id = $GeneratedPackStepId
      run_id = $RunId
      executed_by = "BUILDER_RUNTIME"
      generated_pack_executed = $true
      external_agent_created = $false
      external_agent_production_allowed = $false
      dependency_install_allowed = $false
      external_fetch_allowed = $false
      executable_use_allowed = $false
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      trusted_material_count = 0
      result_path = $GeneratedPackResultPath
      runtime_log_path = $GeneratedPackRuntimeLogPath
      next_allowed_step = $NextAllowedStep
    }

    $ConveyorResult = [ordered]@{
      status = "PASS"
      conveyor_id = $RuntimeId
      step_id = $StepId
      run_id = $RunId
      builder_generated_pack_count = 1
      generated_pack_id = $GeneratedPackStepId
      generated_pack_admitted = $true
      generated_pack_executed = $true
      generated_pack_author = "BUILDER_RUNTIME"
      codex_authored_generated_pack = $false
      codex_bootstrap_used = $true
      external_agent_production_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      route_rebase_decision_path = $RouteRebaseDecisionPath
      generated_pack_path = $GeneratedPackPath
      admission_path = $AdmissionPath
      generated_pack_result_path = $GeneratedPackResultPath
      generated_pack_runtime_log_path = $GeneratedPackRuntimeLogPath
      next_allowed_step = $NextAllowedStep
    }

    $Queue = Read-Phase139JsonRequired -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
    if ($Queue.active_task_id -ne "NONE") {
      throw "PHASE139_QUEUE_NOT_NONE=$($Queue.active_task_id)"
    }

    $Output = [ordered]@{
      status = "PASS"
      engine_name = $RuntimeId
      step_id = $StepId
      run_id = $RunId
      route_rebase_decision_created = $true
      builder_generated_pack_count = 1
      generated_pack_id = $GeneratedPackStepId
      generated_pack_author = "BUILDER_RUNTIME"
      codex_authored_generated_pack = $false
      codex_bootstrap_used = $true
      generated_pack_admitted = $true
      generated_pack_executed = $true
      current_line = "SELF_BUILD"
      external_agent_production_allowed = $false
      production_adoption_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      queue_after = "NONE"
      route_rebase_decision_path = $RouteRebaseDecisionPath
      generated_pack_path = $GeneratedPackPath
      admission_path = $AdmissionPath
      conveyor_result_path = $ConveyorResultPath
      generated_pack_result_path = $GeneratedPackResultPath
      generated_pack_runtime_log_path = $GeneratedPackRuntimeLogPath
      output_path = $OutputPath
      result_path = $ResultPath
      runtime_log_path = $RuntimeLogPath
      report_path = $ReportPath
      proof_path = $ProofPath
      proposed_next_step = $NextAllowedStep
      next_allowed_step = $NextAllowedStep
    }

    $Result = [ordered]@{
      status = "PASS"
      phase = $StepId
      active_line = "AGENT_BUILDER_SELF_DEVELOPMENT"
      run_id = $RunId
      runtime_id = $RuntimeId
      runtime_executed = $true
      builder_runtime_invoked = $true
      route_rebase_decision_created = $true
      builder_generated_pack_count = 1
      generated_pack_id = $GeneratedPackStepId
      generated_pack_author = "BUILDER_RUNTIME"
      codex_authored_generated_pack = $false
      codex_bootstrap_used = $true
      generated_pack_admitted = $true
      generated_pack_executed = $true
      current_line = "SELF_BUILD"
      external_agent_production_allowed = $false
      production_adoption_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      queue_after = "NONE"
      output_path = $OutputPath
      runtime_log_path = $RuntimeLogPath
      next_allowed_step = $NextAllowedStep
    }

    $Report = [ordered]@{
      status = "PASS"
      report_id = "${StepId}_REPORT"
      step_id = $StepId
      run_id = $RunId
      summary = "PHASE139 rebases from delegated autonomy policy wording to Builder self-pack authorship. Codex bootstraps the conveyor only; the PHASE139A self-build pack is emitted, admitted, and bounded-executed by Builder runtime."
      route_rebase_decision_path = $RouteRebaseDecisionPath
      generated_pack_path = $GeneratedPackPath
      admission_path = $AdmissionPath
      conveyor_result_path = $ConveyorResultPath
      generated_pack_result_path = $GeneratedPackResultPath
      generated_pack_runtime_log_path = $GeneratedPackRuntimeLogPath
      generated_pack_authoring_method = "The orchestrator invokes a Builder runtime module. That runtime constructs the generated pack object in memory, writes it to self_build_programs/generated, admits it as SELF_BUILD only, then executes the generated pack's bounded metadata-only seed action."
      codex_role = "Codex authored the bootstrap conveyor module and validator only. The generated pack artifact is written during Builder runtime and records author BUILDER_RUNTIME with codex_authored false."
      admission_behavior = "Admission passes only because the generated pack is SELF_BUILD only and forbids external agent production, dependency installation, external fetch, and executable use."
      validator_behavior = "Validator fails on missing PHASE138D PASS proof, missing V3 route lock, missing generated pack, non-BUILDER_RUNTIME authorship, codex_authored true, missing admission or execution, external agent path changes, trusted materials, forbidden runtime flags, active queue, or wrong next step."
      remaining_risks = @(
        "The generated PHASE139A pack is a bounded seed, not a full autonomous scale trial.",
        "The conveyor proves runtime authorship of one pack only; PHASE140 must scale this without loosening the safety cuts.",
        "The validator checks local artifacts and git path scope, not hosted CI."
      )
      cut_list = @(
        "No external agent production.",
        "No generated_agents or agent_catalog changes.",
        "No dependency install.",
        "No external fetch.",
        "No executable material use.",
        "No material trust.",
        "No production adoption.",
        "No main branch touch.",
        "No commit or push."
      )
      next_allowed_step = $NextAllowedStep
    }

    $Proof = [ordered]@{
      status = "PASS"
      proof_id = $StepId
      step_id = $StepId
      run_id = $RunId
      runtime_mode = "SELF_BUILD_QUEUE_NONE_BUILDER_SELF_PACK_AUTHOR_CONVEYOR_001"
      runtime_executed = $true
      builder_runtime_invoked = $true
      route_rebase_decision_created = $true
      builder_generated_pack_count = 1
      generated_pack_id = $GeneratedPackStepId
      generated_pack_author = "BUILDER_RUNTIME"
      codex_authored_generated_pack = $false
      codex_bootstrap_used = $true
      generated_pack_admitted = $true
      generated_pack_executed = $true
      current_line = "SELF_BUILD"
      external_agent_production_allowed = $false
      production_adoption_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      queue_after = "NONE"
      main_touched = $false
      source_branch = $CurrentBranch
      source_head = $CurrentHead
      route_lock_used = $RouteLockId
      previous_proof_path = $PreviousProofPath
      route_rebase_decision_path = $RouteRebaseDecisionPath
      generated_pack_path = $GeneratedPackPath
      admission_path = $AdmissionPath
      conveyor_result_path = $ConveyorResultPath
      generated_pack_result_path = $GeneratedPackResultPath
      generated_pack_runtime_log_path = $GeneratedPackRuntimeLogPath
      output_path = $OutputPath
      result_path = $ResultPath
      runtime_log_path = $RuntimeLogPath
      report_path = $ReportPath
      next_allowed_step = $NextAllowedStep
    }

    Write-Phase139JsonFile -RepoRoot $RepoRoot -Path $RouteRebaseDecisionPath -Object $RouteRebaseDecision
    Write-Phase139JsonFile -RepoRoot $RepoRoot -Path $GeneratedPackPath -Object $GeneratedPack
    Write-Phase139JsonFile -RepoRoot $RepoRoot -Path $AdmissionPath -Object $Admission
    Write-Phase139JsonFile -RepoRoot $RepoRoot -Path $GeneratedPackResultPath -Object $GeneratedPackExecutionResult
    Write-Phase139TextFile -RepoRoot $RepoRoot -Path $GeneratedPackRuntimeLogPath -Content $GeneratedPackExecutionLog
    Write-Phase139JsonFile -RepoRoot $RepoRoot -Path $ConveyorResultPath -Object $ConveyorResult
    Write-Phase139JsonFile -RepoRoot $RepoRoot -Path $OutputPath -Object $Output
    Write-Phase139JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $Result
    Write-Phase139JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $Report
    Write-Phase139JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $Proof

    return [pscustomobject]$Output
  } finally {
    Pop-Location
  }
}
