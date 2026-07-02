param(
  [Parameter(Mandatory=$true)][ValidateRange(1,2147483647)][int]$TargetAccepted,
  [Parameter(Mandatory=$true)][ValidateSet("Test","Real")][string]$RunKind,
  [int]$PerBatchTimeoutSeconds=240,
  [switch]$Resume
)
$ErrorActionPreference="Stop"
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$utf8=New-Object System.Text.UTF8Encoding($false)
function WriteJson($p,$o,$d=80){$dir=Split-Path -Parent $p; if($dir){New-Item -ItemType Directory -Force -Path $dir|Out-Null}; [IO.File]::WriteAllText((Join-Path (Get-Location).Path $p),($o|ConvertTo-Json -Depth $d),$utf8)}
function ReadJson($p){ return Get-Content $p -Raw | ConvertFrom-Json }
function Invoke-CodexBatch($promptPath,$lastMsg,$stdoutPath,$stderrPath,$timeoutSeconds){
  $cmd="`$ErrorActionPreference='Stop'; Get-Content -Raw '$promptPath' | codex exec --cd . --sandbox workspace-write --output-last-message '$lastMsg' --json -"
  $arg=@('-NoProfile','-ExecutionPolicy','Bypass','-Command',$cmd)
  $p=Start-Process -FilePath 'powershell.exe' -ArgumentList $arg -WorkingDirectory (Get-Location).Path -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -PassThru -WindowStyle Hidden
  $finished=$p.WaitForExit($timeoutSeconds*1000)
  if(-not $finished){
    try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch {}
    return [pscustomobject]@{exit_code=124; timed_out=$true}
  }
  return [pscustomobject]@{exit_code=$p.ExitCode; timed_out=$false}
}
if($RunKind -eq 'Real'){ throw 'BLOCKED_REAL_GATES: execution runner only supports Test until live/Real gates are proven' }
& operations/school/curriculum/canonical_runner/run_codex_curriculum_school_v1.ps1 -TargetAccepted $TargetAccepted -RunKind $RunKind | Out-Host
$plan=ReadJson 'operations/reports/CODEX_CURRICULUM_CANONICAL_RUNNER_V1_LAST_PROOF.json'
if($plan.status -ne 'READY_TEST_SCHEDULE'){ throw "PLAN_NOT_READY: $($plan.status)" }
$runId="codex_curriculum_exec_{0}_{1}_{2}" -f $RunKind.ToLowerInvariant(),$TargetAccepted,(Get-Date -Format 'yyyyMMdd_HHmmss')
if($Resume){
  $base='.runtime/codex_curriculum_execution_runs'
  $latest=Get-ChildItem $base -Directory -ErrorAction SilentlyContinue | Where-Object {$_.Name -like "codex_curriculum_exec_$($RunKind.ToLowerInvariant())_$TargetAccepted*"} | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if($latest){ $runDir=$latest.FullName.Substring((Get-Location).Path.Length+1); $runId=$latest.Name } else { $runDir="$base/$runId" }
} else { $runDir=".runtime/codex_curriculum_execution_runs/$runId" }
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
$aggregate="$runDir/all_candidates.jsonl"
if(-not $Resume -and (Test-Path $aggregate)){ Remove-Item $aggregate -Force }
$batchResults=@(); $acceptedTotal=0; $rejectedTotal=0; $processedTotal=0; $failed=$false; $stopReason='COMPLETED'
$globalCandidateStart=0
foreach($chunk in $plan.scheduler.chunks){
  foreach($batch in $chunk.batches){
    $batchTarget=[int]$batch.target
    $globalBatch=[int]$batch.global_batch_index
    $batchDir="$runDir/chunk_$('{0:D4}' -f [int]$chunk.chunk_index)/batch_$('{0:D4}' -f $globalBatch)"
    New-Item -ItemType Directory -Force -Path $batchDir | Out-Null
    $batchPath="$batchDir/candidates.jsonl"
    $validationPath="$batchDir/validation.json"
    if($Resume -and (Test-Path $batchPath) -and (Test-Path $validationPath)){
      $v=ReadJson $validationPath
      if($v.status -eq 'PASS_CODEX_CURRICULUM_BATCH_VALIDATOR_V1'){
        $processedTotal += [int]$v.processed_count; $acceptedTotal += [int]$v.accepted_count; $rejectedTotal += [int]$v.rejected_count
        $globalCandidateStart += $batchTarget
        $batchResults += [pscustomobject]@{global_batch_index=$globalBatch; target=$batchTarget; status='PASS_RESUMED'; processed=$v.processed_count; accepted=$v.accepted_count; rejected=$v.rejected_count; path=$batchPath}
        continue
      }
    }
    if((Test-Path $batchPath) -and -not (Test-Path $validationPath)){
      $existingLineCount=(Get-Content $batchPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
      if($existingLineCount -eq $batchTarget){
        & operations/school/curriculum/codex_contract/validate_codex_curriculum_batch_v1.ps1 -BatchPath $batchPath | Out-Host
        $v=ReadJson 'operations/reports/CODEX_CURRICULUM_CONTRACT_V1_VALIDATION.json'
        WriteJson $validationPath $v 60
        if($v.status -eq 'PASS_CODEX_CURRICULUM_BATCH_VALIDATOR_V1'){
          Get-Content $batchPath | Add-Content $aggregate
          $processedTotal += [int]$v.processed_count; $acceptedTotal += [int]$v.accepted_count; $rejectedTotal += [int]$v.rejected_count
          $batchResults += [pscustomobject]@{global_batch_index=$globalBatch; target=$batchTarget; status='PASS_EXISTING_FILE_VALIDATED'; processed=$v.processed_count; accepted=$v.accepted_count; rejected=$v.rejected_count; path=$batchPath}
          $globalCandidateStart += $batchTarget
          $checkpoint=[pscustomobject]@{schema='codex_curriculum_execution_checkpoint_v1'; run_id=$runId; status='RUNNING'; target_accepted=$TargetAccepted; run_kind=$RunKind; planned_batches=$plan.scheduler.batch_count; completed_batches=@($batchResults|Where-Object {$_.status -like 'PASS*'}).Count; processed_total=$processedTotal; accepted_total=$acceptedTotal; rejected_total=$rejectedTotal; last_batch=$globalBatch; aggregate_path=$aggregate; updated_at=(Get-Date).ToString('o')}
          WriteJson "$runDir/checkpoint.json" $checkpoint 80
          continue
        }
      }
    }
    $promptPath="$batchDir/prompt.md"; $lastMsg="$batchDir/last_message.md"; $stdout="$batchDir/codex_stdout.jsonl"; $stderr="$batchDir/codex_stderr.txt"
    $start=$globalCandidateStart+1; $end=$globalCandidateStart+$batchTarget
    $prompt=@"
You are Codex acting as bounded curriculum candidate producer, not Builder brain.

TASK: Write exactly $batchTarget JSONL curriculum candidates to this path:
$batchPath

Context:
- This is a Test run, not live.
- TargetAccepted=$TargetAccepted
- ChunkIndex=$($chunk.chunk_index)
- GlobalBatchIndex=$globalBatch
- Candidate ordinal range=$start..$end
- Each line MUST be one valid JSON object. No markdown. No comments.

Read before writing:
- operations/school/curriculum/codex_contract/CODEX_CURRICULUM_CONTRACT_V1.md

Required schema fields for every line:
candidate_id, source_mode, topic, level, objective, new_knowledge, exercise, expected_behavior, negative_trap, validator_hint, behavior_use_proof_target, return_to_parent, source_anchor, duplicate_key, self_generated_easy_candidate

Hard rules:
- Produce exactly $batchTarget lines.
- Use unique candidate_id and duplicate_key inside this batch.
- Prefix candidate_id with codex.curriculum.exec.$TargetAccepted.batch_$globalBatch.
- Use source_mode directed_curriculum for about 75% and experience_curriculum for about 25%.
- level must be 1, 2, or 3.
- self_generated_easy_candidate must be false.
- Do not use placeholders, TODO, same-as-above, lorem, or generic numbered clones.
- Every exercise must be concrete and at least 20 characters.
- Every negative_trap must be meaningful and at least 10 characters.
- Every behavior_use_proof_target must be concrete and at least 20 characters.
- return_to_parent must explain how this lesson improves the parent Builder loop.
- Do not claim the count proves learning.
- Do not modify any other file.

Topic map:
Create transferable Builder curriculum lessons across proof boundaries, school-vs-life separation, Codex preflight, batch validation, chunk checkpointing, rejection handling, rollback, active decision-use, owner correction handling, source governance, candidate quality, negative tests, and runtime/live boundary. Make topics specific, varied, and non-duplicative.

After writing, report only a compact summary.
"@
    [IO.File]::WriteAllText((Join-Path (Get-Location).Path $promptPath),$prompt,$utf8)
    $codex=Invoke-CodexBatch $promptPath $lastMsg $stdout $stderr $PerBatchTimeoutSeconds
    if($codex.timed_out -or $codex.exit_code -ne 0){
      $producedOk=$false
      if(Test-Path $batchPath){
        $producedLineCount=(Get-Content $batchPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
        if($producedLineCount -eq $batchTarget){ $producedOk=$true }
      }
      if(-not $producedOk){
        $failed=$true; $stopReason="CODEX_BATCH_FAILED_OR_TIMEOUT_$globalBatch"
        $batchResults += [pscustomobject]@{global_batch_index=$globalBatch; target=$batchTarget; status='CODEX_FAILED'; exit_code=$codex.exit_code; timed_out=$codex.timed_out; path=$batchPath}
        break
      }
    }
    if(-not (Test-Path $batchPath)){
      $failed=$true; $stopReason="BATCH_FILE_MISSING_$globalBatch"
      $batchResults += [pscustomobject]@{global_batch_index=$globalBatch; target=$batchTarget; status='BATCH_MISSING'; path=$batchPath}
      break
    }
    $lineCount=(Get-Content $batchPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
    if($lineCount -ne $batchTarget){
      $failed=$true; $stopReason="BATCH_LINE_COUNT_MISMATCH_$globalBatch"
      $batchResults += [pscustomobject]@{global_batch_index=$globalBatch; target=$batchTarget; status='LINE_COUNT_FAIL'; line_count=$lineCount; path=$batchPath}
      break
    }
    & operations/school/curriculum/codex_contract/validate_codex_curriculum_batch_v1.ps1 -BatchPath $batchPath | Out-Host
    $v=ReadJson 'operations/reports/CODEX_CURRICULUM_CONTRACT_V1_VALIDATION.json'
    WriteJson $validationPath $v 60
    if($v.status -ne 'PASS_CODEX_CURRICULUM_BATCH_VALIDATOR_V1'){
      $failed=$true; $stopReason="BATCH_VALIDATION_FAIL_$globalBatch"
      $batchResults += [pscustomobject]@{global_batch_index=$globalBatch; target=$batchTarget; status='VALIDATION_FAIL'; processed=$v.processed_count; accepted=$v.accepted_count; rejected=$v.rejected_count; path=$batchPath}
      break
    }
    Get-Content $batchPath | Add-Content $aggregate
    $processedTotal += [int]$v.processed_count; $acceptedTotal += [int]$v.accepted_count; $rejectedTotal += [int]$v.rejected_count
    $batchResults += [pscustomobject]@{global_batch_index=$globalBatch; target=$batchTarget; status='PASS'; processed=$v.processed_count; accepted=$v.accepted_count; rejected=$v.rejected_count; path=$batchPath}
    $globalCandidateStart += $batchTarget
    $checkpoint=[pscustomobject]@{schema='codex_curriculum_execution_checkpoint_v1'; run_id=$runId; status='RUNNING'; target_accepted=$TargetAccepted; run_kind=$RunKind; planned_batches=$plan.scheduler.batch_count; completed_batches=@($batchResults|Where-Object {$_.status -like 'PASS*'}).Count; processed_total=$processedTotal; accepted_total=$acceptedTotal; rejected_total=$rejectedTotal; last_batch=$globalBatch; aggregate_path=$aggregate; updated_at=(Get-Date).ToString('o')}
    WriteJson "$runDir/checkpoint.json" $checkpoint 80
  }
  if($failed){ break }
}
$status=if(-not $failed -and $processedTotal -eq $TargetAccepted -and $acceptedTotal -gt 0){'PASS_CODEX_CURRICULUM_EXECUTION_RUN_V1'}else{'FAIL_CODEX_CURRICULUM_EXECUTION_RUN_V1'}
$report=[pscustomobject]@{schema='codex_curriculum_execution_run_v1'; status=$status; runtime_ready=$false; run_id=$runId; run_kind=$RunKind; target_accepted=$TargetAccepted; planned_chunks=$plan.scheduler.chunk_count; planned_batches=$plan.scheduler.batch_count; completed_batches=@($batchResults|Where-Object {$_.status -like 'PASS*'}).Count; processed_total=$processedTotal; accepted_total=$acceptedTotal; rejected_total=$rejectedTotal; stop_reason=$stopReason; aggregate_path=$aggregate; batch_results=@($batchResults); boundary='Real Codex execution in Test lab. No active promotion until digestion and decision-use proof pass.'}
WriteJson 'operations/reports/CODEX_CURRICULUM_EXECUTION_RUN_V1.json' $report 100
$md=@('# CODEX_CURRICULUM_EXECUTION_RUN_V1','',"Status: $status",'Runtime ready: false','',"Run id: $runId","Run kind: $RunKind","TargetAccepted: $TargetAccepted","Planned chunks: $($plan.scheduler.chunk_count)","Planned batches: $($plan.scheduler.batch_count)","Completed batches: $($report.completed_batches)","Processed total: $processedTotal","Accepted total: $acceptedTotal","Rejected total: $rejectedTotal","Stop reason: $stopReason",'',"Aggregate path: $aggregate",'', 'Boundary: real Codex execution in Test lab only; no live proof.')
[IO.File]::WriteAllText((Join-Path (Get-Location).Path 'operations/reports/CODEX_CURRICULUM_EXECUTION_RUN_V1.md'),($md -join "`r`n"),$utf8)
Write-Host "EXECUTION_STATUS=$status"
Write-Host "RUN_ID=$runId"
Write-Host "TARGET_ACCEPTED=$TargetAccepted"
Write-Host "PLANNED_BATCHES=$($plan.scheduler.batch_count)"
Write-Host "COMPLETED_BATCHES=$($report.completed_batches)"
Write-Host "PROCESSED_TOTAL=$processedTotal"
Write-Host "ACCEPTED_TOTAL=$acceptedTotal"
Write-Host "REJECTED_TOTAL=$rejectedTotal"
Write-Host "STOP_REASON=$stopReason"
Write-Host "AGGREGATE_PATH=$aggregate"
if($status -notlike 'PASS_*'){ exit 1 }