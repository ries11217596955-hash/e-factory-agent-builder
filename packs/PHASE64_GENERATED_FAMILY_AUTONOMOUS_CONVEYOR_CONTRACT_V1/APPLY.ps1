param([string]$RepoRoot,[string]$RunId,[switch]$InvokedByOrchestrator)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if (-not $InvokedByOrchestrator) { throw "Pack must be invoked by orchestrator." }
Set-Location $RepoRoot
Copy-Item ".\packs\PHASE64_GENERATED_FAMILY_AUTONOMOUS_CONVEYOR_CONTRACT_V1\payload\validators\validate_generated_family_autonomous_conveyor_contract_v1.ps1" ".\validators\validate_generated_family_autonomous_conveyor_contract_v1.ps1" -Force
& ".\validators\validate_generated_family_autonomous_conveyor_contract_v1.ps1" -FinalizePhase -RunId $RunId
Write-Host "PACK_COMMIT_PUSH=PASS"
