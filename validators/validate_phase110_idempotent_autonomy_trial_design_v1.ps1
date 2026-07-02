$ErrorActionPreference = "Continue"
$Ok = $true

function Mark-Fail {
  param([string]$Message)
  Write-Output "FAIL=$Message"
  $script:Ok = $false
}

$DesignId = "PHASE110_IDEMPOTENT_AUTONOMY_TRIAL_DESIGN_V1"
$DesignPath = "self_build_batch/autonomy_trials/$DesignId/$DesignId.json"
$ReportPath = "reports/self_development/${DesignId}_REPORT.json"
$ProofPath = "proofs/self_development/${DesignId}.json"

foreach ($p in @($DesignPath, $ReportPath, $ProofPath)) {
  if (-not (Test-Path $p)) {
    Mark-Fail "MISSING=$p"
  } else {
    try {
      $obj = Get-Content $p -Raw | ConvertFrom-Json
      Write-Output "JSON_PARSE_PASS=$p"
      Write-Output "STATUS=$($obj.status)"
      Write-Output "PHASE=$($obj.phase)"
      Write-Output "NEXT_ALLOWED_STEP=$($obj.next_allowed_step)"
    } catch {
      Mark-Fail "JSON_PARSE_FAIL=$p :: $($_.Exception.Message)"
    }
  }
}

try {
  $Design = Get-Content $DesignPath -Raw | ConvertFrom-Json
  $Proof = Get-Content $ProofPath -Raw | ConvertFrom-Json

  if ($Design.runtime_executed -ne $false) { Mark-Fail "DESIGN_RUNTIME_EXECUTED_NOT_FALSE" }
  if ($Design.builder_executed -ne $false) { Mark-Fail "DESIGN_BUILDER_EXECUTED_NOT_FALSE" }
  if ($Design.codex_used -ne $false) { Mark-Fail "DESIGN_CODEX_USED_NOT_FALSE" }
  if ($Design.execution_policy.no_large_json_object_rewrite -ne $true) { Mark-Fail "NO_LARGE_JSON_RULE_MISSING" }
  if ($Design.execution_policy.resume_must_skip_completed_cycles -ne $true) { Mark-Fail "RESUME_RULE_MISSING" }
  if ($Proof.status -ne "PASS") { Mark-Fail "PROOF_NOT_PASS" }
  if ($Proof.runtime_executed -ne $false) { Mark-Fail "PROOF_RUNTIME_EXECUTED_NOT_FALSE" }
} catch {
  Mark-Fail "CONTENT_CHECK_ERROR=$($_.Exception.Message)"
}

if ($Ok -eq $true) {
  Write-Output "PHASE110_DESIGN_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE110_DESIGN_VALIDATE_RESULT=FAIL"
}
