# Master: Receiving and Applying a Child Changelog

This guide is for the **master Shamt agent** applying an incoming changelog file submitted by a child project.

---

## When to Use This Guide

Use this guide when:
- A child project maintainer has submitted a changelog file
- The file has been placed in `.shamt/changelogs/unapplied_external_changes/`

---

## Step 1: Read the Changelog Entry

Read the incoming changelog file completely before doing anything else.

Pay attention to:
- **Guide(s) Affected** — which guide files the change targets
- **Change Type** — core functionality vs. clarification vs. structural
- **Universality Assessment** — is this universal, partial, or child-specific?
- **How to Apply** — any specific instructions provided

---

## Step 2: Assess Universality

Determine whether the change belongs in the master guides.

**Apply to master if:**
- Marked "Universal" — likely beneficial to all Shamt versions
- Marked "Partially universal" AND the universal portion is separable
- It fixes a genuine error or contradiction in the master guides
- It addresses a workflow gap that would affect any project

**Do NOT apply to master if:**
- Marked "Child-specific"
- The change is tightly coupled to that project's tech stack or conventions
- The change contradicts a deliberate master design decision

**When uncertain:** Apply the universal portion only. Note the decision in the changelog's applied record.

---

## Step 3: Apply the Changes

For each guide affected:

1. Read the current guide content
2. Apply the change as described
3. Verify the change doesn't introduce contradictions with surrounding content
4. If conflict found with existing master content → **STOP and escalate to user** — do not resolve autonomously

After applying:
- Re-read the modified sections to confirm accuracy
- Check if adjacent sections need corresponding updates

---

## Step 4: Run the Guide Audit

After applying all changes from the changelog entry:

1. Run the audit: follow `.shamt/guides/audit/` — begin with `audit/README.md`
2. Fix any issues found before proceeding
3. The audit must pass cleanly before publishing

---

## Step 5: Assign Version Number and Publish

1. Check `outbound_changelogs/CHANGELOG_INDEX.md` for the current highest version number
2. Increment by 1 (zero-padded to 4 digits): e.g., current = `v0003` → new = `v0004`
3. Create the outbound changelog file:
   - Filename: `v[NNNN]_[brief-slug].md`
   - Use the changelog entry format from `.shamt/guides/changelog_application/`
   - Summary should describe what was incorporated (may differ from child's summary if only partial)
4. Write the file to `.shamt/outbound_changelogs/`

---

## Step 6: Update CHANGELOG_INDEX.md

Update `outbound_changelogs/CHANGELOG_INDEX.md`:

```markdown
| v0004 | YYYY-MM-DD | [one-line summary of what changed] |
```

Add new entries at the **top** of the table (newest first). Update the "Current Master Version" line.

---

## Step 7: Move Source File

Move the processed changelog from:
- `unapplied_external_changes/[filename].md`

To:
- `applied_external_changes/[filename].md`

---

## Step 8: Confirm with User

Report to the user:
- What changes were applied (and to which guides)
- What was excluded (and why)
- The new version number published
- Any issues encountered or decisions made

---

## Conflict Handling

If a change conflicts with existing master content:
1. **STOP** — do not resolve autonomously
2. Present the conflict to the user clearly:
   - What the child changelog proposes
   - What the master currently says
   - Why they conflict
3. Wait for user direction before proceeding

---

## Changelog Entry Format (for outbound file)

```markdown
# Shamt Changelog Entry

**Entry ID:** SHAMT-CHANGELOG-[NNN]
**Date:** YYYY-MM-DD
**Source Project:** [child project name]
**Author:** master agent

## Guide(s) Affected
- [.shamt/guides/path/to/guide.md] — [section]

## Change Type
- [x] [type]

## Summary
[What changed in the master guides]

## Rationale
[Why this change improves the guides]

## Universality Assessment
- [x] Universal

## How to Apply
[Guidance for child agents applying this to their customized version]
```
