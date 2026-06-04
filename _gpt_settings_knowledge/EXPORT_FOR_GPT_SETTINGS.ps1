$ErrorActionPreference = "Stop"

<#
EXPORT_FOR_GPT_SETTINGS.ps1

Назначение:
- Собирает актуальные файлы из _gpt_settings_knowledge/active в ZIP для ручной загрузки в GPT Knowledge.
- По умолчанию кладёт ZIP на рабочий стол текущего пользователя.
- НЕ открывает ChatGPT, НЕ меняет настройки GPT автоматически, НЕ нажимает Update.

Запуск из корня repo:
powershell -ExecutionPolicy Bypass -File .\_gpt_settings_knowledge\EXPORT_FOR_GPT_SETTINGS.ps1

Опционально можно указать свою папку:
powershell -ExecutionPolicy Bypass -File .\_gpt_settings_knowledge\EXPORT_FOR_GPT_SETTINGS.ps1 -OutputDirectory "C:\Temp"
#>

param(
  [string]$OutputDirectory = ""
)

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Active = Join-Path $Root "active"

if (-not (Test-Path $Active)) {
  throw "ACTIVE_FOLDER_NOT_FOUND=$Active"
}

# Desktop по умолчанию. Если Desktop не найден, используем папку exports рядом с mirror.
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
  $Desktop = [Environment]::GetFolderPath("Desktop")
  if (-not [string]::IsNullOrWhiteSpace($Desktop) -and (Test-Path $Desktop)) {
    $OutputDirectory = $Desktop
  } else {
    $OutputDirectory = Join-Path $Root "exports"
  }
}

if (-not (Test-Path $OutputDirectory)) {
  New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$Out = Join-Path $OutputDirectory ("GPT_KNOWLEDGE_SETTINGS_EXPORT_" + $Stamp + ".zip")

# Берём только обычные файлы из active. Конфликтные загрузочные дубли не экспортируем.
$Files = Get-ChildItem -Path $Active -File | Where-Object {
  $_.Name -notlike "*__CONFLICT_FROM_UPLOAD_*"
} | Sort-Object Name

if ($Files.Count -eq 0) {
  throw "NO_EXPORTABLE_FILES_FOUND=$Active"
}

if (Test-Path $Out) {
  Remove-Item $Out -Force
}

Compress-Archive -Path ($Files.FullName) -DestinationPath $Out -Force

$Hash = (Get-FileHash -Algorithm SHA256 $Out).Hash

Write-Host "GPT_SETTINGS_EXPORT_READY=true"
Write-Host "DOES_NOT_UPDATE_GPT_SETTINGS_AUTOMATICALLY=true"
Write-Host ("SOURCE_ACTIVE_FOLDER=" + $Active)
Write-Host ("UPLOAD_THIS_ZIP=" + $Out)
Write-Host ("FILE_COUNT=" + $Files.Count)
Write-Host ("SHA256=" + $Hash)
Write-Host "NEXT_ACTION=Open GPT Builder settings, replace Knowledge files manually with this ZIP/files, then press Update."
