# Shamt Master — Agent Rules

This is the **master Shamt repository**. You are working on the framework itself, not a child project.

Your primary responsibilities here are:
1. **Reviewing child PRs** — reviewing guide/script improvements submitted by child projects via pull request
2. **Master dev workflow** — making guide improvements using the standardized process
3. **AI service registry** — keeping `ai_services.md` up to date with new AI services

---

## Project Structure

```text
shamt-ai-dev/
├── README.md
├── CLAUDE.md                           (this file)
├── design_docs/
│   ├── unimplemented/                  # design docs awaiting implementation + proposal docs from child projects
│   └── finished/                       # design docs that have been implemented
└── .shamt/
    ├── guides/                         (the canonical guide system)
    │   ├── stages/                     # s1–s10 workflow guides
    │   ├── reference/
    │   ├── audit/
    │   ├── sync/                       # README, separation rule, export workflow, import workflow
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
    │   ├── export/                     # export script
    │   └── import/                     # import script
    └── epics/
        ├── EPIC_TRACKER.md             # not actively maintained for master work — see Master Dev Workflow
        ├── requests/
        └── done/
```

---

## Reviewing Child Project PRs

Child projects submit guide and script improvements to master via pull request (not changelog files).

The PR description will reference `.shamt/CHANGES.md` from the child project for context.

Review steps:
1. Read the PR diff — assess whether changes are truly generic (applicable to all Shamt projects)
2. If project-specific content has leaked into shared files: request changes
3. If generic: approve and merge
4. After merging, run the full guide audit on the entire `.shamt/guides/` tree — do not let changes propagate to other child projects on their next import until the audit passes
5. Commit any audit fixes before the merge is considered complete

**Proposal docs:** Child PRs may include files in `design_docs/unimplemented/` (named `{project}-{epic}-SHAMT-UPDATE-PROPOSAL.md`). These are always acceptable — no generic/specific evaluation needed since they are explicitly project-originated proposals for guide changes, not shared guide files themselves. Review for obvious errors but do not apply the separation rule to them.

**Full workflow guides:** `.shamt/guides/sync/export_workflow.md` (child side) and `.shamt/guides/sync/import_workflow.md` (post-import validation)

---

## Master Dev Workflow

For improving the guides directly:

**Guide:** `.shamt/guides/master_dev_workflow/`

Master work does **not** follow the S1-S10 epic workflow and does **not** use EPIC_TRACKER.md. The operating model:

- **Small changes:** Lightweight workflow — read, fix, audit, commit directly to a branch, open PR
- **Large changes:** Create a design doc at `design_docs/unimplemented/SHAMT{N}_DESIGN.md` for planning, then work on a `feat/SHAMT-N` branch. When implementation is complete, move the doc to `design_docs/finished/SHAMT{N}_DESIGN.md`
- **SHAMT-N numbers:** Sequence markers for change sets, not epic identifiers
- **No stage gates:** Master work proceeds at judgment, not through S1-S10 phase transitions

---

## Design Doc Validation

When asked to validate a design doc (e.g., `design_docs/unimplemented/SHAMT{N}_DESIGN.md`), run a validation loop. Each round checks all dimensions:

1. **Completeness** — Are all necessary aspects covered? Is the problem fully stated? Are all affected files identified? Are edge cases and failure modes addressed?
2. **Correctness** — Are factual claims accurate? Do proposed changes actually work the way described? Are references to existing guides/files accurate?
3. **Consistency** — Is the design internally consistent? Does it conflict with existing guide conventions or other SHAMT decisions?
4. **Helpfulness** — Do the proposals actually solve the stated problem? Is the benefit worth the complexity added?
5. **Improvements** — Are there simpler or better ways to achieve the same goal?
6. **Missing proposals** — Is anything important left out of scope that should be addressed here?
7. **Open questions** — Are there unresolved decisions that need to be surfaced before implementation?

**Exit criterion:** Primary clean round (all 7 dimensions pass with no issues) + independent sub-agent confirmation. Same pattern as workflow validation loops: `consecutive_clean = 1`, then spawn 2 parallel sub-agents both confirming zero issues.

Any issue found in any dimension resets `consecutive_clean` to 0.

---

## Code Review Workflow

To review someone else's branch or PR (not your own epic work):

**Trigger phrases:** "review branch", "do a code review of", "review the changes on", "re-review"

**Guide:** `.shamt/guides/code_review/` (README → code_review_workflow.md)

**What it does:** Produces `.shamt/code_reviews/<sanitized-branch>/` with a validated `overview.md` (ELI5 + What/Why/How) and a versioned `review_vN.md` with copy-paste-ready PR comments.

**Key rules:**
- Never checks out the branch — read-only git commands only
- On re-review: creates `review_v2.md`, `review_v3.md`, etc. — never overwrites previous versions
- If branch cannot be fetched: halt and report to user immediately

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
- When any change affects system behavior (new sync scripts, new guides, new audit scope, new workflow steps): review and update the three master-only files that are not propagated via import — `CLAUDE.md`, root `README.md`, and `scripts/initialization/RULES_FILE.template.md`
- Guide audits require 3 CONSECUTIVE zero-issue rounds to exit (track `consecutive_clean >= 3`). Workflow validation loops (S7.P2, S9.P2, etc.) exit on **primary clean round + independent sub-agent confirmation** (`consecutive_clean = 1`, then spawn 2 parallel sub-agents both confirming zero issues). In both cases, track `consecutive_clean` explicitly and state it at the end of every round; rounds with issues reset the counter to 0.
