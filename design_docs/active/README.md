# Active Design Docs — Shamt + Claude Code + Codex Integration Roadmap

**Created:** 2026-04-27
**Source theorization docs:**
- `../CLAUDE_INTEGRATION_THEORIES.md`
- `../CODEX_INTEGRATION_THEORIES.md`
- `../FUTURE_ARCHITECTURE_OVERVIEW.md`

This directory holds the sequenced design docs that incrementally integrate every proposal from both theorization docs into the Shamt master repo. Each doc is a coherent, independently-validatable unit of work with explicit dependencies on prior docs.

---

## Sequence and dependencies

```
                  SHAMT-39
              Canonical Content
       (skills, agents, commands)
                     │
       ┌─────────────┴─────────────┐
       ▼                           ▼
   SHAMT-40                    (waits for SHAMT-41
   Claude Code                  before Codex parity
   Host Wiring                  picks up the hook bundle)
       │
       ▼
   SHAMT-41
   Hooks Bundle +
   Minimal MCP
       │
       └─────────────┐
                     ▼
                SHAMT-42
                Codex Host Parity
                (AGENTS.md, profiles,
                 requirements.toml)
                     │
                     ▼
                SHAMT-43
                Codex Cloud + OTel + SDK
                     │
                     ▼
                SHAMT-44
                Cross-Cutting Composites
                (validation loop, architect-builder,
                 stale-work, master review,
                 metrics, rollback)
                     │
                     ▼
                SHAMT-45
                Refinements
                (caching, escalation, AskUserQuestion,
                 memory tiers, multi-modal, /fork,
                 pruning audit)
```

---

## What each doc delivers

| # | Title | Effort | Validates |
|---|---|---|---|
| **SHAMT-39** | Canonical Content Foundation | M-L | Foundation; no validation experiment |
| **SHAMT-40** | Claude Code Host Wiring | M | Claude doc Experiment A (skills bundle on real S2.P1.I3) |
| **SHAMT-41** | Hooks Bundle + Minimal MCP (Claude Code) | L | Claude doc Experiment B (PreCompact + SessionStart retiring GUIDE_ANCHOR) |
| **SHAMT-42** | Codex Host Parity | M-L | Codex doc Experiment A (S2.P1.I3 on Codex CLI within ±15% of Claude baseline) |
| **SHAMT-43** | Codex Cloud + OTel + SDK | L | Codex doc Experiment B (cloud builder + OTel + sandbox enforcement) |
| **SHAMT-44** | Cross-Cutting Composites | M | End-to-end S1–S10 epic with all six composites operational |
| **SHAMT-45** | Refinements (Polish Wave) | M | Polish + 1M-context guide pruning audit |

---

## Proposal traceability

Every prioritization-table row from both source docs has a home:

