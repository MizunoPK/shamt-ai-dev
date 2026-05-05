# Templates Index

**Last Updated:** 2026-05-04
**Location:** `.shamt/guides/templates/`

---

## Quick Reference

**When you need a template, find it here by stage or file type.**

---

## Templates by Stage

### Pre-S1: Epic Request Creation

| Template | Filename | Use When |
|----------|----------|----------|
| [Epic Request](#epic-request) | `EPIC_REQUEST_TEMPLATE.md` | User asks to create an epic request BEFORE starting S1 |

**⚠️ IMPORTANT:** Epic request files are created in `.shamt/epics/requests/` and left there until user explicitly initiates S1. Do NOT create SHAMT-{N} folders when writing epic requests.

### S1: Epic Planning

| Template | Filename | Use When |
|----------|----------|----------|
| [Epic README](#epic-readme) | `epic_readme_template.md` | Creating epic folder structure |
| [Discovery](#discovery) | `discovery_template.md` | Creating DISCOVERY.md during Discovery Phase (Step 3) |
| [Epic Ticket](#epic-ticket) | `epic_ticket_template.md` | Validating epic-level understanding (Step 4.6) |
| [Epic Smoke Test Plan](#epic-smoke-test-plan) | `epic_smoke_test_plan_template.md` | Creating initial epic test plan |
| [Epic Lessons Learned](#epic-lessons-learned) | `epic_lessons_learned_template.md` | Creating epic-level lessons document |

### S2: Feature Deep Dive

| Template | Filename | Use When |
|----------|----------|----------|
| [Feature README](#feature-readme) | `feature_readme_template.md` | Creating feature folder |
| [Feature Research Notes](#feature-research-notes) | `FEATURE_RESEARCH_NOTES_template.md` | Recording feature-level research during Discovery Phase (S2.P1.I1) |
| [Spec Summary](#spec-summary) | `spec_summary_template.md` | Validating feature understanding (S2.P1.I3) |
| [Feature Spec](#feature-spec) | `feature_spec_template.md` | Writing detailed feature specification |
| [Feature Checklist](#feature-checklist) | `feature_checklist_template.md` | Tracking feature decisions |
| [Feature Lessons Learned](#feature-lessons-learned) | `feature_lessons_learned_template.md` | Creating feature-level lessons document |

### S2.P2: Cross-Feature Alignment

| Template | Filename | Use When |
|----------|----------|----------|
| [Cross-Feature Alignment](#cross-feature-alignment) | `cross_feature_sanity_check_template.md` | Comparing features for conflicts or duplications during S2.P2 (Cross-Feature Alignment) |

### S4: Interface Contract Definition

| Template | Filename | Use When |
|----------|----------|----------|
| [Feature Test Strategy](#feature-test-strategy) | `feature_test_strategy_template.md` | Options C/D only — algorithmic function test planning at S5 Step 0 |

### S5: Implementation Planning

| Template | Filename | Use When |
|----------|----------|----------|
| [Implementation Plan](#implementation-plan) | `implementation_plan_template.md` | Creating user-approved build guide through S5 v2 Validation Loop |
| [Validation Loop Log (S5)](#validation-loop-log-s5) | `VALIDATION_LOOP_LOG_S5_template.md` | Tracking S5 implementation planning validation loop progress |
| [Implementation Plan Validation Log](#implementation-plan-validation-log) | `implementation_plan_validation_log_template.md` | Tracking 9-dimension validation rounds for an implementation plan |

### S6: Implementation Execution

| Template | Filename | Use When |
|----------|----------|----------|
| [Implementation Checklist](#implementation-checklist) | `implementation_checklist_template.md` | Tracking progress during implementation |

### S7: Testing & Review

| Template | Filename | Use When |
|----------|----------|----------|
| [PR Review Issues](#pr-review-issues) | `pr_review_issues_template.md` | Tracking issues found during PR review |

### S10: Final Changes & Merge

| Template | Filename | Use When |
|----------|----------|----------|
| [Guide Update Proposal](#guide-update-proposal) | `guide_update_proposal_template.md` | Proposing guide improvements discovered during epic work (SHAMT-{N} format) |
| [PR Comment Resolution](#pr-comment-resolution) | `comment_resolution_template.md` | Creating pr_comment_resolution.md in epic folder (S10 Step 5, user-triggered) |
| [PR Review Issues](#pr-review-issues) | `pr_review_issues_template.md` | Tracking issues found during PR review (also used in S7) |

### Parallel Work

| Template | Filename | Use When |
|----------|----------|----------|
| [Handoff Package (S2)](#handoff-package-s2) | `handoff_package_s2_template.md` | Creating handoff package for secondary agents in parallel S2 work |
| [Handoff Package (S5)](#handoff-package-s5) | `handoff_package_s5_template.md` | Creating handoff package for secondary agents in parallel S5 work |
| [Feature Status](#feature-status) | `feature_status_template.txt` | STATUS file format for parallel work coordination (each feature folder) |

### Debugging

| Template | Filename | Use When |
|----------|----------|----------|
| [Debugging Guide Update Recommendations](#debugging-guide-updates) | `debugging_guide_update_recommendations_template.md` | Documenting guide update recommendations from debugging sessions |

### General / Multi-Stage

| Template | Filename | Use When |
|----------|----------|----------|
| [Validation Loop Log](#validation-loop-log) | `VALIDATION_LOOP_LOG_template.md` | Tracking validation loop progress for any stage |

### Master Dev Workflow

| Template | Filename | Use When |
|----------|----------|----------|
| [Design Doc](#design-doc) | `design_doc_template.md` | Creating SHAMT-{N} design docs in `design_docs/active/` for master guide changes (master repo only) |

### Bug Fix Workflow

| Template | Filename | Use When |
|----------|----------|----------|
| [Bug Fix Notes](#bug-fix-notes) | `bugfix_notes_template.md` | Creating bug fix documentation |

---

## Templates by File Type

### Epic-Level Files

#### Epic README
- **File:** `epic_readme_template.md`
- **Created:** S1
- **Purpose:** Central epic tracking (Agent Status, progress, checklists)
- **Size:** ~495 lines
- **When to use:** Creating epic folder in S1

#### Discovery
- **File:** `discovery_template.md`
- **Created:** S1.P3 (Discovery Phase)
- **Purpose:** Epic-level source of truth for problem understanding, solution approach, and feature breakdown rationale
- **Size:** ~386 lines
- **When to use:** S1 Step 3 (Discovery Phase initialization)
- **Critical:** Becomes reference document for all feature specs after user approval

#### Epic Ticket
- **File:** `epic_ticket_template.md`
- **Created:** S1 - Step 3.6
- **Purpose:** User-validated epic-level outcomes
- **Size:** ~140 lines
- **When to use:** After feature breakdown, before folder creation
- **Critical:** Immutable after user validation

#### Epic Smoke Test Plan
- **File:** `epic_smoke_test_plan_template.md`
- **Created:** S1
- **Updated:** S3.P1, S8.P2 (after each feature)
- **Purpose:** Epic end-to-end testing scenarios
- **Size:** ~280 lines
- **When to use:** S1 initial creation, S3.P1 refinement

#### Epic Lessons Learned
- **File:** `epic_lessons_learned_template.md`
- **Created:** S1
- **Updated:** Throughout all stages
- **Purpose:** Cross-feature insights and guide improvements
- **Size:** ~375 lines
- **When to use:** S1 creation, updated after each stage

---

### Feature-Level Files

#### Feature README
- **File:** `feature_readme_template.md`
- **Created:** S1 or S2
- **Updated:** Throughout S2-S8
- **Purpose:** Central feature tracking (Agent Status, progress)
- **Size:** ~165 lines
- **When to use:** Creating feature folder

#### Spec Summary
- **File:** `spec_summary_template.md`
- **Created:** S2.P1.I3
- **Purpose:** User-validated feature-level outcomes
- **Size:** ~200 lines
- **When to use:** After multi-phase research, before implementation
- **Critical:** Immutable after user validation

#### Feature Spec
- **File:** `feature_spec_template.md`
- **Created:** S1 Step 5 (seeded), S2 (completed)
- **Purpose:** PRIMARY specification for implementation. Includes Discovery Context section.
- **Size:** ~370 lines
- **When to use:** Seeded with Discovery Context in S1, completed in S2
- **Critical:** Must start with Discovery Context section referencing DISCOVERY.md

#### Feature Checklist
- **File:** `feature_checklist_template.md`
- **Created:** S2
- **Purpose:** Track resolved vs pending decisions
- **Size:** ~255 lines
- **When to use:** S2 deep dive decision tracking

#### Implementation Plan
- **File:** `implementation_plan_template.md`
- **Created:** S5 (accumulated through S5 v2 Validation Loop)
- **Purpose:** User-approved build guide with tasks, tests, edge cases, matrices
- **Size:** ~55 lines (scaffold; expands to ~300+ lines as the plan is built during S5)
- **When to use:** Throughout S5 v2 — draft in Phase 1, refined through Validation Loop (user approves after primary clean round + sub-agent confirmation)

#### Implementation Checklist
- **File:** `implementation_checklist_template.md`
- **Created:** S6 (start of implementation)
- **Purpose:** Live progress tracking with simple checkboxes
- **Size:** ~160 lines
- **When to use:** Create at S6 start, update as tasks complete

#### Feature Lessons Learned
- **File:** `feature_lessons_learned_template.md`
- **Created:** S2
- **Updated:** After Stages S5, S6, S7
- **Purpose:** Feature-specific development insights
- **Size:** ~190 lines
- **When to use:** S2 creation, updated after each substage

---

### Bug Fix Files

#### Bug Fix Notes
- **File:** `bugfix_notes_template.md`
- **Created:** When bug discovered (any stage)
- **Purpose:** User-verified bug description and fix plan
- **Size:** ~87 lines
- **When to use:** Creating bug fix folder during any stage

---

### Additional Workflow Files

#### Feature Research Notes
- **File:** `FEATURE_RESEARCH_NOTES_template.md`
- **Created:** S2.P1.I1 (Feature-Level Discovery)
- **Purpose:** Recording feature-level research findings during the discovery phase; source of truth for research before spec writing
- **Size:** ~367 lines
- **When to use:** S2.P1.I1 discovery phase for each feature

#### Feature Test Strategy
- **File:** `feature_test_strategy_template.md`
- **Created:** S5 Step 0 (Test Scope Decision)
- **Purpose:** Options C/D only — planning unit tests for algorithmic functions before implementation
- **Size:** ~259 lines
- **When to use:** S5 Step 0 if Testing Approach is C or D

#### Cross-Feature Alignment
- **File:** `cross_feature_sanity_check_template.md`
- **Created:** S2.P2
- **Purpose:** Comparing features for conflicts, duplications, or integration gaps during S2.P2 cross-feature alignment
- **Size:** ~75 lines
- **When to use:** S2.P2 (Cross-Feature Alignment) — pairwise comparison step

#### Validation Loop Log (S5)
- **File:** `VALIDATION_LOOP_LOG_S5_template.md`
- **Created:** S5 (start of Validation Loop)
- **Purpose:** Tracking S5 implementation planning validation loop progress across all 9 dimensions until primary clean round + sub-agent confirmation
- **Size:** ~410 lines
- **When to use:** S5 Validation Loop initialization

#### Validation Loop Log
- **File:** `VALIDATION_LOOP_LOG_template.md`
- **Created:** Any stage requiring a validation loop
- **Purpose:** General-purpose validation loop tracking for QC rounds in any stage
- **Size:** ~180 lines
- **When to use:** Any stage validation loop (non-S5)

#### Implementation Plan Validation Log
- **File:** `implementation_plan_validation_log_template.md`
- **Created:** S5 (start of Implementation Plan validation)
- **Purpose:** Tracking validation rounds for an implementation plan's 9-dimension validation loop (issues, fixes, sub-agent confirmations)
- **Size:** ~195 lines
- **When to use:** S5 implementation plan validation loop

#### Design Doc
- **File:** `design_doc_template.md`
- **Created:** Master dev workflow (large changes requiring planning)
- **Purpose:** SHAMT-{N} design doc capturing problem statement, goals, proposals, implementation plan, and validation strategy for master guide improvements
- **Size:** ~110 lines
- **When to use:** Master repo only — when starting a SHAMT-{N} design doc in `design_docs/active/`

#### PR Review Issues
- **File:** `pr_review_issues_template.md`
- **Created:** S7 or S10 PR review
- **Purpose:** Tracking issues found during PR review with priority classification (P0/P1/P2)
- **Size:** ~175 lines
- **When to use:** S7.P3 Final Review or S10 PR creation

#### Guide Update Proposal
- **File:** `guide_update_proposal_template.md`
- **Created:** S11 (S11.P1 Guide Updates)
- **Purpose:** Proposing guide improvements discovered during epic work, using SHAMT-{N} numbering format
- **Size:** ~257 lines
- **When to use:** S11.P1 when creating guide update proposals

#### PR Comment Resolution
- **File:** `comment_resolution_template.md`
- **Created:** S10 Step 5 (user-triggered, after PR receives review comments)
- **Purpose:** Structured tracking of PR review comments, resolutions, and commit references
- **Size:** ~60 lines
- **When to use:** User directs agent to process PR review comments after PR is created

#### Debugging Guide Update Recommendations
- **File:** `debugging_guide_update_recommendations_template.md`
- **Created:** During or after debugging sessions
- **Purpose:** Documenting guide update recommendations with P0/P1/P2 priority classification from debugging insights
- **Size:** ~280 lines
- **When to use:** Debugging Protocol Step 5 (Root Cause Analysis) when guide improvements are identified

#### Handoff Package (S2)
- **File:** `handoff_package_s2_template.md`
- **Created:** S2 parallel work setup (Primary Agent)
- **Purpose:** Handoff package for secondary agents in parallel S2 work; contains context, epic info, and feature assignment
- **Size:** ~242 lines
- **When to use:** Parallel S2 work — Primary Agent creates one per secondary agent

#### Handoff Package (S5)
- **File:** `handoff_package_s5_template.md`
- **Created:** S5 parallel work setup (Primary Agent, SP2 action)
- **Purpose:** Handoff package for secondary agents in parallel S5 work; contains context, sync point instructions, and milestone checkpoint requirements
- **Size:** ~197 lines
- **When to use:** Parallel S5 work — Primary Agent creates one per secondary agent after S3 Gate 4 approval (post-S4)

#### Feature Status
- **File:** `feature_status_template.txt`
- **Created:** Parallel work setup (Primary and Secondary Agents)
- **Purpose:** Plain-text STATUS file format for parallel work coordination; placed in each feature folder to communicate progress between agents
- **Size:** ~10 lines
- **When to use:** Parallel S2 work — every agent creates a STATUS file for their assigned feature(s); see `parallel_work/README.md`

---

## How to Use Templates

### Step 1: Find the Right Template

Use the tables above to find the template you need based on:
- **Stage:** What stage are you in?
- **File Type:** What type of document do you need to create?

### Step 2: Read the Template

```bash
Read .shamt/guides/templates/{template_name}.md
```

### Step 3: Copy and Fill In

1. Copy the markdown content from the `## Template` section
2. Replace all `{placeholders}` with actual values
3. Create the file in the correct location (see template header)

### Step 4: Verify Completeness

- Check that NO `{placeholders}` remain
- Verify all required sections are filled
- Update status fields appropriately

---

## Template Metadata Quick Reference

| Template | Lines | Immutable | User Validation Required |
|----------|-------|-----------|-------------------------|
| Epic Request | ~187 | No | No |
| Epic README | ~495 | No | No |
| Discovery | ~386 | Yes (after approval)* | Yes (S1.P3) |
| Epic Ticket | ~140 | Yes (after validation) | Yes (S1) |
| Epic Smoke Test Plan | ~280 | No | No |
| Epic Lessons Learned | ~375 | No | No |
| Feature README | ~165 | No | No |
| Spec Summary | ~200 | Yes (after validation) | Yes (S2) |
| Feature Spec | ~370 | No | No |
| Feature Checklist | ~255 | No | No |
| Implementation Plan | ~55 (scaffold) | Yes (after validation) | Yes (S5) |
| Implementation Checklist | ~160 | No | No |
| Feature Lessons Learned | ~190 | No | No |
| Bug Fix Notes | ~87 | Yes (after validation) | Yes |
| Feature Research Notes | ~367 | No | No |
| Feature Test Strategy | ~259 | No | No |
| Handoff Package (S2) | ~242 | No | No |
| Handoff Package (S5) | ~197 | No | No |
| Feature Status | ~10 | No | No |
| Validation Loop Log | ~180 | No | No |
| Validation Loop Log (S5) | ~410 | No | No |
| Implementation Plan Validation Log | ~195 | No | No |
| PR Review Issues | ~175 | No | No |
| PR Comment Resolution | ~60 | No | No |
| Guide Update Proposal | ~257 | No | No |
| Debugging Guide Updates | ~280 | No | No |
| Cross-Feature Alignment | ~75 | No | No |
| Design Doc | ~110 | No | No |

**Immutable templates:** Epic Ticket, Spec Summary, Implementation Plan, Bug Fix Notes (after user validation)

*Discovery is immutable after approval, but can be updated if something is found incorrect or outdated during later stages.

---

## Common Template Workflows

### Starting a New Epic (S1)

1. Create epic folder
2. Use **Epic README** template
3. Use **Discovery** template (S1.P3 - mandatory Discovery Phase)
4. Complete Discovery Loop (exit after primary clean round + sub-agent confirmation with zero issues/gaps)
5. Get user approval of Discovery findings
6. Create feature breakdown (based on Discovery)
7. Use **Epic Ticket** template (get user validation)
8. Create feature folders (seed spec.md with Discovery Context)
9. Use **Epic Smoke Test Plan** template
10. Use **Epic Lessons Learned** template

### Starting a New Feature (S2)

1. ✅ Use **Feature README** template
2. ✅ Research codebase (multi-phase)
3. ✅ Use **Feature Spec** template
4. ✅ Use **Spec Summary** template (get user validation)
5. ✅ Use **Feature Checklist** template
6. ✅ Use **Feature Lessons Learned** template

### Implementing a Feature (S5-S8)

1. ✅ Create **Implementation Plan** (S5 - grows through S5 v2 Validation Loop)
2. ✅ Show Implementation Plan to user for approval
3. ✅ Create **Implementation Checklist** from plan (S6 start)
4. ✅ Update checklist as tasks complete

### Creating Bug Fix Documentation

1. ✅ Create `bugfix_{priority}_{name}/` folder
2. ✅ Use **Bug Fix Notes** template
3. ✅ Present to user for validation
4. ✅ Proceed with bug fix workflow (Stages 2 → S5 → S6 → S7)

---

## Notes

- **Prefer individual templates** over reading the entire archive
- **All templates use markdown format** for consistency
- **Placeholders use `{curly_braces}`** - replace with actual values
- **Some templates are immutable** after user validation (see table above)
- **Templates evolve** based on lessons learned from epics

---

**For questions about templates:** See `EPIC_WORKFLOW_USAGE.md` or `prompts_reference_v2.md`
