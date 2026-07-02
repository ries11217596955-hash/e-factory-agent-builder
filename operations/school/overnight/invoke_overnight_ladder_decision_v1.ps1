param([Parameter(Mandatory=$true)][string]$TaskText,[int]$TopK=5,[switch]$AsJson)
$ErrorActionPreference="Stop"
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$checkpointPath="operations/school/overnight/store/active_overnight_ladder_school_v1/active_overnight_checkpoint.json"
if(-not(Test-Path $checkpointPath)){throw "ACTIVE_OVERNIGHT_CHECKPOINT_MISSING"}
$cp=Get-Content $checkpointPath -Raw|ConvertFrom-Json
$domains=@($cp.domains)
$rules=@(
  @{domain="promotion_lifecycle"; keywords=@("promote","promotion","pass","lab","school","test")},
  @{domain="living_cell_growth"; keywords=@("cell","living","atom","molecule","organ","alphabet")},
  @{domain="school_freedom_governance"; keywords=@("freedom","autonomy","life","school","observe")},
  @{domain="attention_memory_routing"; keywords=@("memory","scan","top-k","router","trillion")},
  @{domain="source_ladder"; keywords=@("source","analogy","unknown","books")},
  @{domain="rollback_immune"; keywords=@("rollback","immune","quarantine","restore")},
  @{domain="codex_boundary"; keywords=@("codex","preflight","write","mutation")},
  @{domain="behavior_delta"; keywords=@("behavior","decision","stronger","delta")}
)
$lower=$TaskText.ToLowerInvariant(); $matched=New-Object System.Collections.Generic.List[string]
foreach($r in $rules){foreach($kw in $r.keywords){if($lower.Contains($kw.ToLowerInvariant())){if(-not $matched.Contains($r.domain)){$matched.Add($r.domain)|Out-Null}; break}}}
if($matched.Count -eq 0){$matched.Add("behavior_delta")|Out-Null}
$atoms=@()
foreach($d in $matched){
  $idx=[Array]::IndexOf($domains,$d)
  if($idx -lt 0){continue}
  for($k=0;$k -lt $TopK;$k++){
    $seq=$idx+1+($k*10)
    if($seq -le [int]$cp.last_good_checkpoint){$atoms += [pscustomobject]@{atom_id="atom.overnight.$('{0:D6}' -f $seq).$d.v1"; sequence=$seq; complexity_score=$seq; domain=$d; behavior_rule="Use overnight ladder atom $seq for $d with compact proof-backed decision and no full scan."}}
  }
}
$mols=@(); foreach($d in $matched){ for($tier=1; $tier -le 5; $tier++){ if($mols.Count -ge 5){break}; $mols += [pscustomobject]@{molecule_id=("molecule.overnight.{0}.tier{1:D6}.v1" -f $d,$tier); domain=$d; tier=$tier} } }
$res=[pscustomobject]@{schema="overnight_ladder_decision_v1"; status=if($atoms.Count -gt 0){"PASS"}else{"NO_MATCH"}; runtime_ready=$false; task_text=$TaskText; run_id=$cp.run_id; last_good_checkpoint=$cp.last_good_checkpoint; matched_domains=@($matched); atom_count=$atoms.Count; molecule_count=$mols.Count; atom_ids_used=@($atoms|ForEach-Object{$_.atom_id}); molecule_ids_used=@($mols|ForEach-Object{$_.molecule_id}); baseline_decision="GENERIC_NO_OVERNIGHT_LADDER"; active_decision=if($atoms.Count -gt 0){"OVERNIGHT_LADDER_GUIDED_DECISION"}else{"GENERIC_NO_OVERNIGHT_LADDER"}; no_full_scan=$true; top_k=$TopK; decision_context=@($atoms)}
if($AsJson){$res|ConvertTo-Json -Depth 30}else{$res}