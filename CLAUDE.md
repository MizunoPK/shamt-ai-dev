# Shamt Master — Agent Rules

This is the **master Shamt repository**. You are working on the framework itself, not a child project.

Your primary responsibilities here are:
1. **Applying child changelogs** — reviewing improvements submitted by child projects and incorporating them into the master guides
2. **Publishing outbound changelogs** — versioning and publishing improvements for child projects to consume
3. **Master dev workflow** — making guide improvements using the standardized process
4. **AI service registry** — keeping `ai_services.md` up to date with new AI services

---

## Project Structure

```
shamt-ai-dev/
├── README.md
├── CLAUDE.md                           (this file)
└── .shamt/
    ├── guides/                         (the canonical guide system)
    │   ├── stages/                     # s1–s10 workflow guides
    │   ├── reference/
    │   ├── audit/
    │   ├── changelog_application/      # guides for applying changelogs
    │   └── master_dev_workflow/        # guide for improving master guides
    ├── initialization/
    │   ├── RULES_FILE.template.md      # AI rules file template
    │   ├── ARCHITECTURE.template.md
    │   ├── CODING_STANDARDS.template.md
    │   ├── EPIC_TRACKER.template.md
    │   ├── ai_services.md              # known AI service registry
    │   ├── init.sh
    │   └── init.ps1
    ├── epics/
    │   ├── EPIC_TRACKER.md             # master's own epic tracker
    │   ├── requests/
    │   ├── done/
    │   └── SHAMT-[N]-[name]/           # active epic folders
    ├── changelogs/
    │   ├── unapplied_external_changes/ # from child projects, not yet applied
    │   └── applied_external_changes/   # from child projects, already applied
    └── outbound_changelogs/
        ├── CHANGELOG_INDEX.md          # version record + index
        └── v[NNNN]_[description].md
```

---

## Applying a Child Changelog

When a child project submits a changelog file, place it in `.shamt/changelogs/unapplied_external_changes/` and follow:

**Guide:** `.shamt/guides/changelog_application/master_receiving_child_changelog.md`

Key steps:
1. Read the changelog entry carefully
2. Assess universality (does this apply to all Shamt versions, or is it child-specific?)
3. Apply relevant changes to the appropriate guide(s)
4. Run the guide audit: `.shamt/guides/audit/`
5. Assign the next version number and publish to `outbound_changelogs/`
6. Update `outbound_changelogs/CHANGELOG_INDEX.md`
7. Move the source file to `applied_external_changes/`

---

## Publishing an Outbound Changelog

After applying improvements (from child changelogs or master dev work):

**Guide:** `.shamt/guides/changelog_application/master_receiving_child_changelog.md` (versioning section)

Version numbering:
- Check `outbound_changelogs/CHANGELOG_INDEX.md` for the latest version number
- Increment by 1, zero-padded to 4 digits (e.g., `v0001`, `v0042`)
- Filename format: `v[NNNN]_[brief-description].md`
- Update `CHANGELOG_INDEX.md` immediately after publishing

---

## Master Dev Workflow

For improving the guides directly (not from a child changelog):

**Guide:** `.shamt/guides/master_dev_workflow/`

This is a lighter process than the full S1–S10 epic workflow, aligned with S10's guide update approach. Use epic tracking in `.shamt/epics/` for significant multi-guide changes.

---

## Updating the AI Service Registry

When a new AI service is discovered (reported by a child project or user):

1. Research the service's rules file convention
2. Add an entry to `.shamt/initialization/ai_services.md`
3. Write a changelog entry documenting the addition
4. Publish as an outbound changelog

---

## Git Conventions

- **Branch format:** `feat/SHAMT-{N}` or `fix/SHAMT-{N}`
- **Commit format:** `feat/SHAMT-{N}: {message}` or `fix/SHAMT-{N}: {message}`
- **Default branch:** `main`
- **No AI attribution** in commit messages

---

## Critical Rules

- Zero autonomous conflict resolution — always escalate to user when uncertain
- Run guide audit after every set of guide changes
- Update `CHANGELOG_INDEX.md` immediately when publishing a new version
- Never merge child changelogs automatically — always agent-reviewed
