# План производства Runbook Executor Agent v1

## Какую программу Builder прочитал

Builder прочитал программу:

`	ext
agent_programs/runbook_executor_agent_v1/PROGRAM.json
`

## Какого агента она описывает

Программа описывает агента $(@{program_id=RUNBOOK_EXECUTOR_AGENT_PROGRAM_V1; agent_id=runbook_executor_agent_v1; agent_name=Runbook Executor Agent v1; purpose=превращает runbook и задачу в операторский план действий; owner_visible_goal=владелец может подать инструкцию и получить чеклист, риски, доказательства и следующий шаг; input_contract=; output_contract=; required_files=System.Object[]; validation_requirements=System.Object[]; github_action_required=True; github_action_name=Run Runbook Executor Agent v1; artifact_name=runbook-executor-agent-v1-output; acceptance_criteria=System.Object[]; forbidden_scope=System.Object[]}.agent_id) - Runbook Executor Agent v1.

Назначение агента:

`	ext
превращает runbook и задачу в операторский план действий
`

Цель для владельца:

`	ext
владелец может подать инструкцию и получить чеклист, риски, доказательства и следующий шаг
`

## Какие шаги производства нужны

План производства:

1. create_agent_folder
2. create_agent_spec
3. create_readme
4. create_runbook
5. create_input_example
6. create_output_example
7. create_run_script
8. alidate_local_runtime
9. create_github_action
10. alidate_github_artifact
11. egister_agent_catalog

## Какие проверки нужны

Проверки из программы:

`	ext
required files present
JSON examples valid
run.ps1 parser check passes
runtime output contains checklist, risks, evidence, next action
validation_status is PASS
`

## Какой GitHub Action нужен

`	ext
Run Runbook Executor Agent v1
`

GitHub Action обязателен:

`	ext
True
`

## Какой artifact ожидается

`	ext
runbook-executor-agent-v1-output
`

## Что это доказывает

Это доказывает, что Builder может прочитать новую программу внешнего агента и подготовить production plan без создания самого агента, пакета агента или GitHub workflow.
