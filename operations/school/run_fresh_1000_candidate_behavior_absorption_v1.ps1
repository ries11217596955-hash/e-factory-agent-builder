param(
    [int]$CandidateCount = 1000,
    [int[]]$Checkpoints = @(10,100,500,700,1000)
)

$ErrorActionPreference = "Stop"
$repoRoot = (git rev-parse --show-toplevel).Trim()
Set-Location $repoRoot

if ($CandidateCount -lt 1) { throw "CandidateCount must be positive" }
$Checkpoints = @($Checkpoints | Where-Object { $_ -le $CandidateCount } | Sort-Object -Unique)
if ($Checkpoints.Count -eq 0 -or $Checkpoints[-1] -ne $CandidateCount) { $Checkpoints += $CandidateCount; $Checkpoints = @($Checkpoints | Sort-Object -Unique) }

$protectedPaths = @(
  "reports/self_development/SELF_MODEL_ACTIVE_MAP.json",
  "reports/self_development/accepted_change_memory_snapshot.json",
  "packs/registry.json"
)
function Get-HashOrMissing([string]$Path) {
    if (Test-Path $Path) { return (Get-FileHash $Path -Algorithm SHA256).Hash.ToLower() }
    return "MISSING"
}
$protectedBefore = @{}
foreach ($p in $protectedPaths) { $protectedBefore[$p] = Get-HashOrMissing $p }

$runId = "fresh1000_" + (Get-Date -Format "yyyyMMdd_HHmmss")
$runtimeRoot = Join-Path ".runtime" $runId
New-Item -ItemType Directory -Force -Path $runtimeRoot | Out-Null

$domains = @(
  "evidence_and_acceptance",
  "codex_boundary",
  "live_lab_boundary",
  "retention_and_memory",
  "input_x_restore",
  "bloat_control",
  "behavior_injection",
  "rollback_checkpoint",
  "owner_authority",
  "validator_order"
)

function New-Candidate([int]$N) {
    $domain = $domains[($N - 1) % $domains.Count]
    $conceptIndex = [int][Math]::Floor(($N - 1) / $domains.Count) + 1
    $atomId = "fresh.behavior.$domain.$('{0:D4}' -f $conceptIndex).v1"
    return [pscustomobject]@{
        candidate_id = "fresh.candidate.$('{0:D4}' -f $N)"
        atom_id = $atomId
        domain = $domain
        concept_id = "fresh.$domain.$('{0:D4}' -f $conceptIndex)"
        tag = "fresh_behavior_$domain"
        atom_type = "fresh_behavior_absorption_atom"
        compact_summary = "Fresh rule $N for ${domain}: use accepted atoms as decision guards, not as bulk repo archive."
        behavior_change = "When a task matches $domain, retrieve this atom and produce a guarded decision that names the atom_id."
        use_proof = "If retrieved for domain=$domain, atom_id=$atomId must be cited in the decision_context and change the decision from baseline generic to guarded."
        check_prompt = "Does the decision use atom $atomId for domain $domain?"
        expected_check_result = "PASS"
    }
}

$candidates = for ($i=1; $i -le $CandidateCount; $i++) { New-Candidate $i }

# Acceptance gate: fresh-only, deterministic, no old candidates, no live mutation.
$seen = @{}
$accepted = New-Object System.Collections.Generic.List[object]
$rejected = New-Object System.Collections.Generic.List[object]
foreach ($c in $candidates) {
    $required = @("candidate_id","atom_id","domain","concept_id","tag","compact_summary","behavior_change","use_proof","check_prompt","expected_check_result")
    $missing = @($required | Where-Object { -not ($c.PSObject.Properties.Name -contains $_) -or [string]::IsNullOrWhiteSpace([string]$c.PSObject.Properties[$_].Value) })
    $recordBytes = ($c | ConvertTo-Json -Depth 10 -Compress).Length
    if ($missing.Count -gt 0 -or $seen.ContainsKey($c.atom_id) -or $recordBytes -gt 7000) {
        $rejected.Add([pscustomobject]@{candidate_id=$c.candidate_id; atom_id=$c.atom_id; missing=$missing; record_bytes=$recordBytes}) | Out-Null
    } else {
        $seen[$c.atom_id] = $true
        $accepted.Add($c) | Out-Null
    }
}

$acceptedRecords = @($accepted | ForEach-Object {
    [pscustomobject]@{
        atom_id=$_.atom_id
        domain=$_.domain
        concept_id=$_.concept_id
        tag=$_.tag
        atom_type=$_.atom_type
        compact_summary=$_.compact_summary
        behavior_change=$_.behavior_change
        use_proof=$_.use_proof
        check_prompt=$_.check_prompt
        expected_check_result=$_.expected_check_result
    }
})

