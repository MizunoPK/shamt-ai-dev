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
├── design_docs/                        # Design doc lifecycle management
│   ├── active/                         # Design docs being worked on
│   │   └── SHAMT{N}_DESIGN.md
│   ├── incoming/                       # Child project proposals awaiting review
│   ├── archive/                        # Implemented design docs
│   │   └── rejected/                   # Rejected child proposals
│   └── NEXT_NUMBER.txt                 # Next SHAMT-N number
└── .shamt/
    ├── guides/                         (the canonical guide system)
    │   ├── stages/                     # s1–s10 workflow guides
    │   ├── reference/
    │   ├── audit/
    │   ├── sync/                       # README, separation rule, export workflow, import workflow
    │   ├── master_dev_workflow/        # guide for improving master guides
    │   ├── design_doc_validation/      # design doc validation guides
    │   └── templates/                  # templates (design_doc_template.md)
    ├── scripts/
    │   ├── initialization/
    │   │   ├── init.sh / init.ps1                           # Full Shamt initialization
    │   │   ├── init_lite.sh / init_lite.ps1                 # Shamt Lite initialization
    │   │   ├── RULES_FILE.template.md                       # AI rules file template (full)
    │   │   ├── SHAMT_LITE.template.md                       # Standalone lite rules file
    │   │   ├── ARCHITECTURE.template.md                     # Full template
    │   │   ├── CODING_STANDARDS.template.md                 # Full template
    │   │   ├── EPIC_TRACKER.template.md
    │   │   ├── ai_services.md                               # Known AI service registry
    │   │   ├── reference/
    │   │   │   ├── severity_classification_lite.md
    │   │   │   ├── validation_exit_criteria_lite.md
    │   │   │   └── question_brainstorm_categories_lite.md
    │   │   └── templates/
    │   │       ├── discovery_lite.template.md
    │   │       ├── code_review_lite.template.md
    │   │       ├── architecture_lite.template.md
    │   │       └── coding_standards_lite.template.md
    │   ├── export/                     # export script
    │   ├── import/                     # import script
    │   └── storage/                    # store/get .shamt/ across machines
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

**Proposal docs:** Child PRs may include proposal files (named `{project}-{epic}-SHAMT-UPDATE-PROPOSAL.md`) that were exported to `design_docs/incoming/`. These are always acceptable — no generic/specific evaluation needed since they are explicitly project-originated proposals for guide changes, not shared guide files themselves. Review for obvious errors but do not apply the separation rule to them. See "Child Proposal Handling" section for the promotion/rejection process.

**Full workflow guides:** `.shamt/guides/sync/export_workflow.md` (child side) and `.shamt/guides/sync/import_workflow.md` (post-import validation)

---

## Master Dev Workflow

For improving the guides directly:

**Guide:** `.shamt/guides/master_dev_workflow/`

Master work does **not** follow the S1-S10 epic workflow and does **not** use EPIC_TRACKER.md. The operating model:

- **Small changes:** Lightweight workflow — read, fix, audit, commit directly to a branch, open PR
- **Large changes:** Create a design doc in `design_docs/active/` (version-controlled), validate it, implement, then archive to `design_docs/archive/`
- **SHAMT-N numbers:** Sequence markers for change sets, not epic identifiers. Reserved via `design_docs/NEXT_NUMBER.txt`
- **No stage gates:** Master work proceeds at judgment, not through S1-S10 phase transitions

See "Design Doc Lifecycle" below for the full design doc process.

---

## Design Doc Lifecycle

**When to create a design doc:**
- Large changes requiring planning (multi-guide, cross-cutting, architectural)
- Changes affecting multiple system behaviors
- When user requests "create a design doc"
- Judgment call — lightweight workflow works for simple fixes

**How to create a design doc:**

1. **Reserve SHAMT-N number:** Read `design_docs/NEXT_NUMBER.txt` (e.g., contains "27"), use that number, increment the file to "28", commit
2. **Create from template:** Use `.shamt/guides/templates/design_doc_template.md` to create `design_docs/active/SHAMT{N}_DESIGN.md`
3. **Write design:** Capture problem statement, goals, proposals, implementation plan, validation strategy
4. **Validate:** Run 7-dimension validation loop (see Design Doc Validation section below)
5. **Implement:** Execute implementation plan on `feat/SHAMT-N` branch
6. **Validate implementation:** Run implementation validation loop (see Implementation Validation section below)
7. **Archive:** Move `SHAMT{N}_DESIGN.md` and validation log to `design_docs/archive/` when complete

