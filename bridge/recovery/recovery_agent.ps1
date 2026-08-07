param(
    [string]$ControlUrl = "https://raw.githubusercontent.com/ries11217596955-hash/e-factory-agent-builder/recovery-control/bridge/recovery/desired_state.json",
    [string]$LocalConfigPath = "$PSScriptRoot\local_config.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-PropValue {
    param($Object, [string]$Name, $Default = $null)
    if ($null -eq $Object) { return $Default }
    $Property = $Object.PSObject.Properties[$Name]
    if ($null -eq $Property) { return $Default }
    return $Property.Value
}

function Expand-PathValue {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $Value }
    return [Environment]::ExpandEnvironmentVariables($Value)
}

function Write-JsonAtomic {
    param([string]$Path, $Value)
    $Directory = Split-Path -Parent $Path
    if (-not (Test-Path $Directory)) {
        New-Item -ItemType Directory -Path $Directory -Force | Out-Null
    }
    $Temp = "$Path.tmp"
    $Value | ConvertTo-Json -Depth 12 | Set-Content -Path $Temp -Encoding UTF8
    Move-Item -Path $Temp -Destination $Path -Force
}

function Test-HttpHealth {
    param([string]$Url)
    if ([string]::IsNullOrWhiteSpace($Url)) { return $false }
    try {
        $Response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
        return ($Response.StatusCode -ge 200 -and $Response.StatusCode -lt 300)
    }
    catch {
        return $false
    }
}

function Test-RepoIdentity {
    param([string]$RepoRoot)
    $Required = @(
        "CAPABILITY_ROADMAP.json",
        "GENESIS_STATE.json",
        "TASK_QUEUE.json",
        "packs\registry.json",
        "orchestrator\run.ps1"
    )
    foreach ($Relative in $Required) {
        if (-not (Test-Path (Join-Path $RepoRoot $Relative))) {
            return $false
        }
    }
    return $true
}

