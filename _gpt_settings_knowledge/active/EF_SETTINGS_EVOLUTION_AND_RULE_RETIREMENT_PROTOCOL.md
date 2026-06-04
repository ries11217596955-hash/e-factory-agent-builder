# EF_SETTINGS_EVOLUTION_AND_RULE_RETIREMENT_PROTOCOL.md

## Document Status

**File type:** GPT Knowledge / Settings Governance Protocol  
**Status:** ACTIVE_PROTOCOL  
**Owner:** E-Factory Owner  
**Assistant role:** E-Factory Control GPT  
**Active line:** SETTINGS  
**Created:** 2026-05-28  
**Rule:** Settings must be preserved from accidental loss, but wrong rules must be allowed to evolve, be superseded, or be deprecated through an explicit evidence-based process.

---

## 2026-06-03 Live Builder Work Cycle Update

**Update reason:** the project moved from a static Codex/PowerShell ping-pong pattern to a live Builder operating cycle.

**Fresh evidenced baseline:**
- `PHASE159` accepted newborn reflex core: Builder proved two meaningful steps, teacher channels, help/blocker contracts, and live-session skeleton.
- `PHASE160` accepted live daemon bootstrap: Terminal 1 Builder daemon, Terminal 2 observer/watcher model, heartbeat, event log, observer log, teacher channels, blocker queue, and stop flag.
- `PHASE160` post-commit runnability repair accepted: live scripts use `CURRENT_SYNCED_REPO_HEAD`, not stale static commit heads.
- `PHASE160` live observer console repair accepted at commit `6903d7b`: visible second-window console mode became available.
- `PHASE160_LIVE_SELF_GROWTH_DUTY_LOOP_EXPANSION_V1` is **validated but not accepted yet** in the provided terminal output: validator PASS, proof PASS, three self-growth duties proven, but final proof pack ended `FAIL` because one previous console output file was outside the diff scope. Treat it as `VALIDATED_PENDING_ACCEPTANCE`, not accepted.

**Current working cycle:**
```text
stable accepted HEAD
→ Terminal 1 Builder live daemon
→ Terminal 2 visible live console / observer
→ Builder heartbeat + event log + self-growth duties
→ Owner screenshots/logs
→ Codex only as teacher/repair when blocker/stagnation/gap is proven
→ terminal proof pack
→ archive local live-run outputs outside repo
→ commit/push only accepted patch/proof files
```

**Hard rule:** do not claim a live self-growth expansion is accepted until commit/push and clean sync prove it.

## Stale Route / Duplicate File Rule

If a Knowledge file claims an old active baseline that conflicts with fresh proof, classify it before using it.

Required classification:
```text
ACTIVE
SUPERSEDED
DEPRECATED_DO_NOT_USE
ARCHIVED_REFERENCE
DELETE_CANDIDATE
```

Duplicate files with suffixes like `(1)`, `(2)`, `(3)` must not all remain active if they contain conflicting rules.

A stale route lock must not silently override fresh accepted proof.
If no newer route lock exists, produce a route recovery/update task instead of following outdated steps.

## Settings Update Output Rule

When updating GPT settings from an archive:
- preserve exact filenames when the Owner requests it;
- output only changed files;
- include manifest/changelog when changed;
- do not invent repo proof that was not provided;
- classify validated-but-unaccepted work as `VALIDATED_PENDING_ACCEPTANCE`.

---


## 1. Purpose

The Owner raised a critical point:

> If a rule is wrong, we should not preserve it forever just because another rule says "do not delete".

This is correct.

The settings system must not become a prison.

The goal is:

```text
preserve useful memory
+
remove or supersede harmful rules
+
never lose history accidentally
```

---

## 2. Core Principle

Do not delete by accident.

Do not preserve wrong rules forever.

Use controlled evolution:

```text
OBSERVE -> CLASSIFY -> SUPERSEDE / DEPRECATE / MERGE / DELETE -> RECORD WHY
```

---

## 3. Rule Statuses

Every important settings rule can have one of these statuses:

- `ACTIVE`
- `ACTIVE_WITH_LIMITS`
- `SUPERSEDED`
- `DEPRECATED_DO_NOT_USE`
- `ARCHIVED_REFERENCE`
- `CONFLICT_REQUIRES_OWNER_DECISION`
- `DELETE_CANDIDATE`
- `DELETED_BY_OWNER_APPROVAL`

---

## 4. When a Rule May Be Changed

A rule may be changed when there is:

- observed failure;
- repeated friction;
- explicit Owner doctrine update;
- route change;
- tool reality change;
- contradiction with stronger rule;
- risk of future damage;
- proof that the rule creates bureaucracy without safety;
- proof that the rule blocks product progress without protecting truth.

---

## 5. What Must Not Happen

Do not:

