param(
    [string]$ConfigPath = "$PSScriptRoot\..\config.local.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-BridgeHealth {
    param([string]$Url)
    try {
        $Response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 3
        return ($Response.StatusCode -ge 200 -and $Response.StatusCode -lt 300)
    }
    catch {
        return $false
    }
}

$BridgeDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ServerPath = Join-Path $BridgeDir "server.py"
$ConfigPath = [Environment]::ExpandEnvironmentVariables($ConfigPath)

if (-not (Test-Path $ServerPath)) { throw "BRIDGE_SERVER_MISSING=$ServerPath" }
if (-not (Test-Path $ConfigPath)) { throw "BRIDGE_CONFIG_MISSING=$ConfigPath" }

$Config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
$HostName = [string]$Config.bind_host
$Port = [int]$Config.port
if ([string]::IsNullOrWhiteSpace($HostName)) { $HostName = "127.0.0.1" }
if ($Port -le 0) { throw "BRIDGE_INVALID_PORT=$Port" }
$HealthUrl = "http://${HostName}:$Port/health"

if (Test-BridgeHealth $HealthUrl) {
    Write-Output "BRIDGE_STATUS=ALREADY_HEALTHY"
    Write-Output "BRIDGE_HEALTH=$HealthUrl"
    return
}

$PythonExe = $null
$PrefixArgs = @()
$Py = Get-Command py.exe -ErrorAction SilentlyContinue
if ($null -ne $Py) {
    $PythonExe = $Py.Source
    $PrefixArgs = @("-3")
}
else {
    $Python = Get-Command python.exe -ErrorAction SilentlyContinue
    if ($null -eq $Python) { $Python = Get-Command python -ErrorAction SilentlyContinue }
    if ($null -eq $Python) { throw "PYTHON_NOT_FOUND" }
    $PythonExe = $Python.Source
}

$RuntimeDir = Join-Path $env:LOCALAPPDATA "EFactory\Bridge"
New-Item -ItemType Directory -Path $RuntimeDir -Force | Out-Null
$StdoutPath = Join-Path $RuntimeDir "bridge_stdout.log"
$StderrPath = Join-Path $RuntimeDir "bridge_stderr.log"
$PidPath = Join-Path $RuntimeDir "bridge.pid"

$ArgumentList = @()
$ArgumentList += $PrefixArgs
$ArgumentList += @("`"$ServerPath`"", "--config", "`"$ConfigPath`"")

$Process = Start-Process `
    -FilePath $PythonExe `
    -ArgumentList $ArgumentList `
    -WorkingDirectory $BridgeDir `
    -WindowStyle Hidden `
    -RedirectStandardOutput $StdoutPath `
    -RedirectStandardError $StderrPath `
    -PassThru

Set-Content -Path $PidPath -Value ([string]$Process.Id) -Encoding ASCII

$Healthy = $false
for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Milliseconds 500
    if (Test-BridgeHealth $HealthUrl) {
        $Healthy = $true
        break
    }
    if ($Process.HasExited) { break }
}

if (-not $Healthy) {
    $ExitDetail = if ($Process.HasExited) { "exit_code=$($Process.ExitCode)" } else { "process_alive_but_health_failed" }
    throw "BRIDGE_START_FAILED;$ExitDetail;stderr=$StderrPath"
}

Write-Output "BRIDGE_STATUS=STARTED"
Write-Output "BRIDGE_PID=$($Process.Id)"
Write-Output "BRIDGE_HEALTH=$HealthUrl"
Write-Output "BRIDGE_STDERR=$StderrPath"
