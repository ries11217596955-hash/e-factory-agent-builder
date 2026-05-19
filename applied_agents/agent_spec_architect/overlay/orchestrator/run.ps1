param(
    [ValidateSet("VERIFY","RUN")]
    [string]$Mode = "VERIFY",

    [string]$InputPath,

    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$AgentRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Push-Location $AgentRoot

try {
    Write-Host "GENERATED_AGENT_ORCHESTRATOR"
    Write-Host "AGENT=agent_spec_architect"
    Write-Host "MODE=$Mode"

    if ($Mode -eq "VERIFY") {
        $Required = @(
            "AGENT_PROFILE.json",
            "contracts\request.schema.json",
            "contracts\result.schema.json",
            "contracts\raw_agent_idea.schema.json",
            "contracts\agent_spec_architecture_result.schema.json",
            "modules\build_agent_spec_architecture.ps1",
            "examples\SAMPLE_REQUEST.json"
        )

        foreach ($Rel in $Required) {
            if (-not (Test-Path (Join-Path $AgentRoot $Rel))) {
                throw "VERIFY missing file: $Rel"
            }
        }

        Write-Host "STATUS=PASS"
        return
    }

    if ([string]::IsNullOrWhiteSpace($InputPath)) {
        throw "InputPath is required for RUN."
    }

    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        throw "OutputPath is required for RUN."
    }

    if (-not (Test-Path $InputPath)) {
        throw "Input file not found: $InputPath"
    }

    $Request = Get-Content $InputPath -Raw | ConvertFrom-Json

    if ([string]::IsNullOrWhiteSpace($Request.request_id)) {
        throw "request_id is required."
    }

    if ($null -eq $Request.payload) {
        throw "payload is required."
    }

    . ".\modules\build_agent_spec_architecture.ps1"

    $Architecture = Build-AgentSpecArchitecture -RawIdea $Request.payload
    $Profile = Get-Content ".\AGENT_PROFILE.json" -Raw | ConvertFrom-Json

    $Result = [pscustomobject]@{
        status = "PASS"
        request_id = $Request.request_id
        agent_id = $Profile.agent_id
        result = [ordered]@{
            architecture = $Architecture
        }
        diagnostics = [ordered]@{
            specialization_mode = "agent_spec_architect_v1"
            build_readiness = $Architecture.build_readiness
            normalized_target_agent_id = $Architecture.normalized_target_agent_id
        }
    }

    $Result | ConvertTo-Json -Depth 100 |
        Set-Content $OutputPath -Encoding UTF8

    Write-Host "GENERATED_AGENT_RUN_STATUS=$($Result.status)"
    Write-Host "GENERATED_AGENT_OUTPUT_PATH=$OutputPath"
    Write-Host "BUILD_READINESS=$($Architecture.build_readiness)"
}
finally {
    Pop-Location
}
