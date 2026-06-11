# PHASE165S-C5B Validate Existing Dispatcher Contract

Status: PASS_EXISTING_DISPATCHER_CONTRACT_VALIDATED

## Corrected Harness

Previous failed smoke-test was invalid because:

- dispatcher requires -EmitJson;
- dispatcher normal mode is SELF_MODE;
- classifier is a function interface, not a direct -MessageType CLI.

## Checks

- no_school_learning_mode: SELF_MODE
- no_school_returns_self_mode: True
- curriculum_learning_mode: SCHOOL_MODE
- curriculum_input_routes_school: True
- classifier_route_decision: ROUTE_CURRICULUM_PACK
- classifier_route_target: SCHOOL_MODE
- classifier_curriculum_routes_school_mode: True
- protected_state_dirty_check: 0

## Route Decision

REUSE_EXISTING_DISPATCHER_NOT_REBUILD

## Next

PHASE165S_C5B_ACCEPTANCE_COMMIT
