# Claude Capability Integration Theories for Shamt

**Status:** Exploratory / theorization (not a SHAMT-N design doc)
**Date:** 2026-04-27
**Purpose:** Map Shamt's existing workflow seams onto Claude's harness capabilities (sub-agents, skills, hooks, routines, MCP servers, plan mode, worktrees, push notifications, `/loop`, etc.) and theorize integrations that would reduce friction, improve reliability, or unlock new capability. This is a brainstorm, not a commitment to build.

**How to read this doc:**
- **§1** — Problem framing: what Shamt does today and where it leaves work on the table.
- **§2** — Capability walkthrough (§2.1–§2.17): one section per Claude capability, each naming concrete Shamt seams.
- **§3** — Cross-cutting workflows (§3.1–§3.6): composites where multiple capabilities combine for a single Shamt outcome.
- **§4** — Speculative / longer-horizon ideas.
- **§5** — Prioritization table with effort and value scoring. *Skim here first if you want the punchline.*
- **§6** — Risks and anti-patterns to avoid.
- **§7** — Two candidate first experiments.

---

## 1. Framing: What Shamt Does Today vs. Where It Leaves Work on the Table

Shamt is, structurally, a **state machine over a long-running multi-agent workflow**:
- 11 stages (S1–S11), each with phases, gates, and approval points
- Validation loops as the universal quality gate (primary clean round + sub-agent confirmation)
- Mandatory model delegation (Haiku/Sonnet/Opus) at named execution points
- Architect–Builder pattern as the mandatory implementation execution shape
- Heavy reliance on **markdown artifacts as state** (Agent Status, EPIC_TRACKER, validation logs, GUIDE_ANCHOR)

The framework already treats sub-agents as a first-class primitive. What it does **not** yet exploit:
1. **Event-driven automation** — every status update, gate transition, and validation-round outcome is currently manual prose the agent writes. Hooks and the harness's notification primitives could carry this.
2. **Persistent ambient state** — Agent Status / GUIDE_ANCHOR / Resume Instructions exist precisely because nothing in the harness deterministically survives compaction. The PreCompact + SessionStart hook pair, plus a custom status line and auto-memory, could replace most of this fragile markdown anchoring with harness behavior.
3. **Scheduled / asynchronous work** — sync cadence ("import when guides feel stale"), lessons-learned capture, metrics population, and cleanup tasks are all "remember to do this eventually." Routines/cron own that domain.
4. **Discoverability of patterns** — `model_selection.md`, `architect_builder_pattern.md`, `validation_loop_master_protocol.md` are reference docs the agent must remember to read. Skills auto-load on context match.
5. **Tool surface** — Shamt's mechanical operations (export script, import script, audit pre-checks, metric aggregation, EPIC_TRACKER mutations) are bash. An MCP server could expose them as typed tools with schema and validation.

The rest of this doc walks the capabilities one by one and points at the seams.

---

## 2. Capability-by-Capability Mapping

### 2.1 Skills (auto-loaded behavior packs)

**Why this fits Shamt:** Shamt's reference guides (`validation_loop_master_protocol.md`, `architect_builder_pattern.md`, `model_selection.md`, severity classification, smoke testing pattern, etc.) are *exactly* what skills are designed to package — a tight bundle of "read this before doing X, here's the protocol, here are the templates." Today the agent has to know to grep for them. Skills make the trigger automatic.

**Concrete skills to ship:**

| Skill | Trigger | What it bundles |
|---|---|---|
| `shamt-validation-loop` | User says "run validation loop" / "validate this spec" / starting S2.P1.I3, S5.P2, S7.P2, S9.P2, S10.P1 | Primary-clean exit criteria, fresh-eyes round patterns, severity classification, fix-and-continue protocol, sub-agent confirmation prompt template |
| `shamt-architect-builder` | Entering S6, or master-dev work where >10 file ops planned | Handoff package format, builder prompt template, error-recovery protocol, monitoring loop |
| `shamt-spec-protocol` | Entering S2, or any "create a spec" / "refine this spec" intent | 10-dimension spec validation, checklist resolution rules (ONE at a time), acceptance-criteria approval gate |
| `shamt-code-review` | Branches reviewed for S7.P3, S9.P4, formal external reviews | The 12/13 dimensions, ELI5 + What/Why/How template, review_v{N}.md versioning |
| `shamt-guide-audit` | Before export, after master guide changes, after PR merge | Audit dimensions, 3-clean-rounds exit criterion, model delegation per dimension |
| `shamt-discovery` | S1.P3 entry | Iterative Q&A loop, "ONE question at a time" rule, question brainstorm categories |
| `shamt-import` / `shamt-export` | "import shamt updates" / "export changes to master" | Diff review pattern, RULES_FILE supplement check, validation loop integration |
| `shamt-lite-story` | Presence of `SHAMT_LITE.md` in repo + new ticket / story file under `stories/` | Six-phase narrative, 1-sub-agent confirmation variant, lite templates |

**Why this beats reference-doc-grepping:** Skills surface *only when triggered*, so context isn't bloated reading them upfront. The trigger phrases formalize what is currently informal ("the agent should read X before Y"). And the skill description itself becomes the precondition — if the trigger doesn't fire, the work probably isn't a real Shamt context.

**Risk:** Skill triggers must be tight or they fire constantly. Anchor on imperative phrasings and on artifact paths (`.shamt/epics/`, `validation_log.md`, `spec.md`) rather than generic words like "validate" or "review."

---

### 2.2 Specialized Sub-Agents (Task tool with frontmatter-defined personas)

**Why this fits Shamt:** Today, sub-agents are spawned ad hoc with the `model` parameter, with the prompt re-stating "you are a Haiku verifier, do X." A persisted agent definition (`.claude/agents/<name>.md`) bakes the role, model, and tool allowlist into a name. Cleaner prompts, consistent behavior, easier auditing.

**Agent definitions to register:**

