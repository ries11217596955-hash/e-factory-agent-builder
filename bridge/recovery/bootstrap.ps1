param(
    [switch]$SkipTaskInstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-JsonAtomic {
    param([string]$Path, $Value)
    $Temp = "$Path.tmp"
    $Value | ConvertTo-Json -Depth 12 | Set-Content -Path $Temp -Encoding UTF8
    Move-Item -Path $Temp -Destination $Path -Force
}

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
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

$ExamplePath = Join-Path $PSScriptRoot "local_config.example.json"
$ConfigPath = Join-Path $PSScriptRoot "local_config.json"

if (-not (Test-Path $ExamplePath)) {
    throw "Missing config template: $ExamplePath"
}

if (-not (Test-Path $ConfigPath)) {
    $Config = Get-Content -Raw -Path $ExamplePath | ConvertFrom-Json
    $Config.repo_root = $RepoRoot
    Write-JsonAtomic -Path $ConfigPath -Value $Config
    Write-Output "LOCAL_CONFIG=CREATED"
}
else {
    $Config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace([string]$Config.repo_root)) {
        $Config.repo_root = $RepoRoot
        Write-JsonAtomic -Path $ConfigPath -Value $Config
        Write-Output "LOCAL_CONFIG=REPAIRED_REPO_ROOT"
    }
    else {
        Write-Output "LOCAL_CONFIG=EXISTS"
    }
}

$Prerequisites = @(
    @{ name = "powershell.exe"; required = $true },
    @{ name = "git.exe"; required = $true },
    @{ name = "gh.exe"; required = $false }
)

$MissingRequired = @()
foreach ($Item in $Prerequisites) {
    $Found = Get-Command $Item.name -ErrorAction SilentlyContinue
    if ($null -eq $Found) {
        $Level = if ($Item.required) { "REQUIRED" } else { "OPTIONAL" }
        Write-Output "PREREQ_MISSING=$($Item.name);LEVEL=$Level"
        if ($Item.required) { $MissingRequired += $Item.name }
    }
    else {
        Write-Output "PREREQ_OK=$($Item.name)"
    }
}

if ($MissingRequired.Count -gt 0) {
    throw "Missing required prerequisites: $($MissingRequired -join ', ')"
}

if (-not $SkipTaskInstall) {
    & (Join-Path $PSScriptRoot "install_recovery_task.ps1")
}
else {
    Write-Output "RECOVERY_TASK=SKIPPED_BY_PARAMETER"
}

Write-Output "RECOVERY_BOOTSTRAP=PREPARED"
Write-Output "RECOVERY_CONTROL=DISABLED_UNTIL_DESIRED_STATE_ENABLED_AND_BRIDGE_START_METHOD_CONFIGURED"
Write-Output "NEXT=configure bridge_service_name or bridge_start_script, then run recovery drills"
