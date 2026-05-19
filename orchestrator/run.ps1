param(
    [ValidateSet("SELF_BUILD", "BUILD_EXTERNAL_AGENT", "VERIFY")]
    [string]$Mode = "VERIFY",

    [string]$RunId = ("SELF_BUILD_" + (Get-Date -Format "yyyyMMdd_HHmmss"))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $RepoRoot

Write-Host "AGENT_BUILDER_ORCHESTRATOR"
Write-Host "MODE=$Mode"
Write-Host "RUN_ID=$RunId"

if ($Mode -ne "SELF_BUILD") {
    Write-Host "STATUS=NO_ACTION_FOR_MODE"
    return
}

. ".\modules\read_pack_registry.ps1"
. ".\modules\select_self_build_pack.ps1"
. ".\modules\execute_self_build_pack.ps1"

$Queue = Get-Content ".\TASK_QUEUE.json" -Raw | ConvertFrom-Json
$Registry = Read-SelfBuildPackRegistry -RepoRoot $RepoRoot
$Pack = Select-SelfBuildPack -Registry $Registry -ActiveTaskId $Queue.active_task_id

Write-Host "SELECTED_PACK=$($Pack.pack_id)"
Write-Host "SELECTED_TASK=$($Pack.task_id)"

$Result = Invoke-SelfBuildPack -RepoRoot $RepoRoot -Pack $Pack -RunId $RunId

Write-Host "PACK_STATUS=$($Result.status)"

if ($Result.status -ne "PASS") {
    if ($Result.error) {
        Write-Host "PACK_ERROR=$($Result.error)"
    }
    throw "Self-build pack failed."
}

Write-Host "STATUS=PASS"
