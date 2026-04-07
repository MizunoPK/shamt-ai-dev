# S7/S9 Code Review Variant — Fresh Sub-Agent Review Pattern

**Purpose:** Documents how S7.P3 (Feature PR Review) and S9.P4 (Epic PR Review) use the code review framework with fresh sub-agent pattern.

**Key Difference from Formal Code Review:** S7/S9 reviews skip overview.md creation and add Dimension 13 (Implementation Fidelity) to validate implementation matches validated plans and specs.

---

## When to Use This Variant

**Use this variant when:**
- **S7.P3 (Final Review):** Feature implementation complete, ready for PR-level review before cross-feature alignment
- **S9.P4 (Epic Final Review):** All epic features complete, ready for final epic-level review before cleanup

**Do NOT use this variant for:**
- **Formal code reviews:** External PRs from other teams/contributors (use standard workflow with overview.md)
- **S7.P2 or S9.P2:** QC validation loops (use validation_loop_qc protocols, not code review)

---

## Differences from Formal Code Review

| Aspect | Formal Code Review | S7/S9 Variant |
|--------|-------------------|---------------|
| **Overview.md** | Required (Steps 3-4) | **Skipped** (saves ~20-30% tokens) |
| **Dimensions** | 12 (7 master + 5 code-review-specific) | **13** (7 master + 6 code-review-specific including Implementation Fidelity) |
| **Step Sequence** | 1 → 2 → 3 → 4 → 5 → 6 → 7 | 1 → 2 → **5** → 6 → 7 (skip 3-4) |
| **Context** | External PR (no implementation plans) | Internal Shamt feature/epic (has validated plans and specs) |
| **Reviewer** | Fresh sub-agent (Opus) | Fresh sub-agent (Opus) |
| **Scope** | All code quality concerns | **S7:** Feature scope / **S9:** Epic scope (cross-feature concerns) |

---

## Fresh Sub-Agent Pattern

**Why fresh sub-agent?**
- **Zero implementation bias:** Sub-agent has no memory of design decisions, shortcuts, or assumptions made during implementation
- **True code review perspective:** Reviews code as written, not as intended
- **Catches implementation drift:** Validates actual implementation matches validated plans

**Pattern:**
1. **Primary agent** (who implemented the code) spawns fresh **sub-agent** (Opus)
2. **Sub-agent** runs code review workflow with no prior context
3. **Sub-agent** produces `review_v1.md` with severity-tagged comments
4. **Primary agent** addresses each comment systematically

---

## Step-by-Step Workflow

### Step 1: Primary Agent Spawns Fresh Sub-Agent

**Primary agent action:** Use Task tool to spawn Opus sub-agent with code review prompt.

**Task Tool Example (S7.P3 - Feature Review):**

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">opus</parameter>
  <parameter name="description">Run fresh code review on feature branch</parameter>
  <parameter name="prompt">You are a fresh code reviewer with ZERO prior context on this feature implementation.

**Context:**
- **Branch:** {feature_branch_name}
- **Review Type:** S7.P3 Feature PR Review
- **Scope:** Feature-level code quality (not epic-level concerns)
- **Implementation Plan:** Available at {path_to_implementation_plan}
- **Spec File:** Available at {path_to_spec_file}

**Your Task:**
Run the code review workflow against this feature branch using the **S7/S9 variant**:

1. **Skip Steps 3-4** (overview.md creation) — not needed for internal reviews
2. Follow Steps 1, 2, 5, 6, 7:
   - Step 1: Access branch (read-only git commands)
   - Step 2: Create output directory
   - Step 5: Determine review version (review_v1.md, review_v2.md, etc.)
   - Step 6: Write review_vN.md (12 review categories, severity-tagged comments)
   - Step 7: Run validation loop (13 dimensions including Implementation Fidelity)

3. **Check all 13 dimensions** (7 master + 6 code-review-specific):
   - Dimensions 1-12: Standard code review dimensions
   - **Dimension 13 (Implementation Fidelity):** Verify every proposal in implementation plan has corresponding code; all spec requirements addressed; no scope creep; no missing features

4. **Review Categories:** Check all 12 categories:
   - Correctness, Code Quality, Comments & Documentation, Code Organization, Testing, Security, Performance, Error Handling, Architecture & Design, Backwards Compatibility, Scope & Changes, Context & Intent

5. **Output:** `.shamt/code_reviews/{sanitized_branch}/review_v1.md` with copy-paste-ready comments

