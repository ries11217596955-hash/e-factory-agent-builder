# GPT Settings Knowledge Mirror

Назначение: зеркало файлов, которые загружаются в настройки Custom GPT как Knowledge.

## Что это такое

Этот каталог — не runtime-память Builder и не рабочие органы Agent Builder.

Это отдельная зона рядом с Builder, чтобы хранить актуальный комплект файлов из настроек нашего GPT и быстро собирать ZIP для ручной загрузки в GPT Knowledge.

## Главная папка

```text
_gpt_settings_knowledge/active/
```

Именно здесь лежат текущие файлы, которые должны попасть в GPT Knowledge.

## Как Owner собирает ZIP для настроек GPT

Из корня repo выполнить:

```powershell
powershell -ExecutionPolicy Bypass -File .\_gpt_settings_knowledge\EXPORT_FOR_GPT_SETTINGS.ps1
```

По умолчанию готовый архив появится на рабочем столе:

```text
Desktop/GPT_KNOWLEDGE_SETTINGS_EXPORT_yyyyMMdd_HHmmss.zip
```

Если рабочий стол недоступен, архив будет создан в:

```text
_gpt_settings_knowledge/exports/
```

Можно указать свою папку:

```powershell
powershell -ExecutionPolicy Bypass -File .\_gpt_settings_knowledge\EXPORT_FOR_GPT_SETTINGS.ps1 -OutputDirectory "C:\Temp"
```

## Важно

Скрипт `EXPORT_FOR_GPT_SETTINGS.ps1`:

- собирает ZIP из `_gpt_settings_knowledge/active/`;
- исключает файлы с `__CONFLICT_FROM_UPLOAD_`;
- печатает путь к готовому ZIP, количество файлов и SHA256;
- НЕ открывает ChatGPT;
- НЕ меняет настройки GPT автоматически;
- НЕ нажимает Update.

После сборки Owner вручную загружает ZIP/файлы в GPT Builder → Knowledge → Update.

## Правило работы

Когда Owner говорит “обнови GPT settings files”:

1. Агент обновляет файлы в `_gpt_settings_knowledge/active/`.
2. Агент обновляет manifest/changelog при необходимости.
3. Owner делает `git pull`.
4. Owner запускает `EXPORT_FOR_GPT_SETTINGS.ps1`.
5. Owner загружает созданный ZIP/файлы в GPT settings.

## Конфликты

Если после нормализации имён найдено два разных файла с одинаковым именем, конфликтный файл сохраняется как:

```text
__CONFLICT_FROM_UPLOAD_<hash>
```

Такие файлы не попадают в export ZIP по умолчанию.

## Происхождение

Создано из архива: `_INBOX (1).zip`

Первая сборка mirror: 2026-06-04T10:48:33Z  
Обновление export-скрипта: 2026-06-04 — ZIP теперь создаётся на Desktop по умолчанию.
