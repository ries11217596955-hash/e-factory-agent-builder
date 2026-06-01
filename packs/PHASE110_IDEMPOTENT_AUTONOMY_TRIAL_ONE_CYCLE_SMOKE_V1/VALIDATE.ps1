param(
  [string]$RepoRoot = (Get-Location).Path,
  [string]$RunId = "PHASE110_IDEMPOTENT_SMOKE_001",
  [switch]$InvokedByOrchestrator
)

$ErrorActionPreference = "Continue"
$Ok = $true

function Mark-Fail {
  param([string]$Message)
  Write-Output "FAIL=$Message"
  $script:Ok = $false
}

$PackId = "PHASE110_IDEMPOTENT_AUTONOMY_TRIAL_ONE_CYCLE_SMOKE_V1"
$TaskId = "TASK_PHASE110_IDEMPOTENT_AUTONOMY_TRIAL_ONE_CYCLE_SMOKE_V1_001"
$PackPath = "packs/$PackId/PACK.json"
$TaskPath = "tasks/$TaskId.json"
$ResultPath = "self_build_batch/autonomy_trials/$PackId/PHASE110_SMOKE_RESULT.json"
$ReportPath = "reports/self_development/${PackId}_REPORT.json"
$ProofPath = "proofs/self_development/${PackId}.json"

Push-Location $RepoRoot

Write-Output "PHASE110_IDEMPOTENT_SMOKE_VALIDATE_START"

foreach ($p in @($PackPath, $TaskPath, "TASK_QUEUE.json", "packs/registry.json")) {
  if (-not (Test-Path $p)) {
    Mark-Fail "MISSING=$p"
  } else {
    try {
      Get-Content $p -Raw | ConvertFrom-Json | Out-Null
      Write-Output "JSON_PARSE_PASS=$p"
    } catch {
      Mark-Fail "JSON_PARSE_FAIL=$p :: $($_.Exception.Message)"
    }
  }
}

$Queue = $null
try {
  $Queue = Get-Content "TASK_QUEUE.json" -Raw | ConvertFrom-Json
  Write-Output "ACTIVE_TASK_ID=$($Queue.active_task_id)"
} catch {
  Mark-Fail "QUEUE_PARSE_FAIL=$($_.Exception.Message)"
}

if (Test-Path $ProofPath) {
  foreach ($p in @($ResultPath, $ReportPath, $ProofPath)) {
    if (-not (Test-Path $p)) {
      Mark-Fail "OUTPUT_MISSING=$p"
    } else {
      try {
        $obj = Get-Content $p -Raw | ConvertFrom-Json
        Write-Output "OUTPUT_JSON_PARSE_PASS=$p"
        Write-Output "OUTPUT_STATUS=$($obj.status)"
        Write-Output "OUTPUT_PHASE=$($obj.phase)"
        Write-Output "OUTPUT_NEXT_ALLOWED_STEP=$($obj.next_allowed_step)"
        if ($obj.status -ne "PASS") {
          Mark-Fail "OUTPUT_NOT_PASS=$p"
        }
      } catch {
        Mark-Fail "OUTPUT_JSON_PARSE_FAIL=$p :: $($_.Exception.Message)"
      }
    }
  }

  if ($null -ne $Queue -and $Queue.active_task_id -ne "NONE") {
    Mark-Fail "QUEUE_NOT_NONE_AFTER_COMPLETED=$($Queue.active_task_id)"
  }
} else {
  if ($null -ne $Queue -and $Queue.active_task_id -ne $TaskId) {
    Mark-Fail "SEED_ACTIVE_TASK_NOT_PHASE110_SMOKE=$($Queue.active_task_id)"
  }
}

if ($Ok -eq $true) {
  Write-Output "PHASE110_IDEMPOTENT_SMOKE_VALIDATE_RESULT=PASS"
} else {
  Write-Output "PHASE110_IDEMPOTENT_SMOKE_VALIDATE_RESULT=FAIL"
}

Pop-Location

if ($Ok -ne $true) {
  throw "PHASE110 idempotent smoke validate failed."
}
