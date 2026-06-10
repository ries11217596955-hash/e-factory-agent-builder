# PHASE165E PATCH DECISION KERNEL FOR DYNAMIC GAP SELECTION V1

## Purpose

Move PHASE87 from hardcoded PHASE88 recommendation toward evidence-backed next gap selection.

## Repair

Initial selector checked lineage selected_material_id at root.
PHASE165D lineage stores owner material under owner_material.selected_material_id.

## Dynamic Decision

- selected_next_step: PHASE165F_PATCH_PROGRAM_GENERATOR_FOR_DYNAMIC_SELF_BUILD_PROGRAMS
- selected_material_id: OWNER_MATERIAL_INPUT_BOOTSTRAP_001
- source_material_id: OWNER_MATERIAL_INPUT_BOOTSTRAP_001
- lineage_owner_material_id: OWNER_MATERIAL_INPUT_BOOTSTRAP_001
- program_id: SELF_BUILD_PROGRAM_OWNER_MATERIAL_INPUT_BOOTSTRAP_001_V1_001
- lineage_id: LINEAGE_SELF_BUILD_PROGRAM_OWNER_MATERIAL_INPUT_BOOTSTRAP_001_V1_001
- evidence_ready: True
- lineage_material_match: True
- hardcoded_phase88_recommendation: False

## Boundary

This step does not execute PHASE88, PHASE89 or PHASE90.
This step does not execute a self-build program.
This step does not mutate protected state.
This step does not change the route lock.

## Next Locked Step

PHASE165F_PATCH_PROGRAM_GENERATOR_FOR_DYNAMIC_SELF_BUILD_PROGRAMS