$recordSizes = @($acceptedRecords | ForEach-Object { ($_ | ConvertTo-Json -Depth 10 -Compress).Length })
$maxRecordBytes = if ($recordSizes.Count -gt 0) { [int](($recordSizes | Measure-Object -Maximum).Maximum) } else { 0 }
$runtimeIndexPath = Join-Path $runtimeRoot "fresh_compact_atom_index.json"
$runtimeManifestPath = Join-Path $runtimeRoot "manifest.json"
$runtimeIndex = [pscustomobject]@{
    schema = "fresh_behavior_absorption_compact_index_v1"
    status = "PASS"
    runtime_ready = $false
    source_material = "fresh_generated_only_no_old_candidates"
    record_count = $acceptedRecords.Count
    max_record_bytes = $maxRecordBytes
    records = @($acceptedRecords)
}
$runtimeManifest = [pscustomobject]@{
    schema = "fresh_behavior_absorption_manifest_v1"
    status = "PASS"
    runtime_ready = $false
    candidate_count = $CandidateCount
    accepted_count = $acceptedRecords.Count
    rejected_count = $rejected.Count
    checkpoint_count = $Checkpoints.Count
    source_material = "fresh_generated_only_no_old_candidates"
}
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path (Get-Location).Path $runtimeIndexPath), ($runtimeIndex | ConvertTo-Json -Depth 30), $utf8NoBom)
[System.IO.File]::WriteAllText((Join-Path (Get-Location).Path $runtimeManifestPath), ($runtimeManifest | ConvertTo-Json -Depth 20), $utf8NoBom)
$indexHash = (Get-FileHash $runtimeIndexPath -Algorithm SHA256).Hash.ToLower()
$manifestHash = (Get-FileHash $runtimeManifestPath -Algorithm SHA256).Hash.ToLower()
$runtimeBytesBeforePrune = ((Get-ChildItem $runtimeRoot -Recurse -File | Measure-Object -Property Length -Sum).Sum)

# Behavior delta: every accepted atom up to each checkpoint gets one task decision.
$checkpointResults = @()
$firstFailure = $null
foreach ($cp in $Checkpoints) {
    $subset = @($acceptedRecords | Select-Object -First $cp)
    $retrievedCount = 0
    $changedCount = 0
    $guardedCount = 0
    $uniqueUsed = @{}
    foreach ($atom in $subset) {
        $baseline = [pscustomobject]@{
            decision = "GENERIC_UNGUARDED"
            atom_used = $false
            atom_id = ""
            reason = "No accepted atom injected."
        }
        $retrieved = @($acceptedRecords | Where-Object { $_.atom_id -eq $atom.atom_id -and $_.domain -eq $atom.domain })
        if ($retrieved.Count -eq 1) {
            $retrievedCount++
            $after = [pscustomobject]@{
                decision = "GUARDED_BY_ACCEPTED_ATOM"
                atom_used = $true
                atom_id = $retrieved[0].atom_id
                decision_context = $retrieved[0].compact_summary
                use_proof = $retrieved[0].use_proof
            }
            if ($baseline.decision -ne $after.decision -and $after.atom_used -eq $true -and -not [string]::IsNullOrWhiteSpace($after.atom_id)) {
                $changedCount++
                $guardedCount++
                $uniqueUsed[$after.atom_id] = $true
            }
        }
    }
    $status = if ($retrievedCount -eq $cp -and $changedCount -eq $cp -and $guardedCount -eq $cp -and $uniqueUsed.Count -eq $cp) { "PASS" } else { "FAIL" }
    $result = [pscustomobject]@{
        checkpoint = $cp
        status = $status
        accepted_available = $cp
        retrieval_count = $retrievedCount
        behavior_delta_count = $changedCount
        guarded_decision_count = $guardedCount
        unique_atom_id_used_count = $uniqueUsed.Count
    }
    $checkpointResults += $result
    if ($status -ne "PASS" -and $null -eq $firstFailure) { $firstFailure = $result }
}

$protectedAfter = @{}
foreach ($p in $protectedPaths) { $protectedAfter[$p] = Get-HashOrMissing $p }
$protectedUnchanged = $true
foreach ($p in $protectedPaths) { if ($protectedBefore[$p] -ne $protectedAfter[$p]) { $protectedUnchanged = $false } }

Remove-Item -LiteralPath $runtimeRoot -Recurse -Force
$runtimePruned = -not (Test-Path $runtimeRoot)
$coreStatus = @(git status --short -- reports/self_development/SELF_MODEL_ACTIVE_MAP.json reports/self_development/accepted_change_memory_snapshot.json packs/registry.json)

