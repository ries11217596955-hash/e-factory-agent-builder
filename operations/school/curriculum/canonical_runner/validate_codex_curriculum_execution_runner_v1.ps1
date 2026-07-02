$ErrorActionPreference="Stop"
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
$runner='operations/school/curriculum/canonical_runner/execute_codex_curriculum_canonical_run_v1.ps1'
$ok=(Test-Path $runner)
$status=if($ok){'PASS_CODEX_CURRICULUM_EXECUTION_RUNNER_EXISTS_V1'}else{'FAIL_CODEX_CURRICULUM_EXECUTION_RUNNER_EXISTS_V1'}
$report=[pscustomobject]@{schema='codex_curriculum_execution_runner_validator_v1'; status=$status; runtime_ready=$false; runner_path=$runner; boundary='Checks executor presence only. Full proof requires running TargetAccepted/RunKind.'}
$utf8=New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path (Get-Location).Path 'operations/reports/CODEX_CURRICULUM_EXECUTION_RUNNER_V1_VALIDATION.json'),($report|ConvertTo-Json -Depth 20),$utf8)
Write-Host "VALIDATION_STATUS=$status"
if($status -notlike 'PASS_*'){exit 1}