# Shamt Future Architecture — Overview

**Status:** Synthesis / explainer (not a SHAMT-N design doc)
**Date:** 2026-04-27
**Purpose:** Show what the Shamt master repo and child projects would look like if both `CLAUDE_INTEGRATION_THEORIES.md` and `CODEX_INTEGRATION_THEORIES.md` were fully implemented. Pitched at someone learning these AI-host capabilities — concepts are explained inline as they come up.

**How to read this doc:**
- §1 — Concept primer for the unfamiliar terms (MCP, hooks, skills, sub-agents, sandbox modes, etc.)
- §2 — What the master repo grows into
- §3 — How a child project looks on Claude Code, on Codex, and dual-host
- §4 — Sync flow: how master ↔ child stays coherent
- §5 — Walkthrough: a single validation loop end-to-end
- §6 — Why the architecture works (load-bearing principles)
- §7 — Living with the architecture: user experience, failure modes, costs
- §8 — Adoption path from today to there
- §9 — Quick reference table
- §10 — One-sentence summary

If you're already comfortable with Claude Code / Codex internals, skip §1.

**Note on selectivity:** This overview prioritizes the **architecturally load-bearing** capabilities — the ones that change the master repo's shape and the host shim story. Mid- and low-priority proposals from the source docs (e.g., status line, multi-modal Discovery, routines/cron, auto-memory, IDE plugin polish, Codex web search modes, Codex-as-MCP-server agent mesh) are mentioned where relevant but not given their own primer entries. The two source theorization docs cover the full surface in their §5 prioritization tables; this doc covers the architecture, not the catalog.

---

## 1. Concept Primer

### `CLAUDE.md` and `AGENTS.md` — the rules file

A markdown file at the repo root that the AI host reads automatically at session start. Acts like a system prompt the user can edit. **Claude Code** reads `CLAUDE.md`; **Codex** reads `AGENTS.md` (and supports a hierarchical lookup with `AGENTS.override.md` priority and per-subdirectory layering). Both serve the same purpose: tell the agent the project conventions, do-not rules, and what context to load.

Shamt currently generates this file at init from `RULES_FILE.template.md`. The future architecture keeps the same pattern but adds host-specific wiring around it.

### MCP — Model Context Protocol

Think of MCP as **typed function calls between an AI agent and an external service**. Today, when an agent needs to do something mechanical (look up a SHAMT-N number, append to a log, run an audit), it shells out via Bash and parses the text output. That's fragile — output formats change, errors are easy to miss.

MCP is a small protocol where the agent calls `shamt.next_number()` and gets back a structured result like `{"number": 42, "reserved": true}`. The agent doesn't parse strings; it reads typed data. An MCP **server** is a small program (in any language) that implements these functions and exposes them over stdio or HTTP. The harness (Claude Code, Codex) handles the plumbing.

**Analogy:** if Bash is "talk to a Unix process by writing and reading text," MCP is "call a Python function — but the function happens to live in a different process."

### Hooks

Hooks are **scripts that the AI harness fires automatically on certain events**. The harness has named events like:
- `PreToolUse` — before an agent runs a tool (Read, Write, Bash, etc.)
- `PostToolUse` — after a tool runs
- `UserPromptSubmit` — when the user types a message
- `SessionStart` — when a new conversation begins
- `Stop` — when the agent finishes a turn
- **`PreCompact`** (Claude Code only) — before the harness summarizes/compresses the conversation
- **`PermissionRequest`** (Codex only) — before the harness asks the user to approve an action

A hook is a small shell script the harness runs at the event. The script can read the event details from stdin and decide to **allow / deny / modify** the action by writing to stdout. Useful for "always do X before Y" rules that today live as prose in CLAUDE.md.

**Example:** a hook on `PreToolUse` matching `git commit` can reject any commit message that doesn't start with `feat/SHAMT-N:`, enforcing Shamt's commit format mechanically.

### Skills

A **skill** is a small markdown file with frontmatter (a YAML header) and a body of instructions. The harness reads the frontmatter trigger and **auto-loads the skill into the agent's context** when the trigger matches. The body is whatever protocol you want the agent to follow.

```
.claude/skills/shamt-validation-loop/SKILL.md:
    ---
    name: shamt-validation-loop
    description: Run a Shamt validation loop on a markdown artifact
    triggers: ["validate this", ".../validation_log.md"]
    ---
    # Validation Loop Protocol
    1. Read the artifact
    2. Check all 8 dimensions
    3. ...
```

Today, a Shamt agent has to *remember* to read `validation_loop_master_protocol.md` from the guide tree. With a skill, the harness auto-loads the protocol when the trigger matches. The agent doesn't have to remember; the harness handles discovery.

Codex's skills surface is in flux; their predecessor "custom prompts" works similarly but is invoked explicitly (`/prompts:shamt-validation-loop`) rather than auto-triggered.

