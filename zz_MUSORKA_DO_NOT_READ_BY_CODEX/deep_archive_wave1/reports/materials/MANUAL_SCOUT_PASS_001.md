# MANUAL_SCOUT_PASS_001

Status: CREATED_BY_GPT_MANUAL_SCOUT
Route step: STEP4_MANUAL_SCOUT_PASS_001
Created at: 2026-05-28T19:19:05.8886156Z

Purpose:
This is the first controlled material candidate list for Agent Builder.
It is not an install plan and not a trusted material registry.

Candidate count: 9

Priority candidates:
1. Ajv - JSON schema validation candidate.
2. python-jsonschema - Python fallback validation candidate.
3. Copier - template rendering candidate.
4. Syft - SBOM candidate.
5. Grype - vulnerability scan candidate.
6. OSV-Scanner - dependency vulnerability scan candidate.
7. ScanCode Toolkit - deep license/provenance candidate, owner approval required.
8. Open Policy Agent - future policy engine reference candidate.
9. Conftest - future policy test reference candidate.

Important limits:
- No candidate is TRUSTED.
- No external tool was installed.
- No external repo was fetched.
- MATERIAL_CATALOG.json was not mutated by this step.
- PHASE80 must import this pass through Builder-controlled flow.

Next allowed step:
PHASE80_MANUAL_SCOUT_PASS_IMPORT_V1
