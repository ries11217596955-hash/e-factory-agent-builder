param(
    [string]$RepoRoot,
    [string]$RunId,
    [switch]$InvokedByOrchestrator
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $InvokedByOrchestrator) { throw "Pack must be invoked by orchestrator." }
Set-Location $RepoRoot

Write-Host "PACK=PHASE51_BUILDER_GITHUB_ACTION_MANUAL_RUN_SURFACE_V1"

New-Item -ItemType Directory -Force -Path ".\.github\workflows" | Out-Null
Copy-Item ".\packs\PHASE51_BUILDER_GITHUB_ACTION_MANUAL_RUN_SURFACE_V1\payload\github\agent-builder-self-build.yml" ".\.github\workflows\agent-builder-self-build.yml" -Force
Copy-Item ".\packs\PHASE51_BUILDER_GITHUB_ACTION_MANUAL_RUN_SURFACE_V1\payload\validators\validate_builder_github_action_manual_run_surface_v1.ps1" ".\validators\validate_builder_github_action_manual_run_surface_v1.ps1" -Force

& ".\validators\validate_builder_github_action_manual_run_surface_v1.ps1" -FinalizePhase -RunId $RunId

git add ".\.github\workflows\agent-builder-self-build.yml"
git add ".\validators\validate_builder_github_action_manual_run_surface_v1.ps1"
git add ".\tasks\TASK_GENERATED_AGENT_ACTION_LAUNCH_CONTRACT_V1_001.json"
git add ".\proofs\BUILDER_GITHUB_ACTION_MANUAL_RUN_SURFACE_V1.json"
git add ".\CAPABILITY_ROADMAP.json"
git add ".\GENESIS_STATE.json"
git add ".\TASK_QUEUE.json"
git commit -m "Self-build PHASE 51 builder GitHub Action manual run surface v1"
git push origin main

Write-Host "PACK_COMMIT_PUSH=PASS"
