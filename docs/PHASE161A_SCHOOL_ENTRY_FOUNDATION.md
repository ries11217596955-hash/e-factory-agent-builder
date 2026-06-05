# PHASE161A School Entry Foundation

PHASE161A creates the first bounded school-entry contour for the Builder. It is not a mature school system and it does not produce external agents. It gives the Builder a session-local way to accept a curriculum pack, normalize lessons, run a bounded lesson batch, write per-lesson results, write a morning review skeleton, and expose school status through the existing live surfaces.

Active line: `AGENT_BUILDER_SELF_DEVELOPMENT`

Active mode: `SELF_BUILD`

The contour is intentionally session-local. Curriculum ingestion and lesson execution write only under `runtime_sessions/school_runs/<school_run_id>`. The lesson runner records `accepted_repo_mutated=false`, `protected_state_mutated=false`, `commit_performed=false`, `push_performed=false`, and `branch_switch_performed=false` in the school run manifest and lesson result files.

Core files:

- `schemas/builder_school_curriculum_pack.schema.json`
- `schemas/builder_school_lesson.schema.json`
- `schemas/builder_school_morning_review.schema.json`
- `modules/inspect_builder_school_entry_state_001.ps1`
- `modules/validate_builder_curriculum_pack_schema_001.ps1`
- `modules/ingest_builder_curriculum_pack_001.ps1`
- `modules/normalize_builder_lesson_batch_001.ps1`
- `modules/run_builder_school_batch_session_local_001.ps1`
- `modules/write_builder_lesson_result_001.ps1`
- `modules/write_builder_morning_review_001.ps1`
- `modules/inspect_builder_school_batch_readiness_001.ps1`

Live surface fields:

- `school_entry_enabled`
- `active_school_run_id`
- `active_curriculum_id`
- `school_lesson_total_count`
- `school_lesson_pass_count`
- `school_lesson_fail_count`
- `school_lesson_quarantine_count`
- `school_morning_review_written`
- `school_route_drift_detected`
- `school_owner_review_required`

The morning review separates ordinary failures from safety quarantines. A failed lesson does not stop the batch; a later lesson proves the batch continued. A safety violation is quarantined separately from failed expected output.
