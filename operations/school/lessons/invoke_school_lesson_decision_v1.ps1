param(
  [Parameter(Mandatory=$true)][string]$TaskText,
  [int]$TopK=3,
  [switch]$AsJson
)
$ErrorActionPreference="Stop"
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$pointer=Get-Content reports/self_development/accepted_change_memory_snapshot.json -Raw | ConvertFrom-Json
if(-not $pointer.active_school_lesson_index_path){ throw "ACTIVE_SCHOOL_LESSON_POINTER_MISSING" }
$index=Get-Content $pointer.active_school_lesson_index_path -Raw | ConvertFrom-Json
$rules=@(
  @{domain="promotion_lifecycle"; keywords=@("promote","promotion","pass","lab","test","report","safe","copy","реал","тест")},
  @{domain="living_cell_growth"; keywords=@("cell","living","organ","atom","molecule","alphabet","клет","атом","молек")},
  @{domain="school_freedom_governance"; keywords=@("school","freedom","autonomy","life path","observe","школ","свобод","жизн")},
  @{domain="attention_memory_routing"; keywords=@("memory","trillion","scan","top-k","router","память","триллион")},
  @{domain="source_ladder"; keywords=@("Seklitova","Strelnikova","source","analogy","unknown","аналог","книг")}
)
$lower=$TaskText.ToLowerInvariant(); $domains=New-Object System.Collections.Generic.List[string]
foreach($rule in $rules){ foreach($kw in $rule.keywords){ if($lower.Contains($kw.ToLowerInvariant())){ if(-not $domains.Contains($rule.domain)){ $domains.Add($rule.domain)|Out-Null}; break } } }
if($domains.Count -eq 0){ $domains.Add("living_cell_growth")|Out-Null }
$lessons=@(); foreach($d in $domains){ $lessons += @($index.lessons | Where-Object {$_.domain -eq $d} | Select-Object -First $TopK) }
$lessonIds=@($lessons | ForEach-Object {$_.lesson_id})
$molecules=@($index.molecules | Where-Object { $d=$_.domain; (@($domains) -contains $d) -or (@($_.lesson_ids) | Where-Object { @($lessonIds) -contains $_ }).Count -gt 0 } | Select-Object -First 3)
$result=[pscustomobject]@{schema="school_lesson_decision_v1"; status=if($lessons.Count -gt 0){"PASS"}else{"NO_LESSON_MATCH"}; runtime_ready=$false; task_text=$TaskText; matched_domains=@($domains); lesson_count=$lessons.Count; molecule_count=$molecules.Count; lesson_ids_used=@($lessonIds); molecule_ids_used=@($molecules | ForEach-Object {$_.molecule_id}); baseline_decision="GENERIC_NO_SCHOOL_MEANING"; active_decision=if($lessons.Count -gt 0){"SCHOOL_MEANING_GUIDED_DECISION"}else{"GENERIC_NO_SCHOOL_MEANING"}; decision_context=@($lessons | ForEach-Object {[pscustomobject]@{lesson_id=$_.lesson_id; domain=$_.domain; meaning=$_.meaning; behavior_rule=$_.behavior_rule}}); no_full_scan=$true; top_k=$TopK}
if($AsJson){ $result | ConvertTo-Json -Depth 20 } else { $result }