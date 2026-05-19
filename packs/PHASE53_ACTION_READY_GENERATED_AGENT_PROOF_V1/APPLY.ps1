param(
    [string]$RepoRoot,
    [string]$RunId,
    [switch]$InvokedByOrchestrator
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $InvokedByOrchestrator) { throw "Pack must be invoked by orchestrator." }
Set-Location $RepoRoot

Write-Host "PACK=PHASE53_ACTION_READY_GENERATED_AGENT_PROOF_V1"

New-Item -ItemType Directory -Force -Path ".\specs\github_action_surface_proof" | Out-Null
Copy-Item ".\packs\PHASE53_ACTION_READY_GENERATED_AGENT_PROOF_V1\payload\specs\github_action_surface_proof\ACTION_READY_AGENT_PROOF_SPEC.json" ".\specs\github_action_surface_proof\ACTION_READY_AGENT_PROOF_SPEC.json" -Force
Copy-Item ".\packs\PHASE53_ACTION_READY_GENERATED_AGENT_PROOF_V1\payload\validators\validate_action_ready_generated_agent_proof_v1.ps1" ".\validators\validate_action_ready_generated_agent_proof_v1.ps1" -Force

& ".\validators\validate_action_ready_generated_agent_proof_v1.ps1" -FinalizePhase -RunId $RunId

git add ".\specs\github_action_surface_proof\ACTION_READY_AGENT_PROOF_SPEC.json"
git add ".\validators\validate_action_ready_generated_agent_proof_v1.ps1"
git add ".\proofs\ACTION_READY_GENERATED_AGENT_PROOF_V1.json"
git add ".\CAPABILITY_ROADMAP.json"
git add ".\GENESIS_STATE.json"
git add ".\TASK_QUEUE.json"
git commit -m "Self-build PHASE 53 Action-ready generated agent proof v1"
git push origin main

Write-Host "PACK_COMMIT_PUSH=PASS"
