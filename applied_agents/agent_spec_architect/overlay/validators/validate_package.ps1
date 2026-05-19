Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$AgentRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Push-Location $AgentRoot

try {
    $Required = @(
        "AGENT_PROFILE.json",
        "contracts\request.schema.json",
        "contracts\result.schema.json",
        "contracts\raw_agent_idea.schema.json",
        "contracts\agent_spec_architecture_result.schema.json",
        "modules\build_agent_spec_architecture.ps1",
        "orchestrator\run.ps1",
        "examples\SAMPLE_REQUEST.json"
    )

    foreach ($Rel in $Required) {
        if (-not (Test-Path (Join-Path $AgentRoot $Rel))) {
            throw "Package validator missing file: $Rel"
        }
    }

    $Tokens = $null
    $Errors = $null

    [System.Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path ".\orchestrator\run.ps1"),
        [ref]$Tokens,
        [ref]$Errors
    ) | Out-Null

    if ($Errors.Count -ne 0) {
        throw "Generated specialized orchestrator parser check failed."
    }

    & ".\orchestrator\run.ps1" -Mode VERIFY | Out-Host

    Write-Host "GENERATED_AGENT_VALIDATOR=PASS"
}
finally {
    Pop-Location
}