**Lifecycle states:**
- **Draft** (`active/`) — Being written, not yet validated
- **Validated** (`active/`) — Passed 7-dimension validation, ready for implementation
- **In Progress** (`active/`) — Implementation underway on branch
- **Implemented** (`archive/`) — Implementation complete, branch merged

**Validation log:** Create `SHAMT{N}_VALIDATION_LOG.md` alongside design doc when starting validation. Moves to archive with design doc.

---

## Design Doc Validation

When asked to validate a design doc, run a validation loop following `.shamt/guides/design_doc_validation/validation_workflow.md`.

**The 7 dimensions:**

1. **Completeness** — Are all necessary aspects covered? Is the problem fully stated? Are all affected files identified? Are edge cases and failure modes addressed?
2. **Correctness** — Are factual claims accurate? Do proposed changes actually work the way described? Are references to existing guides/files accurate?
3. **Consistency** — Is the design internally consistent? Does it conflict with existing guide conventions or other SHAMT decisions?
4. **Helpfulness** — Do the proposals actually solve the stated problem? Is the benefit worth the complexity added?
5. **Improvements** — Are there simpler or better ways to achieve the same goal?
6. **Missing proposals** — Is anything important left out of scope that should be addressed here?
7. **Open questions** — Are there unresolved decisions that need to be surfaced before implementation?

**Exit criterion:** Primary clean round (all 7 dimensions pass with ≤1 LOW-severity issue) + 2 independent sub-agents both confirming zero issues. Same pattern as workflow validation loops: `consecutive_clean = 1`, then spawn 2 parallel sub-agents.

A round is clean if it has ZERO issues OR exactly ONE LOW-severity issue (fixed). Multiple LOW-severity issues OR any MEDIUM/HIGH/CRITICAL severity issue resets `consecutive_clean` to 0. See `reference/severity_classification_universal.md` for severity definitions.

**Detailed workflow:** See `.shamt/guides/design_doc_validation/` for complete validation process, validation log template, and guidance.

---

## Implementation Validation

After implementing a design doc (Phases 1-4 complete), run an implementation validation loop to verify the design was fully and correctly implemented.

**The 5 dimensions:**

1. **Completeness** — Was every proposal implemented? Walk through all proposals and verify corresponding changes exist.
2. **Correctness** — Does the implementation match what was proposed? Check folder structures, file contents, script changes.
3. **Files Affected Accuracy** — Were all files in the "Files Affected" table actually created/modified/moved as specified?
4. **No Regressions** — Did the implementation break anything that was working before?
5. **Documentation Sync** — Do CLAUDE.md, master_dev_workflow.md, and other guides accurately reflect the new system?

**Exit criterion:** Same as design doc validation — primary clean round (≤1 LOW-severity issue) + 2 independent sub-agent confirmations.

**After implementation validation passes:** Run a full guide audit on the entire `.shamt/guides/` tree (not just files affected by the design doc) to ensure the repo is in a healthy state. The audit must achieve 3 consecutive clean rounds.

---

## Child Proposal Handling

Child projects can export design proposals to master via the export script. Proposals land in `design_docs/incoming/`.

**Review process:**
1. Read the proposal file in `incoming/`
2. Assess whether it warrants a full design doc or can be handled as a direct guide update
3. **If promoting to design doc:** Reserve SHAMT-N, create design doc in `active/` incorporating the proposal, delete or archive the original proposal
4. **If rejecting:** Move to `archive/rejected/` with a rejection note at the top of the file explaining why
5. **If implementing directly:** Make the guide changes, reference the proposal in commit message, archive the proposal

**Naming convention:** Child proposals use `{project}-{epic}-SHAMT-UPDATE-PROPOSAL.md` format for traceability.

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

## Shamt Lite