### Sub-agents

A **sub-agent** is a separate agent process spawned by a parent agent, with its own context, prompt, and (often) model choice. The parent says "run this task in a fresh agent and return the result." The sub-agent runs to completion, then exits.

Useful for:
- **Independent verification** — "I think this validation log shows zero issues. Sub-agent: read it fresh and confirm."
- **Token budgets** — heavy mechanical work runs in a Haiku/cheap-model sub-agent so the parent (an Opus/expensive-model) doesn't burn its context on it.
- **Tool restriction** — a sub-agent can be given fewer tools than the parent (read-only, no shell, no write). Reduces blast radius.

Sub-agents are defined in `.claude/agents/<name>.md` (Claude Code) or `.codex/agents/<name>.toml` (Codex). The definition specifies model, tools, and a prompt template.

### Profiles (Codex)

Codex's config file (`.codex/config.toml`) supports **named profiles** — bundles of settings (model, sandbox mode, approval policy, MCP servers, reasoning effort) you can switch between with `codex --profile <name>`. Useful for stage-specific configuration: a `shamt-s5` profile pins planning to read-only with high reasoning effort; a `shamt-s6` profile pins building to workspace-write with minimal reasoning; the user picks at session start.

Claude Code has no exact equivalent; you'd approximate by spawning sub-agents with different tool/model settings.

### PermissionRequest hook (Codex-only)

A hook that fires when the harness is about to ask the user for approval (e.g., before running a shell command, before editing a file outside an allowed directory). The hook can return `{"decision": "approve" | "deny"}` to short-circuit. Useful for auto-approving low-risk in-scope operations while preserving human review for risky ones.

Example: during S6 builder execution, auto-approve any edit inside the active feature folder; bubble everything else to the user. Reduces approval fatigue without abandoning the gate.

### Reasoning effort (Codex; analogous to Claude's "extended thinking")

A setting controlling how much "thinking budget" the model spends on each response. Codex exposes five levels (`minimal | low | medium | high | xhigh`). Cheap, fast tasks (mechanical execution, sub-agent confirmation) want `minimal` or `low`; hard validation rounds and root-cause diagnoses want `high` or `xhigh`. Per-sub-agent override in TOML.

Claude has a similar concept (extended thinking on/off plus model choice); the lever is binary-ish rather than five-level.

### Agents SDK (Codex)

A Python / TypeScript library that lets your own program drive Codex sessions programmatically. Instead of "user types in CLI," your script calls `agents.run(...)` and gets back the result. Useful for embedding Codex into CI scripts, custom IDE plugins, internal dev tools.

For Shamt, the SDK enables a `shamt-validate-pr.py` style CI script: a GitHub Action runs the script, the script drives a Codex session through the validation skill, results are posted as a PR comment. No interactive user needed.

### Sandbox modes (Codex first-class)

A sandbox mode is the **set of operations the agent is allowed to perform**. Codex makes this explicit:
- `read-only` — the agent can read files but cannot edit, write, or run side-effecting shell commands
- `workspace-write` — can edit files inside the working tree, but not outside
- `danger-full-access` — anything goes (use with care)

Each Codex sub-agent declares its sandbox mode in TOML. A `shamt-validator` defined as `sandbox_mode = "read-only"` *cannot* accidentally edit the artifact it's validating, even if the prompt has a bug.

Claude Code achieves a similar effect via tool allowlists (per-agent `tools: [...]` lists), but Codex's three-mode declarative version is structurally tighter.

### `requirements.toml` (Codex-only)

An **admin-enforced policy file** unique to Codex. Where regular config (`config.toml`) is user-editable, `requirements.toml` is intended to be set by an admin and *not bypassed* by the user. It can pin sandbox mode floors ("never `danger-full-access`"), allowlist MCP servers, set deny-read globs ("never read `.env`"), and force hook directories.

For Shamt, this is the cleanest expression of the master-vs-child contract: a child project's `requirements.toml` is set by Shamt master, and rules like "the audit hook must run before export" are *enforced* by the harness rather than relying on the agent to follow them.

Claude Code has no equivalent today.

### OpenTelemetry (OTel)

OpenTelemetry is the **industry-standard observability protocol**. Programs emit "traces" (a record of what happened) and "metrics" (counts and durations) over OTLP, and a collector (Grafana, Honeycomb, Jaeger, Datadog, etc.) ingests them.

Codex emits OTel out of the box: every tool call, every model request, every token spent shows up in the collector with stage / sub-agent / model labels. This is "free observability" — the kind of metrics dashboard you'd otherwise have to instrument by hand.

Claude Code doesn't currently expose OTel; on Claude Code, observability has to be built via hooks → MCP → custom logging.

### `@codex` GitHub mention

