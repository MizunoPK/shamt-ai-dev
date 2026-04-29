---
name: shamt-guide-audit
description: >
  Systematic quality audit of all .shamt/guides/ files across 23 dimensions
  (plus D-DRIFT and D-COVERAGE for skill artifacts). Uses a 4-sub-round structure
  per round and exits only after 3 consecutive clean rounds with all 9 criteria met.
triggers:
  - "run guide audit"
  - "audit the guides"
  - "run a full audit"
  - "audit guides"
source_guides:
  - guides/audit/README.md
  - guides/audit/audit_overview.md
  - guides/reference/severity_classification_universal.md
master-only: false
---

# Skill: shamt-guide-audit

## Overview

The guide audit ensures consistency, accuracy, and completeness across all `.shamt/guides/` files
(including any subdirectory added by later SHAMTs). It evaluates 23 dimensions organized into
4 sub-rounds per audit round, plus 2 skill-specific dimensions (D-DRIFT and D-COVERAGE) that
check `.shamt/skills/` artifacts.

**Exit criterion: 3 CONSECUTIVE CLEAN ROUNDS** — NOT the 1+2-sub-agents criterion used by
workflow validation loops. This is a hard rule. Track `consecutive_clean` explicitly.

---

## When This Skill Triggers

Use this skill when the user says: "run guide audit", "audit the guides", "run a full audit",
"audit guides".

**Mandatory triggers** (always run after):
- Major restructuring (stage renumbering, folder reorganization, file splits/merges)
- Terminology changes (notation updates, naming convention changes)
- Workflow updates (new stages/phases, changed gate requirements, modified file structures)
- After S11.P1 guide updates
- When a user reports an inconsistency

**Optional triggers:** Quarterly maintenance, before major releases, after significant content updates.

---

## Protocol

### Before Starting — Run Pre-Audit Checks

```bash
cd .shamt/guides/audit
bash scripts/pre_audit_checks.sh
```

The pre-audit script covers D1-D12 automated checks (D1, D3, D4, D8, D9, D10, D11, D12, D14,
D17, D18, D20 partial). It catches ~45-55% of typical issues. Spawn a Haiku sub-agent to run it.

### Round Structure — 4 Sub-Rounds Per Round

Every round consists of 4 sub-rounds executed in sequence. Each sub-round follows 5 stages:
S1 Discovery → S2 Fix Planning → S3 Apply Fixes → S4 Verification → S5 Loop Decision.

```
Round N:
  Sub-Round N.1: Core (D1, D2, D3, D4)
  Sub-Round N.2: Content Quality (D5, D6, D7, D8, D9, D23)
  Sub-Round N.3: Structural (D10, D11, D12, D13, D14)
  Sub-Round N.4: Advanced (D15, D16, D17, D18, D19, D20, D21, D22)
  + D-DRIFT and D-COVERAGE checks (integrate into N.4 or as N.5)
```

**Sub-round loop logic:**
- Sub-round finds issues → Fix ALL → Re-run same sub-round → Repeat until 0 issues
- Sub-round clean (0 issues) → Proceed to next sub-round
- All 4 sub-rounds clean → Round N complete

**A round is clean if** the total issues discovered during the round's first pass (all 4 sub-rounds
combined) was ZERO, or exactly 1 LOW-severity issue (fixed). Any 2+ LOW, or any
MEDIUM/HIGH/CRITICAL resets `consecutive_clean` to 0.

**Zero deferrals policy:** ALL identified issues must be investigated and fixed immediately.
If uncertain: read the files, investigate. Still uncertain: ask the user. Never defer to a
later round.

---

## The 23 Audit Dimensions

### Sub-Round N.1: Core Dimensions