| Source (doc, priority row) | Lands in |
|---|---|
| Claude #1 Skills bundle | SHAMT-39 |
| Claude #2 Sub-agent definitions | SHAMT-39 |
| Claude #3 PreCompact + SessionStart | SHAMT-41 |
| Claude #4 Slash commands | SHAMT-39 (content) + SHAMT-40 (wiring) |
| Claude #5 `/loop` for validation | SHAMT-44 |
| Claude #6 AskUserQuestion | SHAMT-45 |
| Claude #7 High-value hooks | SHAMT-41 |
| Claude #8 Push notifications | SHAMT-41 |
| Claude #9 Prompt-caching-aware model_selection | SHAMT-45 |
| Claude #10 Worktree isolation | SHAMT-44 (rollback workflow) |
| Claude #11 shamt-mcp server | SHAMT-41 (minimal) + SHAMT-44 (full) |
| Claude #12 Routines / cron | SHAMT-44 (stale-work janitor) |
| Claude #13 Plan mode | SHAMT-39 (encoded in skills); SHAMT-45 (refined) |
| Claude #14 TaskCreate-based step tracking | SHAMT-45 (deferred to follow-on if needed) |
| Claude #15 Auto-memory split | SHAMT-45 (memory tier guide) |
| Claude #16 1M-context guide pruning | SHAMT-45 (audit) |
| Claude #17 Multi-modal + Web in Discovery | SHAMT-45 |
| Claude #18 Status line | SHAMT-40 (basic) + SHAMT-45 (enhanced) |
| Claude #19 Metrics & observability loop | SHAMT-44 |
| Claude #20 Rollback / recovery loop | SHAMT-44 |
| Claude #21 Extended-thinking-aware model selection | SHAMT-45 |
| Claude #22 Agent SDK / managed deployment | SHAMT-43 |
| Codex #1 AGENTS.md template | SHAMT-42 |
| Codex #2 Subagent TOMLs | SHAMT-39 (canonical) + SHAMT-42 (Codex form) |
| Codex #3 Codex profiles per stage | SHAMT-42 |
| Codex #4 Skills as host-portable | SHAMT-39 |
| Codex #5 Hooks port | SHAMT-41 (Claude) + SHAMT-42 (Codex) |
| Codex #6 shamt-requirements.toml | SHAMT-42 |
| Codex #7 OTel + dashboards | SHAMT-43 |
| Codex #8 PermissionRequest hook | SHAMT-42 |
| Codex #9 Cloud task setup S6 builder | SHAMT-43 |
| Codex #10 @codex master review | SHAMT-43 |
| Codex #11 shamt-mcp server (host-portable) | SHAMT-41 (minimal) + SHAMT-44 (full) |
| Codex #12 Stage transitions as profile switches | SHAMT-42 |
| Codex #13 Web search per profile | SHAMT-45 |
| Codex #14 @codex stale-work janitor | SHAMT-44 |
| Codex #15 Memory for user prefs | SHAMT-45 |
| Codex #16 Multi-modal in Discovery | SHAMT-45 |
| Codex #17 Reasoning escalation rule | SHAMT-45 |
| Codex #18 IDE plugin status | SHAMT-45 (status line enhancement) |
| Codex #19 Cloud-native validation loop fan-out | SHAMT-44 |
| Codex #20 Container-native rollback | SHAMT-44 |
| Codex #21 shamt-meta-orchestrator | SHAMT-45 (deferred decision) |
| Codex #22 Custom compact_prompt | SHAMT-42 |
| Codex #23 shamt-validate-pr.py SDK | SHAMT-43 |
| Codex #24 codex exec CI workflows | SHAMT-43 |
| Codex #25 /fork hypothesis branching | SHAMT-45 |

---

## How to use this directory

1. **Review the sequence above** to confirm dependencies make sense for your situation.
2. **Validate each doc in turn** using Shamt's design-doc validation loop (7 dimensions, primary clean + 2 sub-agents) before starting implementation.
3. **Implement on `feat/SHAMT-N` branches** per Shamt's master dev workflow.
4. **After implementation**, run implementation validation (5 dimensions) and the full guide audit.
5. **Move to `archive/`** once implemented per Shamt's design-doc lifecycle.

If the sequence needs to change (e.g., a doc is split, merged, or skipped), update this README and the affected design docs' "Depends on" headers.

---

## Notes on sequencing

- **SHAMT-39 → SHAMT-40 → SHAMT-41** is the Claude-Code-only critical path. After SHAMT-41, Shamt-on-Claude-Code is operational with skills, hooks, and minimal MCP.
- **SHAMT-42 → SHAMT-43** is the Codex-only critical path. Both docs depend on SHAMT-39 (content) and SHAMT-41 (hooks bundle to port). After SHAMT-43, Shamt-on-Codex is operational with cloud, OTel, and SDK.
- **SHAMT-44** waits for both host paths to converge — it composes primitives from all of SHAMT-39 through SHAMT-43.
- **SHAMT-45** is post-everything polish and audit; safe to defer indefinitely if priorities shift.

If only one host is in scope (e.g., Claude-Code-only deployment), SHAMT-39 → SHAMT-40 → SHAMT-41 → (skip 42/43) → SHAMT-44 (Claude-Code-only composites; cloud variants in §3 deferred or marked N/A) → SHAMT-45 is a valid trimmed sequence.

If both hosts are in scope (recommended dual-host posture per Codex doc §8), follow the full sequence.
