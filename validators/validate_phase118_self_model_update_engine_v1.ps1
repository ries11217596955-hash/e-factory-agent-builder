$ErrorActionPreference = "Continue"
$Ok = $true
function Mark-Fail { param([string]$Message) Write-Output "FAIL=$Message"; $script:Ok = $false }
$StepId = "PHASE118_BUILD_SELF_MODEL_UPDATE_ENGINE_V1"
$NextAllowed = "PHASE119_BUILD_SELF_MODEL_AWARE_DECISION_LOOP_V1"
$SelfModelPath = "self_model/BUILDER_SELF_MODEL.json"
$EngineOutputPath = "self_build_batch/autonomy_trials/$StepId/SELF_MODEL_UPDATE_ENGINE_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"
foreach ($p in @("modules/invoke_self_model_update_engine.ps1","modules/invoke_self_need_detection_engine.ps1","orchestrator/run.ps1",$SelfModelPath,$EngineOutputPath,$ResultPath,$ReportPath,$ProofPath)) { if (-not (Test-Path $p)) { Mark-Fail "MISSING=$p" } else { Write-Output "EXISTS=$p" } }
try {
  $SelfModel = Get-Content $SelfModelPath -Raw | ConvertFrom-Json
  $Engine = Get-Content $EngineOutputPath -Raw | ConvertFrom-Json
  $Queue = Get-Content "TASK_QUEUE.json" -Raw | ConvertFrom-Json
  Write-Output "SELF_MODEL_STATUS=$($SelfModel.status)"
  Write-Output "SELF_MODEL_ID=$($SelfModel.self_model_id)"
  Write-Output "SELF_MODEL_CURRENT_NEED=$($SelfModel.current_detected_need)"
  Write-Output "SELF_MODEL_NEXT=$($SelfModel.recommended_next_step)"
  Write-Output "ENGINE_STATUS=$($Engine.status)"
  Write-Output "ENGINE_UPDATED=$($Engine.self_model_updated)"
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"
  $proven = @($SelfModel.proven_capabilities | Where-Object { $_.status -eq "PROVEN" })
  if ($SelfModel.status -ne "PASS") { Mark-Fail "SELF_MODEL_NOT_PASS" }
  if ($SelfModel.current_detected_need -ne "NEED_SELF_MODEL_AWARE_DECISION_LOOP") { Mark-Fail "SELF_MODEL_NEED_UNEXPECTED=$($SelfModel.current_detected_need)" }
  if ($SelfModel.recommended_next_step -ne $NextAllowed) { Mark-Fail "SELF_MODEL_NEXT_UNEXPECTED=$($SelfModel.recommended_next_step)" }
  if ($proven.Count -lt 8) { Mark-Fail "PROVEN_CAPABILITY_COUNT_TOO_LOW=$($proven.Count)" }
  if ($Engine.status -ne "PASS") { Mark-Fail "ENGINE_NOT_PASS" }
  if ($Engine.self_model_updated -ne $true) { Mark-Fail "ENGINE_SELF_MODEL_UPDATED_NOT_TRUE" }
  if ($Engine.proposed_next_step -ne $NextAllowed) { Mark-Fail "ENGINE_NEXT_UNEXPECTED=$($Engine.proposed_next_step)" }
  if ($Queue.active_task_id -ne "NONE") { Mark-Fail "QUEUE_NOT_NONE=$($Queue.active_task_id)" }
} catch { Mark-Fail "SELF_MODEL_VALIDATE_PARSE_FAIL=$($_.Exception.Message)" }
foreach ($p in @($ResultPath,$ReportPath,$ProofPath)) { try { $obj = Get-Content $p -Raw | ConvertFrom-Json; Write-Output "JSON_PARSE_PASS=$p"; Write-Output "STATUS=$($obj.status)"; Write-Output "NEXT_ALLOWED_STEP=$($obj.next_allowed_step)"; if ($obj.status -ne "PASS") { Mark-Fail "OUTPUT_NOT_PASS=$p" }; if ($obj.next_allowed_step -ne $NextAllowed) { Mark-Fail "OUTPUT_NEXT_STEP_UNEXPECTED=$p :: $($obj.next_allowed_step)" } } catch { Mark-Fail "JSON_PARSE_FAIL=$p :: $($_.Exception.Message)" } }
if ($Ok -eq $true) { Write-Output "PHASE118_SELF_MODEL_UPDATE_VALIDATE_RESULT=PASS" } else { Write-Output "PHASE118_SELF_MODEL_UPDATE_VALIDATE_RESULT=FAIL" }
if ($Ok -ne $true) { throw "PHASE118 self-model update validation failed." }
