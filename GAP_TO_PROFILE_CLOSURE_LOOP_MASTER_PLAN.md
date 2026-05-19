# GAP-TO-PROFILE CLOSURE LOOP v1

## Purpose

Upgrade Agent Builder from:

unsupported raw idea
→ gap diagnostic artifact

to:

unsupported raw idea
→ gap diagnostic artifact
→ specialization profile candidate brief
→ new registered specialization profile
→ rerun same idea
→ specialized agent build succeeds.

---

# PHASE 30 — Gap-to-Profile Candidate Brief v1

## Goal
Create a reusable candidate brief artifact from a real specialization gap report.

Proof candidate:
- missing kind: `decision_support_agent`
- proposed profile: `decision_support_agent_v1`

## Gate
`GAP_TO_PROFILE_CANDIDATE_BRIEF_V1_READY = PASS`

---

# PHASE 31 — Decision Support Agent Specialization Profile v1

## Goal
Add the first gap-driven specialization profile:

- `decision_support_agent` → `decision_support_agent_v1`

Prove:
- registry mapping exists;
- overlay applies;
- generated runtime emits specialized decision-support behavior.

## Gate
`DECISION_SUPPORT_AGENT_SPECIALIZATION_PROFILE_V1_READY = PASS`

---

# PHASE 32 — Gap Closure Specialized Factory Proof v1

## Goal
Rerun the same previously unsupported raw idea family and prove:

- prior route = `SPECIALIZATION_GAP`;
- new route = `PASS`;
- selected profile = `decision_support_agent_v1`;
- target generated agent emits specialized runtime operation.

## Gate
`GAP_CLOSURE_SPECIALIZED_FACTORY_PROOF_V1 = PASS`
