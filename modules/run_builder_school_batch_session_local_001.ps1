param(
  [string]$RepoRoot = "",
  [string]$SchoolRunId = "",
  [string]$SchoolRunRoot = ""
)

$ErrorActionPreference = "Stop"
$Phase161ARunnerSavedRepoRoot = $RepoRoot
$Phase161ARunnerSavedSchoolRunId = $SchoolRunId
$Phase161ARunnerSavedSchoolRunRoot = $SchoolRunRoot
. (Join-Path $PSScriptRoot "write_builder_lesson_result_001.ps1")
$RepoRoot = $Phase161ARunnerSavedRepoRoot
$SchoolRunId = $Phase161ARunnerSavedSchoolRunId
$SchoolRunRoot = $Phase161ARunnerSavedSchoolRunRoot
. (Join-Path $PSScriptRoot "write_builder_morning_review_001.ps1")
$RepoRoot = $Phase161ARunnerSavedRepoRoot
$SchoolRunId = $Phase161ARunnerSavedSchoolRunId
$SchoolRunRoot = $Phase161ARunnerSavedSchoolRunRoot
Remove-Variable -Name Phase161ARunnerSavedRepoRoot,Phase161ARunnerSavedSchoolRunId,Phase161ARunnerSavedSchoolRunRoot -ErrorAction SilentlyContinue

function Resolve-Phase161ARunnerRepoRoot {
  param([string]$RepoRoot)
  if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
    return [System.IO.Path]::GetFullPath($RepoRoot)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
}

function Resolve-Phase161ARunnerSchoolRunRoot {
  param([string]$RepoRoot, [string]$SchoolRunId, [string]$SchoolRunRoot)
  if (-not [string]::IsNullOrWhiteSpace($SchoolRunRoot)) {
    if ([System.IO.Path]::IsPathRooted($SchoolRunRoot)) {
      return [System.IO.Path]::GetFullPath($SchoolRunRoot)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $SchoolRunRoot))
  }
  if ([string]::IsNullOrWhiteSpace($SchoolRunId)) {
    throw "PHASE161A_SCHOOL_RUN_ID_OR_ROOT_REQUIRED"
  }
  return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot "runtime_sessions/school_runs/$SchoolRunId"))
}

function Read-Phase161ARunnerJsonSafe {
  param([string]$Path)
  try {
    if (-not (Test-Path -LiteralPath $Path)) {
      return $null
    }
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
  } catch {
    return $null
  }
}

