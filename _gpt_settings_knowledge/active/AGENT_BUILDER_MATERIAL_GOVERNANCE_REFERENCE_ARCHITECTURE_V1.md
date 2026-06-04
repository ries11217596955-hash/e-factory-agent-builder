# AGENT_BUILDER_MATERIAL_GOVERNANCE_REFERENCE_ARCHITECTURE_V1.md

## Document Status

**File type:** GPT Knowledge / Reference Architecture  
**Status:** REFERENCE_ARCHITECTURE  
**Version:** 2026-06-01-R2  
**Replacement rule:** New additive reference file. It does not replace the route lock.

---

## 1. Purpose

This document captures the target architecture for Agent Builder material governance.

It is not the active execution route.
The active route is `AGENT_BUILDER_NEXT_15_STEPS_LOCK_V1.md`.

This file guides Steps 3–11 of the route.

---

## 2. Main Principle

First governance.
Then agentness.

External materials are food/tools/references, not Builder's core brain.
No LLM, local model, framework, public repository, or template should be treated as Builder's identity.

Builder must safely acquire, classify, quarantine, test, wrap, and prove materials before using them to build external agents.

---

## 3. Target Architecture

Self-Knowledge  
→ Material Acquisition Bootstrap  
→ Manual Scout Pass  
→ Material Catalog  
→ Material Admission Policy  
→ Quarantine  
→ Operation Contracts  
→ Tool Smoke Tests  
→ Operation Runtime  
→ Self-Development Decision Kernel  
→ Self-Build Program Generator  
→ Program Admission  
→ Builder executes own self-build program  
→ External agent readiness gate  
→ External agent production

---

## 4. Candidate Material Stack

### Schema validation
- Ajv
- Python `jsonschema`

### Template generation
- Copier
- Cookiecutter as reference/alternative
- Yeoman as reference only

### SBOM / vulnerability
- Syft
- Grype
- Trivy
- OSV-Scanner

### License / compliance
- Licensee
- ScanCode Toolkit as deep mode
- ORT as later/deep mode

### Policy
- simple JSON policy evaluator first;
- OPA/Conftest as stronger policy layer after bootstrap.

### Task / workflow
- go-task;
- GitHub Actions;
- Docker Official Images as controlled base references.

### Reference/security signals
- OpenSSF Scorecard;
- deps.dev;
- SPDX references.

### LLM/multi-agent frameworks
- LangGraph;
- CrewAI;
- AutoGen;
- OpenHands;
- Semantic Kernel;
- Ruflo.

Status for these:
`REFERENCE_ONLY` until Builder proves material governance and operation runtime.

---

## 5. Usage Modes

Every material must be classified as:

- `USE_AS_TOOL`
- `WRAP_ONLY`
- `COPY_WITH_ATTRIBUTION`
- `ADAPT`
- `REIMPLEMENT`
- `REFERENCE_ONLY`
- `ASK_PERMISSION`
- `REJECT`

---

## 6. Material Statuses

- `DISCOVERED`
- `CANDIDATE`
- `QUARANTINED`
- `WRAPPED`
- `TESTED`
- `TRUSTED`
- `REJECTED`
- `REFERENCE_ONLY`
- `OWNER_APPROVAL_REQUIRED`

No material starts as `TRUSTED`.

---

## 7. Source Priority

Use sources in this order:

1. official documentation;
2. official repository;
3. package registry metadata;
4. release artifacts;
5. license file;
6. security advisories;
7. OpenSSF Scorecard/deps.dev;
8. reputable examples;
9. blogs/tutorials only as learning references.

Avoid:
- torrents;
- unknown file dumps;
- cracked archives;
- unclear mirrors;
- no provenance sources.

---

## 8. Quarantine Rule

External material may be placed in:
- `materials/inbox/`
- `materials/quarantine/`
- `materials/reference_only/`

It must not enter:
- trusted registry;
- operation runtime;
- external agent production;

until it has:
- source;
- license/risk;
- policy decision;
- test/smoke plan;
- proof/report;
- Owner approval if needed.

---

## 9. First Practical Batch

Do not install 50 tools at once.

First controlled trial batch:
- Ajv or jsonschema;
- Copier;
- OSV-Scanner or Syft;
- simple policy evaluator or Conftest.

Each must have:
- version;
- source;
- license note;
- install method;
- smoke command;
- rollback note;
- proof/report.

---

## 10. Relation To Route Lock

This file is a reference.

If it conflicts with the active route lock:
- follow the route lock;
- or create `ROUTE_CHANGE_REQUEST`.

