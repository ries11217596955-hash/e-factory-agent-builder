# Runbook Executor Agent v1

## Что это за агент

Runbook Executor Agent v1 - второй внешний агент, произведённый Builder из программы-заказа. Он принимает runbook, описание задачи или инцидента и превращает их в операторский план действий.

## Зачем он создан

Агент нужен, чтобы оператор мог быстрее перейти от инструкции к конкретному безопасному плану выполнения: чеклисту, рискам, доказательствам и следующему шагу.

## Что принимает

Агент принимает JSON-файл с обязательными полями:

- `runbook_title`
- `runbook_steps`
- `task_or_incident`
- `environment`
- `constraints`

## Что выдаёт

Агент создаёт JSON-результат:

- `execution_checklist`
- `risk_flags`
- `required_evidence`
- `next_operator_action`
- `validation_status`

При успешной локальной проверке `validation_status` равен `PASS`.

## Где лежит

```text
generated_agents/runbook_executor_agent_v1/
```

Точка запуска:

```text
generated_agents/runbook_executor_agent_v1/run.ps1
```

## Как запустить локально

Из корня репозитория:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File generated_agents/runbook_executor_agent_v1/run.ps1 -InputPath generated_agents/runbook_executor_agent_v1/INPUT_EXAMPLE.json -OutputPath generated_agents/runbook_executor_agent_v1/OUTPUT_EXAMPLE_RUNTIME.json
```

## GitHub-кнопка

GitHub-кнопка для этого агента ещё не создана. Workflow `.github/workflows/run-runbook-executor-agent-v1.yml` должен быть добавлен отдельным следующим этапом.

## Какие доказательства есть

Программа и план производства:

```text
proofs/RUNBOOK_EXECUTOR_AGENT_PROGRAM_TRIAL_V1.json
reports/external_agent_production/RUNBOOK_EXECUTOR_AGENT_PROGRAM_TRIAL_V1_REPORT.json
```

Локальное производство агента:

```text
proofs/RUNBOOK_EXECUTOR_AGENT_PRODUCTION_V1.json
reports/external_agent_production/RUNBOOK_EXECUTOR_AGENT_PRODUCTION_V1_REPORT.json
```

## Текущий статус

Статус агента: `PRODUCED_LOCAL_PENDING_GITHUB_ACTION`.

Локальная validation: `PASS`.

GitHub Action validation: `PENDING`.

## Следующий шаг

Добавить GitHub Actions запуск для Runbook Executor Agent v1.
