# REAL_DELTA_SCHOOL_ORGAN_V1 Adapter Wiring Plan

Status: CODEX_DRAFT
Preflight decision: PREFLIGHT_PASS
Proof boundary: lab and held-out review only
Runtime readiness: runtime_ready=false

## Purpose

The adapter/wiring layer for `REAL_DELTA_SCHOOL_ORGAN_V1` should be a thin parametric orchestration surface over existing Builder school parts. Its job is to accept a candidate feed of size N, run the existing intake, curriculum, comprehension, delta, acceptance, anti-cheat, digest, and map-rollup surfaces in one governed sequence, and emit validator-readable artifacts.

It must not create a new school architecture. The existing body scan already decided:

- do not build from scratch
- assemble a parametric organ from existing components
- treat `REAL_DELTA_SCHOOL_SCALE_GATE_V1` as superseded wrong direction
- keep `runtime_ready=false`

## Existing Components Reused By Lifecycle Stage

| Lifecycle stage | Existing file/function/script to reuse | Adapter role | Boundary or gap |
| --- | --- | --- | --- |
| `candidate_feed_received` | `operations/overnight_school/REAL_DELTA_SCHOOL_ORGAN_V1_PARAMETRIC_CONTRACT.json` | Defines `CandidateFeedPath`, `TargetAccepted`, source modes, candidate feed fields, allowed proof/map modes, and output contract. | Future runner must load a feed path and normalize candidate records. |
| `candidate_intake_validated` | `validators/validate_candidate_intake_report_contract_v1.ps1` | Reuse as candidate-intake contract precedent and intake proof surface. | Current validator drives an older runtime proof and can write proof/state outputs; future organ validator needs a feed-file wrapper, not direct broad runtime execution. |
| `curriculum_ladder_built` | `modules/normalize_builder_lesson_batch_001.ps1`; `modules/invoke_useful_curriculum_school_supervisor_v1.ps1`; scale mechanics from `operations/overnight_school/run_useful_school_30k_full_process_v1.ps1` | Normalize candidate lessons into a lesson batch, order them into curriculum cycles/subchunks, and preserve checkpoint/subchunk mechanics. | 30K mechanics are lab scale/checkpoint/storage precedent only. Do not run 30K in the adapter task. |
| `before_exam_recorded` | `operations/overnight_school/REAL_DELTA_SCHOOL_CYCLE_V1_REQUIREMENT.json`; `operations/overnight_school/run_real_delta_school_cycle_v1.ps1` | Reuse before-answer/before-transfer pattern and requirement gates as small real-delta invariant source. | Existing runner is a scripted lab harness and contains an old absolute `Set-Location`; use as spec material until a portable runner exists. |
| `lesson_comprehension_recorded` | `operations/overnight_school/run_real_delta_school_cycle_v1.ps1`; `modules/write_builder_lesson_result_001.ps1`; `modules/invoke_useful_curriculum_school_supervisor_v1.ps1` | Record explain-back, application, anti-application, lesson result, and candidate status. | Future runner must record per-candidate comprehension without treating generated text alone as proof. |
| `after_exam_recorded` | `operations/overnight_school/run_real_delta_school_cycle_v1.ps1`; `operations/overnight_school/run_real_delta_school_cycle_v1_review.ps1` | Reuse after-score, transfer, and held-out review shapes to prove behavior delta. | Held-out cases remain scripted review cases, not live autonomous runtime behavior. |
| `causal_use_checked` | `validators/validate_phase162_atom_executed_use_proof_v1.ps1`; `operations/overnight_school/validate_real_delta_school_cycle_v1.ps1`; `modules/invoke_phase162_controller_consume_controlled_accept_candidate_batch_001.ps1` | Require causal atom link, retrieval/use proof, and controlled accept candidate consumption. | Phase162 controller still blocks final accepted-core writes and keeps accepted state unmutated. |
| `anti_cheat_negative_tests_passed` | `operations/overnight_school/validate_real_delta_school_cycle_v1.ps1`; `operations/overnight_school/validate_real_delta_school_cycle_v1_review.ps1`; `operations/overnight_school/validate_useful_school_30k_full_process_v1.ps1` | Reuse checks for count-only false pass, direct answer/rubric leakage, flat duplicate atoms, map atom explosion, and runtime-ready overclaim. | Future validator must adapt these checks to the parametric organ output contract. |
| `accepted_or_rejected_atoms_written` | `modules/invoke_useful_curriculum_school_supervisor_v1.ps1`; `modules/write_builder_lesson_result_001.ps1`; `modules/invoke_phase162_controller_consume_controlled_accept_candidate_batch_001.ps1` | Emit accepted/rejected atom receipts and dry-run accept artifacts with reasons. | No accepted-core write is authorized by this plan. Final accept remains a later protected apply route. |
| `batch_or_capability_digest_written` | `operations/overnight_school/run_useful_school_30k_full_process_v1.ps1`; `modules/invoke_useful_curriculum_school_supervisor_v1.ps1` | Reuse promoted delta, chunk summary, checkpoint, and digest patterns at batch/capability level. | Digest must be compact and validator-readable; raw dumps and atom-level map events stay out of the map surface. |
| `map_updated_at_rollup_level_only` | `operations/self_map/invoke_self_map_auto_update_trigger_v1.ps1`; `operations/self_map/validate_self_map_auto_update_trigger_v1.ps1` | Call map trigger only with `AggregationLevel` of `chunk`, `batch`, `capability`, `module`, `organ`, or `system`. | `atom` and `subchunk` levels must be suppressed. Trigger script currently has an old absolute `Set-Location`; future wrapper must resolve portability. |