**Guide Reference:** `.shamt/guides/code_review/code_review_workflow.md`
**Variant Guide:** `.shamt/guides/code_review/s7_s9_code_review_variant.md`
  </parameter>
</invoke>
```

**Task Tool Example (S9.P4 - Epic Review):**

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">opus</parameter>
  <parameter name="description">Run fresh code review on epic branch</parameter>
  <parameter name="prompt">You are a fresh code reviewer with ZERO prior context on this epic implementation.

**Context:**
- **Branch:** {epic_branch_name}
- **Review Type:** S9.P4 Epic PR Review
- **Scope:** Epic-level concerns (cross-feature integration, architectural coherence, NOT per-feature code quality)
- **Epic Implementation Plans:** Available at {path_to_epic_folder}/features/
- **Epic Spec Files:** Available at {path_to_epic_folder}/features/

**Your Task:**
Run the code review workflow against this epic branch using the **S7/S9 variant** with **epic-scope focus**:

1. **Skip Steps 3-4** (overview.md creation)
2. Follow Steps 1, 2, 5, 6, 7 (13 dimensions)

3. **Epic-Scope Focus:**
   - **Cross-feature integration:** Do features work together correctly?
   - **Architectural coherence:** Is design consistent across features?
   - **Epic requirements coverage:** Are all original epic goals satisfied?
   - **Emergent patterns:** Are there inconsistencies only visible at full-epic scale?
   - **NOT per-feature code quality:** S7.P3 already reviewed each feature individually

4. **Review Categories:** Check all 12 categories at **epic scope**:
   - Focus on cross-feature concerns, not individual feature quality

5. **Dimension 13 (Implementation Fidelity):** Check at **epic scope**:
   - Verify all feature implementation plans collectively satisfy epic goals
   - Verify no epic-level requirements missed
   - Verify no scope creep at epic level

**Guide Reference:** `.shamt/guides/code_review/code_review_workflow.md`
**Variant Guide:** `.shamt/guides/code_review/s7_s9_code_review_variant.md`
  </parameter>
</invoke>
```

---

### Step 2: Sub-Agent Executes Code Review

**Sub-agent executes:**
- Step 1: Access branch (read-only)
- Step 2: Create output directory (`.shamt/code_reviews/{sanitized_branch}/`)
- Step 5: Determine review version (review_v1.md, v2.md, etc.)
- Step 6: Write review_vN.md with all findings
- Step 7: Run validation loop (13 dimensions) until primary clean round + sub-agent confirmation

**Output:** `review_v1.md` at `.shamt/code_reviews/{sanitized_branch}/review_v1.md`

---

### Step 3: Primary Agent Reads Review

**Primary agent action:** Read the completed review file.

```bash
# Read the review file
Read .shamt/code_reviews/{sanitized_branch}/review_v1.md
```

**Review structure:**
- **Header:** Branch, date, file count, commit range
- **Comments by Category:** Grouped by 12 review categories
- **Comments by Severity:** BLOCKING → CONCERN → SUGGESTION → NITPICK
- **Format:** Each comment has file path, line number, issue description, suggested fix

---

### Step 4: Primary Agent Addresses Comments

**Protocol (per Design Decision 3):**

**BLOCKING comments:**
- **Action:** Fix immediately
- **Why:** Correctness bugs, security issues, data-loss risks
- **Cannot proceed until:** All BLOCKING comments resolved

**CONCERN comments:**
- **Action:** Fix immediately
- **Why:** Real quality, performance, or maintainability problems
- **Cannot proceed until:** All CONCERN comments resolved

**SUGGESTION comments:**
- **Action:** Walk through with user one-by-one
- **Present to user:** Context + comment + suggested fix
- **User decides:** Fix now / Document as "acknowledged, won't fix" / Escalate for discussion
- **Why:** Optional improvements where developer judgment applies

**NITPICK comments:**
- **Action:** Walk through with user one-by-one
- **Present to user:** Context + comment + suggested fix
- **User decides:** Fix now / Document as "acknowledged, won't fix" / Escalate for discussion
- **Why:** Minor style/preference where author discretion applies

**Comment Response Template:**