You can tag `@codex` in a GitHub issue or PR comment, and Codex will spin up a **cloud task** (a disposable container running Codex) to address it. The task can read the diff, edit files, run tests, and open a PR — all without anyone interactively driving it. It's "Codex as a service" triggered via GitHub's native mention syntax.

### Codex Cloud / containers

When `@codex` fires (or you start a task at chatgpt.com/codex), Codex spins up an **isolated container** based on the open-source `codex-universal` image (preinstalled languages and tools). The repo is checked out, setup scripts run, the agent loop runs, results are committed. Containers are disposable — failure means start over with no cleanup.

Useful for parallel work (run 6 features concurrently in 6 containers) and for headless automation (PR review, CI gates).

### `/loop` (Claude Code) and self-pacing iteration

Claude Code skill that **runs a prompt repeatedly with self-pacing**. You set a goal and an exit condition; the harness keeps invoking the prompt until the condition is met, sleeping between iterations to amortize cost. Natural fit for Shamt's "iterate until clean" patterns — validation loops, discovery Q&A, builder monitoring. The agent doesn't have to track round counters in conversation; the harness does.

Codex doesn't have a single equivalent primitive; the same pattern is approximated by `codex exec` invoked from a small driver script, or by `/fork` for branching exploration.

### `AskUserQuestion` (Claude Code) — structured user prompts

A Claude Code tool that lets the agent ask a structured question with predefined options ("approve as-is" / "request changes" / "reject scope") and capture the answer in a parseable form. Better than free-text agent prose for gates the user must explicitly answer — S5 plan approval, S9 zero-bug confirmation, S2.P1.I2 checklist resolution. Combined with hooks, it lets you build "block this push unless `AskUserQuestion` recorded ZERO bugs" enforcement.

Codex doesn't have a one-to-one equivalent today; explicit-options gates are typically posted as PR comments or simulated via the agent's prose plus a structured artifact write.

### Worktrees vs. containers

Both are isolation mechanisms for parallel work. **Worktrees** (Claude Code via `Agent isolation: "worktree"`) check out a separate Git working copy in a subdirectory; multiple agents can work on different branches without checkout conflicts. **Containers** (Codex Cloud) spin up a disposable VM-equivalent per task — stronger isolation, harder rollback semantics, but tied to the cloud surface.

For Shamt's parallel-feature work in S2 / S5 / S7, worktrees solve the "multi-agent on one repo" problem on Claude Code; containers solve it more thoroughly on Codex Cloud. The architecture proposes both, host-appropriately.

### PreCompact hook

When a Claude Code conversation gets long enough that context overflows, the harness **compacts** it — summarizing earlier messages to free up room. By default this happens silently. The `PreCompact` hook fires *before* compaction, giving you a chance to dump important state to disk so it survives. Shamt's `GUIDE_ANCHOR.md` and Resume Instructions exist as compensation for the harness not deterministically preserving context across compaction (and across sessions in general); a PreCompact + SessionStart hook pair takes over much of that bookkeeping by writing the snapshot at compaction time and reading it back on session resume.

Codex does not have a PreCompact equivalent. The Codex doc discusses three workarounds (custom `compact_prompt`, manual `/compact` discipline, artifact-as-substrate).

---

## 2. The Master Repo, Future State

Here's what `shamt-ai-dev/` looks like once both theorization docs are fully realized:

