$ErrorActionPreference = "Continue"
$Ok = $true
function Mark-Fail { param([string]$Message) Write-Output "FAIL=$Message"; $script:Ok = $false }
$StepId = "PHASE117_BUILD_PROOF_AWARE_SELF_NEED_ENGINE_V1"
$NextAllowed = "PHASE118_BUILD_SELF_MODEL_UPDATE_ENGINE_V1"
$EngineOutputPath = "self_build_batch/autonomy_trials/$StepId/PROOF_AWARE_SELF_NEED_ENGINE_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"
foreach ($p in @("modules/invoke_self_need_detection_engine.ps1","orchestrator/run.ps1",$EngineOutputPath,$ResultPath,$ReportPath,$ProofPath)) { if (-not (Test-Path $p)) { Mark-Fail "MISSING=$p" } else { Write-Output "EXISTS=$p" } }
try {
  $Engine = Get-Content $EngineOutputPath -Raw | ConvertFrom-Json
  Write-Output "ENGINE_STATUS=$($Engine.status)"
  Write-Output "ENGINE_PROOF_AWARE=$($Engine.proof_aware)"
  Write-Output "ENGINE_DIAGNOSIS=$($Engine.diagnosis)"
  Write-Output "ENGINE_DETECTED_NEED=$($Engine.detected_need_id)"
  Write-Output "ENGINE_NEXT=$($Engine.recommended_next_step)"
  if ($Engine.status -ne "PASS") { Mark-Fail "ENGINE_NOT_PASS" }
  if ($Engine.proof_aware -ne $true) { Mark-Fail "ENGINE_NOT_PROOF_AWARE" }
  if ($Engine.diagnosis -ne "MISSING_SELF_MODEL_UPDATE_CAPABILITY") { Mark-Fail "ENGINE_DIAGNOSIS_UNEXPECTED=$($Engine.diagnosis)" }
  if ($Engine.detected_need_id -ne "NEED_SELF_MODEL_UPDATE_ENGINE") { Mark-Fail "ENGINE_NEED_UNEXPECTED=$($Engine.detected_need_id)" }
  if ($Engine.recommended_next_step -ne $NextAllowed) { Mark-Fail "ENGINE_NEXT_UNEXPECTED=$($Engine.recommended_next_step)" }
} catch { Mark-Fail "ENGINE_OUTPUT_PARSE_FAIL=$($_.Exception.Message)" }
foreach ($p in @($ResultPath,$ReportPath,$ProofPath)) { try { $obj = Get-Content $p -Raw | ConvertFrom-Json; Write-Output "JSON_PARSE_PASS=$p"; Write-Output "STATUS=$($obj.status)"; Write-Output "NEXT_ALLOWED_STEP=$($obj.next_allowed_step)"; if ($obj.status -ne "PASS") { Mark-Fail "OUTPUT_NOT_PASS=$p" }; if ($obj.next_allowed_step -ne $NextAllowed) { Mark-Fail "OUTPUT_NEXT_STEP_UNEXPECTED=$p :: $($obj.next_allowed_step)" } } catch { Mark-Fail "JSON_PARSE_FAIL=$p :: $($_.Exception.Message)" } }
try { $Queue = Get-Content "TASK_QUEUE.json" -Raw | ConvertFrom-Json; Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"; if ($Queue.active_task_id -ne "NONE") { Mark-Fail "QUEUE_NOT_NONE=$($Queue.active_task_id)" } } catch { Mark-Fail "QUEUE_PARSE_FAIL=$($_.Exception.Message)" }
if ($Ok -eq $true) { Write-Output "PHASE117_PROOF_AWARE_SELF_NEED_VALIDATE_RESULT=PASS" } else { Write-Output "PHASE117_PROOF_AWARE_SELF_NEED_VALIDATE_RESULT=FAIL" }
if ($Ok -ne $true) { throw "PHASE117 proof-aware self-need validation failed." }
