# PHASE161F Rollback Plan

PHASE161F performs no protected mutation, so no protected rollback is required now.

For a future owner-approved apply:

1. Verify every protected target matches the SHA-256 recorded in its candidate.
2. Save exact byte-for-byte pre-apply copies outside runtime execution paths.
3. Apply one target at a time.
4. Parse and validate immediately after each target.
5. Restore the exact pre-apply copy on any failure.
6. Re-run protected consumers, PHASE161E refresh, and repository safety checks.
7. Do not continue to another target until the current target passes.