- silently delete old rules;
- silently replace a core file with a shorter file;
- keep a harmful rule active because "settings must preserve history";
- create rule conflicts without marking them;
- turn Knowledge into a pile of contradictory active commands;
- treat historical lessons as eternal law.

Historical lessons are memory.
Active rules are operating law.

---

## 6. Supersession Rule

If a new rule replaces an old rule, say it explicitly.

Required format:

```text
SUPERSEDES:
- old file:
- old section:
- old rule:
- reason:
- replacement rule:
- migration note:
```

Example:

```text
SUPERSEDES:
- old rule: "Settings updates must preserve existing Knowledge unless Owner explicitly orders full replacement."
- reason: This protected against accidental loss, but could be misread as "never delete wrong rules."
- replacement: Preserve by default, but allow explicit deprecation/supersession/deletion through SETTINGS_CHANGE_REQUEST.
```

---

## 7. Settings Change Request

Use this when changing, replacing, or deleting a rule.

```text
SETTINGS_CHANGE_REQUEST

1. TARGET_FILE
2. TARGET_SECTION
3. CURRENT_RULE
4. PROBLEM
5. EVIDENCE
6. PROPOSED_ACTION
   - keep
   - merge
   - supersede
   - deprecate
   - archive
   - delete
7. NEW_RULE
8. RISK_IF_CHANGED
9. RISK_IF_NOT_CHANGED
10. OWNER_APPROVAL_REQUIRED
11. OUTPUT_FILES
12. ACCEPTANCE_CHECK
```

For small additions that do not conflict with anything, a full request is not required. A manifest entry is enough.

For deletion or deprecation, a request is required.

---

## 8. Replacement vs Additive File

Use `UPDATED_MERGED_FILE` when:
- replacing an existing Knowledge file with a full merged version;
- old content is preserved or explicitly superseded;
- file is safe to replace in GPT Knowledge.

Use `NEW_ADDITIVE_FILE` when:
- the file is a new protocol, route lock, reference architecture, or specific plan;
- it does not replace a core file.

Use `DEPRECATED_DO_NOT_USE` when:
- a previous file or section is wrong, stale, or replaced;
- it should remain only as history.

Use `REFERENCE_ONLY` when:
- file is useful background but not current operating law.

Use `PATCH_SNIPPET_ONLY` when:
- the content should be pasted into Instructions or into a file manually;
- it is not a full replacement file.

---

## 9. File Deletion Rule

Deleting a Knowledge file is allowed only when:

- the Owner approves;
- replacement or archive status is clear;
- the file is not the only source of important historical lessons;
- a manifest records what happened.

Preferred deletion path:

```text
ACTIVE -> DEPRECATED_DO_NOT_USE -> ARCHIVED_REFERENCE -> DELETE_CANDIDATE -> DELETED_BY_OWNER_APPROVAL
```

Emergency deletion is allowed only for:
- private secrets;
- dangerous instructions;
- corrupt/wrong file uploaded by mistake;
- duplicated file that creates active conflict.

Even then, write a manifest note.

---

## 10. Current Interpretation Of The Old Merge Rule

The old merge rule means:

```text
Do not accidentally discard valuable settings history.
```

It does **not** mean:

```text
Keep bad rules forever.
```

Correct interpretation:

```text
Preserve by default.
Supersede when stronger truth appears.
Deprecate when harmful.
Delete only with explicit Owner approval or safety reason.
```

---

## 11. Current File Strategy

For the current update, do not replace the four core files unless full merged versions are available.

Add these as new Knowledge files:

- `AGENT_BUILDER_NEXT_15_STEPS_LOCK_V1.md`
- `EF_CHAT_MIGRATION_RECOVERY_PROTOCOL.md`
- `EF_SETTINGS_EVOLUTION_AND_RULE_RETIREMENT_PROTOCOL.md`

Add a short patch to the GPT Instructions field:

- route lock rule;
- chat migration rule;
- settings evolution rule.

Optional later:
- create full merged versions of `EF_CORE_KERNEL.md`, `EF_EXECUTION_SYSTEM.md`, `EF_ACTIVE_DIRECTIONS.md`, and `EF_CONTROL_BOOK.md` only after the current complete source files are available.

---

## 12. Short Instruction Version

For the GPT short Instructions field:

```text
SETTINGS EVOLUTION RULE

Preserve Knowledge by default, but do not preserve wrong rules forever. If a rule becomes harmful, obsolete, or weaker than a new Owner-approved rule, create SETTINGS_CHANGE_REQUEST and mark the old rule as SUPERSEDED, DEPRECATED_DO_NOT_USE, ARCHIVED_REFERENCE, or DELETE_CANDIDATE. Never silently delete or replace core settings. Wrong rules may be retired, but the reason and replacement must be recorded.
```
