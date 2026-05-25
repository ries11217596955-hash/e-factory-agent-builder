# План выполнения программы производства агента

## Какую программу Builder прочитал

Builder прочитал программу:

`	ext
agent_programs/remediation_intake_operator_agent_v1/PROGRAM.json
`

## Какого агента она описывает

Программа описывает агента $(@{program_id=PROGRAM_REMEDIATION_INTAKE_OPERATOR_AGENT_V1; agent_id=remediation_intake_operator_agent_v1; agent_name=Remediation Intake Operator Agent v1; purpose=принимает описание проблемы и превращает его в структурированную карточку для оператора; owner_visible_goal=Оператор получает нормализованную карточку проблемы с severity, likely_area, missing_information и recommended_next_step.; input_contract=; output_contract=; required_files=System.Object[]; validation_requirements=System.Object[]; github_action_required=True; github_action_name=Run Remediation Intake Operator Agent v1; github_workflow=.github/workflows/run-remediation-intake-operator-agent-v1.yml; artifact_name=remediation-intake-operator-agent-v1-output; agent_location=generated_agents/remediation_intake_operator_agent_v1/; run_script=generated_agents/remediation_intake_operator_agent_v1/run.ps1; proof_paths=System.Object[]; report_paths=System.Object[]; acceptance_criteria=System.Object[]; forbidden_scope=System.Object[]}.agent_id) - Remediation Intake Operator Agent v1.

Назначение агента:

`	ext
принимает описание проблемы и превращает его в структурированную карточку для оператора
`

Цель для владельца:

`	ext
Оператор получает нормализованную карточку проблемы с severity, likely_area, missing_information и recommended_next_step.
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

Проверки взяты из alidation_requirements программы:

`	ext
agent package required files exist
run.ps1 passes PowerShell parser check
INPUT_EXAMPLE.json produces OUTPUT_EXAMPLE_RUNTIME.json
runtime output contains validation_status PASS
GitHub Actions workflow can run manually and upload expected artifact
agent is registered in agent_catalog/AGENT_CATALOG.json
`

## Какой GitHub Action нужен

`	ext
Run Remediation Intake Operator Agent v1
`

GitHub Action обязателен:

`	ext
True
`

## Какой artifact ожидается

`	ext
remediation-intake-operator-agent-v1-output
`

## Что это доказывает

Это доказывает, что Builder может прочитать PROGRAM.json, извлечь обязательные поля программы производства агента и подготовить структурированный план выполнения без создания нового агента.
