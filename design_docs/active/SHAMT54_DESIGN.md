# SHAMT-54: Shamt Lite Cheat Sheet

**Status:** Draft
**Created:** 2026-05-04
**Branch:** `feat/SHAMT-54`
**Depends on:** SHAMT-52 (regen-lite scripts must exist for the regen-time phases to apply)

---

## Problem Statement

Shamt Lite has no cheat sheet. Full-Shamt generates `.shamt/CHEATSHEET.md` via
`regen-claude-shims.sh` / `regen-codex-shims.sh` — filtered by AI service, PR provider, repo
type, and active hooks — giving users an always-current at-a-glance reference for their
specific setup. Shamt Lite users have no equivalent and must mentally scan `SHAMT_LITE.md`
(a dense 600-line reference file) to recall which slash commands exist, what Codex profiles
to switch between, or what the six phases are called.

---

## Goals

1. Generate `shamt-lite/CHEATSHEET.md` at `init_lite.sh` time and on every regen-lite run.
2. Content is useful at a glance: six-phase story map, 5 patterns one-liner each, available
   commands/skills/profiles by AI service, validation rules, context-clear breakpoints.
3. Service differentiation matches the user's actual setup (Claude Code slash commands if
   regen-lite-claude ran, Codex profiles if regen-lite-codex ran, Cursor rules if
   regen-lite-cursor ran, or a generic "no host" variant).
