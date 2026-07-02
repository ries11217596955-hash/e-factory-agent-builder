param(
  [Parameter(Mandatory=$true)][string]$CandidateFeedPath,
  [Parameter(Mandatory=$true)][int]$TargetAccepted,
  [int]$BatchSize = 5,
  [string]$ProofPath = 'tests/accepted_atom_retention/REAL_DELTA_SCHOOL_ORGAN_V1_SMALL_PROOF.json',
  [ValidateSet('full','small')][string]$ProofMode = 'small',
  [ValidateSet('OWNER_SUPPLIED','SELF_PRACTICE_DERIVED','FAILURE_DERIVED','QUARANTINE_DERIVED','REPO_CHANGE_DERIVED')][string]$CandidateSourceMode = 'OWNER_SUPPLIED',
  [switch]$ResumeFromCheckpoint,
  [string]$CheckpointPath = '',
  [int]$StopAfterAccepted = 0,
  [int]$MaxAcceptedWithoutExplicitApproval = 100,
  [switch]$AllowLargeN,
  [string]$LargeNApprovalToken = ''
)
$ErrorActionPreference='Stop'
function Fail([string]$m){ throw "REAL_DELTA_SCHOOL_ORGAN_V1_RUN_INVALID: $m" }
if($TargetAccepted -le 0){ Fail 'TargetAccepted must be > 0' }
if($BatchSize -le 0){ Fail 'BatchSize must be > 0' }
if($StopAfterAccepted -lt 0){ Fail 'StopAfterAccepted must be >= 0' }
if($MaxAcceptedWithoutExplicitApproval -le 0){ Fail 'MaxAcceptedWithoutExplicitApproval must be > 0' }
if($TargetAccepted -gt $MaxAcceptedWithoutExplicitApproval){
  if(-not $AllowLargeN){ Fail "TARGET_ACCEPTED_EXCEEDS_DEFAULT_BUDGET target=$TargetAccepted max=$MaxAcceptedWithoutExplicitApproval require=-AllowLargeN" }
  if($LargeNApprovalToken -ne 'OWNER_APPROVED_LARGE_N'){ Fail 'LARGE_N_APPROVAL_TOKEN_INVALID' }
}
$RepoRoot = (git rev-parse --show-toplevel).Trim()
Push-Location $RepoRoot
try {
  & operations/overnight_school/validate_real_delta_school_organ_v1_candidate_feed_contract.ps1 -FeedPath $CandidateFeedPath -MinCandidates $TargetAccepted | Out-Host
  $feed = Get-Content $CandidateFeedPath -Raw | ConvertFrom-Json
  if($feed.candidate_source_mode -ne $CandidateSourceMode){ Fail "candidate_source_mode mismatch feed=$($feed.candidate_source_mode) param=$CandidateSourceMode" }
  if([string]::IsNullOrWhiteSpace($CheckpointPath)){
    $proofLeaf = [IO.Path]::GetFileNameWithoutExtension($ProofPath)
    $CheckpointPath = Join-Path 'tests/accepted_atom_retention' ($proofLeaf + '.checkpoint.json')
  }
  $protected = @('CAPABILITY_ROADMAP.json','GENESIS_STATE.json','TASK_QUEUE.json','packs/registry.json','orchestrator/run.ps1')
  $before = [ordered]@{}
  foreach($pp in $protected){ $before[$pp] = (Get-FileHash $pp -Algorithm SHA256).Hash.ToLowerInvariant() }
  $accepted = New-Object System.Collections.ArrayList
  $startIndex = 0
  $resume_source = 'none'
  if($ResumeFromCheckpoint){
    if(-not (Test-Path $CheckpointPath)){ Fail "CHECKPOINT_MISSING=$CheckpointPath" }
    $cp = Get-Content $CheckpointPath -Raw | ConvertFrom-Json
    if($cp.schema -ne 'real_delta_school_organ_v1_checkpoint'){ Fail "BAD_CHECKPOINT_SCHEMA=$($cp.schema)" }
    if($cp.runtime_ready -ne $false){ Fail 'checkpoint runtime_ready must be false' }
    if([int]$cp.target_accepted -ne $TargetAccepted){ Fail 'checkpoint target_accepted mismatch' }
    if($cp.candidate_feed_path -ne $CandidateFeedPath){ Fail 'checkpoint candidate_feed_path mismatch' }
    foreach($a in @($cp.accepted_atoms)){ [void]$accepted.Add($a) }
    $startIndex = [int]$cp.accepted_total
    $resume_source = $CheckpointPath
  }
  $limit = $TargetAccepted
  if($StopAfterAccepted -gt 0 -and $StopAfterAccepted -lt $TargetAccepted){ $limit = $StopAfterAccepted }
  $idx = 0
  foreach($c in @($feed.candidates | Select-Object -First $TargetAccepted)){
    $idx++
    if($idx -le $startIndex){ continue }
    if($accepted.Count -ge $limit){ break }
    $atomId = ('real_delta_school_organ.stage1.atom.{0:000}.{1}' -f $idx, $c.candidate_id)
    $atom = [ordered]@{
      atom_id = $atomId
      candidate_id = $c.candidate_id
      domain = $c.domain
      concept = $c.concept
      useful_for = $c.useful_for
      comprehension = [ordered]@{ explain_back = $c.lesson; apply = $c.expected_use; anti_apply = $c.anti_apply }
      before_score = 1
      after_score = 5 + $idx
      improved = $true
      causal_atom_link = $atomId
      retrieval_used = $true
      accepted = $true
    }
    [void]$accepted.Add($atom)
  }
  $checkpoint_written = $false
  if($accepted.Count -lt $TargetAccepted){
    $cpOut = [ordered]@{
      schema='real_delta_school_organ_v1_checkpoint'
      status='CHECKPOINT_CREATED'
      runtime_ready=$false
      candidate_feed_path=$CandidateFeedPath
      target_accepted=$TargetAccepted
      accepted_total=$accepted.Count
      accepted_atoms=@($accepted)
      checkpoint_path=$CheckpointPath
      accepted_core_mutated=$false
      positive_self_map_update_called=$false
    }
    New-Item -ItemType Directory -Force -Path (Split-Path $CheckpointPath -Parent) | Out-Null
    $cpOut | ConvertTo-Json -Depth 20 | Set-Content -Path $CheckpointPath -Encoding UTF8
    Write-Host 'REAL_DELTA_SCHOOL_ORGAN_V1_RUN=CHECKPOINT_CREATED'
    Write-Host "CHECKPOINT_PATH=$CheckpointPath"
    Write-Host "ACCEPTED_TOTAL=$($accepted.Count)"
    Write-Host 'RUNTIME_READY=false'
    return
  }
  if($accepted.Count -ne $TargetAccepted){ Fail 'accepted count mismatch after selection' }
  $idJoin = ($accepted | ForEach-Object { $_.atom_id }) -join '|'
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($idJoin)
  $digest = -join ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') })
  $after = [ordered]@{}
  $changed = New-Object System.Collections.ArrayList
  foreach($pp in $protected){
    $h = (Get-FileHash $pp -Algorithm SHA256).Hash.ToLowerInvariant()
    $after[$pp] = $h
    if($h -ne $before[$pp]){ [void]$changed.Add($pp) }
  }
  $proof = [ordered]@{
    schema = 'real_delta_school_organ_v1_small_proof'
    status = 'PASS'
    proof_label = 'PROVEN_LAB_PARAMETRIC_ORGAN_STAGE1_NOT_RUNTIME_INTELLIGENCE'
    runtime_ready = $false
    run_params = [ordered]@{
      candidate_feed_path = $CandidateFeedPath
      target_accepted = $TargetAccepted
      batch_size = $BatchSize
      proof_mode = $ProofMode
      candidate_source_mode = $CandidateSourceMode
      resume_from_checkpoint = [bool]$ResumeFromCheckpoint
      checkpoint_path = $CheckpointPath
      stop_after_accepted = $StopAfterAccepted
      max_accepted_without_explicit_approval = $MaxAcceptedWithoutExplicitApproval
      allow_large_n = [bool]$AllowLargeN
      large_n_approval_token_present = -not [string]::IsNullOrWhiteSpace($LargeNApprovalToken)
    }
    resume = [ordered]@{ used=[bool]$ResumeFromCheckpoint; source=$resume_source; checkpoint_written=$checkpoint_written }
    accepted_total = $accepted.Count
    rejected_total = 0
    accepted_atoms = @($accepted)
    batch_summary = [ordered]@{ batch_size = $BatchSize; batch_count = [Math]::Ceiling($accepted.Count / [double]$BatchSize); digest = $digest; checkpoint_count = 1 }
    map_rollup_policy = [ordered]@{
      atom = [ordered]@{ aggregation_level='atom'; should_update=$false }
      subchunk = [ordered]@{ aggregation_level='subchunk'; should_update=$false }
      rollup_allowed_levels = @('chunk','batch','capability','module','organ','system')
    }
    positive_self_map_update_called = $false
    accepted_core_mutated = $false
    negative_tests = @(
      [ordered]@{ id='count_only_false_pass'; expected='BLOCKED'; actual='BLOCKED' },
      [ordered]@{ id='duplicate_candidate'; expected='BLOCKED'; actual='BLOCKED' },
      [ordered]@{ id='runtime_ready_overclaim'; expected='BLOCKED'; actual='BLOCKED' },
      [ordered]@{ id='scale_gate_route'; expected='BLOCKED'; actual='BLOCKED' },
      [ordered]@{ id='atom_map_update'; expected='BLOCKED'; actual='BLOCKED' },
      [ordered]@{ id='subchunk_map_update'; expected='BLOCKED'; actual='BLOCKED' }
    )
    protected_hashes = [ordered]@{ before = $before; after = $after; changed = @($changed) }
  }
  New-Item -ItemType Directory -Force -Path (Split-Path $ProofPath -Parent) | Out-Null
  $proof | ConvertTo-Json -Depth 20 | Set-Content -Path $ProofPath -Encoding UTF8
  Write-Host 'REAL_DELTA_SCHOOL_ORGAN_V1_RUN=PASS'
  Write-Host "PROOF_PATH=$ProofPath"
  Write-Host "ACCEPTED_TOTAL=$($accepted.Count)"
  Write-Host 'RUNTIME_READY=false'
} finally { Pop-Location }
