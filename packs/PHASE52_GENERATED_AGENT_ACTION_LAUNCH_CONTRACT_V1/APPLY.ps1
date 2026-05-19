param(
    [string]$RepoRoot,
    [string]$RunId,
    [switch]$InvokedByOrchestrator
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $InvokedByOrchestrator) { throw "Pack must be invoked by orchestrator." }
Set-Location $RepoRoot

Write-Host "PACK=PHASE52_GENERATED_AGENT_ACTION_LAUNCH_CONTRACT_V1"

Copy-Item ".\packs\PHASE52_GENERATED_AGENT_ACTION_LAUNCH_CONTRACT_V1\payload\contracts\generated_agent_github_action_launch_surface.contract.json" ".\contracts\generated_agent_github_action_launch_surface.contract.json" -Force
Copy-Item ".\packs\PHASE52_GENERATED_AGENT_ACTION_LAUNCH_CONTRACT_V1\payload\modules\new_external_agent_package.ps1" ".\modules\new_external_agent_package.ps1" -Force
Copy-Item ".\packs\PHASE52_GENERATED_AGENT_ACTION_LAUNCH_CONTRACT_V1\payload\validators\validate_generated_agent_action_launch_contract_v1.ps1" ".\validators\validate_generated_agent_action_launch_contract_v1.ps1" -Force

& ".\validators\validate_generated_agent_action_launch_contract_v1.ps1" -FinalizePhase -RunId $RunId

git add ".\contracts\generated_agent_github_action_launch_surface.contract.json"
git add ".\modules\new_external_agent_package.ps1"
git add ".\validators\validate_generated_agent_action_launch_contract_v1.ps1"
git add ".\tasks\TASK_ACTION_READY_GENERATED_AGENT_PROOF_V1_001.json"
git add ".\proofs\GENERATED_AGENT_ACTION_LAUNCH_CONTRACT_V1.json"
git add ".\CAPABILITY_ROADMAP.json"
git add ".\GENESIS_STATE.json"
git add ".\TASK_QUEUE.json"
git commit -m "Self-build PHASE 52 generated agent Action launch contract v1"
git push origin main

Write-Host "PACK_COMMIT_PUSH=PASS"
