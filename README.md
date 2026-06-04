# EF_GPT_KNOWLEDGE_LIVE_BUILDER_MODE_UPDATE_2026_06_03

## Purpose

This update aligns GPT Knowledge with the new Agent Builder working cycle:

```text
stable accepted HEAD
→ Builder live daemon
→ visible live console
→ self-growth duty loop
→ Codex as bounded teacher/repair only
→ terminal proof pack
→ archive local runtime outputs
→ commit/push accepted artifacts
```

## What Changed

This pack updates only the files that needed rule changes.

Main corrections:
- old PHASE78 route lock is now marked as superseded reference;
- live Builder mode is treated as the current operating cycle;
- stale static ExpectedHead is forbidden for live scripts;
- repo identity must be resolved from script location;
- live-run outputs must be archived outside repo unless explicitly accepted;
- external PowerShell watcher is allowed when only operator visibility is needed;
- internal observer console is allowed when accepted as Builder capability;
- self-growth duty loop evidence is classified as `VALIDATED_PENDING_ACCEPTANCE` until commit/push.

## Current Evidence Classification

Accepted:
```text
6903d7b Add PHASE160 live observer console repair
```

Validated but not accepted:
```text
PHASE160_LIVE_SELF_GROWTH_DUTY_LOOP_EXPANSION_V1
validator PASS
proof PASS
diff scope FAIL due previous console sample output
```

## Upload Guidance

Replace existing GPT Knowledge files with these same filenames.

Do not keep older duplicate active copies if this pack marks them as superseded or delete candidates.
