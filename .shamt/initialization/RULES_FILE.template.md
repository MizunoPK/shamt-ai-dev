# {{PROJECT_NAME}} — Agent Rules

> **This file:** `RULES_FILE.template.md` is renamed and placed during initialization per the AI service being used (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot).

---

## Quick Start for New Agents

**FIRST:** Read `ARCHITECTURE.md` for complete architectural overview and implementation details.

**SECOND:** Read this file for workflow rules, coding standards references, and commit protocols.

**THIRD:** Check `.shamt/epics/` for any in-progress epic work to resume.

---

## Project Overview

**Project:** {{PROJECT_NAME}}
**Epic Tag:** {{EPIC_TAG}}
**Agent Name:** {{SHAMT_NAME}}
**Git Platform:** {{GIT_PLATFORM}}
**Default Branch:** {{DEFAULT_BRANCH}}

---

## Workflow System

This project uses the **Shamt epic-driven development workflow** (S1–S10).

**All guides live at:** `.shamt/guides/`

**Stage overview:**
```
S1: Epic Planning → S2: Feature Deep Dives → S3: Cross-Feature Sanity Check →
S4: Feature Testing Strategy → S5-S8: Feature Loop → S9: Epic Final QC → S10: Cleanup

Per-feature: S5 (Plan) → S6 (Execute) → S7 (Test) → S8 (Align) → repeat or S9
```

**Resuming in-progress work:** Check `.shamt/epics/` for active epic folders. Read `EPIC_README.md` → Agent Status section for exact resumption point.

---

## Critical Rules

✅ **Always required:**
- Read guide before starting each stage
- Use phase transition prompts from `.shamt/guides/prompts/`
- Update Agent Status in README files at every checkpoint
- Fix ALL issues immediately (zero tech debt tolerance)
- 100% test pass rate before commits

❌ **Never allowed:**
- Skip stages or dimensions in S5 Validation Loop
- Defer issues for later
- Commit without running tests
- Autonomous conflict resolution (always escalate to user)

---

## Git Conventions

- **Branch format:** `{work_type}/{{EPIC_TAG}}-{N}` (epic/feat/fix)
- **Commit format:** `{commit_type}/{{EPIC_TAG}}-{N}: {message}`
- **Commit title max:** 100 characters
- **No AI attribution** in commit messages (no Co-Authored-By, no "Generated with")

---

## Key File Locations

| File | Location | Purpose |
|------|----------|---------|
| Epic tracker | `.shamt/epics/EPIC_TRACKER.md` | All epics + next available number |
| Architecture | `ARCHITECTURE.md` | Project structure and design |
| Coding standards | `CODING_STANDARDS.md` | Style, naming, testing rules |
| Guides | `.shamt/guides/` | Full S1–S10 workflow |
| Epic work | `.shamt/epics/` | Active and archived epics |

---

## Coding Standards

See `CODING_STANDARDS.md` for complete standards. Key points:
- [Agent: fill in 3–5 key coding rules after analyzing the codebase]

---

## Shamt Changelog

This project participates in the Shamt changelog ecosystem:
- **Write a changelog** when you make guide improvements that could benefit other projects
- **Changelog location:** `.shamt/changelogs/outbound/`
- **Apply updates** from `.shamt/changelogs/unapplied_external_changes/` when available
- **Guide:** `.shamt/guides/changelog_application/child_applying_master_changelog.md`
