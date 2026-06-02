param(
  [Parameter(Mandatory = $true)]
  [string]$Message,
  [string]$Author = "OWNER_OR_ASSISTANT",
  [string]$CorrectionId = ("CORRECTION_" + (Get-Date -Format "yyyyMMdd_HHmmss"))
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$SessionRoot = Join-Path $RepoRoot "runtime_sessions/builder_life_loop/current"
$InboxPath = Join-Path $SessionRoot "correction_inbox.json"

New-Item -ItemType Directory -Force -Path $SessionRoot | Out-Null

if (Test-Path -LiteralPath $InboxPath) {
  $Inbox = Get-Content -LiteralPath $InboxPath -Raw | ConvertFrom-Json
} else {
  $Inbox = [pscustomobject]([ordered]@{
    status = "PASS"
    inbox_id = "BUILDER_LIFE_LOOP_CORRECTION_INBOX"
    pending_corrections = @()
    observed_correction_count = 0
    next_behavior_trial = "PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1"
  })
}

$Pending = @($Inbox.pending_corrections)
$Pending += [ordered]@{
  correction_id = $CorrectionId
  status = "PENDING"
  author = $Author
  message = $Message
  created_at = (Get-Date).ToUniversalTime().ToString("o")
}

$Outbox = [ordered]@{
  status = "PASS"
  inbox_id = "BUILDER_LIFE_LOOP_CORRECTION_INBOX"
  pending_corrections = $Pending
  observed_correction_count = if ($Inbox.PSObject.Properties.Name -contains "observed_correction_count") { $Inbox.observed_correction_count } else { 0 }
  next_behavior_trial = "PHASE143_BUILDER_CORRECTION_INBOX_RESPONSE_TRIAL_V1"
  updated_at = (Get-Date).ToUniversalTime().ToString("o")
}

$json = ($Outbox | ConvertTo-Json -Depth 50) -replace "`r`n", "`n"
[System.IO.File]::WriteAllText($InboxPath, "$json`n", [System.Text.UTF8Encoding]::new($false))
Write-Host "BUILDER_LIFE_LOOP_CORRECTION_WRITTEN=$CorrectionId"
Write-Host "CORRECTION_INBOX_PATH=$InboxPath"