function Start-BoundedComponent {
    param(
        [string]$ServiceName,
        [string]$StartScript,
        [string]$ComponentName
    )

    if (-not [string]::IsNullOrWhiteSpace($ServiceName)) {
        try {
            $Service = Get-Service -Name $ServiceName -ErrorAction Stop
            if ($Service.Status -ne "Running") {
                Start-Service -Name $ServiceName -ErrorAction Stop
                Start-Sleep -Seconds 2
            }
            return [pscustomobject]@{ status = "OK"; method = "service"; detail = $ServiceName }
        }
        catch {
            return [pscustomobject]@{ status = "FAIL"; method = "service"; detail = $_.Exception.Message }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($StartScript)) {
        $Resolved = Expand-PathValue $StartScript
        if (-not (Test-Path $Resolved)) {
            return [pscustomobject]@{ status = "BLOCKED"; method = "script"; detail = "Missing start script: $Resolved" }
        }
        try {
            & $Resolved
            if ($LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0) {
                return [pscustomobject]@{ status = "FAIL"; method = "script"; detail = "Exit code $LASTEXITCODE" }
            }
            return [pscustomobject]@{ status = "OK"; method = "script"; detail = $Resolved }
        }
        catch {
            return [pscustomobject]@{ status = "FAIL"; method = "script"; detail = $_.Exception.Message }
        }
    }

    return [pscustomobject]@{ status = "BLOCKED"; method = "none"; detail = "No bounded start method configured for $ComponentName" }
}

$StartedAt = (Get-Date).ToUniversalTime().ToString("o")
$DefaultStateDir = Join-Path $env:LOCALAPPDATA "EFactory\Recovery"
$Report = [ordered]@{
    schema_version = 1
    started_at = $StartedAt
    finished_at = $null
    control_url = $ControlUrl
    desired_generation = $null
    enabled = $null
    status = "STARTED"
    actions = @()
}

try {
    if (-not (Test-Path $LocalConfigPath)) {
        throw "BOOTSTRAP_CONFIG_MISSING: copy local_config.example.json to local_config.json and configure bounded local paths/services."
    }

    $Config = Get-Content -Raw -Path $LocalConfigPath | ConvertFrom-Json
    $ConfiguredStateDir = Expand-PathValue ([string](Get-PropValue $Config "local_state_dir" $DefaultStateDir))
    if ([string]::IsNullOrWhiteSpace($ConfiguredStateDir)) { $ConfiguredStateDir = $DefaultStateDir }
    $StateDir = $ConfiguredStateDir
    $StatePath = Join-Path $StateDir "state.json"
    $ReportsDir = Join-Path $StateDir "reports"

    New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null

    $Desired = Invoke-RestMethod -Uri $ControlUrl -TimeoutSec 15
    $SchemaVersion = [int](Get-PropValue $Desired "schema_version" 0)
    $Generation = [int](Get-PropValue $Desired "generation" -1)
    $Enabled = [bool](Get-PropValue $Desired "enabled" $false)

    $Report.desired_generation = $Generation
    $Report.enabled = $Enabled

    if ($SchemaVersion -ne 1) { throw "UNSUPPORTED_SCHEMA_VERSION=$SchemaVersion" }
    if ($Generation -lt 0) { throw "INVALID_GENERATION=$Generation" }

    $LastGeneration = -1
    if (Test-Path $StatePath) {
        try {
            $State = Get-Content -Raw -Path $StatePath | ConvertFrom-Json
            $LastGeneration = [int](Get-PropValue $State "last_applied_generation" -1)
        }
        catch {
            $LastGeneration = -1
        }
    }

    if ($Generation -lt $LastGeneration) {
        throw "GENERATION_ROLLBACK_REJECTED: desired=$Generation last_applied=$LastGeneration"
    }

    $Bridge = Get-PropValue $Desired "bridge" $null
    $Tunnel = Get-PropValue $Desired "tunnel" $null
    $Repo = Get-PropValue $Desired "repo" $null
    $HealthUrl = [string](Get-PropValue $Bridge "health_url" "")
    $ExpectedRemote = [string](Get-PropValue $Repo "expected_remote" "")

    $Requested = @(Get-PropValue $Desired "requested_operations" @())
    $Allowed = @(
        "health_report",
        "ensure_bridge",
        "ensure_tunnel",
        "ensure_repo_remote",
        "ensure_github_cli"
    )

    foreach ($Operation in $Requested) {
        if ($Allowed -notcontains [string]$Operation) {
            throw "UNKNOWN_OR_FORBIDDEN_OPERATION=$Operation"
        }
    }

    $IsNewGeneration = ($Generation -gt $LastGeneration)

    foreach ($Operation in $Requested) {
        $Operation = [string]$Operation
        $Action = [ordered]@{
            operation = $Operation
            status = "SKIPPED"
            detail = ""
            health_before = $null
            health_after = $null
        }

        if ($Operation -ne "health_report" -and -not $Enabled) {
            $Action.detail = "Recovery mutation disabled by desired state."
            $Report.actions += [pscustomobject]$Action
            continue
        }

        if ($Operation -ne "health_report" -and -not $IsNewGeneration) {
            $Action.detail = "Generation already applied; mutating operation is idempotently skipped."
            $Report.actions += [pscustomobject]$Action
            continue
        }

        switch ($Operation) {
            "health_report" {
                $BridgeHealthy = Test-HttpHealth $HealthUrl
                $Action.status = if ($BridgeHealthy) { "OK" } else { "DEGRADED" }
                $Action.health_after = $BridgeHealthy
                $Action.detail = "Bridge health probe only; no mutation."
            }

            "ensure_bridge" {
                $Before = Test-HttpHealth $HealthUrl
                $Action.health_before = $Before
                if ($Before) {
                    $Action.status = "OK"
                    $Action.health_after = $true
                    $Action.detail = "Bridge already healthy."
                }
                else {
                    $StartResult = Start-BoundedComponent `
                        -ServiceName ([string](Get-PropValue $Config "bridge_service_name" "")) `
                        -StartScript ([string](Get-PropValue $Config "bridge_start_script" "")) `
                        -ComponentName "bridge"
                    Start-Sleep -Seconds 3
                    $After = Test-HttpHealth $HealthUrl
                    $Action.health_after = $After
                    $Action.status = if ($After) { "RECOVERED" } else { [string]$StartResult.status }
                    $Action.detail = [string]$StartResult.detail
                }
            }

            "ensure_tunnel" {
                $TunnelEnabled = [bool](Get-PropValue $Tunnel "enabled" $false)
                if (-not $TunnelEnabled) {
                    $Action.status = "SKIPPED"
                    $Action.detail = "Tunnel disabled by desired state."
                }
                else {
                    $StartResult = Start-BoundedComponent `
                        -ServiceName ([string](Get-PropValue $Config "tunnel_service_name" "")) `
                        -StartScript ([string](Get-PropValue $Config "tunnel_start_script" "")) `
                        -ComponentName "tunnel"
                    $Action.status = [string]$StartResult.status
                    $Action.detail = [string]$StartResult.detail
                }
            }

            "ensure_repo_remote" {
                $RepoRoot = Expand-PathValue ([string](Get-PropValue $Config "repo_root" ""))
                $GitPath = [string](Get-PropValue $Config "git_path" "git.exe")
                if ([string]::IsNullOrWhiteSpace($RepoRoot) -or -not (Test-Path $RepoRoot)) {
                    $Action.status = "BLOCKED"
                    $Action.detail = "Configured repo_root missing."
                }
                elseif (-not (Test-RepoIdentity $RepoRoot)) {
                    $Action.status = "BLOCKED"
                    $Action.detail = "STOP=WRONG_AGENT_BUILDER_REPO"
                }
                elseif ([string]::IsNullOrWhiteSpace($ExpectedRemote)) {
                    $Action.status = "BLOCKED"
                    $Action.detail = "Expected remote missing from desired state."
                }
                else {
                    try {
                        $CurrentRemote = (& $GitPath -C $RepoRoot remote get-url origin 2>&1 | Out-String).Trim()
                        if ($LASTEXITCODE -ne 0) { throw "git remote get-url failed: $CurrentRemote" }
                        if ($CurrentRemote -ne $ExpectedRemote) {
                            & $GitPath -C $RepoRoot remote set-url origin $ExpectedRemote | Out-Null
                            if ($LASTEXITCODE -ne 0) { throw "git remote set-url failed with exit code $LASTEXITCODE" }
                        }
                        $VerifiedRemote = (& $GitPath -C $RepoRoot remote get-url origin 2>&1 | Out-String).Trim()
                        if ($VerifiedRemote -ne $ExpectedRemote) { throw "remote verification mismatch: $VerifiedRemote" }
                        $Action.status = "OK"
                        $Action.detail = "origin=$VerifiedRemote"
                    }
                    catch {
                        $Action.status = "FAIL"
                        $Action.detail = $_.Exception.Message
                    }
                }
            }

            "ensure_github_cli" {
                $GhPath = [string](Get-PropValue $Config "github_cli_path" "gh.exe")
                try {
                    $Output = (& $GhPath auth status 2>&1 | Out-String).Trim()
                    if ($LASTEXITCODE -ne 0) { throw $Output }
                    $Action.status = "OK"
                    $Action.detail = "GitHub CLI is present and auth status returned success."
                }
                catch {
                    $Action.status = "BLOCKED"
                    $Action.detail = "GitHub CLI unavailable or unauthenticated. Recovery Agent does not install credentials automatically. $($_.Exception.Message)"
                }
            }
        }

        $Report.actions += [pscustomobject]$Action
    }

    $MutatingRequested = @($Requested | Where-Object { $_ -ne "health_report" })
    $BlockingStatuses = @("FAIL", "BLOCKED")
    $HasBlockingResult = $false
    foreach ($ActionResult in $Report.actions) {
        if ($BlockingStatuses -contains [string]$ActionResult.status) {
            $HasBlockingResult = $true
            break
        }
    }

    if ($Enabled -and $IsNewGeneration -and $MutatingRequested.Count -gt 0 -and -not $HasBlockingResult) {
        Write-JsonAtomic -Path $StatePath -Value ([ordered]@{
            last_applied_generation = $Generation
            applied_at = (Get-Date).ToUniversalTime().ToString("o")
        })
    }

    $Report.status = if ($HasBlockingResult) { "BLOCKED" } else { "OK" }
}
catch {
    $Report.status = "FAIL"
    $Report.actions += [pscustomobject]([ordered]@{
        operation = "agent_cycle"
        status = "FAIL"
        detail = $_.Exception.Message
        health_before = $null
        health_after = $null
    })

    if (-not (Get-Variable -Name ReportsDir -Scope Script -ErrorAction SilentlyContinue)) {
        $ReportsDir = Join-Path $DefaultStateDir "reports"
        New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null
    }
}
finally {
    $Report.finished_at = (Get-Date).ToUniversalTime().ToString("o")
    $Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $ReportPath = Join-Path $ReportsDir "recovery_$Stamp.json"
    Write-JsonAtomic -Path $ReportPath -Value $Report
    Write-Output "RECOVERY_REPORT=$ReportPath"
    Write-Output "RECOVERY_STATUS=$($Report.status)"
}
