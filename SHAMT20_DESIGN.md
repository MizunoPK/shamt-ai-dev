# SHAMT-20 Design: Epic Development Efficiency — Token & Time Reduction

**Status:** Draft
**Branch:** `feat/SHAMT-20` (not yet created)

---

## Problem

The S1–S10 epic development process is designed for correctness. It achieves this through:

- **Validation loops** at S1.P3, S2.P1 (embedded at I1 and I3), S5.P2, S7.P2, S7.P3, S8.P1, S9.P2, S9.P4 — each requiring a primary clean round + sub-agent confirmation to exit (S9.P4 exception: the guide has inconsistent exit criteria — Passing Criteria uses "2 consecutive rounds with ZERO issues = PASS", while earlier sections reference "primary clean round + sub-agent confirmation"; P4 explicitly resolves this ambiguity)
- **Parallelization** at S2 (feature specs) and S5 (implementation plans) via secondary agents
- **Multi-stage user gates** at S2.I3, S3, S5 Gate 5, and S9.P3

The process works, but it is slow and token-intensive. An informal analysis suggests:

| Stage | Typical Duration | Primary Driver |
|-------|----------------:|----------------|
| S1 | 2–5h | Discovery validation loop |
| S2 (per feature, parallelized) | 2–4h | 3-iteration spec refinement |
| S3 | 2–3h | Epic docs + approval |
| S5 (per feature, parallelized) | 4.5–7h | Implementation plan validation (6–8 rounds) |
| S6 | Variable | Implementation — **sequential per feature** |
| S7 (per feature, **sequential**) | 2–4h | Feature QC + PR review |
| S8 (per feature) | 0.5–1h | Cross-feature alignment |
| S9 | 4–7h | Epic smoke + QC loop + user testing + final review |
| S10 | 1.5–3h | Cleanup + commit + archive |

For a 3-feature epic, total agent time (excluding S6) is roughly **35–60 hours**. Including implementation, 60–100 hours.

The core problem: **we have no instrumentation**. Every figure above is a rough estimate. We do not know:
- Which stages actually drive the most time
- Which validation dimensions cause the most counter resets (= most rework)
- How many tokens each stage consumes
- Whether complexity-independent stages (e.g., S8.P1) consistently contribute proportional value

Without data, optimization proposals are guesswork. And there is one obvious structural gap independent of data: **S6 and S7 are done sequentially by the primary agent** even though the guides already have parallel infrastructure for S2 and S5.

**A note on S5.P2:** S5 (implementation planning) is the single largest per-feature time sink at 4.5–7h, driven almost entirely by the validation loop (typically 6–8 rounds checking many dimensions across 7 master + S5-specific categories). Targeted proposals for S5.P2 specifically (e.g., reducing dimensions if some rarely trigger resets) are deferred until P1 metrics reveal the actual reset-causing dimensions and the actual dimension count is verified against the current S5.P2 guide. This is likely the highest-value future optimization area.

---

## Goals

1. Add metrics collection so we can measure actual stage cost across epics.
2. Identify and fix specific sources of redundancy and sequential bottlenecks.
3. Maintain quality — no proposal should weaken validation loop exit criteria, allow deferred issues, or remove user testing.

---

## Non-Goals / Constraints

The following are out of scope:

- Changing validation loop exit criteria (primary clean round + sub-agent confirmation stays)
- Allowing deferred issues during validation
- Removing VALIDATION_LOG.md (format may be optimized; existence stays)
- Weakening S9.P3 user testing
- Merging S7.P2 and S7.P3 into a single phase (they check different things; merging would create 20+ dimension loops). Note: P4's S9.P4 scope narrowing is a different operation — it narrows the scope of a SINGLE existing phase rather than merging two distinct phases with different purposes.

---

## Current State: Parallelization Inventory

Before proposing changes, the current parallelization state:

| Stage | Parallelized? | Notes |
|-------|:------------:|-------|
| S2.P1 spec creation | ✅ | Secondary agents per feature |
| S5.P1+P2 planning | ✅ | Secondary agents per feature |
| Sub-agent confirmation | ✅ | Always runs 2 agents in parallel |
| S6 implementation | ❌ | Primary agent only, sequential |
| S7 feature QC/review | ❌ | Primary agent only, sequential |
| S8 alignment | ❌ | Primary agent only, sequential |
| S9 epic QC | ❌ | Single agent |

The most glaring gap: for a 3-feature epic, S6+S7+S8 is done 3× sequentially by the primary agent even when features are independent.

---

## Proposals

### P1: Epic Metrics Logging (FOUNDATIONAL)

**Priority:** P0 — implement first; all other proposals need real data to validate

**Problem:**
All optimization decisions today are based on estimates and inference. We don't know which stages/dimensions actually drive time. Proposals P2–P10 below are educated guesses that could be wrong or misaligned with where the real cost is.

**Proposed Change:**
Add `EPIC_METRICS.md` to the epic folder structure template (created in S1 Step 5: Epic Structure Creation). The **primary agent is the sole updater** — secondary agents report timing data in their handoff packages at sync points, and the primary consolidates it into EPIC_METRICS.md. This avoids write conflicts when multiple agents run in parallel.

