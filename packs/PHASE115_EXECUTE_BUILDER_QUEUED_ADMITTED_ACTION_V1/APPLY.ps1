param(
  [string]$RepoRoot = (Get-Location).Path,
  [string]$RunId = "PHASE115_EXECUTE_BUILDER_QUEUED_ADMITTED_ACTION_V1",
  [switch]$InvokedByOrchestrator
)
$ErrorActionPreference = "Continue"
$Ok = $true
function Mark-Fail { param([string]$Message) Write-Output "FAIL=$Message"; $script:Ok = $false }
function Write-JsonFile { param($Path, $Object, [int]$Depth = 20) $dir = Split-Path $Path -Parent; if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }; $Object | ConvertTo-Json -Depth $Depth | Set-Content -Path $Path -Encoding UTF8 }
$PackId = "PHASE115_EXECUTE_BUILDER_QUEUED_ADMITTED_ACTION_V1"
$TaskId = "TASK_PHASE115_EXECUTE_BUILDER_QUEUED_ADMITTED_ACTION_V1_001"
$NextAllowed = "PHASE116_BUILDER_AUTONOMOUS_CHAIN_SMOKE_V1"
$ResultPath = "self_build_batch/autonomy_trials/$PackId/${PackId}_RESULT.json"
$ReportPath = "reports/self_development/${PackId}_REPORT.json"
$ProofPath = "proofs/self_development/$PackId.json"
Push-Location $RepoRoot
Write-Output "PHASE115_GENERATED_MOVE_APPLY_START"
Write-Output "RUN_ID=$RunId"
try {
  $Queue = Get-Content "TASK_QUEUE.json" -Raw | ConvertFrom-Json
  Write-Output "ACTIVE_TASK_ID_AT_APPLY=$($Queue.active_task_id)"
  if ($Queue.active_task_id -ne $TaskId) { Mark-Fail "ACTIVE_TASK_ID_NOT_GENERATED_TASK=$($Queue.active_task_id)" }
  $tasks = @($Queue.tasks)
  $task = @($tasks | Where-Object { $_.task_id -eq $TaskId })
  if ($task.Count -eq 0) { Mark-Fail "GENERATED_TASK_NOT_FOUND=$TaskId" } else { $task[0].status = "COMPLETED" }
  $Queue.tasks = @($tasks)
  $Queue.active_task_id = "NONE"
  Write-JsonFile "TASK_QUEUE.json" $Queue 24
} catch { Mark-Fail "GENERATED_MOVE_APPLY_ERROR=$($_.Exception.Message)" }
$status = if ($Ok -eq $true) { "PASS" } else { "FAIL" }
$Result = [ordered]@{ status = $status; phase = $PackId; task_id = $TaskId; run_id = $RunId; runtime_executed = $true; builder_executed = $true; generated_by_phase114 = $true; queue_returned_to_none = $true; codex_used = $false; main_touched = $false; next_allowed_step = $NextAllowed }
$Report = [ordered]@{ status = $status; report_id = "${PackId}_REPORT"; phase = $PackId; summary = "Generated admitted-action self-build move executed and returned queue to NONE."; next_allowed_step = $NextAllowed }
$Proof = [ordered]@{ status = $status; proof_id = $PackId; phase = $PackId; runtime_mode = "SELF_BUILD_GENERATED_ADMITTED_ACTION_MOVE"; generated_by_phase114 = $true; queue_returned_to_none = $true; codex_used = $false; main_touched = $false; result_path = $ResultPath; report_path = $ReportPath; next_allowed_step = $NextAllowed }
Write-JsonFile $ResultPath $Result 16
Write-JsonFile $ReportPath $Report 16
Write-JsonFile $ProofPath $Proof 16
if ($Ok -eq $true) { Write-Output "PHASE115_GENERATED_MOVE_APPLY_RESULT=PASS"; Write-Output "TASK_QUEUE_RETURNED_TO_NONE" } else { Write-Output "PHASE115_GENERATED_MOVE_APPLY_RESULT=FAIL" }
Pop-Location
if ($Ok -ne $true) { throw "PHASE115 generated move apply failed." }
