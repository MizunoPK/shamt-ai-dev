# SHAMT-50: Command and Skill UX Clarity

**Status:** Validated
**Created:** 2026-05-03
**Branch:** `feat/SHAMT-50`
**Validation Log:** [SHAMT50_VALIDATION_LOG.md](./SHAMT50_VALIDATION_LOG.md)

---

## Problem Statement

Three related UX problems exist in the commands, skills, and CHEATSHEET deployed by `regen-claude-shims.sh`:

**Problem 1 — Unhelpful previews.** `regen-claude-shims.sh` prepends the managed header (`<!-- Managed by Shamt — do not edit... -->`) to every deployed command and skill file. Claude Code uses the first line of a command file as its description in the command palette, and displays the first line of a skill file as its description in the system-reminder skill listing. This means every Shamt command and skill shows the same useless managed comment instead of a meaningful description. A user typing `/shamt-` sees commands that all look identical until they open each one.

For skills, the managed header also sits *before* the YAML `---` frontmatter delimiter, which technically breaks YAML frontmatter parsing (frontmatter must start at the very beginning of the file). The `description:` field in the frontmatter is therefore never read by parsers that expect spec-compliant frontmatter.

**Problem 2 — Confusing naming.** The generated `.shamt/CHEATSHEET.md` (produced by the regen script) tells users "use `/shamt-validate` with `/loop`", and the system-reminder skill listing shows `shamt-validation-loop` as a separate-looking entry. There is no `/shamt-validation-loop` slash command — it is the internal skill invoked by `/shamt-validate`. A user who sees both entries reasonably wonders whether they are two different tools. Additionally, some CHEATSHEET rows reference `shamt-validation-loop` as if it were user-invokable (e.g., the AskUserQuestion decision table), compounding the confusion.

**Problem 3 — `/loop` presented as required.** The CHEATSHEET says "use with `/loop`" for both `/shamt-validate` and `/shamt-audit`. But the `shamt-validation-loop` skill already encodes a complete multi-round protocol: its "Round Structure" section says "Repeat Every Round" and the exit criteria drive termination — the loop is self-contained. The command's own "What Happens" section explicitly says "Continues until a primary clean round is achieved." There is no reason the user must prepend `/loop`. The `/loop` + `ScheduleWakeup` mechanism is an optional enhancement for very large artifacts or many-round sessions where context may be exhausted — not the primary usage pattern. Presenting it as required creates confusion and implies the commands are single-shot tools that need external looping.

---

## Goals

1. Every deployed slash command shows a meaningful one-line description when previewed in the Claude Code command palette.
2. Every deployed skill shows a meaningful description in the Claude Code system-reminder skill listing.
3. YAML frontmatter in skill files is spec-compliant (frontmatter delimiter `---` is the very first line of the file).
4. The CHEATSHEET clearly distinguishes `/shamt-validate` (user slash command) from `shamt-validation-loop` (internal skill).
5. `/shamt-validate` and `/shamt-audit` are documented as self-contained loops that run to completion on their own; `/loop` is positioned as an optional context-management tool, not a required wrapper.
6. The `shamt-validation-loop` skill's `/loop` self-pacing section is repositioned as an advanced/optional section, not the primary invocation pattern.
7. All fixes are applied to canonical source files — no manual edits to generated files in `.claude/`.

---

## Detailed Design

### Proposal 1: Append managed header to end of deployed files

**Description:** Change `regen-claude-shims.sh` to write the managed header as a trailing HTML comment at the *end* of each deployed command and skill file, rather than prepending it. The actual content (command title, skill frontmatter) becomes the first line, which is what Claude Code reads for previews and system-reminder listings.

For commands: source files in `.shamt/commands/*.md` start with `# /shamt-<name>` followed by `**Purpose:** ...`. Moving the header to the end means Claude Code sees the command title or purpose as the effective description.

For skills: source files in `.shamt/skills/*/SKILL.md` start with `---` YAML frontmatter containing a `description:` field. Moving the header to the end makes the frontmatter spec-compliant and allows parsers to read the `description:` value.

**Impact on `is_shamt_managed()`:** The function currently uses `head -1 "$file" | grep -q "Managed by Shamt"`. With the header at the end, this must change to `grep -q "Managed by Shamt" "$file"` (whole-file search). This is more permissive, not less — a user-authored file that never contained the header will still not be overwritten.