**What it is:** A standalone lightweight version of Shamt (10 files total) that provides validation loops, discovery protocol, and code review workflows without the full S1-S10 epic framework.

**Target users:** Developers who want quality patterns and systematic validation but don't need epic tracking or the full workflow.

**Master repo storage:** All Shamt Lite files are stored in `.shamt/scripts/initialization/`:
- `SHAMT_LITE.template.md` — Standalone rules file with 5 core patterns
- `init_lite.sh` / `init_lite.ps1` — Initialization scripts
- `reference/` — 3 reference files (severity, validation, question brainstorming)
- `templates/` — 4 templates (discovery, code review, architecture, coding standards)

**Deployment:** When users run `init_lite.sh` or `init_lite.ps1`, these files are copied to `shamt-lite/` in their project with template variables replaced ({{PROJECT_NAME}}, {{DATE}}).

**Key principle:** `SHAMT_LITE.md` is standalone and executable. An agent can run all 5 patterns using only Part 1 of that file without reading any supporting files. Supporting files in `reference/` and `templates/` provide optional depth and copy-paste convenience.

**When to update Shamt Lite:**
- When validation loop mechanics change in the canonical guides
- When severity classification rules are refined
- When discovery protocol or question brainstorming framework improves
- When code review workflow is updated
- Never copy epic-specific content into lite files

**Maintenance rule:** Shamt Lite files are NOT synced via import/export. They are maintained directly in the master repo and versioned independently.

---

## Architecture & Coding Standards Maintenance

Child projects maintain ARCHITECTURE.md and CODING_STANDARDS.md through the S1-S10 workflow:

- **S1.P3 Discovery:** Review existing docs, check for undocumented additions (Step 3b)
- **S7.P3 Final Review:** Complete Documentation Impact Assessment (Step 1b)
- **S10 Cleanup:** Final Architecture/Standards Review (Step 3e)

**Audit:** D23 (Architecture/Standards Currency) validates document freshness and accuracy during audits. Threshold: 60 days.

**Master role:** When reviewing child PRs that update these templates, verify metadata sections (Last Updated, Update History, Update Triggers, How to Update) are present.

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
- Guide audits require 3 CONSECUTIVE clean rounds (where each round has ≤1 LOW-severity issue) to exit (track `consecutive_clean >= 3`). Workflow validation loops (S7.P2, S9.P2, etc.) exit on **primary clean round + independent sub-agent confirmation** (`consecutive_clean = 1`, then spawn 2 parallel sub-agents both confirming zero issues). A round is clean if it has ZERO issues OR exactly ONE LOW-severity issue (fixed). Multiple LOW-severity issues OR any MEDIUM/HIGH/CRITICAL severity issue resets `consecutive_clean` to 0. Track `consecutive_clean` explicitly and state it at the end of every round. See `reference/severity_classification_universal.md` for severity definitions.

---

## Model Selection for Token Optimization (SHAMT-27)

**Purpose:** Save 30-50% tokens across workflows through strategic model delegation

**Quick Reference:**
- **Haiku** (cheap, fast): File operations, git operations, grep/glob searches, tests, sub-agent confirmations
- **Sonnet** (balanced): Code reading, structural analysis, medium-complexity tasks
- **Opus** (deep reasoning): Validation, root cause analysis, design decisions, complex multi-dimensional checks

**Key Workflows:**
- **Guide Audit:** 40-50% savings (Haiku for pre-checks/counting, Sonnet for structural, Opus for content)
- **Validation Loops:** 30-45% savings (Haiku for mechanical, Sonnet for code reading, Opus for validation)
- **Code Review:** 30-40% savings (Haiku for git ops, Sonnet for ELI5, Opus for issue classification)
- **Sub-Agent Confirmations:** 70-80% savings (always use Haiku - focused verification, not deep reasoning)

**Complete Guide:** See `.shamt/guides/reference/model_selection.md` for decision framework, task catalog, Task tool examples, and common mistakes.

**When to Use:** Spawn sub-agents with the `model` parameter in the Task tool when delegation will save tokens without degrading quality. Always delegate sub-agent confirmations to Haiku.

**When NOT to Use:** Parallel work coordination (use Sonnet for consistency), tasks requiring existing context (avoid context switching overhead).