- `shamt-validator` (Haiku) — Independent confirmation of validation rounds. Read-only tools. Prompt template embeds the dimension list and exit criteria.
- `shamt-builder` (Haiku) — Mechanical executor for architect-builder S6. Allowed tools: Read/Write/Edit/Bash. Prompt enforces: no design decisions, report errors immediately.
- `shamt-discovery-researcher` (Sonnet) — Iterative Q&A driver for S1.P3 / S2.P1.I1. Allowed tools: Read, Grep, WebFetch. Bounded by question brainstorm categories.
- `shamt-guide-auditor` (mixed model per dimension) — Runs the audit against `.shamt/guides/` with the 3-clean-rounds protocol baked in.
- `shamt-spec-aligner` (Sonnet) — S2.P2 / S8.P1 cross-feature pairwise alignment. Read-only.
- `shamt-architect` (Opus) — S5.P1 mechanical plan author. The model selection guide already says Opus here; the agent definition formalizes it.
- `shamt-code-reviewer` (Sonnet/Opus split) — Already kind of exists in the framework; codify its tool allowlist (no checkout, read-only git).

**Tooling note:** The Task tool's `subagent_type` field is the integration point. Hooks could enforce that S6 *must* use `shamt-builder` (PreToolUse hook on Task that rejects an S6 Task call with a different agent type or model).

---

### 2.3 Hooks (event-driven harness automation)

**Why this fits Shamt:** Shamt's guides are full of *imperative rules* ("update Agent Status after every step", "run guide audit before export", "never commit with --no-verify", "validate each spec change"). Each one of those is a hook waiting to be born. Hooks turn "the agent should remember to do X" into "the harness ensures X."

**High-value hooks:**

| Hook | Event | Action |
|---|---|---|
| Pre-export audit gate | UserPromptSubmit matching `/export` or PreToolUse on the export script | Refuse if last guide audit timestamp > N hours old or audit log shows unfixed issues. *Requires audit results to be persisted to a known artifact (e.g., `.shamt/audit/last_run.json`) — today they live only in the agent's conversation. Adopting this hook means committing to that artifact format.* |
| Validation log auto-stamp | PostToolUse on Edit when path matches `*VALIDATION_LOG.md` | Append round timestamp + model used; counts cleanly toward the round counter without the agent having to write it |
| Architect-builder enforcement | PreToolUse on Task during S6 phase | Block if `subagent_type != "shamt-builder"` or `model != "haiku"` |
| Commit-message format | PreToolUse on Bash matching `git commit` | Enforce `feat/SHAMT-N:` or `fix/SHAMT-N:` prefix; reject AI attribution lines |
| `--no-verify` blocker | PreToolUse on Bash | Reject any `git commit --no-verify` / `--no-gpg-sign` (CLAUDE.md already forbids; harness should enforce) |
| EPIC_TRACKER mutation log | PostToolUse on Edit/Write of EPIC_TRACKER.md | Append change to a sidecar audit log; useful for resumption-after-compaction debugging |
| Stage-transition snapshot | UserPromptSubmit matching "advance to S{N}" | Auto-write a Resume Context block (current stage/phase/step/blockers) to a known location for next session |
| Sub-agent confirmation receipt | SubagentStop | If the validating sub-agent reports issues, refuse to advance `consecutive_clean` past the current round. *"Mark complete" today is convention (the agent writes "EXIT" or similar in the validation log); the hook either codifies that artifact convention or assumes a structured trailer in the log. Either way, requires deciding what the machine-readable signal is.* |
| User-testing zero-bug gate | PreToolUse on Bash matching `git push` during S9 | Refuse if user-testing artifact doesn't show "ZERO bugs found" |
| **Resume-context snapshot** | **PreCompact** | **Before the harness compacts the conversation, dump current epic / stage / phase / step / blockers / open validation-loop counters to a known artifact. This is exactly the problem Shamt's "session compaction protocol" was hand-rolled to solve — PreCompact is the harness-native version.** |
| **Auto-load epic context** | **SessionStart** | **On session boot, detect active epic (most recent `.shamt/epics/<active>/` mtime, or a small pointer file), read its Agent Status + GUIDE_ANCHOR, and pre-populate the agent's context. Replaces the "agent reads GUIDE_ANCHOR.md first" ritual with harness behavior.** |

**The PreCompact / SessionStart pair is structurally the most important Shamt-native hook.** Today, every guide has Resume Instructions, every epic has GUIDE_ANCHOR.md, and Agent Status is the only thing standing between a compacted conversation and total context loss. The PreCompact hook writes the resume snapshot deterministically; SessionStart reads it back. The agent stops carrying the bookkeeping. Together they obviate a meaningful fraction of the prose currently in the guides.

**Risk / cost:** Hooks are powerful but brittle. Each one is config drift waiting to happen. Ship them as opt-in via `.claude/settings.local.json` snippets the user can paste, not as global mandates. And test the *deny* path. Concrete failure modes to simulate before shipping a hook: (a) the audit log file the pre-export hook reads is missing or empty (does it block forever?), (b) the user is doing legitimate work outside an active epic and the architect-builder enforcement hook fires anyway (false-positive denial of a legitimate Task spawn), (c) the commit-message hook rejects a merge commit that doesn't match `feat/SHAMT-N:` because the commit was generated by `git merge` not by the agent. A hook that refuses a legitimate action is worse than no hook — every proposed hook needs a smoke test for at least one realistic false-positive scenario.

---

### 2.4 Routines / Scheduled Agents (cron-driven, calendar time)

**Why this fits Shamt:** Shamt has several "do this eventually" obligations that nobody owns: stale-guide imports, unmerged child PRs sitting in `incoming/`, lessons-learned not yet propagated, metrics not aggregated, design docs in `active/` that have been stalled for weeks. Routines turn ambient TODOs into scheduled work.

*(Routines run on calendar time. `/loop` self-pacing — covered in §2.11 — is the orthogonal "iterate until done" primitive. They are different shapes; this section is about the scheduled-cadence variant only.)*

**Recurring routines (cron):**

- **Weekly stale-guide checker (master)** — Scan child projects' `last_sync.conf` (if accessible) or just open an issue on master noting "no imports in N weeks, consider auditing for divergence."
- **Weekly `incoming/` triage (master)** — List proposals in `design_docs/incoming/`, summarize ages, flag any > 30 days old. Output to a digest file or post to a notifications channel.
- **Monthly architecture/standards currency check (child)** — D23 audit dimension currently fires inside guide audit. As a separate monthly routine, it would catch drift earlier.
- **Bi-weekly "active" design-doc status sweep (master)** — For each `design_docs/active/SHAMT*.md`, check its branch state, last commit, validation log progress. Flag stalls.

