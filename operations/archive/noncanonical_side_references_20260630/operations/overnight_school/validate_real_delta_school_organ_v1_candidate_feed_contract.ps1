param(
  [Parameter(Mandatory=$true)][string]$FeedPath,
  [int]$MinCandidates = 1
)
$ErrorActionPreference='Stop'
function Fail([string]$m){ throw "REAL_DELTA_SCHOOL_ORGAN_V1_CANDIDATE_FEED_CONTRACT_INVALID: $m" }
if(-not (Test-Path $FeedPath)){ Fail "FEED_MISSING=$FeedPath" }
$raw = Get-Content $FeedPath -Raw
$feed = $raw | ConvertFrom-Json
if($feed.schema -ne 'real_delta_school_organ_v1_candidate_feed'){ Fail "BAD_SCHEMA=$($feed.schema)" }
if($feed.runtime_ready -ne $false){ Fail 'runtime_ready must be false' }
if([string]::IsNullOrWhiteSpace($feed.candidate_source_mode)){ Fail 'candidate_source_mode missing' }
$candidates = @($feed.candidates)
if($candidates.Count -lt $MinCandidates){ Fail "CANDIDATE_COUNT_LT_MIN count=$($candidates.Count) min=$MinCandidates" }
$ids = @{}
$concepts = @{}
$required = @('candidate_id','domain','concept','useful_for','lesson','before_answer','after_answer','anti_apply','expected_use')
foreach($c in $candidates){
  foreach($r in $required){
    if(-not ($c.PSObject.Properties.Name -contains $r)){ Fail "CANDIDATE_FIELD_MISSING=$r" }
    if([string]::IsNullOrWhiteSpace([string]$c.$r)){ Fail "CANDIDATE_FIELD_EMPTY=$r id=$($c.candidate_id)" }
  }
  if($ids.ContainsKey([string]$c.candidate_id)){ Fail "DUPLICATE_CANDIDATE_ID=$($c.candidate_id)" }
  $ids[[string]$c.candidate_id] = $true
  $conceptKey = (([string]$c.domain)+'|'+([string]$c.concept)+'|'+([string]$c.useful_for)).ToLowerInvariant()
  if($concepts.ContainsKey($conceptKey)){ Fail "DUPLICATE_CONCEPT=$conceptKey" }
  $concepts[$conceptKey] = $true
}
Write-Host 'VALIDATION_PASS=REAL_DELTA_SCHOOL_ORGAN_V1_CANDIDATE_FEED_CONTRACT_VALID'
Write-Host "FEED_PATH=$FeedPath"
Write-Host "CANDIDATE_COUNT=$($candidates.Count)"
Write-Host 'RUNTIME_READY=false'
