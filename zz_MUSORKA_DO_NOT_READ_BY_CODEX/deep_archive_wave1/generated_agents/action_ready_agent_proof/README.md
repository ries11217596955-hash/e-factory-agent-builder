# Action Ready Agent Proof

## Mission
Prove that generated external agents now include a GitHub Actions launch delivery artifact while preserving operational RUN validation.

## Agent ID
action_ready_agent_proof

## Package Profile
operational_action_ready

## Runtime
orchestrator/run.ps1 -Mode RUN -InputPath <request.json> -OutputPath <result.json>

## GitHub Actions launch surface
Delivery artifact:
deployment/github_actions/run-generated-agent.workflow.yml

When this agent package becomes its own repository, place the workflow at:
.github/workflows/run-generated-agent.yml

This creates a manual Run workflow button in GitHub Actions.
