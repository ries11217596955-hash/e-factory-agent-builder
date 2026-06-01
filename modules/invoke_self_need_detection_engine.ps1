function Read-JsonRequired {
  param([string]$Path)

  if (-not (Test-Path $Path)) {
    throw "Required JSON file missing: $Path"
  }

  return Get-Content $Path -Raw | ConvertFrom-Json
}

function Invoke-SelfNeedDetectionEngine {
  param(
    [string]$RepoRoot,
    [string]$RunId,
    [string]$OutputRoot
  )

  Push-Location $RepoRoot

  try {
    if (-not (Test-Path $OutputRoot)) {
      New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
    }

    $Queue = Read-JsonRequired "TASK_QUEUE.json"
    $Phase110Finalize = Read-JsonRequired "proofs/self_development/PHASE110_FINALIZE_IDEMPOTENT_AUTONOMY_TRIAL_V1.json"
    $Phase111Probe = Read-JsonRequired "proofs/self_development/PHASE111_BUILDER_NEXT_ACTION_DECISION_PROBE_V1.json"

    $status = "PASS"
    $diagnosis = "UNKNOWN"
    $detectedNeedId = ""
    $missingCapability = ""
    $recommendedNextStep = ""
    $reason = ""

    if ($Queue.active_task_id -ne "NONE") {
      $status = "BLOCKED"
      $diagnosis = "QUEUE_NOT_EMPTY"
      $detectedNeedId = "NEED_QUEUE_SAFETY_REVIEW"
      $missingCapability = "SAFE_DECISION_REQUIRES_EMPTY_OR_CONTROLLED_QUEUE"
      $recommendedNextStep = "PHASE112_QUEUE_SAFETY_REVIEW_V1"
      $reason = "Self-need detection requires queue NONE as baseline."
    } elseif (
      $Phase110Finalize.status -eq "PASS" -and
      $Phase111Probe.classification -eq "NO_AUTONOMOUS_NEXT_ACTION_SELECTION_FOUND"
    ) {
      $status = "PASS"
      $diagnosis = "MISSING_DECISION_TO_ACTION_CAPABILITY"
      $detectedNeedId = "NEED_DECISION_TO_ACTION_ENGINE"
      $missingCapability = "BUILDER_CAN_REPEAT_RUNTIME_OPERATION_BUT_CANNOT_TRANSLATE_STATE_NEED_INTO_NEXT_ACTION"
      $recommendedNextStep = "PHASE112_BUILD_DECISION_TO_ACTION_ENGINE_V1"
      $reason = "PHASE110 proved repeatability; PHASE111 probe proved Builder does not select a next action when active_task_id is NONE."
    } else {
      $status = "BLOCKED"
      $diagnosis = "INSUFFICIENT_OR_UNEXPECTED_EVIDENCE"
      $detectedNeedId = "NEED_STATE_EVIDENCE_REVIEW"
      $missingCapability = "TRUSTED_STATE_INTERPRETATION"
      $recommendedNextStep = "PHASE112_STATE_EVIDENCE_REVIEW_V1"
      $reason = "Required proof chain was missing or did not match expected evidence."
    }

    $Result = [ordered]@{
      status = $status
      engine_name = "SELF_NEED_DETECTION_ENGINE_V1"
      run_id = $RunId
      active_line = "AGENT_BUILDER / SELF_BUILD"
      queue_active_task_id = $Queue.active_task_id
      phase110_finalize_status = $Phase110Finalize.status
      phase111_probe_status = $Phase111Probe.status
      phase111_probe_classification = $Phase111Probe.classification
      diagnosis = $diagnosis
      detected_need_id = $detectedNeedId
      missing_capability = $missingCapability
      recommended_next_step = $recommendedNextStep
      reason = $reason
      autonomy_claimed = $false
      codex_used = $false
      main_touched = $false
    }

    $OutputPath = Join-Path $OutputRoot "SELF_NEED_DETECTION_ENGINE_OUTPUT.json"
    $Result | ConvertTo-Json -Depth 16 | Set-Content -Path $OutputPath -Encoding UTF8

    $Result["output_path"] = $OutputPath

    return [pscustomobject]$Result
  } finally {
    Pop-Location
  }
}