| D# | Name | What to Check | Automation |
|----|------|---------------|------------|
| D1 | Cross-Reference Accuracy | All file paths, stage references, cross-links are valid | 90% automated |
| D2 | Terminology Consistency | Notation, naming conventions, terminology uniform across all guides | 80% automated |
| D3 | Workflow Integration | Guides correctly reference each other; prerequisites and transitions coherent | 40% automated |
| D4 | CLAUDE.md Synchronization | Root file quick references match actual guide content (step numbers, stage names, gate criteria) | 60% automated |

**Why first:** Broken references and inconsistent notation affect all other checks.

**Model:** Haiku for D1 grep/file-counting; Opus for D2 content pattern analysis; Haiku for D4
automated checks.

### Sub-Round N.2: Content Quality Dimensions

| D# | Name | What to Check | Automation |
|----|------|---------------|------------|
| D5 | Count Accuracy | File counts, stage counts, iteration counts match reality | 90% automated |
| D6 | Content Completeness | No missing sections, gaps in coverage, or orphaned references | 85% automated |
| D7 | Template Currency | Templates reflect current workflow structure and terminology | 70% automated |
| D8 | Documentation Quality | All required sections present; no TODOs or placeholders | 90% automated |
| D9 | Content Accuracy | Claims in guides match reality (step counts, durations, file names) | 70% automated |
| D23 | Architecture/Standards Currency | ARCHITECTURE.md and CODING_STANDARDS.md accurate and up-to-date (threshold: 60 days) | 50% automated |

**Model:** Opus for D5-D9 accuracy/completeness analysis.

### Sub-Round N.3: Structural Dimensions

