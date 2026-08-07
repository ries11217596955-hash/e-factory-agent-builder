param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RuntimeDir = Join-Path $env:LOCALAPPDATA "EFactory\Bridge"
$PidPath = Join-Path $RuntimeDir "bridge.pid"

if (-not (Test-Path $PidPath)) {
    Write-Output "BRIDGE_STATUS=NOT_RUNNING_OR_PID_UNKNOWN"
    return
}

$PidText = (Get-Content -Raw -Path $PidPath).Trim()
$ProcessId = 0
if (-not [int]::TryParse($PidText, [ref]$ProcessId)) {
    Remove-Item $PidPath -Force -ErrorAction SilentlyContinue
    throw "BRIDGE_PID_INVALID=$PidText"
}

$Process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
if ($null -eq $Process) {
    Remove-Item $PidPath -Force -ErrorAction SilentlyContinue
    Write-Output "BRIDGE_STATUS=NOT_RUNNING"
    return
}

if ($Process.ProcessName -notmatch '^(python|python3|py)$') {
    throw "BRIDGE_PID_SAFETY_STOP: pid=$ProcessId process=$($Process.ProcessName)"
}

Stop-Process -Id $ProcessId -Force -ErrorAction Stop
Remove-Item $PidPath -Force -ErrorAction SilentlyContinue
Write-Output "BRIDGE_STATUS=STOPPED"
Write-Output "BRIDGE_PID=$ProcessId"