4. `CHEATSHEET.md` stays untracked (it is generated and project-specific — same policy as
   full-Shamt's cheat sheet).

---

## Non-Goals

- This is not a new SHAMT_LITE.md / story_workflow_lite.md. The cheat sheet is a generated
  reference card, not editable canonical content.
- This does not add new commands, skills, or profiles — it documents what SHAMT-52 already
  deployed.
- No AI-service detection heuristic. The service is written to a config file at init time;
  regen reads that config. If no config exists, a generic (host-agnostic) cheat sheet is
  generated.

---

## Design

### Proposal 1 — AI service config file

`init_lite.sh` (and `.ps1`) writes `shamt-lite/config/ai_service.conf` based on the
`--host` flag passed at init time. If no `--host` is given, it writes `none`.

```
shamt-lite/
└── config/
    └── ai_service.conf    # one of: claude, codex, cursor, claude_codex, claude_cursor,
                            #         codex_cursor, claude_codex_cursor, none
```

The file contains a single word (the comma-joined host list, normalized). Examples:
- `init_lite.sh --host=claude` → `claude`
- `init_lite.sh --host=claude,codex` → `claude_codex`
- `init_lite.sh` (no host) → `none`

**Gitignore:** `shamt-lite/config/` is added to `shamt-lite/.gitignore` — this config is
machine-specific (like full-Shamt's `.shamt/config/`).

### Proposal 2 — Cheat sheet content (service-differentiated)

The cheat sheet is a generated Markdown file. A Python script embedded in each init/regen
script writes it. The script reads `shamt-lite/config/ai_service.conf` to determine which
sections to include.

**Sections (all services):**

```markdown
# Shamt Lite — Cheat Sheet

## Six-Phase Story Workflow
(condensed table: Phase | Artifact | Gate)

## Core Patterns
(5 one-liners: when to use each pattern)

## Validation Rules
(consecutive_clean logic, 1 sub-agent, severity quick ref)

## Context-Clear Breakpoints
(after Gate 2b, after Gate 3)

## Builder Handoff
(>10 mechanical steps → spawn Haiku builder)
```

**Service-specific sections appended after the common content:**

**Claude Code (`claude` in ai_service.conf):**
```markdown
## Slash Commands
| Command | What it does |
|---------|-------------|
| `/lite-story` | Start a new story (Intake phase) |
| `/lite-spec {slug}` | Run Spec phase for a story |
| `/lite-plan {slug}` | Run Plan phase for a story |
| `/lite-review {slug}` | Run Review phase for a story |
| `/lite-validate` | Run a validation loop on the current artifact |

## Skills (auto-triggered)
| Skill | Trigger phrase |
|-------|---------------|
| `shamt-lite-story` | "start a story", "new story" |
| `shamt-lite-spec` | "run spec", "write spec for" |
| `shamt-lite-plan` | "write plan", "create implementation plan" |
| `shamt-lite-review` | "review the code", "run code review" |

## Personas
| Persona | Use |
|---------|-----|
| `shamt-lite-builder` | Haiku — executes mechanical implementation plans |
| `shamt-lite-validator` | Haiku — sub-agent confirmation of validation loops |
```

**Codex (`codex` in ai_service.conf):**
```markdown
## Codex Profiles
Switch profiles at phase boundaries:
| Phase | Profile flag |
|-------|-------------|
| Intake | `codex --profile shamt-lite-intake` |
| Spec (research) | `codex --profile shamt-lite-spec-research` |
| Spec (design) | `codex --profile shamt-lite-spec-design` |
| Spec (validation) | `codex --profile shamt-lite-spec-validate` |
| Plan | `codex --profile shamt-lite-plan` |
| Build | `codex --profile shamt-lite-build` |
| Review | `codex --profile shamt-lite-review` |
| Validation sub-agent | `codex --profile shamt-lite-validator` |

Phase transitions are session boundaries — relaunch Codex with the new profile.
```

**Cursor (`cursor` in ai_service.conf):**
```markdown
## Cursor Rules
Shamt Lite .mdc rules are active in `.cursor/rules/`. They auto-attach based on file
glob patterns; no manual activation needed for story-folder work.

To explicitly invoke a pattern, reference it by name in your prompt:
- "run the spec protocol for {slug}"
- "write an implementation plan"
- "validate this artifact"
- "do a code review of this branch"
```

**Generic / no host (`none` in ai_service.conf):**
```markdown
## Natural Language Triggers
No host-specific commands are set up. Reference patterns by name in your prompt:
- "run the spec protocol" → Pattern 3
- "validate this" → Pattern 1
- "write an implementation plan" → Pattern 5
- "code review" → Pattern 4 (formal mode)
- "start a story" → story_workflow_lite.md workflow
```

### Proposal 3 — Generation sites

The cheat sheet is generated in three places:

**3a. `init_lite.sh` / `init_lite.ps1`** — final phase, after all other files are written.
Writes `shamt-lite/CHEATSHEET.md` and adds `CHEATSHEET.md` to `shamt-lite/.gitignore`.

**3b. `regen-lite-claude.sh` / `.ps1`** — new final phase added to the regen script.
Reads `shamt-lite/config/ai_service.conf` from the target project. Regenerates
`shamt-lite/CHEATSHEET.md`. (Depends on SHAMT-52 for the regen-lite-claude script to exist.)

**3c. `regen-lite-codex.sh` / `.ps1`** — same as 3b but for the Codex regen script.

**3d. `regen-lite-cursor.sh` / `.ps1`** — same as 3b but for the Cursor regen script.

### Proposal 4 — CHEATSHEET.md gitignore

`shamt-lite/.gitignore` already exists on SHAMT-52 for `host/codex/.model_resolution.local.toml`
and `host/cursor/.model_resolution.local.toml`. This proposal adds:

```
CHEATSHEET.md
config/
```

Both are machine-specific generated artifacts.

### Proposal 5 — CLAUDE.md update

The Shamt Lite section of CLAUDE.md currently says nothing about a cheat sheet.
Add a line noting that `init_lite.sh` generates `shamt-lite/CHEATSHEET.md` (gitignored,
service-specific).

---

## Open Questions

**OQ1 — Should the cheat sheet be a static template instead of generated?**
Static would be simpler (no Python generator, no config file) but can't differentiate by
service. The full-Shamt precedent is generated. Decision: generated, matching full-Shamt's
approach.

**OQ2 — What if the user changes hosts after init?**
They'd re-run the appropriate regen-lite script, which regenerates the cheat sheet for the
new host. Or they could re-run `init_lite.sh --host=...` in an existing project (which
currently errors if `shamt-lite/` already exists). That error behavior is out of scope here —
this design only handles the generation side.

**OQ3 — Should `shamt-lite/config/` be gitignored or tracked?**
Decision: gitignored. It's machine-specific (same reasoning as `.shamt/config/` in full-Shamt).
The ai_service choice is inherent to the developer's machine setup, not the project itself.

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/scripts/initialization/init_lite.sh` | MODIFY | Add config/ write + cheat sheet phase |
| `.shamt/scripts/initialization/init_lite.ps1` | MODIFY | Same |
| `.shamt/scripts/regen/regen-lite-claude.sh` | MODIFY | Add cheat sheet phase (SHAMT-52 dep) |
| `.shamt/scripts/regen/regen-lite-claude.ps1` | MODIFY | Same |
| `.shamt/scripts/regen/regen-lite-codex.sh` | MODIFY | Same |
| `.shamt/scripts/regen/regen-lite-codex.ps1` | MODIFY | Same |
| `.shamt/scripts/regen/regen-lite-cursor.sh` | MODIFY | Same |
| `.shamt/scripts/regen/regen-lite-cursor.ps1` | MODIFY | Same |
| `CLAUDE.md` | MODIFY | Note cheat sheet in Shamt Lite section |

**Legend:** MODIFY = existing file changed; KEEP = file referenced but must NOT be changed.

**Note on SHAMT-52 dependency:** The regen-lite-*.sh/.ps1 files exist only on `feat/SHAMT-52`.
Implementation of this design must be applied on top of SHAMT-52 (either after it merges to
main, or on a branch forked from feat/SHAMT-52).

---

## Implementation Plan

### Phase 1: Reconnaissance
- Read current `init_lite.sh` and `init_lite.ps1` fully (both live and SHAMT-52 versions)
- Read all 8 regen-lite scripts from feat/SHAMT-52
- Confirm exact insertion points for config write and cheat sheet phase

### Phase 2: Add config/ write to init_lite.sh/.ps1
- After host flag parsing and before the success message, write `shamt-lite/config/ai_service.conf`
- Normalize host list (comma-separated, alphabetically sorted, underscore-joined: `claude_codex`)
- Add `config/` and `CHEATSHEET.md` to the `.gitignore` block in both scripts

### Phase 3: Implement cheat sheet generator (shared Python)
- Write the Python script inline (heredoc) that:
  1. Reads `shamt-lite/config/ai_service.conf`
  2. Produces the common sections
  3. Appends service-specific sections based on the config value
  4. Writes `shamt-lite/CHEATSHEET.md`
- Test logic against all service variants: `claude`, `codex`, `cursor`, `claude_codex`,
  `claude_cursor`, `codex_cursor`, `claude_codex_cursor`, `none`

### Phase 4: Add cheat sheet phase to init_lite.sh/.ps1
- Invoke the Phase 3 Python script as the final phase of `init_lite.sh`
- Add `CHEATSHEET.md` to success message file listing
- Repeat for `init_lite.ps1`

### Phase 5: Add cheat sheet phase to each regen-lite script (8 scripts)
- For each of the 8 regen-lite scripts: add a final cheat sheet phase
- Each regen-lite script knows its own host (claude/codex/cursor); write or update
  `shamt-lite/config/ai_service.conf` before generating the cheat sheet
- The cheat sheet must reflect the currently active host (even if a different host was
  previously configured)

### Phase 6: Update CLAUDE.md
- Add one sentence to the Shamt Lite section noting cheat sheet generation

### Phase 7: Validation
- Run implementation validation loop (5 dimensions)
- Run full guide audit (3 consecutive clean rounds)
- Commit and open PR

---

## Validation Strategy

### Implementation validation (5 dimensions)
1. **Completeness** — All 8 regen scripts + both init scripts updated; config/ write present
2. **Correctness** — ai_service.conf values match all `--host` combination inputs; cheat sheet
   sections appear iff the matching service is in the config; gitignore entries correct
3. **Files Affected Accuracy** — All MODIFY files changed; no accidental changes to KEEP files
4. **No Regressions** — Existing regen-lite output (skills, commands, agents, profiles) unchanged
5. **Documentation Sync** — CLAUDE.md Lite section reflects cheat sheet; regen/README.md accurate

### Guide audit (3 consecutive clean rounds)
Standard 23-dimension + D-DRIFT + D-COVERAGE audit after implementation.