| D# | Name | What to Check | Automation |
|----|------|---------------|------------|
| D10 | Intra-File Consistency | Within-file quality: consistent headers, checklists, formatting | 80% automated |
| D11 | File Size Assessment | Workflow guides ≤2000 lines; CLAUDE.md ≤40,000 characters (hard limit) | 100% automated |
| D12 | Structural Patterns | Guides follow expected template structures | 60% automated |
| D13 | Cross-File Dependencies | Stage prerequisites match outputs; workflow continuity | 30% automated |
| D14 | Character and Format Compliance | No banned Unicode chars (curly quotes, Unicode checkboxes, other non-ASCII that agents can't process) | 100% automated |

**Model:** Haiku for D11/D14 automated; Sonnet for D10/D12 structural analysis; Haiku for D13 grep.

### Sub-Round N.4: Advanced Dimensions

| D# | Name | What to Check | Automation |
|----|------|---------------|------------|
| D15 | Context-Sensitive Validation | Distinguish intentional exceptions from real errors | 20% automated |
| D16 | Duplication Detection | No duplicate content or contradictory instructions across guides | 50% automated |
| D17 | Accessibility | Navigation aids, TOCs, scannable structure | 80% automated |
| D18 | Stage Flow Consistency | Behavioral continuity and semantic consistency across stage transitions | 30% automated |
| D19 | Rules File Template Alignment | Child project rules file retains Shamt structural sections (child context only) | 30% automated |
| D20 | Script Integrity | Sync/init scripts are functionally correct; bash/PS parity; output matches guide instructions; transient files gitignored (manual review) | 20% automated |
| D21 | Agent Comprehension Risk | Each guide unambiguously states its scope near H1; no migration notes in the instruction path; structurally similar guides have explicit scope differentiation callouts | 15% automated |
| D22 | Guide Bypass Risk | Each guide has MANDATORY READING PROTOCOL; FORBIDDEN SHORTCUTS block naming guide-specific bypasses; phase commitment gate for multi-phase guides; NEXT MANDATORY STEP footers in phase transition prompts | 30% automated |

**Model:** Opus for D15-D22 (complex analysis requiring deep reasoning).

---

## Skill Dimensions (D-DRIFT and D-COVERAGE)

These two dimensions are added by SHAMT-39. Check them during Sub-Round N.4 (or as a dedicated
Sub-Round N.5 if the advanced dimensions are already large).

### D-DRIFT — Skill Protocol Drift

**For every SKILL.md in `.shamt/skills/`:**

1. Read the SKILL.md's `source_guides:` frontmatter list
2. Read each referenced source guide
3. Compare the SKILL.md's protocol steps against the source guide content
4. Flag any divergences:
   - **MEDIUM:** Minor prose drift — skill describes a step differently but intent is preserved
   - **HIGH:** Missing step — the source guide has a mandatory step that the SKILL.md omits
   - **HIGH:** Contradicted step — the SKILL.md says something that contradicts the source guide

**What counts as a divergence:**
- A required constraint mentioned in the source guide is not mentioned in the SKILL.md
- A step order in the SKILL.md does not match the source guide
- The SKILL.md's exit criteria differ from the source guide's exit criteria
- A "hard rule" or "anti-shortcut" in the source guide is absent from the SKILL.md

**What does NOT count as a divergence:**
- Condensed prose that accurately captures the intent (this is expected — skills are distillations)
- Omitting examples that are present in the source guide
- Slightly different wording that preserves the same constraint

### D-COVERAGE — Skill Coverage Gap

**Walk `.shamt/guides/` and assess coverage:**

1. List all guide files in `.shamt/guides/` (all subdirectories)
2. For each guide file, check whether a corresponding SKILL.md exists that covers its protocol
3. Flag guide files with NO corresponding skill body as **LOW-severity candidates** — propose
   whether a new skill is warranted (not a defect unless coverage was intended)
4. Also check the reverse gap: for each SKILL.md, verify its `source_guides:` list actually
   covers all the protocol steps in the skill body — flag any protocol steps in the SKILL.md
   that have no traceable source guide as **MEDIUM** (the skill is asserting steps that are not
   anchored to canonical guide content)

**Severity guidance:**
- Guide with no skill and coverage was NOT planned: **LOW** (candidate proposal)
- Guide with no skill but README.md or CLAUDE.md says a skill exists: **HIGH** (broken promise)
- SKILL.md protocol step with no traceable source guide: **MEDIUM**

---

## Exit Criteria

### Audit-Level Exit (3 Consecutive Clean Rounds)

**Track `consecutive_clean` and state it explicitly at the end of every round.**

```
consecutive_clean = 0

After each round:
  Round has 0 issues across all 4 sub-rounds (first pass): consecutive_clean += 1
  Round has exactly 1 LOW (fixed):                         consecutive_clean += 1
  Round has 2+ LOW OR any MEDIUM/HIGH/CRITICAL:            consecutive_clean = 0

Exit only when: consecutive_clean >= 3 AND all 9 criteria met
```

**ALL 9 criteria must be met to exit:**

1. All issues resolved — every issue from all rounds fixed and verified
2. Zero new issues — latest round found ZERO issues in all 4 sub-rounds
3. Zero verification findings — latest round's S4 verifications found ZERO new issues
4. 3 consecutive clean rounds — `consecutive_clean >= 3`
5. All remaining instances documented as intentional
6. User has NOT challenged findings
7. Confidence score >= 80% across all 23 dimensions (+ D-DRIFT, D-COVERAGE)
8. Pattern diversity — >= 5 pattern types used per dimension category across rounds
9. Spot-check clean — 10+ files manually checked per sub-round, zero issues

**If user challenges you in ANY way:** Immediately loop back to Round 1, Sub-Round 1.1.
User challenge = evidence you missed something. Do not defend — re-verify everything.

---

## Severity Classification

| Severity | Definition | Clean Round Impact |
|----------|------------|-------------------|
| CRITICAL | Blocks workflow; broken file paths; CLAUDE.md >40K chars; template errors | Reset to 0 |
| HIGH | Causes confusion; contradictions; missing critical sections; wrong counts | Reset to 0 |
| MEDIUM | Reduces quality; file >2000 lines; minor inaccuracies; missing optional sections | Reset to 0 |
| LOW | Cosmetic; trailing whitespace; trivial typos; extra blank lines | 1 allowed per round |

**Guide audit examples:**
- Broken file path in workflow guide: CRITICAL
- CLAUDE.md >40,000 characters: CRITICAL
- Mixed notation in same file: HIGH
- Missing required section: HIGH
- File >2000 lines (readable): MEDIUM
- Count slightly off: MEDIUM
- Trailing whitespace: LOW

**Borderline rule:** When uncertain between two levels, classify as the HIGHER severity.

---

## Model Delegation Pattern

```
Primary Agent (Opus):
├─ Spawn Haiku → Pre-audit script (D1-D12 automated)
├─ Spawn Haiku → File counting, cross-reference grep (D13, D14, D15)
├─ Spawn Sonnet → Structural dimensions (D11 file size, D12 patterns, D16 duplication)
├─ Primary (Opus) → Content/correctness (D2-D5, D7-D9), D17-D23, adversarial self-check
├─ Primary (Opus) → D-DRIFT and D-COVERAGE checks
└─ Spawn 2x Haiku (parallel) → Sub-round completion spot-checks
```

Estimated token savings: 40-50% per audit round vs. Opus-only execution.

**Note:** Guide audits do NOT use the sub-agent confirmation exit pattern. The exit criterion is
3 consecutive clean rounds tracked by the primary agent. The 2x Haiku parallel confirmation
pattern applies ONLY to workflow validation loops (S2, S5, S7.P2, S9.P2, etc.), not guide audits.

---

## Fresh Eyes Protocol

Each new round must use different patterns and a different approach than the previous round.

**Before starting Round N:**
- Clear context from Round N-1 (close files, take a break)
- Do NOT look at Round N-1 discovery report before Round N discovery
- Use DIFFERENT search patterns (not the same grep commands)
- Search folders in DIFFERENT order than Round N-1
- Start from a DIFFERENT dimension category than Round N-1

**Anti-patterns:**
- Re-running Round N-1 patterns to "verify" — finds same things or nothing (false confidence)
- Skipping folders "because I know they're clean" — NOT fresh eyes
- Treating Round 2 as validation of Round 1 — SHAMT-7 evidence: Round 3 found 70+ issues after Round 1-2

**Pattern type rotation across rounds:**
- Round 1: Exact string matches
- Round 2: Punctuation variations (`:`, `-`, `(`, context patterns)
- Round 3: Manual spot-reading (different approach from grep-only rounds)

---

## Quick Reference

**Sub-round groupings:**
- N.1 Core: D1 (cross-refs), D2 (terminology), D3 (workflow), D4 (CLAUDE.md)
- N.2 Content: D5 (counts), D6 (completeness), D7 (templates), D8 (docs quality), D9 (accuracy), D23 (arch/standards)
- N.3 Structural: D10 (intra-file), D11 (file size), D12 (patterns), D13 (cross-file deps), D14 (char compliance)
- N.4 Advanced: D15 (context-sensitive), D16 (duplication), D17 (accessibility), D18 (stage flow), D19 (rules template), D20 (script integrity), D21 (agent comprehension), D22 (guide bypass)
- Skills: D-DRIFT (skill vs source divergence), D-COVERAGE (guide-to-skill gap)

**Output files (temporary, never commit):**
```
audit/outputs/
├── round_N_discovery_report.md
├── round_N_fix_plan.md
├── round_N_verification_report.md
├── round_N_loop_decision.md
└── round_N_improvements_working.md
```

**Critical file size thresholds:**
- CLAUDE.md: must not exceed 40,000 characters (hard policy limit, CRITICAL if violated)
- Workflow guides (`stages/**/*.md`): flag files >2000 lines (MEDIUM)

**Anti-shortcuts:**
- Never exit on fewer than 3 consecutive clean rounds
- Never defer an issue to a later round — investigate or ask the user
- Never re-use the same grep patterns across consecutive rounds
- Never skip the fresh eyes protocol between rounds
- Never score a round clean without documenting `consecutive_clean = N`