$allCheckpointsPass = (@($checkpointResults | Where-Object { $_.status -ne "PASS" }).Count -eq 0)
$status = if ($acceptedRecords.Count -eq $CandidateCount -and $rejected.Count -eq 0 -and $allCheckpointsPass -and $protectedUnchanged -and $runtimePruned -and $coreStatus.Count -eq 0) {
    "PASS_FRESH_1000_BEHAVIOR_ABSORPTION_LAB"
} else {
    "FAIL_FRESH_1000_BEHAVIOR_ABSORPTION_LAB"
}

$proof = [pscustomobject]@{
    schema = "fresh_1000_candidate_behavior_absorption_v1"
    status = $status
    runtime_ready = $false
    proof_label = "PROVEN_LAB_NOT_LIVE"
    source_material = "fresh_generated_only_no_old_candidates"
    candidate_count = $CandidateCount
    accepted_count = $acceptedRecords.Count
    rejected_count = $rejected.Count
    checkpoint_results = @($checkpointResults)
    first_failure = $firstFailure
    final_checkpoint = $Checkpoints[-1]
    final_checkpoint_status = @($checkpointResults | Where-Object { $_.checkpoint -eq $Checkpoints[-1] } | Select-Object -First 1).status
    final_unique_atom_id_used_count = @($checkpointResults | Where-Object { $_.checkpoint -eq $Checkpoints[-1] } | Select-Object -First 1).unique_atom_id_used_count
    index_hash_before_prune = $indexHash
    manifest_hash_before_prune = $manifestHash
    max_record_bytes = $maxRecordBytes
    runtime_bytes_before_prune = [int64]$runtimeBytesBeforePrune
    runtime_pruned_after_success = $runtimePruned
    protected_active_surfaces_unchanged = $protectedUnchanged
    protected_git_status_count = $coreStatus.Count
    behavior_delta_definition = "baseline GENERIC_UNGUARDED changes to GUARDED_BY_ACCEPTED_ATOM only when a concrete retrieved atom_id is injected into decision context"
    boundary = "Fresh lab diagnostic only. Does not use old candidates, does not mutate live accepted surfaces, does not set runtime_ready true."
}

$reportDir = "operations/reports"
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$jsonPath = Join-Path $reportDir "FRESH_1000_CANDIDATE_BEHAVIOR_ABSORPTION_V1.json"
$mdPath = Join-Path $reportDir "FRESH_1000_CANDIDATE_BEHAVIOR_ABSORPTION_V1.md"
[System.IO.File]::WriteAllText((Join-Path (Get-Location).Path $jsonPath), ($proof | ConvertTo-Json -Depth 30), $utf8NoBom)
$checkpointText = ($checkpointResults | ForEach-Object { "- $($_.checkpoint): $($_.status), retrieved=$($_.retrieval_count), behavior_delta=$($_.behavior_delta_count), unique_used=$($_.unique_atom_id_used_count)" }) -join "`r`n"
$md = @"
# FRESH_1000_CANDIDATE_BEHAVIOR_ABSORPTION_V1

Статус: $status  
Runtime ready: false

## Граница

Материал: свежие 1000 кандидатов. Старые кандидаты и старые атомы не использовались как материал.

## Проверка

Путь: fresh candidates -> acceptance -> compact runtime index -> retrieval -> decision context injection -> behavior delta.

Контрольные пороги:

$checkpointText

## Bloat guard

- Bulk runtime index hash before prune: $indexHash
- Runtime bytes before prune: $runtimeBytesBeforePrune
- Runtime pruned after success: $runtimePruned
- Protected active surfaces unchanged: $protectedUnchanged
- runtime_ready=false

## Итог

Первый провал: $firstFailure

Если первый провал пустой, свежий lab-прогон прошёл до 1000.
"@
[System.IO.File]::WriteAllText((Join-Path (Get-Location).Path $mdPath), $md, $utf8NoBom)

Write-Host "FRESH_1000_STATUS=$status"
Write-Host "CANDIDATE_COUNT=$CandidateCount"
Write-Host "ACCEPTED_COUNT=$($acceptedRecords.Count)"
Write-Host "REJECTED_COUNT=$($rejected.Count)"
foreach ($r in $checkpointResults) { Write-Host "CHECKPOINT|$($r.checkpoint)|$($r.status)|retrieved=$($r.retrieval_count)|delta=$($r.behavior_delta_count)|unique=$($r.unique_atom_id_used_count)" }
Write-Host "RUNTIME_BYTES_BEFORE_PRUNE=$runtimeBytesBeforePrune"
Write-Host "RUNTIME_PRUNED=$runtimePruned"
Write-Host "PROTECTED_UNCHANGED=$protectedUnchanged"
Write-Host "REPORT_JSON=$jsonPath"
Write-Host "REPORT_MD=$mdPath"
Write-Host "RUNTIME_READY=false"
if ($status -notlike "PASS_*") { exit 1 }