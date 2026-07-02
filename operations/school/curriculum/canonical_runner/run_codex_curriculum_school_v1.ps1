param(
  [Parameter(Mandatory=$true)][ValidateRange(1,2147483647)][int]$TargetAccepted,
  [Parameter(Mandatory=$true)][ValidateSet("Test","Real")][string]$RunKind
)
$ErrorActionPreference="Stop"
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$utf8=New-Object System.Text.UTF8Encoding($false)
$ChunkSize=5000
$BatchSize=100
function WriteJson($p,$o,$d=60){$dir=Split-Path -Parent $p; if($dir){New-Item -ItemType Directory -Force -Path $dir|Out-Null}; [IO.File]::WriteAllText((Join-Path (Get-Location).Path $p),($o|ConvertTo-Json -Depth $d),$utf8)}
function New-Schedule([int]$N){
  $chunks=@(); $remaining=$N; $chunkIndex=0; $batchTotal=0
  while($remaining -gt 0){
    $chunkIndex++
    $chunkTarget=[Math]::Min($ChunkSize,$remaining)
    $batches=@(); $chunkRemaining=$chunkTarget; $batchIndex=0
    while($chunkRemaining -gt 0){
      $batchIndex++; $batchTotal++
      $batchTarget=[Math]::Min($BatchSize,$chunkRemaining)
      $batches += [pscustomobject]@{batch_index=$batchIndex; global_batch_index=$batchTotal; target=$batchTarget; status="PLANNED"; contract_validation_required=$true; digestion_required=$true; active_decision_use_required=$true}
      $chunkRemaining -= $batchTarget
    }
    $chunks += [pscustomobject]@{chunk_index=$chunkIndex; target=$chunkTarget; batch_count=$batches.Count; batches=@($batches); status="PLANNED"}
    $remaining -= $chunkTarget
  }
  return [pscustomobject]@{chunk_size=$ChunkSize; batch_size=$BatchSize; chunk_count=$chunks.Count; batch_count=$batchTotal; last_chunk_size=$chunks[-1].target; last_batch_size=$chunks[-1].batches[-1].target; chunks=@($chunks)}
}
$schedule=New-Schedule $TargetAccepted
$components=@(
  "operations/school/curriculum/codex_contract/CODEX_CURRICULUM_CONTRACT_V1.md",
  "operations/school/curriculum/codex_contract/validate_codex_curriculum_batch_v1.ps1",
  "operations/school/curriculum/codex_digest/digest_codex_curriculum_batch_v1.ps1",
  "operations/school/curriculum/codex_active/validate_codex_curriculum_active_decision_v1.ps1",
  "operations/school/curriculum/scale_gate/validate_codex_curriculum_scale_gate_v1.ps1"
)
$missing=@($components | Where-Object { -not (Test-Path $_) })
$codexCmd=(Get-Command codex -ErrorAction SilentlyContinue)
$runId="codex_curriculum_{0}_{1}_{2}" -f $RunKind.ToLowerInvariant(),$TargetAccepted,(Get-Date -Format "yyyyMMdd_HHmmss")
$runDir=".runtime/codex_curriculum_canonical_runs/$runId"
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
$blockers=@()
if($missing.Count -gt 0){ $blockers += @($missing | ForEach-Object { "missing_component: $_" }) }
if(-not $codexCmd){ $blockers += "codex_cli_missing" }
if($RunKind -eq "Real"){
  $blockers += "Real blocked: live accepted-core absorption not proven for Codex curriculum canonical runner"
  $blockers += "Real blocked: Owner explicit Real authorization and live rollback gate required"
}
$status="READY_TEST_SCHEDULE"
$proofLabel="CODEX_CURRICULUM_CANONICAL_TEST_SCHEDULE_READY_NOT_EXECUTED"
if($blockers.Count -gt 0){
  if($RunKind -eq "Real"){$status="BLOCKED_REAL_GATES"; $proofLabel="REAL_RUN_BLOCKED_NOT_IMPLEMENTED_NOT_PROVEN"}
  else {$status="BLOCKED_TEST_PREFLIGHT"; $proofLabel="TEST_RUN_BLOCKED_PREFLIGHT"}
}
$report=[pscustomobject]@{
  schema="codex_curriculum_canonical_runner_v1"
  status=$status
  proof_label=$proofLabel
  runtime_ready=$false
  run_id=$runId
  run_kind=$RunKind
  target_accepted=$TargetAccepted
  owner_interface="operations/school/curriculum/canonical_runner/run_codex_curriculum_school_v1.ps1 -TargetAccepted <N> -RunKind <Test|Real>"
  scheduler=$schedule
  chunk_size=$ChunkSize
  batch_size=$BatchSize
  codex_cli_present=[bool]$codexCmd
  components_present=($missing.Count -eq 0)
  missing_components=@($missing)
  blockers=@($blockers)
  execution_state=if($status -eq "READY_TEST_SCHEDULE"){"SCHEDULE_READY_EXECUTION_NOT_STARTED"}else{"BLOCKED"}
  next_required_stage=if($status -eq "READY_TEST_SCHEDULE"){"execute_batches_100_under_chunks_5000_then_contract_digest_active_decision_use"}else{"clear_blockers"}
  accepted_core_mutated=$false
  live_absorption_attempted=$false
  boundary="Canonical two-parameter runner/scheduler for Codex curriculum. This invocation plans and gates; it does not call Codex or mutate active atoms."
}
WriteJson "operations/reports/CODEX_CURRICULUM_CANONICAL_RUNNER_V1_LAST_PROOF.json" $report 80
$runReportPath="$runDir/run_plan.json"
WriteJson $runReportPath $report 80
$md=@(
"# CODEX_CURRICULUM_CANONICAL_RUNNER_V1_LAST_PROOF",
"",
"Status: $status",
"Proof label: $proofLabel",
"Runtime ready: false",
"",
"Run kind: $RunKind",
"TargetAccepted: $TargetAccepted",
"ChunkSize: $ChunkSize",
"BatchSize: $BatchSize",
"Chunk count: $($schedule.chunk_count)",
"Batch count: $($schedule.batch_count)",
"Last chunk size: $($schedule.last_chunk_size)",
"Last batch size: $($schedule.last_batch_size)",
"Codex CLI present: $([bool]$codexCmd)",
"Components present: $($missing.Count -eq 0)",
"Blockers: $($blockers.Count)",
"",
"Boundary: schedule/gate only; no Codex execution, no active mutation, no live proof."
)
[IO.File]::WriteAllText((Join-Path (Get-Location).Path "operations/reports/CODEX_CURRICULUM_CANONICAL_RUNNER_V1_LAST_PROOF.md"),($md -join "`r`n"),$utf8)
Write-Host "CANONICAL_RUNNER_STATUS=$status"
Write-Host "PROOF_LABEL=$proofLabel"
Write-Host "TARGET_ACCEPTED=$TargetAccepted"
Write-Host "RUN_KIND=$RunKind"
Write-Host "CHUNK_SIZE=$ChunkSize"
Write-Host "BATCH_SIZE=$BatchSize"
Write-Host "CHUNK_COUNT=$($schedule.chunk_count)"
Write-Host "BATCH_COUNT=$($schedule.batch_count)"
Write-Host "LAST_CHUNK_SIZE=$($schedule.last_chunk_size)"
Write-Host "LAST_BATCH_SIZE=$($schedule.last_batch_size)"
Write-Host "CODEX_CLI_PRESENT=$([bool]$codexCmd)"
Write-Host "BLOCKERS=$($blockers.Count)"
Write-Host "RUNTIME_READY=false"
if($status -like "BLOCKED_*"){ exit 2 }