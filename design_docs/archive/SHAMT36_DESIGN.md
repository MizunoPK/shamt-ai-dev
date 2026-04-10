# SHAMT-36: S4 — Interface Contract Definition

**Status:** Implemented
**Created:** 2026-04-09
**Branch:** `feat/SHAMT-36`
**Validation Log:** [SHAMT36_VALIDATION_LOG.md](./SHAMT36_VALIDATION_LOG.md)

---

## Problem Statement

S4 was deprecated in SHAMT-6 because the original feature test-planning stage produced elaborate
pre-implementation test plans that went stale on first contact with real code. The deprecation was
correct — but it left a structural hole: S3 ends at Gate 4.5 and jumps directly to S5, skipping
an entire numbered stage. This causes two concrete problems:

**1. Cross-feature contract conflicts discovered too late.**
Each feature creates its implementation plan (S5) in isolation. S5-CA then catches interface
conflicts, shared-code conflicts, and data-flow mismatches *after* all that planning is done —
sometimes requiring plan reworks that cost another full validation loop. The root cause is that
features make assumptions about shared interfaces rather than planning against agreed contracts.

**2. Awkward numbering and naming throughout the guides.**
Gate 4.5 exists only because S4 doesn't. The EPIC_WORKFLOW_USAGE overview says "S4 deprecated".
The mandatory gates guide has an "S4: (Deprecated)" section. Reference cards point to archived
content. New users reading guides encounter confusing gaps. Stage reference cards exist for stages
1-3 and 5+ but the stage 4 slot is a redirect stub.

**Impact of not solving this:** S5-CA rework continues at its current rate (proportional to
integration complexity), and the guide system carries permanent cosmetic/structural debt from the
deprecation.

---

## Goals

1. Introduce a genuinely useful S4 stage that defines cross-feature interface contracts *before*
   per-feature implementation planning begins, reducing S5-CA conflict rate for integrated epics.
2. Keep overhead proportional: single-feature or non-integrated epics get a fast-skip path (5-10
   min), not a mandatory full process.
3. Restore contiguous stage numbering — S1 through S11 with no gaps or "(Deprecated)" stubs.
4. Rename Gate 4.5 to Gate 4 for conceptual cleanliness (Gate N gates entry to Stage N+1).
5. Wire S4 into the parallel work flow (primary runs S4 before activating secondary agents for S5).

---

## Detailed Design

### Proposal 1: S4 — Interface Contract Definition

**Description:**

After Gate 4 (formerly Gate 4.5 — epic plan approved), and before per-feature S5 planning begins,
the primary agent runs S4 to define all cross-feature interface contracts. A contract is any
shared technical boundary between two or more features: a function signature, a data schema, a
file format, an API shape, a shared configuration key.

**Full path (≥1 integration point identified in S2.P2):** ~30-45 minutes

1. **Review S2.P2 output** — read all Cross-Feature Alignment notes and identify every
   integration point flagged between features.
2. **Classify contracts by type** — function/method signatures, data structure schemas, file
   formats, shared constants, configuration keys, API endpoints.
3. **Define each contract** — for modifications to *existing* code: look up the current signature
   and record it (verify from actual source). For *new* code: define the agreed interface based
   on what the specs require, choosing the simplest form consistent with all consuming features.
4. **Identify producer/consumer relationships** — for each contract, which feature produces it
   (or modifies it) and which features consume it.
5. **Create `interface_contracts.md`** in the epic folder.
6. **Validation loop** — primary clean round + sub-agent confirmation.
7. **Proceed to S5** (serial) or trigger SP2 handoff (parallel).

**Fast-skip path (single-feature epic OR S2.P2 found zero integration points):** ~5-10 minutes

1. Document that no shared interfaces exist (with brief justification).
2. Create a minimal `interface_contracts.md` stating "No cross-feature contracts — proceed to S5".
3. No validation loop required.
4. Proceed to S5.

**Output:** `epic/interface_contracts.md` containing a contract registry table plus per-contract detail sections.

**Required fields per contract entry:**

| Field | Description |
|-------|-------------|
| `name` | Short identifier (e.g., `process_batch_results`) |
| `type` | One of: function signature, data schema, file format, shared constant, config key, API endpoint |
| `definition` | Full signature / schema / format spec — no TBD allowed |
| `producing feature(s)` | Which feature(s) create or modify this interface |
| `consuming feature(s)` | Which feature(s) call or read this interface |
| `source` | `existing: path/to/file.py:line_N` or `new` |
| `status` | `confirmed` (verified from source code) or `proposed` (new — not yet in codebase) |

**How S5 uses the output:**
- New prerequisite step at the start of S5 Phase 1: read `interface_contracts.md` and verify
  your feature's contracts appear in your plan. Reference contracts by name in implementation
  steps rather than re-defining the interface locally.

