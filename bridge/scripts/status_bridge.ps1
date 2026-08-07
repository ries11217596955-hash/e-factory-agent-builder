param(
    [string]$ConfigPath = "$PSScriptRoot\..\config.local.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ConfigPath = [Environment]::ExpandEnvironmentVariables($ConfigPath)
if (-not (Test-Path $ConfigPath)) {
    Write-Output "BRIDGE_STATUS=CONFIG_MISSING"
    Write-Output "BRIDGE_CONFIG=$ConfigPath"
    return
}

$Config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
$HostName = [string]$Config.bind_host
$Port = [int]$Config.port
if ([string]::IsNullOrWhiteSpace($HostName)) { $HostName = "127.0.0.1" }
$HealthUrl = "http://${HostName}:$Port/health"

try {
    $Response = Invoke-RestMethod -Uri $HealthUrl -TimeoutSec 3
    Write-Output "BRIDGE_STATUS=HEALTHY"
    Write-Output "BRIDGE_HEALTH=$HealthUrl"
    Write-Output "BRIDGE_VERSION=$($Response.version)"
    Write-Output "BRIDGE_PID=$($Response.pid)"
}
catch {
    Write-Output "BRIDGE_STATUS=UNHEALTHY"
    Write-Output "BRIDGE_HEALTH=$HealthUrl"
    Write-Output "BRIDGE_ERROR=$($_.Exception.Message)"
}
