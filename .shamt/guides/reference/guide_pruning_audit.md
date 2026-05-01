# Guide Pruning Audit

**Scope:** Resume Instructions sections and GUIDE_ANCHOR references across `.shamt/guides/`
**Conducted:** 2026-04-30 (SHAMT-45 Phase 8)
**Hypothesis:** PreCompact + SessionStart hooks (SHAMT-41) may make some compaction-fear
patterns redundant on Opus 4.7 / GPT-5.x with 1M context windows.
**Conservative bias:** Per OQ1, keep anything with even minor regression risk.

---

## Summary

| Category | Finding | Action |
|----------|---------|--------|
| `GUIDE_ANCHOR.md` (mandatory creation) | Hooks replace it when enabled; still needed when hooks off | Simplify S1 step to conditional |
| Resume Instructions in guides (templates) | Teach what to document — still load-bearing regardless of context window | Keep |
| Resume Instructions in architect_builder | Are builder-resume instructions (step ranges), not GUIDE_ANCHOR pattern | Keep |
| `precompact-snapshot.sh` / `session-start-resume.sh` notes | Already well-documented in master_dev_workflow.md | No change needed |

---

## Detailed Findings

### 1. GUIDE_ANCHOR.md — Simplify (not delete)

**Files affected:**
- `.shamt/guides/stages/s1/s1_epic_planning.md` — Step 5.5 marks GUIDE_ANCHOR.md as "MANDATORY"
- `.shamt/guides/reference/stage_1/stage_1_reference_card.md` — mentions GUIDE_ANCHOR as required
- `.shamt/guides/missed_requirement/discovery.md` — cross-link references GUIDE_ANCHOR
- `.shamt/guides/missed_requirement/realignment.md` — cross-link references GUIDE_ANCHOR

**Analysis:**
- When `features.shamt_hooks=true` is set, `precompact-snapshot.sh` + `session-start-resume.sh` replace GUIDE_ANCHOR.md entirely. The `master_dev_workflow.md` already says: "No manual GUIDE_ANCHOR / Resume Instructions step is needed for sessions where these hooks fire."
- When hooks are NOT enabled (projects that haven't set `shamt_hooks=true`), GUIDE_ANCHOR.md remains the only resumption artifact. Deleting the step would break those projects.
- 1M context windows reduce the frequency of compaction, but don't eliminate it (very long epics still compact).

**Verdict: SIMPLIFY — conditional note, not deletion**

Add to S1 Step 5.5: *"If `features.shamt_hooks=true` is set, `RESUME_SNAPSHOT.md` (written by the hooks) replaces GUIDE_ANCHOR.md for context resumption. You may skip creating GUIDE_ANCHOR.md in that case. If hooks are not enabled, GUIDE_ANCHOR.md remains mandatory."*

**Risk of deletion:** MEDIUM — projects without hooks would lose their only resumption artifact. Conservative bias says keep.

---

### 2. Resume Instructions sections in missed_requirement guides — Keep

**Files affected:**
- `.shamt/guides/missed_requirement/discovery.md` — "**Resume Instructions:**" template block
- `.shamt/guides/missed_requirement/realignment.md` — "**Resume Instructions:**" template block

**Analysis:**
These are template snippets inside guide documents — they teach the agent what to document
*when a missed requirement is detected*, specifically: what step to resume at, what context
to preserve. This is process documentation, not a compaction workaround. Even with 1M context,
the pattern is load-bearing because it:
- Creates a structured record of the pause point
- Is filled in by the agent and read by a resuming agent
- Remains useful regardless of context window size

**Verdict: KEEP — not a compaction-fear artifact**

---

### 3. Resume Instructions in architect_builder_pattern.md — Keep

**File:** `.shamt/guides/reference/architect_builder_pattern.md`

**Analysis:**
The "Resume Instructions" in this guide refer to instructions given to a *builder sub-agent*
for resuming from a specific step range (e.g., "Execute steps 23 through 50"). This is
unrelated to the compaction-fear GUIDE_ANCHOR pattern. The instructions remain load-bearing
for any partial builder execution.

**Verdict: KEEP — different pattern, not in scope**

---

### 4. Import workflow context references — Keep

**File:** `.shamt/guides/sync/import_workflow.md`

**Analysis:**
References to context/session management in the import workflow relate to managing
the import process across sessions, not standalone GUIDE_ANCHOR ritual. Not a pruning target.

**Verdict: KEEP**

---

## Recommended Simplifications

### S1 Step 5.5 — Add conditional hooks note

In `.shamt/guides/stages/s1/s1_epic_planning.md`, Step 5.5 ("Create GUIDE_ANCHOR.md"),
add the note: *"If `features.shamt_hooks=true` is set, RESUME_SNAPSHOT.md replaces
GUIDE_ANCHOR.md. You may skip this step when hooks are enabled."*

Same note in `.shamt/guides/reference/stage_1/stage_1_reference_card.md`.

**Applies changes to:** 2 files
**Risk:** LOW — additive note, no deletions

---

## Coverage-Gap Check (D-COVERAGE pass)

Skills updated in SHAMT-45 with new source guide content:
- `shamt-discovery`: added multi-modal + web tools + testing-approach gate (no corresponding source guide section yet in `s1_p3_discovery_phase.md` — see below)
- `shamt-validation-loop`: added STALL_ALERT pickup + S9 zero-bug gate (source: `validation_loop_composite.md` covers stall detection; S9 gate is new skill content)
- `shamt-spec-protocol`: added S1 approval gate + S2.P1.I2 gate + /fork (source: `critical_workflow_rules.md` partially covers; /fork is new)
- `shamt-architect-builder`: added Gate 5 AskUserQuestion + /fork S5 (source: `architect_builder_pattern.md` has Gate 5 narrative but not the structured AskUserQuestion form)

**New guide content needed (D-COVERAGE candidates):**
- `s1_p3_discovery_phase.md` should document the testing-approach gate (A/B/C/D AskUserQuestion) added to `shamt-discovery` — LOW priority, skill body is canonical
- `validation_loop_composite.md` S9 zero-bug confirmation gate — already referenced in skill; composite may benefit from explicit documentation

No HIGH-severity coverage gaps found. All new protocol content in skill bodies has traceable rationale in existing guides; the skill bodies themselves are the primary canonical reference for the new patterns.