**One-shot scheduled (post-event triggers):**

- **Post-S10 merge → +1 week** — Schedule an agent to re-read the epic, evaluate whether the lessons-learned in S11 actually got propagated, and verify metrics were populated. Feels much more honest than asking the agent to do it inline at S11.P3 when it's exhausted.
- **Post-feature-flag ship → +2 weeks** — Generic Claude pattern, but Shamt's S10 overview document often mentions flag/gate state. A scheduled cleanup PR routine fits cleanly.
- **Post-export PR → +3 days** — Check if master merged the PR; if yes, kick off an import on the originating child. Closes the upstream/downstream loop without the user having to remember.

*(`/loop` coverage moved to §2.11 to keep cron and self-pacing cleanly separated.)*

---

### 2.5 MCP Servers (typed tool surface for Shamt's mechanical ops)

**Why this fits Shamt:** A handful of operations are mechanical, frequently used, and benefit from typed schemas:
- Reserve next SHAMT-N number (currently a manual read–increment–commit on `NEXT_NUMBER.txt` — single-user safe today, but a contention point if more than one agent ever wants to start an epic concurrently)
- Open a feature branch with the canonical naming
- Stamp a validation log round (round N, model used, dimensions checked, issues found, severities)
- Append to EPIC_METRICS.md / PROCESS_METRICS.md
- Run the export pipeline (verify CHANGES.md exists, scan for epic-tag contamination, run audit, push, open PR)
- Run the import pipeline with diff-review hooks

**Theorized `shamt-mcp` server tools:**

```
shamt.next_number()                       → reserves and returns next SHAMT-N atomically
shamt.start_design_doc(n, title)          → creates active/SHAMT{N}_DESIGN.md from template
shamt.validation_round(log_path, ...)     → appends a round entry, returns consecutive_clean count
shamt.audit_run(scope)                    → runs guide audit, returns structured result (issues by severity)
shamt.export(epic, dry_run)               → packages and pushes child changes to master
shamt.import(dry_run)                     → fetches and surfaces master diffs for review
shamt.epic_status(epic_id)                → structured snapshot of stage/phase/blockers
shamt.metrics.append(epic_id, metric)     → appends to PROCESS_METRICS.md cleanly
```

**Why this is better than bash scripts:**
- Typed inputs/outputs reduce parsing errors when the agent reads results.
- The harness can permission them once (allow `mcp__shamt__*`) instead of permissioning many bash variations.
- Hooks can target `mcp__shamt__*` events specifically (e.g., post-export → schedule import-back routine).
- Multi-machine: if served over HTTP, the same MCP could in principle be reachable from non-CLI Claude surfaces (desktop, web), though that depends on the surface actually allowing remote MCP and isn't a near-term goal.

**Risk:** Building an MCP server is real engineering. Worth doing only if the bash scripts are actually painful in practice. The `shamt.next_number()` and `shamt.validation_round()` ones probably justify themselves; the others might not.

---

### 2.6 Auto-Memory (persistent context across sessions)

**Why this fits Shamt:** GUIDE_ANCHOR.md and Agent Status sections exist as a *workaround* for the fact that prior-session context is lost. Some of that state is genuinely epic-local (current step in a specific epic) — that should stay in the artifact. But other state is *cross-session and cross-epic*:

- **User preferences** — "this user prefers terse responses," "always use Sonnet for code review unless cost is a concern," "we don't use the lite workflow on this repo"
- **Project facts** — "child project X is on Shamt version Y," "this child uses Cursor not Claude Code as the rules-file target"
- **Validated approaches** — "for this codebase, the integration-test pattern uses real DB not mocks (see incident from 2026-Q1)"
- **External references** — "epic tracking lives in Linear project SHAMT-DEV"

These belong in `.claude/projects/.../memory/` not in `.shamt/` artifacts. Splitting them out cleans up Agent Status sections (which today carry too much load).

**What stays in Shamt artifacts (don't memory-ify):** current-step pointers, validation-loop counters, EPIC_TRACKER state, anything that another agent on another machine needs. Memory is per-user-per-machine; Shamt artifacts are the shared ground truth.

---

### 2.7 Plan Mode (read-only exploration before action)

**Why this fits Shamt:** S5 (implementation planning) and S10.P1 (overview document narrative) are *explicitly* "no execution yet, design the plan first" phases. The harness's plan mode is exactly this primitive. Entering plan mode for the duration of S5.P1 would prevent accidental writes during what's supposed to be a read-and-think phase.

Less obvious: **S1.P3 Discovery** is also plan-mode-shaped — read-heavy, no writes until DISCOVERY.md is being authored. Could enter plan mode, exit when the artifact is being written.

**Concrete proposal:** Skill `shamt-implementation-plan` (or `shamt-architect`) auto-enters plan mode on activation and reminds the agent that exit happens only at "Gate 5 — user approves plan."

---

### 2.8 Worktrees (isolated branches without juggling)

**Why this fits Shamt:** Master CLAUDE.md mentions parallel epic work ("S1–S5 of this epic may run in parallel"); `parallel_work/` is a whole directory of protocols. The fundamental friction in parallel work is that multiple agents on one repo step on each other (lockfiles, branch switches, conflicting writes to EPIC_TRACKER).

**Worktree per epic** removes most of this:
- `feat/SHAMT-N` lives in `.worktrees/SHAMT-N/`
- Each agent operates on its own worktree, no checkout fights
- Audit and master-dev work happen on `main` worktree
- S10.P3 push happens from the worktree, then the worktree is cleaned up at S11

The Agent tool's `isolation: "worktree"` parameter is the immediate hook — sub-agents that do potentially-conflicting work (e.g., S2 secondary agents on different features) get isolated worktrees automatically.

**Risk:** EPIC_TRACKER.md is shared mutable state across worktrees. Need either a) move it out of git (status file, not tracked), b) treat it as conflict-prone and merge frequently, or c) split per-epic tracker files. Option (c) feels cleanest and probably warrants a small SHAMT-N proposal — but it has a real cost: today EPIC_TRACKER.md gives at-a-glance cross-epic visibility ("what's active, what's done, who's blocked"). Splitting per-epic loses that aggregation, so option (c) probably requires either a thin index file (`EPIC_INDEX.md` listing all per-epic trackers) or a small `shamt status` MCP/CLI query that joins them. The aggregation problem is solvable but worth designing before committing to the split.

