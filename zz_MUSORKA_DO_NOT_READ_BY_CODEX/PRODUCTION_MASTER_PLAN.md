# PRODUCTION MASTER PLAN v1

## Purpose

This plan upgrades E-Factory Agent Builder from a proven genesis/self-build system into a production-grade Agent Factory.

## Standing production rule

The factory is production-grade only when it can:

1. accept a rich external agent specification;
2. build a materially complete agent package;
3. validate the generated package with a reusable harness;
4. expose a direct BUILD_EXTERNAL_AGENT execution mode;
5. prove the end-to-end factory on a production-style agent specification.

---

# PHASE 8 — Production Spec Contract v1

## Goal
Replace proof-level external agent specs with a richer, reusable production contract.

## Gate
`PRODUCTION_SPEC_CONTRACT_V1_READY = PASS`

---

# PHASE 9 — Production Package Blueprint v1

## Goal
Upgrade the package generator from minimal scaffold to a materially complete starter agent repository.

## Gate
`PRODUCTION_PACKAGE_BLUEPRINT_V1_READY = PASS`

---

# PHASE 10 — Generated Agent Validation Harness v1

## Goal
Add a reusable validation harness for generated agent packages, including file checks and generated orchestrator smoke-run.

## Gate
`GENERATED_AGENT_VALIDATION_HARNESS_V1_READY = PASS`

---

# PHASE 11 — Factory BUILD_EXTERNAL_AGENT Mode v1

## Goal
Expose a direct operational mode:

`orchestrator/run.ps1 -Mode BUILD_EXTERNAL_AGENT -SpecPath ... -OutputRoot ...`

## Gate
`FACTORY_BUILD_EXTERNAL_AGENT_MODE_V1_READY = PASS`

---

# PHASE 12 — Production Factory Proof v1

## Goal
Use the factory's own production build mode to generate and validate a production-style proof agent.

## Gate
`PRODUCTION_FACTORY_PROOF_V1 = PASS`
