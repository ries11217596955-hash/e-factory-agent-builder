Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$AgentRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$OriginalLocation = Get-Location
Push-Location $AgentRoot
try {

$Required = @(
    "AGENT_PROFILE.json",
    "contracts\request.schema.json",
    "contracts\result.schema.json",
    "modules\invoke_agent_operation.ps1",
    "orchestrator\run.ps1",
    "examples\SAMPLE_REQUEST.json",
    "deployment\github_actions\run-generated-agent.workflow.yml"
)

foreach ($Rel in $Required) {
    if (-not (Test-Path (Join-Path $AgentRoot $Rel))) {
        throw "Package validator missing file: $Rel"
    }
}

$null = Get-Content ".\AGENT_PROFILE.json" -Raw | ConvertFrom-Json
$null = Get-Content ".\contracts\request.schema.json" -Raw | ConvertFrom-Json
$null = Get-Content ".\contracts\result.schema.json" -Raw | ConvertFrom-Json

$WorkflowText = Get-Content ".\deployment\github_actions\run-generated-agent.workflow.yml" -Raw
$WorkflowMarkers = @(
    "workflow_dispatch:",
    "orchestrator\run.ps1",
    "actions/checkout@v6",
    "actions/upload-artifact@v7"
)

foreach ($Marker in $WorkflowMarkers) {
    if ($WorkflowText -notmatch [regex]::Escape($Marker)) {
        throw "Generated agent workflow template missing marker: $Marker"
    }
}

$Tokens = $null
$Errors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path ".\orchestrator\run.ps1"),
    [ref]$Tokens,
    [ref]$Errors
) | Out-Null

if ($Errors.Count -ne 0) { throw "Generated orchestrator parser check failed." }

& ".\orchestrator\run.ps1" -Mode VERIFY | Out-Host
Write-Host "GENERATED_AGENT_VALIDATOR=PASS"
}
finally {
    Pop-Location
}
