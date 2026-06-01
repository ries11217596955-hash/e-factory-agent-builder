$ErrorActionPreference = "Continue"
$Ok = $true
function Mark-Fail { param([string]$Message) Write-Output "FAIL=$Message"; $script:Ok = $false }
$StepId = "PHASE114_BUILD_ADMITTED_ACTION_EXECUTION_ENGINE_V1"
$NextAllowed = "PHASE115_EXECUTE_BUILDER_QUEUED_ADMITTED_ACTION_V1"
$GeneratedPackId = "PHASE115_EXECUTE_BUILDER_QUEUED_ADMITTED_ACTION_V1"
$GeneratedTaskId = "TASK_PHASE115_EXECUTE_BUILDER_QUEUED_ADMITTED_ACTION_V1_001"
$ExecutionOutputPath = "self_build_batch/autonomy_trials/$StepId/ADMITTED_ACTION_EXECUTION_ENGINE_OUTPUT.json"
$ExecutableMovePath = "self_build_batch/autonomy_trials/$StepId/EXECUTABLE_SELF_BUILD_MOVE.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"
foreach ($p in @("modules/invoke_admitted_action_execution_engine.ps1","orchestrator/run.ps1","packs/$GeneratedPackId/PACK.json","packs/$GeneratedPackId/APPLY.ps1","packs/$GeneratedPackId/VALIDATE.ps1","tasks/$GeneratedTaskId.json",$ExecutionOutputPath,$ExecutableMovePath,$ResultPath,$ReportPath,$ProofPath)) { if (-not (Test-Path $p)) { Mark-Fail "MISSING=$p" } else { Write-Output "EXISTS=$p" } }
try {
  $Output = Get-Content $ExecutionOutputPath -Raw | ConvertFrom-Json
  $Move = Get-Content $ExecutableMovePath -Raw | ConvertFrom-Json
  $Queue = Get-Content "TASK_QUEUE.json" -Raw | ConvertFrom-Json
  $Registry = Get-Content "packs/registry.json" -Raw | ConvertFrom-Json
  $Pack = Get-Content "packs/$GeneratedPackId/PACK.json" -Raw | ConvertFrom-Json
  $Task = Get-Content "tasks/$GeneratedTaskId.json" -Raw | ConvertFrom-Json
  Write-Output "EXECUTION_STATUS=$($Output.status)"
  Write-Output "GENERATED_PACK=$($Output.generated_pack_id)"
  Write-Output "GENERATED_TASK=$($Output.generated_task_id)"
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"
  Write-Output "PACK_STATUS=$($Pack.status)"
  Write-Output "TASK_STATUS=$($Task.status)"
  $registeredPack = @($Registry.packs | Where-Object { $_.pack_id -eq $GeneratedPackId })
  $queuedTask = @($Queue.tasks | Where-Object { $_.task_id -eq $GeneratedTaskId })
  if ($Output.status -ne "PASS") { Mark-Fail "EXECUTION_OUTPUT_NOT_PASS" }
  if ($Output.generated_pack_id -ne $GeneratedPackId) { Mark-Fail "GENERATED_PACK_UNEXPECTED=$($Output.generated_pack_id)" }
  if ($Output.generated_task_id -ne $GeneratedTaskId) { Mark-Fail "GENERATED_TASK_UNEXPECTED=$($Output.generated_task_id)" }
  if ($Output.executed_generated_move -ne $false) { Mark-Fail "GENERATED_MOVE_ALREADY_EXECUTED" }
  if ($Output.proposed_next_step -ne $NextAllowed) { Mark-Fail "NEXT_STEP_UNEXPECTED=$($Output.proposed_next_step)" }
  if ($Queue.active_task_id -ne $GeneratedTaskId) { Mark-Fail "QUEUE_ACTIVE_TASK_NOT_GENERATED=$($Queue.active_task_id)" }
  if ($registeredPack.Count -eq 0) { Mark-Fail "GENERATED_PACK_NOT_REGISTERED" }
  if ($queuedTask.Count -eq 0) { Mark-Fail "GENERATED_TASK_NOT_IN_QUEUE" }
  if ($Pack.status -ne "READY") { Mark-Fail "GENERATED_PACK_NOT_READY" }
  if ($Task.status -ne "READY") { Mark-Fail "GENERATED_TASK_NOT_READY" }
} catch { Mark-Fail "EXECUTION_VALIDATE_PARSE_FAIL=$($_.Exception.Message)" }
foreach ($p in @($ResultPath,$ReportPath,$ProofPath)) { try { $obj = Get-Content $p -Raw | ConvertFrom-Json; Write-Output "JSON_PARSE_PASS=$p"; Write-Output "STATUS=$($obj.status)"; Write-Output "NEXT_ALLOWED_STEP=$($obj.next_allowed_step)"; if ($obj.status -ne "PASS") { Mark-Fail "OUTPUT_NOT_PASS=$p" }; if ($obj.next_allowed_step -ne $NextAllowed) { Mark-Fail "OUTPUT_NEXT_STEP_UNEXPECTED=$p :: $($obj.next_allowed_step)" } } catch { Mark-Fail "JSON_PARSE_FAIL=$p :: $($_.Exception.Message)" } }
if ($Ok -eq $true) { Write-Output "PHASE114_ADMITTED_ACTION_EXECUTION_VALIDATE_RESULT=PASS" } else { Write-Output "PHASE114_ADMITTED_ACTION_EXECUTION_VALIDATE_RESULT=FAIL" }
if ($Ok -ne $true) { throw "PHASE114 admitted action execution validation failed." }