---

### 2.9 Push Notifications

**Why this fits Shamt:** Shamt has more user-blocking gates than almost any framework I've seen — feature breakdown approval, checklist Q&A (one at a time!), acceptance criteria approval, S5 plan approval, S7 smoke results, S9 user testing zero-bugs, S10 PR ready. Most of these the user has to *poll for*. A `PushNotification` on gate-reached transforms the workflow from "user babysits the agent" to "user gets pinged when needed."

**Notification triggers:**

- Gate reached (S1 breakdown, S5 plan, S9 user testing, S10 PR opened)
- Builder error during S6 (architect needs to diagnose)
- Validation loop stuck (e.g., 5 rounds without exit — user judgment needed)
- Stale design doc routine flags something
- Child PR review queued on master

Pair with hooks: a hook on Stop that, if the agent's last action was "waiting for user approval," fires a push notification and exits cleanly.

---

### 2.10 Status Line / Output Styles

**Why this fits Shamt:** Custom status line could surface the *one piece of state the user needs to glance at*: current epic + stage/phase + validation-loop round + blocker.

Concrete idea: a status-line script that reads `.shamt/epics/<active>/AGENT_STATUS.md` (or a small `STATUS` file) and renders:

```
SHAMT-42 │ S5.P2 round 3 │ 2 LOW open │ blocked: user approval
```

Or during builder execution:

```
SHAMT-42 │ S6 builder │ step 7/14 │ 12s elapsed
```

This is purely cosmetic but it dramatically reduces the "where am I in this 11-stage process" cognitive load that the framework otherwise pushes onto markdown anchors.

**Output styles** are a smaller win — could define a "shamt-validation" output style that renders validation log entries consistently, but markdown is already fine here.

---

### 2.11 `/loop` (self-pacing iteration)

`/loop` is the orthogonal cousin of routines (§2.4): not "tomorrow at 9am" but "keep iterating on this until done." Natural Shamt fits:

- **Validation loops** — `/loop` self-paces rounds, checks the validation log to determine state, exits when primary-clean + sub-agent confirms are written.
- **Discovery Q&A** — loops question → answer → spec update → checklist re-check until empty.
- **Builder monitoring during S6** — polls the builder's task output, hands errors back to the architect, exits on completion.
- **Long-running guide audit** — loops dimension by dimension.

`/loop` is a quiet superpower because it externalizes loop state to file artifacts (which Shamt already has) and lets the agent "wake up clean" each iteration without dozens of rounds of conversation history. Practically, most of Shamt's "do this until clean" prose maps to `/loop` more cleanly than to ad-hoc multi-turn agent reasoning, because the exit criterion is *file-observable* (validation log says clean + sub-agent confirms).

---

### 2.12 Background Tasks (Bash `run_in_background`, Agent `run_in_background`)

**Why this fits Shamt:** S2 supports parallel feature work; S6 architect spawning the builder is naturally async. Today, the architect is mostly blocking on the builder. `Agent run_in_background` lets the architect kick off the builder, do *other* monitoring work (e.g., update EPIC_METRICS.md, prep S7 smoke plan), and react when notified.

For S2 with multiple features, **multiple background sub-agents** with distinct worktrees plus a primary coordinator agent maps cleanly. The protocols in `.shamt/guides/parallel_work/` were built before background-agent primitives existed; revisiting them through that lens probably simplifies several of them.

---

### 2.13 Slash Commands (user-invocable Shamt operations)

**Why this fits Shamt:** Skills (§2.1) are *triggered* by context match; slash commands are *invoked* by the user. Shamt has many user-initiated verbs that are clean slash-command targets — operations the user explicitly chooses to start, often from outside any active conversation context.

**Concrete commands to register** (under `.claude/commands/` per-project, or as user-level commands):

| Command | Purpose | Where it bridges to existing Shamt |
|---|---|---|
| `/shamt-start-epic <title>` | Reserve SHAMT-N, create branch, scaffold epic folder, invoke S1.P1 skill | Today: manual sequence at S1 entry |
| `/shamt-validate <artifact>` | Activate `shamt-validation-loop` skill on a specific artifact (spec, plan, design doc) | Today: prose instruction in stage guides |
| `/shamt-audit [scope]` | Run guide audit (full tree by default, scoped if argued) | Today: master-dev mandatory pre-export step |
| `/shamt-export` / `/shamt-import` | Trigger the sync workflows | Today: bash scripts the agent has to remember to invoke |
| `/shamt-status` | Print current epic / stage / phase / blocker (calls out to `shamt-mcp.epic_status` if MCP exists, else reads Agent Status) | Today: agent re-reads markdown each session |
| `/shamt-resume` | Re-hydrate context after compaction / new session — pair with PreCompact + SessionStart hooks | Today: GUIDE_ANCHOR.md ritual |
| `/shamt-promote <proposal>` | Master-only: promote `incoming/` proposal to `active/SHAMT{N}` design doc | Today: manual, in CLAUDE.md |
| `/shamt-builder <plan>` | Spawn `shamt-builder` Haiku on a validated plan; user-invocable for ad-hoc plan execution outside S6 | Today: only inside S6 architect-builder pattern |

**Slash commands vs. skills — when to use which:** Skills auto-fire when context matches (good for "you're entering S5, here's the protocol"). Commands explicitly start work (good for "I want to begin a new epic"). Many proposals will want both — a `/shamt-validate` command that *invokes* the `shamt-validation-loop` skill is cleaner than relying on the trigger to fire from natural language alone.

**Risk:** Slash commands are easy to add and easy to forget. Documenting them in CLAUDE.md (or auto-discovering from `.claude/commands/`) is necessary, otherwise they become tribal knowledge.

---

### 2.14 User-Interaction Primitives (`AskUserQuestion`, `TaskCreate`)

**Why this fits Shamt:** The framework is unusually disciplined about user interaction — "ONE question at a time," explicit gates, approval rituals. Two harness tools map directly onto these patterns.