```
shamt-ai-dev/
├── README.md
├── CLAUDE.md                           # master rules (already exists)
├── design_docs/                        # already exists
│   ├── active/
│   ├── incoming/
│   ├── archive/
│   ├── CLAUDE_INTEGRATION_THEORIES.md
│   ├── CODEX_INTEGRATION_THEORIES.md
│   ├── FUTURE_ARCHITECTURE_OVERVIEW.md (this doc)
│   └── NEXT_NUMBER.txt
└── .shamt/
    ├── guides/                         # already exists; revised for cache-aware model_selection
    │   ├── stages/                     # S1–S11 guides
    │   ├── reference/
    │   │   ├── model_selection.md      # ← updated: adds cache state + reasoning effort axes
    │   │   ├── architect_builder_pattern.md
    │   │   ├── validation_loop_master_protocol.md
    │   │   └── ...
    │   ├── audit/, code_review/, ...
    │   └── sync/, templates/
    │
    ├── skills/                         # NEW — canonical, host-portable skill content
    │   ├── shamt-validation-loop/SKILL.md
    │   ├── shamt-architect-builder/SKILL.md
    │   ├── shamt-spec-protocol/SKILL.md
    │   ├── shamt-code-review/SKILL.md
    │   ├── shamt-guide-audit/SKILL.md
    │   ├── shamt-discovery/SKILL.md
    │   ├── shamt-import/SKILL.md
    │   ├── shamt-export/SKILL.md
    │   ├── shamt-master-reviewer/SKILL.md
    │   └── shamt-lite-story/SKILL.md
    │
    ├── agents/                         # NEW — canonical sub-agent personas
    │   ├── shamt-validator.yaml        # neutral persona definition (sandbox, model, prompt)
    │   ├── shamt-builder.yaml
    │   ├── shamt-architect.yaml
    │   ├── shamt-guide-auditor.yaml
    │   ├── shamt-spec-aligner.yaml
    │   ├── shamt-code-reviewer.yaml
    │   └── shamt-discovery-researcher.yaml
    │
    ├── commands/                       # NEW — canonical slash command bodies
    │   ├── shamt-start-epic.md
    │   ├── shamt-validate.md
    │   ├── shamt-audit.md
    │   ├── shamt-export.md
    │   ├── shamt-import.md
    │   ├── shamt-status.md
    │   ├── shamt-resume.md
    │   ├── shamt-promote.md
    │   └── shamt-builder.md
    │
    ├── hooks/                          # NEW — hook script bodies (executable, host-neutral)
    │   ├── pre-export-audit-gate.sh
    │   ├── commit-format.sh
    │   ├── no-verify-blocker.sh
    │   ├── validation-log-stamp.sh
    │   ├── architect-builder-enforcer.sh
    │   ├── user-testing-gate.sh
    │   ├── permission-router.sh        # Codex PermissionRequest handler
    │   ├── precompact-snapshot.sh      # Claude Code PreCompact handler
    │   └── session-start-resume.sh     # both hosts
    │
    ├── mcp/                            # NEW — shamt-mcp server (cross-host)
    │   ├── README.md
    │   ├── pyproject.toml              # or Cargo.toml / package.json — implementer's choice
    │   └── src/                        # tools: next_number, validation_round, audit_run,
    │                                   #        epic_status, metrics.append, export, import
    │
    ├── observability/                  # NEW — OTel + dashboards
    │   ├── otel-collector.yaml         # OTel collector config preset
    │   ├── grafana/                    # Shamt-aware Grafana dashboards (JSON)
    │   └── README.md                   # how to wire OTel into a child project
    │
    ├── sdk/                            # NEW — Agents SDK scripts (Python / TypeScript)
    │   ├── shamt-validate-pr.py        # CI gate: validates artifacts on PR
    │   ├── shamt-cron-janitor.py       # scheduled stale-work scanner
    │   └── README.md
    │
    ├── host/                           # NEW — host-specific wiring templates
    │   ├── claude/
    │   │   ├── settings.starter.json   # initial .claude/settings.json content
    │   │   └── README.md
    │   └── codex/
    │       ├── config.starter.toml     # initial .codex/config.toml content
    │       ├── requirements.toml.template
    │       ├── profiles/
    │       │   ├── shamt-s1.fragment.toml
    │       │   ├── shamt-s2.fragment.toml
    │       │   ├── shamt-s5.fragment.toml
    │       │   ├── shamt-s6-builder.fragment.toml
    │       │   ├── shamt-validator.fragment.toml
    │       │   └── ...
    │       └── README.md
    │
    ├── scripts/
    │   ├── initialization/
    │   │   ├── init.sh / init.ps1                # ← extended with host-aware wiring
    │   │   ├── init_lite.sh / init_lite.ps1
    │   │   ├── RULES_FILE.template.md            # → CLAUDE.md / AGENTS.md (existing)
    │   │   ├── SHAMT_LITE.template.md
    │   │   ├── ARCHITECTURE.template.md
    │   │   ├── CODING_STANDARDS.template.md
    │   │   ├── EPIC_TRACKER.template.md
    │   │   ├── ai_services.md                    # ← adds wiring-tier column
    │   │   ├── reference/, templates/
    │   │   └── ...
    │   ├── regen/                                # NEW — host-shim regeneration
    │   │   ├── regen-claude-shims.sh             # .shamt/skills → .claude/skills, etc.
    │   │   ├── regen-codex-shims.sh              # .shamt/skills → .codex/agents, profiles
    │   │   └── README.md
    │   ├── statusline/                           # NEW — status-line scripts (Claude Code)
    │   │   └── shamt-statusline.sh               # renders epic / stage / blocker
    │   ├── export/                               # existing
    │   ├── import/                               # existing — extended to call regen post-import
    │   └── storage/
    │
    └── epics/                                    # existing — not relevant to child sync
        ├── EPIC_TRACKER.md
        ├── requests/
        └── done/
```