function Write-Phase161ARunnerJsonFile {
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

function Test-Phase161ALessonUnsafe {
  param([object]$Lesson)
  $unsafeActions = @("commit", "push", "branch_switch", "accepted_repo_mutation", "protected_state_mutation")
  foreach ($action in @($Lesson.allowed_actions | ForEach-Object { [string]$_ })) {
    if ($unsafeActions -contains $action) {
      return $true
    }
  }
  if ($Lesson.PSObject.Properties.Name -contains "safety_rules") {
    $safety = $Lesson.safety_rules
    foreach ($unsafeTrue in @("accepted_repo_mutation_allowed", "protected_state_mutation_allowed", "repo_commit_allowed", "repo_push_allowed", "branch_switch_allowed")) {
      if ($safety.PSObject.Properties.Name -contains $unsafeTrue -and [bool]$safety.$unsafeTrue) {
        return $true
      }
    }
  }
  return $false
}

function Invoke-Phase161ASchoolBatchSessionLocal {
  param(
    [string]$RepoRoot = "",
    [string]$SchoolRunId = "",
    [string]$SchoolRunRoot = ""
  )
  $resolvedRepoRoot = Resolve-Phase161ARunnerRepoRoot -RepoRoot $RepoRoot
  $schoolRunRootFull = Resolve-Phase161ARunnerSchoolRunRoot -RepoRoot $resolvedRepoRoot -SchoolRunId $SchoolRunId -SchoolRunRoot $SchoolRunRoot
  $manifestPath = Join-Path $schoolRunRootFull "school_run_manifest.json"
  $batchPath = Join-Path $schoolRunRootFull "normalized_lesson_batch.json"
  $manifest = Read-Phase161ARunnerJsonSafe -Path $manifestPath
  $batch = Read-Phase161ARunnerJsonSafe -Path $batchPath
  if ($null -eq $manifest) {
    throw "PHASE161A_SCHOOL_RUN_MANIFEST_MISSING"
  }
  if ($null -eq $batch) {
    throw "PHASE161A_NORMALIZED_LESSON_BATCH_MISSING"
  }
  $artifactRoot = Join-Path $schoolRunRootFull "lesson_artifacts"
  if (-not (Test-Path -LiteralPath $artifactRoot)) {
    New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
  }
  $processedResults = @()
  $firstFailIndex = $null
  $runContinuesAfterFailedLesson = $false
  foreach ($lesson in @($batch.lessons)) {
    $lessonIndex = [int]$lesson.lesson_index
    $lessonId = [string]$lesson.lesson_id
    $status = "PASS"
    $failureReason = "NONE"
    $quarantineReason = "NONE"
    $artifacts = @()
    if (Test-Phase161ALessonUnsafe -Lesson $lesson) {
      $status = "QUARANTINED"
      $quarantineReason = "unsafe_action_requested"
    } elseif (@($lesson.expected_outputs | ForEach-Object { [string]$_ }) -contains "INTENTIONAL_MISSING_OUTPUT") {
      $status = "FAIL"
      $failureReason = "missing_expected_output"
    } elseif ($lesson.PSObject.Properties.Name -contains "validator_expectations" -and $lesson.validator_expectations.PSObject.Properties.Name -contains "force_status" -and [string]$lesson.validator_expectations.force_status -eq "FAIL") {
      $status = "FAIL"
      $failureReason = "validator_forced_failure"
    } else {
      $artifactFileName = "{0:d3}_{1}_artifact.txt" -f $lessonIndex, ($lessonId -replace "[^A-Za-z0-9_.-]", "_")
      $artifactPath = Join-Path $artifactRoot $artifactFileName
      [System.IO.File]::WriteAllText($artifactPath, "lesson_id=$lessonId`nstatus=PASS`n", [System.Text.UTF8Encoding]::new($false))
      $artifacts += "lesson_artifacts/$artifactFileName"
    }
    if ($null -ne $firstFailIndex -and $lessonIndex -gt $firstFailIndex) {
      $runContinuesAfterFailedLesson = $true
    }
    $resultRecord = Write-Phase161ALessonResult -SchoolRunRoot $schoolRunRootFull -LessonId $lessonId -LessonIndex $lessonIndex -Status $status -FailureReason $failureReason -QuarantineReason $quarantineReason -ArtifactsCreated $artifacts -ContinuedAfterFailure ($null -ne $firstFailIndex -and $lessonIndex -gt $firstFailIndex)
    $processedResults += [ordered]@{
      lesson_id = $lessonId
      lesson_index = $lessonIndex
      status = $status
      failure_reason = $failureReason
      quarantine_reason = $quarantineReason
      result_path = [string]$resultRecord.result_path
    }
    if ($status -eq "FAIL" -and $null -eq $firstFailIndex) {
      $firstFailIndex = $lessonIndex
    }
  }
  $passCount = @($processedResults | Where-Object { [string]$_.status -eq "PASS" }).Count
  $failCount = @($processedResults | Where-Object { [string]$_.status -eq "FAIL" }).Count
  $quarantineCount = @($processedResults | Where-Object { [string]$_.status -eq "QUARANTINED" }).Count
  $updatedManifest = [ordered]@{
    status = "COMPLETED_SESSION_LOCAL"
    school_run_id = [string]$manifest.school_run_id
    school_run_root = [string]$manifest.school_run_root
    curriculum_id = [string]$manifest.curriculum_id
    curriculum_version = [string]$manifest.curriculum_version
    active_line = [string]$manifest.active_line
    active_mode = [string]$manifest.active_mode
    route_step_id = [string]$manifest.route_step_id
    active_route_lock_stamp = [string]$manifest.active_route_lock_stamp
    active_route_lock_file = [string]$manifest.active_route_lock_file
    branch = [string]$manifest.branch
    run_head = [string]$manifest.run_head
    lesson_total_count = @($processedResults).Count
    lesson_pass_count = $passCount
    lesson_fail_count = $failCount
    lesson_quarantine_count = $quarantineCount
    morning_review_written = $true
    run_continues_after_failed_lesson = $runContinuesAfterFailedLesson
    quarantine_handled_separately = ($failCount -gt 0 -and $quarantineCount -gt 0)
    accepted_repo_mutation_allowed = $false
    protected_state_mutation_allowed = $false
    accepted_repo_mutated = $false
    protected_state_mutated = $false
    commit_performed = $false
    push_performed = $false
    branch_switch_performed = $false
    completed_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Phase161ARunnerJsonFile -Path $manifestPath -Object $updatedManifest
  $morningReview = Write-Phase161AMorningReview -SchoolRunRoot $schoolRunRootFull
  return [pscustomobject][ordered]@{
    status = "PASS"
    session_local_batch_runner_pass = $true
    school_run_id = [string]$updatedManifest.school_run_id
    lesson_total_count = [int]$updatedManifest.lesson_total_count
    lesson_pass_count = [int]$updatedManifest.lesson_pass_count
    lesson_fail_count = [int]$updatedManifest.lesson_fail_count
    lesson_quarantine_count = [int]$updatedManifest.lesson_quarantine_count
    lesson_results_written = (@($processedResults).Count -eq [int]$updatedManifest.lesson_total_count)
    run_continues_after_failed_lesson = $runContinuesAfterFailedLesson
    quarantine_handled_separately = [bool]$updatedManifest.quarantine_handled_separately
    morning_review_created = [bool]$morningReview.morning_review_created
    failure_clustering_skeleton_created = [bool]$morningReview.failure_clustering_skeleton_created
    accepted_repo_mutated = $false
    protected_state_mutated = $false
    commit_performed = $false
    push_performed = $false
    branch_switch_performed = $false
  }
}

if (-not [string]::IsNullOrWhiteSpace($SchoolRunId) -or -not [string]::IsNullOrWhiteSpace($SchoolRunRoot)) {
  Invoke-Phase161ASchoolBatchSessionLocal -RepoRoot $RepoRoot -SchoolRunId $SchoolRunId -SchoolRunRoot $SchoolRunRoot | ConvertTo-Json -Depth 50
}