**Alternatives considered:**
- *Add explicit description frontmatter to command files*: Would require updating 8 source files and changing the regen commands phase. Appending the header achieves the same outcome with a one-line regen change.
- *Separate `.description` sidecar files*: Too complex; no prior art in this codebase.

### Proposal 2: Clarify `shamt-validation-loop` vs `/shamt-validate` in CHEATSHEET

**Description:** Update `.shamt/commands/CHEATSHEET.md` to:

1. Add a note at the top of the `## Gate Prompts (AskUserQuestion — SHAMT-45)` section (before the table): "`shamt-validation-loop` is the internal skill invoked by `/shamt-validate` — use `/shamt-validate` to trigger these gates; do not invoke the skill directly."
2. Leave `shamt-validation-loop` in the Skill column of rows 162–163 unchanged — it IS a skill, the column is labeled "Skill", and all other rows use skill names. Replacing it with `/shamt-validate` (a command name) would create a column type inconsistency. The note above the table provides the necessary disambiguation.

The skill name itself is correct and widely referenced in guides, CLAUDE.md, and composites — renaming it would be a large blast radius for a cosmetic issue.

### Proposal 3: Reposition `/loop` as optional in commands and skill

**Description:** Three coordinated changes:

**3a — Update command source files (`.shamt/commands/shamt-validate.md` and `shamt-audit.md`):**
- The Usage sections already show the correct primary form (`/shamt-validate {artifact}`, no `/loop` prefix); no changes needed there.
- Add a Notes bullet to each: "For very large artifacts or many-round sessions where context may be exhausted, use `/loop /shamt-validate {artifact}` to enable session-break checkpointing between rounds."

**3b — Update the `shamt-validation-loop` skill (`shamt-validation-loop/SKILL.md`):**
- The `## /loop Self-Pacing (Claude Code)` section is already a top-level section at line 310 (after `## Validation Log Format`, before `## Exit Criteria`) — it is NOT inside the Protocol section. The `## Cloud-Task-as-Confirmer-Instance Variant` at line 389 is also a top-level section in the same area.
- Restructure in place: add a new `## Advanced Options` section at line 310, demote `## /loop Self-Pacing (Claude Code)` to `###` and `## Cloud-Task-as-Confirmer-Instance Variant` to `###` as subsections under it. The final order will be: `## Validation Log Format` → `## Advanced Options` (with `###` subsections) → `## Exit Criteria` → `## Quick Reference`.
- Add an "Optional" preamble at the top of `## Advanced Options`: "**Optional — only needed for very large artifacts or many-round sessions.** By default, the validation loop runs all rounds in a single invocation. Use `/loop` self-pacing when context exhaustion is a risk."
- Within the `/loop` subsection: remove the instruction "When the user invokes `/shamt-validate`... call `ScheduleWakeup`" — replace with: "If the session is at risk of context exhaustion, call `ScheduleWakeup` after each round to enable a session break."
- The main `## Protocol` section (line 51) describes the complete multi-round loop already; no changes needed there.

**3c — Update regen script Phase 5 (cheat sheet generation):**
The "use with `/loop`" text is not in the source CHEATSHEET — it is hardcoded in the Python block of `regen-claude-shims.sh` Phase 5 (lines 421–422 for the Slash Commands bullet list, line 499 for the Claude Code Tips bullet). Fix those three `lines.append(...)` calls:
- Line 421: change `'- \`/shamt-validate\` — run validation loop (use with \`/loop\`)'` → `'- \`/shamt-validate {artifact}\` — run validation loop to completion (self-terminating)'`
- Line 422: change `'- \`/shamt-audit\` — run guide audit (use with \`/loop\`)'` → `'- \`/shamt-audit\` — run guide audit to completion (3 consecutive clean rounds)'`
- Line 499: change `'- \`/loop\` with \`/shamt-validate\` self-paces validation rounds'` → `'- Prefix \`/loop\` only if context exhaustion is a risk (very large artifact, 5+ expected rounds)'`

