$ErrorActionPreference = 'Stop'

$Root = (git rev-parse --show-toplevel).Trim()
Set-Location $Root

$ModulePath = Join-Path $Root 'modules/invoke_useful_school_30k_with_comprehension_and_delta_v1.ps1'
$ProofPath = Join-Path $Root 'tests/accepted_atom_retention/USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_V1_PROOF.json'
$ValidatorPath = Join-Path $Root 'validators/validate_useful_school_30k_with_comprehension_and_delta_v1_proof.ps1'

. $ModulePath

$Proof = Invoke-UsefulSchool30KWithComprehensionAndDeltaV1
$Proof | ConvertTo-Json -Depth 60 | Set-Content -LiteralPath $ProofPath -Encoding UTF8

& $ValidatorPath -ProofPath $ProofPath

Write-Host 'USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_STATUS=PASS'
Write-Host 'VALIDATION_PASS=USEFUL_SCHOOL_30K_WITH_COMPREHENSION_AND_DELTA_V1_PROVEN'
Write-Host 'RUNTIME_READY=false'
