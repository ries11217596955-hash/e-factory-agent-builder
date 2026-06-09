# GAP REMEDIATION INTAKE RUNTIME v1

## Purpose

Promote the proven SP-N7 logic from a proof-pack path into a permanent Builder runtime path.

Current proven chain:
gap report
→ profile candidate brief

Target runtime chain:
orchestrator mode GAP_TO_PROFILE_CANDIDATE
→ specialization profile candidate artifact
→ intake report artifact

---

# PHASE 33 — Gap Remediation Intake Mode v1

## Goal
Add a first-class orchestrator mode:

`GAP_TO_PROFILE_CANDIDATE`

Input:
- `GapReportPath`
- optional `CandidateOutputPath`

Output:
- specialization profile candidate brief

## Gate
`GAP_REMEDIATION_INTAKE_MODE_V1_READY = PASS`

---

# PHASE 34 — Candidate Intake Report Contract v1

## Goal
Create a formal runtime report artifact:

`GAP_REMEDIATION_INTAKE_REPORT.json`

Required fields:
- source gap report;
- candidate path;
- candidate profile id;
- candidate agent kind;
- required build move;
- status.

## Gate
`CANDIDATE_INTAKE_REPORT_CONTRACT_V1_READY = PASS`

---

# PHASE 35 — Runtime Gap-to-Candidate Factory Proof v1

## Goal
Prove end-to-end that Builder runtime can:
- reproduce a specialization gap;
- invoke `GAP_TO_PROFILE_CANDIDATE`;
- emit candidate brief;
- emit intake report;
- preserve exact missing family semantics.

## Gate
`RUNTIME_GAP_TO_CANDIDATE_FACTORY_PROOF_V1 = PASS`
