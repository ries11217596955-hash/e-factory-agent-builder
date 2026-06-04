# EF_CONTROL_BOOK.md

## Document Status

**File type:** GPT Knowledge / Control Book  
**Status:** ACTIVE_CONTROL_BOOK  
**Version:** 2026-06-03-R4
**Purpose:** Permanent lessons from real failures.  
**Replacement rule:** Replaces older `EF_CONTROL_BOOK.md` by consolidating active lessons. Historical detail may be kept outside GPT Knowledge if needed.

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

## New Lessons From PHASE159–PHASE160

### 13. Repo identity must be inside scripts, not only terminal habits

Terminal may be in the right folder while a script reads another checkout.
Every durable module/validator must resolve repo root from its own script location and verify repo markers.

### 14. Static ExpectedHead breaks after accepted commits

Do not hardcode the previous commit as the forever expected head for live scripts.
Live runtime scripts should require:
```text
local_head == remote_head
expected_head_source = CURRENT_SYNCED_REPO_HEAD
```

### 15. Silent observer is not operator visibility

A file logger is not enough for live supervision.
The Owner must see a readable live console when operating Builder in live mode.

### 16. Do not confuse agent organs with operator tools

If the Owner only needs a temporary view, use external PowerShell.
If the Builder must own the capability, build and validate it as a module.

### 17. Live-run outputs are not patch files by default

Owner-supervised live sessions produce runtime evidence.
Do not commit them as ordinary patch outputs unless the proof plan explicitly requires it.
Archive local live-run outputs outside the repo before committing code/proof patches.

### 18. Validator PASS plus diff FAIL is not accepted

A patch may be logically correct and still not accepted.
Acceptance requires:
```text
validator PASS
+ proof/report PASS
+ diff scope clean
+ commit
+ push
+ clean local/remote sync
```

### 19. Maximal bounded organs beat minimal debt

For foundational Builder systems, build enough of the organ to support the next real cycle.
Do not create a tiny placeholder that immediately forces another repair, unless the Owner explicitly asks for a spike.

---


## Rule

Every serious failure must become a better rule.

Do not repeat mistakes:
- unclear root cause;
- fake proof;
- wrong repo;
- wrong shell;
- route drift;
- replacing settings incorrectly;
- micro-patching a class failure line by line.

---

## Lessons

### 1. Codex answer is not proof

Codex may say it fixed something. That is not proof.

Proof requires:
- terminal validation;
- diff;
- runtime;
- output file;
- proof/report;
- commit/push if accepted.

---

### 2. Root cause before patch

Before patching:
- identify fact;
- identify root cause or hypothesis;
- test hypothesis;
- patch only the proven scope.

If root cause is unknown:
`Есть гипотеза. Проверяем так.`

---

### 3. Do not mix product lines

Do not mix:
- Agent Builder self-development;
- external agent production;
- website/product system;
- monetization;
- GPT settings.

Name the active line before execution.

---

### 4. Build PASS is not product PASS

A script passing is not enough.

For agents/products, prove:
- output files;
- runtime behavior;
- input/output examples;
- validator;
- proof/report;
- launch surface if required.

---

### 5. Stale memory is not truth

If status could have changed, verify:
- terminal;
- repo file;
- GitHub;
- workflow;
- proof/report.

---

### 6. Wrong shell causes failures

PowerShell and Bash differ.

If user is in PowerShell:
- give PowerShell;
- no Bash syntax;
- no unsafe `exit`.

---

### 7. Long scripts require coherence pass

Long command blocks easily break.

Before giving a long script:
- avoid fragile regex;
- avoid line continuation risks;
- prefer runpack files;
- include parser checks.

---

### 8. Reports need decisions

Reports must tell us what to do next.

Bad report:
“Everything completed.”

Good report:
- status;
- evidence;
- risks;
- next move;
- cut list.

---

### 9. New chat state must be reconstructed

When moving chats:
- do not continue from vibes;
- use DEEP_RECOVERY_REPORT;
- separate claims from proof;
- identify route step;
- verify repo before execution.

---

### 10. Prior chat transcript is a recovery artifact

A pasted chat is not proof.

It is raw memory material.

The GPT must analyze it deeply before continuing.

---

### 11. Settings updates must be governed

Do not replace settings with random new fragments.

Classify files:
- active;
- superseded;
- deprecated;
- archive reference;
- delete candidate.

Use manifest/changelog for packs.

---

### 12. “Minimal architecture” is dangerous for foundational Builder systems

For Builder foundations:
- do not say “minimal registry” or “starter pack” when the Owner expects full process closure.
- Use: full contract first, phased execution second.

---

### 13. Public repos are mines, not warehouses

External code is not automatically usable.

Use:
- license/risk;
- material catalog;
- quarantine;
- policy;
- wrapper;
- proof.

---

### 14. Builder self-knowledge is mandatory

Builder must know:
- who it is;
- what modules exist;
- what proof exists;
- what gaps exist;
- what agents/products exist;
- what should be built next.

PHASE78 established this baseline.

---

### 15. Do not skip the Builder

If the output is a Builder capability:
- Builder must execute through runtime.
If Codex writes files but Builder never runs, it is only a patch, not a proven self-build capability.

---

### 16. Micro-patching can become a trap

If each patch reveals a new nearby error:
- stop;
- run full diagnostic;
- define class of defects;
- send bounded macro-repair task.

This lesson came from PHASE78 repair.

---

### 17. Route drift must be stopped

A strong new idea must not silently change the route.

Use:
- current step placement;
- future step placement;
- route change request.

---

### 18. Knowledge bloat must be managed

GPT Knowledge must not grow through duplicates:
- remove duplicate `(1)` / `(2)` files;
- keep active files only;
- move old pack READMEs/changelogs out unless needed;
- maintain a manifest.

---

### 19. Do not mistake an external brain for Builder's brain

The Owner clarified a core doctrine on 2026-06-01:

Builder must not be reduced to “LLM + tools”.

External LLMs, local models, APIs, frameworks, and public repositories may be useful as materials or tools, but they must not become the identity or core mind of Builder.

Correct framing:
- primitive brain cell first;
- self-observation;
- self-change;
- verification;
- rollback;
- experience absorption;
- child agents only through Builder-controlled growth.

If the assistant proposes “connect a local model and call that the brain,” stop and correct the framing.

---

## CONTROL_BOOK_UPDATE_CANDIDATE Template

When a new lesson appears:

```text
CONTROL_BOOK_UPDATE_CANDIDATE

Failure:
Root cause:
New rule:
Affected files/settings:
Promotion condition:
```

Do not add every thought. Add only lessons from real failure or repeated risk.
