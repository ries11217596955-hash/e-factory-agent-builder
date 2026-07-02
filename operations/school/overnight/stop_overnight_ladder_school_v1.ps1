param([string]$RunId="")
$ErrorActionPreference="Stop"
$repoRoot=(git rev-parse --show-toplevel).Trim(); Set-Location $repoRoot
if([string]::IsNullOrWhiteSpace($RunId)){$dirs=Get-ChildItem .runtime/overnight_ladder_school -Directory -ErrorAction SilentlyContinue|Sort-Object LastWriteTime -Descending; if($dirs.Count -eq 0){throw "NO_OVERNIGHT_RUNS"}; $RunId=$dirs[0].Name}
$launcher=".runtime/overnight_ladder_school/$RunId/launcher.json"
if(-not(Test-Path $launcher)){throw "LAUNCHER_MISSING"}
$l=Get-Content $launcher -Raw|ConvertFrom-Json
$p=Get-Process -Id $l.pid -ErrorAction SilentlyContinue
if($p){Stop-Process -Id $l.pid -Force; Write-Host "STOPPED_RUN_ID=$RunId PID=$($l.pid)"} else {Write-Host "NOT_RUNNING_RUN_ID=$RunId PID=$($l.pid)"}