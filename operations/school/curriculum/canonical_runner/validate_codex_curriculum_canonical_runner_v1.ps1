$ErrorActionPreference="Stop"
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$utf8=New-Object System.Text.UTF8Encoding($false)
$results=@()
function Run-Case([int]$N,[string]$Kind,[int]$ExpectChunks,[int]$ExpectBatches,[int]$ExpectLastChunk,[int]$ExpectLastBatch,[string]$ExpectStatusPrefix){
  $out=& operations/school/curriculum/canonical_runner/run_codex_curriculum_school_v1.ps1 -TargetAccepted $N -RunKind $Kind 2>&1
  $exit=$LASTEXITCODE
  $proof=Get-Content operations/reports/CODEX_CURRICULUM_CANONICAL_RUNNER_V1_LAST_PROOF.json -Raw | ConvertFrom-Json
  $ok=($proof.run_kind -eq $Kind -and [int]$proof.target_accepted -eq $N -and [int]$proof.scheduler.chunk_size -eq 5000 -and [int]$proof.scheduler.batch_size -eq 100 -and [int]$proof.scheduler.chunk_count -eq $ExpectChunks -and [int]$proof.scheduler.batch_count -eq $ExpectBatches -and [int]$proof.scheduler.last_chunk_size -eq $ExpectLastChunk -and [int]$proof.scheduler.last_batch_size -eq $ExpectLastBatch -and ([string]$proof.status).StartsWith($ExpectStatusPrefix))
  return [pscustomobject]@{id="N${N}_${Kind}"; status=if($ok){"PASS"}else{"FAIL"}; exit_code=$exit; runner_status=$proof.status; target=$N; kind=$Kind; chunk_count=$proof.scheduler.chunk_count; batch_count=$proof.scheduler.batch_count; last_chunk_size=$proof.scheduler.last_chunk_size; last_batch_size=$proof.scheduler.last_batch_size; blockers=@($proof.blockers)}
}
$results += Run-Case 5000 "Test" 1 50 5000 100 "READY_TEST_SCHEDULE"
$results += Run-Case 5001 "Test" 2 51 1 1 "READY_TEST_SCHEDULE"
$results += Run-Case 5839 "Test" 2 59 839 39 "READY_TEST_SCHEDULE"
$results += Run-Case 30000 "Test" 6 300 5000 100 "READY_TEST_SCHEDULE"
$results += Run-Case 5000 "Real" 1 50 5000 100 "BLOCKED_REAL_GATES"
$fail=@($results | Where-Object {$_.status -ne "PASS"}).Count
$status=if($fail -eq 0){"PASS_CODEX_CURRICULUM_CANONICAL_RUNNER_V1"}else{"FAIL_CODEX_CURRICULUM_CANONICAL_RUNNER_V1"}
$report=[pscustomobject]@{schema="codex_curriculum_canonical_runner_validator_v1"; status=$status; runtime_ready=$false; owner_interface="TargetAccepted + RunKind only"; chunk_size=5000; batch_size=100; case_count=$results.Count; pass_count=@($results|Where-Object {$_.status -eq "PASS"}).Count; fail_count=$fail; results=@($results); boundary="Validates two-parameter scheduler/gate. Does not execute Codex candidate generation."}
[IO.File]::WriteAllText((Join-Path (Get-Location).Path "operations/reports/CODEX_CURRICULUM_CANONICAL_RUNNER_V1_VALIDATION.json"),($report|ConvertTo-Json -Depth 60),$utf8)
$lines=($results|ForEach-Object{"- $($_.id): $($_.status), runner=$($_.runner_status), chunks=$($_.chunk_count), batches=$($_.batch_count), last_chunk=$($_.last_chunk_size), last_batch=$($_.last_batch_size)"}) -join "`r`n"
$md=@("# CODEX_CURRICULUM_CANONICAL_RUNNER_V1_VALIDATION","","Status: $status","Runtime ready: false","","Owner interface: TargetAccepted + RunKind only","ChunkSize: 5000","BatchSize: 100","Pass: $($report.pass_count)","Fail: $fail","","## Results",$lines,"","Boundary: scheduler/gate validation only; no Codex execution.")
[IO.File]::WriteAllText((Join-Path (Get-Location).Path "operations/reports/CODEX_CURRICULUM_CANONICAL_RUNNER_V1_VALIDATION.md"),($md -join "`r`n"),$utf8)
Write-Host "VALIDATION_STATUS=$status"
Write-Host "CASE_COUNT=$($results.Count)"
Write-Host "PASS_COUNT=$($report.pass_count)"
Write-Host "FAIL_COUNT=$fail"
Write-Host "OWNER_INTERFACE=TargetAccepted+RunKind"
Write-Host "CHUNK_SIZE=5000"
Write-Host "BATCH_SIZE=100"
Write-Host "RUNTIME_READY=false"
if($status -notlike "PASS_*"){exit 1}