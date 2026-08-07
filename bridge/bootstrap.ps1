param(
    [switch]$SkipStart,
    [switch]$SkipRecoveryInstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-JsonAtomic {
    param([string]$Path, $Value)
    $Directory = Split-Path -Parent $Path
    if (-not (Test-Path $Directory)) { New-Item -ItemType Directory -Path $Directory -Force | Out-Null }
    $Temp = "$Path.tmp"
    $Value | ConvertTo-Json -Depth 12 | Set-Content -Path $Temp -Encoding UTF8
    Move-Item -Path $Temp -Destination $Path -Force
}

function New-BridgeToken {
    $Bytes = New-Object byte[] 32
    $Rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $Rng.GetBytes($Bytes) } finally { $Rng.Dispose() }
    return [Convert]::ToBase64String($Bytes).TrimEnd('=').Replace('+','-').Replace('/','_')
}

$BridgeDir = (Resolve-Path $PSScriptRoot).Path
$RepoRoot = (Resolve-Path (Join-Path $BridgeDir "..")).Path
$Required = @(
    "CAPABILITY_ROADMAP.json",
    "GENESIS_STATE.json",
    "TASK_QUEUE.json",
    "packs\registry.json",
    "orchestrator\run.ps1"
)
foreach ($Relative in $Required) {
    if (-not (Test-Path (Join-Path $RepoRoot $Relative))) {
        Write-Output "STOP=WRONG_AGENT_BUILDER_REPO"
        throw "Missing repo identity file: $Relative"
    }
}

$Python = Get-Command py.exe -ErrorAction SilentlyContinue
if ($null -eq $Python) { $Python = Get-Command python.exe -ErrorAction SilentlyContinue }
if ($null -eq $Python) { $Python = Get-Command python -ErrorAction SilentlyContinue }
if ($null -eq $Python) { throw "PYTHON_NOT_FOUND" }
$Git = Get-Command git.exe -ErrorAction SilentlyContinue
if ($null -eq $Git) { $Git = Get-Command git -ErrorAction SilentlyContinue }
if ($null -eq $Git) { throw "GIT_NOT_FOUND" }

$RuntimeDir = Join-Path $env:LOCALAPPDATA "EFactory\Bridge"
New-Item -ItemType Directory -Path $RuntimeDir -Force | Out-Null
$TokenPath = Join-Path $RuntimeDir "bridge_token.txt"
if (-not (Test-Path $TokenPath)) {
    Set-Content -Path $TokenPath -Value (New-BridgeToken) -Encoding ASCII -NoNewline
    Write-Output "BRIDGE_TOKEN=CREATED_LOCAL_ONLY"
}
else {
    $Existing = (Get-Content -Raw -Path $TokenPath).Trim()
    if ($Existing.Length -lt 24) { throw "BRIDGE_TOKEN_INVALID_TOO_SHORT" }
    Write-Output "BRIDGE_TOKEN=EXISTS_LOCAL_ONLY"
}

$TemplatePath = Join-Path $BridgeDir "config.example.json"
$ConfigPath = Join-Path $BridgeDir "config.local.json"
if (-not (Test-Path $TemplatePath)) { throw "BRIDGE_CONFIG_TEMPLATE_MISSING=$TemplatePath" }
$Config = Get-Content -Raw -Path $TemplatePath | ConvertFrom-Json
$Config.allowed_roots = @($RepoRoot)
$Config.default_cwd = $RepoRoot
$Config.token_file = $TokenPath
$Config.report_dir = Join-Path $RuntimeDir "reports"
$Config.recovery_report_dir = Join-Path $env:LOCALAPPDATA "EFactory\Recovery\reports"
Write-JsonAtomic -Path $ConfigPath -Value $Config
Write-Output "BRIDGE_CONFIG=$ConfigPath"

$RecoveryDir = Join-Path $BridgeDir "recovery"
$RecoveryExample = Join-Path $RecoveryDir "local_config.example.json"
$RecoveryConfigPath = Join-Path $RecoveryDir "local_config.json"
if (-not (Test-Path $RecoveryExample)) { throw "RECOVERY_CONFIG_TEMPLATE_MISSING=$RecoveryExample" }
if (Test-Path $RecoveryConfigPath) {
    $RecoveryConfig = Get-Content -Raw -Path $RecoveryConfigPath | ConvertFrom-Json
}
else {
    $RecoveryConfig = Get-Content -Raw -Path $RecoveryExample | ConvertFrom-Json
}
$RecoveryConfig.repo_root = $RepoRoot
$RecoveryConfig.bridge_service_name = ""
$RecoveryConfig.bridge_start_script = (Join-Path $BridgeDir "scripts\start_bridge.ps1")
Write-JsonAtomic -Path $RecoveryConfigPath -Value $RecoveryConfig
Write-Output "RECOVERY_CONFIG=$RecoveryConfigPath"

if (-not $SkipStart) {
    & (Join-Path $BridgeDir "scripts\start_bridge.ps1") -ConfigPath $ConfigPath
}
else {
    Write-Output "BRIDGE_START=SKIPPED_BY_PARAMETER"
}

if (-not $SkipRecoveryInstall) {
    & (Join-Path $RecoveryDir "bootstrap.ps1")
}
else {
    Write-Output "RECOVERY_INSTALL=SKIPPED_BY_PARAMETER"
}

Write-Output "BRIDGE_BOOTSTRAP=COMPLETE"
Write-Output "BRIDGE_LOCAL_HEALTH=http://127.0.0.1:$($Config.port)/health"
Write-Output "REMOTE_EXPOSURE=NOT_CONFIGURED"