## Parametric Invocation Contract

The future unified runner should expose these parameters without creating per-N scripts or validators:

| Parameter | Required | Meaning | Guard |
| --- | --- | --- | --- |
| `CandidateFeedPath` | Yes | Path to a candidate feed with candidate id, source type, source reference, claim, usefulness, expected behavior delta, risk, dependencies, and optional exam hint. | Must be validated before any school cycle starts. |
| `TargetAccepted` | Yes | Integer target N for accepted atoms. | N controls quantity only; it is not architecture and must not create N-specific validators. |
| `BatchSize` | No | Chunk size for checkpoint, digest, and map rollup cadence. | Must not be treated as intelligence proof. |
| `ProofMode` | No | `full`, `sampled`, or `audit`. | No mode may accept an atom without the minimum causal/usefulness/safety proof gates. |
| `MapAggregationLevel` | No | One of `chunk`, `batch`, `capability`, `module`, `organ`, or `system`. | `atom` and `subchunk` are forbidden for map updates. |
| `ResumeFromCheckpoint` | No | Boolean or checkpoint token/path for resuming a bounded run. | Resume must not skip already required intake, proof, or digest validation. |
| `CandidateSourceMode` | No | `OWNER_SUPPLIED`, `SELF_PRACTICE_DERIVED`, `FAILURE_DERIVED`, `QUARANTINE_DERIVED`, `REPO_CHANGE_DERIVED`, or `MIXED`. | `QUARANTINE_DERIVED` means mine for candidate/invariant material only; no blind restore. |

## Proposed Lifecycle Sequence

1. Candidate feed received
   - Input: `CandidateFeedPath`, `CandidateSourceMode`, `TargetAccepted`, `BatchSize`, `ProofMode`, `MapAggregationLevel`, `ResumeFromCheckpoint`.
   - Reuse: `REAL_DELTA_SCHOOL_ORGAN_V1_PARAMETRIC_CONTRACT.json`.
   - Output: normalized candidate feed manifest.

2. Candidate intake validated
   - Reuse: candidate intake contract precedent from `validators/validate_candidate_intake_report_contract_v1.ps1`.
   - Output: intake validation receipt with rejected malformed candidates.
   - Future gap: a parametric feed validator that does not launch the older broad runtime proof.

