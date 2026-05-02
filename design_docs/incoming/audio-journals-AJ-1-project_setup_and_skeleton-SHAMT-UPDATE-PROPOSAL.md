# Audio Journals — AJ-1-project_setup_and_skeleton Guide Update Proposals

**Status:** Pending Implementation
**Created:** 2026-04-10
**Source Epic:** AJ-1-project_setup_and_skeleton
**Proposals:** 3 accepted, 0 modified, 0 rejected

---

## Overview

AJ-1 was the foundational project setup epic establishing directory structure, config, database, logging, tests, and documentation for the Audio Journals project. All three guide improvement proposals address sub-agent false positives observed during S7.P2, S7.P3, and S9.P2 confirmation rounds. False positives occurred because sub-agent prompt templates lack fields for project context (prior deliverables, design choices, tool flags) and explicit artifact paths. Adding these fields to the templates prompts the primary agent to populate them — reducing false positive investigation overhead.

---

## Proposal P2-1: Add project context guidance to S7.P2 sub-agent confirmation prompts

**Priority:** P2
**Affected Guide:** `.shamt/guides/stages/s7/s7_p2_qc_rounds.md`
**Section:** Sub-Agent Confirmation Protocol — sub-agent prompt template

### Problem

During F02 S7.P2, confirmation sub-agents produced 4 false positives: claiming `src/__init__.py` had content (0 bytes by design), flagging `Config.from_env()` for a "Path type mismatch" (intentional two-phase validation design), claiming `sqlite3.Error` handler needed `sys.exit(1)` (wrong per spec — spec said "exit gracefully"), and claiming `logs/` was missing (created by F01). Each required investigation to dismiss. Root cause: the current template has no project context section, so sub-agents arrive knowing nothing about prior feature deliverables, intentional design choices, or project-specific tool flags.

### Current State

```markdown
  <parameter name="prompt">You are sub-agent A confirming zero issues in feature QC validation.

**Artifact to validate:** Feature {feature_NN} implemented code
**Validation dimensions:** All 17 dimensions (7 master + 10 S7 QC) from reference/validation_loop_s7_feature_qc.md
**Your task:** Review the entire feature implementation and verify ALL dimensions.

CRITICAL: Report ANY issue found, even LOW severity. If zero issues found, state "CONFIRMED: Zero issues found".

Check: Empirical verification, completeness, consistency, traceability, clarity, upstream alignment, standards, cross-feature integration, error handling, end-to-end functionality, test coverage (100% passing), requirements completion, imports, types, input validation, test stubs.
```

### Proposed Change

```markdown
  <parameter name="prompt">You are sub-agent A confirming zero issues in feature QC validation.

**Artifact to validate:** Feature {feature_NN} implemented code
**Validation dimensions:** All 17 dimensions (7 master + 10 S7 QC) from reference/validation_loop_s7_feature_qc.md
**Your task:** Review the entire feature implementation and verify ALL dimensions.

**Project context (prevents false positives — read before flagging issues):**
- Prior feature deliverables: {e.g., "Feature 01 created: logs/ directory, data/ subdirs, .gitkeep files, requirements.txt"}
- Intentional design choices: {e.g., "src/__init__.py is intentionally 0 bytes (package marker only)", "Config.from_env() returns str|None — validate() call site is responsible for None handling"}
- Project tool configuration: {e.g., "mypy uses --ignore-missing-imports, NOT --strict", "ruff config is under [tool.ruff.lint]"}
- Lint patterns: {e.g., "side-effect-only instantiation omits variable capture by design (avoids ruff F841)"}

CRITICAL: Report ANY issue found, even LOW severity. If zero issues found, state "CONFIRMED: Zero issues found".

Check: Empirical verification, completeness, consistency, traceability, clarity, upstream alignment, standards, cross-feature integration, error handling, end-to-end functionality, test coverage (100% passing), requirements completion, imports, types, input validation, test stubs.
```

### Rationale

Sub-agents spawned for confirmation have no memory of prior conversation context. Without a project context block, they flag intentional design choices as bugs. Adding a project context placeholder in the template reminds the primary agent to populate it — reducing false positive investigation cycles.

---

## Proposal P2-2: Require absolute file paths in S7.P3 sub-agent spawning parameters

