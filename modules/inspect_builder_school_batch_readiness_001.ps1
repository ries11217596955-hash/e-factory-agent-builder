param(
  [string]$RepoRoot = "",
  [string]$SchoolRunId = ""
)

$ErrorActionPreference = "Stop"
$Phase161AReadinessSavedRepoRoot = $RepoRoot
$Phase161AReadinessSavedSchoolRunId = $SchoolRunId
. (Join-Path $PSScriptRoot "inspect_builder_school_entry_state_001.ps1")
$RepoRoot = $Phase161AReadinessSavedRepoRoot
$SchoolRunId = $Phase161AReadinessSavedSchoolRunId
Remove-Variable -Name Phase161AReadinessSavedRepoRoot,Phase161AReadinessSavedSchoolRunId -ErrorAction SilentlyContinue

function Test-Phase161ASchoolBatchReadiness {
  param([string]$RepoRoot = "", [string]$SchoolRunId = "")
  $resolvedRepoRoot = Resolve-Phase161ARepoRoot -RepoRoot $RepoRoot
  $requiredFiles = @(
    "schemas/builder_school_curriculum_pack.schema.json",
    "schemas/builder_school_lesson.schema.json",
    "schemas/builder_school_morning_review.schema.json",
    "modules/validate_builder_curriculum_pack_schema_001.ps1",
    "modules/ingest_builder_curriculum_pack_001.ps1",
    "modules/normalize_builder_lesson_batch_001.ps1",
    "modules/run_builder_school_batch_session_local_001.ps1",
    "modules/write_builder_lesson_result_001.ps1",
    "modules/write_builder_morning_review_001.ps1"
  )
  $missing = @()
  foreach ($file in $requiredFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $resolvedRepoRoot $file))) {
      $missing += $file
    }
  }
  $state = Get-Phase161ASchoolEntryState -RepoRoot $resolvedRepoRoot -SchoolRunId $SchoolRunId
  return [pscustomobject][ordered]@{
    status = if ($missing.Count -eq 0 -and [bool]$state.active_route_lock_stamp_exposed) { "PASS" } else { "FAIL" }
    readiness_id = "PHASE161A_SCHOOL_BATCH_READINESS"
    required_file_count = $requiredFiles.Count
    missing_required_files = @($missing)
    active_route_lock_stamp_exposed = [bool]$state.active_route_lock_stamp_exposed
    school_entry_enabled = [bool]$state.school_entry_enabled
    active_school_run_id = [string]$state.active_school_run_id
    active_curriculum_id = [string]$state.active_curriculum_id
    lesson_total_count = [int]$state.school_lesson_total_count
    owner_review_required = [bool]$state.school_owner_review_required
    inspected_at = (Get-Date).ToUniversalTime().ToString("o")
  }
}

if (-not [string]::IsNullOrWhiteSpace($RepoRoot) -or -not [string]::IsNullOrWhiteSpace($SchoolRunId)) {
  Test-Phase161ASchoolBatchReadiness -RepoRoot $RepoRoot -SchoolRunId $SchoolRunId | ConvertTo-Json -Depth 30
}
