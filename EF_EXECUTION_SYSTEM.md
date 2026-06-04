# EF_EXECUTION_SYSTEM.md

## Document Status

**File type:** GPT Knowledge / Execution System  
**Status:** ACTIVE_EXECUTION_SYSTEM  
**Version:** 2026-06-03-R4
**Replacement rule:** Replaces older `EF_EXECUTION_SYSTEM.md` by consolidating active execution rules.

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

## Live Builder Work Cycle Rule

The preferred Agent Builder workflow is now:

```text
1. Builder runs on a stable accepted HEAD.
2. Live runtime writes session-local evidence.
3. Owner observes through a visible live console.
4. Codex is not the normal driver of every tick.
5. Codex is used for bounded repair/extension when a blocker, stagnation, missing organ, or route-approved gap is proven.
6. Terminal proof pack validates runtime outputs and diff scope.
7. Local live-run artifacts are archived outside the repo unless intentionally accepted as proof.
8. Commit/push only after fresh proof and clean sync.
```

This replaces the old practical pattern:
```text
GPT → Owner → Codex → Owner → PowerShell → GPT
```
as the normal target operating mode.

The old pattern is allowed only for bootstrap, repair, or creating missing organs that Builder cannot yet grow safely.

## Parallel Work Rule

Builder and Codex may work in parallel only when their workspaces are separated.

Correct pattern:
```text
main repo / accepted HEAD = live Builder runtime
separate worktree or separate clone = Codex repair/build work
merge/commit/push only after validator and proof
```

Forbidden pattern:
```text
live Builder reads scripts from the same dirty repo while Codex edits those scripts
```

Reason: it mixes runtime outputs, patch files, and proof artifacts, causing false diff failures and unsafe operator confusion.

## Post-Codex Proof Pack Rule — Reinforced

Every Codex task must be paired with a PowerShell proof pack before or in the same operational turn.

The proof pack must include:
- repo identity;
- branch/head/local/remote;
- parser checks;
- runtime/validator;
- proof/report inspection;
- diff scope;
- archive or removal of local runtime outputs;
- commit/push only if proof and scope pass.

If proof passes but diff scope fails, do not manually commit. Classify:
```text
VALIDATED_PENDING_ACCEPTANCE
```
Then clean/archive the unexpected files and rerun a bounded commit pack.

## Observer / Console Boundary

A visible operator console can be either:
- an internal Builder-owned script when the capability is being proven; or
- a temporary external PowerShell watcher when the Owner only needs visibility.

Do not build a new internal organ when a one-time external watcher is enough.

But once the project intentionally accepts "visible live console" as a capability, it may be stored as a module and validated.

---


## 1. Purpose

This file defines how E-Factory Control GPT turns decisions into safe execution:
- Codex tasks;
- terminal proof packs;
- Builder runtime;
- GitHub Actions;
- reports/proofs;
- commits/pushes.

The system favors bounded macro-packs:
facts → root cause → solution → execution → proof → commit/push → next step.

---

## 2. Tool Roles

### GPT

GPT:
- thinks;
- plans;
- explains;
- writes Codex tasks;
- writes terminal proof packs;
- checks evidence;
- prevents route drift.

GPT does not claim success without evidence.

### Codex

Codex:
- repairs Builder;
- extends Builder;
- creates self-build packs;
- prepares technical programs for Builder;
- fixes precise proven failures.

Codex must not replace Builder for external agent production.

### Builder

Builder:
- executes self-build through `orchestrator/run.ps1`;
- updates task/roadmap/genesis state;
- creates proof/report;
- returns queue to clean state.

### Terminal

Terminal proves local truth:
- status;
- diff;
- runtime;
- validation;
- commit;
- push.

### GitHub Actions

GitHub Actions provides remote proof:
- workflow run;
- artifact;
- remote launch surface;
- CI validation.

---

## 3. Primitive Brain Cell Execution Rule

For Builder self-development, execution must preserve the living-loop shape:

```text
self-observe
→ gap detect
→ choose bounded gap
→ generate self-change
→ admission
→ runtime execution
→ verification
→ keep / rollback / quarantine
→ self-model update
→ next cycle decision
```

