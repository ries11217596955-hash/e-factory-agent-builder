# AGENTS.md

## Purpose

Execution discipline for work inside `e-factory-agent-builder`.

## Product target

Build a self-constructing Agent Builder that:

1. first builds its own verified operating contour;
2. then builds other agents from formal specs.

## Active modes

- `SELF_BUILD`
- `BUILD_EXTERNAL_AGENT`
- `VERIFY`

## Architecture law

- orchestrator owns flow only;
- modules own logic;
- contracts define accepted data;
- validators define PASS / FAIL;
- state files must not claim completion without validation evidence;
- chat is not source of truth;
- repo-defined plan is source of truth.

## Serial execution law

Do not drip-feed routine micro-steps.

When task scope is defined in repo truth:
1. read the plan;
2. read current state;
3. execute the next bounded tranche;
4. validate;
5. update state and queue only after evidence;
6. continue until hard stop.

## Hard stops

STOP if:
- plan does not define the next step;
- validator fails and root cause is unclear;
- a task would cross declared scope;
- external-agent-build is attempted before self-build readiness;
- state, roadmap, and queue contradict each other.

## Forbidden drift

- no giant prompt as SSOT;
- no chaotic self-modification;
- no external agent generation before `SELF_BUILD_READY = PASS`;
- no fake PASS without validator evidence;
- no collapsing this repo back into Site Auditor.