The relationship to VALIDATION_LOG.md: after each validation loop exits, the primary agent reads the loop's validation log, counts the rounds, identifies the top 3 reset-causing dimensions, and records those in EPIC_METRICS.md. VALIDATION_LOG.md is the source of truth for loop details; EPIC_METRICS.md is the summary. Note: most loops use VALIDATION_LOG.md as the filename; S8.P1 uses `S8_ALIGNMENT_VALIDATION_{feature_NN}.md` — verify the actual filename for each loop type at implementation.

**File format:**

```markdown
# Epic Metrics — {epic_name}

**Branch:** feat/SHAMT-{N}
**Start Date:** {YYYY-MM-DD}
**End Date:** {YYYY-MM-DD}
**Testing Approach:** {A/B/C/D} *(letter codes defined in S1 Epic Planning guide — implementation should look up and embed legend here)*
**Feature Count:** {N}
**Parallel Agents Used:** S2={N agents}, S5={N agents}, S6/S7={N agents or "none"}

---

## Stage Timing

| Stage | Start | End | Duration | Notes |
|-------|-------|-----|----------|-------|
| S1 | HH:MM | HH:MM | Xh Ym | |
| S2 (parallel) | HH:MM | HH:MM | Xh Ym | N agents |
| S3 | HH:MM | HH:MM | Xh Ym | |
| S5 (parallel) | HH:MM | HH:MM | Xh Ym | N agents |
| S6 | HH:MM | HH:MM | Xh Ym | |
| S7 total | HH:MM | HH:MM | Xh Ym | N features |
| S8 total | HH:MM | HH:MM | Xh Ym | N features |
| S9 | HH:MM | HH:MM | Xh Ym | S9.P3 restarts: {N} |
| S10 | HH:MM | HH:MM | Xh Ym | |
| **TOTAL** | | | Xh Ym | |

---

## Validation Loop Summary

| Loop | Stage | Rounds to Exit | Top 3 Reset-Causing Dimensions |
|------|-------|---------------:|-------------------------------|
| Discovery | S1.P3 | {N} | {dim}, {dim}, {dim} |
| Impl. Plan | S5.P2 F01 | {N} | {dim}, {dim}, {dim} |
| Feature QC | S7.P2 F01 | {N} | {dim}, {dim}, {dim} |
| Feature PR | S7.P3 F01 | {N} | {dim}, {dim}, {dim} |
| S8 Alignment | S8.P1 F01 | {N} | {dim}, {dim}, {dim} |
| Epic QC | S9.P2 | {N} | {dim}, {dim}, {dim} |
| Epic PR | S9.P4 | {N} | {dim}, {dim}, {dim} |

*(Add rows for F02, F03, etc. as applicable. S8.P1 alignment loops are typically short — 2 rounds.)*

---

## Notes

{Agent observations about unexpected bottlenecks, repeated patterns, surprising findings.}
```

**Location:** Epic root folder, same level as EPIC_README.md (e.g., `.shamt/epics/SHAMT-N-name/EPIC_METRICS.md`). Moves to `done/` with the rest of the epic folder at S10.

**Instrumentation points** — when the primary agent updates the file:
- **S1 Step 5 (Epic Structure Creation):** Create file, record branch name (already created in Step 1), fill in start date and feature count
- **After each stage exits:** Fill in end time and duration (collecting from secondary handoff packages if applicable)
- **After each validation loop exits:** Count rounds from VALIDATION_LOG.md, identify top 3 reset dimensions, record in table
- **S10 Step 5 (epic commit):** Include EPIC_METRICS.md in commit

**Estimated cost:** <10 min total per epic. Zero risk to quality.

**Long-term value:** After 5–10 epics, patterns will be actionable. Which dimension causes the most resets? Is S9.P3 restart frequency a problem? Are simple epics faster? This is the foundation for every other proposal here.

**Affected guides:** S1 primary guide (add EPIC_METRICS.md creation to Step 5 Epic Structure Creation), `parallel_work/s2_secondary_agent_guide.md` and `parallel_work/s5_secondary_agent_guide.md` (add timing fields to handoff package format — see OQ7), `stages/s10/s10_epic_cleanup.md` (add EPIC_METRICS.md to Step 5 commit list).

---

### P2: Parallel Smoke Testing (S7.P1 and S9.P1)

**Priority:** P1 — low-risk, immediately implementable, benefits every epic

**Problem:**
S7.P1 (feature smoke testing) has 3 sequential mandatory parts:
1. Import Test — verify modules import without errors
2. Entry Point Test — verify feature starts correctly
3. E2E Test — execute with real data, verify values

Parts 1 and 2 test different concerns (module imports vs. entry-point execution) and can be initiated simultaneously — neither requires the other to complete first as a technical matter. The current guides run them sequentially as a conservative default, but running them in parallel is safe: if Part 1 fails (imports broken), the Part 2 result is discarded and both re-run after the fix. Same pattern applies to S9.P1 (epic smoke testing), which has 4 parts where Parts 1-2 can be parallelized on the same basis.

