param(
  [int]$CandidateCount = 25,
  [string]$FeedPath = 'operations/overnight_school/REAL_DELTA_SCHOOL_ORGAN_V1_DRY_RUN_FEED_25.json'
)
$ErrorActionPreference='Stop'
if($CandidateCount -lt 1){ throw 'CandidateCount must be >= 1' }
$candidates = New-Object System.Collections.ArrayList
for($i=1; $i -le $CandidateCount; $i++){
  $id = ('dryrun.atom.{0:000}' -f $i)
  $domain = 'dry_run_domain_' + (($i % 7) + 1)
  $concept = ('dry_run_unique_concept_{0:000}' -f $i)
  [void]$candidates.Add([ordered]@{
    candidate_id = $id
    domain = $domain
    concept = $concept
    useful_for = "mechanics-only batch/checkpoint validation item $i"
    lesson = "Dry-run candidate $i proves mechanics fields are wired; it does not prove learning quality."
    before_answer = "Before dry-run item $i, the runner has no accepted proof for this item."
    after_answer = "After dry-run item $i, the proof records accepted atom, causal link, retrieval flag and score delta."
    anti_apply = "Do not treat dry-run item $i as semantic intelligence or live readiness."
    expected_use = "Use item $i only to test parametric runner mechanics, batching and checkpoint/resume."
  })
}
$feed=[ordered]@{
  schema='real_delta_school_organ_v1_candidate_feed'
  candidate_source_mode='OWNER_SUPPLIED'
  feed_purpose='DRY_RUN_MECHANICS_ONLY'
  generated_for_test=$true
  learning_quality_claimed=$false
  runtime_ready=$false
  candidate_count=$CandidateCount
  candidates=@($candidates)
}
New-Item -ItemType Directory -Force -Path (Split-Path $FeedPath -Parent) | Out-Null
$feed | ConvertTo-Json -Depth 20 | Set-Content -Path $FeedPath -Encoding UTF8
Write-Host 'REAL_DELTA_SCHOOL_ORGAN_V1_DRY_RUN_FEED_GENERATED=PASS'
Write-Host "FEED_PATH=$FeedPath"
Write-Host "CANDIDATE_COUNT=$CandidateCount"
Write-Host 'FEED_PURPOSE=DRY_RUN_MECHANICS_ONLY'
Write-Host 'LEARNING_QUALITY_CLAIMED=false'
Write-Host 'RUNTIME_READY=false'
