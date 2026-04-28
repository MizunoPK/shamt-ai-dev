# SHAMT-45: Refinements — Caching, Reasoning Escalation, AskUserQuestion, Memory, Multi-Modal, /fork, Pruning

**Status:** Validated
**Created:** 2026-04-27
**Branch:** `feat/SHAMT-45`
**Validation Log:** [SHAMT45_VALIDATION_LOG.md](./SHAMT45_VALIDATION_LOG.md)
**Depends on:** SHAMT-39 through SHAMT-44 (refines what they ship; doesn't introduce new core primitives)
**Companion docs:** `CLAUDE_INTEGRATION_THEORIES.md` (#9, #14, #15, #16, #17, #21), `CODEX_INTEGRATION_THEORIES.md` (#13, #15, #16, #17, #18, #21, #25), `FUTURE_ARCHITECTURE_OVERVIEW.md`

---

## Problem Statement

SHAMT-39 through SHAMT-44 deliver the architecturally load-bearing primitives and composites. Several mid- and lower-tier proposals from both source docs remain — improvements that polish, optimize, or extend the system but don't change its shape:

- **Prompt caching awareness in `model_selection.md`** (Claude #9, Codex #21 implicit) — the framework's mandatory model delegation patterns predate prompt caching as a first-class cost lever; the guidance should be revised to a (model, cache state, reasoning effort) three-axis recommendation.
- **Reasoning effort escalation rule** (Claude #21, Codex #17) — auto-bump reasoning when `consecutive_clean` is stuck or root-cause analysis is in progress; SHAMT-44 added the stall detector but the escalation isn't yet wired.
- **`AskUserQuestion` at gates** (Claude #6) — turn user-blocking gates from prose into machine-readable artifacts so SHAMT-41's pre-push tripwire and similar hooks have structured inputs.
- **Memory tier separation** (Claude #15, Codex #15) — split user-preference and project-fact memory from epic state; document what belongs in `~/.claude/projects/<path>/memory/` (or Codex's `[memories]`) vs. what stays in `.shamt/epics/<active>/`.
- **Multi-modal in Discovery skill + Web tools** (Claude #17, Codex #16) — ingest design diagrams, allow WebFetch with citation requirement during Discovery research.
- **`/fork`-based hypothesis branching** (Codex #25) — codify the S2.P1.I2 / S5 alternative-architectures patterns for Codex.
- **Status line refinements** (Claude #18, Codex #18) — surface metrics from SHAMT-44 in the status line; show reasoning effort + active profile.
- **1M-context-aware guide pruning** (Claude #16) — audit which Resume Instructions and GUIDE_ANCHOR rituals are still load-bearing on Opus 4.7 / GPT-5.x and trim what's no longer needed.
- **TaskCreate-based step tracking** (Claude #14) — use the harness's structured task tooling for Agent Status sections.
- **`shamt-meta-orchestrator`** (Codex #21) — speculative cross-host orchestrator. SHAMT-45 evaluates whether to ship a stub or defer entirely.

These are the framework's "polish wave" — none structurally change the architecture, but together they tighten the user experience and close the loop on empirical validation.

---

## Goals

1. Revise `model_selection.md` to incorporate cache-state and reasoning-effort axes; replace the binary "Haiku vs. Sonnet vs. Opus" guidance with named profiles (`validate-cheap`, `validate-careful`, `diagnose`, `plan`).
2. Wire reasoning-effort escalation: when `validation-stall-detector.sh` fires, recommend (or auto-apply if user opts in) reasoning effort bump and/or model upgrade.
3. Update gate-prompts in S1 / S2 / S3 / S5 / S9 to use `AskUserQuestion` (Claude Code) with structured options; document the Codex-side equivalent (PR comment with structured response template).
4. Author memory-tier separation guide describing what goes in harness memory vs. `.shamt/` artifacts; update existing `AGENT_STATUS.md` template patterns to match.
5. Update `shamt-discovery` skill to permit and encourage Web tools (with URL citation in DISCOVERY.md) and image ingestion via `Read` for attached diagrams.
6. Update `shamt-spec-protocol` and `shamt-architect-builder` skills with `/fork` patterns for Codex (S2.P1.I2 multi-answer branching, S5 alternative-architectures parallel exploration).
7. Enhance `shamt-statusline.sh` to consume SHAMT-44's metrics output (show recent stall warnings, current reasoning effort, active profile).
8. Run a 1M-context guide-pruning audit: identify Resume Instructions and GUIDE_ANCHOR sections that are no longer load-bearing on current frontier models; propose specific deletions or simplifications.
9. Optionally ship `TaskCreate`-based AGENT_STATUS.md replacement (if the empirical pruning audit shows the artifact is over-engineered).
10. Decide on `shamt-meta-orchestrator`: ship a minimal scaffold (deferred completion) or defer entirely.

---

## Detailed Design

### Proposal 1: Cache-aware model_selection revision

**Description:** Existing `model_selection.md` recommends Haiku/Sonnet/Opus per task type (with Codex-equivalent mapping in `.shamt/agents/README.md`). Revise to a three-axis profile recommendation:

```
Profile: validate-cheap
  Model: cheap-tier (Haiku / Codex default)
  Cache: warm (sub-agent confirmation prompts cache on repeated invocation)
  Reasoning effort: minimal-to-low
  Use for: sub-agent confirmation rounds, mechanical checks

Profile: validate-careful
  Model: reasoning-tier (Opus / Codex frontier)
  Cache: warm (loop iterations cache the validation log)
  Reasoning effort: medium-to-high
  Use for: primary validation rounds 3+, hard-to-resolve issues

Profile: diagnose
  Model: reasoning-tier
  Cache: cold (fresh context for root-cause analysis)
  Reasoning effort: high-to-xhigh
  Use for: builder error diagnosis, validation loop stalls

Profile: plan
  Model: reasoning-tier
  Cache: warm (reference guides + spec)
  Reasoning effort: high
  Use for: S5 mechanical implementation plan authoring
```

The named profiles map directly to:
- Claude Code: sub-agent definitions referencing model + extended thinking flag
- Codex: profile fragments under `.shamt/host/codex/profiles/` with `model_reasoning_effort` set

**Rationale:** Caching is a parallel optimization to model delegation. Skipping it leaves significant cost savings unrealized. The named-profile approach makes the (model, cache, reasoning) tuple legible.

### Proposal 2: Reasoning effort escalation wired to stall detector

**Description:** SHAMT-44 added `validation-stall-detector.sh`. Wire its output to a recommended action:

When the stall detector fires (`consecutive_clean = 0` for ≥3 rounds), it writes `.shamt/epics/<active>/STALL_ALERT.md` with:
- Current model and reasoning effort
- Recommended next step: bump reasoning effort one level OR escalate model tier (if already at maximum reasoning)
- A user-confirm prompt via `AskUserQuestion` (or PR comment on Codex headless)

The `shamt-validation-loop` skill picks up the alert on next round and proposes the escalation; user confirms before applying.

**Rationale:** Stall detection without an action recommendation is just noise. Coupling them with explicit user-confirm preserves human-in-the-loop while making escalation easy.

### Proposal 3: AskUserQuestion at S1 / S2 / S5 / S9 gates (Claude Code)

**Description:** Update the relevant skills to invoke `AskUserQuestion` rather than free-text prose for:

- S1 feature breakdown approval — options: `["approve as-is", "request changes", "reject scope"]`
- S2.P1.I2 checklist resolution — present each question with predefined options where they exist; free-text where genuinely open
- S5 plan approval (Gate 5) — `["approve", "request changes", "reject"]`
- S9 user-testing zero-bug confirmation — `["ZERO bugs found", "bugs found"]` with required reason if "bugs found"
- S3 testing-approach selection — A/B/C/D variant options

Pre-push tripwire (SHAMT-44) and other hooks then have machine-readable artifacts to gate on.

For Codex headless deployments, document the equivalent: post the structured question as a PR comment with the response template; parse the reply.

**Rationale:** Gates today are prose convention. Structured gates are enforceable.

### Proposal 4: Memory tier separation guide

**Description:** Author `.shamt/guides/reference/memory_tiers.md` describing:

- **Harness memory** (Claude Code's `~/.claude/projects/<path>/memory/`, Codex's `[memories]` Chronicle):
  - User preferences: terse responses, preferred review style, etc.
  - Project facts: child project version, primary language, validated approaches
  - External references: where bugs are tracked, where Slack discussions live
  - **Never:** epic state, validation counters, current step pointer
- **Shamt artifacts** (`.shamt/epics/<active>/`):
  - Current SHAMT-N, stage, phase, step
  - Validation log, audit log, builder handoff log
  - Spec, design doc, validation outcomes
  - Anything another agent on another machine needs to resume
- **Decision rule:** "Would another agent on another machine need this to continue work?" → artifact. "Is this user-preference / project-context / approach-history?" → memory.

Update existing `AGENT_STATUS.md` template guidance to push memory-tier content out of artifacts.

**Rationale:** Without explicit guidance, agents and users mix tiers. Memory grows polluted; artifacts grow bloated. Clean separation preserves both.

### Proposal 5: Discovery skill — multi-modal + Web tools

**Description:** Update `shamt-discovery` SKILL.md body:

- "If the user attaches a diagram via `Read` (image / PDF), describe it and integrate observations into DISCOVERY.md's design-context section."
- "Permit `WebFetch` and `WebSearch` for prior-art research. Cite every URL in DISCOVERY.md so the research is reproducible."
- Codex variant: image input via `-i` flag; web search modes (`cached` recommended for reproducibility, `live` only with explicit user request).

Update Discovery profile in Codex (`.shamt/host/codex/profiles/shamt-s1.fragment.toml`) to enable web search in `cached` mode; disable in other stages' profiles.

**Rationale:** Niche but free improvement. Discovery is the right phase for this; building it into the skill body and profile makes it default-on without ceremony.

### Proposal 6: `/fork` patterns for Codex hypothesis branching

**Description:** Update two skills with `/fork`-pattern guidance for Codex:

- `shamt-spec-protocol`: "When a S2.P1.I2 checklist question has multiple plausible answers, on Codex use `/fork` to explore each branch in parallel; on Claude Code, run sequential exploration with explicit comparison at the end."
- `shamt-architect-builder`: "When S5 plan-authoring has multiple plausible architectures, on Codex use `/fork` to draft each plan in a separate thread; merge insights before validation. On Claude Code, sequential drafting with intermediate compare."

The Codex doc §2.6 introduces `/fork`; SHAMT-45 codifies the pattern.

**Rationale:** Both proposals are skill-content additions, not infrastructure. Captures the framework's first-class support for parallel hypothesis exploration on Codex.

### Proposal 7: Status line enhancement

**Description:** Update `shamt-statusline.sh` to render:

```
SHAMT-42 │ S5.P2 round 3 │ effort: high │ stall: warn │ profile: shamt-s5
```

vs. current minimal:

```
SHAMT-42 │ S5.P2 round 3 │ blocker: user approval
```

Reads from `.shamt/epics/<active>/AGENT_STATUS.md`, `.shamt/epics/<active>/STALL_ALERT.md` (if present), and active profile from environment.

**Rationale:** Pure UX. Surfaces SHAMT-44's stall detection and SHAMT-45's reasoning-effort escalation without requiring the user to chase down separate files.

### Proposal 8: 1M-context-aware guide pruning audit

**Description:** Run a structured audit on `.shamt/guides/`:

1. Identify all Resume Instructions sections.
2. Identify all GUIDE_ANCHOR.md references.
3. For each, ask: "On Opus 4.7 / GPT-5.x with PreCompact + SessionStart hooks (SHAMT-41) installed, is this still load-bearing?"
4. Categorize: keep / simplify / delete.
5. Write findings and proposed deletions/simplifications to `.shamt/guides/reference/guide_pruning_audit.md` (the file listed in Files Affected for this phase).

The audit is empirical — runs the validation skill on representative epics with and without each ritual; measures whether deletion causes regression.

**Rationale:** The framework's compaction-fear architecture predates 1M context windows and the PreCompact hook. Some of it is redundant. Pruning reduces guide bloat and agent context spend.

### Proposal 9: Decide on `shamt-meta-orchestrator`

**Description:** The Codex doc §2.16 / §4 / §5 #21 proposes a meta-orchestrator that runs as a Codex agent and dispatches to either local Codex CLI or Codex Cloud as MCP tools. The Codex doc explicitly flags this as speculative and only justified if cross-host orchestration becomes a goal.

SHAMT-45 evaluates: is cross-host orchestration a real goal yet? If yes, ship a minimal scaffold (`.shamt/sdk/shamt-meta-orchestrator-stub.py`). If no, defer entirely with a tracking note in CLAUDE.md.

**Recommendation:** Defer. The dual-host posture per Codex doc §8 (Codex headless / Claude Code interactive) doesn't require an orchestrator — users pick the host per session. Reopen if orchestration friction is observed.

### Recommended approach

Proposals 1–8 ship together as the polish wave. Proposal 9 (`shamt-meta-orchestrator`) is deferred with a tracking entry. Optional follow-on (Proposal 10): `TaskCreate`-based AGENT_STATUS.md replacement if Proposal 8's pruning audit reveals the artifact is over-engineered. Defer that to a follow-on design doc if the audit findings warrant it.

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/guides/reference/model_selection.md` | MODIFY | Three-axis profiles |
| `.shamt/agents/README.md` | MODIFY | Map profiles to per-host model/effort tuples |
| `.shamt/hooks/validation-stall-detector.sh` | MODIFY | Write recommendation to STALL_ALERT.md (escalation) |
| `.shamt/skills/shamt-validation-loop/SKILL.md` | MODIFY | Pick up STALL_ALERT and propose escalation |
| `.shamt/skills/shamt-spec-protocol/SKILL.md` | MODIFY | AskUserQuestion at S1/S2/S5/S9 gates; /fork on S2.P1.I2 |
| `.shamt/skills/shamt-architect-builder/SKILL.md` | MODIFY | /fork on S5 alternative-architectures |
| `.shamt/skills/shamt-discovery/SKILL.md` | MODIFY | Multi-modal + Web tools |
| `.shamt/host/codex/profiles/shamt-s1.fragment.toml` | MODIFY | Enable web_search="cached" |
| `.shamt/host/codex/profiles/shamt-s2.fragment.toml` | MODIFY | Enable web_search if research stage; disable otherwise |
| `.shamt/host/codex/profiles/*.fragment.toml` | MODIFY | Set web_search="disabled" on non-research stages |
| `.shamt/guides/reference/memory_tiers.md` | CREATE | Tier separation rules |
| `.shamt/scripts/initialization/templates/AGENT_STATUS.template.md` | MODIFY | Push memory-tier content out |
| `.shamt/scripts/statusline/shamt-statusline.sh` | MODIFY | Render effort, stall, profile |
| `.shamt/guides/reference/guide_pruning_audit.md` | CREATE | Audit findings + proposed deletions |
| (various — enumerated at Phase 8 start) | DELETE / MODIFY | Placeholder: specific guides identified by the pruning audit and listed before Phase 8 begins. Cannot be enumerated before the audit runs. |
| `.shamt/commands/CHEATSHEET.md` | MODIFY | (a) Update the status line format example to show the enhanced render (`effort`, `stall`, `profile` fields from Proposal 7). (b) Add a "Gate Prompts" section documenting each AskUserQuestion gate (stage, options, and what "bugs found" requires). (c) Add a "Memory Quick Reference" box: one-sentence decision rule ("Would another agent need this to resume? → artifact. Preference/fact/reference? → harness memory.") |
| `CLAUDE.md` | MODIFY | New section "Polish Wave (SHAMT-45)" + tracking entry for deferred shamt-meta-orchestrator |

---

## Implementation Plan

### Phase 1: model_selection revision
- [ ] Author the three-axis profile recommendation in `model_selection.md`.
- [ ] Update `.shamt/agents/README.md` to map profiles to per-host implementations.
- [ ] Validate that existing sub-agent personas still resolve to a profile (no orphans).

### Phase 2: Reasoning effort escalation
- [ ] Update `validation-stall-detector.sh` to write a structured STALL_ALERT.md with current state and recommendation.
- [ ] Update `shamt-validation-loop` skill to read STALL_ALERT.md on round entry and propose escalation via AskUserQuestion (Claude Code) or PR comment template (Codex headless).
- [ ] Test with a deliberately-stuck validation case.

### Phase 3: AskUserQuestion at gates
- [ ] Update each gated skill (spec-protocol, validation-loop, code-review where applicable) to use AskUserQuestion with predefined option sets.
- [ ] Document Codex headless equivalent: PR comment with structured response template; SDK script parses reply.

### Phase 4: Memory tier separation guide
- [ ] Author `.shamt/guides/reference/memory_tiers.md` with the decision rule.
- [ ] Update AGENT_STATUS.md template to remove memory-tier content guidance.
- [ ] Cross-link from existing GUIDE_ANCHOR.md (if not deleted in Phase 8) and resume guides.

### Phase 5: Discovery skill multi-modal + Web tools
- [ ] Update `shamt-discovery` SKILL.md.
- [ ] Update Codex S1 profile fragment to enable web_search="cached".
- [ ] Disable web_search in non-research profiles.

### Phase 6: /fork patterns
- [ ] Update `shamt-spec-protocol` and `shamt-architect-builder` skill bodies with /fork guidance for Codex.
- [ ] Document the Claude Code sequential equivalent.

### Phase 7: Status line enhancement
- [ ] Update `shamt-statusline.sh` to read the additional sources (STALL_ALERT, profile env var).
- [ ] Test rendering with various states (no epic, active epic, stalled epic, S6 builder running).
- [ ] Update `CHEATSHEET.md` with: (a) the new status line format showing `effort`, `stall`, and `profile` fields; (b) the "Gate Prompts" section documenting each AskUserQuestion gate (from Proposal 3) with its options; (c) the "Memory Quick Reference" decision rule from Proposal 4.

### Phase 8: Guide pruning audit
- [ ] Inventory Resume Instructions sections and GUIDE_ANCHOR references.
- [ ] For each, run the validation skill on representative epics with and without the section in context.
- [ ] Categorize per audit (keep / simplify / delete) and write findings to `.shamt/guides/reference/guide_pruning_audit.md`.
- [ ] Apply deletions / simplifications. This is the most invasive phase; review carefully.

### Phase 9: shamt-meta-orchestrator decision
- [ ] Document the deferral in CLAUDE.md with a tracking note.
- [ ] If the user wants to proceed with a stub anyway, add `.shamt/sdk/shamt-meta-orchestrator-stub.py` with a "TODO: implement when cross-host orchestration becomes a real goal" header.

### Phase 10: Validation
- [ ] Implementation validation loop (5 dimensions).
- [ ] Full guide audit (3 clean rounds).
- [ ] Run a real epic exercising the new behaviors:
  - Multi-modal Discovery on a feature with an attached diagram
  - /fork hypothesis exploration on a S2.P1.I2 question
  - Stall detector triggers escalation; user confirms; reasoning effort bumps
  - Status line shows enhanced render
  - Memory-tier audit: verify nothing in the AGENT_STATUS.md template is memory-tier content

---

## Validation Strategy

- **Primary:** Design doc validation loop on this doc.
- **Implementation:** All files in "Files Affected" match spec.
- **Empirical:** End-to-end epic exercising the new behaviors per Phase 10.
- **Pruning audit empirical:** Deletions don't cause measurable regression in validation outcomes (rounds-to-exit, severity profiles).
- **Status line render test:** Manually trigger each state combination; confirm render is correct.
- **Success criteria:**
  1. `model_selection.md` reads as a three-axis recommendation with named profiles.
  2. Stall detector writes structured alerts; validation loop proposes escalation.
  3. AskUserQuestion fires at all named gates with structured options.
  4. Memory-tier guide authored and AGENT_STATUS.md template updated.
  5. Discovery skill ingests images and cites web sources.
  6. /fork pattern documented in two skills.
  7. Status line surfaces effort + stall + profile.
  8. Pruning audit completes with categorized findings; agreed deletions applied.

---

## Open Questions

1. **Pruning audit thoroughness vs. risk:** Aggressive pruning could hurt edge-case recovery. **Recommendation:** Keep anything where the audit shows even minor regression; bias toward conservative deletions.
2. **AskUserQuestion on Codex CLI (interactive):** Codex's CLI may have a structured-question equivalent. **Recommendation:** Verify at implementation time; if present, use it natively; if not, fall back to prose with structured response template.
3. **`shamt-meta-orchestrator` revisit cadence:** When should the deferral be reconsidered? **Recommendation:** When 3+ child projects use both Claude Code and Codex actively and ask for cross-host orchestration; track in CLAUDE.md.
4. **Memory-tier guide enforcement:** Should there be a hook that checks AGENT_STATUS.md doesn't contain memory-tier content? **Recommendation:** Optional; add to SHAMT-44's hook bundle if violations are observed in practice.
5. **TaskCreate-based AGENT_STATUS.md:** If Phase 8's audit shows AGENT_STATUS.md is over-engineered, should TaskCreate replace it? **Recommendation:** Defer to a separate follow-on design doc; SHAMT-45 is already substantial.

---

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Cache-aware profile recommendations are wrong for some workloads | Profile names are advisory; users override per-task; document the advisory nature |
| Stall escalation auto-applies too aggressively | User-confirm before applying; opt-in flag for full auto |
| AskUserQuestion availability differs across hosts | Document fallback; on hosts lacking the primitive, use prose with structured template |
| Pruning audit deletes a guide that was load-bearing on edge cases | Audit categorizes "keep" generously; deletions are reviewed by the user before applying |
| Status line script's expanded read paths slow down session start | Cache the reads with a short TTL; profile if measured slow |
| /fork pattern misuse on Codex (forks proliferate) | Document explicit `re-merge` step in the pattern; user is responsible for closing branches |

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-27 | Initial draft created |
| 2026-04-27 | Validated — added clarifying note to "(various)" placeholder row in Files Affected |
| 2026-04-27 | Fixed Proposal 8 contradiction: "propose within this design doc" → "write to guide_pruning_audit.md" (aligning with Files Affected); added S3 to Goal 3 to match Proposal 3 |
| 2026-04-27 | Added CHEATSHEET.md MODIFY entry to Files Affected; Phase 7 step to update status line format, gate prompts, and memory quick reference in the cheat sheet |
