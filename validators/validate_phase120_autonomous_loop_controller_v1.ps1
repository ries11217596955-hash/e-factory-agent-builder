$ErrorActionPreference = "Continue"
$Ok = $true
function Mark-Fail { param([string]$Message) Write-Output "FAIL=$Message"; $script:Ok = $false }
$StepId = "PHASE120_BUILD_AUTONOMOUS_LOOP_CONTROLLER_V1"
$NextAllowed = "PHASE121_RUN_BOUNDED_AUTONOMOUS_LOOP_TRIAL_V1"
$ControllerPath = "self_control/AUTONOMOUS_LOOP_CONTROLLER.json"
$ControllerOutputPath = "self_build_batch/autonomy_trials/$StepId/AUTONOMOUS_LOOP_CONTROLLER_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"
foreach ($p in @("modules/invoke_autonomous_loop_controller.ps1","modules/invoke_self_model_aware_decision_loop.ps1","orchestrator/run.ps1",$ControllerPath,$ControllerOutputPath,$ResultPath,$ReportPath,$ProofPath)) { if (-not (Test-Path $p)) { Mark-Fail "MISSING=$p" } else { Write-Output "EXISTS=$p" } }
try {
  $Controller = Get-Content $ControllerPath -Raw | ConvertFrom-Json
  $Output = Get-Content $ControllerOutputPath -Raw | ConvertFrom-Json
  $Queue = Get-Content "TASK_QUEUE.json" -Raw | ConvertFrom-Json
  Write-Output "CONTROLLER_STATUS=$($Controller.status)"
  Write-Output "CONTROLLER_ID=$($Controller.controller_id)"
  Write-Output "CONTROLLER_MAX_RUNTIME_CALLS=$($Controller.max_runtime_calls_per_trial)"
  Write-Output "CONTROLLER_NEXT=$($Controller.next_trial)"
  Write-Output "OUTPUT_STATUS=$($Output.status)"
  Write-Output "OUTPUT_NEXT=$($Output.proposed_next_step)"
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"
  if ($Controller.status -ne "PASS") { Mark-Fail "CONTROLLER_NOT_PASS" }
  if ($Controller.controller_id -ne "AUTONOMOUS_LOOP_CONTROLLER_V1") { Mark-Fail "CONTROLLER_ID_UNEXPECTED=$($Controller.controller_id)" }
  if ($Controller.max_runtime_calls_per_trial -ne 2) { Mark-Fail "CONTROLLER_MAX_RUNTIME_UNEXPECTED=$($Controller.max_runtime_calls_per_trial)" }
  if ($Controller.require_queue_none_at_start -ne $true) { Mark-Fail "CONTROLLER_QUEUE_GATE_NOT_TRUE" }
  if ($Controller.require_proof_before_next_phase -ne $true) { Mark-Fail "CONTROLLER_PROOF_GATE_NOT_TRUE" }
  if ($Controller.next_trial -ne $NextAllowed) { Mark-Fail "CONTROLLER_NEXT_UNEXPECTED=$($Controller.next_trial)" }
  if ($Output.status -ne "PASS") { Mark-Fail "OUTPUT_NOT_PASS" }
  if ($Output.controller_created -ne $true) { Mark-Fail "OUTPUT_CONTROLLER_CREATED_NOT_TRUE" }
  if ($Output.proposed_next_step -ne $NextAllowed) { Mark-Fail "OUTPUT_NEXT_UNEXPECTED=$($Output.proposed_next_step)" }
  if ($Queue.active_task_id -ne "NONE") { Mark-Fail "QUEUE_NOT_NONE=$($Queue.active_task_id)" }
} catch { Mark-Fail "CONTROLLER_VALIDATE_PARSE_FAIL=$($_.Exception.Message)" }
foreach ($p in @($ResultPath,$ReportPath,$ProofPath)) { try { $obj = Get-Content $p -Raw | ConvertFrom-Json; Write-Output "JSON_PARSE_PASS=$p"; Write-Output "STATUS=$($obj.status)"; Write-Output "NEXT_ALLOWED_STEP=$($obj.next_allowed_step)"; if ($obj.status -ne "PASS") { Mark-Fail "OUTPUT_ARTIFACT_NOT_PASS=$p" }; if ($obj.next_allowed_step -ne $NextAllowed) { Mark-Fail "OUTPUT_ARTIFACT_NEXT_UNEXPECTED=$p :: $($obj.next_allowed_step)" } } catch { Mark-Fail "JSON_PARSE_FAIL=$p :: $($_.Exception.Message)" } }
if ($Ok -eq $true) { Write-Output "PHASE120_AUTONOMOUS_LOOP_CONTROLLER_VALIDATE_RESULT=PASS" } else { Write-Output "PHASE120_AUTONOMOUS_LOOP_CONTROLLER_VALIDATE_RESULT=FAIL" }
if ($Ok -ne $true) { throw "PHASE120 validation failed." }
