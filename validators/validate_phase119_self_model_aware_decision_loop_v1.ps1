$ErrorActionPreference = "Continue"
$Ok = $true
function Mark-Fail { param([string]$Message) Write-Output "FAIL=$Message"; $script:Ok = $false }
$StepId = "PHASE119_BUILD_SELF_MODEL_AWARE_DECISION_LOOP_V1"
$NextAllowed = "PHASE120_BUILD_AUTONOMOUS_LOOP_CONTROLLER_V1"
$LoopOutputPath = "self_build_batch/autonomy_trials/$StepId/SELF_MODEL_AWARE_DECISION_LOOP_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"
foreach ($p in @("modules/invoke_self_model_aware_decision_loop.ps1","modules/invoke_self_model_update_engine.ps1","self_model/BUILDER_SELF_MODEL.json","orchestrator/run.ps1",$LoopOutputPath,$ResultPath,$ReportPath,$ProofPath)) { if (-not (Test-Path $p)) { Mark-Fail "MISSING=$p" } else { Write-Output "EXISTS=$p" } }
try {
  $Loop = Get-Content $LoopOutputPath -Raw | ConvertFrom-Json
  $SelfModel = Get-Content "self_model/BUILDER_SELF_MODEL.json" -Raw | ConvertFrom-Json
  $Queue = Get-Content "TASK_QUEUE.json" -Raw | ConvertFrom-Json
  Write-Output "LOOP_STATUS=$($Loop.status)"
  Write-Output "LOOP_DECISION_ID=$($Loop.decision_id)"
  Write-Output "LOOP_SELECTED_NEED=$($Loop.selected_need_id)"
  Write-Output "LOOP_NEXT=$($Loop.proposed_next_step)"
  Write-Output "SELF_MODEL_CURRENT_NEED=$($SelfModel.current_detected_need)"
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"
  if ($Loop.status -ne "PASS") { Mark-Fail "LOOP_NOT_PASS" }
  if ($Loop.selected_need_id -ne "NEED_AUTONOMOUS_LOOP_CONTROLLER") { Mark-Fail "LOOP_NEED_UNEXPECTED=$($Loop.selected_need_id)" }
  if ($Loop.selected_target_capability -ne "AUTONOMOUS_LOOP_CONTROLLER") { Mark-Fail "LOOP_TARGET_UNEXPECTED=$($Loop.selected_target_capability)" }
  if ($Loop.proposed_next_step -ne $NextAllowed) { Mark-Fail "LOOP_NEXT_UNEXPECTED=$($Loop.proposed_next_step)" }
  if ($Queue.active_task_id -ne "NONE") { Mark-Fail "QUEUE_NOT_NONE=$($Queue.active_task_id)" }
} catch { Mark-Fail "LOOP_VALIDATE_PARSE_FAIL=$($_.Exception.Message)" }
foreach ($p in @($ResultPath,$ReportPath,$ProofPath)) { try { $obj = Get-Content $p -Raw | ConvertFrom-Json; Write-Output "JSON_PARSE_PASS=$p"; Write-Output "STATUS=$($obj.status)"; Write-Output "NEXT_ALLOWED_STEP=$($obj.next_allowed_step)"; if ($obj.status -ne "PASS") { Mark-Fail "OUTPUT_NOT_PASS=$p" }; if ($obj.next_allowed_step -ne $NextAllowed) { Mark-Fail "OUTPUT_NEXT_STEP_UNEXPECTED=$p :: $($obj.next_allowed_step)" } } catch { Mark-Fail "JSON_PARSE_FAIL=$p :: $($_.Exception.Message)" } }
if ($Ok -eq $true) { Write-Output "PHASE119_SELF_MODEL_AWARE_DECISION_LOOP_VALIDATE_RESULT=PASS" } else { Write-Output "PHASE119_SELF_MODEL_AWARE_DECISION_LOOP_VALIDATE_RESULT=FAIL" }
if ($Ok -ne $true) { throw "PHASE119 validation failed." }
