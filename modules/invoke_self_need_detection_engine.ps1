function Read-JsonOptional {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return $null }
  try { return Get-Content $Path -Raw | ConvertFrom-Json } catch { return $null }
}

function Write-JsonFile {
  param($Path, $Object, [int]$Depth = 20)
  $dir = Split-Path $Path -Parent
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $Object | ConvertTo-Json -Depth $Depth | Set-Content -Path $Path -Encoding UTF8
}

function Invoke-SelfNeedDetectionEngine {
  param(
    [string]$RepoRoot,
    [string]$RunId,
    [string]$OutputRoot
  )

  Push-Location $RepoRoot

  try {
    if (-not (Test-Path $OutputRoot)) { New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null }

    $CanonicalRoot = "self_build_batch/autonomy_trials/PHASE117_BUILD_PROOF_AWARE_SELF_NEED_ENGINE_V1"
    if (-not (Test-Path $CanonicalRoot)) { New-Item -ItemType Directory -Force -Path $CanonicalRoot | Out-Null }

    $Queue = Read-JsonOptional "TASK_QUEUE.json"
    $P110 = Read-JsonOptional "proofs/self_development/PHASE110_FINALIZE_IDEMPOTENT_AUTONOMY_TRIAL_V1.json"
    $P111 = Read-JsonOptional "proofs/self_development/PHASE111_BUILD_NEXT_ACTION_DECISION_KERNEL_V1.json"
    $P112 = Read-JsonOptional "proofs/self_development/PHASE112_BUILD_DECISION_TO_ACTION_ENGINE_V1.json"
    $P113 = Read-JsonOptional "proofs/self_development/PHASE113_BUILD_DECISION_ACTION_ADMISSION_BRIDGE_V1.json"
    $P114 = Read-JsonOptional "proofs/self_development/PHASE114_BUILD_ADMITTED_ACTION_EXECUTION_ENGINE_V1.json"
    $P115 = Read-JsonOptional "proofs/self_development/PHASE115_EXECUTE_BUILDER_QUEUED_ADMITTED_ACTION_V1.json"
    $P116 = Read-JsonOptional "proofs/self_development/PHASE116_BUILDER_AUTONOMOUS_CHAIN_SMOKE_V1.json"

    $status = "PASS"
    $diagnosis = "UNKNOWN"
    $detectedNeedId = ""
    $missingCapability = ""
    $recommendedNextStep = "PHASE118_BUILD_SELF_MODEL_UPDATE_ENGINE_V1"
    $reason = ""

    if ($null -eq $Queue) {
      $status = "BLOCKED"
      $diagnosis = "QUEUE_UNREADABLE"
      $detectedNeedId = "NEED_QUEUE_STATE_REPAIR"
      $missingCapability = "QUEUE_STATE_RELIABILITY"
      $recommendedNextStep = "PHASE118_REPAIR_QUEUE_STATE_ACCESS_V1"
      $reason = "TASK_QUEUE.json could not be read."
    } elseif ($Queue.active_task_id -ne "NONE") {
      $status = "BLOCKED"
      $diagnosis = "QUEUE_NOT_EMPTY"
      $detectedNeedId = "NEED_QUEUE_SAFETY_REVIEW"
      $missingCapability = "SAFE_DECISION_REQUIRES_EMPTY_OR_CONTROLLED_QUEUE"
      $recommendedNextStep = "PHASE118_QUEUE_SAFETY_REVIEW_V1"
      $reason = "Self-need detection requires queue NONE as baseline."
    } elseif (
      $P116.status -eq "PASS" -and
      $P116.classification -eq "CHAIN_EXECUTION_PASS_BUT_SELF_NEED_IS_STALE" -and
      $P115.status -eq "PASS" -and
      $P114.status -eq "PASS" -and
      $P113.status -eq "PASS" -and
      $P112.status -eq "PASS"
    ) {
      $status = "PASS"
      $diagnosis = "MISSING_SELF_MODEL_UPDATE_CAPABILITY"
      $detectedNeedId = "NEED_SELF_MODEL_UPDATE_ENGINE"
      $missingCapability = "BUILDER_CAN_EXECUTE_SELF_BUILD_CHAIN_BUT_DOES_NOT_UPDATE_SELF_MODEL_FROM_PROOFS"
      $recommendedNextStep = "PHASE118_BUILD_SELF_MODEL_UPDATE_ENGINE_V1"
      $reason = "Proof chain shows decision-to-action, admission, executable move creation, and execution are already built. The stale diagnosis must be replaced by proof-aware self-model updating."
    } elseif (
      $P110.status -eq "PASS" -and
      $P111.classification -eq "NO_AUTONOMOUS_NEXT_ACTION_SELECTION_FOUND"
    ) {
      $status = "PASS"
      $diagnosis = "MISSING_DECISION_TO_ACTION_CAPABILITY"
      $detectedNeedId = "NEED_DECISION_TO_ACTION_ENGINE"
      $missingCapability = "BUILDER_CAN_REPEAT_RUNTIME_OPERATION_BUT_CANNOT_TRANSLATE_STATE_NEED_INTO_NEXT_ACTION"
      $recommendedNextStep = "PHASE112_BUILD_DECISION_TO_ACTION_ENGINE_V1"
      $reason = "Fallback path: old proof chain exists but later chain proofs are missing."
    } else {
      $status = "BLOCKED"
      $diagnosis = "INSUFFICIENT_OR_UNEXPECTED_EVIDENCE"
      $detectedNeedId = "NEED_STATE_EVIDENCE_REVIEW"
      $missingCapability = "TRUSTED_PROOF_CHAIN_INTERPRETATION"
      $recommendedNextStep = "PHASE118_STATE_EVIDENCE_REVIEW_V1"
      $reason = "Required proof chain is missing or unexpected."
    }

    $Result = [ordered]@{
      status = $status
      engine_name = "SELF_NEED_DETECTION_ENGINE_V1"
      proof_aware = $true
      run_id = $RunId
      active_line = "AGENT_BUILDER / SELF_BUILD"
      queue_active_task_id = if ($null -ne $Queue) { $Queue.active_task_id } else { "__UNREADABLE__" }
      phase110_finalize_status = if ($null -ne $P110) { $P110.status } else { "__MISSING__" }
      phase111_status = if ($null -ne $P111) { $P111.status } else { "__MISSING__" }
      phase112_status = if ($null -ne $P112) { $P112.status } else { "__MISSING__" }
      phase113_status = if ($null -ne $P113) { $P113.status } else { "__MISSING__" }
      phase114_status = if ($null -ne $P114) { $P114.status } else { "__MISSING__" }
      phase115_status = if ($null -ne $P115) { $P115.status } else { "__MISSING__" }
      phase116_status = if ($null -ne $P116) { $P116.status } else { "__MISSING__" }
      phase116_classification = if ($null -ne $P116) { $P116.classification } else { "__MISSING__" }
      diagnosis = $diagnosis
      detected_need_id = $detectedNeedId
      missing_capability = $missingCapability
      recommended_next_step = $recommendedNextStep
      reason = $reason
      autonomy_claimed = $false
      codex_used = $false
      main_touched = $false
    }

    $LegacyOutputPath = Join-Path $OutputRoot "SELF_NEED_DETECTION_ENGINE_OUTPUT.json"
    $CanonicalOutputPath = Join-Path $CanonicalRoot "PROOF_AWARE_SELF_NEED_ENGINE_OUTPUT.json"

    Write-JsonFile $LegacyOutputPath $Result 20
    Write-JsonFile $CanonicalOutputPath $Result 20

    $Result["output_path"] = $LegacyOutputPath
    $Result["canonical_output_path"] = $CanonicalOutputPath

    return [pscustomobject]$Result
  } finally {
    Pop-Location
  }
}
