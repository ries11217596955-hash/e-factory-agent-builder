$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Active = Join-Path $ScriptRoot "active"
$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$Temp = Join-Path ([IO.Path]::GetTempPath()) "gpt_knowledge_export_$Stamp"
$Desktop = [Environment]::GetFolderPath("Desktop")
$Zip = Join-Path $Desktop "GPT_KNOWLEDGE_SETTINGS_EXPORT_$Stamp.zip"

$Continue = $true

Write-Host "GPT_SETTINGS_EXPORT_START"
Write-Host "ACTIVE=$Active"
Write-Host "ZIP=$Zip"

if (!(Test-Path $Active)) {
  Write-Host "STOP=ACTIVE_FOLDER_NOT_FOUND"
  $Continue = $false
}

if ($Continue) {
  if (Test-Path $Temp) { Remove-Item $Temp -Recurse -Force }
  New-Item -ItemType Directory -Path $Temp -Force | Out-Null

  $Files = Get-ChildItem $Active -File | Where-Object {
    $_.Name -notlike "*__CONFLICT_FROM_UPLOAD_*"
  }

  foreach ($File in $Files) {
    Copy-Item $File.FullName -Destination $Temp -Force
  }

  $Count = (Get-ChildItem $Temp -File).Count

  if ($Count -eq 0) {
    Write-Host "STOP=NO_FILES_TO_EXPORT"
    $Continue = $false
  }
}

if ($Continue) {
  if (Test-Path $Zip) { Remove-Item $Zip -Force }

  Compress-Archive -Path (Join-Path $Temp "*") -DestinationPath $Zip -Force

  $Hash = Get-FileHash $Zip -Algorithm SHA256

  Write-Host "DONE=GPT_KNOWLEDGE_ZIP_CREATED"
  Write-Host "ZIP=$Zip"
  Write-Host "FILES=$Count"
  Write-Host "SHA256=$($Hash.Hash)"
}
