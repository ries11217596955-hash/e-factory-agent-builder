param(
    [ValidateSet("VERIFY","RUN")]
    [string]$Mode = "VERIFY",
    [string]$InputPath,
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$AgentRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$OriginalLocation = Get-Location
Push-Location $AgentRoot
try {

Write-Host "GENERATED_AGENT_ORCHESTRATOR"
Write-Host "MODE=$Mode"

if ($Mode -eq "VERIFY") {
    $Required = @(
        "AGENT_PROFILE.json",
        "contracts\request.schema.json",
        "contracts\result.schema.json",
        "modules\invoke_agent_operation.ps1",
        "deployment\github_actions\run-generated-agent.workflow.yml"
    )
    foreach ($Rel in $Required) {
        if (-not (Test-Path (Join-Path $AgentRoot $Rel))) {
            throw "VERIFY missing file: $Rel"
        }
    }
    Write-Host "STATUS=PASS"
    return
}

if ([string]::IsNullOrWhiteSpace($InputPath)) { throw "InputPath is required for RUN." }
if ([string]::IsNullOrWhiteSpace($OutputPath)) { throw "OutputPath is required for RUN." }
if (-not (Test-Path $InputPath)) { throw "Input file not found: $InputPath" }

$Request = Get-Content $InputPath -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($Request.request_id)) { throw "request_id is required." }
if ($null -eq $Request.payload) { throw "payload is required." }

$Profile = Get-Content ".\AGENT_PROFILE.json" -Raw | ConvertFrom-Json
. ".\modules\invoke_agent_operation.ps1"
$Result = Invoke-AgentOperation -Request $Request -Profile $Profile
$Result | ConvertTo-Json -Depth 100 | Set-Content $OutputPath -Encoding UTF8

Write-Host "GENERATED_AGENT_RUN_STATUS=$($Result.status)"
Write-Host "GENERATED_AGENT_OUTPUT_PATH=$OutputPath"
}
finally {
    Pop-Location
}
