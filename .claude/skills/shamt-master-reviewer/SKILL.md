---
name: shamt-master-reviewer
description: >
  Reviews incoming child-project PRs in the shamt-ai-dev master repo. Evaluates
  whether changes are truly generic (applicable to all Shamt projects) vs.
  project-specific, applies the separation rule, approves or requests changes,
  runs a full guide audit after merge, and handles proposal docs correctly.
triggers:
  - "review child PR"
  - "review incoming PR"
  - "review this PR from a child project"
source_guides:
  - ../CLAUDE.md
master-only: true
---

## Overview

Child projects submit guide and script improvements to master via pull request. The PR description will reference `.shamt/CHANGES.md` from the child project for context.

This skill is for use in the **shamt-ai-dev master repo only**. It covers the complete child PR review process from reading the diff through post-merge audit.

---

## When This Skill Triggers

- User says "review child PR", "review incoming PR", or "review this PR from a child project"
- An incoming PR from a child Shamt project needs evaluation
- A PR containing guide or script changes from a non-master project is present

---

## Protocol

### Step 1: Read the PR Diff

Read the full PR diff before making any evaluation. Assess:
- Which files were changed (`guides/`, `scripts/`, `design_docs/incoming/`, other)
- What the changes actually do (not just what the PR description says)
- Whether the changes are additions, modifications, or deletions

Use read-only git commands to inspect the diff:

```bash
git fetch origin <branch-name>
git diff origin/main...origin/<branch-name>
git diff --stat origin/main...origin/<branch-name>
```

---

### Step 2: Apply the Separation Rule

**Scope:** This step applies only to `.shamt/guides/` and `.shamt/scripts/`. Skills (`.shamt/skills/`), agents (`.shamt/agents/`), and commands (`.shamt/commands/`) are master-authored one-way imports — children should not modify them directly. If a child PR includes changes to those directories, guide them to the proposal doc mechanism (`.shamt/CHANGES.md`) instead of applying the separation rule.

For each changed file in `.shamt/guides/` and `.shamt/scripts/`, evaluate:

**Is this change generic (applicable to all Shamt projects)?**

Signs of generic content — APPROVE:
- Rules about Shamt workflow behavior (validation loops, stage transitions, missed requirements)
- Rules about how agents interact with Shamt system files
- Clarifications that prevent a common agent mistake
- New guide sections that address a workflow gap
- Corrected procedures that were wrong or ambiguous
- New templates or reference files
- Conventions that apply regardless of tech stack or domain

Signs of project-specific content — REQUEST CHANGES:
- References to a specific tech stack, test commands, or language (`pytest`, `tsc`, etc.)
- Examples using the child project's actual file names, class names, or APIs
- The child project's epic tag as a literal value (e.g., `KAI-{N}`) instead of the generic `SHAMT-{N}` placeholder
- Historical context or lessons specific to that project
- Content that only makes sense for that project's domain or codebase

**The core question:** Would this change be helpful to a completely different Shamt child project working in a different tech stack on a different domain?

---

### Step 3: Handle Proposal Docs

PRs may include proposal files landing in `design_docs/incoming/` (named `{project}-{epic}-SHAMT-UPDATE-PROPOSAL.md`). These are **always acceptable** without the generic/specific evaluation.

Proposal docs are explicitly project-originated; they are not shared guide files. Review for obvious errors (malformed content, broken references) but do not apply the separation rule. The master maintainer decides separately whether to promote them to design docs.

---

### Step 4: Make the Review Decision

**If all changed guide/script files pass the separation rule:**
- Approve the PR
- Note any LOW-severity style observations (optional, not blocking)

**If any changed guide/script file fails the separation rule:**
- Request changes with specific, actionable feedback
- Identify exactly which content is project-specific and why
- Suggest how to generalize (e.g., replace specific epic tag with `SHAMT-{N}`, remove tech-specific examples, replace concrete filenames with placeholders)
- Do not merge until the project-specific content is removed or moved to `project-specific-configs/`

**If a change contradicts an existing Shamt design decision:**
- Request changes with explanation of the design decision being contradicted
- Reference the relevant guide or CLAUDE.md section

---

### Step 5: After Approving — Merge and Run Full Guide Audit

After the PR is approved and merged:

1. **Merge the PR** (via `gh pr merge` or GitHub UI)
2. **Run a full guide audit** on the entire `.shamt/guides/` tree, starting from `guides/audit/README.md`
3. The audit must achieve **3 consecutive clean rounds** (≤1 LOW issue per round) before the merge is considered complete
4. **Commit any audit fixes** before declaring the merge complete

**Why audit after merge:** Changes from one child project may interact with content in other guides that the child's author didn't see or modify. The audit catches cross-reference gaps, terminology inconsistencies, and workflow description conflicts before they propagate to other child projects on their next import.

**Do not let the merged changes propagate to other child projects (via import) until the post-merge audit passes.**

---

## Exit Criteria

Review is complete when ALL of the following are true:

- [ ] PR diff read in full
- [ ] Separation rule applied to every changed file in `guides/` and `scripts/`
- [ ] Proposal docs (if any) reviewed for obvious errors, accepted without separation rule
- [ ] Decision made: approved OR changes requested with specific feedback
- [ ] If approved and merged: full guide audit run (3 consecutive clean rounds achieved)
- [ ] Any audit-fix commits made before declaring merge complete

---

## Quick Reference

### Separation rule decision table

| What you see | Verdict |
|---|---|
| Workflow step clarification (any tech stack) | Generic — approve |
| New guide section for a process gap | Generic — approve |
| Corrected procedure or fixed ambiguity | Generic — approve |
| New template or reference file | Generic — approve |
| `SHAMT-{N}` placeholder in instruction text | Generic — approve |
| `KAI-{N}` or other project tag in instruction text | Project-specific — request changes |
| `pytest` or `tsc` as example test commands | Project-specific — request changes |
| Child project's actual filenames in examples | Project-specific — request changes |
| Content only meaningful for that domain | Project-specific — request changes |
| Proposal doc in `design_docs/incoming/` | Always acceptable — approve |
| Child PR modifies file in `skills/`, `agents/`, or `commands/` | Always request changes — guide to proposal doc mechanism (`.shamt/CHANGES.md`) instead |

### Post-merge audit exit criterion

3 CONSECUTIVE clean rounds required (not just any 3 rounds). Track `consecutive_clean` explicitly:
- Clean round: ZERO issues OR exactly ONE LOW-severity issue (fixed)
- 2+ LOW issues or any MEDIUM/HIGH/CRITICAL: reset `consecutive_clean` to 0
- Audit exits when `consecutive_clean >= 3`

### Common reviewer mistakes

- Applying the separation rule to proposal docs in `design_docs/incoming/` — do not do this
- Approving without noticing `SHAMT-{N}` was replaced with the child's epic tag in guide files
- Skipping the post-merge guide audit — always run it before declaring merge complete
- Merging and allowing imports before the post-merge audit passes

<!-- Managed by Shamt — do not edit. Run regen-claude-shims.sh to regenerate. -->