**`AskUserQuestion`** — Purpose-built for structured user prompts with options. Where Shamt uses it well:
- **S2.P1.I2 checklist resolution** — The guide explicitly mandates ONE question at a time. `AskUserQuestion` enforces the structure and captures the answer in a parseable shape (vs. free-text agent prose that has to be re-parsed for the spec update).
- **S1 feature breakdown approval** — Present options ("approve as-is" / "request changes" / "reject scope"), capture answer, branch.
- **S5 plan approval (Gate 5)** — Same pattern.
- **S9 user-testing zero-bug confirmation** — Force a structured "ZERO bugs" / "bugs found" answer rather than parsing free-text.
- **S3 testing-approach selection** — A/B/C/D variant selection is literally an options list.

The semantic value: gates today are convention; with `AskUserQuestion` they become *machine-readable artifacts*. Combined with hooks (§2.3), this enables: PreToolUse on `git push` → check that the most recent S9 `AskUserQuestion` recorded "ZERO bugs" → otherwise refuse.

**`TaskCreate` / `TaskList` / `TaskUpdate`** — Structured task tracking. Shamt's Agent Status sections are *manual* task lists. Using the harness primitive instead:
- **Per-stage task lists** — S1 has 9+ status updates, S2 has per-iteration steps, S6 has builder-handoff steps. Each could be a TaskList with auto-update on completion.
- **Validation loop rounds** — Each round becomes a task; sub-agent confirmations become subtasks. Counter is the harness's job, not the agent's.
- **Cross-feature S2 coordination** — Each feature's progress as a parallel task list under one epic-level TaskList. Replaces the more elaborate STATUS.md / lockfile patterns in `parallel_work/`.

**Caveat:** Task tools are session-scoped in their default behavior. For the cross-session case (resume after compaction, hand-off between agents), tasks need to be persisted to artifacts — which loops back to PreCompact / SessionStart hooks. The structured-task primitive is the *interface*; the artifact is the *substrate*.

---

### 2.15 Context Window Economics (1M context, prompt caching, extended thinking)

**Why this fits Shamt:** A meaningful slice of Shamt's design exists *because of context-window scarcity*: GUIDE_ANCHOR.md, Resume Instructions, Agent Status sections, the strict separation of artifacts (so an agent can re-read only what it needs), the model-delegation patterns (so cheap models do the bulk of file ops). Three model-level capabilities reframe these choices.

**1M context window (Opus 4.7):** With ~1M tokens of context, the *entire* `.shamt/guides/` tree, an active epic, and several reference docs can coexist in one conversation. The compaction-fear architecture is partially over-engineered for this regime. Implications:
- Some Resume Instructions / GUIDE_ANCHOR rituals can be loosened — at session start, just read the relevant guides into context and stop worrying about it.
- Multi-feature S2 work might be tractable in one conversation rather than requiring parallel sub-agent coordination.
- Validation loops can hold all dimensions + the artifact + reference protocols simultaneously, reducing re-reads.

This isn't an argument to *remove* the compaction protocols — agents on Sonnet/Haiku still hit smaller windows, and even Opus can be exhausted by very long epics. But it suggests guides should distinguish between "context discipline always required" and "context discipline that was needed when models had 200K windows and is now optional."

**Prompt caching:** Shamt re-reads the same guides constantly across sessions and across sub-agents. With caching, the second-and-subsequent reads are dramatically cheaper. Practical implications:
- Stable-content reads (reference guides, severity classification, validation protocols) should be loaded *first* in any prompt so they cache cleanly.
- Sub-agent prompt templates that include guide excerpts benefit hugely from caching since the same template fires N times in a validation round.
- Caching is a *parallel* optimization to model delegation, not a substitute. Haiku-with-cache can be cheaper than Sonnet-with-cache; Opus-with-cache on a re-read can be cheaper than Sonnet-cold.

This is a model-selection axis the framework currently ignores. A cache-aware model_selection.md would distinguish "cold call to Sonnet" from "warm call to Sonnet" and might revise some of the mandatory delegations.

**Extended / interleaved thinking:** For the hardest validation rounds (Dimension 2 Correctness on a complex spec, multi-dimensional QC, root-cause analysis on a builder error), more thinking budget meaningfully changes outcomes. The framework currently selects model (Haiku/Sonnet/Opus) but not thinking budget. Concrete proposal: extend `model_selection.md` to a third axis — *(model, cache state, thinking budget)* — with named profiles like:

- `validate-cheap` = (Haiku, warm, no extended thinking) for sub-agent confirmation rounds.
- `validate-careful` = (Opus, warm, extended thinking on) for primary validation rounds 3+ where issues are persisting.
- `diagnose` = (Opus, cold, extended thinking on) for S6 builder error root-cause analysis.
- `plan` = (Opus or Sonnet, warm-on-spec, extended thinking on) for S5 mechanical plan authoring.

Triggering rule: turn extended thinking on when (a) the round is a primary validation pass on a high-severity dimension, (b) `consecutive_clean` has been stuck at 0 for ≥2 rounds (something is genuinely hard), or (c) the agent is doing root-cause analysis on a builder error rather than mechanical execution. Off otherwise. This is the smallest rule that captures most of the value without burning thinking budget on trivial passes.

---

### 2.16 Multi-Modal & Web Tools (under-used in Discovery and Spec)

Two smaller capabilities worth flagging:

**Multi-modal (image reading):** Read tool already accepts PNG/JPG/PDF. Shamt specs and design docs occasionally reference diagrams (architecture sketches, UI mocks, sequence diagrams). The framework does not currently say anything about consuming them. A `shamt-discovery` or `shamt-spec-protocol` skill could include: "If the user attaches a diagram, read it and incorporate observations into DISCOVERY.md / spec.md design section." Niche but real.

**WebFetch / WebSearch in Discovery:** S1.P3 Discovery and S2.P1.I1 research phases are exactly when external documentation is most valuable (third-party API docs, RFCs, prior-art research). The Discovery skill should permit and encourage these tools, with a guard rail (cite the URL in DISCOVERY.md) so the research is reproducible.

Both are LOW-priority but free improvements once the relevant skills are written.

---

### 2.17 Claude Agent SDK / Managed Agents (deployment surface)