**Proposed Change:**
For S7.P1: after identifying test targets from the feature's spec.md and git history, spawn a sub-agent to run Part 2 (Entry Point Test) simultaneously while the primary runs Part 1 (Import Test). For S9.P1: after reading the `epic_smoke_test_plan.md`, spawn a sub-agent to run Part 2 simultaneously while the primary runs Part 1. In both cases, both results are collected before Part 3 begins. If either Part 1 or Part 2 fails, the failure is fixed and both re-run before attempting Part 3.

S9.P1 has 4 parts total (vs. 3 for S7.P1): Parts 3-4 proceed in sequence after the parallel Part 1-2 completes.

**Affected guides:** `stages/s7/s7_p1_smoke_testing.md`, the relevant S9 smoke testing guide.

**Estimated impact:**
- S7.P1: ~10-15 min saved per feature smoke test run
- S9.P1: ~10-15 min saved once at epic level
- For a 3-feature epic: 3 × S7.P1 + 1 × S9.P1 ≈ 40-60 min total saved
- Additional savings if S7.P3 bugs trigger S9.P1 restarts

**Risk:** Very low. Parts 1-2 are read-only verification tests with no side effects. If either fails, the restart protocol is unchanged (re-run all parts from Part 1).

---

### P3: S7/S8 Cross-Feature Pipeline Parallelization

**Priority:** P1 — highest potential impact for multi-feature epics, higher implementation cost

**Problem:**
After S5 (all implementation plans approved), S6+S7+S8 is done sequentially per feature:
```
Feature 01: S6 → S7.P1 → S7.P2 → S7.P3 → S8.P1 → S8.P2
Feature 02: S6 → S7.P1 → S7.P2 → S7.P3 → S8.P1 → S8.P2
Feature 03: S6 → S7.P1 → S7.P2 → S7.P3 → S8.P1 → S8.P2  ← waits for F02
```

For a 3-feature epic with independent features, total S6+S7+S8 time is 3× the per-feature time. The parallel infrastructure (secondary agents, checkpoint protocol, lock files) already exists from S2 and S5 — it just hasn't been applied to S6/S7.

**Proposed Change:**
After S5 Gate 5 (all implementation plans approved), the primary agent runs a parallelization eligibility check:

**Eligibility criteria for S6/S7 parallelization:**
- Features operate in independent directories (no shared source files that both modify)
- Features don't have runtime dependencies on each other (Feature 02 doesn't call Feature 01's code at runtime)
- Test suites are independent (no shared test fixtures that could conflict)

Note: P7 (S8.P1 Dependency-Targeted Review, Part A) adds a `## Feature Dependencies` section to each feature's spec.md. If P7 is implemented first, eligibility can be read directly from that section rather than requiring a fresh assessment.

If eligible, spawn secondary agents for S6+S7 using the same handoff package pattern from S2/S5:
- Primary takes Feature 01 through S6 → S7.P1 → S7.P2 → S7.P3
- Secondary agents each take one feature through the same sequence
- Checkpoint protocol for progress monitoring (already exists)
- **Failure mode:** If a secondary agent fails or goes stale mid-S7, the primary takes over using the existing stale agent protocol from `checkpoint_protocol.md`. Total time increases but correctness is preserved.

