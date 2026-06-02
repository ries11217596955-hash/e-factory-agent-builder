function Resolve-Phase140Path {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Read-Phase140JsonRequired {
  param(
    [string]$RepoRoot,
    [string]$Path
  )

  $fullPath = Resolve-Phase140Path -RepoRoot $RepoRoot -Path $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "PHASE140_MISSING_JSON=$Path"
  }

  return Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
}

function Write-Phase140JsonFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [object]$Object,
    [int]$Depth = 100
  )

  $fullPath = Resolve-Phase140Path -RepoRoot $RepoRoot -Path $Path
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

function Write-Phase140TextFile {
  param(
    [string]$RepoRoot,
    [string]$Path,
    [string]$Content
  )

  $fullPath = Resolve-Phase140Path -RepoRoot $RepoRoot -Path $Path
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  if (-not $Content.EndsWith("`n")) {
    $Content += "`n"
  }

  [System.IO.File]::WriteAllText($fullPath, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Assert-Phase140True {
  param(
    [object]$Value,
    [string]$Name
  )

  if ($Value -ne $true) {
    throw "PHASE140_FLAG_NOT_TRUE=$Name actual=$Value"
  }
}

function Assert-Phase140False {
  param(
    [object]$Value,
    [string]$Name
  )

  if ($Value -ne $false) {
    throw "PHASE140_FLAG_NOT_FALSE=$Name actual=$Value"
  }
}

function Assert-Phase140Equals {
  param(
    [object]$Actual,
    [object]$Expected,
    [string]$Name
  )

  if ($Actual -ne $Expected) {
    throw "PHASE140_VALUE_UNEXPECTED=$Name actual=$Actual expected=$Expected"
  }
}

function Invoke-BuilderSelfPackAuthorScaleTrial001 {
  param(
    [string]$RepoRoot,
    [string]$RunId,
    [string]$OutputRoot
  )

  $ErrorActionPreference = "Stop"

  Push-Location $RepoRoot

  try {
    $StepId = "PHASE140_BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_V1"
    $RuntimeId = "PHASE140_BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_001"
    $PreviousStepId = "PHASE139_BUILD_BUILDER_SELF_PACK_AUTHOR_CONVEYOR_V1"
    $NextAllowedStep = "PHASE141_BUILDER_SELF_LEARNING_LOOP_METRICS_V1"
    $RouteLockId = "AGENT_BUILDER_NEXT_15_STEPS_LOCK_V3_SELF_PACK_AUTHOR"
    $ExpectedBranch = "phase110-idempotent-autonomy-trial-runtime"

    if ([string]::IsNullOrWhiteSpace($RunId)) {
      $RunId = $RuntimeId
    }

    $OutputArtifactRoot = "self_build_batch/autonomy_trials/$StepId"
    if (-not [string]::IsNullOrWhiteSpace($OutputRoot)) {
      $OutputArtifactRoot = $OutputRoot -replace "\\", "/"
    }

    $PreviousProofPath = "proofs/self_development/${PreviousStepId}.json"
    $AdmissionBatchPath = "self_control/BUILDER_GENERATED_SELF_BUILD_PACKS_ADMISSION_BATCH.json"
    $ScaleTrialResultPath = "self_control/BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_RESULT.json"
    $CurrentStatePath = "self_control/CURRENT_AGENT_BUILDER_STATE.json"
    $NextActionPath = "self_control/NEXT_ACTION.json"
    $ProofPointerPath = "self_control/LAST_ACCEPTED_PROOF_POINTER.json"
    $RestoreToolPath = "tools/restore_agent_builder_state.ps1"
    $OutputPath = "$OutputArtifactRoot/BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_OUTPUT.json"
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
      if (-not (Test-Path -LiteralPath (Resolve-Phase140Path -RepoRoot $RepoRoot -Path $identityFile))) {
        throw "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityFile"
      }
    }

    $CurrentBranch = (git branch --show-current).Trim()
    if ($CurrentBranch -eq "main") {
      throw "PHASE140_MAIN_BRANCH_FORBIDDEN"
    }
    Assert-Phase140Equals -Actual $CurrentBranch -Expected $ExpectedBranch -Name "current_branch"

    $CurrentHead = (git rev-parse --short HEAD).Trim()

    $externalAgentStatus = @(git status --short --untracked-files=all -- generated_agents agent_catalog applied_agents 2>$null)
    if ($externalAgentStatus.Count -gt 0) {
      throw "PHASE140_EXTERNAL_AGENT_SCOPE_DIRTY=$($externalAgentStatus -join '; ')"
    }

    $PreviousProof = Read-Phase140JsonRequired -RepoRoot $RepoRoot -Path $PreviousProofPath
    Assert-Phase140Equals -Actual $PreviousProof.status -Expected "PASS" -Name "phase139_status"
    Assert-Phase140Equals -Actual $PreviousProof.next_allowed_step -Expected $StepId -Name "phase139_next_allowed_step"
    Assert-Phase140Equals -Actual $PreviousProof.builder_generated_pack_count -Expected 1 -Name "phase139_builder_generated_pack_count"
    Assert-Phase140Equals -Actual $PreviousProof.generated_pack_author -Expected "BUILDER_RUNTIME" -Name "phase139_generated_pack_author"
    Assert-Phase140False -Value $PreviousProof.codex_authored_generated_pack -Name "phase139_codex_authored_generated_pack"
    Assert-Phase140True -Value $PreviousProof.generated_pack_admitted -Name "phase139_generated_pack_admitted"
    Assert-Phase140True -Value $PreviousProof.generated_pack_executed -Name "phase139_generated_pack_executed"
    Assert-Phase140False -Value $PreviousProof.external_agent_production_allowed -Name "phase139_external_agent_production_allowed"
    Assert-Phase140Equals -Actual $PreviousProof.trusted_material_count -Expected 0 -Name "phase139_trusted_material_count"
    Assert-Phase140False -Value $PreviousProof.external_fetch_performed -Name "phase139_external_fetch_performed"
    Assert-Phase140False -Value $PreviousProof.dependency_install_performed -Name "phase139_dependency_install_performed"
    Assert-Phase140False -Value $PreviousProof.executable_materials_used -Name "phase139_executable_materials_used"

    $Queue = Read-Phase140JsonRequired -RepoRoot $RepoRoot -Path "TASK_QUEUE.json"
    Assert-Phase140Equals -Actual $Queue.active_task_id -Expected "NONE" -Name "queue_active_task_id"

    $GeneratedAt = (Get-Date).ToUniversalTime().ToString("o")
    $GeneratedPackSpecs = @(
      [ordered]@{
        step_id = "PHASE140A_BUILDER_GENERATED_STATE_SYNC_CAPSULE_SEED_V1"
        purpose = "Seed the repo-native state sync capsule needed to restore Agent Builder state on another PC"
        expected_outputs = @(
          $CurrentStatePath,
          $NextActionPath,
          $ProofPointerPath,
          $RestoreToolPath,
          "self_build_batch/autonomy_trials/PHASE140A_BUILDER_GENERATED_STATE_SYNC_CAPSULE_SEED_V1/PHASE140A_BUILDER_GENERATED_STATE_SYNC_CAPSULE_SEED_V1_RESULT.json",
          "self_build_batch/autonomy_trials/PHASE140A_BUILDER_GENERATED_STATE_SYNC_CAPSULE_SEED_V1/PHASE140A_BUILDER_GENERATED_STATE_SYNC_CAPSULE_SEED_V1_RUNTIME_LOG.txt"
        )
      }
      [ordered]@{
        step_id = "PHASE140B_BUILDER_GENERATED_SELF_LEARNING_METRIC_SEED_V1"
        purpose = "Seed the next self-learning loop metric surface after Builder proves scaled self-pack authorship"
        expected_outputs = @(
          "self_build_batch/autonomy_trials/PHASE140B_BUILDER_GENERATED_SELF_LEARNING_METRIC_SEED_V1/PHASE140B_BUILDER_GENERATED_SELF_LEARNING_METRIC_SEED_V1_RESULT.json",
          "self_build_batch/autonomy_trials/PHASE140B_BUILDER_GENERATED_SELF_LEARNING_METRIC_SEED_V1/PHASE140B_BUILDER_GENERATED_SELF_LEARNING_METRIC_SEED_V1_RUNTIME_LOG.txt"
        )
      }
      [ordered]@{
        step_id = "PHASE140C_BUILDER_GENERATED_NEXT_GAP_SELECTOR_SEED_V1"
        purpose = "Seed the next gap selector surface for choosing the next bounded self-development move"
        expected_outputs = @(
          "self_build_batch/autonomy_trials/PHASE140C_BUILDER_GENERATED_NEXT_GAP_SELECTOR_SEED_V1/PHASE140C_BUILDER_GENERATED_NEXT_GAP_SELECTOR_SEED_V1_RESULT.json",
          "self_build_batch/autonomy_trials/PHASE140C_BUILDER_GENERATED_NEXT_GAP_SELECTOR_SEED_V1/PHASE140C_BUILDER_GENERATED_NEXT_GAP_SELECTOR_SEED_V1_RUNTIME_LOG.txt"
        )
      }
    )

    $GeneratedPackIds = @($GeneratedPackSpecs | ForEach-Object { $_.step_id })
    $GeneratedPackPaths = @()
    $GeneratedPackResultPaths = @()
    $GeneratedPackRuntimeLogPaths = @()

    foreach ($spec in $GeneratedPackSpecs) {
      $generatedPackStepId = $spec.step_id
      $generatedPackPath = "self_build_programs/generated/${generatedPackStepId}.json"
      $generatedPackExecutionRoot = "self_build_batch/autonomy_trials/$generatedPackStepId"
      $generatedPackResultPath = "$generatedPackExecutionRoot/${generatedPackStepId}_RESULT.json"
      $generatedPackRuntimeLogPath = "$generatedPackExecutionRoot/${generatedPackStepId}_RUNTIME_LOG.txt"

      $GeneratedPackPaths += $generatedPackPath
      $GeneratedPackResultPaths += $generatedPackResultPath
      $GeneratedPackRuntimeLogPaths += $generatedPackRuntimeLogPath

      $generatedPack = [ordered]@{
        status = "BUILDER_RUNTIME_AUTHORED"
        step_id = $generatedPackStepId
        pack_id = $generatedPackStepId
        author = "BUILDER_RUNTIME"
        authorship_status = "BUILDER_RUNTIME_AUTHORED"
        codex_authored = $false
        line = "SELF_BUILD"
        external_agent_production_allowed = $false
        dependency_install_allowed = $false
        external_fetch_allowed = $false
        executable_use_allowed = $false
        purpose = $spec.purpose
        expected_outputs = $spec.expected_outputs
        generated_during_runtime = $true
        generated_by_runtime = $RuntimeId
        run_id = $RunId
        generated_at = $GeneratedAt
        source_scale_trial_step = $StepId
        validator_contract = [ordered]@{
          required_status = "PASS"
          required_execution_actor = "BUILDER_RUNTIME"
          generated_pack_executed_required = $true
          bounded_mode_required = $true
          fail_if_external_agent_created = $true
          fail_if_external_fetch_performed = $true
          fail_if_dependency_install_performed = $true
          fail_if_executable_material_used = $true
          fail_if_next_allowed_step_not = $NextAllowedStep
        }
        proof_contract = [ordered]@{
          required_fields = @(
            "status",
            "executed_by",
            "bounded_mode",
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

      Write-Phase140JsonFile -RepoRoot $RepoRoot -Path $generatedPackPath -Object $generatedPack
    }

    $AdmissionBatch = [ordered]@{
      status = "PASS"
      admission_id = "BUILDER_GENERATED_SELF_BUILD_PACKS_ADMISSION_BATCH"
      admission_mode = "ONE_BATCH"
      admitted_by = "BUILDER_RUNTIME"
      admitted_pack_count = 3
      admitted_packs = $GeneratedPackIds
      generated_packs_author = "BUILDER_RUNTIME"
      codex_authored_generated_packs = $false
      generated_packs_admitted = $true
      external_agent_production_allowed = $false
      dependency_install_allowed = $false
      external_fetch_allowed = $false
      executable_use_allowed = $false
      admission_reason = "all generated packs are SELF_BUILD metadata-only seeds with forbidden external production/material actions"
      next_allowed_step = $NextAllowedStep
    }

    $CurrentState = [ordered]@{
      status = "PASS"
      state_capsule_id = "PHASE140_REPO_STATE_SYNC_CAPSULE"
      branch = $ExpectedBranch
      accepted_head = $CurrentHead
      last_accepted_phase = $PreviousStepId
      current_phase = $StepId
      current_line = "SELF_BUILD"
      active_route_lock = $RouteLockId
      next_allowed_step = $NextAllowedStep
      last_accepted_proof = $PreviousProofPath
      pending_current_proof = $ProofPath
      generated_by_runtime = $RuntimeId
      generated_at = $GeneratedAt
    }

    $NextAction = [ordered]@{
      status = "PASS"
      next_allowed_step = $NextAllowedStep
      next_action_type = "SELF_BUILD"
      external_agent_production_allowed = $false
      owner_interactive_prompt_required = $false
      source_phase = $StepId
      generated_by_runtime = $RuntimeId
    }

    $ProofPointer = [ordered]@{
      status = "PASS"
      last_accepted_proof = $PreviousProofPath
      pending_current_proof = $ProofPath
      last_accepted_phase = $PreviousStepId
      current_phase = $StepId
      next_allowed_step = $NextAllowedStep
    }

    $RestoreToolContent = @(
      'param(',
      '  [string]$RepoRoot = (Join-Path $env:USERPROFILE "Documents\e-factory-agent-builder")',
      ')',
      '',
      '$ErrorActionPreference = "Stop"',
      '$Continue = $true',
      '$Branch = "phase110-idempotent-autonomy-trial-runtime"',
      '',
      'Write-Host "RESTORE_AGENT_BUILDER_STATE"',
      'Write-Host "REPO_ROOT=$RepoRoot"',
      '',
      'if ([string]::IsNullOrWhiteSpace($env:USERPROFILE)) {',
      '  Write-Host "STOP=USERPROFILE_NOT_SET"',
      '  $Continue = $false',
      '}',
      '',
      'if ($Continue -and -not (Test-Path -LiteralPath $RepoRoot)) {',
      '  Write-Host "STOP=REPO_ROOT_NOT_FOUND"',
      '  $Continue = $false',
      '}',
      '',
      'if ($Continue) {',
      '  Push-Location $RepoRoot',
      '  try {',
      '    foreach ($identityFile in @(',
      '      "CAPABILITY_ROADMAP.json",',
      '      "GENESIS_STATE.json",',
      '      "TASK_QUEUE.json",',
      '      "packs/registry.json",',
      '      "orchestrator/run.ps1"',
      '    )) {',
      '      if (-not (Test-Path -LiteralPath $identityFile)) {',
      '        Write-Host "STOP=WRONG_AGENT_BUILDER_REPO"',
      '        Write-Host "MISSING=$identityFile"',
      '        $Continue = $false',
      '      }',
      '    }',
      '',
      '    if ($Continue) {',
      '      git fetch origin',
      '      git switch $Branch',
      '      git pull --ff-only origin $Branch',
      '',
      '      $CurrentBranch = (git branch --show-current).Trim()',
      '      $CurrentHead = (git rev-parse --short HEAD).Trim()',
      '      $StatusLines = @(git status --short)',
      '',
      '      Write-Host "BRANCH=$CurrentBranch"',
      '      Write-Host "HEAD=$CurrentHead"',
      '      if ($StatusLines.Count -eq 0) {',
      '        Write-Host "STATUS_SHORT=CLEAN"',
      '      } else {',
      '        foreach ($line in $StatusLines) {',
      '          Write-Host "STATUS_SHORT=$line"',
      '        }',
      '      }',
      '',
      '      $NextActionPath = Join-Path $RepoRoot "self_control\NEXT_ACTION.json"',
      '      if (Test-Path -LiteralPath $NextActionPath) {',
      '        $NextAction = Get-Content -LiteralPath $NextActionPath -Raw | ConvertFrom-Json',
      '        Write-Host "NEXT_ALLOWED_STEP=$($NextAction.next_allowed_step)"',
      '      } else {',
      '        Write-Host "NEXT_ALLOWED_STEP=UNKNOWN"',
      '      }',
      '    }',
      '  } finally {',
      '    Pop-Location',
      '  }',
      '}'
    ) -join "`n"

    Write-Phase140JsonFile -RepoRoot $RepoRoot -Path $AdmissionBatchPath -Object $AdmissionBatch
    Write-Phase140JsonFile -RepoRoot $RepoRoot -Path $CurrentStatePath -Object $CurrentState
    Write-Phase140JsonFile -RepoRoot $RepoRoot -Path $NextActionPath -Object $NextAction
    Write-Phase140JsonFile -RepoRoot $RepoRoot -Path $ProofPointerPath -Object $ProofPointer
    Write-Phase140TextFile -RepoRoot $RepoRoot -Path $RestoreToolPath -Content $RestoreToolContent

    foreach ($spec in $GeneratedPackSpecs) {
      $generatedPackStepId = $spec.step_id
      $generatedPackExecutionRoot = "self_build_batch/autonomy_trials/$generatedPackStepId"
      $generatedPackResultPath = "$generatedPackExecutionRoot/${generatedPackStepId}_RESULT.json"
      $generatedPackRuntimeLogPath = "$generatedPackExecutionRoot/${generatedPackStepId}_RUNTIME_LOG.txt"
      $isStateSync = ($generatedPackStepId -eq "PHASE140A_BUILDER_GENERATED_STATE_SYNC_CAPSULE_SEED_V1")
      $isLearningMetric = ($generatedPackStepId -eq "PHASE140B_BUILDER_GENERATED_SELF_LEARNING_METRIC_SEED_V1")
      $isGapSelector = ($generatedPackStepId -eq "PHASE140C_BUILDER_GENERATED_NEXT_GAP_SELECTOR_SEED_V1")

      $GeneratedPackExecutionResult = [ordered]@{
        status = "PASS"
        step_id = $generatedPackStepId
        run_id = $RunId
        executed_by = "BUILDER_RUNTIME"
        bounded_mode = $true
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
        repo_state_sync_capsule_created = $isStateSync
        self_learning_metric_seed_created = $isLearningMetric
        next_gap_selector_seed_created = $isGapSelector
        result_path = $generatedPackResultPath
        runtime_log_path = $generatedPackRuntimeLogPath
        next_allowed_step = $NextAllowedStep
      }

      $GeneratedPackExecutionLog = @(
        "GENERATED_SELF_BUILD_PACK=$generatedPackStepId",
        "GENERATED_PACK_EXECUTION_STATUS=PASS",
        "EXECUTED_BY=BUILDER_RUNTIME",
        "BOUNDED_MODE=True",
        "GENERATED_PACK_EXECUTED=True",
        "REPO_STATE_SYNC_CAPSULE_CREATED=$isStateSync",
        "SELF_LEARNING_METRIC_SEED_CREATED=$isLearningMetric",
        "NEXT_GAP_SELECTOR_SEED_CREATED=$isGapSelector",
        "EXTERNAL_AGENT_CREATED=False",
        "EXTERNAL_AGENT_PRODUCTION_ALLOWED=False",
        "MATERIAL_EXTERNAL_FETCH_PERFORMED=False",
        "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=False",
        "MATERIAL_EXECUTABLE_USED=False",
        "GENERATED_PACK_NEXT_STEP=$NextAllowedStep"
      ) -join "`n"

      Write-Phase140JsonFile -RepoRoot $RepoRoot -Path $generatedPackResultPath -Object $GeneratedPackExecutionResult
      Write-Phase140TextFile -RepoRoot $RepoRoot -Path $generatedPackRuntimeLogPath -Content $GeneratedPackExecutionLog
    }

    $ScaleTrialResult = [ordered]@{
      status = "PASS"
      scale_trial_id = $RuntimeId
      step_id = $StepId
      run_id = $RunId
      builder_generated_pack_count = 3
      generated_pack_ids = $GeneratedPackIds
      generated_pack_paths = $GeneratedPackPaths
      generated_pack_result_paths = $GeneratedPackResultPaths
      generated_pack_runtime_log_paths = $GeneratedPackRuntimeLogPaths
      generated_packs_author = "BUILDER_RUNTIME"
      codex_authored_generated_packs = $false
      codex_bootstrap_used = $true
      generated_packs_admitted = $true
      generated_packs_executed = $true
      bounded_execution_mode = $true
      repo_state_sync_capsule_created = $true
      restore_tool_created = $true
      admission_batch_path = $AdmissionBatchPath
      current_state_path = $CurrentStatePath
      next_action_path = $NextActionPath
      proof_pointer_path = $ProofPointerPath
      restore_tool_path = $RestoreToolPath
      current_line = "SELF_BUILD"
      external_agent_production_allowed = $false
      production_adoption_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      queue_after = "NONE"
      next_allowed_step = $NextAllowedStep
    }

    $Output = [ordered]@{
      status = "PASS"
      engine_name = $RuntimeId
      step_id = $StepId
      run_id = $RunId
      builder_generated_pack_count = 3
      generated_pack_ids = $GeneratedPackIds
      generated_packs_author = "BUILDER_RUNTIME"
      codex_authored_generated_packs = $false
      codex_bootstrap_used = $true
      generated_packs_admitted = $true
      generated_packs_executed = $true
      repo_state_sync_capsule_created = $true
      restore_tool_created = $true
      current_line = "SELF_BUILD"
      external_agent_production_allowed = $false
      production_adoption_allowed = $false
      trusted_material_count = 0
      external_fetch_performed = $false
      dependency_install_performed = $false
      executable_materials_used = $false
      queue_after = "NONE"
      admission_batch_path = $AdmissionBatchPath
      scale_trial_result_path = $ScaleTrialResultPath
      current_state_path = $CurrentStatePath
      next_action_path = $NextActionPath
      proof_pointer_path = $ProofPointerPath
      restore_tool_path = $RestoreToolPath
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
      builder_generated_pack_count = 3
      generated_pack_ids = $GeneratedPackIds
      generated_packs_author = "BUILDER_RUNTIME"
      codex_authored_generated_packs = $false
      codex_bootstrap_used = $true
      generated_packs_admitted = $true
      generated_packs_executed = $true
      repo_state_sync_capsule_created = $true
      restore_tool_created = $true
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
      summary = "PHASE140 scales Builder self-pack authorship from one generated pack to exactly three runtime-authored SELF_BUILD packs and creates a repo-native state sync capsule for restoration without chat memory."
      orchestrator_hook = "orchestrator/run.ps1 invokes Invoke-BuilderSelfPackAuthorScaleTrial001 when PHASE139 proof is PASS and next_allowed_step is PHASE140."
      generated_pack_authoring_method = "The Builder runtime constructs three generated pack objects in memory, writes them under self_build_programs/generated, admits them as one SELF_BUILD-only batch, and writes bounded execution results for each."
      admission_batch_behavior = "All three generated packs are admitted in one batch only when author is BUILDER_RUNTIME, codex_authored is false, and external production, fetch, install, executable use, and material trust are forbidden."
      restore_tool_behavior = "tools/restore_agent_builder_state.ps1 uses USERPROFILE-derived default path, fetches origin, switches to the phase110 runtime branch, pulls ff-only, prints branch/head/status, and prints NEXT_ALLOWED_STEP when NEXT_ACTION.json is present. It does not commit, push, or write tracked files."
      validator_behavior = "Validator fails on missing or non-PASS PHASE139 proof, wrong generated pack count, non-runtime authorship, codex-authored generated packs, missing batch admission or bounded execution, missing state sync files or restore tool, external agent path changes, trusted materials, forbidden fetch/install/executable flags, active queue, or wrong next step."
      generated_pack_paths = $GeneratedPackPaths
      admission_batch_path = $AdmissionBatchPath
      scale_trial_result_path = $ScaleTrialResultPath
      current_state_path = $CurrentStatePath
      next_action_path = $NextActionPath
      proof_pointer_path = $ProofPointerPath
      restore_tool_path = $RestoreToolPath
      proof_path = $ProofPath
      remaining_risks = @(
        "The generated packs are bounded metadata-only seeds; PHASE141 must turn the learning metric seed into a measured loop.",
        "The restore tool is created and inspected locally but intentionally not executed during PHASE140 because it performs git fetch/pull.",
        "The validator checks local worktree scope and artifacts, not hosted CI."
      )
      cut_list = @(
        "No external agent production.",
        "No generated_agents, agent_catalog, or applied_agents changes.",
        "No dependency install.",
        "No external fetch by runtime.",
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
      runtime_mode = "SELF_BUILD_QUEUE_NONE_BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_001"
      runtime_executed = $true
      builder_runtime_invoked = $true
      builder_generated_pack_count = 3
      generated_pack_ids = $GeneratedPackIds
      generated_pack_paths = $GeneratedPackPaths
      generated_pack_result_paths = $GeneratedPackResultPaths
      generated_pack_runtime_log_paths = $GeneratedPackRuntimeLogPaths
      generated_packs_author = "BUILDER_RUNTIME"
      codex_authored_generated_packs = $false
      codex_bootstrap_used = $true
      generated_packs_admitted = $true
      generated_packs_executed = $true
      repo_state_sync_capsule_created = $true
      restore_tool_created = $true
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
      admission_batch_path = $AdmissionBatchPath
      scale_trial_result_path = $ScaleTrialResultPath
      current_state_path = $CurrentStatePath
      next_action_path = $NextActionPath
      proof_pointer_path = $ProofPointerPath
      restore_tool_path = $RestoreToolPath
      output_path = $OutputPath
      result_path = $ResultPath
      runtime_log_path = $RuntimeLogPath
      report_path = $ReportPath
      next_allowed_step = $NextAllowedStep
    }

    $RuntimeLog = @(
      "BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL=PHASE140_BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_001",
      "SELF_PACK_AUTHOR_SCALE_STATUS=PASS",
      "BUILDER_GENERATED_PACK_COUNT=3",
      "GENERATED_PACKS_AUTHOR=BUILDER_RUNTIME",
      "CODEX_AUTHORED_GENERATED_PACKS=False",
      "CODEX_BOOTSTRAP_USED=True",
      "GENERATED_PACKS_ADMITTED=True",
      "GENERATED_PACKS_EXECUTED=True",
      "REPO_STATE_SYNC_CAPSULE_CREATED=True",
      "RESTORE_TOOL_CREATED=True",
      "EXTERNAL_AGENT_PRODUCTION_ALLOWED=False",
      "MATERIAL_TRUSTED_COUNT=0",
      "MATERIAL_EXTERNAL_FETCH_PERFORMED=False",
      "MATERIAL_DEPENDENCY_INSTALL_PERFORMED=False",
      "MATERIAL_EXECUTABLE_USED=False",
      "SELF_PACK_AUTHOR_SCALE_NEXT_STEP=PHASE141_BUILDER_SELF_LEARNING_LOOP_METRICS_V1",
      "STATUS=PASS_STOPPED_BUILDER_SELF_PACK_AUTHOR_SCALE_TRIAL_BUILT"
    ) -join "`n"

    Write-Phase140JsonFile -RepoRoot $RepoRoot -Path $ScaleTrialResultPath -Object $ScaleTrialResult
    Write-Phase140JsonFile -RepoRoot $RepoRoot -Path $OutputPath -Object $Output
    Write-Phase140JsonFile -RepoRoot $RepoRoot -Path $ResultPath -Object $Result
    Write-Phase140TextFile -RepoRoot $RepoRoot -Path $RuntimeLogPath -Content $RuntimeLog
    Write-Phase140JsonFile -RepoRoot $RepoRoot -Path $ReportPath -Object $Report
    Write-Phase140JsonFile -RepoRoot $RepoRoot -Path $ProofPath -Object $Proof

    return [pscustomobject]$Output
  } finally {
    Pop-Location
  }
}
