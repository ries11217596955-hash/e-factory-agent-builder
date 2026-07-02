param(
  [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"

function Resolve-Phase161AValidatorRepoRoot {
  param([string]$RepoRoot)
  if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
    return [System.IO.Path]::GetFullPath($RepoRoot)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
}

function Read-Phase161AValidatorJson {
  param([string]$Path)
  return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Write-Phase161AValidatorJson {
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

function Stop-Phase161AValidator {
  param([string]$Reason)
  Write-Output "PHASE161A_SCHOOL_ENTRY_FOUNDATION_VALIDATE_RESULT=FAIL"
  Write-Output "FAIL_REASON=$Reason"
  exit 1
}

function Assert-Phase161A {
  param([bool]$Condition, [string]$Reason)
  if (-not $Condition) {
    Stop-Phase161AValidator -Reason $Reason
  }
}

function Test-Phase161APowerShellSyntax {
  param([string]$Path)
  try {
    [void][scriptblock]::Create((Get-Content -LiteralPath $Path -Raw))
    return $true
  } catch {
    return $false
  }
}

function Invoke-Phase161AJsonScript {
  param(
    [string]$RepoRoot,
    [string]$ScriptRelativePath,
    [string[]]$Arguments = @()
  )
  $scriptPath = Join-Path $RepoRoot $ScriptRelativePath
  $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @Arguments 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    Stop-Phase161AValidator -Reason "SCRIPT_FAILED=$ScriptRelativePath output=$($output -join ' | ')"
  }
  $jsonText = $output -join "`n"
  try {
    return $jsonText | ConvertFrom-Json
  } catch {
    Stop-Phase161AValidator -Reason "SCRIPT_JSON_INVALID=$ScriptRelativePath output=$($output -join ' | ')"
  }
}

function Invoke-Phase161AScript {
  param(
    [string]$RepoRoot,
    [string]$ScriptRelativePath,
    [string[]]$Arguments = @()
  )
  $scriptPath = Join-Path $RepoRoot $ScriptRelativePath
  $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @Arguments 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) {
    Stop-Phase161AValidator -Reason "SCRIPT_FAILED=$ScriptRelativePath output=$($output -join ' | ')"
  }
  return @($output)
}

function Get-Phase161AFileHashMap {
  param([string]$RepoRoot, [string[]]$RelativePaths)
  $hashes = [ordered]@{}
  foreach ($relative in $RelativePaths) {
    $path = Join-Path $RepoRoot $relative
    if (Test-Path -LiteralPath $path) {
      $hashes[$relative] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    } else {
      $hashes[$relative] = "MISSING"
    }
  }
  return $hashes
}

function Test-Phase161AHashMapSame {
  param([hashtable]$Before, [hashtable]$After)
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

$ResolvedRepoRoot = Resolve-Phase161AValidatorRepoRoot -RepoRoot $RepoRoot
$Pushed = $false

try {
  Push-Location $ResolvedRepoRoot
  $Pushed = $true

  $RequiredIdentity = @(
    "CAPABILITY_ROADMAP.json",
    "GENESIS_STATE.json",
    "TASK_QUEUE.json",
    "packs/registry.json",
    "orchestrator/run.ps1"
  )
  foreach ($identityPath in $RequiredIdentity) {
    if (-not (Test-Path -LiteralPath (Join-Path $ResolvedRepoRoot $identityPath))) {
      Stop-Phase161AValidator -Reason "STOP=WRONG_AGENT_BUILDER_REPO missing=$identityPath"
    }
  }

  $InitialBranch = (git branch --show-current).Trim()
  $InitialHead = (git rev-parse HEAD).Trim()
  $InitialRemoteHead = ""
  try {
    $InitialRemoteHead = (git rev-parse "origin/$InitialBranch" 2>$null).Trim()
  } catch {
    $InitialRemoteHead = ""
  }

  $ProtectedStatePaths = @(
    "CAPABILITY_ROADMAP.json",
    "GENESIS_STATE.json",
    "TASK_QUEUE.json",
    "packs/registry.json",
    "orchestrator/run.ps1",
    "route_locks/ACTIVE_ROUTE_LOCK.json"
  )
  $ProtectedHashesBefore = Get-Phase161AFileHashMap -RepoRoot $ResolvedRepoRoot -RelativePaths $ProtectedStatePaths

  $Flags = [ordered]@{
    ACTIVE_ROUTE_LOCK_STAMP_EXPOSED = $false
    CURRICULUM_PACK_SCHEMA_CREATED = $false
    LESSON_SCHEMA_CREATED = $false
    MORNING_REVIEW_SCHEMA_CREATED = $false
    CURRICULUM_INGEST_PASS = $false
    SESSION_LOCAL_BATCH_RUNNER_PASS = $false
    LESSON_RESULTS_WRITTEN = $false
    RUN_CONTINUES_AFTER_FAILED_LESSON = $false
    QUARANTINE_HANDLED_SEPARATELY = $false
    MORNING_REVIEW_CREATED = $false
    FAILURE_CLUSTERING_SKELETON_CREATED = $false
    LIVE_SCHOOL_SURFACE_FIELDS_PRESENT = $false
    PHASE160K_QUALITY_COMPATIBILITY_PRESERVED = $false
    PHASE160J_OWNER_TASK_COMPATIBILITY_PRESERVED = $false
    NO_ACCEPTED_REPO_MUTATION = $false
    NO_PROTECTED_STATE_MUTATION = $false
    RUNTIME_OUTPUTS_STAGED = $false
    NO_COMMIT_PERFORMED = $false
    NO_PUSH_PERFORMED = $false
    NO_BRANCH_SWITCH = $false
  }

  $SchemaPaths = [ordered]@{
    CURRICULUM_PACK_SCHEMA_CREATED = "schemas/builder_school_curriculum_pack.schema.json"
    LESSON_SCHEMA_CREATED = "schemas/builder_school_lesson.schema.json"
    MORNING_REVIEW_SCHEMA_CREATED = "schemas/builder_school_morning_review.schema.json"
  }
  foreach ($flagName in $SchemaPaths.Keys) {
    $schemaPath = Join-Path $ResolvedRepoRoot $SchemaPaths[$flagName]
    Assert-Phase161A -Condition (Test-Path -LiteralPath $schemaPath) -Reason "SCHEMA_MISSING=$($SchemaPaths[$flagName])"
    [void](Read-Phase161AValidatorJson -Path $schemaPath)
    $Flags[$flagName] = $true
  }

  $PowerShellFiles = @(
    "modules/inspect_builder_school_entry_state_001.ps1",
    "modules/validate_builder_curriculum_pack_schema_001.ps1",
    "modules/ingest_builder_curriculum_pack_001.ps1",
    "modules/normalize_builder_lesson_batch_001.ps1",
    "modules/run_builder_school_batch_session_local_001.ps1",
    "modules/write_builder_lesson_result_001.ps1",
    "modules/write_builder_morning_review_001.ps1",
    "modules/inspect_builder_school_batch_readiness_001.ps1",
    "modules/start_builder_live_growth_daemon_001.ps1",
    "modules/watch_builder_live_console_001.ps1",
    "modules/watch_builder_live_growth_session_observer_001.ps1",
    "validators/validate_phase161a_school_entry_foundation_v1.ps1"
  )
  foreach ($file in $PowerShellFiles) {
    Assert-Phase161A -Condition (Test-Phase161APowerShellSyntax -Path (Join-Path $ResolvedRepoRoot $file)) -Reason "POWERSHELL_PARSE_FAIL=$file"
  }

  $RouteState = Invoke-Phase161AJsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/inspect_builder_school_entry_state_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot)
  $Flags.ACTIVE_ROUTE_LOCK_STAMP_EXPOSED = ([bool]$RouteState.active_route_lock_stamp_exposed -and [string]$RouteState.active_route_lock_stamp -match "PHASE161")

  $Stamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
  $ValidatorInputRoot = Join-Path $ResolvedRepoRoot "runtime_sessions/school_runs/PHASE161A_VALIDATOR_INPUT_$Stamp"
  if (-not (Test-Path -LiteralPath $ValidatorInputRoot)) {
    New-Item -ItemType Directory -Force -Path $ValidatorInputRoot | Out-Null
  }
  $CurriculumPath = Join-Path $ValidatorInputRoot "curriculum_pack.json"
  $FailurePolicy = [ordered]@{
    continue_batch = $true
    quarantine_on_safety_violation = $true
  }
  $CurriculumPack = [ordered]@{
    curriculum_id = "PHASE161A_VALIDATOR_CURRICULUM"
    curriculum_version = "1.0.0"
    pack_type = "BUILDER_SCHOOL_CURRICULUM_PACK"
    active_line = "AGENT_BUILDER_SELF_DEVELOPMENT"
    active_mode = "SELF_BUILD"
    route_lock_required = $true
    route_lock_stamp = [string]$RouteState.active_route_lock_stamp
    route_step_id = "PHASE161A_SCHOOL_ENTRY_FOUNDATION_V1"
    title = "PHASE161A bounded school-entry validator curriculum"
    safety_rules = [ordered]@{
      accepted_repo_mutation_allowed = $false
      protected_state_mutation_allowed = $false
      repo_commit_allowed = $false
      repo_push_allowed = $false
      branch_switch_allowed = $false
      runtime_session_only = $true
    }
    lessons = @(
      [ordered]@{
        lesson_id = "PHASE161A_LESSON_ROUTE_STAMP"
        title = "Route stamp intake"
        objective = "Expose the active route lock stamp inside school state."
        inputs = @("route_locks/ACTIVE_ROUTE_LOCK.json")
        expected_outputs = @("ACTIVE_ROUTE_LOCK_STAMP_EXPOSED")
        allowed_actions = @("read_repo", "read_route_lock", "write_runtime")
        failure_policy = $FailurePolicy
      },
      [ordered]@{
        lesson_id = "PHASE161A_LESSON_SCHEMA_PARSE"
        title = "Schema parse"
        objective = "Parse school schemas and write a runtime artifact."
        inputs = @("schemas/builder_school_curriculum_pack.schema.json", "schemas/builder_school_lesson.schema.json")
        expected_outputs = @("CURRICULUM_PACK_SCHEMA_CREATED", "LESSON_SCHEMA_CREATED")
        allowed_actions = @("read_repo", "parse_schema", "write_runtime")
        failure_policy = $FailurePolicy
      },
      [ordered]@{
        lesson_id = "PHASE161A_LESSON_INTENTIONAL_FAIL"
        title = "Intentional failed output"
        objective = "Fail one lesson without stopping the batch."
        inputs = @("runtime_session")
        expected_outputs = @("INTENTIONAL_MISSING_OUTPUT")
        allowed_actions = @("write_runtime")
        failure_policy = $FailurePolicy
      },
      [ordered]@{
        lesson_id = "PHASE161A_LESSON_SAFETY_QUARANTINE"
        title = "Safety quarantine"
        objective = "Quarantine unsafe repo mutation separately from ordinary failure."
        inputs = @("runtime_session")
        expected_outputs = @("QUARANTINE_HANDLED_SEPARATELY")
        allowed_actions = @("commit")
        failure_policy = $FailurePolicy
      }
    )
  }
  Write-Phase161AValidatorJson -Path $CurriculumPath -Object $CurriculumPack

  $CurriculumValidation = Invoke-Phase161AJsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/validate_builder_curriculum_pack_schema_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-CurriculumPackPath", $CurriculumPath)
  $Flags.CURRICULUM_INGEST_PASS = ([string]$CurriculumValidation.status -eq "PASS" -and [bool]$CurriculumValidation.curriculum_ingest_pass)

  $SchoolRunId = "PHASE161A_VALIDATOR_$Stamp"
  $IngestResult = Invoke-Phase161AJsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/ingest_builder_curriculum_pack_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-CurriculumPackPath", $CurriculumPath, "-SchoolRunId", $SchoolRunId)
  Assert-Phase161A -Condition ([string]$IngestResult.status -eq "PASS") -Reason "CURRICULUM_INGEST_SCRIPT_FAILED"

  $RunnerResult = Invoke-Phase161AJsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/run_builder_school_batch_session_local_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-SchoolRunId", $SchoolRunId)
  $Flags.SESSION_LOCAL_BATCH_RUNNER_PASS = ([string]$RunnerResult.status -eq "PASS" -and [bool]$RunnerResult.session_local_batch_runner_pass)
  $Flags.LESSON_RESULTS_WRITTEN = [bool]$RunnerResult.lesson_results_written
  $Flags.RUN_CONTINUES_AFTER_FAILED_LESSON = [bool]$RunnerResult.run_continues_after_failed_lesson
  $Flags.QUARANTINE_HANDLED_SEPARATELY = [bool]$RunnerResult.quarantine_handled_separately
  $Flags.MORNING_REVIEW_CREATED = [bool]$RunnerResult.morning_review_created
  $Flags.FAILURE_CLUSTERING_SKELETON_CREATED = [bool]$RunnerResult.failure_clustering_skeleton_created

  $SchoolRunRoot = Join-Path $ResolvedRepoRoot "runtime_sessions/school_runs/$SchoolRunId"
  $Manifest = Read-Phase161AValidatorJson -Path (Join-Path $SchoolRunRoot "school_run_manifest.json")
  $ResultFiles = @(Get-ChildItem -LiteralPath (Join-Path $SchoolRunRoot "lesson_results") -File -Filter "*_result.json" | Sort-Object Name)
  $Results = @($ResultFiles | ForEach-Object { Read-Phase161AValidatorJson -Path $_.FullName })
  $Review = Read-Phase161AValidatorJson -Path (Join-Path $SchoolRunRoot "morning_review.json")
  Assert-Phase161A -Condition ($ResultFiles.Count -eq 4) -Reason "LESSON_RESULT_COUNT_UNEXPECTED=$($ResultFiles.Count)"
  Assert-Phase161A -Condition ([int]$Manifest.lesson_pass_count -ge 2 -and [int]$Manifest.lesson_fail_count -ge 1 -and [int]$Manifest.lesson_quarantine_count -ge 1) -Reason "LESSON_COUNTS_UNEXPECTED"
  Assert-Phase161A -Condition (@($Review.failure_clusters).Count -ge 1 -and @($Review.quarantine_clusters).Count -ge 1) -Reason "MORNING_REVIEW_CLUSTERS_MISSING"

  $SchoolState = Invoke-Phase161AJsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/inspect_builder_school_entry_state_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-SchoolRunId", $SchoolRunId)
  Assert-Phase161A -Condition ([bool]$SchoolState.school_entry_enabled -and [int]$SchoolState.school_lesson_total_count -eq 4) -Reason "SCHOOL_ENTRY_STATE_INCOMPLETE"

  $Readiness = Invoke-Phase161AJsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/inspect_builder_school_batch_readiness_001.ps1" -Arguments @("-RepoRoot", $ResolvedRepoRoot, "-SchoolRunId", $SchoolRunId)
  Assert-Phase161A -Condition ([string]$Readiness.status -eq "PASS") -Reason "SCHOOL_BATCH_READINESS_FAIL"

  $LiveRunId = "PHASE161A_LIVE_SURFACE_$Stamp"
  Invoke-Phase161AScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/start_builder_live_growth_daemon_001.ps1" -Arguments @("-RunId", $LiveRunId, "-DurationSeconds", "2", "-TickIntervalSeconds", "1") | Out-Null
  $LiveSessionRelative = "runtime_sessions/live_growth/$LiveRunId"
  $LiveSessionRoot = Join-Path $ResolvedRepoRoot $LiveSessionRelative
  $CurrentState = Read-Phase161AValidatorJson -Path (Join-Path $LiveSessionRoot "current_state.json")
  $RequiredLiveStateFields = @(
    "school_entry_enabled",
    "active_school_run_id",
    "active_curriculum_id",
    "school_lesson_total_count",
    "school_lesson_pass_count",
    "school_lesson_fail_count",
    "school_lesson_quarantine_count",
    "school_morning_review_written",
    "school_route_drift_detected",
    "school_owner_review_required",
    "active_route_lock_stamp",
    "current_route_step_id"
  )
  $LiveStateFieldsPresent = $true
  foreach ($field in $RequiredLiveStateFields) {
    if (-not ($CurrentState.PSObject.Properties.Name -contains $field)) {
      $LiveStateFieldsPresent = $false
    }
  }

  $ConsoleRunId = "PHASE161A_CONSOLE_$Stamp"
  Invoke-Phase161AScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/watch_builder_live_console_001.ps1" -Arguments @("-SessionRoot", $LiveSessionRelative, "-RunId", $LiveRunId, "-DurationSeconds", "2", "-PollIntervalSeconds", "1", "-ConsoleRunId", $ConsoleRunId) | Out-Null
  $ConsoleResult = Read-Phase161AValidatorJson -Path (Join-Path $ResolvedRepoRoot "runtime_sessions/live_growth_console/$ConsoleRunId/console_run_result.json")
  $ConsoleSamplePath = Join-Path $ResolvedRepoRoot "runtime_sessions/live_growth_console/$ConsoleRunId/console_output_sample.txt"
  $ConsoleSample = Get-Content -LiteralPath $ConsoleSamplePath -Raw
  $ConsoleTokens = @("SCHOOL_ENTRY=", "ACTIVE_SCHOOL_RUN=", "CURRICULUM_ID=", "LESSON_TOTAL=", "LESSON_PASS=", "LESSON_FAIL=", "LESSON_QUARANTINE=", "MORNING_REVIEW=", "ACTIVE_ROUTE_LOCK=", "ROUTE_STEP=")
  $ConsoleTokensPresent = $true
  foreach ($token in $ConsoleTokens) {
    if ($ConsoleSample -notmatch [regex]::Escape($token)) {
      $ConsoleTokensPresent = $false
    }
  }

  $ObserverResult = Invoke-Phase161AJsonScript -RepoRoot $ResolvedRepoRoot -ScriptRelativePath "modules/watch_builder_live_growth_session_observer_001.ps1" -Arguments @("-SessionRoot", $LiveSessionRelative, "-RunId", $LiveRunId, "-DurationSeconds", "2", "-PollIntervalSeconds", "1")
  $ObserverFieldsPresent = (
    [bool]$ObserverResult.school_run_exists -and
    [bool]$ObserverResult.school_morning_review_exists -and
    [bool]$ObserverResult.school_route_stamp_present -and
    [bool]$ObserverResult.school_no_accepted_repo_mutation -and
    [bool]$ObserverResult.school_no_protected_state_mutation -and
    [bool]$ObserverResult.school_run_continues_after_fail -and
    [bool]$ObserverResult.school_quarantine_handled_separately
  )
  $Flags.LIVE_SCHOOL_SURFACE_FIELDS_PRESENT = ($LiveStateFieldsPresent -and [bool]$ConsoleResult.live_console_shows_phase161a_school_fields -and $ConsoleTokensPresent -and $ObserverFieldsPresent)

  $Phase160KFiles = @(
    "modules/inspect_builder_quality_decision_index_001.ps1",
    "modules/watch_builder_live_console_001.ps1",
    "modules/watch_builder_live_growth_session_observer_001.ps1"
  )
  $Phase160KParserOk = $true
  foreach ($file in $Phase160KFiles) {
    if (-not (Test-Phase161APowerShellSyntax -Path (Join-Path $ResolvedRepoRoot $file))) {
      $Phase160KParserOk = $false
    }
  }
  $Phase160KProofExists = @(Get-ChildItem -LiteralPath (Join-Path $ResolvedRepoRoot "proofs/self_development") -File -Filter "*PHASE160K*PROOF*.json" -ErrorAction SilentlyContinue).Count -gt 0
  $Flags.PHASE160K_QUALITY_COMPATIBILITY_PRESERVED = ($Phase160KParserOk -and $Phase160KProofExists -and [bool]$ConsoleResult.live_console_shows_phase160h_quality_fields)

  $Phase160JFiles = @(
    "modules/inspect_builder_owner_task_lifecycle_state_001.ps1",
    "modules/watch_builder_live_console_001.ps1",
    "modules/watch_builder_live_growth_session_observer_001.ps1"
  )
  $Phase160JParserOk = $true
  foreach ($file in $Phase160JFiles) {
    if (-not (Test-Phase161APowerShellSyntax -Path (Join-Path $ResolvedRepoRoot $file))) {
      $Phase160JParserOk = $false
    }
  }
  $Phase160JProofExists = @(Get-ChildItem -LiteralPath (Join-Path $ResolvedRepoRoot "proofs/self_development") -File -Filter "*PHASE160J*PROOF*.json" -ErrorAction SilentlyContinue).Count -gt 0
  $Flags.PHASE160J_OWNER_TASK_COMPATIBILITY_PRESERVED = ($Phase160JParserOk -and $Phase160JProofExists -and [bool]$ConsoleResult.live_console_shows_phase160j_owner_task_fields)

  $ResultRecordsSafe = (@($Results | Where-Object { [bool]$_.accepted_repo_mutated -or [bool]$_.protected_state_mutated -or [bool]$_.commit_performed -or [bool]$_.push_performed -or [bool]$_.branch_switch_performed }).Count -eq 0)
  $Flags.NO_ACCEPTED_REPO_MUTATION = ((-not [bool]$Manifest.accepted_repo_mutated) -and (-not [bool]$RunnerResult.accepted_repo_mutated) -and $ResultRecordsSafe)
  $ProtectedHashesAfter = Get-Phase161AFileHashMap -RepoRoot $ResolvedRepoRoot -RelativePaths $ProtectedStatePaths
  $Flags.NO_PROTECTED_STATE_MUTATION = (Test-Phase161AHashMapSame -Before $ProtectedHashesBefore -After $ProtectedHashesAfter)
  $StagedRuntimeOutputs = @(git diff --cached --name-only -- runtime_sessions)
  $Flags.RUNTIME_OUTPUTS_STAGED = ($StagedRuntimeOutputs.Count -gt 0)

  $FinalHead = (git rev-parse HEAD).Trim()
  $FinalBranch = (git branch --show-current).Trim()
  $FinalRemoteHead = ""
  try {
    $FinalRemoteHead = (git rev-parse "origin/$InitialBranch" 2>$null).Trim()
  } catch {
    $FinalRemoteHead = ""
  }
  $Flags.NO_COMMIT_PERFORMED = ($FinalHead -eq $InitialHead -and -not [bool]$Manifest.commit_performed -and -not [bool]$RunnerResult.commit_performed)
  $Flags.NO_PUSH_PERFORMED = (([string]::IsNullOrWhiteSpace($InitialRemoteHead) -and [string]::IsNullOrWhiteSpace($FinalRemoteHead)) -or $InitialRemoteHead -eq $FinalRemoteHead)
  $Flags.NO_BRANCH_SWITCH = ($FinalBranch -eq $InitialBranch -and -not [bool]$Manifest.branch_switch_performed -and -not [bool]$RunnerResult.branch_switch_performed)

  foreach ($flagName in $Flags.Keys) {
    if ($flagName -eq "RUNTIME_OUTPUTS_STAGED") {
      Assert-Phase161A -Condition (-not [bool]$Flags[$flagName]) -Reason "$flagName=$($Flags[$flagName])"
    } else {
      Assert-Phase161A -Condition ([bool]$Flags[$flagName]) -Reason "$flagName=False"
    }
  }

  Write-Output "PHASE161A_SCHOOL_ENTRY_FOUNDATION_VALIDATE_RESULT=PASS"
  Write-Output "ACTIVE_ROUTE_LOCK_STAMP_EXPOSED=True"
  Write-Output "CURRICULUM_PACK_SCHEMA_CREATED=True"
  Write-Output "LESSON_SCHEMA_CREATED=True"
  Write-Output "MORNING_REVIEW_SCHEMA_CREATED=True"
  Write-Output "CURRICULUM_INGEST_PASS=True"
  Write-Output "SESSION_LOCAL_BATCH_RUNNER_PASS=True"
  Write-Output "LESSON_RESULTS_WRITTEN=True"
  Write-Output "RUN_CONTINUES_AFTER_FAILED_LESSON=True"
  Write-Output "QUARANTINE_HANDLED_SEPARATELY=True"
  Write-Output "MORNING_REVIEW_CREATED=True"
  Write-Output "FAILURE_CLUSTERING_SKELETON_CREATED=True"
  Write-Output "LIVE_SCHOOL_SURFACE_FIELDS_PRESENT=True"
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