**Priority:** P2
**Affected Guide:** `.shamt/guides/stages/s7/s7_p3_final_review.md`
**Section:** Step 1a: Spawn Fresh Sub-Agent — Key parameters for sub-agent

### Problem

During F03 S7.P3, a confirmation sub-agent falsely reported README.md as "missing from tests/ directory." The actual README.md is at the project root per spec. The sub-agent searched in the feature folder because the prompt said "README.md (project setup documentation)" without an absolute path. Root cause: the S7.P3 guide's "Key parameters" section doesn't specify that absolute paths are required, nor does it prompt the primary agent to list all artifacts (including those outside the feature folder).

### Current State

```markdown
**Key parameters for sub-agent:**
- **Branch:** Feature branch name (e.g., `feat/EPIC-123/feature-01`)
- **Review Type:** S7.P3 Feature PR Review
- **Scope:** Feature-level code quality (not epic-level concerns)
- **Implementation Plan:** Path to validated implementation plan
- **Spec File:** Path to feature spec file
- **Model:** `opus` (for deep reasoning and thorough review)
```

### Proposed Change

```markdown
**Key parameters for sub-agent:**
- **Branch:** Feature branch name (e.g., `feat/EPIC-123/feature-01`)
- **Review Type:** S7.P3 Feature PR Review
- **Scope:** Feature-level code quality (not epic-level concerns)
- **Implementation Plan:** Absolute path to validated implementation plan (e.g., `/abs/path/implementation_plan.md`)
- **Spec File:** Absolute path to feature spec file
- **All artifacts under review:** List ALL files with absolute paths, especially those NOT in the feature folder (e.g., project root README.md, shared config files, main entry point)
- **Model:** `opus` (for deep reasoning and thorough review)

⚠️ **Always use absolute paths.** Sub-agents default to searching in the feature folder when paths are ambiguous. A project root `README.md` will be reported as "missing" if the path is not explicit.
```

### Rationale

Adding the "All artifacts under review" parameter with the absolute path requirement prevents a specific class of false positive: the sub-agent claiming a file is absent because it searched in the wrong directory. The warning note makes the reason concrete so future agents understand why absolute paths matter.

---

## Proposal P3-1: Specify project's exact static analysis command in S9.P2 sub-agent prompts

**Priority:** P3
**Affected Guide:** `.shamt/guides/stages/s9/s9_p2_epic_qc_rounds.md`
**Section:** Sub-Agent Confirmation Protocol — sub-agent prompt template (near lines 1028–1050)

### Problem

During S9.P2 Epic QC, a confirmation sub-agent flagged `metadata: dict` and `list[dict]` as missing type parameters. Root cause: the sub-agent used `mypy --strict` instead of the project's `mypy --ignore-missing-imports`. Running the project's actual command showed zero issues. The prompt template has no field for specifying project-specific tool commands, so sub-agents default to the most thorough mode available.

### Current State

```markdown
  <parameter name="prompt">You are sub-agent A confirming zero issues in epic QC validation.

**Artifact to validate:** Epic {epic_name} complete implementation
**Validation dimensions:** All 13 dimensions (7 master + 6 epic) from reference/validation_loop_master_protocol.md
```

### Proposed Change

```markdown
  <parameter name="prompt">You are sub-agent A confirming zero issues in epic QC validation.

**Artifact to validate:** Epic {epic_name} complete implementation
**Validation dimensions:** All 13 dimensions (7 master + 6 epic) from reference/validation_loop_master_protocol.md

**Project static analysis commands (use these exactly — different flags produce different error sets):**
- {e.g., `venv/bin/mypy src/ main.py tests/ --ignore-missing-imports` — NOT `mypy --strict`}
- {e.g., `venv/bin/ruff check .`}
```

### Rationale

A single placeholder block added to the prompt template prompts the primary agent to fill in the project's exact tool commands — preventing the sub-agent from defaulting to stricter modes the project hasn't adopted. This is a low-effort addition with targeted benefit for typed-language projects where tool mode differences produce meaningfully different error sets.

---

## Rejected Proposals (for reference)

*(No proposals rejected — all 3 approved.)*

---

## Implementation Notes

- Apply all proposals as a single batch
- Run full guide audit (3 consecutive clean rounds) before committing
- Update `reference/guide_update_tracking.md` with implementation entry
- Delete this file from `unimplemented_design_proposals/` after successful implementation and commit
