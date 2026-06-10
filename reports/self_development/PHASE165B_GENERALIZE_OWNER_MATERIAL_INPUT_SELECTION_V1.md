# PHASE165B GENERALIZE OWNER MATERIAL INPUT SELECTION V1

## Purpose

Replace single active owner-material input dependency with a governed selection layer from inbox/queue.

## Result

Selector reads READY owner-material candidates from inbox, selects by priority, and emits selected owner-material input.

## Validation

- selected_material_id: OWNER_MATERIAL_INPUT_BOOTSTRAP_001
- selected_source_file: OWNER_MATERIAL_INPUT_BOOTSTRAP_001.json
- candidate_count: 1
- not_atom: True
- required_path: PHASE87->PHASE88->PHASE89->PHASE90
- ACTIVE_OWNER_MATERIAL_INPUT.json overwritten: False

## Safety

- protected state mutated: False
- route lock mutated: False
- Codex used: False
- external fetch/install: False

## Created Artifacts

- self_build_batch/owner_material_inputs/SELECT_OWNER_MATERIAL_INPUT_V1.ps1
- self_build_batch/owner_material_inputs/inbox/OWNER_MATERIAL_INPUT_BOOTSTRAP_001.json
- self_build_batch/owner_material_inputs/selected/SELECTED_OWNER_MATERIAL_INPUT.json
- reports/self_development/PHASE165B_GENERALIZE_OWNER_MATERIAL_INPUT_SELECTION_V1.md
- proofs/self_development/PHASE165B_GENERALIZE_OWNER_MATERIAL_INPUT_SELECTION_V1.json

## Boundary

This does not connect selector output to canonical PHASE87 yet.
That belongs to later route work.

## Next Locked Step

PHASE165C_DYNAMIC_SELF_BUILD_PROGRAM_ID_CONTRACT
