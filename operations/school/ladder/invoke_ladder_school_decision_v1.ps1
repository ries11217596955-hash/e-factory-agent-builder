param([Parameter(Mandatory=$true)][string]$TaskText,[int]$TopK=5,[switch]$AsJson)
$ErrorActionPreference="Stop"
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$ptr=Get-Content reports/self_development/accepted_change_memory_snapshot.json -Raw | ConvertFrom-Json
if(-not $ptr.active_ladder_school_index_path){throw "ACTIVE_LADDER_SCHOOL_POINTER_MISSING"}
$idx=Get-Content $ptr.active_ladder_school_index_path -Raw | ConvertFrom-Json
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
$lower=$TaskText.ToLowerInvariant(); $domains=New-Object System.Collections.Generic.List[string]
foreach($r in $rules){foreach($kw in $r.keywords){if($lower.Contains($kw.ToLowerInvariant())){if(-not $domains.Contains($r.domain)){$domains.Add($r.domain)|Out-Null}; break}}}
if($domains.Count -eq 0){$domains.Add("behavior_delta")|Out-Null}
$atoms=@(); foreach($d in $domains){$atoms += @($idx.atoms | Where-Object {$_.domain -eq $d} | Select-Object -First $TopK)}
$atomIds=@($atoms | ForEach-Object {$_.atom_id})
$molecules=@($idx.molecules | Where-Object {@($domains) -contains $_.domain} | Select-Object -First 5)
$res=[pscustomobject]@{schema="ladder_school_decision_v1"; status=if($atoms.Count -gt 0){"PASS"}else{"NO_MATCH"}; runtime_ready=$false; task_text=$TaskText; matched_domains=@($domains); atom_count=$atoms.Count; molecule_count=$molecules.Count; atom_ids_used=@($atomIds); molecule_ids_used=@($molecules|ForEach-Object{$_.molecule_id}); baseline_decision="GENERIC_NO_LADDER_ATOM"; active_decision=if($atoms.Count -gt 0){"LADDER_SCHOOL_GUIDED_DECISION"}else{"GENERIC_NO_LADDER_ATOM"}; no_full_scan=$true; top_k=$TopK; decision_context=@($atoms|ForEach-Object{[pscustomobject]@{atom_id=$_.atom_id; sequence=$_.sequence; complexity_score=$_.complexity_score; domain=$_.domain; behavior_rule=$_.behavior_rule}})}
if($AsJson){$res|ConvertTo-Json -Depth 20}else{$res}