**How S5-CA uses the output:**
- Step 0 of S5-CA sync verification: check that all implementation plans reference contracts
  from `interface_contracts.md` rather than defining their own divergent versions.
- D2 (interface conflict) checks become targeted confirmation checks rather than discovery.

**No user gate at S4.** Contracts are technical derivations of specs the user already approved
(Gates 3 and 4). Adding a gate here would create overhead with no quality gain. Contracts surface
implicitly at Gate 5 — each feature's implementation plan references the contracts, so the user
sees them when approving implementation plans.

**Parallel mode impact:** Currently, SP2 (secondary agent activation) fires immediately after
Gate 4 approval. With S4, SP2 must wait until S4 is complete, because secondary agents need
`interface_contracts.md` before they can start S5. Primary runs S4 alone; secondaries have NOT
been activated yet during S4 — they are not waiting at a sync point, they simply haven't been
started. SP2 is what starts them, and SP2 now fires after S4 exits rather than immediately after
Gate 4 approval. No new sync point is introduced.

**Rationale:**
- The value is proportional to integration complexity: zero overhead for simple epics (fast-skip),
  meaningful conflict prevention for integrated multi-feature epics.
- Contracts are pulled from existing S2.P2 work — S4 is deriving implementation-level specifics
  from spec-level integration points already identified, not doing new discovery.
- The cost of defining a contract up-front is lower than the cost of a conflict found in S5-CA
  (which requires re-validating the affected implementation plan dimension).

**Alternatives considered:**

*Alternative A: Keep the gap, just fix the naming confusion.* Rename Gate 4.5 to Gate 4 and
clean up "(Deprecated)" references. Zero process change. Rejected because this solves only
problem #2 (naming/numbering) and not problem #1 (S5-CA rework).

*Alternative B: Move contract definition into S5 Phase 1 as a new step.* Have each feature
define its own side of the contracts during S5. Rejected because this recreates the problem —
features still plan in isolation, and conflicts are still caught post-hoc by S5-CA.

*Alternative C: Fold contract definition into S3.* Add a "technical contracts" step to S3.
Rejected because S3 already has a defined scope (epic test strategy + doc refinement +
approval); adding a third concern dilutes its focus and makes S3 heavier without a natural
division.