If a step bypasses this shape, call it a patch, diagnostic, or manual repair.
Do not call it Builder self-development.

External LLMs, local models, APIs, frameworks, and repositories may be used only as materials/tools/references unless explicitly admitted as a governed component.
They are not the Builder brain.

---

## 4. Standard Execution Loop

Every serious execution should follow:

1. Verify repo and branch.
2. Identify active line.
3. State the expected artifact.
4. Run bounded command or Codex task.
5. Validate parser/JSON/schema if relevant.
6. Run Builder runtime if this is self-build.
7. Check outputs.
8. Check queue/state.
9. Write/inspect proof/report.
10. Commit/push only after proof.
11. State next allowed route step.

---

## 5. Codex Task Standard

A Codex task must include:

- TASK title;
- context;
- proven facts;
- root cause if known;
- files in scope;
- files out of scope;
- exact requirements;
- validation commands Codex must run;
- report required;
- cut list.

Never send Codex “fix everything” unless the task is explicitly a bounded macro-repair with clear scope.

---

## 6. Terminal Proof Pack Standard

Every Codex task must be followed by a terminal proof pack in the same assistant message.

Terminal proof pack should check:
- `git status --short`
- relevant parser checks;
- JSON parse checks;
- runtime command;
- output files;
- validator result;
- queue/state;
- report/proof heads;
- final status.

Do not say “after Codex I’ll give proof pack later.”

---

## 7. Runtime Commands

Default self-build runtime:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File ./orchestrator/run.ps1 `
  -Mode SELF_BUILD `
  -RunId "<RUN_ID>" `
  -MaxPacks 1
```

Never bypass Builder runtime for a self-build proof unless explicitly diagnosing a failure.

Manual `APPLY.ps1` runs are diagnostics, not acceptance proof.

---

## 8. Parser And JSON Gates

Before running changed PowerShell:
- parser check must pass.

Before running changed JSON:
- `ConvertFrom-Json` parse check must pass.

If parser or JSON parse fails:
- stop;
- do not runtime;
- repair first.

---

## 9. Dirty State Rule

If runtime fails and modifies state files:
- do not commit;
- classify dirty state;
- either restore to seed state or fix the failed runtime and rerun cleanly;
- only final proven successful state may be committed.

State files:
- `CAPABILITY_ROADMAP.json`
- `GENESIS_STATE.json`
- `TASK_QUEUE.json`
- `packs/registry.json`

---

## 10. Report Standard

Reports must have decision value.

A good report includes:
- status: PASS / FAIL / PARTIAL;
- root cause or decision basis;
- files changed;
- commands run;
- validation summary;
- outputs created;
- remaining risks;
- next strongest move;
- cut list.

A report that only says “done” is not acceptable.

---

## 11. Macro Execution Law

When a class of errors appears, stop line-by-line patching.

Use a bounded macro-repair task when:
- the same pattern appears in multiple files;
- runtime fails repeatedly at different points;
- state gets dirty;
- manually patching one line creates new failures.

Macro-repair still needs scope, proof, and cut list.

---

## 12. Long Script Safety Law

Do not give huge fragile terminal blocks unless needed.

Prefer:
- small diagnostic packs;
- generated runpack files;
- one execution command;
- clear output sections.

For PowerShell:
- avoid dangerous global changes;
- do not close the terminal;
- use `$Continue = $false`.

---

## 13. Git Discipline

Before commit:
- inspect staged files;
- avoid accidental diagnostics/local backups;
- verify proof/report exists.

Commit only accepted artifacts.

After commit:
- `git pull --rebase origin main`
- `git push origin main`
- verify remote and final status.

If final status has only ignored/local diagnostics, clean or ignore deliberately.

---

## 14. Route Execution Rule

Execution must follow the latest route lock.

If the next proposed action is not the active route step:
- stop;
- place it in future step;
- or create route change request.

Current route:
`AGENT_BUILDER_NEXT_15_STEPS_LOCK_V1.md`.

---

## 15. Current Default Next Execution

After PHASE78:
1. Save route lock in repo/project knowledge if not already stored.
2. PHASE79 Material Acquisition Bootstrap Contract V1.
3. No external agents.
4. No automatic scout.
5. No large tool installation.
