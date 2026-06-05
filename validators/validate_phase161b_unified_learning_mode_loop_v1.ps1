param(
  [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"

function Resolve-Phase161BValidatorRepoRoot {
  param([string]$RepoRoot)
  if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
    return [System.IO.Path]::GetFullPath($RepoRoot)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
}

function Stop-Phase161BValidator {
  param([string]$Reason)
  Write-Output "PHASE161B_UNIFIED_LEARNING_MODE_LOOP_VALIDATE_RESULT=FAIL"
  Write-Output "FAIL_REASON=$Reason"
  exit 1
}

function Assert-Phase161B {
  param([bool]$Condition, [string]$Reason)
  if (-not $Condition) {
    Stop-Phase161BValidator -Reason $Reason
  }
}

function Read-Phase161BValidatorJson {
  param([string]$Path)
  return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Write-Phase161BValidatorJson {
  param([string]$Path, [object]$Object)
  $directory = Split-Path -Path $Path -Parent
  if ($directory -and -not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  $json = ($Object | ConvertTo-Json -Depth 100) -replace "`r`n", "`n"
  if (-not $json.EndsWith("`n")) {
    $json += "`n"
  }
  [System.IO.File]::WriteAllText($Path, $json, [System.Text.UTF8Encoding]::new($false))
}

function Test-Phase161BPowerShellSyntax {
  param([string]$Path)
  try {
    [void][scriptblock]::Create((Get-Content -LiteralPath $Path -Raw))
    return $true
  } catch {
    return $false
  }
}

function Invoke-Phase161BJsonScript {
  param(
    [string]$RepoRoot,
    [string]$ScriptRelativePath,
    [string[]]$Arguments = @()
  )
  $scriptPath = Join-Path $RepoRoot $ScriptRelativePath
  $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @Arguments 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    Stop-Phase161BValidator -Reason "SCRIPT_FAILED=$ScriptRelativePath output=$($output -join ' | ')"
  }
  try {
    return ($output -join "`n") | ConvertFrom-Json
  } catch {
    Stop-Phase161BValidator -Reason "SCRIPT_JSON_INVALID=$ScriptRelativePath output=$($output -join ' | ')"
  }
}

function Invoke-Phase161BScript {
  param(
    [string]$RepoRoot,
    [string]$ScriptRelativePath,
    [string[]]$Arguments = @()
  )
  $scriptPath = Join-Path $RepoRoot $ScriptRelativePath
  $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @Arguments 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    Stop-Phase161BValidator -Reason "SCRIPT_FAILED=$ScriptRelativePath output=$($output -join ' | ')"
  }
  return @($output)
}

function Get-Phase161BFileHashMap {
  param([string]$RepoRoot, [string[]]$RelativePaths)
  $hashes = [ordered]@{}
  foreach ($relative in $RelativePaths) {
    $path = Join-Path $RepoRoot $relative
    $hashes[$relative] = if (Test-Path -LiteralPath $path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash } else { "MISSING" }
  }
  return $hashes
}

function Test-Phase161BHashMapSame {
  param([object]$Before, [object]$After)
  foreach ($key in $Before.Keys) {
    if (-not $After.Contains($key)) {
      return $false
    }
    if ([string]$Before[$key] -ne [string]$After[$key]) {
      return $false
    }
  }
  return $true
}

function New-Phase161BValidatorCurriculum {
  param(
    [string]$CurriculumId,
    [string]$Source,
    [bool]$Unsafe = $false
  )
  $failurePolicy = [ordered]@{
    continue_batch = $true
    quarantine_on_safety_violation = $true
  }
  $safeRules = [ordered]@{
    accepted_repo_mutation_allowed = $false
    protected_state_mutation_allowed = $false
    repo_commit_allowed = $false
    repo_push_allowed = $false
    branch_switch_allowed = $false
    runtime_session_only = $true
  }
  if ($Unsafe) {
    $safeRules.repo_commit_allowed = $true
  }
  $lesson4Actions = if ($Unsafe) { @("commit") } else { @("write_runtime") }
  return [ordered]@{
    curriculum_id = $CurriculumId
    curriculum_version = "1.0.0"
    curriculum_source = $Source
    pack_type = "BUILDER_SCHOOL_CURRICULUM_PACK"
    active_line = "AGENT_BUILDER_SELF_DEVELOPMENT"
    active_mode = "SELF_BUILD"
    route_lock_required = $true
    route_step_id = "PHASE161B_UNIFIED_LEARNING_MODE_LOOP_V1"
    title = "$CurriculumId validator curriculum"
    safety_rules = $safeRules
    lessons = @(
      [ordered]@{
        lesson_id = "$($CurriculumId)_ROUTE_STAMP"
        title = "Route stamp"
        objective = "Read the active route stamp."
        inputs = @("route_locks/ACTIVE_ROUTE_LOCK.json")
        expected_outputs = @("ACTIVE_ROUTE_LOCK_STAMP_EXPOSED")
        allowed_actions = @("read_repo", "read_route_lock", "write_runtime")
        failure_policy = $failurePolicy
      },
      [ordered]@{
        lesson_id = "$($CurriculumId)_SCHEMA_PARSE"
        title = "Schema parse"
        objective = "Parse the school schemas."
        inputs = @("schemas/builder_school_curriculum_pack.schema.json")
        expected_outputs = @("CURRICULUM_PACK_SCHEMA_CREATED")
        allowed_actions = @("read_repo", "parse_schema", "write_runtime")
        failure_policy = $failurePolicy
      },
      [ordered]@{
        lesson_id = "$($CurriculumId)_INTENTIONAL_FAIL"
        title = "Intentional missing output"
        objective = "Create one ordinary failed lesson."
        inputs = @("runtime_session")
        expected_outputs = @("INTENTIONAL_MISSING_OUTPUT")
        allowed_actions = @("write_runtime")
        failure_policy = $failurePolicy
      },
      [ordered]@{
        lesson_id = "$($CurriculumId)_SAFETY_CHECK"
        title = "Safety check"
        objective = "Keep unsafe actions separated from ordinary failures."
        inputs = @("runtime_session")
        expected_outputs = @("QUARANTINE_HANDLED_SEPARATELY")
        allowed_actions = $lesson4Actions
        failure_policy = $failurePolicy
      }
    )
  }
}

$ResolvedRepoRoot = Resolve-Phase161BValidatorRepoRoot -RepoRoot $RepoRoot
$Pushed = $false

try {
  Push-Location $ResolvedRepoRoot
  $Pushed = $true

  foreach ($identity in @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1")) {
    Assert-Phase161B -Condition (Test-Path -LiteralPath (Join-Path $ResolvedRepoRoot $identity)) -Reason "STOP=WRONG_AGENT_BUILDER_REPO missing=$identity"
  }

  $InitialBranch = (git branch --show-current).Trim()
  $InitialHead = (git rev-parse HEAD).Trim()
  $InitialRemoteHead = ""
  try {
    $InitialRemoteHead = (git rev-parse "origin/$InitialBranch" 2>$null).Trim()
  } catch {
    $InitialRemoteHead = ""
  }
  $ProtectedPaths = @("CAPABILITY_ROADMAP.json", "GENESIS_STATE.json", "TASK_QUEUE.json", "packs/registry.json", "orchestrator/run.ps1", "route_locks/ACTIVE_ROUTE_LOCK.json")
  $ProtectedBefore = Get-Phase161BFileHashMap -RepoRoot $ResolvedRepoRoot -RelativePaths $ProtectedPaths

  $Flags = [ordered]@{
    NO_CURRICULUM_SELECTS_SELF_MODE = $false
    OWNER_CURRICULUM_SELECTS_SCHOOL_MODE = $false
    COMPLETED_SCHOOL_RUN_SELECTS_ABSORB_EXPERIENCE = $false
    ABSORPTION_WRITTEN = $false
    AFTER_ABSORPTION_RETURNS_TO_SELF_MODE = $false
    NEXT_SELF_LEARNING_RECOMMENDATION_CREATED = $false
    FAILURE_CLUSTERING_UPGRADED = $false
    OWNER_CURRICULUM_PRIORITY_PASS = $false
    UNSAFE_CURRICULUM_NOT_RUN = $false
    OVERNIGHT_LEARNING_RUN_PLAN_CREATED = $false
    LIVE_LEARNING_MODE_SURFACE_FIELDS_PRESENT = $false
    PHASE161A_SCHOOL_ENTRY_COMPATIBILITY_PASS = $false
    PHASE160K_QUALITY_COMPATIBILITY_PRESERVED = $false
    PHASE160J_OWNER_TASK_COMPATIBILITY_PRESERVED = $false
    NO_ACCEPTED_REPO_MUTATION = $false
    NO_PROTECTED_STATE_MUTATION = $false
    RUNTIME_OUTPUTS_STAGED = $false
    NO_COMMIT_PERFORMED = $false
    NO_PUSH_PERFORMED = $false
    NO_BRANCH_SWITCH = $false
  }

  foreach ($schema in @("schemas/builder_learning_mode_state.schema.json", "schemas/builder_learning_absorption.schema.json", "schemas/builder_school_curriculum_pack.schema.json", "schemas/builder_school_lesson.schema.json", "schemas/builder_school_morning_review.schema.json")) {
    [void](Read-Phase161BValidatorJson -Path (Join-Path $ResolvedRepoRoot $schema))
  }

  $TouchedPowerShell = @(
    "modules/decide_builder_learning_mode_001.ps1",
    "modules/inspect_builder_learning_mode_state_001.ps1",
    "modules/absorb_builder_school_experience_001.ps1",
    "modules/write_builder_learning_absorption_report_001.ps1",
    "modules/select_builder_next_self_learning_step_001.ps1",
    "modules/cluster_builder_lesson_failures_001.ps1",
    "modules/prepare_builder_overnight_learning_run_001.ps1",
    "modules/start_builder_live_growth_daemon_001.ps1",
    "modules/watch_builder_live_console_001.ps1",
    "modules/watch_builder_live_growth_session_observer_001.ps1",
    "modules/write_builder_morning_review_001.ps1",
    "modules/ingest_builder_curriculum_pack_001.ps1",
    "modules/normalize_builder_lesson_batch_001.ps1",
    "modules/run_builder_school_batch_session_local_001.ps1",
    "validators/validate_phase161b_unified_learning_mode_loop_v1.ps1"
  )
  foreach ($file in $TouchedPowerShell) {
    Assert-Phase161B -Condition (Test-Phase161BPowerShellSyntax -Path (Join-Path $ResolvedRepoRoot $file)) -Reason "POWERSHELL_PARSE_FAIL=$file"
  }

  Assert-Phase161B -Condition (Test-Path -LiteralPath (Join-Path $ResolvedRepoRoot "reports/self_development/PHASE161B_UNIFIED_LEARNING_MODE_LOOP_REPORT.md")) -Reason "REPORT_MISSING"
  Assert-Phase161B -Condition (Test-Path -LiteralPath (Join-Path $ResolvedRepoRoot "proofs/self_development/PHASE161B_UNIFIED_LEARNING_MODE_LOOP_PROOF.json")) -Reason "PROOF_MISSING"
  Assert-Phase161B -Condition (Test-Path -LiteralPath (Join-Path $ResolvedRepoRoot "route_change_requests/PHASE161B_UNIFIED_LEARNING_MODE_LOOP_REQUEST.md")) -Reason "ROUTE_REQUEST_MISSING"

  $Stamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
  $ScenarioRoot = Join-Path $ResolvedRepoRoot "runtime_sessions/phase161b_validator_$Stamp"
  $EmptyCurriculumRoot = Join-Path $ScenarioRoot "empty_curricula"
  $OwnerCurriculumRoot = Join-Path $ScenarioRoot "owner_curricula"
  $UnsafeCurriculumRoot = Join-Path $ScenarioRoot "unsafe_curricula"
  $PriorityCurriculumRoot = Join-Path $ScenarioRoot "priority_curricula"
  foreach ($dir in @($EmptyCurriculumRoot, (Join-Path $OwnerCurriculumRoot "owner"), (Join-Path $UnsafeCurriculumRoot "owner"), (Join-Path $PriorityCurriculumRoot "owner"), (Join-Path $PriorityCurriculumRoot "internal"), (Join-Path $PriorityCurriculumRoot "generated"))) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }

  $OwnerCurriculumPath = Join-Path $OwnerCurriculumRoot "owner/owner_curriculum.json"
  $OwnerCurriculum = New-Phase161BValidatorCurriculum -CurriculumId "PHASE161B_OWNER_CURRICULUM_$Stamp" -Source "owner"
  Write-Phase161BValidatorJson -Path $OwnerCurriculumPath -Object $OwnerCurriculum

  $UnsafeCurriculumPath = Join-Path $UnsafeCurriculumRoot "owner/unsafe_curriculum.json"
  $UnsafeCurriculum = New-Phase161BValidatorCurriculum -CurriculumId "PHASE161B_UNSAFE_CURRICULUM_$Stamp" -Source "owner" -Unsafe $true
  Write-Phase161BValidatorJson -Path $UnsafeCurriculumPath -Object $UnsafeCurriculum

  Write-Phase161BValidatorJson -Path (Join-Path $PriorityCurriculumRoot "owner/owner_priority.json") -Object (New-Phase161BValidatorCurriculum -CurriculumId "PHASE161B_PRIORITY_OWNER_$Stamp" -Source "owner")
  Write-Phase161BValidatorJson -Path (Join-Path $PriorityCurriculumRoot "internal/internal_priority.json") -Object (New-Phase161BValidatorCurriculum -CurriculumId "PHASE161B_PRIORITY_INTERNAL_$Stamp" -Source "internal")
  Write-Phase161BValidatorJson -Path (Join-Path $PriorityCurriculumRoot "generated/generated_priority.json") -Object (New-Phase161BValidatorCurriculum -CurriculumId "PHASE161B_PRIORITY_GENERATED_$Stamp" -Source "generated")

  $Decision1 = Invoke-Phase161BJsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/decide_builder_learning_mode_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-CurriculumRoot", $EmptyCurriculumRoot, "-DecisionId", "PHASE161B_S1_NO_CURRICULUM_$Stamp", "-IgnoreLatestSchoolRun", "-EmitJson")
  $Flags.NO_CURRICULUM_SELECTS_SELF_MODE = ([string]$Decision1.learning_mode -eq "SELF_MODE" -and [bool]$Decision1.self_mode_allowed -and -not [bool]$Decision1.school_mode_allowed -and -not [bool]$Decision1.safe_idle_only)

  $Decision2 = Invoke-Phase161BJsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/decide_builder_learning_mode_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-CurriculumRoot", $OwnerCurriculumRoot, "-DecisionId", "PHASE161B_S2_OWNER_CURRICULUM_$Stamp", "-IgnoreLatestSchoolRun", "-EmitJson")
  $Flags.OWNER_CURRICULUM_SELECTS_SCHOOL_MODE = ([string]$Decision2.learning_mode -eq "SCHOOL_MODE" -and [string]$Decision2.selected_curriculum_source -eq "owner" -and [bool]$Decision2.school_mode_allowed)

  $SchoolRunId = "PHASE161B_VALIDATOR_SCHOOL_$Stamp"
  $Ingest = Invoke-Phase161BJsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/ingest_builder_curriculum_pack_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-CurriculumPackPath", $OwnerCurriculumPath, "-SchoolRunId", $SchoolRunId)
  Assert-Phase161B -Condition ([string]$Ingest.status -eq "PASS") -Reason "PHASE161A_INGEST_COMPAT_FAIL"
  $Runner = Invoke-Phase161BJsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/run_builder_school_batch_session_local_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-SchoolRunId", $SchoolRunId)
  Assert-Phase161B -Condition ([string]$Runner.status -eq "PASS") -Reason "PHASE161A_RUNNER_COMPAT_FAIL"
  $PrimarySchoolRunRoot = Join-Path $ResolvedRepoRoot "runtime_sessions/school_runs/$SchoolRunId"

  $Decision3 = Invoke-Phase161BJsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/decide_builder_learning_mode_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-CurriculumRoot", $OwnerCurriculumRoot, "-SchoolRunId", $SchoolRunId, "-DecisionId", "PHASE161B_S3_ABSORB_REQUIRED_$Stamp", "-EmitJson")
  $Flags.COMPLETED_SCHOOL_RUN_SELECTS_ABSORB_EXPERIENCE = ([string]$Decision3.learning_mode -eq "ABSORB_EXPERIENCE" -and [bool]$Decision3.absorption_required)

  $Absorption = Invoke-Phase161BJsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/absorb_builder_school_experience_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-SchoolRunId", $SchoolRunId, "-AbsorptionId", "PHASE161B_ABSORB_VALIDATOR_$Stamp", "-EmitJson")
  $AbsorptionRoot = Join-Path $ResolvedRepoRoot ([string]$Absorption.absorption_root)
  $AbsorptionJson = Read-Phase161BValidatorJson -Path (Join-Path $AbsorptionRoot "learning_absorption.json")
  $NextRecommendations = Read-Phase161BValidatorJson -Path (Join-Path $AbsorptionRoot "next_self_learning_recommendations.json")
  $Flags.ABSORPTION_WRITTEN = ([bool]$Absorption.absorption_written -and (Test-Path -LiteralPath (Join-Path $AbsorptionRoot "learning_absorption_report.md")) -and (Test-Path -LiteralPath (Join-Path $AbsorptionRoot "school_to_gap_backlog_suggestions.json")))
  $Flags.NEXT_SELF_LEARNING_RECOMMENDATION_CREATED = ([string]$NextRecommendations.resume_mode -eq "SELF_MODE" -and -not [string]::IsNullOrWhiteSpace([string]$NextRecommendations.recommended_next_gap))
  $Flags.FAILURE_CLUSTERING_UPGRADED = ([bool]$Absorption.failure_clustering_upgraded -and @($AbsorptionJson.repeated_failure_clusters | Where-Object { $_.PSObject.Properties.Name -contains "cluster_type" -and $_.PSObject.Properties.Name -contains "next_action" }).Count -gt 0)

  $Decision4 = Invoke-Phase161BJsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/decide_builder_learning_mode_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-CurriculumRoot", $OwnerCurriculumRoot, "-SchoolRunId", $SchoolRunId, "-DecisionId", "PHASE161B_S4_RETURN_SELF_$Stamp", "-EmitJson")
  $Flags.AFTER_ABSORPTION_RETURNS_TO_SELF_MODE = ([string]$Decision4.learning_mode -eq "SELF_MODE" -and [string]$Decision4.last_absorption_id -eq [string]$Absorption.absorption_id -and [string]$Decision4.recommended_next_self_gap -ne "NONE" -and [string]$NextRecommendations.source_school_run_id -eq $SchoolRunId)

  $Decision5 = Invoke-Phase161BJsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/decide_builder_learning_mode_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-CurriculumRoot", $UnsafeCurriculumRoot, "-DecisionId", "PHASE161B_S5_UNSAFE_$Stamp", "-IgnoreLatestSchoolRun", "-EmitJson")
  $UnsafeReportPath = Join-Path $ResolvedRepoRoot "runtime_sessions/learning_curriculum_quarantine/PHASE161B_S5_UNSAFE_$Stamp/unsafe_curriculum_report.json"
  $UnsafeReport = Read-Phase161BValidatorJson -Path $UnsafeReportPath
  $Flags.UNSAFE_CURRICULUM_NOT_RUN = ([bool]$Decision5.unsafe_curriculum_quarantined -and [bool]$UnsafeReport.unsafe_curriculum_not_run -and @($UnsafeReport.unsafe_patterns | Where-Object { [string]$_.cluster_type -eq "safety_violation" }).Count -gt 0)

  $Decision6 = Invoke-Phase161BJsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/decide_builder_learning_mode_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-CurriculumRoot", $PriorityCurriculumRoot, "-DecisionId", "PHASE161B_S6_PRIORITY_$Stamp", "-IgnoreLatestSchoolRun", "-EmitJson")
  $Flags.OWNER_CURRICULUM_PRIORITY_PASS = ([string]$Decision6.learning_mode -eq "SCHOOL_MODE" -and [string]$Decision6.selected_curriculum_source -eq "owner" -and [bool]$Decision6.owner_curriculum_available -and [bool]$Decision6.internal_curriculum_available -and [bool]$Decision6.generated_curriculum_available)

  $Overnight = Invoke-Phase161BJsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/prepare_builder_overnight_learning_run_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-RunId", "PHASE161B_OVERNIGHT_VALIDATOR_$Stamp", "-IntendedMode", "SCHOOL_MODE", "-CurriculumId", ([string]$OwnerCurriculum.curriculum_id), "-MaxLessons", "4", "-MaxRuntimeMinutes", "60", "-EmitJson")
  $OvernightPlan = Read-Phase161BValidatorJson -Path ([string]$Overnight.plan_path)
  $Flags.OVERNIGHT_LEARNING_RUN_PLAN_CREATED = ([bool]$Overnight.overnight_learning_run_plan_created -and [bool]$OvernightPlan.no_accepted_repo_mutation -and [bool]$OvernightPlan.no_commit_push_branch_switch)

  $CompatCurriculumRoot = Join-Path $ScenarioRoot "phase161a_compat_curricula"
  New-Item -ItemType Directory -Force -Path $CompatCurriculumRoot | Out-Null
  $CompatCurriculumPath = Join-Path $CompatCurriculumRoot "phase161a_compat_curriculum.json"
  $CompatCurriculum = New-Phase161BValidatorCurriculum -CurriculumId "PHASE161B_PHASE161A_COMPAT_$Stamp" -Source "owner"
  $CompatCurriculum.lessons[3].allowed_actions = @("commit")
  Write-Phase161BValidatorJson -Path $CompatCurriculumPath -Object $CompatCurriculum
  $CompatSchoolRunId = "PHASE161B_PHASE161A_COMPAT_$Stamp"
  $CompatIngest = Invoke-Phase161BJsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/ingest_builder_curriculum_pack_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-CurriculumPackPath", $CompatCurriculumPath, "-SchoolRunId", $CompatSchoolRunId)
  Assert-Phase161B -Condition ([string]$CompatIngest.status -eq "PASS") -Reason "PHASE161A_COMPAT_INGEST_FAIL"
  $CompatRunner = Invoke-Phase161BJsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/run_builder_school_batch_session_local_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-SchoolRunId", $CompatSchoolRunId)
  Assert-Phase161B -Condition ([string]$CompatRunner.status -eq "PASS") -Reason "PHASE161A_COMPAT_RUNNER_FAIL"
  $CompatSchoolRunRoot = Join-Path $ResolvedRepoRoot "runtime_sessions/school_runs/$CompatSchoolRunId"
  $Review = Read-Phase161BValidatorJson -Path (Join-Path $CompatSchoolRunRoot "morning_review.json")
  $ResultStatuses = @(Get-ChildItem -LiteralPath (Join-Path $CompatSchoolRunRoot "lesson_results") -File -Filter "*_result.json" | ForEach-Object { (Read-Phase161BValidatorJson -Path $_.FullName).status })
  $Flags.PHASE161A_SCHOOL_ENTRY_COMPATIBILITY_PASS = (
    (Test-Path -LiteralPath (Join-Path $ResolvedRepoRoot "schemas/builder_school_curriculum_pack.schema.json")) -and
    (Test-Path -LiteralPath (Join-Path $ResolvedRepoRoot "schemas/builder_school_lesson.schema.json")) -and
    (Test-Path -LiteralPath (Join-Path $ResolvedRepoRoot "schemas/builder_school_morning_review.schema.json")) -and
    ($ResultStatuses -contains "PASS") -and ($ResultStatuses -contains "FAIL") -and ($ResultStatuses -contains "QUARANTINED") -and
    ($null -ne $Review)
  )

  $LiveRunId = "PHASE161B_LIVE_SURFACE_$Stamp"
  Invoke-Phase161BScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/start_builder_live_growth_daemon_001.ps1" -Arguments @("-RunId", $LiveRunId, "-DurationSeconds", "2", "-TickIntervalSeconds", "1") | Out-Null
  $LiveSessionRelative = "runtime_sessions/live_growth/$LiveRunId"
  $LiveSessionRoot = Join-Path $ResolvedRepoRoot $LiveSessionRelative
  $CurrentState = Read-Phase161BValidatorJson -Path (Join-Path $LiveSessionRoot "current_state.json")
  $LiveFields = @("learning_mode", "previous_learning_mode", "learning_mode_decision_reason", "active_curriculum_id", "active_school_run_id", "absorption_required", "last_absorption_id", "last_absorption_status", "recommended_next_self_gap", "selected_curriculum_source", "owner_curriculum_available", "internal_curriculum_available", "generated_curriculum_available", "school_mode_allowed", "self_mode_allowed", "safe_idle_only")
  $LiveStateFieldsPresent = $true
  foreach ($field in $LiveFields) {
    if (-not ($CurrentState.PSObject.Properties.Name -contains $field)) {
      $LiveStateFieldsPresent = $false
    }
  }
  $ConsoleRunId = "PHASE161B_CONSOLE_$Stamp"
  Invoke-Phase161BScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/watch_builder_live_console_001.ps1" -Arguments @("-SessionRoot", $LiveSessionRelative, "-RunId", $LiveRunId, "-DurationSeconds", "2", "-PollIntervalSeconds", "1", "-ConsoleRunId", $ConsoleRunId) | Out-Null
  $ConsoleResult = Read-Phase161BValidatorJson -Path (Join-Path $ResolvedRepoRoot "runtime_sessions/live_growth_console/$ConsoleRunId/console_run_result.json")
  $ConsoleSample = Get-Content -LiteralPath (Join-Path $ResolvedRepoRoot "runtime_sessions/live_growth_console/$ConsoleRunId/console_output_sample.txt") -Raw
  $ConsoleTokensPresent = $true
  foreach ($token in @("LEARNING_MODE=", "ACTIVE_CURRICULUM=", "ACTIVE_SCHOOL_RUN=", "ABSORPTION_REQUIRED=", "LAST_ABSORPTION=", "NEXT_SELF_GAP=", "SELECTED_CURRICULUM_SOURCE=")) {
    if ($ConsoleSample -notmatch [regex]::Escape($token)) {
      $ConsoleTokensPresent = $false
    }
  }
  $ObserverResult = Invoke-Phase161BJsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/watch_builder_live_growth_session_observer_001.ps1" -Arguments @("-SessionRoot", $LiveSessionRelative, "-RunId", $LiveRunId, "-DurationSeconds", "2", "-PollIntervalSeconds", "1")
  $ObserverLearningDetected = (
    [bool]$ObserverResult.learning_school_mode_selected_when_curriculum_exists -and
    [bool]$ObserverResult.learning_self_mode_selected_when_no_curriculum_exists -and
    [bool]$ObserverResult.learning_absorption_selected_after_completed_school_run -and
    [bool]$ObserverResult.learning_returned_to_self_mode_after_absorption -and
    [bool]$ObserverResult.learning_no_accepted_repo_mutation -and
    [bool]$ObserverResult.learning_no_protected_state_mutation
  )
  $Flags.LIVE_LEARNING_MODE_SURFACE_FIELDS_PRESENT = ($LiveStateFieldsPresent -and [bool]$ConsoleResult.live_console_shows_phase161b_learning_mode_fields -and $ConsoleTokensPresent -and $ObserverLearningDetected)

  $Phase160KParserOk = $true
  foreach ($file in @("modules/inspect_builder_quality_decision_index_001.ps1", "modules/watch_builder_live_console_001.ps1", "modules/watch_builder_live_growth_session_observer_001.ps1")) {
    if (-not (Test-Phase161BPowerShellSyntax -Path (Join-Path $ResolvedRepoRoot $file))) {
      $Phase160KParserOk = $false
    }
  }
  $Phase160KProofExists = @(Get-ChildItem -LiteralPath (Join-Path $ResolvedRepoRoot "proofs/self_development") -File -Filter "*PHASE160K*PROOF*.json" -ErrorAction SilentlyContinue).Count -gt 0
  $Flags.PHASE160K_QUALITY_COMPATIBILITY_PRESERVED = ($Phase160KParserOk -and $Phase160KProofExists -and [bool]$ConsoleResult.live_console_shows_phase160h_quality_fields)

  $Phase160JParserOk = $true
  foreach ($file in @("modules/inspect_builder_owner_task_lifecycle_state_001.ps1", "modules/watch_builder_live_console_001.ps1", "modules/watch_builder_live_growth_session_observer_001.ps1")) {
    if (-not (Test-Phase161BPowerShellSyntax -Path (Join-Path $ResolvedRepoRoot $file))) {
      $Phase160JParserOk = $false
    }
  }
  $Phase160JProofExists = @(Get-ChildItem -LiteralPath (Join-Path $ResolvedRepoRoot "proofs/self_development") -File -Filter "*PHASE160J*PROOF*.json" -ErrorAction SilentlyContinue).Count -gt 0
  $Flags.PHASE160J_OWNER_TASK_COMPATIBILITY_PRESERVED = ($Phase160JParserOk -and $Phase160JProofExists -and [bool]$ConsoleResult.live_console_shows_phase160j_owner_task_fields)

  $SchoolManifest = Read-Phase161BValidatorJson -Path (Join-Path $PrimarySchoolRunRoot "school_run_manifest.json")
  $DecisionRecordsSafe = @(Get-ChildItem -LiteralPath (Join-Path $ResolvedRepoRoot "runtime_sessions/learning_mode_decisions") -File -Filter "learning_mode_decision.json" -Recurse | ForEach-Object { Read-Phase161BValidatorJson -Path $_.FullName } | Where-Object { -not [bool]$_.no_accepted_repo_mutation -or -not [bool]$_.no_protected_state_mutation }).Count -eq 0
  $Flags.NO_ACCEPTED_REPO_MUTATION = (-not [bool]$SchoolManifest.accepted_repo_mutated -and -not [bool]$AbsorptionJson.accepted_repo_mutated -and $DecisionRecordsSafe)
  $ProtectedAfter = Get-Phase161BFileHashMap -RepoRoot $ResolvedRepoRoot -RelativePaths $ProtectedPaths
  $Flags.NO_PROTECTED_STATE_MUTATION = (Test-Phase161BHashMapSame -Before $ProtectedBefore -After $ProtectedAfter)
  $Flags.RUNTIME_OUTPUTS_STAGED = (@(git diff --cached --name-only -- runtime_sessions).Count -gt 0)

  $FinalHead = (git rev-parse HEAD).Trim()
  $FinalBranch = (git branch --show-current).Trim()
  $FinalRemoteHead = ""
  try {
    $FinalRemoteHead = (git rev-parse "origin/$InitialBranch" 2>$null).Trim()
  } catch {
    $FinalRemoteHead = ""
  }
  $Flags.NO_COMMIT_PERFORMED = ($FinalHead -eq $InitialHead -and -not [bool]$SchoolManifest.commit_performed)
  $Flags.NO_PUSH_PERFORMED = (([string]::IsNullOrWhiteSpace($InitialRemoteHead) -and [string]::IsNullOrWhiteSpace($FinalRemoteHead)) -or $InitialRemoteHead -eq $FinalRemoteHead)
  $Flags.NO_BRANCH_SWITCH = ($FinalBranch -eq $InitialBranch -and -not [bool]$SchoolManifest.branch_switch_performed)

  foreach ($flagName in $Flags.Keys) {
    if ($flagName -eq "RUNTIME_OUTPUTS_STAGED") {
      Assert-Phase161B -Condition (-not [bool]$Flags[$flagName]) -Reason "$flagName=$($Flags[$flagName])"
    } else {
      Assert-Phase161B -Condition ([bool]$Flags[$flagName]) -Reason "$flagName=False"
    }
  }

  Write-Output "PHASE161B_UNIFIED_LEARNING_MODE_LOOP_VALIDATE_RESULT=PASS"
  Write-Output "NO_CURRICULUM_SELECTS_SELF_MODE=True"
  Write-Output "OWNER_CURRICULUM_SELECTS_SCHOOL_MODE=True"
  Write-Output "COMPLETED_SCHOOL_RUN_SELECTS_ABSORB_EXPERIENCE=True"
  Write-Output "ABSORPTION_WRITTEN=True"
  Write-Output "AFTER_ABSORPTION_RETURNS_TO_SELF_MODE=True"
  Write-Output "NEXT_SELF_LEARNING_RECOMMENDATION_CREATED=True"
  Write-Output "FAILURE_CLUSTERING_UPGRADED=True"
  Write-Output "OWNER_CURRICULUM_PRIORITY_PASS=True"
  Write-Output "UNSAFE_CURRICULUM_NOT_RUN=True"
  Write-Output "OVERNIGHT_LEARNING_RUN_PLAN_CREATED=True"
  Write-Output "LIVE_LEARNING_MODE_SURFACE_FIELDS_PRESENT=True"
  Write-Output "PHASE161A_SCHOOL_ENTRY_COMPATIBILITY_PASS=True"
  Write-Output "PHASE160K_QUALITY_COMPATIBILITY_PRESERVED=True"
  Write-Output "PHASE160J_OWNER_TASK_COMPATIBILITY_PRESERVED=True"
  Write-Output "NO_ACCEPTED_REPO_MUTATION=True"
  Write-Output "NO_PROTECTED_STATE_MUTATION=True"
  Write-Output "RUNTIME_OUTPUTS_STAGED=False"
  Write-Output "NO_COMMIT_PERFORMED=True"
  Write-Output "NO_PUSH_PERFORMED=True"
  Write-Output "NO_BRANCH_SWITCH=True"
} finally {
  if ($Pushed) {
    Pop-Location
  }
}