**Recommended approach:** Proposal 1 is the only proposal. There is no competing alternative
that addresses both problems without creating new issues.

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/guides/stages/s4/s4_interface_contracts.md` | CREATE | Main S4 guide (full path + fast-skip path + validation loop) |
| `.shamt/guides/reference/stage_4/stage_4_reference_card.md` | MODIFY | Replace deprecated content with new S4 reference card |
| `.shamt/guides/stages/s4/s4_feature_testing_strategy.md` | MODIFY | Update redirect stub: was "→ S5", now "→ s4_interface_contracts.md" |
| `.shamt/guides/stages/s3/s3_epic_planning_approval.md` | MODIFY | (1) "Next Stage" → S4 instead of S5; (2) Gate 4.5 → Gate 4; (3) remove "S4 is deprecated" note in S3.P3 |
| `.shamt/guides/stages/s5/s5_v2_validation_loop.md` | MODIFY | Add S4 to prerequisites; add step to read `interface_contracts.md` at start of Phase 1 |
| `.shamt/guides/stages/s5/s5_ca_cross_plan_alignment.md` | MODIFY | Step 0: add check that `interface_contracts.md` exists (fast-skip also creates it, so check is simply "file exists"); update D2 conflict notes |
| `.shamt/guides/parallel_work/s5_primary_agent_guide.md` | MODIFY | Phase 1 trigger: "After Gate 4 → run S4 → then SP2 handoff" (was "After Gate 4.5 → SP2 immediately") |
| `.shamt/guides/parallel_work/s5_parallel_protocol.md` | MODIFY | SP2 trigger: moves from Gate 4 approval to S4 completion; update protocol flow description |
| `.shamt/guides/EPIC_WORKFLOW_USAGE.md` | MODIFY | Update workflow overview line (remove "S4 deprecated" note); add S4 description to stage-by-stage section |
| `.shamt/guides/reference/mandatory_gates.md` | MODIFY | (1) Rename Gate 4.5 → Gate 4; (2) Replace "S4: (Deprecated)" section with "S4: 0 formal gates"; (3) Update summary statistics |
| `.shamt/guides/reference/critical_workflow_rules.md` | MODIFY | Update status line: remove "S4 deprecated" reference |

**Probable additional files** (contain "Gate 4.5" or "S4 deprecated" — verify during implementation):

| File | Status | Notes |
|------|--------|-------|
| `.shamt/guides/reference/stage_3/stage_3_reference_card.md` | INVESTIGATE | Likely references Gate 4.5; update to Gate 4 |
| `.shamt/guides/reference/stage_5/stage_5_reference_card.md` | INVESTIGATE | Likely references S4 deprecation in prerequisites |
| `.shamt/guides/reference/faq_troubleshooting.md` | INVESTIGATE | May mention S4 gap |
| `.shamt/guides/reference/glossary.md` | INVESTIGATE | May define Gate 4.5 |
| `.shamt/guides/stages/s2/s2_p1_spec_creation_refinement.md` | INVESTIGATE | May reference "Gate 4" (acceptance criteria) — rename to "Gate 3a" |
| `.shamt/guides/reference/stage_2/stage_2_reference_card.md` | INVESTIGATE | May reference "Gate 4" (acceptance criteria) — rename to "Gate 3a" |

---

## Implementation Plan

### Phase 1: Create S4 Main Guide

Create `.shamt/guides/stages/s4/s4_interface_contracts.md` with:
- [ ] Mandatory reading protocol (same structure as other stage guides)
- [ ] Forbidden shortcuts section
- [ ] Prerequisites checklist (S3 complete, Gate 4 passed, S2.P2 integration points available)
- [ ] Overview section (purpose, time estimates: full 30-45 min / fast-skip 5-10 min)
- [ ] Full-path workflow (Steps 1-6: S2.P2 review → classify → define → produce/consume mapping → create file → validation loop)
- [ ] Fast-skip path (single-feature / no integration points detected)
- [ ] Validation loop section (dimensions, exit criterion: primary clean round + sub-agent confirmation)
- [ ] `interface_contracts.md` format spec (required fields for each contract entry)
- [ ] Parallel mode note (primary runs S4; secondaries wait; SP2 fires after S4 exits)
- [ ] Exit criteria checklist
- [ ] "Next Stage" pointer: S5 (serial) / SP2 activation (parallel)

**S4 Validation Loop Dimensions (5):**
1. Contract Completeness — Every integration point from S2.P2 has a corresponding contract entry
2. Contract Specificity — No TBD fields; all signatures/schemas fully defined
3. Contract Correctness — Existing-code contracts verified from source (file:line cited); new contracts consistent with codebase patterns
4. Producer/Consumer Accuracy — Each contract correctly identifies which features produce vs. consume it
5. No Conflicting Definitions — No two contracts define the same interface differently

### Phase 2: Update S4 Reference Card and Redirect Stub

- [ ] Rewrite `.shamt/guides/reference/stage_4/stage_4_reference_card.md` as a new one-page summary (purpose, full vs. fast-skip decision, validation dimensions, exit criteria, next stage)
- [ ] Update `.shamt/guides/stages/s4/s4_feature_testing_strategy.md` to redirect to `s4_interface_contracts.md` instead of to S5

### Phase 3: Update S3 (Next-Stage Pointer and Gate Rename)

In `.shamt/guides/stages/s3/s3_epic_planning_approval.md`:
- [ ] "Next Stage" section: change destination from S5 to S4 (update READ/GOAL/ESTIMATE lines)
- [ ] S3.P3 header: change "Gate 4.5" → "Gate 4" in the section title and all references within the file
- [ ] Remove "Note: S4 is deprecated. Test scope decisions..." sentence from S3.P3

### Phase 4: Update S5 (Prerequisites and Phase 1 Step)

In `.shamt/guides/stages/s5/s5_v2_validation_loop.md`:
- [ ] Prerequisites checklist: add "S4 complete (`interface_contracts.md` exists in epic folder — both full-path and fast-skip create this file)"
- [ ] Phase 1 Step 0 (Test Scope Decision): add a sub-step: "Read `interface_contracts.md`. Verify that your feature's contracts (as producing or consuming feature) are accounted for in your planning notes."

### Phase 5: Update S5-CA (Contract Verification)

In `.shamt/guides/stages/s5/s5_ca_cross_plan_alignment.md`:
- [ ] Step 0 (Sync Verification): add `interface_contracts.md` to the verification checklist ("file exists" — both full-path and fast-skip paths create it, so presence is the only check needed)
- [ ] Step 1 (Pairwise Plan Comparison): add a preliminary note: "If `interface_contracts.md` contains actual contracts (not the fast-skip 'no contracts' stub), D2 and D5 checks should be verifications against those contracts, not discovery. Flag any plan that deviates from a contract as a conflict."

### Phase 6: Update Parallel Work Guides

In `.shamt/guides/parallel_work/s5_primary_agent_guide.md`:
- [ ] Phase 1 (currently "S3 Gate 4.5 Approval (SP2 Trigger)"): rename to "Gate 4 Approval + S4 Execution"
- [ ] Update the phase to: (a) receive Gate 4 approval; (b) run S4 solo; (c) then trigger SP2 handoff to secondaries
- [ ] Update all "Gate 4.5" references → "Gate 4" in this file

In `.shamt/guides/parallel_work/s5_parallel_protocol.md`:
- [ ] Update SP2 trigger description: "fires after S4 complete" instead of "fires after Gate 4.5 approval"
- [ ] Update all "Gate 4.5" references → "Gate 4" in this file

### Phase 7: Update Cross-Cutting Reference Files

- [ ] `.shamt/guides/EPIC_WORKFLOW_USAGE.md`: Update workflow overview line; add S4 to stage-by-stage section
- [ ] `.shamt/guides/reference/mandatory_gates.md`: (1) Rename informal "Gate 4" (S2 acceptance criteria, embedded in Gate 3) → "Gate 3a" throughout; (2) rename Gate 4.5 → Gate 4 throughout; (3) replace "S4: (Deprecated)" section with "S4: No Formal Gates — Interface Contract Definition runs between Gate 4 and Gate 5"; (4) update summary statistics
- [ ] `.shamt/guides/reference/critical_workflow_rules.md`: Update status line
- [ ] Investigate and update probable additional files from the "probable" table above:
  - Grep for `"Gate 4\.5"` across all guides → rename to Gate 4
  - Grep for `"S4.*deprecated"` and `"deprecated.*S4"` → update to reflect S4 is active
  - Grep for `"Gate 4"` in S2-related files → identify informal acceptance-criteria Gate 4 references and rename to Gate 3a

### Phase 8: Guide Audit

- [ ] Run full guide audit on `.shamt/guides/` tree (3 consecutive clean rounds per CLAUDE.md audit rules)
- [ ] Confirm no remaining "Gate 4.5" references (except in archive)
- [ ] Confirm no remaining "S4 is deprecated" references (except in archive)

---

## Validation Strategy

- **Design doc validation:** 7-dimension validation loop (primary clean round + 2 independent sub-agent confirmations)
- **Implementation validation:** 5-dimension validation loop after all phases complete
- **Guide audit:** 3 consecutive clean rounds on full `.shamt/guides/` tree after implementation
- **Success criteria:**
  - `interface_contracts.md` format is specific enough to plan against (no TBD fields allowed)
  - Fast-skip path is unambiguously triggered (clear decision criterion: single-feature OR S2.P2 found zero integration points)
  - Gate 4 is the only name for what was Gate 4.5 — zero remaining "Gate 4.5" references outside `archive/`
  - S5 prerequisites clearly require S4 completion
  - Parallel work guides correctly delay SP2 until after S4 exits

---

## Open Questions

1. ~~**Gate 4 numbering conflict:**~~ **Resolved.** Rename the informal S2 embedded gate (acceptance criteria, currently called "Gate 4" in mandatory_gates.md) to "Gate 3a" first, then rename Gate 4.5 → Gate 4. Phase 7 implementation must include this rename in mandatory_gates.md and any other file that references the informal "Gate 4".

2. **S5 Step 0 impact:** S5 Step 0 is currently the "Test Scope Decision" (determines testing approach A/B/C/D per feature). The proposed S4 prerequisite step would be added alongside Step 0, not replacing it. Should this be Step 0a (sub-step) or a new named step before Step 0? Propose sub-step to avoid renumbering S5's other steps.

3. **interface_contracts.md format strictness:** Should the format require a specific schema (table vs. freeform sections vs. structured YAML-like blocks)? Stricter format means easier machine-readable validation but more rigid for unusual contract types. Propose a markdown table for the contract registry + freeform detail sections per contract (structured enough to validate, flexible enough for edge cases).

---

## Risks & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| S4 overhead exceeds benefit for typical single-feature epics | Medium | Low | Fast-skip path requires only 5-10 min; clear decision criterion prevents bloat |
| "Gate 4.5" references missed during implementation (guide audit catches them) | Medium | Low | Phase 7 grep pass specifically for "Gate 4.5" and "S4 deprecated" |
| Parallel work timing change (S4 before SP2) disrupts existing workflows | Low | Medium | Only affects parallel-mode epics; change is an extension of existing flow, not a restructure |
| Gate 4 numbering conflict with informal Gate 4 in mandatory_gates.md | Low | Low | Resolved: informal S2 "Gate 4" (acceptance criteria) renamed to Gate 3a before Gate 4.5 → Gate 4 rename |
| S4 contracts become stale if specs change during S5 planning | Low | Low | `interface_contracts.md` is a living document through S5-CA: if a spec changes during S5 and affects a contract, the agent discovering the change updates the file directly. S5-CA's conflict check acts as a backstop. The contracts document is frozen (no further edits) after S5-CA exits. |

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-09 | Initial draft created |
| 2026-04-09 | Validated — 2 rounds, 7 issues fixed (2 HIGH, 5 MEDIUM), both sub-agents confirmed |
