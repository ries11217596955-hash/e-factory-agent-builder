[CmdletBinding()]
param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
)

$ErrorActionPreference = "Stop"
throw "PHASE108_CANDIDATE_NOT_ADMITTED_FOR_EXECUTION"