**S8.P1 in parallel mode:** S8.P1 currently assumes sequential implementation (you update remaining specs before they're implemented). In parallel mode, all features implement simultaneously, so there are no "remaining unimplemented specs" to update mid-stream. S8.P1 becomes a **post-implementation cross-check** rather than a pre-implementation spec update:
- After all features complete S7: each feature's agent reads all other features' actual implementations and checks for interface mismatches
- If mismatches found: document in a "Interface Mismatch Flags" section in the S8 output file, and note in EPIC_README.md Agent Status. S9.P2 reads S8 output files during its pre-round reading and investigates flagged mismatches as part of the Cross-Feature Integration dimension

Whether the parallel-mode S8.P1 cross-check uses a formal validation loop (primary clean round + sub-agent confirmation) or a single-pass check is a design decision for `s6_s7_parallel_protocol.md`. Note: the current sequential-mode S8.P1 has a **MANDATORY** formal validation loop (its Step 5 is explicitly labeled "Alignment Validation Loop, MANDATORY," with "primary clean round + sub-agent confirmation" exit criterion). Reducing this to a single-pass check in parallel mode is a deliberate quality trade-off that must be explicitly justified in `s6_s7_parallel_protocol.md`, not left as an implicit default.

New guide files needed:
- `s6_s7_parallel_protocol.md` (primary agent coordination)
- `s6_s7_secondary_agent_guide.md` (secondary agent S6+S7 execution — must cover S6 execution in secondary-agent context)
- Updates to `s5_primary_agent_guide.md` (new sync point after Gate 5 — primary now runs parallelization eligibility check)
- Update to `s5_parallel_protocol.md` (describe the extended post-Gate-5 workflow: eligibility check → conditional S6/S7 secondary spawning)
- Update to the S8 alignment guide (parallel mode S8.P1 behavior)
- Update to `checkpoint_protocol.md` (extend to cover S6/S7 parallel monitoring)
- Note in S9.P2 guide (intake path for interface mismatch flags generated by parallel-mode S8.P1)

**Estimated impact:**
- 3-feature epic with independent features: 50–60% reduction in S6+S7+S8 time
- Illustrative example with estimated S6 duration: 3 × (S6: Xh + S7: 3h + S8: 0.75h) → parallel reduces to ~1× per-feature time
- Actual gain depends on S6 duration, which is variable — see P1 data before committing to this proposal

**Risk:** Medium-high. Requires new guide files (substantial authoring). Parallel S6 could create merge conflicts on shared infrastructure files. Mitigation: eligibility check prevents use when features share files.

**Implementation dependency:** Design the full guide after P1 data shows actual S6/S7 cost.

---

### P4: S9.P4 Scope Narrowing

**Priority:** P1 — reduces redundant validation, low implementation risk

**Problem:**
S9.P4 runs the full 11-category PR review at epic scope. S7.P3 already ran the same 11 categories per-feature. The categories are the same but the scope is different: feature-scope vs. epic-scope.

Most of S9.P4's 11 categories have two components: (a) per-feature quality checks that S7.P3 already confirmed, and (b) epic-level concerns only visible when viewing all features together. The per-feature component (code comments, naming, per-feature test coverage, individual function refactoring) adds minimal value at epic scope — S7.P3 confirmed those. The epic-level component (cross-feature integration, architecture coherence across features, original requirements satisfaction, patterns only visible at epic scope) retains full value.

S9.P4 should focus entirely on the epic-level component.

**Proposed Change:**
Replace S9.P4's 11-category PR review with a **5-category epic-level review**. S7.P3 is unchanged — it keeps its existing 11 categories.

New S9.P4 categories:
1. **Cross-Feature Integration:** Do features work together as designed? Integration points verified with actual calls and data flows? No gaps in the handoff between features?
2. **Architecture Coherence:** Does the implementation match intended architecture? No unplanned coupling between features? No architectural drift introduced across the epic?
3. **Epic Requirements Coverage:** Are all original epic requirements satisfied? Verify against the original request file line-by-line.
4. **Emergent Quality Patterns:** Quality issues that only appear at epic scope — e.g., inconsistent error handling patterns across features, naming inconsistencies between features, duplicated logic that could be consolidated. (Per-feature code quality was confirmed in S7.P3; this category looks for cross-feature patterns only.)
5. **Epic Documentation Completeness:** EPIC_README.md, lessons learned, and epic_smoke_test_plan.md are accurate, complete, and reflect the actual implementation.

The check "S7.P3 was completed and passed for each feature" becomes an **entry prerequisite for S9.P4**, not a validation loop category. If S7.P3 did not pass for any feature, S9.P4 cannot start.

**Implementation note:** The current S9.P4 guide uses "2 consecutive rounds with ZERO issues = PASS" as its exit criterion — different from the master protocol's "primary clean round + sub-agent confirmation." The proposed 5-category version must explicitly decide which standard to apply and state it in the updated guide. If the master protocol standard is adopted (recommended for consistency), the new guide should say so explicitly rather than inheriting the current divergent criterion by omission.

**Affected guides:** The S9.P4 workflow guide and any S9 router guide.

**Estimated impact:**
- S9.P4 current: validation loop over 11 categories, 4–6 rounds typical (1.5–2h)
- S9.P4 after: validation loop over 5 focused categories — likely fewer rounds since per-feature defects no longer surface
- Rough estimate: 40–50% reduction in S9.P4 time (from 1.5–2h to 45–75 min)

**Risk:** Low. The per-feature code quality is confirmed by S7.P3 (a hard requirement). The 5 new categories cover all concerns uniquely visible at epic scope. The validation loop exit criteria are unchanged.

---

### P5: Validation Log Format Compaction

**Priority:** P2 — reduces per-round overhead across all validation loops

**Problem:**
VALIDATION_LOG.md requires verbose documentation per round: pre-round gate (5 checkboxes + prose), dimension results (prose per dimension), adversarial self-check (5 questions with prose answers), post-round gate (6 checkboxes + prose). For a 6-round loop, that's ~12 log sections.

The overhead is real: each log entry likely costs 5–10 min to write. A 3-feature epic has approximately **12+ validation loops** in the primary stages (S1.P3×1, S5.P2×3, S7.P2×3, S7.P3×3, S9.P2×1, S9.P4×1). Additional loops exist in S2.P1 (embedded gates per feature) and S8.P1 (alignment loops per feature) — the actual count is higher. At 6 rounds average per loop, ~72+ log entries. At 7.5 min per entry: ~540+ min of log-writing overhead per epic — a substantial fraction of total time.

The verbosity was designed to enforce discipline. It works, but the format can be made compact without losing that discipline.

**Proposed Change:**
Define a compact table format for VALIDATION_LOG.md that satisfies tracking requirements with less prose:

```markdown
# Validation Log — {artifact_name}

| # | Pattern | D1 | D2 | D3 | D4 | D5 | D6 | D7 | {extra dims} | Issues | Counter |
|---|---------|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:---:|--------|:-------:|
| 1 | Sequential | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ | D8✅ D9❌ | 3 found + fixed | 0 |
| 2 | Reverse | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | All ✅ | 0 (adv-check clean) | 1 → spawn |

**Sub-agents (Round 2):**
- Agent A: 0 issues ✅
- Agent B: 0 issues ✅ → EXIT

**Issue Notes:**
- R1-D3: {brief description of issue and fix applied, with tool call evidence}
- R1-D6: {brief description}
- R1-D9: {brief description}

**Spot-check Notes (clean rounds):**
- R2: Read {file}, Grep {pattern} → {N} matches as expected ✅
```

The adversarial self-check moves from 250-word prose to a single inline flag per round: if any adversarial question surfaces a new issue, it is logged as a normal issue (resetting the counter as usual). If no new issues surface, it is noted in the Issues column as "0 (adv-check clean)." This preserves the adversarial check without verbose answers.

**Tool call evidence requirement:** Each ❌ dimension must reference the specific Read/Grep tool call that found the issue in the Issue Notes. For ✅ dimensions, at least one tool call citation must appear per round (in the "Issues" column or a separate "Spot-check" entry) to preserve the master protocol's ≥3 technical claims verification requirement. A round where all dimensions are ✅ but no tool calls are documented is not acceptable.

**Scope:** Applies to all standard validation loops: S1.P3, S5.P2, S7.P2, S7.P3, S8.P1, S9.P2, S9.P4, and any S2.P1 embedded gates that produce a loop log file (verify at implementation). The compact format applies regardless of the exact filename — most loops use VALIDATION_LOG.md; S8.P1 uses `S8_ALIGNMENT_VALIDATION_{feature_NN}.md`. Does not change the loop exit criteria or the adversarial self-check requirement.

**Affected guides:** `reference/validation_loop_master_protocol.md` (add compact format as default option), all per-loop validation guides that reference the VALIDATION_LOG.md format.

**Estimated impact:**
- ~15–25 min savings per validation loop
- For a 3-feature epic with 12+ validation loops: ~180–300 min (~3–5 hours) saved
- Token reduction: significant, since log entries are large across long loops

**Risk:** Low-medium. The compact format is less expressive for complex issues. Mitigation: agents can always expand to prose for a specific issue if complexity warrants it; the compact format is the default.

---

### P6: S2.P1 Adaptive Iteration (Gate After I1)

**Priority:** P2 — eliminates redundant iteration for complete specs

**Problem:**
S2.P1 has 3 mandatory iterations for every feature:
- I1: Feature-level discovery (60–90 min)
- I2: Checklist resolution (45–90 min)
- I3: Refinement & alignment (30–60 min)

I2 exists to resolve unanswered checklist questions from I1 through user Q&A (the agent presents checklist items to the user one-at-a-time for approval). If I1 is done thoroughly enough that all checklist questions are already resolved, I2 adds time without value. (Cross-feature interface assumption checking occurs in I3 Step 1, which runs regardless of whether I2 is skipped.)

**Proposed Change:**
After I1 completes, run a **15-minute quality gate** before proceeding:

```
I1 Completeness Gate:
[ ] The agent has resolved all checklist.md questions through research (zero questions remain "UNKNOWN", "TBD", or "check with user" in the agent's working notes — checklist.md itself remains questions-only per current guide convention and is never marked [x])
[ ] All acceptance criteria are measurable (specific thresholds, not "should work" or "performs well")
[ ] All referenced file paths verified with Read tool (no assumed paths)
[ ] No circular dependencies with other features identified during I1
[ ] No scope items flagged for discussion that haven't been resolved
[ ] No cross-feature interface assumptions that haven't been verified against other features'
    I1 specs (e.g., "Feature 01 assumes Feature 02 outputs format X" — is that actually in F02's spec?)
    Note: in parallel S2, only features whose I1 is already complete can be checked. If the relevant
    feature's I1 is not yet complete, this criterion fails → proceed to I2 (I2 will revisit once
    that feature's spec is available).

If ALL items pass → skip I2, proceed directly to I3
If ANY item fails → proceed normally to I2
```

Gate 2 (Spec-to-Epic Alignment Check) and Gate 3 (User Approval) remain mandatory regardless of whether I2 was skipped. S2.P2 (Cross-Feature Alignment) also still runs after all I3s complete.

**Implementation note:** The current S2.P1 guide contains a "FORBIDDEN SHORTCUTS" rule that explicitly states I1, I2, and I3 are all mandatory and must run in sequence. Implementing P6 requires removing or modifying that rule to make I2 conditional. The implementation must verify the original rationale for that rule (was it to catch UNKNOWN checklist items, inter-feature inconsistencies, or both?) and confirm that the gate criteria adequately cover both scenarios.

**Affected guides:** `stages/s2/s2_p1_spec_creation_refinement.md` (S2.P1 guide).

**Estimated impact:**
- For features where I1 is genuinely complete: saves 45–90 min per feature
- Rough estimate: 30–50% of features may qualify (depends on epic complexity)
- For a 3-feature epic: 45–150 min potential savings

**Risk:** Low-medium. I2 catches both "UNKNOWN" checklist items and cross-feature inconsistencies. The gate criteria above address both. Mitigation: Gate 2 (Spec-to-Epic Alignment) and S2.P2 provide additional backstops even if I2 is skipped.

---

### P7: S8.P1 Dependency-Targeted Review

**Priority:** P2 — reduces scope of cross-feature spec review

**Problem:**
After each feature completes S7, S8.P1 reviews ALL remaining unimplemented features' specs for alignment with the actual implementation. For a 5-feature epic, Feature 01's S8.P1 reviews specs for Features 02–05. If Feature 03 has no dependency on Feature 01, reviewing Feature 03's spec is a no-op.

**Proposed Change:**
Two parts:

**Part A — Feature Dependency Declaration (S2 change):**
Add a `## Feature Dependencies` section to each feature's spec.md during S2:

```markdown
## Feature Dependencies
**Depends on:** [Feature 02 — uses its output format], [Feature 04 — calls its API]
**Depended on by:** [Feature 03 — consumes this feature's output]
**Independent of:** [Feature 05]
**Modifies shared files:** [utils/parser.py, config/settings.py] (or "None")
```

If the feature has no dependencies: `**Depends on:** None`, `**Modifies shared files:** None`

The `**Modifies shared files:**` line is important: it captures shared utility or configuration files that multiple features might both modify, even without a direct feature-to-feature API dependency. This list also feeds P3's parallelization eligibility check — if two features both list the same shared file, they cannot run S6 in parallel.

**Part B — S8.P1 targeted review:**
When Feature 01 completes S7, S8.P1 reads Feature 01's `## Depended on by` list and reviews only those features' specs. Features not in the list are skipped.

Note: This `## Feature Dependencies` section also directly powers P3's parallelization eligibility check — if all features list "Independent of" all others, parallel S6/S7 is immediately eligible without a separate assessment. When P3 is also implemented, S8.P1 gains a second mode: in parallel execution, the cross-check reviews actual implementations (not specs) — see P3 and the Implementation Sequence P3+P7 interaction note.

**Affected guides:** Feature spec.md template (S2), S8.P1 workflow guide.

**Estimated impact:**
- For loosely coupled epics: 50–80% reduction in S8.P1 scope per feature
- For tightly coupled epics: no change
- Rough estimate: saves 15–40 min per completed feature depending on coupling

**Risk:** Low-medium. The current S8.P1 guide prohibits skipping features in two places: (1) Critical Rule: "Review ALL remaining features (not just 'related' ones)" — rationale: implementation insights can affect unexpected features; and (2) FORBIDDEN SHORTCUTS: "Skip checking remaining feature specs because 'the changes were minor' — ALL not-yet-implemented feature specs must be reviewed." P7 Part B proposes overriding both. The S8.P1 implementation update must modify both the Critical Rule and the FORBIDDEN SHORTCUTS entry. The safety net is S9.P2 (12 dimensions including Cross-Feature Integration); if S9.P2 is considered a sufficient catch for spec-level misalignments that targeted S8.P1 would have found, the risk is acceptable.

**Misclassification guard:** When Feature 01's S8.P1 runs, it should do a quick verification of features listed as "Independent of" — confirm that Feature 01's actual implementation has no calls, data flows, or shared file writes to those features beyond what was known during S2. This is not a full spec review, just a surface-level confirmation that the "Independent of" claim remains valid post-implementation.

---

### P8: S3 Early Start Overlap

**Priority:** P2 — eliminates waiting between late S2 and S3

**Problem:**
S3 (Epic Docs & Approval, 2–3h) starts only after ALL features complete S2. But S3's preparatory work — drafting architecture docs and refining the epic test plan — doesn't require all specs to be finalized. It requires most of them. The final feature completing S2.I3 doesn't significantly change the architecture that was already visible from the first N-1 features.

Currently: Feature N finishes S2.I3 → S3 begins (full wait)
Proposed: Feature N enters S2.I3 → S3 preparation begins in parallel

**Proposed Change:**
When all but one feature have completed S2.P1 (I3 stage), the primary agent may begin S3 preparation (architecture docs draft, epic test plan refinement draft) while the final feature finishes S2.I3. The drafts are marked provisional and finalized once the last spec is complete.

S3's cross-feature alignment and user approval steps still require all specs complete — only the preparation steps overlap.

**Affected guides:** S3 primary guide (add a conditional "early start" section), S2 primary agent guide (note when to signal S3 readiness).

**Estimated impact:**
- Saves ~30–60 min on S3 per epic (the time that architecture drafting + test plan refinement overlap with the last S2.I3)
- No savings for single-feature epics or when all features complete S2 simultaneously

**Risk:** Low-medium. If the last feature's spec changes something architectural, the provisional S3 draft needs rework. Mitigation: the draft is explicitly provisional; full alignment still happens before user approval.

---

### P9: PROCESS_METRICS Aggregation File

**Priority:** P3 — enables trend analysis across epics

**Problem:**
Even with P1 (EPIC_METRICS.md per epic), patterns only emerge if data is aggregated. A per-epic file buried in `epics/done/` is not visible enough for trend analysis.

**Proposed Change:**
Create `.shamt/epics/PROCESS_METRICS.md` alongside EPIC_TRACKER.md. During S10 Step 7 (EPIC_TRACKER update), the agent appends one summary row. On the first epic (file does not yet exist), the agent creates the file with the table header before appending the first row:

```markdown
| Epic | Date | Features | Total Time | S5 Avg Rounds | S7 Avg Rounds | S9 Rounds | S9P3 Restarts | Top Reset Dim |
|------|------|:--------:|:----------:|:-------------:|:-------------:|:---------:|:-------------:|---------------|
| SHAMT-N | 2026-03-29 | 3 | 52h | 7 | 6 | 8 | 0 | D1-Empirical |
```

After 10+ epics, this table reveals:
- Which stages are consistently most expensive → prioritize optimization
- Which dimension causes the most resets across epics → invest in pre-validation
- Whether S9.P3 restarts are common → worth improving smoke testing depth
- Whether loops are shortening over time → measures guide quality improvement

**Affected guides:** `s10_epic_cleanup.md` (add PROCESS_METRICS.md row append to Step 7 instructions and Exit Criteria checklist).

**Estimated cost:** ~10 min per epic to fill in S10.

**Risk:** Negligible. Informational only.

---

### P10: S1 Discovery Scope Scaler

**Priority:** P3 — reduces over-investment in simple epics

**Problem:**
The S1 Discovery Phase runs identically for all epics. For a well-understood, small epic (e.g., "add a new config option to an existing module"), the full Discovery scope may over-engineer the research needed.

**Proposed Change:**
Before starting Discovery, the agent classifies epic complexity using concrete criteria:

| Class | Criteria | Discovery Scope |
|-------|----------|-----------------|
| **Simple** | ≤2 features AND no new external integrations AND extends existing module (not new system) AND user has provided detailed spec in request | Reduced DISCOVERY.md (subset of required sections — verify actual count against `stages/s1/` DISCOVERY.md template at implementation). Validation loop unchanged. |
| **Standard** | 3–5 features, OR new integration with existing internal service, OR moderate new logic | Current DISCOVERY.md (all sections). Standard validation loop. |
| **Complex** | 6+ features, OR new external dependency, OR architectural decision, OR cross-system change | Current DISCOVERY.md + extended research. Agent is encouraged to run extra rounds. |

Classification is proposed by the agent and confirmed by the user before Discovery begins.

**Note:** Implement only after P1+P9 data confirms that Simple epics genuinely have shorter loops. Validation criteria: if Simple epics average ≥20% fewer validation loop rounds per feature than Standard epics (across ≥5 epics of each class), the scaler is worth implementing. If Simple epics show the same loop counts as Standard, the classification overhead is not justified and this proposal is rejected. P9's PROCESS_METRICS.md table is the source of this comparison.

**Affected guides:** S1 primary guide (add complexity classification section).

**Estimated impact:**
- For Simple epics: 45–75 min savings on Discovery Phase
- No change for Standard/Complex

**Risk:** Medium. Misclassifying a Standard epic as Simple under-invests in discovery and creates cascading quality issues. Mitigation: criteria are binary and objective; user confirmation is required.

---

## Proposals Considered and Rejected

**R1: Tiered dimension checking (check only "critical" dimensions in early rounds)**
Violates the "check ALL dimensions EVERY round" principle. Early partial checks miss cross-dimensional issues — rejected.

**R2: Parallel primary validation rounds (run Round N alongside sub-agents verifying Round N-1)**
There is no "Round N-1" to verify until primary declares it clean. The dependency chain is fundamental — rejected.

**R3: Streaming validation (check dimensions while reading)**
Violates the fresh-eyes principle. Interleaved reading and checking prevents the clean-slate perspective — rejected.

**R4: Counter persistence for same-round fixes**
"Found and fixed in same round" is definitionally not a clean round. Changing this would incentivize rushing fixes — rejected.

**R5: Removing VALIDATION_LOG.md entirely**
The log enforces discipline via tool call evidence requirements. Compaction (P5) is the right approach — rejected.

**R6: Fully automated dimension checking for validation loops**
The audit system (`pre_audit_checks.sh`) already does this for guide consistency. Extending to implementation validation requires substantial new tooling. Defer until P1 identifies which dimensions most benefit from automation — deferred, not rejected.

**R7: Merging S7.P2 and S7.P3**
They check different things. S7.P2 validates correctness; S7.P3 validates production-readiness. Merging would create 20+ dimension loops — rejected.

**R8: Making S9.P4 conditional (skip entirely if S7.P3 averaged ≤2 rounds)**
S9.P4's unique value is checking integration and epic-scope concerns that S7.P3 cannot check. Even with perfect per-feature quality, epic-level integration issues can emerge. The narrowed scope (P4) is the better approach — rejected.

---

## Implementation Sequence

Order based on independence, risk, and data dependency:

1. **P1 (Metrics Logging)** — No dependencies. Implement first.
2. **P4 (S9.P4 Scope Narrowing)** — Pure guide edit, low risk, immediate benefit.
3. **P5 (Validation Log Compaction)** — Guide format change, benefits every subsequent loop.
4. **P2 (Parallel Smoke Testing)** — Small targeted guide change, very low risk.
5. **P7 (S8.P1 Dependency-Targeted Review)** — Requires spec template change (S2) + S8 guide update.
6. **P6 (S2.P1 Adaptive Iteration)** — Guide change to S2 with new quality gate.
7. **P8 (S3 Early Start)** — Guide changes to S3 + S2 coordination.
8. **P9 (PROCESS_METRICS Aggregation)** — Add aggregation row to S10 workflow.
9. **P10 (S1 Discovery Scope Scaler)** — After P1+P9 data confirms value.
10. **P3 (S7/S8 Pipeline Parallelization)** — Most complex; design fully only after P1 data confirms S6/S7 is actually the biggest driver. Per OQ8, P3 may be extracted to a separate SHAMT-21 design doc rather than implemented as part of SHAMT-20. This entry indicates intent and ordering; final scope decision happens when P1 data is available.

**Note on affected guide files:** Each proposal above lists its primary affected guides. Before implementing any proposal, a targeted audit of all S1-S10 guides should confirm no additional cross-references require updating (the same pattern used in SHAMT-19 before committing).

**Note on P3+P7 interaction:** When both P3 (pipeline parallelization) and P7 (dependency-targeted review) are implemented, S8.P1 has two modes: (a) in sequential mode, S8.P1 uses P7's targeted review (only "Depended on by" features); (b) in parallel mode, S8.P1 uses P3's post-implementation cross-check (all features read each other's actual implementations for interface mismatches). P7's dependency declarations still feed P3's eligibility check and P3's parallel-mode cross-check. The combined guide update for S8.P1 must describe both modes explicitly.

**Note on master-only files:** Per CLAUDE.md, when any change affects system behavior (new guides, new workflow steps), assess whether CLAUDE.md, root README.md, and `scripts/initialization/RULES_FILE.template.md` require updates. Each implemented proposal should trigger this assessment before closing its SHAMT branch.

---

## Open Questions

**OQ1: Should EPIC_METRICS.md be committed to git?**
- Committed: Persists in history, visible in PRs, informs future agents
- Gitignored: Less commit noise, but lost after archival
Recommendation: Commit it — the data is worth preserving.

**OQ2: For P3 (S7/S8 parallelization), how do shared infrastructure files get handled?**
- Option A: Prohibit parallelization if any shared files exist (safest)
- Option B: Shared files are primary agent's responsibility only; secondaries submit a "shared changes needed" list
- Option C: Feature branches + merge at sync point (most flexible)
Recommendation: Start with Option A.

**OQ3: For P4 (S9.P4 scope), should the 5 new categories replace the 11 entirely, or should the 11 remain with explicit "skip if S7.P3 passed" logic per category?**
- Option A: Replace with 5 categories (clean break, simpler)
- Option B: Keep 11 but add skip logic (more nuanced, more complex)
Recommendation: Option A.

**OQ4: For P6 (S2.P1 gate), is S2.P2 (Cross-Feature Alignment) a sufficient safety net for skipped I2s?**
The main risk is inter-feature inconsistencies that I2 would catch but the gate misses. S2.P2 runs after all I3s complete and explicitly checks cross-feature alignment. This should be sufficient, but needs empirical validation from P1 data.

**OQ5: Should P5 (log compaction) wait for 2+ epics of P1 data before finalizing format?**
The overhead estimate (9 hours per 3-feature epic) is inferred. If real data shows this is an overestimate, compaction may not be worth its discipline risk. Recommendation: implement a pilot version of the compact format in the first P1-tracked epic, measure actual overhead, then finalize.

Pilot decision criteria: if actual overhead per loop is >5 min/loop on average (measured from P1 timing data), P5 full implementation proceeds. If actual overhead is <2 min/loop, P5 is de-prioritized (the verbose format is not a significant bottleneck). If the pilot reveals the compact format causes agents to miss issues (evidenced by issues appearing in sub-agent rounds that primary missed), P5 is rejected regardless of overhead.

**OQ6: For P10 (Discovery scope scaler), is user confirmation of the "Simple" classification worth the added gate?**
The gate is ~5 min. Savings are 45–75 min. Net positive if classification is accurate. The criteria are binary/objective, reducing agent self-classification bias.

**OQ7: For P1 (EPIC_METRICS.md), how do secondary agents report timing data?**
Secondary agents cannot write directly to EPIC_METRICS.md (write conflict risk). Resolved by design: secondary agents include start/end timestamps in their handoff packages. The primary agent consolidates these into EPIC_METRICS.md at sync points. The handoff package format should be updated to include timing fields.

**OQ8: Should P3 (S6/S7 parallelization) be a separate SHAMT design doc?**
P3 requires significant new guide authoring (2 new files, 5 modified guides) and has a hard data dependency on P1. It may be cleaner to track P3 as SHAMT-21 after P1 is implemented and data is collected. This doc can stand as the discovery and framing for that future work.

**OQ9: For P3 (parallel S6/S7), what is the abort/merge protocol if a dependency is discovered mid-parallel-S6?**
Eligibility check happens at S5 Gate 5, before secondary agents start. But mid-implementation a secondary agent may discover an unexpected dependency (e.g., Feature 02's implementation needs a class that Feature 01 is concurrently modifying). Options: (A) Secondary agent stops and reports dependency to primary via checkpoint; primary either serializes remaining work or coordinates a merge. (B) Secondary agent buffers the needed change as a "shared changes needed" item and continues; primary handles at sync point. This should be resolved in the s6_s7_parallel_protocol.md design.
Recommendation: Option A. Stopping and reporting is safer — buffering shared changes risks the secondary completing work that is then invalidated by a conflict resolution decision. Option A produces a clean checkpoint and keeps the primary in control of the dependency resolution.

---

**Last Updated:** 2026-03-29