```markdown
## Comment Response Log

### BLOCKING Comments (Must Fix)
1. **[File:Line]** {Issue description}
   - **Status:** ✅ Fixed | ❌ Unresolved
   - **Action Taken:** {What was done to fix}

### CONCERN Comments (Must Fix)
1. **[File:Line]** {Issue description}
   - **Status:** ✅ Fixed | ❌ Unresolved
   - **Action Taken:** {What was done to fix}

### SUGGESTION Comments (User Review)
1. **[File:Line]** {Issue description}
   - **Presented to User:** {Date}
   - **User Decision:** Fix / Document / Escalate
   - **Status:** ✅ Addressed
   - **Action Taken:** {What was done}

### NITPICK Comments (User Review)
1. **[File:Line]** {Issue description}
   - **Presented to User:** {Date}
   - **User Decision:** Fix / Document / Escalate
   - **Status:** ✅ Addressed
   - **Action Taken:** {What was done}
```

---

## Checkpoint: All Comments Addressed

**Before declaring S7.P3 or S9.P4 complete, verify:**

- [ ] All BLOCKING comments resolved (code fixed)
- [ ] All CONCERN comments resolved (code fixed)
- [ ] All SUGGESTION comments addressed (fixed OR documented with user approval)
- [ ] All NITPICK comments addressed (fixed OR documented with user approval)
- [ ] Comment Response Log complete
- [ ] All code changes committed

**If ANY item unchecked:** Return to Step 4 and complete remaining comments.

---

## Scope Distinctions

### S7.P3 — Feature Scope

**Focus:**
- Feature-level code quality
- Feature requirements satisfaction
- Feature implementation plan adherence

**NOT in scope:**
- Cross-feature integration (handled in S8 and S9)
- Epic-level concerns (handled in S9.P4)

### S9.P4 — Epic Scope

**Focus:**
- Cross-feature integration correctness
- Architectural coherence across features
- Epic requirements coverage (original epic goals)
- Emergent quality patterns visible only at full-epic scale

**NOT in scope:**
- Per-feature code quality (already handled in S7.P3 for each feature)
- Individual feature correctness (already validated)

---

## Why Skip Overview.md?

**Rationale:**
1. **Token efficiency:** Overview creation + validation saves ~20-30% of review tokens
2. **Not needed for internal context:** Primary agent already has full context of implementation
3. **Review comments are sufficient:** `review_vN.md` is the actionable artifact — overview is supplementary
4. **Faster review cycle:** Fewer validation rounds (skip 2 validation loops for overview)

**What's lost:**
- ELI5 summary (not critical for internal reviews)
- "What/Why/How" narrative (already captured in specs and implementation plans)

**What's preserved:**
- All 12 review categories checked
- All 13 dimensions validated (including Implementation Fidelity)
- Copy-paste-ready PR comments
- Systematic comment addressing

---

## Common Mistakes to Avoid

**Mistake 1: Primary agent reviews own code**
- ❌ Primary agent runs review without sub-agent
- ✅ Always spawn fresh Opus sub-agent (zero implementation bias)

**Mistake 2: Skipping Dimension 13**
- ❌ Only check dimensions 1-12 for S7/S9 reviews
- ✅ Check all 13 dimensions (Implementation Fidelity is mandatory for S7/S9)

**Mistake 3: Rubber-stamping SUGGESTION/NITPICK**
- ❌ Auto-document all SUGGESTION/NITPICK as "won't fix" without user input
- ✅ Walk through with user one-by-one for judgment

**Mistake 4: Mixing feature and epic scope**
- ❌ S9.P4 reviews per-feature code quality
- ✅ S9.P4 focuses on epic-level concerns only (cross-feature, architecture)

**Mistake 5: Creating overview.md**
- ❌ Follow full formal workflow including overview creation
- ✅ Skip Steps 3-4 (overview.md), proceed Step 1 → 2 → 5 → 6 → 7

---

## Summary

**S7/S9 Code Review Variant:**
- Fresh sub-agent (Opus) reviews code with zero implementation bias
- Skip overview.md (saves ~20-30% tokens)
- Check 13 dimensions (add Implementation Fidelity)
- Primary agent addresses all comments systematically
- BLOCKING/CONCERN must fix; SUGGESTION/NITPICK walk through with user
- S7 = feature scope; S9 = epic scope (cross-feature concerns)

**Key Benefits:**
- Eliminates implementation bias
- Validates plan adherence (Dimension 13)
- Produces actionable PR comments
- Unified framework across all Shamt PR reviews
- Token-efficient (skip overview.md)

---

**See Also:**
- `code_review/code_review_workflow.md` — Full code review workflow
- `stages/s7/s7_p3_final_review.md` — S7.P3 integration
- `stages/s9/s9_p4_epic_final_review.md` — S9.P4 integration
