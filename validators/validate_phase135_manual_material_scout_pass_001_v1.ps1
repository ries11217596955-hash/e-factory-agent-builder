$ErrorActionPreference = "Continue"
$Ok = $true

function Mark-Fail {
  param([string]$Message)
  Write-Output "FAIL=$Message"
  $script:Ok = $false
}

$StepId = "PHASE135_RUN_MANUAL_MATERIAL_SCOUT_PASS_001_V1"
$NextAllowed = "PHASE136_IMPORT_MANUAL_MATERIAL_SCOUT_PASS_TO_CATALOG_V1"

$ScoutPath = "materials/MANUAL_SCOUT_PASS_001.json"
$CatalogPath = "materials/MATERIAL_CATALOG.json"
$OutputPath = "self_build_batch/autonomy_trials/$StepId/MANUAL_MATERIAL_SCOUT_PASS_001_OUTPUT.json"
$ResultPath = "self_build_batch/autonomy_trials/$StepId/${StepId}_RESULT.json"
$ReportPath = "reports/self_development/${StepId}_REPORT.json"
$ProofPath = "proofs/self_development/${StepId}.json"

foreach ($p in @(
  "modules/invoke_manual_material_scout_pass_001.ps1",
  "orchestrator/run.ps1",
  $ScoutPath,
  $CatalogPath,
  $OutputPath,
  $ResultPath,
  $ReportPath,
  $ProofPath
)) {
  if (-not (Test-Path $p)) {
    Mark-Fail "MISSING=$p"
  } else {
    Write-Output "EXISTS=$p"
  }
}

try {
  $Scout = Get-Content $ScoutPath -Raw | ConvertFrom-Json
  $Catalog = Get-Content $CatalogPath -Raw | ConvertFrom-Json
  $Output = Get-Content $OutputPath -Raw | ConvertFrom-Json
  $Queue = Get-Content "TASK_QUEUE.json" -Raw | ConvertFrom-Json

  Write-Output "SCOUT_STATUS=$($Scout.status)"
  Write-Output "SCOUT_ID=$($Scout.scout_pass_id)"
  Write-Output "SCOUT_CANDIDATE_COUNT=$($Scout.candidate_material_count)"
  Write-Output "SCOUT_REFERENCE_ONLY_COUNT=$($Scout.reference_only_material_count)"
  Write-Output "SCOUT_TRUSTED_COUNT=$($Scout.trusted_material_count)"
  Write-Output "CATALOG_STATUS=$($Catalog.status)"
  Write-Output "CATALOG_CANDIDATE_COUNT=$($Catalog.candidate_material_count)"
  Write-Output "CATALOG_TRUSTED_COUNT=$($Catalog.trusted_material_count)"
  Write-Output "OUTPUT_STATUS=$($Output.status)"
  Write-Output "OUTPUT_NEXT=$($Output.proposed_next_step)"
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"

  if ($Scout.status -ne "PASS") { Mark-Fail "SCOUT_NOT_PASS" }
  if ($Scout.scout_pass_id -ne "MANUAL_MATERIAL_SCOUT_PASS_001") { Mark-Fail "SCOUT_ID_UNEXPECTED=$($Scout.scout_pass_id)" }
  if ($Scout.candidate_material_count -ne 3) { Mark-Fail "SCOUT_CANDIDATE_COUNT_UNEXPECTED=$($Scout.candidate_material_count)" }
  if ($Scout.reference_only_material_count -ne 1) { Mark-Fail "SCOUT_REFERENCE_ONLY_COUNT_UNEXPECTED=$($Scout.reference_only_material_count)" }
  if ($Scout.trusted_material_count -ne 0) { Mark-Fail "SCOUT_TRUSTED_COUNT_NOT_ZERO=$($Scout.trusted_material_count)" }
  if ($Scout.external_fetch_performed_by_runtime -ne $false) { Mark-Fail "SCOUT_EXTERNAL_FETCH_TRUE" }
  if ($Scout.dependency_install_performed -ne $false) { Mark-Fail "SCOUT_DEPENDENCY_INSTALL_TRUE" }

  $materials = @($Catalog.materials)
  if ($materials.Count -ne 4) { Mark-Fail "CATALOG_MATERIAL_COUNT_UNEXPECTED=$($materials.Count)" }

  foreach ($m in $materials) {
    if ($m.owner_decision_required -ne $true) { Mark-Fail "MATERIAL_OWNER_DECISION_NOT_TRUE=$($m.material_id)" }
    if ($m.initial_status -eq "TRUSTED" -or $m.initial_status -eq "TESTED" -or $m.initial_status -eq "WRAPPED") {
      Mark-Fail "MATERIAL_FORBIDDEN_INITIAL_STATUS=$($m.material_id)::$($m.initial_status)"
    }
  }

  if ($Catalog.trusted_material_count -ne 0) { Mark-Fail "CATALOG_TRUSTED_COUNT_NOT_ZERO=$($Catalog.trusted_material_count)" }
  if ($Catalog.next_allowed_step -ne $NextAllowed) { Mark-Fail "CATALOG_NEXT_UNEXPECTED=$($Catalog.next_allowed_step)" }
  if ($Output.status -ne "PASS") { Mark-Fail "OUTPUT_NOT_PASS" }
  if ($Output.proposed_next_step -ne $NextAllowed) { Mark-Fail "OUTPUT_NEXT_UNEXPECTED=$($Output.proposed_next_step)" }
  if ($Queue.active_task_id -ne "NONE") { Mark-Fail "QUEUE_NOT_NONE=$($Queue.active_task_id)" }
} catch {
  Mark-Fail "MANUAL_SCOUT_VALIDATE_PARSE_FAIL=$($_.Exception.Message)"
}

foreach ($p in @($ResultPath,$ReportPath,$ProofPath)) {
  try {
    $obj = Get-Content $p -Raw | ConvertFrom-Json
    Write-Output "JSON_PARSE_PASS=$p"
    Write-Output "STATUS=$($obj.status)"
    Write-Output "NEXT_ALLOWED_STEP=$($obj.next_allowed_step)"

    if ($obj.status -ne "PASS") { Mark-Fail "OUTPUT_ARTIFACT_NOT_PASS=$p" }
    if ($obj.next_allowed_step -ne $NextAllowed) { Mark-Fail "OUTPUT_ARTIFACT_NEXT_UNEXPECTED=$p :: $($obj.next_allowed_step)" }
  } catch {
    Mark-Fail "JSON_PARSE_FAIL=$p :: $($_.Exception.Message)"
  }
}

if ($Ok -eq $true) {
  Write-Output "PHASE135_MANUAL_MATERIAL_SCOUT_PASS_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE135_MANUAL_MATERIAL_SCOUT_PASS_VALIDATE_RESULT=FAIL"
}

if ($Ok -ne $true) {
  throw "PHASE135 validation failed."
}
