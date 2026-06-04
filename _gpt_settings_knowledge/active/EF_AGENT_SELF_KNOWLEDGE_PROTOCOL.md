# EF_AGENT_SELF_KNOWLEDGE_PROTOCOL.md

## Document Status

**File type:** GPT Knowledge / Agent Self-Knowledge Protocol  
**Status:** ACTIVE_PROTOCOL  
**Version:** 2026-06-03-R4
**Replacement rule:** Replaces older `EF_AGENT_SELF_KNOWLEDGE_PROTOCOL.md`.

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

## Live Self-Map Requirement

Builder self-knowledge must now include live-runtime truth, not only static repo truth.

Builder must be able to report:
- accepted HEAD;
- current live session root;
- heartbeat status/count;
- current tick;
- self_growth_enabled;
- self_growth_duty_count;
- last_self_growth_gap;
- next_self_growth_gap;
- blocker_queue count;
- teacher_inbox/outbox state;
- whether current outputs are accepted proof or local runtime evidence only.

Capability claims must distinguish:
```text
ACCEPTED_PROVEN
VALIDATED_PENDING_ACCEPTANCE
SESSION_LOCAL_RUNTIME_EVIDENCE
CANDIDATE
MISSING
FAILED
```

A validator PASS without commit/push is not `ACCEPTED_PROVEN`.

---


## 1. Purpose

As Agent Builder grows, it must be able to describe itself from repo evidence.

Self-description is not branding.
Self-description is operational truth.

---

## 2. Core Rule

Builder must not claim capabilities without evidence.

Every capability should be classified as:
- `PROVEN`;
- `PARTIAL`;
- `CANDIDATE`;
- `MISSING`;
- `UNKNOWN`;
- `FAILED`.

---

## 3. Required Questions Builder Must Answer

Builder must be able to answer:

1. Who am I?
2. What repo am I in?
3. What is my current capability?
4. What is my current queue state?
5. What systems exist?
6. What systems are missing?
7. What modules exist?
8. What operations exist?
9. What agents or agent-like products exist?
10. Which proofs/reports support my claims?
11. What should be built next?
12. What should not be done next?
13. Which self-development loop level am I currently at?
14. Which gaps block the next level?
15. Which self-changes were kept, rolled back, quarantined, or left for Owner decision?
16. Which child agents/organs exist, and what experience did they return?
17. Am I using external materials as governed tools, or am I mistakenly depending on them as my brain?

---

## 4. Required Artifacts

Self-knowledge should produce:

- `self_knowledge/BUILDER_SELF_MODEL.json`
- `self_knowledge/CAPABILITY_MANIFEST.json`
- `self_knowledge/MODULE_INVENTORY.json`
- `self_knowledge/EVIDENCE_INDEX.json`
- `self_knowledge/PRODUCED_AGENTS_INDEX.json`
- `self_knowledge/ROADMAP_STATE.json`
- `reports/self_knowledge/BUILDER_SELF_DESCRIBE_REPORT.json`
- `reports/self_knowledge/BUILDER_SELF_DESCRIBE_SUMMARY.md`
- `proofs/self_knowledge/AGENT_BUILDER_SELF_KNOWLEDGE_SYSTEM_FULL_CONTRACT_V1.json`

Future brain-cell self-development should also produce or evolve:
- `self_knowledge/SELF_DEVELOPMENT_LEVEL.json`
- `self_knowledge/SELF_DEVELOPMENT_GAP_LEDGER.json`
- `self_knowledge/SELF_CHANGE_HISTORY.json`
- `self_knowledge/CHILD_AGENT_EXPERIENCE_INDEX.json`

PHASE78 created the first proven version.

---

## 5. Self-Describe Report Must Include

- generated timestamp;
- repo identity;
- current capability;
- queue state;
- major existing systems;
- major missing systems;
- capability counts;
- module inventory counts;
- proof/report indexes;
- produced agent candidates;
- next recommended gap;
- current self-development level;
- last self-change decision if available;
- child-agent/organ experience summary if available;
- external material dependency warning if relevant;
- cut list.

---

## 6. Failure Behavior

If Builder cannot describe itself:
- do not pretend;
- write failure report;
- keep queue safe;
- do not mark capability complete;
- show missing evidence.

---

## 7. Relationship To Route Lock

Self-knowledge is the input to the route, not a replacement for route lock.

The latest route lock decides what step is active.
Self-knowledge provides evidence for why later steps matter.

---

## 8. Current Baseline

PHASE78 is accepted as the first self-knowledge baseline.

Accepted remote commit:
`ba7f928 Close PHASE78 self knowledge runtime proof`.

The next route uses this report to build:
- material acquisition;
- operation system;
- self-development decision kernel;
- self-build program loop.