**Why this fits Shamt:** Today Shamt is shaped around Claude Code as the host: interactive CLI, file-based artifacts on a developer's machine, the user as the synchronous approver at every gate. The Agent SDK and managed-agent deployment open a different shape — Shamt as a *service* that runs without a human in the loop, triggered by external events.

**Concrete deployment patterns:**

- **CI-triggered S7 QC agent.** A managed agent listening on PR events runs the S7 validation loop (smoke, QC, code review) and posts results as PR comments. The "user approval" gate becomes a reviewer-approval gate on the PR itself.
- **Master review pipeline as a managed agent (§3.4).** Listens on `child→master` PRs, applies the separation rule, posts a draft review, requests changes or approves. Hooks fire on merge to schedule post-merge audits.
- **Stale-work janitor as a managed agent (§3.3).** Runs on schedule (or on webhook), produces digests, files issues. Stateless apart from its read of the repo.
- **Agent-SDK-embedded Shamt for non-Claude-Code IDEs.** A wrapper that exposes Shamt skills/agents through the SDK so Cursor / Continue / custom IDE clients can drive the same workflow. Most of the framework already translates because it's file-and-artifact based.

**What changes vs. CLI-shaped Shamt:**

- **User-approval gates become async.** `AskUserQuestion` becomes a PR comment, a GitHub Issue, or a webhook callback. The gate's "blocked" state is durable (the artifact records it) rather than ephemeral (the conversation pauses).
- **Hooks shift from local `settings.json` to deployment config.** PreCompact/SessionStart matter less because managed agents tend to be stateless per-invocation; instead, the artifact-as-state property becomes load-bearing.
- **Memory disappears or moves.** Per-user memory doesn't apply when the agent is a service. Project-level state must live in artifacts or a backing store.
- **Cost model changes.** Managed agents are pay-per-invocation; cost discipline matters more, which makes the prompt-caching and model-selection axes (§2.15) even more important.

**Risk:** This is the most ambitious deployment shape and the framework has not been pressure-tested against async approval flows. Specifically, the "ONE question at a time" rule (S2.P1.I2) becomes awkward when "answering" is a 24-hour-latency PR comment thread — the lite/full distinction may need a third "managed" variant with batched questions.

**Worth scoping if:** anyone wants Shamt to operate without a human in the room, or wants to embed Shamt-style workflows into non-CLI Claude surfaces. Not urgent for the current single-user single-machine use case.

---

## 3. Cross-Cutting Workflows (combining multiple capabilities)

### 3.1 The "Validation Loop as a First-Class Object"

Today: a validation loop is prose in a guide + a markdown log + the agent's memory of what round it's on.

Theorized: a validation loop is a `/loop`-driven skill with an MCP-backed log (`shamt.validation_round()`), a hook that auto-stamps Edits to the log, and a `shamt-validator` Haiku sub-agent for the confirmation round. The agent only writes the *issue analysis*; the harness owns counter, exit criterion, and round mechanics.

**Which capabilities combine:** Skill (`shamt-validation-loop`) + sub-agent (`shamt-validator`) + MCP (`shamt.validation_round`) + hook (auto-stamp) + `/loop` (self-pace rounds).

This is the single highest-value composite, because validation loops are the most-repeated pattern in the entire framework.

### 3.2 The "Architect–Builder Pipeline"

Today: S5 architect writes plan, S6 architect re-reads it, creates handoff, spawns Haiku, monitors with prose updates.