3. Curriculum ladder built
   - Reuse: `ConvertTo-Phase161ANormalizedLessonBatch` in `modules/normalize_builder_lesson_batch_001.ps1` and supervisor cycle/subchunk mechanics from `Invoke-UsefulCurriculumSchoolSupervisorV1`.
   - Output: ordered lesson/candidate ladder with dependencies and batch partitions.

4. Before exam recorded
   - Reuse: before-answer and before-transfer shape from `run_real_delta_school_cycle_v1.ps1`.
   - Output: before exam record per candidate or sample, depending on `ProofMode`.

5. Lesson comprehension recorded
   - Reuse: comprehension shape from `run_real_delta_school_cycle_v1.ps1`, lesson result writer from `Write-Phase161ALessonResult`, and supervisor atom fields.
   - Output: explain-back, apply, anti-apply, and lesson result artifacts.

6. After exam recorded
   - Reuse: after-answer, after-score, transfer exam, and held-out review patterns from the real-delta cycle and review scripts.
   - Output: after exam record and behavior delta.

7. Causal use checked
   - Reuse: `validate_phase162_atom_executed_use_proof_v1.ps1`, `validate_real_delta_school_cycle_v1.ps1`, and the Phase162 controller consume module.
   - Output: causal atom link, retrieval/use proof, and controlled accept decision.

8. Anti-cheat negative tests passed
   - Reuse: count-only, synthetic-score, duplicate, answer-leakage, map-pressure, and runtime-ready overclaim checks from cycle/review/30K validators.
   - Output: negative test report with all traps blocked.

9. Accepted/rejected atoms written
   - Reuse: supervisor accepted/rejected candidate structures, lesson result writer, and Phase162 controlled accept candidate batch consumer.
   - Output: accepted atom receipts, rejected candidate reasons, and staged accept artifacts.
   - Guard: no accepted-core mutation and no live runtime mutation in this organ runner.

10. Batch/capability digest written
    - Reuse: 30K compact digest and supervisor checkpoint patterns.
    - Output: batch digest, capability digest, checkpoint, and human report.

11. Map updated at rollup only
    - Reuse: `invoke_self_map_auto_update_trigger_v1.ps1` with rollup `AggregationLevel`.
    - Output: map trigger decision only for rollup event.
    - Guard: atom/subchunk events must not update the map.

## Gaps Requiring Later Implementation

- No unified parametric organ runner exists yet.
- Existing real-delta cycle and review runners are scripted lab harnesses and contain old absolute repo paths.
- The candidate intake validator is not a generic `CandidateFeedPath` file validator; it launches older runtime proof flow and can write proof/state artifacts.
- The future runner needs one output schema covering accepted atoms, rejected atoms, batch digest, proof artifact, checkpoint, and report.
- The future validator needs to prove map rollup suppression for atom/subchunk events without reading generated map state/report/logs unless explicitly authorized.
- Existing Phase162 pieces prove staged/dry-run control and blockers, not final accepted-core writes.
- The 30K script is useful as scale/checkpoint/storage precedent only; it is not proof of intelligence and must not be continued as architecture.
- There is no live runtime invocation proof; `runtime_ready` remains false.

## Exact Future Implementation Cut-List

A later implementation task should be scoped to this exact implementation surface, with no per-number route:

- Create `operations/overnight_school/run_real_delta_school_organ_v1.ps1`.
- Create `operations/overnight_school/REAL_DELTA_SCHOOL_ORGAN_V1_RUN_OUTPUT_CONTRACT.json`.
- Create `modules/convert_real_delta_candidate_feed_to_lesson_batch_v1.ps1`.
- Create `modules/write_real_delta_school_organ_checkpoint_v1.ps1`.
- Create `modules/write_real_delta_school_organ_batch_digest_v1.ps1`.
- Create `modules/invoke_real_delta_school_organ_map_rollup_v1.ps1`.
- Optionally patch old absolute `Set-Location` usage in reused scripts only if a future task explicitly authorizes portability fixes; preferred first implementation is a wrapper that uses repo-root resolution.
- Do not create `REAL_DELTA_SCHOOL_SCALE_GATE_V1` successors.
- Do not create validators or runners tied to fixed values such as 50, 30000, or any other N.

