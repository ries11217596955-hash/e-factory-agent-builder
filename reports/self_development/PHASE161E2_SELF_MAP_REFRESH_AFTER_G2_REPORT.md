# PHASE161E2 Self-Map Refresh After G2 Report

Validation result: `PASS`

Accepted subject head: `0c4a454c6fd78507a94f0a30bf80f1265e24e1c6`

Accepted phase: `PHASE161G2_APPLY_LIMITED_PROTECTED_SELF_MODEL_REFERENCES`

Map refresh status: `SELF_KNOWLEDGE_READY`

The existing PHASE161E refresh regenerated the derived body map after the accepted G2 protected-reference commit.

- Self knowledge ready: `True`
- Map ready for next decision: `True`
- Active wired proven: `196`
- Present not wired: `272`
- Historical reference only: `204`
- Superseded: `1`
- Real stubs: `2`
- False-positive stubs: `76`
- Gap chains: `7`

The refreshed derived memory references:

- `GENESIS_STATE.json.protected_self_model_memory`
- `CAPABILITY_ROADMAP.json.phase161e_self_map_auto_refresh`

The evidence boundary remains derived/cautious. Validator-only evidence was not promoted to live evidence. The refresh created no further protected-state diff.
