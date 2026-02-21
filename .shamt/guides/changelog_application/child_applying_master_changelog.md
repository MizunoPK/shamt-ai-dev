# Child Project: Applying a Master Shamt Changelog

This guide is for a **child Shamt agent** applying an incoming changelog published by the master Shamt repo.

---

## When to Use This Guide

Use this guide when:
- New changelog files have been downloaded from master's `outbound_changelogs/`
- Files have been placed in `.shamt/changelogs/unapplied_external_changes/`

---

## Before You Start: Deduplication Check

For each file in `unapplied_external_changes/`:

1. Check if the filename already exists in `applied_external_changes/`
2. If it does → the changelog was already applied. Move it to `applied_external_changes/` and skip.
3. If it doesn't → proceed with application below.

---

## Step 1: Read the Changelog Entry

Read the file completely before making any changes.

Pay attention to:
- **Guide(s) Affected** — which `.shamt/guides/` files are targeted
- **Change Type** — helps assess impact
- **Universality Assessment** — Universal means apply as-is; Partial means read the notes carefully
- **How to Apply** — follow any specific instructions provided

---

## Step 2: Assess Applicability to Your Project

Even universal changelogs may need adaptation if your guides have been locally customized.

Ask yourself:
- Does your version of the affected guide have significant local customizations in the changed section?
- Does the proposed change contradict a deliberate local decision?
- Is the change still relevant given how your guides have evolved?

**If clearly applicable:** proceed to Step 3.

**If a conflict exists:** proceed to Step 4 (escalate).

**If clearly not applicable** (e.g., change targets a section you removed): note in the index as "skipped — not applicable" and move the file to `applied_external_changes/`.

---

## Step 3: Apply the Change

For each guide affected:

1. Read the current state of your guide
2. Apply the change as described in "How to Apply"
3. Verify the change fits cleanly with your surrounding local customizations
4. Re-read the modified section to confirm it reads correctly in your context

---

## Step 4: Escalate Conflicts to User

**If you find a conflict between the changelog and your local guide customization:**

1. **STOP immediately** — do not attempt to resolve autonomously
2. Present the conflict clearly to the user:

```
CONFLICT FOUND in [guide path]

Master changelog proposes:
[quote the change]

Your current guide says:
[quote the conflicting section]

Conflict: [explain why they conflict]

Options:
A) Apply the master change (overrides local customization)
B) Keep local customization (skip this changelog for this section)
C) Merge manually (you specify how)
```

3. Wait for user decision before proceeding
4. Apply the user's chosen resolution

---

## Step 5: Update the Applied Index

After successfully applying a changelog:

1. Move the file from `unapplied_external_changes/` to `applied_external_changes/`
2. Update `applied_external_changes/CHANGELOG_INDEX.md`:

```markdown
| v0004 | YYYY-MM-DD | [one-line summary] |
```

Add new entries at the **top** of the table. Update the "Current Version" line.

---

## Step 6: Consider Writing a Changelog Entry

After applying master changelogs, reflect on whether your local guides have improvements worth contributing back.

The master changelog may also have prompted you to notice something in your guides worth fixing independently. If so, consider writing a child changelog entry in `.shamt/changelogs/outbound/`.

---

## Processing Multiple Files

If multiple changelog files are in `unapplied_external_changes/`:

- Process them in **version number order** (lowest first)
- Complete Steps 1–5 for each file before starting the next
- Do not batch or skip files

---

## Edge Cases

**File in unapplied but already in applied:** Deduplicate — move to applied, skip.

**Changelog targets a guide you deleted:** Note as "not applicable — guide removed" in the index. Move to applied.

**Changelog adds a new guide section you already added independently:** Compare content. If equivalent, mark applied. If different, escalate to user.

**"How to Apply" section is missing:** Use your judgment based on the Summary and Rationale. If uncertain, escalate to user.
