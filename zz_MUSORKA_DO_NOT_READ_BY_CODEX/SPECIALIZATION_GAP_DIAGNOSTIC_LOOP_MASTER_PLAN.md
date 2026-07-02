# SPECIALIZATION GAP DIAGNOSTIC LOOP v1

## Purpose

Upgrade Agent Builder from:

raw idea
→ specialization lookup
→ if no profile: fatal error

to:

raw idea
→ specialization lookup
→ if no profile: structured specialization gap artifact.

---

# PHASE 27 — Specialization Gap Contract v1

## Goal
Create a reusable contract and writer module for missing specialization profiles.

Gap artifact must capture:
- raw idea path;
- derived spec path;
- derived agent id;
- missing agent kind;
- requested package profile;
- resolver status/reason;
- required next move.

## Gate
`SPECIALIZATION_GAP_CONTRACT_V1_READY = PASS`

---

# PHASE 28 — No-Match Diagnostic Mode v1

## Goal
Modify:

`BUILD_FROM_RAW_IDEA_SPECIALIZED`

so that `NO_MATCH` no longer throws.

Instead it must:
- write `SPECIALIZATION_GAP_REPORT.json`;
- write `BUILD_FROM_RAW_IDEA_SPECIALIZED_REPORT.json` with status `SPECIALIZATION_GAP`;
- return controlled diagnostic output.

## Gate
`NO_MATCH_DIAGNOSTIC_MODE_V1_READY = PASS`

---

# PHASE 29 — Missing Profile Factory Proof v1

## Goal
Prove end-to-end that an unsupported raw idea family:
- becomes a derived spec;
- fails specialization resolution cleanly;
- emits a gap report;
- does not crash the factory route.

## Gate
`MISSING_PROFILE_FACTORY_PROOF_V1 = PASS`
