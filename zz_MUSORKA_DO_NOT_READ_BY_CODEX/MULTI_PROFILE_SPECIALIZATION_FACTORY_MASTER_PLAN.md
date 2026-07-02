# MULTI-PROFILE SPECIALIZATION FACTORY v1

## Purpose

Upgrade Agent Builder from:

raw idea
→ one bounded specialization profile
→ one specialized agent

to:

raw idea
→ registry-backed specialization resolver
→ multiple bounded specialization profiles
→ multiple specialized agent families.

---

# PHASE 24 — Specialization Profile Registry v1

## Goal
Replace one-off resolver hardcoding with a registry-backed specialization lookup.

Initial registry:
- `audit_agent` → `audit_agent_v1`

## Gate
`SPECIALIZATION_PROFILE_REGISTRY_V1_READY = PASS`

---

# PHASE 25 — Specification Agent Profile v1

## Goal
Add a second specialization profile:
- `specification_agent` → `specification_agent_v1`

Prove that:
- registry resolves the profile;
- external agent build applies the overlay;
- generated runtime emits specialized specification behavior.

## Gate
`SPECIFICATION_AGENT_SPECIALIZATION_PROFILE_V1_READY = PASS`

---

# PHASE 26 — Multi-Profile Specialized Factory Proof v1

## Goal
Prove end-to-end routing for two raw idea families:
- audit raw idea → audit_agent_v1;
- specification raw idea → specification_agent_v1.

## Gate
`MULTI_PROFILE_SPECIALIZED_FACTORY_PROOF_V1 = PASS`
