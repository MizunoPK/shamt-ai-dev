# Shamt Master — Agent Rules

This is the **master Shamt repository**. You are working on the framework itself, not a child project.

Your primary responsibilities here are:
1. **Reviewing child PRs** — reviewing guide/script improvements submitted by child projects via pull request
2. **Master dev workflow** — making guide improvements using the standardized process
3. **AI service registry** — keeping `ai_services.md` up to date with new AI services

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
    │   ├── changelog_application/      # legacy guides (will be removed in Phase 4)
    │   └── master_dev_workflow/        # guide for improving master guides
    ├── scripts/
    │   ├── initialization/
    │   │   ├── RULES_FILE.template.md  # AI rules file template
    │   │   ├── ARCHITECTURE.template.md
    │   │   ├── CODING_STANDARDS.template.md
    │   │   ├── EPIC_TRACKER.template.md
    │   │   ├── ai_services.md          # known AI service registry
    │   │   ├── init.sh
    │   │   └── init.ps1
    │   ├── export/                     # export script (Phase 3)
    │   └── import/                     # import script (Phase 3)
    └── epics/
        ├── EPIC_TRACKER.md             # master's own epic tracker
        ├── requests/
        ├── done/
        └── SHAMT-[N]-[name]/           # active epic folders
```

---

## Reviewing Child Project PRs

Child projects submit guide and script improvements to master via pull request (not changelog files).

The PR description will reference `.shamt/CHANGES.md` from the child project for context.

Review steps:
1. Read the PR diff — assess whether changes are truly generic (applicable to all Shamt projects)
2. If generic: approve and merge
3. If project-specific content has leaked into shared files: request changes
4. After merging, the import script will distribute the improvement to other child projects on their next import

**Full workflow guide:** `.shamt/guides/` (export/import guides will be added in Phase 4)

---

## Master Dev Workflow

For improving the guides directly:

**Guide:** `.shamt/guides/master_dev_workflow/`

This is a lighter process than the full S1–S10 epic workflow, aligned with S10's guide update approach. Use epic tracking in `.shamt/epics/` for significant multi-guide changes.

---

## Updating the AI Service Registry

When a new AI service is discovered (reported by a child project or user):

1. Research the service's rules file convention
2. Add an entry to `.shamt/scripts/initialization/ai_services.md`
3. Update the init scripts if the service needs special handling
4. Commit the change with a descriptive message

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
- Never approve child PRs that contain project-specific content in shared guide files
