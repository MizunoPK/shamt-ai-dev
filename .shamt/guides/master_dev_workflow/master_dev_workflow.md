# Master Dev Workflow — Guide Improvement Process

This guide defines the standardized process for improving the master Shamt guides directly (not via a child changelog).

Use this when:
- You've identified a gap, error, or improvement opportunity in the master guides
- You're making structural changes to the guide system
- You're adding new guides or sections

This process is intentionally lighter than the full S1-S10 epic workflow. It's aligned with S10's lessons-learned update approach.

---

## When to Use This vs. the Full Epic Workflow

| Scope | Use |
|-------|-----|
| Single guide fix, clarification, or small addition | This workflow |
| New guide section (< 1 guide file) | This workflow |
| New guide files or significant restructuring | Full epic workflow (S1-S10) with SHAMT epic tracking |
| Multi-guide cross-cutting changes | Full epic workflow |

---

## Step 1: Define the Change

Before touching any files, write a one-paragraph description of:
- What the current guide says (or doesn't say)
- What the problem or gap is
- What the improvement should be

This becomes the basis for your changelog entry.

---

## Step 2: Read the Affected Guides

Use the Read tool to load the full content of every guide you plan to modify.

Do not work from memory. Even if you just read the guide, re-read it now.

---

## Step 3: Make the Changes

Apply your improvements to the guide files.

Rules:
- Fix ALL issues in one pass — do not leave partial fixes
- If you discover scope is larger than expected → stop and switch to full epic workflow
- No deferred issues — fix everything or don't change anything

---

## Step 4: Run the Guide Audit

After making changes:

1. Open `.shamt/guides/audit/README.md`
2. Run the pre-audit checks: `bash .shamt/guides/audit/scripts/pre_audit_checks.sh` (if applicable)
3. Work through the audit stages
4. Fix any issues found before proceeding
5. The audit must pass cleanly

---

## Step 5: Write a Changelog Entry

Write a changelog entry in `.shamt/changelogs/` describing what changed.

**Even for master-internal changes**, write the entry — it becomes the basis for the outbound changelog.

Use the template:

```markdown
# Shamt Changelog Entry

**Entry ID:** SHAMT-CHANGELOG-[NNN]
**Date:** YYYY-MM-DD
**Source Project:** master
**Author:** [agent]

## Guide(s) Affected
- [.shamt/guides/path/to/guide.md] — [section]

## Change Type
- [ ] Core functionality change
- [ ] New guide or section added
- [ ] Clarification / wording improvement
- [ ] Bug fix (guide was incorrect or contradictory)
- [ ] Structural/organizational change

## Summary
[1-3 sentences]

## Rationale
[Why this change was made]

## Universality Assessment
- [x] Universal

## How to Apply
[Guidance for child agents applying this to their customized guides]
```

---

## Step 6: Publish as an Outbound Changelog

1. Check `outbound_changelogs/CHANGELOG_INDEX.md` for the current version number
2. Assign the next sequential version: `v[NNNN]_[brief-slug].md`
3. Copy the changelog entry to `outbound_changelogs/`
4. Update `CHANGELOG_INDEX.md` — add new entry at top, update current version

---

## Step 7: Commit

```bash
git add .shamt/guides/ .shamt/outbound_changelogs/
git commit -m "feat/SHAMT-[N]: [brief description of guide improvement]"
```

---

## Using Epic Tracking for Larger Work

For significant multi-guide changes, use the full SHAMT epic workflow:

1. Create epic folder in `.shamt/epics/SHAMT-[N]-[name]/`
2. Update `.shamt/epics/EPIC_TRACKER.md`
3. Create branch: `feat/SHAMT-[N]`
4. Follow S1-S10 stages as appropriate for the scope
5. Publish outbound changelog at the end (S10)
