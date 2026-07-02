param(
  [string]$RepoRoot = (Get-Location).Path,
  [string]$RunId = "PHASE115_EXECUTE_BUILDER_QUEUED_ADMITTED_ACTION_V1",
  [switch]$InvokedByOrchestrator
)
$ErrorActionPreference = "Continue"
$Ok = $true
function Mark-Fail { param([string]$Message) Write-Output "FAIL=$Message"; $script:Ok = $false }
$PackId = "PHASE115_EXECUTE_BUILDER_QUEUED_ADMITTED_ACTION_V1"
$TaskId = "TASK_PHASE115_EXECUTE_BUILDER_QUEUED_ADMITTED_ACTION_V1_001"
$NextAllowed = "PHASE116_BUILDER_AUTONOMOUS_CHAIN_SMOKE_V1"
$ResultPath = "self_build_batch/autonomy_trials/$PackId/${PackId}_RESULT.json"
$ReportPath = "reports/self_development/${PackId}_REPORT.json"
$ProofPath = "proofs/self_development/$PackId.json"
Push-Location $RepoRoot
Write-Output "PHASE115_GENERATED_MOVE_VALIDATE_START"
foreach ($p in @("TASK_QUEUE.json", "packs/registry.json", "packs/$PackId/PACK.json", "tasks/$TaskId.json")) { if (-not (Test-Path $p)) { Mark-Fail "MISSING=$p" } else { try { Get-Content $p -Raw | ConvertFrom-Json | Out-Null; Write-Output "JSON_PARSE_PASS=$p" } catch { Mark-Fail "JSON_PARSE_FAIL=$p :: $($_.Exception.Message)" } } }
try { $Queue = Get-Content "TASK_QUEUE.json" -Raw | ConvertFrom-Json; Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)" } catch { Mark-Fail "QUEUE_PARSE_FAIL=$($_.Exception.Message)" }
if (Test-Path $ProofPath) { foreach ($p in @($ResultPath, $ReportPath, $ProofPath)) { try { $obj = Get-Content $p -Raw | ConvertFrom-Json; Write-Output "OUTPUT_JSON_PARSE_PASS=$p"; Write-Output "OUTPUT_STATUS=$($obj.status)"; Write-Output "OUTPUT_NEXT_ALLOWED_STEP=$($obj.next_allowed_step)"; if ($obj.status -ne "PASS") { Mark-Fail "OUTPUT_NOT_PASS=$p" }; if ($obj.next_allowed_step -ne $NextAllowed) { Mark-Fail "OUTPUT_NEXT_STEP_UNEXPECTED=$($obj.next_allowed_step)" } } catch { Mark-Fail "OUTPUT_JSON_PARSE_FAIL=$p :: $($_.Exception.Message)" } }; if ($Queue.active_task_id -ne "NONE") { Mark-Fail "QUEUE_NOT_NONE_AFTER_EXECUTION=$($Queue.active_task_id)" } } else { if ($Queue.active_task_id -ne $TaskId) { Mark-Fail "QUEUE_NOT_READY_FOR_GENERATED_TASK=$($Queue.active_task_id)" } }
if ($Ok -eq $true) { Write-Output "PHASE115_GENERATED_MOVE_VALIDATE_RESULT=PASS" } else { Write-Output "PHASE115_GENERATED_MOVE_VALIDATE_RESULT=FAIL" }
Pop-Location
if ($Ok -ne $true) { throw "PHASE115 generated move validate failed." }
