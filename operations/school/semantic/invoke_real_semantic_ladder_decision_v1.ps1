param([Parameter(Mandatory=$true)][string]$TaskText,[int]$TopK=5,[switch]$AsJson)
$ErrorActionPreference="Stop"
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$cpPath='operations/school/semantic/store/active_real_semantic_ladder_school_v1/active_semantic_checkpoint.json'
if(-not(Test-Path $cpPath)){throw 'ACTIVE_REAL_SEMANTIC_CHECKPOINT_MISSING'}
$cp=Get-Content $cpPath -Raw | ConvertFrom-Json
$rules=@(
  @{domain='promotion_lifecycle'; keywords=@('promote','promotion','pass','school','test')},
  @{domain='living_cell_growth'; keywords=@('cell','living','atom','molecule','organ','alphabet')},
  @{domain='school_freedom_governance'; keywords=@('freedom','autonomy','life','observe','school')},
  @{domain='attention_memory_routing'; keywords=@('memory','scan','top-k','router','trillion')},
  @{domain='source_ladder'; keywords=@('source','analogy','unknown','books')},
  @{domain='evidence_acceptance'; keywords=@('proof','evidence','accept','validate')},
  @{domain='rollback_immune'; keywords=@('rollback','immune','quarantine')},
  @{domain='codex_boundary'; keywords=@('codex','preflight','write')},
  @{domain='memory_budget'; keywords=@('budget','limit','bloat')},
  @{domain='behavior_delta'; keywords=@('behavior','decision','stronger','delta')}
)
$lower=$TaskText.ToLowerInvariant(); $domains=New-Object System.Collections.Generic.List[string]
foreach($r in $rules){foreach($kw in $r.keywords){if($lower.Contains($kw.ToLowerInvariant())){if(-not $domains.Contains($r.domain)){$domains.Add($r.domain)|Out-Null}; break}}}
if($domains.Count -eq 0){$domains.Add('behavior_delta')|Out-Null}
$atoms=@(); foreach($d in $domains){$atoms += @($cp.accepted_atoms | Where-Object {$_.domain -eq $d} | Select-Object -First $TopK)}
$molecules=@($cp.molecules | Where-Object {@($domains) -contains $_.domain} | Select-Object -First 5)
$res=[pscustomobject]@{schema='real_semantic_ladder_decision_v1'; status=if($atoms.Count -gt 0){'PASS'}else{'NO_MATCH'}; runtime_ready=$false; run_id=$cp.run_id; task_text=$TaskText; learned_count=$cp.learned_count; matched_domains=@($domains); atom_count=$atoms.Count; molecule_count=$molecules.Count; atom_ids_used=@($atoms|ForEach-Object{$_.atom_id}); molecule_ids_used=@($molecules|ForEach-Object{$_.molecule_id}); baseline_decision='GENERIC_NO_REAL_SEMANTIC_ATOM'; active_decision=if($atoms.Count -gt 0){'REAL_SEMANTIC_LADDER_GUIDED_DECISION'}else{'GENERIC_NO_REAL_SEMANTIC_ATOM'}; no_full_scan=$true; decision_context=@($atoms|ForEach-Object{[pscustomobject]@{atom_id=$_.atom_id; semantic_hash=$_.semantic_hash; domain=$_.domain; behavior_rule=$_.behavior_rule}})}
if($AsJson){$res|ConvertTo-Json -Depth 30}else{$res}