The big additions are six new top-level directories under `.shamt/`: **skills**, **agents**, **commands**, **hooks**, **mcp**, **observability**, **sdk**, and **host**. Plus a small **scripts/regen/** directory for the host-shim wiring.

---

## 3. Child Projects, Future State

A child project's structure depends on which host(s) the user picked at init. Three configurations:

### 3a. Child project on Claude Code only

```
my-claude-project/
├── README.md
├── CLAUDE.md                       # generated by init from RULES_FILE.template.md
├── .shamt/                         # MASTER-SYNCED
│   ├── guides/                     # (existing)
│   ├── skills/                     # canonical skill content
│   ├── agents/                     # canonical sub-agent personas
│   ├── commands/                   # canonical slash command bodies
│   ├── hooks/                      # canonical hook scripts
│   ├── mcp/                        # canonical shamt-mcp server source
│   ├── observability/              # OTel preset (optional in child)
│   ├── sdk/                        # SDK scripts (optional)
│   ├── host/                       # only host/claude/ used here
│   ├── scripts/
│   ├── epics/                      # local epic state (not synced)
│   └── CHANGES.md                  # local upstream candidates (not synced)
│
└── .claude/                        # PROJECT-LOCAL (generated by init + regen scripts)
    ├── skills/                     # → mirrors .shamt/skills/ (auto-regenerated)
    │   ├── shamt-validation-loop/SKILL.md
    │   └── ...
    ├── agents/                     # → from .shamt/agents/ (Claude Code form)
    │   ├── shamt-validator.md
    │   └── ...
    ├── commands/                   # → from .shamt/commands/
    │   ├── shamt-validate.md
    │   └── ...
    └── settings.json               # init writes Shamt blocks; user owns afterward
                                    # blocks: hooks registry, mcpServers, statusLine
```

### 3b. Child project on Codex only

```
my-codex-project/
├── README.md
├── AGENTS.md                       # generated by init from RULES_FILE.template.md
├── requirements.toml               # ← Codex admin policy, copied from template
├── .shamt/                         # MASTER-SYNCED (same as 3a)
│   └── ...
└── .codex/                         # PROJECT-LOCAL
    ├── agents/                     # → from .shamt/agents/ (Codex TOML form)
    │   ├── shamt-validator.toml
    │   └── ...
    └── config.toml                 # init writes Shamt blocks; user owns afterward
                                    # blocks: profiles import, mcp_servers, hooks, otel
```

### 3c. Dual-host child project (Claude Code + Codex)

```
my-dual-host-project/
├── README.md
├── CLAUDE.md                       # symlink or duplicate of AGENTS.md
├── AGENTS.md                       # primary instruction file
├── requirements.toml               # Codex admin policy
├── .shamt/                         # MASTER-SYNCED
├── .claude/                        # Claude Code wiring (as 3a)
│   └── ...
└── .codex/                         # Codex wiring (as 3b)
    └── ...
```

A dual-host project is the recommended posture per the Codex doc's §8: **Codex for headless / CI / scheduled work, Claude Code for interactive epic execution**, sharing one `.shamt/` substrate.

---

## 4. Sync Flow — How Master ↔ Child Stays Coherent

```
┌──────────────────────────────────────────────────────────────────┐
│  MASTER REPO (shamt-ai-dev)                                      │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  .shamt/                                                 │    │
│  │    skills/  agents/  commands/  hooks/  mcp/  ...        │    │
│  │    guides/  scripts/  host/  observability/  sdk/        │    │
│  └──────────────────────────────────────────────────────────┘    │
│                       │                                          │
│                       │ (1) export script bundles updates        │
│                       ▼                                          │
│              ┌─────────────────┐                                 │
│              │  diff package   │                                 │
│              └─────────────────┘                                 │
└──────────────────────│───────────────────────────────────────────┘
                       │
                       │ via PR / shamt import
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│  CHILD PROJECT                                                   │
│                                                                  │
│  (2) import script applies diffs to .shamt/                      │
│      │                                                           │
│      ▼                                                           │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  .shamt/  (updated content from master)                  │    │
│  └──────────────────────────────────────────────────────────┘    │
│      │                                                           │
│      │ (3) regen script: .shamt/ → host shims                    │
│      ▼                                                           │
│  ┌──────────────────────────┐    ┌────────────────────────────┐  │
│  │  .claude/                │    │  .codex/                   │  │
│  │    skills/  agents/      │    │    agents/                 │  │
│  │    commands/             │    │    config.toml             │  │
│  │    settings.json (★)     │    │    (profiles imports ★)    │  │
│  └──────────────────────────┘    └────────────────────────────┘  │
│                                                                  │
│  ★ settings.json / config.toml are NOT regenerated on sync.      │
│    Init writes them once; user owns them afterward.              │
└──────────────────────────────────────────────────────────────────┘
```

Key property: **Shamt updates touch `.shamt/` only**. Host config files (`settings.json`, `config.toml`, `requirements.toml`) are written *once* at init and respected thereafter. The regen step refreshes auto-generated host shims (skills, agents, commands directories) but never the user-edited config files.

This means: a child project can heavily customize `.claude/settings.json` (their Claude theme, their personal permission allowlist, their own non-Shamt skills) and Shamt updates will not stomp on any of it.

---

## 5. End-to-End Walkthrough — A Validation Loop

To make the layered architecture concrete, let's trace what happens when a developer asks "validate this spec" on a Shamt-on-Claude-Code child project, post-implementation of all the theories:

```
USER: "Validate the spec at .shamt/epics/SHAMT-42/feature-a/spec.md"
  │
  ▼
[1] Claude Code recognizes a skill trigger.
    Reads .claude/skills/shamt-validation-loop/SKILL.md
    (which is a shim/symlink pointing at .shamt/skills/shamt-validation-loop/SKILL.md)
  │
  ▼
[2] Skill body instructs the agent to:
    a. Initialize a validation log via MCP:
         shamt.validation_round(log_path="...", round=1, dimensions=[...])
       → returns {round_number: 1, consecutive_clean: 0}
    b. Run primary review against the 8 dimensions
    c. Spawn shamt-validator sub-agent (twice, in parallel) for confirmation
  │
  ▼
[3] Agent does primary review, finds 1 MEDIUM issue, fixes it.
    Calls MCP again:
         shamt.validation_round(round=1, severity_counts={MEDIUM: 1, LOW: 0}, fixed=true)
       → returns {consecutive_clean: 0}
    
    Hook (PostToolUse on Edit of validation_log.md) fires:
         .shamt/hooks/validation-log-stamp.sh
         Auto-stamps timestamp + model used into the log
  │
  ▼
[4] Round 2: agent re-reads, finds no issues.
    Calls MCP:
         shamt.validation_round(round=2, severity_counts={}, ...)
       → returns {consecutive_clean: 1}
  │
  ▼
[5] Sub-agent confirmation:
    Agent invokes Task tool with subagent_type="shamt-validator"
    → spawns Haiku sub-agent defined in .claude/agents/shamt-validator.md
       (synced from .shamt/agents/shamt-validator.yaml)
    Sub-agent runs with read-only sandbox / tool restriction by definition
    (cannot edit the artifact it's validating, even if its prompt has a bug)
    Sub-agent reads artifact, reports zero issues
  │
  ▼
[6] Two parallel sub-agents both confirm clean.
    Hook (SubagentStop) fires:
         .shamt/hooks/validation-confirmation.sh
         Refuses to mark loop complete unless both confirmers reported zero
    Both did → loop exits clean.
  │
  ▼
[7] OPTIONAL: PushNotification fires
    "SHAMT-42 feature-a spec validation: PASSED (2 rounds, 1 MEDIUM fixed)"
  │
  ▼
[8] OPTIONAL: OTel emits trace data (on Codex; or via custom MCP on Claude Code)
    Visible in the OTel collector as a span tree:
         shamt-validation-loop
           ├── round-1 (primary, Opus, 4.2K tokens)
           ├── round-2 (primary, Opus, 1.8K tokens)
           ├── confirmer-1 (sub-agent, Haiku, 0.9K tokens)
           └── confirmer-2 (sub-agent, Haiku, 0.9K tokens)
```

Each step touches a different layer:

- **Skill** (`.claude/skills/`) — what to do (the protocol)
- **MCP** (`.shamt/mcp/`) — typed verbs (`validation_round`, etc.)
- **Hooks** (`.shamt/hooks/`) — automatic enforcement around the verbs
- **Sub-agents** (`.claude/agents/`) — independent confirmation with restricted tools
- **OTel/Push** — observability and notification surfaces

The agent's *prose* shrinks dramatically: round counters, exit criteria, severity counting, "remember to call the validator" — all of that becomes structural rather than narrative. The agent narrates only the issue analysis, not the bookkeeping.

---

## 6. Why the Architecture Works (Load-Bearing Principles)

Four principles hold the whole thing together:

### Principle 1: `.shamt/` is the source of truth; host directories are downstream artifacts

Everything Shamt cares about lives in `.shamt/`. Host directories (`.claude/`, `.codex/`) hold either auto-regenerated shims or user-owned wiring. This is what makes the dual-host story tractable: same content, two host shapes.

```
┌────────────────────────────────────────┐
│  CONTENT LAYER (.shamt/)               │  ← canonical, host-portable
│  skills, agents, commands, hooks,      │
│  mcp server, sdk scripts, observability│
└────────────────┬───────────────────────┘
                 │
                 │ regen (mechanical transform per host)
                 │
        ┌────────┴────────┐
        ▼                 ▼
┌──────────────┐    ┌──────────────┐
│ .claude/     │    │ .codex/      │  ← host shims (auto-generated)
└──────────────┘    └──────────────┘
        ▲                 ▲
        │                 │
        │  written-once-then-user-owns
        │
   settings.json    config.toml + requirements.toml
```

### Principle 2: Mechanical operations belong in MCP; instructions belong in skills; rules belong in hooks

A clean separation of concerns:

- **What to do?** → skill (markdown protocol body)
- **How to do verb X?** → MCP function (typed call)
- **What must always happen at event Y?** → hook (script triggered by harness)

Conflating these makes Shamt brittle. Today the framework conflates them in prose ("the agent should remember to update the validation log; if the validator reports issues the agent should not exit"). The split makes each concern enforceable by the appropriate layer.

### Principle 3: Cross-host portability is a property, not a goal

Once content is in `.shamt/` and the MCP server is the execution layer, **adding a new host is a two-file effort**: a regen script that produces host-shaped shims, and a settings/config writer for first-time init. Codex compatibility, future Cursor compatibility, future Claude Agent SDK packaging — all become small additions, not framework rewrites.

### Principle 4: Master enforces what it can; child owns what it must

Master controls the canonical content. The child controls user-machine wiring. Codex's `requirements.toml` lets master enforce *rules* (no `danger-full-access`, audit must run before export) without owning *config* (the user's preferred reasoning effort, their personal MCP additions). Claude Code lacks a perfect equivalent, so on Claude Code master enforcement is softer (hooks the user could disable) — but that asymmetry is an honest reflection of harness capability, not a Shamt design flaw.

---

## 7. Living With the Architecture — User Experience, Failure Modes, Costs

The architecture is described in terms of files and primitives so far. Three practical questions a learner reasonably asks:

### 7a. What changes for the human user?

**Less to remember, same control over decisions.** The user's job today on Shamt is "drive the agent through the workflow, approve gates, answer checklist questions, watch for the agent forgetting a rule." After adoption:

- **Gates that mattered are still gates.** S5 plan approval, S9 user-testing zero-bug confirmation, S10 PR creation — all still ask the user. `AskUserQuestion` makes the prompt structured rather than free-text, but the user is still the decider.
- **Gates that didn't matter become invisible.** Approval prompts for routine in-scope edits, the agent re-reading reference guides at the start of each phase, manual round-counter tracking — all handled by hooks / MCP / skills. The user stops seeing them.
- **The CLAUDE.md / AGENTS.md rules are still authoritative**, but more of them are *enforced by the harness* rather than *requested of the agent*. A user can still read CLAUDE.md to understand what Shamt expects; they can also trust that "the architect-builder pattern is mandatory in S6" is a hook-rejected violation, not a polite suggestion.
- **Day-to-day feel:** fewer interruptions for trivial approvals, more trust that bookkeeping is correct, the validation log just *has* the right round count without the agent reciting it.

### 7b. Failure modes and what to do about them

The new architecture introduces new things that can fail. Each has a known mitigation:

| Failure | Symptom | Mitigation |
|---|---|---|
| MCP server crashes / unreachable | `shamt.validation_round()` errors out | Skill body falls back to writing prose entry directly to the validation log; harness retries on next call. Don't make MCP load-bearing for correctness — only for ergonomics. |
| Hook script has a bug | Legitimate operations get rejected | Codex-only: `requirements.toml` ships only well-tested hooks. Both hosts: opt-in via `settings.local.json` snippets initially; promote to `settings.json` after soak. Test the deny path before shipping. |
| Sub-agent confirmer disagrees with parent | Validation loop won't exit; counter stuck at 0 | After N rounds without progress, push notification fires; user is brought into the loop. `consecutive_clean=0` for ≥2 rounds is a known signal to escalate reasoning effort or model. |
| Compaction loses state mid-loop | Agent re-reads GUIDE_ANCHOR / Resume Instructions and recovers | Pre-adoption fallback. After PreCompact hook lands (Claude Code) or `compact_prompt` is configured (Codex), the snapshot is deterministic. |
| Sync fetches a broken skill update | Skill behaves wrong; nothing critical breaks | `shamt import` is reviewed before accepting. Validation loop on the imported content catches issues. Easy rollback via git. |
| Codex container fails mid-S6 build | Cloud task errors; no local damage | Disposability: the container is discarded, architect re-spawns. Worktree-as-rollback-boundary on Claude Code is the analog. |

The general rule: **artifacts are the durable substrate, primitives are the ergonomics**. As long as `.shamt/epics/<active>/` and the validation logs are intact, recovery is a fresh agent reading the artifacts.

### 7c. Cost implications

More sub-agents and more hook fires mean more API calls — but the net effect is usually *cheaper*, because the architecture lets cheap models do most of the work:

- **Sub-agent confirmation** — Haiku/cheap-model sub-agents replace Opus/expensive-model context-spend on mechanical bookkeeping. The Claude doc projects 70–80% savings on confirmation rounds.
- **Architect-builder split** — expensive model plans, cheap model executes. 60–70% savings projected on S6 implementation.
- **Prompt caching** — guides re-read across sessions and across sub-agents become cache-hits after the first read. Significant savings; quantification needs the metrics loop (§3.5 of the source docs).
- **OTel telemetry / `shamt.metrics.append()`** — closes the loop on whether projected savings are real. The metrics loop is partly self-validating: it instruments the cost claims it's measuring.

The honest caveat: **savings claims are projected, not measured**. The §3.5 metrics & observability cross-cutting workflow (in both source docs) is what would empirically validate them. Until that lands, treat the percentages as hypotheses worth testing, not guarantees.

---

## 8. Adoption Path — How to Get From Today to There

Today, master has `.shamt/guides/`, `.shamt/scripts/`, `.shamt/epics/`. Five additive waves get to the future state:

```
┌──────────────────────────────────────────────────────────────────┐
│ WAVE 1 — Content authoring (low risk, high leverage)             │
│   Add: .shamt/skills/, .shamt/agents/, .shamt/commands/          │
│   No host wiring yet; child projects ignore the new directories  │
│   Validated by Claude doc Experiment A                           │
└──────────────────────────────────────────────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│ WAVE 2 — Host shim wiring                                        │
│   Add: .shamt/scripts/regen/, .shamt/host/claude/                │
│   Init script extended: detects Claude Code, writes              │
│         .claude/settings.json starter + regenerates shims        │
│   Single-host (Claude Code) operational                          │
└──────────────────────────────────────────────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│ WAVE 3 — Hooks bundle + minimal MCP                              │
│   Add: .shamt/hooks/, .shamt/mcp/ (next_number + validation_round)│
│   Validated by Claude doc Experiment B                           │
│   GUIDE_ANCHOR / Resume Instructions begin to be retired         │
└──────────────────────────────────────────────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│ WAVE 4 — Codex host parity                                       │
│   Add: .shamt/host/codex/, .shamt/host/codex/profiles/,          │
│        requirements.toml.template                                │
│   Init script learns --host=codex and --host=claude,codex        │
│   Validated by Codex doc Experiment A                            │
└──────────────────────────────────────────────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│ WAVE 5 — Cloud-native + observability + SDK                      │
│   Add: .shamt/observability/, .shamt/sdk/                        │
│   Codex Cloud setup for S6 builder; OTel collector preset;       │
│   shamt-validate-pr.py CI gate                                   │
│   Validated by Codex doc Experiment B                            │
└──────────────────────────────────────────────────────────────────┘
```

Each wave is self-contained: child projects on prior waves keep working. A child project that imported during wave 1 has skills content under `.shamt/skills/` but no `.claude/skills/` shims; nothing breaks, the new content is just unused until they re-init.

The two experiments named in the Claude doc and the two named in the Codex doc serve as the gating criteria between waves. If an experiment fails, the corresponding wave is delayed until the issue is understood.

---

## 9. Quick reference — concept → file → host

For someone implementing or reading this:

| Concept | Master canonical | Claude Code shim | Codex shim |
|---|---|---|---|
| Rules file | `.shamt/scripts/initialization/RULES_FILE.template.md` | `CLAUDE.md` (repo root) | `AGENTS.md` (repo root) |
| Skill | `.shamt/skills/<name>/SKILL.md` | `.claude/skills/<name>/SKILL.md` | `.codex/skills/` *(when stable)* or `~/.codex/prompts/<name>.md` *(interim)* |
| Sub-agent persona | `.shamt/agents/<name>.yaml` | `.claude/agents/<name>.md` | `.codex/agents/<name>.toml` |
| Slash command | `.shamt/commands/<name>.md` | `.claude/commands/<name>.md` | `~/.codex/prompts/<name>.md` *(or skills surface when stable)* |
| Hook script | `.shamt/hooks/<name>.sh` | registered in `.claude/settings.json` | registered in `.codex/config.toml` `[hooks]` |
| MCP server | `.shamt/mcp/` (source) | registered in `.claude/settings.json` `mcpServers` | registered in `.codex/config.toml` `[mcp_servers.shamt]` |
| Codex profile | `.shamt/host/codex/profiles/<name>.fragment.toml` | N/A | imported into `.codex/config.toml` |
| Admin policy | `.shamt/host/codex/requirements.toml.template` | N/A | `requirements.toml` (repo root) |
| OTel config | `.shamt/observability/otel-collector.yaml` | (custom MCP/hook integration) | `[otel]` block in `.codex/config.toml` |
| SDK CI script | `.shamt/sdk/shamt-validate-pr.py` | invokable from anywhere | invokable from anywhere |

---

## 10. The Picture in One Sentence

Shamt's master repo becomes a host-agnostic content layer (skills, agents, commands, hooks, MCP server, SDK scripts, observability presets) plus a thin per-host wiring layer that knows how to translate the canonical content into whatever the chosen AI host (Claude Code, Codex, or both) expects to find — while master rules are enforced by the harness rather than asked of the agent.

The companion theorization docs (`CLAUDE_INTEGRATION_THEORIES.md`, `CODEX_INTEGRATION_THEORIES.md`) explain *why* each capability fits and *what* trade-offs come with each proposal. This doc shows how they cohere into a single architecture.

---

*End of overview.*