**Rationale:** The skill's Round Structure is already a proper loop — it repeats until `consecutive_clean` meets the exit criterion, then exits. Claude running in a single invocation handles this natively without any `/loop` mechanism. The `/loop` + `ScheduleWakeup` pattern is only needed when a very large artifact or many rounds would push the session context to its limit. Making this the primary documented pattern misleads users into thinking the commands are single-shot and require external looping to work correctly.

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/scripts/regen/regen-claude-shims.sh` | MODIFY | (1) Append managed header to end for commands, skills, agents; change `is_shamt_managed()` to `grep -q`; (2) Phase 5 Python: fix three `lines.append()` calls that hardcode "use with `/loop`" |
| `.shamt/commands/shamt-validate.md` | MODIFY | Add advanced `/loop` note to Notes section (Usage and What Happens already correct) |
| `.shamt/commands/shamt-audit.md` | MODIFY | Same — add advanced `/loop` note only |
| `.shamt/skills/shamt-validation-loop/SKILL.md` | MODIFY | Move `/loop` self-pacing section to "Advanced Options"; default protocol describes single-invocation loop |
| `.shamt/commands/CHEATSHEET.md` | MODIFY | Add disambiguating note above Gate Prompts table; leave skill column entries unchanged |
| `.claude/commands/*.md` (all command files) | REGENERATE | Fixed automatically when regen runs |
| `.claude/skills/*/SKILL.md` (all skill files) | REGENERATE | Fixed automatically when regen runs |
| `.claude/agents/*.md` (all agent files) | REGENERATE | Fixed automatically when regen runs (header moves to end, YAML frontmatter becomes spec-compliant) |

---

## Implementation Plan

### Phase 1: Update regen script

- [ ] Open `.shamt/scripts/regen/regen-claude-shims.sh`
- [ ] In the **commands phase** (~line 219): change from prepend to append — `cat "$cmd_file"` then `printf '\n%s\n' "$MANAGED_HEADER"`
- [ ] In the **skills phase** (~line 101): change from prepend to append — `cat "$skill_src"` then `printf '\n%s\n' "$MANAGED_HEADER"`
- [ ] Update `is_shamt_managed()` (~line 58): change `head -1 "$file" | grep -q "Managed by Shamt"` to `grep -q "Managed by Shamt" "$file"`
- [ ] Agents phase (~line 178): change Python to write content first, then append managed header as the final line (same pattern as commands/skills)

### Phase 2: Update command source files

- [ ] Open `.shamt/commands/shamt-validate.md`
  - [ ] Verify the "Usage" code block shows only `/shamt-validate {artifact}` with no `/loop` prefix (already correct — confirm, don't change)
  - [ ] Confirm "What Happens" steps 6-9 already describe a complete self-terminating loop (they do — confirm, don't change)
  - [ ] Add a Notes bullet: "For very large artifacts or sessions likely to span many rounds, prefix with `/loop` to enable context-checkpoint recovery between rounds. Not required for typical use."
- [ ] Open `.shamt/commands/shamt-audit.md`
  - [ ] Same treatment — confirm the "What Happens" already says "Continues until 3 consecutive clean rounds"; add the same `/loop` advanced note

### Phase 3: Update the validation loop skill

- [ ] Open `.shamt/skills/shamt-validation-loop/SKILL.md`
- [ ] Locate `## /loop Self-Pacing (Claude Code)` at line 310 and `## Cloud-Task-as-Confirmer-Instance Variant` at line 389 — both are top-level sections already positioned between `## Validation Log Format` and `## Exit Criteria`
- [ ] Insert a new `## Advanced Options` header at line 310 (before the `/loop` section), with preamble: "**Optional — only needed for very large artifacts or many-round sessions.** By default, the validation loop runs all rounds in a single invocation. Use `/loop` self-pacing when context exhaustion is a risk."
- [ ] Demote `## /loop Self-Pacing (Claude Code)` from `##` to `###` (making it a subsection of Advanced Options)
- [ ] Demote `## Cloud-Task-as-Confirmer-Instance Variant` from `##` to `###` (making it the second subsection of Advanced Options)
- [ ] Within the `/loop` subsection: remove the instruction "When the user invokes `/shamt-validate`... call `ScheduleWakeup`" — that phrasing positions ScheduleWakeup as automatic on every invoke. Replace with: "If the session is at risk of context exhaustion, call `ScheduleWakeup` after each round to enable a session break."
- [ ] Leave `## Protocol`, `## The 7 Master Dimensions`, `## Severity Classification`, `## Validation Log Format`, `## Exit Criteria`, and `## Quick Reference` unchanged — no structural moves needed for those

### Phase 4: Fix regen script Phase 5 + source CHEATSHEET decision table

**4a — Regen script Phase 5 (hardcoded "use with `/loop`" text):**
- [ ] Open `.shamt/scripts/regen/regen-claude-shims.sh`
- [ ] Line 421: change `'- \`/shamt-validate\` — run validation loop (use with \`/loop\`)'` → `'- \`/shamt-validate {artifact}\` — run validation loop to completion (self-terminating)'`
- [ ] Line 422: change `'- \`/shamt-audit\` — run guide audit (use with \`/loop\`)'` → `'- \`/shamt-audit\` — run guide audit to completion (3 consecutive clean rounds)'`
- [ ] Line 499: change `'- \`/loop\` with \`/shamt-validate\` self-paces validation rounds'` → `'- Prefix \`/loop\` only if context exhaustion is a risk (very large artifact, 5+ expected rounds)'`

**4b — Source CHEATSHEET Gate Prompts section (Proposal 2):**
- [ ] Open `.shamt/commands/CHEATSHEET.md`
- [ ] At the top of `## Gate Prompts (AskUserQuestion — SHAMT-45)` (just above the table at line 156): add the note "`shamt-validation-loop` is the internal skill invoked by `/shamt-validate` — use `/shamt-validate` to trigger these gates; do not invoke the skill directly."
- [ ] Leave rows 162–163 unchanged — `shamt-validation-loop` is correct in the Skill column; the note above the table provides disambiguation

### Phase 5: Regenerate deployed files and verify

- [ ] Run `.shamt/scripts/regen/regen-claude-shims.sh` from the repo root
- [ ] Confirm all `.claude/commands/*.md` files have the managed header at the bottom
- [ ] Confirm all `.claude/skills/*/SKILL.md` files have the managed header at the bottom and YAML frontmatter starts at line 1
- [ ] Confirm all `.claude/agents/*.md` files have the managed header at the bottom and YAML frontmatter starts at line 1
- [ ] Verify in Claude Code command palette that a meaningful description shows (not the managed comment)
- [ ] Start a fresh session and confirm the system-reminder skill listing shows readable descriptions

### Phase 6: Guide audit

- [ ] Run `/shamt-audit` on the full `.shamt/guides/` tree
- [ ] Achieve 3 consecutive clean rounds before merging

---

## Validation Strategy

- **Design doc validation:** 7-dimension loop. Exit: primary clean round (≤1 LOW-severity issue) + 2 independent Haiku sub-agent confirmations.
- **Implementation validation:** 5-dimension loop after phases 1–5. Key focus: Correctness (header truly at end; frontmatter parses; `/loop` is optional not required in skill and commands), No Regressions (regen idempotency; user-authored file preservation).
- **Manual check:** After regen, open Claude Code, type `/shamt-` and confirm the palette shows meaningful descriptions. Start a new session and confirm skills listing is readable.
- **Success criteria:** (1) No command or skill file in `.claude/` starts with the managed comment. (2) YAML frontmatter in all deployed skill files starts at line 1. (3) CHEATSHEET makes clear `/shamt-validate` and `/shamt-audit` are self-contained loops. (4) No CHEATSHEET row requires the user to use `/loop` for normal operation.

---

## Open Questions

None.

---

## Risks & Mitigation

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| `is_shamt_managed()` change causes regen to overwrite a user-authored file | Low | `grep -q` is more permissive than `head -1` — a user-authored file that never had the managed header is still safe |
| Agents phase also prepends header but is missed | Medium | Phase 1 explicitly includes a check-and-fix step for the agents phase |
| Removing ScheduleWakeup as automatic behavior causes very long validation runs to exhaust context | Low | The advanced note in commands and skill explains when to use `/loop`; the behavior is still available, just not mandatory |
| Guide files referencing the "use /loop with /shamt-validate" pattern become stale | Medium | Phase 6 guide audit (D1 cross-references, D4 workflow integration) surfaces stale references; `validation_loop_composite.md` and `shamt-validation-loop` SKILL.md itself are the most likely locations |

---

## Change History

| Date | Change |
|------|--------|
| 2026-05-03 | Initial draft created |
| 2026-05-03 | Added Problem 3 (loop required vs optional); expanded proposals, files, and implementation plan accordingly |
