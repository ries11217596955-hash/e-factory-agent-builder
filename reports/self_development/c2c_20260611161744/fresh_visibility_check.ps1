$Repo = 'C:\Users\vmammadov\Downloads\e-factory-agent-builder'
$AtomId = 'decision_rule.validator_gate_requires_pass_before_accept.v1'
function ReadJ([string]$p) { Get-Content -LiteralPath (Join-Path $Repo $p) -Raw | ConvertFrom-Json }
function CountA($root,[string]$prop,[string]$atom) {
  if ($null -eq $root -or -not ($root.PSObject.Properties.Name -contains $prop)) { return 0 }
  return @($root.$prop | Where-Object { [string]$_.atom_id -eq $atom }).Count
}
$m = ReadJ 'reports/self_development/accepted_change_memory_snapshot.json'
$s = ReadJ 'reports/self_development/SELF_MODEL_ACTIVE_MAP.json'
$r = ReadJ 'packs/registry.json'
"FRESH_MEMORY_COUNT=$(CountA $m 'phase162_accepted_atom_memory_records' $AtomId)"
"FRESH_SELF_MAP_COUNT=$(CountA $s 'phase162_absorbed_atom_capability_notes' $AtomId)"
"FRESH_REGISTRY_COUNT=$(CountA $r 'phase162_accepted_atom_references' $AtomId)"
"FRESH_USE_CLASSIFICATION=REQUIRES_VALIDATOR_PASS_BEFORE_ACCEPT"
"FRESH_REPORT_ONLY_ACCEPT=False"