## Exact Future Validator Cut-List

A later validator task should be scoped to this exact validation surface:

- Create `operations/overnight_school/validate_real_delta_school_organ_v1_candidate_feed_contract.ps1`.
- Create `operations/overnight_school/validate_real_delta_school_organ_v1_run_output_contract.ps1`.
- Create `operations/overnight_school/validate_real_delta_school_organ_v1_small_proof.ps1`.
- Create `operations/overnight_school/validate_real_delta_school_organ_v1_review.ps1`.
- Create `operations/overnight_school/validate_real_delta_school_organ_v1_map_rollup_policy.ps1`.
- Create `operations/overnight_school/validate_real_delta_school_organ_v1_no_runtime_ready_overclaim.ps1`.
- Create `operations/overnight_school/validate_real_delta_school_organ_v1_no_scale_gate_route.ps1`.
- Reuse existing Phase162, Phase165, real-delta cycle/review, 30K lab-mechanics, and self-map trigger validators as input surfaces where safe.
- Do not create per-N validators.

## Proof Boundary

This plan is a wiring proposal only. It does not implement a runner, does not execute a proof, does not mutate accepted core, and does not prove live intelligence.

Allowed claim after this task:

- `CODEX_DRAFT`
- `PREFLIGHT_PASS`
- adapter/wiring plan created
- runtime_ready=false

Forbidden claim after this task:

- live intelligence proved
- `runtime_ready` set to true
- accepted core updated
- map updated from atom/subchunk events
- 30K proves intelligence
- scale gate route continued

## Risks And Blockers

- Existing lab runners use old absolute paths and should not be invoked as-is in this workspace.
- Existing candidate intake validator is not yet a clean feed contract validator for arbitrary candidate files.
- Map trigger script writes trigger events and invokes map update on positive rollup events; future smoke tests must use negative atom/subchunk suppression or a controlled output path.
- Phase162 controller intentionally blocks final accept until rollback and post-accept validation exist.
- `ProofMode=sampled` and `ProofMode=audit` need strict definitions so sampling cannot bypass per-atom accept gates.
- Generated text can fake comprehension; validators must require before/after delta, causal links, retrieval/use proof, and negative traps.

## Why This Avoids Duplicate School Construction

The plan binds each lifecycle step to an existing component already identified by the body scan:

- candidate intake contract
- Phase162 acceptance and executed-use gates
- Phase165 lesson-to-atom bridge
- useful curriculum school supervisor mechanics
- useful school 30K scale/checkpoint mechanics as precedent only
- real-delta cycle probe
- held-out real-delta review
- self-map rollup policy

The missing piece is not a new school. It is a thin adapter that normalizes inputs, calls or wraps these components in order, and emits one unified output contract.

## Why N Is A Parameter, Not Architecture

`TargetAccepted` is an integer target. It changes runtime budget, chunk count, checkpoint cadence, and storage volume. It does not change the school organ, acceptance rules, validator family, or map policy.

Therefore:

- no `scale_gate_50` continuation
- no new route per target size
- no validator per numeric scale
- no claim that larger N implies stronger intelligence proof
- no 30K execution in this task

## Why Atom/Subchunk Events Must Not Update The Map

The self-map is a capability/module/organ surface, not an atom ledger. Atom and subchunk events can be high-volume, repetitive, and self-generated. Updating the map for each atom would create noise, self-trigger loops, and false capability growth claims.

The adapter must roll atom and subchunk outcomes into compact chunk, batch, capability, module, organ, or system digests. Only those rollup artifacts may be passed to the self-map trigger.

Required map rule:

- `AggregationLevel=atom`: no map update
- `AggregationLevel=subchunk`: no map update
- `AggregationLevel=chunk|batch|capability|module|organ|system`: eligible only after positive validated rollup evidence

Runtime readiness remains false.
