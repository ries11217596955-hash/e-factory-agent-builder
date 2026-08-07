param(
    [string]$TaskName = "EFactory-Recovery-Agent",
    [string]$AgentPath = "$PSScriptRoot\recovery_agent.ps1"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$AgentPath = (Resolve-Path $AgentPath).Path
$PowerShellExe = (Get-Command powershell.exe -ErrorAction Stop).Source
$TaskRun = '"{0}" -NoProfile -ExecutionPolicy Bypass -File "{1}"' -f $PowerShellExe, $AgentPath

& schtasks.exe /Create /TN $TaskName /TR $TaskRun /SC MINUTE /MO 1 /F | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "FAILED_TO_CREATE_RECOVERY_TASK exit_code=$LASTEXITCODE"
}

& schtasks.exe /Run /TN $TaskName | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "RECOVERY_TASK_CREATED_BUT_FIRST_RUN_FAILED exit_code=$LASTEXITCODE"
}

Write-Output "RECOVERY_TASK=$TaskName"
Write-Output "RECOVERY_TASK_STATUS=INSTALLED_AND_TRIGGERED"