Theorized: S5 emits a typed plan artifact (validated against `implementation_plan_format.md`'s schema via MCP) — and S5 itself runs in plan mode so the architect can't accidentally write code while planning. At S6, the architect (no longer in plan mode) calls `shamt.start_builder(plan_path)` which spawns `shamt-builder` (Haiku, isolated worktree). Architect runs `/loop` to poll builder. Hook on builder Stop fires PushNotification on error; on success the worktree is *surfaced for review*, not auto-merged (auto-merge skips the human checkpoint that S7 exists for).

**Which capabilities combine:** Plan mode (in S5) + sub-agent (`shamt-builder`) + worktree isolation + MCP + `/loop` + hook + push.

### 3.3 The "Stale Work Janitor"

Today: child PRs sit in `design_docs/incoming/`, design docs stall in `active/`, child projects forget to import for months, lessons learned never propagate.

Theorized: a recurring routine (`shamt-janitor`, weekly) scans `incoming/`, `active/`, child sync timestamps, and digest-posts findings. One-shot routines schedule cleanup on epic completion (lessons-learned check at +1 week, import-back at +3 days post-merge).

**Which capabilities combine:** Cron routines + push notifications + MCP for scanning + auto-memory for "what we already triaged."

### 3.4 The "Master Review Pipeline"

Today: child PR opens; master maintainer reads diff, runs audit manually, decides generic vs project-specific, merges or requests changes.

Theorized: GitHub webhook → routine fires `shamt-pr-reviewer` agent → reads diff, applies separation rule via `shamt-guide-auditor`, posts a draft review. Maintainer approves or amends. Hook on merge schedules the post-merge audit.

**Which capabilities combine:** Routines + sub-agents + skills (separation rule) + push notification on review-ready.

### 3.5 The "Metrics & Observability Loop"

Today: PROCESS_METRICS.md and EPIC_METRICS.md exist; they're populated by the agent inline at S11.P3 and at stage exits. Cross-epic trends (how long does S5 typically take? are validation loops getting more rounds over time? is the architect-builder pattern actually saving the projected 60–70%?) require manual aggregation by reading the files.

Theorized: hooks on the relevant artifact edits (validation log round entries, S6 builder Stop events, S11 metric writes) emit structured metric events to an `MCP shamt.metrics.append`. A weekly `shamt-metrics-digest` routine aggregates and posts a digest (per-stage durations, validation round distributions, model usage and token spend, cache hit rates if instrumented). A `/shamt-metrics` slash command queries the same backing store on demand. Anomalies (validation rounds 2σ above median, S6 step count > plan estimate by >50%) trigger PushNotification.

**Which capabilities combine:** Hooks (event emission) + MCP (typed metric store) + routine (weekly digest) + slash command (on-demand query) + push (anomaly alerts).

**Why it matters:** The token-savings claims throughout the framework (model_selection: 30–50%, architect-builder: 60–70%, sub-agent confirmation: 70–80%) are *projected*, not measured. Without instrumentation, there's no way to know if the savings are real, regressions creep in, or different children get wildly different results. This loop is the diagnostic layer the framework currently lacks.

**Bootstrapping caveat:** Several other proposals in this doc lean on empirical claims that this loop would be needed to validate (e.g., §2.15's "Opus 4.7 1M context can hold the whole guide tree", §2.11's `/loop` context savings, §2.1's caching-aware delegation). That's a circular dependency: you can't measure savings without the metrics loop, but you don't ship the metrics loop until something else needs it. The pragmatic path is to ship a *minimal* version (just token-spend events from `Bash`/`Task` calls into a flat log) alongside whichever experiment fires first, and let the diagnostic surface area grow with the proposals it serves.

### 3.6 The "Rollback / Recovery Loop"

Today: `.shamt/guides/missed_requirement/` and the debugging guides cover *manual* recovery (agent realizes mid-S6 that the plan is wrong, agent finds a missed requirement at S7 and recurses). There is no automated rollback. If the builder corrupts a file mid-S6, the agent diagnoses and re-edits; if a validation loop gets stuck, the agent decides to escalate.

Theorized: three composable safety nets.

1. **Worktree-as-rollback-boundary.** All S6 builder execution happens in an isolated worktree (§2.8). On builder failure, the worktree can be discarded entirely with no impact on `main` or other epics. The architect always has a clean baseline to retry from.
2. **Validation-loop stall detection.** A hook on validation log writes tracks `consecutive_clean` history. If it doesn't advance for ≥N rounds, fire PushNotification ("loop stalled at round X, likely needs human judgment") and offer to escalate the model (Sonnet → Opus, extended thinking on per §2.15). Prevents indefinite spinning.
3. **Pre-S10 push tripwire.** A hook on `git push` during S10 verifies the merge target, runs a final smoke check, and refuses if the architect-builder handoff log shows unresolved errors or the validation log shows `consecutive_clean < 1`. Adds a final guard before changes leave the worktree.

**Which capabilities combine:** Worktrees + hooks (stall detection, pre-push tripwire) + push notifications + automatic model escalation (§2.15).

**Why it matters:** The framework's recovery story today is "the agent is smart enough to notice and correct." That works in conversational settings but fails when running headless (managed agent, §2.17) or under cost pressure (cheap-model agent on a deceptively easy plan). Rollback boundaries and stall detection make the recovery story *mechanical* rather than conversational.

---

## 4. Speculative / Longer-Horizon Ideas

These are weaker bets but worth flagging:

- **Shamt as a custom output mode.** Output styles could enforce the "Update Agent Status after every step" rhythm by formatting the agent's output into a structured envelope automatically. Probably overkill, but cute.
- **Multi-repo Shamt orchestration.** A meta-MCP server that knows about multiple child repos and can answer "which children have unimported master changes?" / "which children have un-exported lessons learned?" Useful only if you actually have ≥3 active children.
- **Validation-loop replays as test fixtures.** Archived validation logs could be replayed against new versions of validation skills/prompts to detect regressions. Lightweight CI for the framework itself.
- **Discovery Q&A driven by a small model.** Currently Sonnet does Discovery. With a tight question-brainstorm-categories skill, Haiku might be sufficient — would need a quality study.
- **Memory-backed user-preference learning.** "User has accepted Opus for code review 8/10 times; default to Opus on this repo." Auto-tunes model selection over time.
- **PushNotification on validation-loop stalls.** If `consecutive_clean` hasn't moved in N rounds, ping the user — likely a stuck issue that needs human judgment.

---

## 5. Prioritization (rough)

Effort scale: **XS** (<1 hour, just configuration / a single file), **S** (half day), **M** (1–3 days), **L** (week-plus, real engineering). Value scale: **★** to **★★★★★**.

| # | Proposal | Effort | Value | Notes |
|---|---|---|---|---|
| 1 | **Skills bundle** (`shamt-validation-loop`, `shamt-architect-builder`, `shamt-spec-protocol`, `shamt-code-review`, `shamt-guide-audit`, `shamt-discovery`, `shamt-import`/`-export`) | S | ★★★★★ | Biggest leverage. Each skill is frontmatter + body wrapping content from existing reference guides. Compose with #2. |
| 2 | **Specialized sub-agent definitions** (`.claude/agents/shamt-validator`, `-builder`, `-architect`, `-guide-auditor`, `-spec-aligner`, `-code-reviewer`) | XS–S | ★★★★ | Formalizes model-delegation patterns CLAUDE.md already mandates. Per-agent file, takes minutes each. |
| 3 | **PreCompact + SessionStart hook pair** | S | ★★★★★ | Replaces the GUIDE_ANCHOR / Resume Instructions ritual with harness behavior. Touches at the heart of what makes Shamt feel heavy. |
| 4 | **Slash commands** (`/shamt-start-epic`, `/shamt-validate`, `/shamt-audit`, `/shamt-export`, `/shamt-import`, `/shamt-status`, `/shamt-resume`) | XS | ★★★★ | Markdown files in `.claude/commands/`. Each is a few lines invoking a skill or running a script. Pairs naturally with #1. |
| 5 | **`/loop` for validation rounds + builder monitoring + Discovery** | XS | ★★★★ | No new infrastructure; just adopt the primitive. Big context savings on long validation cycles. |
| 6 | **AskUserQuestion at gates + structured S2.P1.I2 checklist resolution** | S | ★★★ | Turns gate approvals from prose into machine-readable artifacts. Enables hook-based push-blocking (#7). |
| 7 | **Hooks for high-value rules** (`--no-verify` blocker, commit-message format, pre-export audit gate, validation-log auto-stamp, S9 zero-bug push gate) | S | ★★★★ | Small surface, high reliability. Ship as opt-in `settings.local.json` snippets so users can choose. |
| 8 | **PushNotification on user-blocking gates and builder errors** | XS | ★★★ | Quality-of-life. Dovetails with #6 (gates) and #7 (hooks fire the notification). |
| 9 | **Prompt-caching-aware revision of `model_selection.md`** | S | ★★★ | No code; just a guide update. Could meaningfully change the cost equation on validation-loop sub-agents. Requires a small empirical study. |
| 10 | **Worktree isolation for parallel epics** | M | ★★★ | Requires EPIC_TRACKER restructure (split per-epic) to be safe. Only worth it if parallel epics are actually happening. |
| 11 | **`shamt-mcp` server (minimal: `next_number`, `validation_round`)** | M | ★★ | Carve out the two atomic operations first. Skip the broader tool surface unless friction is felt. |
| 12 | **Routines / cron** (`incoming/` triage, post-merge import-back, lessons-learned recheck at +1 week) | M | ★★ | High value but requires either GitHub Actions or a long-running scheduling host. Defer until #1–#5 are paying off. |
| 13 | **Plan mode integration in S5 / S10.P1 / Discovery** | XS | ★★ | Mostly a documentation update — agent already mostly behaves correctly here. |
| 14 | **TaskCreate-based step tracking inside skills** | S | ★★ | Replaces some Agent Status prose. Useful but cross-session persistence requires #3 first. |
| 15 | **Auto-memory split** (move user / project facts out of Agent Status) | XS | ★ | Incremental cleanup. Do as memory accumulates. |
| 16 | **1M-context-aware guide pruning** | M | ★★ | Audit which Resume Instructions / GUIDE_ANCHOR rituals are still load-bearing on Opus 4.7 and trim. Saves agent context, improves clarity. Requires actual measurement. |
| 17 | **Multi-modal + Web tools in Discovery skill** | XS | ★ | Two lines in the skill body permitting Read of attached images and WebFetch with citation requirement. |
| 18 | **Status line showing epic / stage / blocker** | XS | ★★ | Cosmetic but reduces "where am I" load. Tiny script reading Agent Status. |
| 19 | **Metrics & observability loop** (§3.5: hooks → typed metric store → weekly digest + on-demand query) | M | ★★★ | Required to validate the framework's projected token savings empirically. Without this, model-selection claims drift from reality. |
| 20 | **Rollback / recovery loop** (§3.6: worktree-as-rollback + stall detection + pre-push tripwire) | S–M | ★★★ | The mechanical-recovery story headless deployment (§2.17) needs. Worth doing alongside worktree adoption (#10). |
| 21 | **Extended-thinking-aware model selection** (§2.15: triggered by stuck `consecutive_clean` or root-cause diagnosis) | XS | ★★ | Guide update only; small empirical study to set the trigger thresholds. |
| 22 | **Claude Agent SDK / managed-agent deployment** (§2.17) | L | ★★★ | Only justified if Shamt needs to run headless (CI, master review automation). Defer until the use case is real. |

The top cluster (#1–#5) is the high-leverage, low-effort core. #3 (PreCompact/SessionStart) is the highest-impact single hook pair and probably should be done before #7's broader hook suite — it has more behavioral effect on the framework's day-to-day shape than any other proposal here. #19 and #20 are the diagnostic and safety layers respectively; both become urgent the moment #22 (managed-agent deployment) is on the table, because headless operation breaks the "agent is smart enough to notice" recovery story the framework currently relies on.

---

## 6. Risks & Anti-Patterns to Avoid

- **Don't build infrastructure ahead of demonstrated friction.** MCP servers, custom routines, multi-repo orchestrators — all are fun to design and overkill for a single-user single-machine setup. Add capability when you've felt the pain twice.
- **Don't let hooks become invisible policy.** Every hook is a piece of magic the user can't see in CLAUDE.md. Document each hook in the same place as the rule it enforces, or the framework gets harder to reason about.
- **Don't fragment state across systems.** Shamt's strength is that everything is files in `.shamt/`. The moment state lives in MCP database + memory + status file + EPIC_TRACKER + git, the framework loses its "any agent can resume from artifacts" property. New state goes in artifacts unless there's a strong reason otherwise.
- **Skills with overlapping triggers fight each other.** Tight, anchor-based triggers (file paths, exact phrases) beat loose semantic ones.
- **`/loop` and hooks together can build a system that runs without supervision.** That's powerful and risky. Default to *opt-in* loops with clear exit conditions and visible state.

---

## 7. What I'd Actually Try First

Two candidate experiments, depending on appetite:

**Experiment A (capability test):** Build the `shamt-validation-loop` skill and the `shamt-validator` Haiku agent definition together. Run them through a real S2.P1.I3 spec validation. Measure tokens, rounds-to-exit, and how much of the round-counter / exit-criterion bookkeeping fell off the agent's plate. *Validates the skills+agents thesis.*

**Experiment B (architectural test):** Wire up the PreCompact + SessionStart hook pair to dump and re-hydrate epic state, and audit whether GUIDE_ANCHOR.md / Resume Instructions can be retired or simplified. *Validates the "harness can replace bookkeeping prose" thesis.*

A is the safer first step (no surface-area changes to the framework, just additive). B is the higher-impact bet (touches the core compaction-fear architecture).

**Sequencing and gate criteria:**
- Run **A first**. It's additive, low-risk, and produces baseline token-cost numbers (paired with the minimal metrics-loop instrumentation per §3.5) that B will need for comparison.
- A's success gate: validation loop on a real S2.P1.I3 spec exits in fewer or equal rounds than baseline, with ≥30% token reduction on the validation phase, and the agent's prose around round-counter / exit-criterion bookkeeping visibly drops out. If A clears that bar, ship the broader skills bundle (§5 #1) and sub-agent definitions (#2).
- After A ships, run **B**. B's success gate: at least one full epic completes without the agent reading GUIDE_ANCHOR.md or Resume Instructions because PreCompact/SessionStart carried the context, *and* a deliberate compaction event mid-epic produces a clean resume. If B clears that bar, the framework can begin retiring those guides — start with the lightest (Resume Instructions on small-stage guides), defer the EPIC_TRACKER-adjacent ones until cross-epic worktree work is in scope.
- If A fails: the issue is probably that the validation-loop work isn't as mechanical as it looks; investigate before continuing. If B fails: PreCompact/SessionStart probably can't carry all the state we think they can, and the framework's compaction prose is doing more work than it appears. Either failure is informative — it tells us the framework isn't redundant where it looks redundant — and re-grounds the rest of the prioritization table.

---

*End of theorization.*
