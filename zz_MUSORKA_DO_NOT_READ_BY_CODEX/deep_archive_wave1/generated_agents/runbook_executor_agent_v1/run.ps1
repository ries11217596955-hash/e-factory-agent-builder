param(
    [string]$InputPath,
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-JsonFile {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "JSON path is required."
    }
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "JSON file missing: $Path"
    }

    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Write-JsonFile {
    param(
        [string]$Path,
        [object]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "OutputPath is required."
    }

    $Directory = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($Directory) -and -not (Test-Path -LiteralPath $Directory)) {
        New-Item -ItemType Directory -Force -Path $Directory | Out-Null
    }

    $Value | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Assert-RequiredField {
    param(
        [object]$Value,
        [string]$FieldName
    )

    if ($Value.PSObject.Properties.Name -notcontains $FieldName) {
        throw "Input missing required field: $FieldName"
    }
    if ($null -eq $Value.$FieldName) {
        throw "Input field must not be null: $FieldName"
    }
    if ($Value.$FieldName -is [string] -and [string]::IsNullOrWhiteSpace([string]$Value.$FieldName)) {
        throw "Input field must not be empty: $FieldName"
    }
}

$Input = Read-JsonFile -Path $InputPath
$RequiredFields = @(
    "runbook_title",
    "runbook_steps",
    "task_or_incident",
    "environment",
    "constraints"
)

foreach ($Field in $RequiredFields) {
    Assert-RequiredField -Value $Input -FieldName $Field
}

$RunbookSteps = @($Input.runbook_steps)
if ($RunbookSteps.Count -lt 1) {
    throw "runbook_steps must contain at least one step."
}

$Constraints = @($Input.constraints)
$ExecutionChecklist = @()
$StepNumber = 1
foreach ($Step in $RunbookSteps) {
    $StepText = [string]$Step
    if ([string]::IsNullOrWhiteSpace($StepText)) {
        throw "runbook_steps contains an empty step."
    }

    $ExecutionChecklist += [ordered]@{
        step_number = $StepNumber
        action = $StepText
        operator_context = "Apply to '$($Input.task_or_incident)' in '$($Input.environment)'."
    }
    $StepNumber += 1
}

$RiskFlags = @()
foreach ($Constraint in $Constraints) {
    $ConstraintText = [string]$Constraint
    if (-not [string]::IsNullOrWhiteSpace($ConstraintText)) {
        $RiskFlags += "Constraint: $ConstraintText"
    }
}
if ($RiskFlags.Count -eq 0) {
    $RiskFlags += "No explicit constraints supplied; operator must confirm operational boundaries before execution."
}

$RequiredEvidence = @(
    "Original runbook title: $($Input.runbook_title)",
    "Task or incident: $($Input.task_or_incident)",
    "Environment: $($Input.environment)",
    "Before and after observation for each checklist step",
    "Final operator note with unresolved symptoms or confirmation of completion"
)

$Result = [ordered]@{
    execution_checklist = $ExecutionChecklist
    risk_flags = $RiskFlags
    required_evidence = $RequiredEvidence
    next_operator_action = "Review risks, execute the checklist in order, collect the required evidence, and escalate if any step cannot be completed safely."
    validation_status = "PASS"
}

Write-JsonFile -Path $OutputPath -Value $Result
Write-Output "RUNBOOK_EXECUTOR_AGENT_STATUS=PASS"
