# Codex Capability Integration Theories for Shamt

**Status:** Exploratory / theorization (not a SHAMT-N design doc)
**Date:** 2026-04-27
**Purpose:** Map Shamt's existing workflow seams onto OpenAI Codex's capabilities (CLI, Cloud, IDE, GitHub `@codex`, AGENTS.md, subagents, hooks, MCP, sandbox modes, `requirements.toml`, OpenTelemetry, etc.) and theorize integrations that would let Shamt run on Codex — or run on both Codex and Claude Code from a shared core. This is a brainstorm, not a commitment to build.

**How to read this doc:**
- **§1** — Framing: what Shamt currently assumes about its Claude-Code host, and what does/doesn't transfer to Codex.
- **§2** — Capability walkthrough (§2.1–§2.18): one section per Codex capability, each naming concrete Shamt seams and contrasting against the equivalent Claude Code primitive.
- **§3** — Cross-cutting workflows (§3.1–§3.6): composites that compose multiple Codex capabilities for a single Shamt outcome.
- **§4** — Speculative / longer-horizon ideas.
- **§5** — Prioritization table with effort and value scoring. *Skim here first if you want the punchline.*
- **§6** — Risks and anti-patterns specific to Codex.
- **§7** — Two candidate first experiments.

A companion doc, `CLAUDE_INTEGRATION_THEORIES.md`, covers the same exercise for Claude Code. Reading the two side-by-side surfaces which capabilities each host has uniquely — useful if Shamt wants to remain host-portable.

**Source of Codex capability claims:** all factual statements about Codex (config keys, hook events, sandbox modes, `agents.max_depth=1` and `max_threads=6` defaults, `requirements.toml` semantics, `codex-universal` container model, `@codex` GitHub mention behavior, `[memories]` Chronicle semantics, OpenTelemetry export, Codex-as-MCP-server, etc.) are drawn from a survey of OpenAI's published Codex documentation (developers.openai.com/codex/*, openai.com/index/introducing-codex, the openai/codex GitHub repo) as of late April 2026. Codex evolves fast; values like default `max_depth` or the precise hook event list should be re-verified against the current changelog before implementation.

---

## 1. Framing: What Shamt Assumes vs. What Codex Actually Provides

Shamt was designed inside Claude Code's surface area. Several of its load-bearing assumptions are Claude-Code-shaped, not framework-universal. Mapping to Codex requires being honest about which of those assumptions hold:

| Shamt assumption | Holds on Codex? | Notes & mitigation pointer |
|---|---|---|
| Hierarchical instruction file (`CLAUDE.md`) discoverable from anywhere in the repo | **Yes**, via `AGENTS.md` (root → leaf, with `AGENTS.override.md` priority and `project_doc_fallback_filenames`). Direct analog. | Outside a Git repo only `$CODEX_HOME/AGENTS.md` applies — slightly stricter than Claude Code. **See §2.1.** |
| Sub-agent spawning with model selection (Haiku/Sonnet/Opus) | **Yes**, via `[agents]` and per-agent TOML in `~/.codex/agents/` (and `.codex/agents/`). Each agent can override model and reasoning effort. | But `agents.max_depth=1` by default — Shamt's nested validation→confirmation→sub-confirmation patterns will hit the ceiling and need flattening or explicit raises. **See §2.3.** |
| Hooks for PreToolUse / PostToolUse / SessionStart / Stop / UserPromptSubmit | **Yes**, plus PermissionRequest. | **PreCompact is not in the documented Codex hook set.** Shamt's PreCompact + SessionStart pair (§2.3 of the Claude doc) does not directly map. SessionStart with matcher `resume` is the closest fallback. **See §2.4 (PreCompact gap workarounds).** |
| MCP server tools | **Yes**, first-class in CLI (STDIO + Streamable HTTP, `enabled_tools`/`disabled_tools`, OAuth). | Cloud-side MCP support is under-specified in public docs — assume more constrained. **See §2.5.** |
| Skills (auto-loaded markdown behavior packs) | **Mixed** — Codex's "skills" surface is referenced as the replacement for the now-deprecated `~/.codex/prompts/` custom-prompts feature, but the canonical skills doc was not confirmed in research. Treat as in-flight. | Shamt's `.claude/skills/` strategy needs a Codex landing site that may still be moving. **Mitigation: author host-portable skill content in `.shamt/skills/` and ship Codex shims via `~/.codex/prompts/` until the new skills surface stabilizes — see §2.2.** |
| Worktrees for parallel work | **Implicit** — Codex Cloud achieves parallel work via *containers*, which are stronger isolation than worktrees. CLI worktrees still work but are largely obviated by Cloud. | This is one of Codex's biggest wins; **see §2.8.** |
| Local file artifacts as authoritative state | **Yes** — same model. AGENTS.md and any artifact in the repo is canonical. | (No mitigation needed.) |
| Slash commands | **Yes** (`/<name>` for built-ins, `/prompts:<name>` for user-defined custom prompts). Custom prompts are deprecated; skills are the future. | **See §2.2 for the skills/prompts migration path.** |
| Plan mode | **Partial** — `/plan` slash command exists; semantics differ from Claude Code's read-only plan mode. Worth verifying behavior empirically. | **Mitigation: pin `sandbox_mode="read-only"` on the relevant profile (§2.6 / §2.11) to enforce planning-phase read-only-ness regardless of whether `/plan` matches Claude Code semantics.** |
| Auto-memory across sessions | **Different** — Codex has opt-in `[memories]` ("Chronicle") with consolidation model and aging. Not the same lightweight per-fact write model as Claude Code. | **Mitigation: keep Shamt's load-bearing facts in artifacts (AGENTS.md, validation logs); use `[memories]` only for user-preference-tier facts. See §2.14.** |
| Push notifications | **Indirect** — no native push primitive. Stop hook + external script (e.g., shell command that calls `notify-send`, posts to Slack, etc.) is the workaround. | **Mitigation: §2.4 Stop hook + handler script that fires the notification. Plumbing is straightforward; no native primitive needed.** |

**The biggest structural differences for Shamt:**

1. **Cloud is a first-class deployment**, not an afterthought. `chatgpt.com/codex` and `@codex` on GitHub turn long-running parallel tasks into a managed service. Several Shamt patterns that Claude doc theorized as "speculative / Agent SDK deployment" are *already shipping primitives* on Codex.
2. **`requirements.toml` is unique to Codex** — an admin-enforced policy file that pins sandbox modes, allowed MCP servers, deny-read globs, managed hook directories. This is the missing piece for Shamt's master-vs-child guardrail story; nothing in Claude Code corresponds.
3. **OpenTelemetry export is built-in** — request duration, tool invocations, token usage flow out of the box. The metrics & observability cross-cutting workflow (§3.5 in the Claude doc) is half-built before Shamt does anything.
4. **`agents.max_depth=1` ceiling** is a real constraint. Shamt's nested validation patterns must flatten — the harness *enforces* what Claude Code only suggests in prose.
5. **No PreCompact hook** — Shamt's GUIDE_ANCHOR / Resume Instructions ritual cannot rely on automatic snapshotting. SessionStart on `resume` is the fallback, but it fires on session boot, not on the harness's compaction event.
6. **Sandbox modes are first-class** (`read-only` / `workspace-write` / `danger-full-access`). Per-subagent override means Shamt can pin a `shamt-validator` subagent to `read-only` declaratively, which Claude Code can only enforce via tool allowlists.

The rest of this doc walks the capabilities and points at the seams.

---

## 2. Capability-by-Capability Mapping

### 2.1 AGENTS.md (the CLAUDE.md analog)

**What it is:** Hierarchical Markdown instruction file walked from Git root down to the working directory; `AGENTS.override.md` takes priority over `AGENTS.md`; configurable fallback names (`TEAM_GUIDE.md`, `.agents.md`, etc.) via `project_doc_fallback_filenames`. Concatenation is root-to-leaf with later (closer) files overriding. Default size cap 32 KiB, raisable via `project_doc_max_bytes`.

**Why this fits Shamt:** Almost a direct analog of CLAUDE.md. Shamt's master-rules-file pattern (`scripts/initialization/RULES_FILE.template.md`) maps onto AGENTS.md without rework. The **additive layering** is actually richer than Claude Code's — a child project can ship a root `AGENTS.md` that's the master ruleset, plus subdirectory `AGENTS.md` files that override per-feature.

**Concrete proposal:** A Shamt-on-Codex deploy ships an `AGENTS.md` template (from `RULES_FILE.template.md`) at the repo root, with a small companion `AGENTS.override.md` for project-specific deviations. Master ↔ child sync targets `AGENTS.md`; `AGENTS.override.md` is the project-private supplement that survives import without conflict.

**Risk:** 32 KiB default cap is real — Shamt's full rules file is dense; if it spills past 32 KiB, raise via `project_doc_max_bytes` or split into hierarchical AGENTS.md files (probably the better design anyway: `AGENTS.md` at root for master rules, per-subdir AGENTS.md for stage-specific instructions).

---

### 2.2 Skills / Custom Prompts

**State of play:** Codex has a `~/.codex/prompts/` custom-prompts directory invoked as `/prompts:<name>` with `$1..$9` / `$ARGUMENTS` / `$FOO` substitution. **This is now marked deprecated** in favor of a "skills" surface that the OpenAI docs reference but did not fully document at the time of this survey. Treat skills as the strategic target; treat custom prompts as bridge.

**Why this matters for Shamt:** The Claude doc theorized 8 high-value skills (`shamt-validation-loop`, `shamt-architect-builder`, `shamt-spec-protocol`, etc.) as the single highest-leverage proposal. On Codex, the same skill content needs to land in *two* places to be host-portable:

- A neutral content tree (e.g., `.shamt/skills/<name>/`) that both Claude Code and Codex can ingest.
- Host-specific shims: `.claude/skills/<name>/SKILL.md` that imports from `.shamt/skills/<name>/`, and the equivalent Codex skills directory once its format is confirmed.

Until Codex skills are stable, a `~/.codex/prompts/shamt-*.md` set delivers most of the value: each prompt embeds the protocol body and uses `$ARGUMENTS` to receive the artifact path. Invocation is `/prompts:shamt-validation-loop spec.md` — explicit rather than auto-triggered, but still enormously cleaner than re-reading reference guides each session.

**Concrete deliverable:** Author skill content as the canonical source under `.shamt/skills/<name>/SKILL.md` (host-neutral). Generate Codex prompts and Claude skills from this source via small build step. Master ↔ child sync targets `.shamt/skills/`; hosts read from their respective shim directories.

**Risk:** Auto-trigger semantics differ. Claude Code skills auto-load on context match; Codex custom prompts are explicit `/prompts:` invocations. The "context-aware behavior" Shamt benefits from in Claude is replaced by explicit invocation in Codex — slightly more friction, but also more predictable. If/when Codex skills land with auto-loading, this gap closes.

---

### 2.3 Subagents (`[agents]` config + per-agent TOML)

**What it is:** Codex supports native subagent definitions under `~/.codex/agents/<name>.toml` and `.codex/agents/<name>.toml`, each with `name`, `description`, `developer_instructions`, optional `model`, `model_reasoning_effort`, `sandbox_mode`, `mcp_servers`, `skills.config`. Spawned only on explicit request. Configured via `[agents]` block: `max_threads=6` (parallel), `max_depth=1` (nesting). Children inherit parent live config.

**Why this fits Shamt:** Direct, stronger analog of Claude Code's `.claude/agents/`. Codex's per-agent config is *richer* — a subagent's sandbox mode and MCP server allowlist are declared in TOML, not pleaded for in a prompt. Shamt's existing sub-agent personas map cleanly:

| Persona | TOML highlights |
|---|---|
| `shamt-validator` | `sandbox_mode="read-only"`, no MCP, `model_reasoning_effort="low"`, role-only `developer_instructions` |
| `shamt-builder` | `sandbox_mode="workspace-write"`, `model_reasoning_effort="minimal"`, error-reporting protocol in instructions |
| `shamt-architect` | `model="gpt-5-codex"` or strongest available, `model_reasoning_effort="high"`, `sandbox_mode="read-only"` (planning is read-only), MCP allowed for guide tooling |
| `shamt-guide-auditor` | `sandbox_mode="read-only"`, multi-dimension instructions, `model_reasoning_effort="high"` |
| `shamt-code-reviewer` | `sandbox_mode="read-only"`, `model_reasoning_effort="medium"`, MCP for git tooling |
| `shamt-spec-aligner` | `sandbox_mode="read-only"`, cross-feature alignment instructions |

**Concrete proposal:** Author subagent TOMLs alongside the skill content (`.shamt/agents/<name>.toml`) and sync them out to `.codex/agents/` per host. The TOMLs are short (≤30 lines each) and far more declarative than hand-written agent prompts.

**Risk — `max_depth=1`:** This is the meaningful constraint. Shamt's full validation loop today is structurally:
```
primary agent → validation round → spawns sub-agent confirmer (× 2)
```
That's depth 2 from the root. On Codex with `max_depth=1`, the primary agent can spawn confirmers, but those confirmers cannot themselves spawn anything. **In practice that's fine for the validation loop** — confirmers don't fan out further. But for nested workflows (e.g., a `shamt-guide-auditor` that spawns per-dimension specialists), the ceiling bites. Two responses: raise `max_depth` explicitly in `config.toml` for those workflows, or flatten to a single layer of fan-out.

**Pleasant surprise — `max_threads=6`:** Up to 6 parallel subagents per parent by default. Validation rounds with multiple independent confirmers, S2 multi-feature parallel work, S5/S9 multi-feature audits all run in parallel without coordination prose. This is a meaningful win over Claude Code's single-Task-per-spawn pattern (where parallelism comes from multiple Task calls in one assistant message).

---

### 2.4 Hooks (5 events + PermissionRequest)

**What's there:** SessionStart (matchers `startup|resume|clear`), UserPromptSubmit, PreToolUse, PostToolUse, **PermissionRequest** (unique to Codex), Stop. Configured via `~/.codex/hooks.json`, inline `[hooks]` in `config.toml`, project-local equivalents (project hooks require trusted config). Handler type `command` only. Matcher is regex on tool name (or session-source for SessionStart). JSON over stdin/stdout protocol. Multi-source merging is additive. Behind feature flag `features.codex_hooks=true`.

**What's NOT there:** **PreCompact.** No event fires before the harness compacts the conversation.

**Why this matters for Shamt:** Most of the Claude doc's hook proposals port cleanly:

| Shamt hook | Codex event | Notes |
|---|---|---|
| `--no-verify` blocker | PreToolUse on shell tool, regex `git commit.*--no-verify` | Direct port. |
| Commit-message format enforcement | PreToolUse on shell, regex `git commit` | Direct port. |
| Pre-export audit gate | PreToolUse on shell or UserPromptSubmit regex | Direct port. |
| Validation log auto-stamp | PostToolUse on file-edit tools matching `*VALIDATION_LOG.md` | Direct port. |
| Architect-builder enforcement | PreToolUse on agent-spawn tool — but matcher is regex on tool name only, so subagent persona check needs a workaround (script reads stdin to check the agent name) | Same outcome, slightly more script in the hook handler. |
| User-testing zero-bug gate | PreToolUse on shell `git push.*` during S9 | Direct port. |
| Auto-load epic context | SessionStart with matcher `resume` | Partial port — fires on session resume but not mid-session compaction. |
| **Resume-context snapshot (PreCompact)** | **No equivalent.** | **The biggest gap.** Workarounds: hook on Stop to snapshot; or rely on `/compact` being user-invoked and write a Stop handler that always dumps state; or use `[memories]` Chronicle to consolidate context state automatically. None matches PreCompact's automatic-pre-compaction guarantee. |

**The PreCompact gap — workaround patterns:** Since Codex doesn't fire a hook before compaction, Shamt's GUIDE_ANCHOR / Resume Instructions story needs a different substrate on this host. Three composable mitigations:

1. **Custom `compact_prompt`** — Codex's `compact_prompt` config key overrides the inline summarization prompt that runs at `/compact` time. Shamt-on-Codex can ship a compaction prompt that *explicitly* instructs the summarizer to preserve current epic / stage / phase / step / blockers / open validation-loop counters in the summary output. Won't fire automatically, but when `/compact` runs, the right state survives.
2. **`/compact` discipline at stage transitions** — Treat each stage exit (S1→S2, S2→S3, etc.) as a moment to *manually* invoke `/compact`. A user-prompt slash command (`/shamt-stage-end`) can wrap "save Agent Status, run `/compact`, post-compact verify state preserved." Less automatic than PreCompact but more deterministic about *when* compaction happens.
3. **Artifact-as-substrate** — Lean harder on `.shamt/epics/<active>/AGENT_STATUS.md` and the validation log as the durable record. Compaction loss becomes acceptable because the artifacts re-hydrate context on demand. SessionStart hook (matcher `resume`) reads them at session boot. Chronicle (`[memories]`, §2.14) supplements with consolidated facts but isn't load-bearing.

These three together approximate PreCompact's behavior, with the caveat that Mitigation 1 fires only on user-initiated compaction and Mitigation 2 requires user discipline. The artifact substrate (Mitigation 3) is the load-bearing one — same as on Claude Code, just without the automatic snapshot belt.

**Codex-only opportunity — PermissionRequest hook:** A hook that fires when the harness is about to ask the user for approval. Programmable: return `{"decision": "approve"|"deny", "reason": "..."}` to short-circuit. For Shamt, this enables auto-approving low-risk operations within a known stage (e.g., during S6 builder execution, auto-approve any Read/Edit on files inside the active feature folder; bubble everything else to the user). Reduces approval fatigue without abandoning approval.

**Codex-only opportunity — `requirements.toml`-managed hooks:** Admin-pinned hooks via `[hooks] managed_dir`. Shamt master could ship a hook bundle that *cannot be disabled* by child projects (without modifying `requirements.toml`). Useful for non-negotiable rules (commit-format, no-verify, audit-before-export).

**Risk:** Codex hook matcher being regex-on-tool-name only is less expressive than Claude Code's matcher language. Tool names are stable identifiers, so it's usually enough, but agent-persona-based matching (e.g., "block if subagent_type != shamt-builder") needs the handler script to parse stdin.

---

### 2.5 MCP Servers

**What's there:** First-class in CLI. Both STDIO (`command`, `args`, `env`, `cwd`) and Streamable HTTP (`url`, `bearer_token_env_var`, `http_headers`) under `[mcp_servers.<id>]` with `enabled_tools`/`disabled_tools`, timeouts, OAuth fields. Manageable via `codex mcp add` / `/mcp`. Cloud MCP support exists but is more constrained.

**Why this fits Shamt:** Same proposal as the Claude doc, mostly. A `shamt-mcp` server providing `next_number()`, `validation_round()`, `audit_run()`, `epic_status()`, `metrics.append()` plugs into both hosts identically — MCP is the cleanest cross-host integration point Shamt has. The same server binary serves both.

**Concrete proposal:** If Shamt builds an MCP server (Claude doc §5 #11), it should be a single Rust/Python/Node binary that registers in both `.claude/settings.json` and `.codex/config.toml` with parallel configs. Cross-host portability is essentially free at the MCP layer.

**Risk:** Codex Cloud's MCP support is less documented; STDIO MCP servers in a sandboxed container are a different beast than on a developer's machine. For features Shamt wants in Cloud (e.g., `next_number()` reservation), the MCP server probably needs to be HTTP-served from somewhere reachable, not STDIO. Plan for HTTP-first if Cloud is a target.

---

### 2.6 Codex CLI Config + Profiles

**What's there:** TOML config at `~/.codex/config.toml` and `.codex/config.toml` (project-local; loads only when project is trusted). Profiles via `[profiles.<name>]` with arbitrary key overrides. Notable keys: `model`, `model_reasoning_effort`, `sandbox_mode`, `approval_policy`, `[features]` toggles, `web_search`, `[mcp_servers.*]`, `[agents]`, `[memories]`, `[permissions.*]`, `[shell_environment_policy]`, `[hooks]`, `[rules]`, `[otel]`, `[tui]`, `model_instructions_file`, `compact_prompt`, `developer_instructions`, `tool_output_token_limit`.

**Why this fits Shamt:** Profiles are Codex's killer feature for stage-specific configuration. Each Shamt stage can declare its own profile:

```toml
# NOTE: Replace ${FRONTIER_MODEL} and ${DEFAULT_MODEL} with the current model
# names from OpenAI's Codex changelog at deploy time (e.g., the latest gpt-5.x
# release at the time of writing was reported in the survey, but the lineup
# moves; do not hardcode a name that will age out).

[profiles.shamt-s5]
model = "${FRONTIER_MODEL}"          # strongest available — planning needs reasoning headroom
model_reasoning_effort = "high"
sandbox_mode = "read-only"           # planning is read-only
approval_policy = "on-request"
[profiles.shamt-s5.mcp_servers]
shamt = { command = "shamt-mcp", args = ["serve"] }

[profiles.shamt-s6]
model = "${DEFAULT_MODEL}"           # cheaper model fine for mechanical execution
model_reasoning_effort = "minimal"   # builder is mechanical
sandbox_mode = "workspace-write"
approval_policy = "on-request"

[profiles.shamt-validator]
model = "${FRONTIER_MODEL}"
model_reasoning_effort = "low"       # confirmation is shallow, not deep reasoning
sandbox_mode = "read-only"
approval_policy = "never"
```

`${FRONTIER_MODEL}` and `${DEFAULT_MODEL}` are deliberate placeholders — Shamt's profile fragments should be templated and resolved at init time (or via env var substitution if Codex's TOML loader supports it; otherwise via a small `shamt init codex` script that reads the current model names from a config and writes the resolved profiles). Hardcoding a literal `gpt-5.X-codex` name would age out within a release cycle.

Switching stages becomes `codex --profile shamt-s5 …` (or a slash command that switches in-session if Codex supports profile re-application; otherwise relaunch).

**Headless / CI invocation — `codex exec`:** Codex CLI ships a non-interactive mode (`codex exec [...]`) that runs an agent against a prompt and exits. This is the primitive Shamt's CI integrations should target. A GitHub Action can run `codex exec --profile shamt-guide-audit "audit the changes in this PR" --model <frontier>` and post results. The `@codex` GitHub workflow (§2.9) is one packaging of this; `codex exec` in arbitrary CI systems is the more general pattern. For Shamt: every long-running headless workflow (post-merge audit, scheduled stale-work scan, master-side review draft) maps to a `codex exec` invocation with the appropriate profile.

**Project trust:** `.codex/config.toml` only loads when the project is trusted (`[projects.<path>]` block). A Shamt init script should add the project to the user's trust list automatically (or instruct the user to). Otherwise the per-project profiles silently don't apply, which is a hard-to-diagnose failure.

**Hypothesis branching — `/fork`:** Codex's `/fork` clones the current conversation to a new thread, letting the agent explore an alternate hypothesis without losing the original. Two natural Shamt fits: (1) **S2.P1.I2 checklist resolution** when a question has 2+ plausible answers — fork once per branch, run each to a partial spec, compare; (2) **S5 implementation planning** when alternative architectures are on the table — fork to draft each plan in parallel, then merge insights. Today the framework forces sequential exploration via prose; `/fork` makes the branching explicit and durable.

**Concrete proposal:** Author a `codex/config.fragment.toml` per stage in `.shamt/codex/profiles/`, with a small import pattern in the project's main `config.toml`. Master ↔ child sync owns the fragments; the child's own `config.toml` is the single import line. Init script handles project-trust registration.

**Risk:** Profile overrides are at config-load time. A long-running session can't trivially switch profiles mid-stream. Workarounds: relaunch with `--profile`, or design profiles for the *agent persona* (which can be re-spawned) rather than the *stage* (which transitions in one session).

---

### 2.7 `requirements.toml` (Admin-Enforced Policy)

**What's there:** Admin-level `requirements.toml` can pin or restrict any config (allowed sandbox modes, MCP allowlist, hooks managed dir, deny-read globs, …). Not user-overridable. This is unique to Codex; **Claude Code has no equivalent**.

**Why this fits Shamt:** This is the missing piece for the master-vs-child guardrail story. Today, "the child project must follow the rules in CLAUDE.md" is enforced by *the agent reading and respecting them*. With `requirements.toml`, master can ship a non-negotiable policy bundle:

- **Sandbox floor:** Force `sandbox_mode in ["read-only", "workspace-write"]` — never `danger-full-access` in a Shamt-managed project.
- **MCP allowlist:** Only `shamt`, `git`, and a small named whitelist; child projects can't accidentally enable arbitrary servers in a Shamt-managed flow.
- **Managed hooks dir:** Master ships hooks via `[hooks] managed_dir = ".shamt/hooks/"`, ensuring `--no-verify` blocker, audit-before-export, etc. fire deterministically.
- **Deny-read globs:** Block agents from reading `.env`, secrets, etc. — universal across all stages.
- **Approval policy floor:** Force `approval_policy != "never"` for stages that touch git push or external services.

**Concrete proposal:** A `shamt-requirements.toml` template lives in `.shamt/scripts/initialization/`. Init scripts copy it to the project's `requirements.toml` location with a "do not edit" header. Master ↔ child sync includes this file; project deviations require explicit override that triggers an audit signal.

**Risk:** `requirements.toml` is admin-enforced. If Shamt master ships rules that turn out to be wrong, child projects can't easily work around them — they have to override the requirements file (which Shamt audits will flag). This is a feature for compliance use cases and a friction point for fast iteration. Ship requirements bundles conservatively.

**Strategic note:** This is the single largest divergence between hosts. Shamt-on-Codex can be *meaningfully more rigorous* than Shamt-on-Claude-Code purely because of `requirements.toml`. If guardrail enforcement is a goal, Codex is the stronger host.

---

### 2.8 Codex Cloud (Containers + Parallel Tasks)

**What's there:** Each cloud task spawns an isolated container based on the open-source `codex-universal` image (preinstalled languages, tools). Repo checked out at branch/commit; setup scripts run with full internet; agent phase runs with configurable network policy (`disabled|limited|full`). Container caches persist 12h; maintenance scripts refresh deps on resume. Caches invalidate on setup-script / env-var / secret changes. Secrets are setup-only and removed before the agent phase. Parallel tasks supported from chat UI and IDE extensions.

**Why this is huge for Shamt:** Worktree isolation (Claude doc §2.8) is the rough hack; **containers are the real thing**. Several Shamt patterns become straightforward:

- **S2 multi-feature parallel work** — each feature is a cloud task on its own container. Lock-file protocols and STATUS.md coordination patterns from `parallel_work/` mostly disappear because containers don't share filesystems.
- **S6 architect-builder** — the builder runs in a container with `sandbox_mode=workspace-write` and a tightly-scoped network policy. Architect monitors via the chat UI / IDE. If the builder fails, the container is discarded; the architect re-spawns from a clean baseline.
- **S7/S9 QC fan-out** — each validation dimension runs as a parallel cloud task, with results gathered by a coordinator agent in chat. 6+ parallel agents on independent containers.
- **S10 PR creation** — already happens cloud-side. Codex commits, cites evidence, opens the PR.

**Concrete proposal:** A `codex-environment.json` (or whatever Cloud's environment manifest is named — verify) per Shamt project specifies setup scripts to install Shamt's MCP server, pre-cache the guide tree, and seed `AGENTS.md`. The cloud task starts on a known baseline. A `shamt-cloud-dispatcher` skill or slash command takes a stage descriptor (e.g., `S2.feature-3`) and fires off the appropriate cloud task with the right profile and environment.

**Risk:** Cloud is fundamentally a different operational model than CLI. State doesn't persist locally; all artifact state must be committed to the repo (which is mostly fine — Shamt is artifact-driven). But local files the developer is editing aren't visible to cloud tasks unless committed. The "agent and human edit the same file simultaneously" pattern from Claude Code CLI doesn't hold; flows must be PR-shaped.

**Risk — secrets handling:** Secrets are removed before the agent phase. Shamt's MCP server probably needs auth. Plan for token refresh from setup phase, or design the MCP server to accept credentials it fetches from the environment after the secret is gone (e.g., a service account token cached during setup). Adjacent primitive: `shell_environment_policy` controls which env vars survive into the agent's shell tool — useful for selectively allowing service-account variables that were materialized during setup while denying anything that might leak into untrusted MCP tool calls.

---

### 2.9 GitHub `@codex` Integration

**What's there:** Tag `@codex` on issues or PRs to spawn cloud tasks; Codex commits inside its container, cites evidence, opens PRs. Code-review mode runs as a separate Codex agent analyzing diffs against a base branch (also exposed via `/review` in CLI).

**Why this fits Shamt:** This is the master review pipeline (Claude doc §3.4) *already shipping*. Shamt master can subscribe to `@codex` on child PR open: cloud Codex agent reads the diff, applies the separation rule (via a `shamt-master-reviewer` skill), posts a draft review comment. The maintainer can iterate via further `@codex` mentions in the PR thread.

**Concrete proposal:**
1. Author `shamt-master-reviewer` skill (read-only, separation-rule-focused) and a corresponding subagent TOML.
2. On master repo, configure `@codex` to use a profile that loads this skill/agent on PR-comment context.
3. Maintainer's role becomes "review the draft, accept or amend" rather than "read the diff, run audit, write review."

**Risk:** GitHub permissions and branch-protection interactions need care — `@codex` opening a PR vs. amending one vs. commenting only is policy-driven. Shamt should specify the policy in `requirements.toml` (§2.7) so it's enforced rather than aspirational.

---

### 2.10 IDE Extensions

**What's there:** Official VS Code extension (Cursor, Windsurf compatible). Three modes: Chat, Agent, Agent (Full Access). Can launch cloud tasks from the editor and apply diffs locally. JetBrains support since January 2026 (IntelliJ, PyCharm, WebStorm, Rider). Extension config layers share with CLI config.

**Why this fits Shamt:** Same workflow concepts as the CLI. Most Shamt logic (skills, agents, hooks, profiles) lives in config files and applies uniformly. IDE-specific opportunity: surface stage transitions and gate state in the IDE's status bar via the same mechanism §2.18 of the Claude doc proposes — but here the surface is OpenAI's IDE plugin, not a custom status line script.

**Risk:** IDE extension version drift — features may land in CLI before the IDE plugin or vice versa. Shamt should depend on CLI primitives where possible, with IDE as a UX layer.

---

### 2.11 Sandbox Modes

**What's there:** Three first-class modes — `read-only`, `workspace-write`, `danger-full-access`. Configurable globally, per-profile, and per-subagent. Granular `[permissions.<name>]` blocks for filesystem and network policy.

**Why this fits Shamt:** This is a structural improvement over Claude Code's tool-allowlist approach. Shamt agent personas pin sandbox mode declaratively:

- `shamt-validator` → `read-only`. The harness physically prevents writes, even if the prompt has a bug.
- `shamt-builder` → `workspace-write`. Cannot escape the working tree.
- `shamt-discovery-researcher` → `read-only` + network allowed (for WebFetch).
- Master dev work → `workspace-write` (default).

**Concrete proposal:** Pin sandbox mode in each subagent TOML (§2.3) and add a hook that rejects any attempt to spawn a subagent with `sandbox_mode != "read-only"` for a defined read-only persona list. Defense in depth.

**Risk:** None really — this is straight upside vs. Claude Code's softer enforcement.

---

### 2.12 Reasoning Controls

**What's there:** `model_reasoning_effort` accepts `minimal | low | medium | high | xhigh` (xhigh model-dependent). `model_reasoning_summary` toggles summary verbosity. `Alt+,` / `Alt+.` shortcut adjusts level interactively. Per-agent override supported.

**Why this fits Shamt:** Direct analog of the Claude doc's "extended-thinking-aware model selection" (§2.15 / §5 #21). Better than Claude Code in one respect: 5 levels (`minimal`–`xhigh`) instead of binary on/off, so Shamt can tune granularly. The named-profile pattern from the Claude doc (`validate-cheap`, `validate-careful`, `diagnose`, `plan`) maps to Codex profiles directly.

**Concrete proposal:** Add `model_reasoning_effort` to each subagent TOML. Trigger rule from the Claude doc applies: bump to `high` when `consecutive_clean` is stuck; bump to `xhigh` for root-cause diagnosis on builder errors.

**Risk:** Token cost scales sharply with reasoning effort. Default-low for confirmers, default-medium for primary work, escalate intentionally — never default everything to `high`.

---

### 2.13 Web Search

**What's there:** First-party `web_search` tool with modes `disabled|cached|live` (default `cached`). Configurable via `tools.web_search` for `context_size`, `allowed_domains`, location.

**Why this fits Shamt:** S1.P3 Discovery and S2.P1.I1 research benefit (Claude doc §2.16). On Codex, this is a config flag rather than a tool the agent has to remember to use. Set `web_search="cached"` in the Discovery profile and `disabled` in Builder/Validator profiles to prevent network drift during execution.

**Risk:** None significant. `cached` mode is the right default for reproducibility.

---

### 2.14 Memory (Chronicle / `[memories]`)

**What's there:** Optional `[memories]` system behind `features.memories=true` — generates, consolidates, and ages out memories from rollouts. Tunable: `generate_memories`, `consolidation_model`, `extract_model`, `max_rollout_age_days`, `max_unused_days`, `disable_on_external_context`.

**Why this differs from Claude Code:** Claude Code's auto-memory is "agent decides to write a fact, fact persists." Codex's Chronicle is "rollout transcripts get post-hoc consolidated by a model into memory artifacts that age out." Different shape — more algorithmic, less explicit.

**Why this fits Shamt:** For Shamt's needs (user preferences, project facts, validated approaches), explicit AGENTS.md is probably the better long-lived store, with Chronicle as a supplementary lazy-learning layer. Don't push Shamt's load-bearing facts (active epic, validation counters) through Chronicle — those belong in artifacts.

**Concrete proposal:** Enable `[memories]` for user-preference-tier facts ("user prefers terse responses"); leave epic state in `.shamt/epics/<active>/` artifacts. Configure aggressive `max_unused_days` to prevent stale-fact accumulation.

**Risk:** Chronicle's consolidation model decides what's worth keeping. If it's a smaller model than the primary, it can mis-summarize. Audit periodically.

---

### 2.15 OpenTelemetry Observability (Built-in)

**What's there:** `[otel]` config block exports traces and metrics: request duration, tool invocations, token usage, opt-in `log_user_prompt`. Standard OTLP export to any OTel collector.

**Why this is huge for Shamt:** The Claude doc §3.5 metrics & observability cross-cutting workflow — proposed as a multi-week effort requiring hooks + MCP + routines + slash commands — is essentially **half-built before Shamt does anything** on Codex. The framework's projected token-savings claims (model_selection 30–50%, architect-builder 60–70%, sub-agent confirmation 70–80%) become measurable trivially. Spin up a local OTel collector (Grafana, Honeycomb, anything OTLP), point Codex at it, get per-stage / per-subagent / per-tool telemetry for free.

**Concrete proposal:** Ship a `shamt-otel-collector-config.yaml` that lights up dashboards aligned to Shamt's stage/phase/subagent labels (which the agent emits naturally as part of its trace context). Validation-loop round counts, builder execution duration, audit pass-rate trends — all queryable, all without writing custom hooks.

**Risk:** OTel needs a collector somewhere. For a single-developer setup, that's a local Docker container. For team / org use, a hosted backend. Plan accordingly.

---

### 2.16 Codex-as-MCP-Server + Agents SDK (Agent Mesh, Library Embedding)

**What's there:** Codex can run as an MCP server over stdio, consumable by other agents. The OpenAI Agents SDK additionally lets Python/TypeScript code invoke Codex sessions programmatically, with structured handoff semantics. Together these turn Codex from "a CLI/cloud product" into "a callable agent runtime."

**Why this fits Shamt — three deployment shapes unlock:**

1. **Agent-as-MCP-tool.** A Shamt orchestrator (running on the developer's machine or in CI) consumes a Codex agent as an MCP tool. The orchestrator decides "this stage runs locally, this stage runs in cloud" and dispatches accordingly. Same Shamt skill content, different execution host per call. Replaces the Claude doc's speculative "managed-agent deployment" with a shipping primitive — but adds the integration cost of authoring the orchestrator.
2. **Shamt-as-a-library via the Agents SDK.** The Agents SDK lets a host application (a CI script, a custom IDE plugin, an internal dev tool) embed Codex sessions with arbitrary tool surfaces. Shamt's framework logic — "run validation loop on artifact X with N confirmers" — can be wrapped as a Python/TypeScript function that internally drives Codex sessions. Means Shamt becomes consumable from non-Codex-CLI surfaces: Jupyter, web apps, internal tooling. The artifact substrate stays the same; the host is what changes.
3. **CI-native validation loops.** A GitHub Action runs an Agents-SDK-powered Python script that drives a Codex session through a Shamt validation loop, posts results as a PR comment, and exits. No `@codex` mention needed; the workflow is fully scripted. Useful when the validation should fire automatically (every PR opens) rather than on user invocation.

**Concrete proposals:**

- **`shamt-meta-orchestrator`** (speculative) — A small Python program using the Agents SDK that maps stages to execution hosts and dispatches. Reads `.shamt/epics/<active>/STAGE` to decide; exposes itself as an MCP server so a developer's Claude Code or Codex CLI session can drive it. Genuinely useful only if cross-host orchestration becomes a goal; otherwise overengineered.
- **`shamt-validate-pr.py`** (Agents SDK) — A self-contained CI script: clone repo, identify changed artifacts, drive Codex through `shamt-validation-loop` skill, post results. Ships in `.shamt/scripts/ci/` and is invoked from a GitHub Action workflow. This is the highest-immediate-value SDK integration — turns Shamt validation from interactive discipline into automatic gate.

**Risk:** Complexity. Agent meshes are easy to design and hard to debug. The SDK adds a programming layer (Python/TypeScript code) that didn't exist in pure-Shamt-on-CLI. Maintaining a meta-orchestrator means owning a small program; ship only when the friction of *not* having it is felt twice. The CI script (`shamt-validate-pr.py`) is much lower commitment and probably the right starting point for SDK work.

---

### 2.17 Multi-Modal

**What's there:** Image input via `-i` flag or paste-into-composer. Image generation/editing in CLI and IDE. PDF input is **not explicitly documented** in the surveyed sources.

**Why this fits Shamt:** S1.P3 Discovery and S2.P1.I1 spec phases occasionally consume design diagrams or UI mocks. Codex's image input is straightforward; PDF support is uncertain and probably needs a workaround (convert to images at ingestion).

**Concrete proposal:** Add a Discovery / Spec skill instruction: "If the user provides an image (-i flag), describe the diagram and integrate observations into DISCOVERY.md / spec.md." Same content as Claude doc §2.16, mechanism slightly different.

**Risk:** None significant.

---

### 2.18 Approval / PermissionRequest Hooks

**What's there:** `approval_policy` modes (`untrusted | on-request | never` plus granular). Mid-session adjustment via `/permissions`. **PermissionRequest hook** can programmatically decide on the harness's approval prompts.

**Why this fits Shamt:** Shamt has many user-blocking gates. Most should remain user-driven (S5 plan approval, S9 zero-bug confirmation). But many *intermediate* approvals (read this file, edit this file inside the active epic folder) are noise. PermissionRequest hook can auto-approve scoped operations and bubble only meaningful decisions:

```python
# pseudo-handler for PermissionRequest
if tool_name == "edit" and target_path.startswith(f".shamt/epics/{active_epic}/"):
    return {"decision": "approve", "reason": "in-scope edit"}
if tool_name == "shell" and command.startswith("git commit"):
    return {"decision": "ask_user", "reason": "commit needs human review"}
return {"decision": "ask_user"}  # default: defer to user
```

**Concrete proposal:** Ship a `shamt-permission-router.sh` (or .py) handler in `.shamt/hooks/` that scopes auto-approval by active epic, active stage, and known-safe tool patterns. Reduces approval fatigue without abandoning approval as a checkpoint.

**Risk:** A misconfigured PermissionRequest handler that auto-approves too broadly is worse than no auto-approval — it silently rubber-stamps risky actions. Test the deny path: feed it an out-of-scope edit, verify it bubbles. Same risk pattern as the Claude doc's hook-deny-path discussion.

---

## 3. Cross-Cutting Workflows (combining multiple capabilities)

### 3.1 The "Validation Loop as a Cloud-Task Fan-Out"

Today (in Claude-Code-shaped Shamt): primary validation round + 2 sub-agent confirmations as Task spawns in one conversation.

Theorized on Codex: each validation round runs locally; each sub-agent confirmation is a *parallel cloud task* on its own container, with `sandbox_mode=read-only` and a `shamt-validator` profile. Coordinator (local) reads cloud task results from the chat / API and writes to the validation log. `agents.max_threads=6` permits up to 6 concurrent confirmers if a higher confidence bar is wanted.

**Which capabilities combine:** Subagents (§2.3) + Cloud (§2.8) + sandbox modes (§2.11) + profiles (§2.6) + skills (§2.2) + OTel (§2.15 — measure it).

**Why this beats the Claude variant:** True parallelism on isolated containers; each confirmer has its own clean context; results are durable in the cloud-task UI; OTel metrics let you see whether 2 confirmers is the right number empirically.

### 3.2 The "Architect–Builder Pipeline" (Cloud-Native)

Today: S5 architect writes plan, S6 architect spawns Haiku builder, monitors with prose updates.

Theorized on Codex: S5 architect runs locally with `shamt-s5` profile (`read-only` sandbox, `reasoning_effort=high`). Validated plan gets committed to the repo. S6 fires a cloud task with `shamt-s6-builder` profile (workspace-write sandbox, reasoning-effort minimal, no MCP except for the metrics emitter). Cloud task executes the plan in a clean container. On failure, the container is discarded; on success, it opens a PR. Architect locally (via IDE or chat) reviews the PR.

**Which capabilities combine:** Profiles + subagents + Cloud + sandbox modes + reasoning controls + GitHub PR integration + OTel.

**Why this beats the Claude variant:** Cloud disposability gives genuine rollback semantics (Claude doc §3.6 had to invent worktree-as-rollback-boundary). PR-shaped output integrates with code review naturally.

### 3.3 The "Stale-Work Janitor" (`@codex` on Schedule)

Today (Claude doc): a recurring routine scans `incoming/` and `active/`, posts digests, schedules cleanups.

Theorized on Codex: a GitHub Actions cron job opens an issue tagged `@codex` weekly with prompt "scan `design_docs/incoming/` and `design_docs/active/`, summarize stale items >30 days, file follow-up issues for each." Codex runs as a cloud task, posts results, closes the originating issue. No long-running scheduling host needed; GitHub Actions + `@codex` is the host.

**Which capabilities combine:** GitHub `@codex` (§2.9) + GitHub Actions + cloud tasks (§2.8) + AGENTS.md context.

**Why this beats the Claude variant:** No external infrastructure. The same pattern (scheduled mention) works for any "do this weekly" obligation Shamt has.

### 3.4 The "Master Review Pipeline" (Already Mostly Shipping)

Today: maintainer reads child PR diff, runs audit manually.

Theorized on Codex: master repo configures `@codex` mentions on incoming child PRs to fire `shamt-master-reviewer` skill + subagent. Cloud Codex agent applies separation rule, runs audit on the touched guide files, posts a draft review. Maintainer iterates via further `@codex` mentions.

**Which capabilities combine:** `@codex` (§2.9) + skills (§2.2) + subagents (§2.3) + AGENTS.md (§2.1 — master rules in `.shamt/master-AGENTS.md`).

**Why this beats the Claude variant:** This is a deployment-ready primitive on Codex; on Claude Code it was speculative (Claude doc §2.17 / §3.4 required Agent SDK theorization). On Codex you just configure it.

### 3.5 The "Metrics & Observability Loop" (Mostly Free)

Today (Claude doc §3.5): hooks → MCP → typed metric store → routine digest → slash command.

Theorized on Codex: enable `[otel]` block in config, point at any OTLP collector, ship a Shamt-aware Grafana dashboard preset. Stage / subagent / tool dimensions are tagged automatically. Optional: `shamt-mcp.metrics.append` for *Shamt-specific* metrics (e.g., validation round count, audit pass-rate) that don't fall out of stock OTel. Routine digest becomes a Grafana scheduled report or a `@codex`-triggered weekly summary.

**Which capabilities combine:** OTel (§2.15) + MCP (§2.5) for Shamt-specific events + cloud tasks for the digest.

**Why this beats the Claude variant:** Stock OTel covers ~70% of what the Claude doc §3.5 proposed building from scratch. The Shamt-specific MCP server is a thin layer on top, not the whole observability stack.

### 3.6 The "Rollback / Recovery Loop" (Container-Native)

Today (Claude doc §3.6): worktrees + stall detection + pre-push tripwire.

Theorized on Codex: container disposability is the rollback boundary by default — every failed cloud task is a clean slate. Stall detection fires when a cloud task exceeds a configurable wall-clock budget; PermissionRequest hook (§2.18) escalates to a higher reasoning effort or a different model on stall. Pre-push tripwire is a PreToolUse hook on `git push` that verifies the cloud task's exit conditions (tests passed, no unresolved errors).

**Which capabilities combine:** Cloud (§2.8) + PermissionRequest hook (§2.18) + reasoning escalation (§2.12) + PreToolUse hook (§2.4) + OTel (§2.15) for stall metrics.

**Why this beats the Claude variant:** Container disposability is *automatic*. The Claude doc had to invent worktrees-as-rollback-boundaries; Codex gives that for free.

---

## 4. Speculative / Longer-Horizon Ideas

- **Codex as the headless deployment, Claude Code as the interactive deployment.** Shamt-on-Codex via `@codex` + GitHub Actions handles all scheduled / triggered / async work. Shamt-on-Claude-Code handles interactive developer-driven work. Same artifact substrate; different host per use case. Cross-host portable skill content (§2.2) + MCP server (§2.5) make this dual-host model tractable.
- **`requirements.toml` as the master ↔ child contract.** Child projects' `requirements.toml` is shipped from master and version-locked. Drift signals via audit. Codex-only feature, but architecturally the cleanest expression of Shamt's master-vs-child rule yet.
- **`shamt-meta-orchestrator` (§2.16).** A local Codex agent that delegates to cloud Codex agents via Codex-as-MCP-server, choosing host per stage. Gives Shamt true tiered execution.
- **Codex skills auto-loading (when stable).** When the new skills surface lands and supports auto-trigger semantics analogous to Claude Code's, the explicit-`/prompts:`-invocation friction goes away. Watch for this; Shamt's skill-content authoring should be easy to retarget.
- **`@codex`-driven validation loops for design docs.** Validation log lives in repo; `@codex validate this design doc` fires cloud tasks per dimension; results posted as PR comments. Async, durable, reviewable.
- **OTel-driven prompt-caching analysis.** Use OTel cache-hit telemetry to recompute Shamt's model-selection guidance empirically — same project as Claude doc §5 #9, but with measurement built in.
- **Memory consolidation tuned for Shamt patterns.** Chronicle's `extract_model` and `consolidation_model` could be tuned to specifically extract validated approaches and team conventions, with stricter aging on epic-specific facts. Niche but real.

---

## 5. Prioritization (rough)

Effort scale: **XS** (<1 hour, just configuration), **S** (half day), **M** (1–3 days), **L** (week-plus). Value scale: **★** to **★★★★★**.

| # | Proposal | Effort | Value | Notes |
|---|---|---|---|---|
| 1 | **AGENTS.md from `RULES_FILE.template.md`** + `.shamt/codex/` config fragments | XS | ★★★★★ | Foundational — Shamt cannot run on Codex without it. |
| 2 | **Subagent TOMLs** (`shamt-validator`, `-builder`, `-architect`, `-guide-auditor`, `-spec-aligner`, `-code-reviewer`) with per-agent sandbox + reasoning effort | S | ★★★★★ | Direct port from Claude proposal but richer (sandbox + MCP allowlist baked in). |
| 3 | **Codex profiles per stage** (`shamt-s1`, `shamt-s2`, …, `shamt-s10`) | S | ★★★★ | Stage-specific model / sandbox / approval. Cleaner than Claude Code can express. |
| 4 | **Skills as host-portable content** in `.shamt/skills/`, with Codex `~/.codex/prompts/shamt-*.md` shims (interim) | S | ★★★★★ | The skills bundle is still the highest-leverage content asset. Author once, ship to both hosts. |
| 5 | **Hooks port** (`--no-verify`, commit-format, pre-export audit, validation-log auto-stamp, push gate) | S | ★★★★ | Direct ports work; the PermissionRequest hook is bonus value. |
| 6 | **`shamt-requirements.toml`** template | S | ★★★★ | Codex-only, but enforces master-vs-child contract harder than anything Claude Code can do. |
| 7 | **OTel config + Grafana dashboard preset** | S | ★★★★ | The metrics & observability cross-cutting workflow nearly free on Codex. |
| 8 | **PermissionRequest hook scoped to active epic** | S | ★★★ | Codex-only; reduces approval fatigue meaningfully. |
| 9 | **Cloud task setup for S6 builder** (`codex-environment.json` or equivalent + setup script) | M | ★★★★ | Container-native architect-builder pipeline (§3.2). Big leverage. |
| 10 | **`@codex` master review** on child PRs — `shamt-master-reviewer` skill + workflow | M | ★★★★ | The master review pipeline goes from speculative to shipping. |
| 11 | **`shamt-mcp` server** (host-portable: STDIO for CLI, HTTP for Cloud) | M | ★★★ | Same value as Claude doc; works on both hosts. |
| 12 | **Stage transitions as profile switches** (`/profile shamt-s5` etc.) | XS | ★★ | Documentation + small slash command, mostly. |
| 13 | **Web search mode locked per profile** (`cached` for Discovery, `disabled` elsewhere) | XS | ★★ | Reproducibility win. |
| 14 | **`@codex`-scheduled stale-work janitor** | S | ★★ | GitHub Actions cron + `@codex` mention. Replaces Claude doc's routine speculation. |
| 15 | **Memory (`[memories]`) for user preferences only** | XS | ★ | Lightweight; explicit AGENTS.md remains the load-bearing instruction surface. |
| 16 | **Multi-modal in Discovery skill** | XS | ★ | Image-input note in skill body. |
| 17 | **Reasoning escalation rule** (auto-bump `model_reasoning_effort` on stuck `consecutive_clean`) | S | ★★ | Mirrors Claude doc §2.15 / §5 #21. |
| 18 | **Codex IDE plugin status integration** (display active stage / blocker) | S | ★ | Cosmetic; low priority. |
| 19 | **Cloud-native validation loop fan-out** (§3.1) | M | ★★★ | Premium feature; deferred until #1–#9 are paying off. |
| 20 | **Container-native rollback / stall detection** (§3.6) | M | ★★★ | Pairs with #9; partly automatic. |
| 21 | **`shamt-meta-orchestrator` (Codex-as-MCP-server agent mesh)** | L | ★★ | Speculative; only justified if cross-host orchestration becomes a goal. |
| 22 | **Custom `compact_prompt` preserving Shamt state** | XS | ★★★ | Single config key; mitigates a meaningful chunk of the missing PreCompact behavior. |
| 23 | **`shamt-validate-pr.py` (Agents SDK CI script)** | M | ★★★ | Self-contained PR-validation gate. Smaller commitment than the meta-orchestrator and high practical value. |
| 24 | **`codex exec`-driven CI workflows** (audit, validation, master review) | S | ★★★ | Ships Shamt validation as a GitHub Action. Pairs with #6 / #10. |
| 25 | **`/fork`-based hypothesis branching** in S2.P1.I2 / S5 alternative-architectures | XS | ★★ | Mostly a skill-content addition; codifies a workflow that is currently sequential prose. |

*Note on the CI / headless cluster (#10, #14, #23, #24):* these are related but distinct packagings of the same underlying capability. **`@codex`** (#10, #14) is the GitHub-native mention pattern — user-friendly, but tied to GitHub. **`shamt-validate-pr.py`** (#23) wraps the Agents SDK in a Python script — embeddable in any CI, programmatically composable. **Raw `codex exec`** (#24) is the bare CLI invocation in arbitrary shell scripts — lowest commitment, no SDK overhead. Pick by use case: GitHub-only repos can stop at `@codex`; multi-CI-host or non-GitHub setups want SDK or raw `exec`.

The top cluster (#1–#7) is the high-leverage, low-effort core for Shamt-on-Codex. Compared to the Claude doc's top cluster: #1, #2, #4, #5, #11 are direct ports; #3 (profiles), #6 (`requirements.toml`), and #7 (OTel) are Codex-only wins that have no Claude-Code equivalent. Item #9 (cloud builder) is the highest-leverage Codex-specific architectural change.

---

## 6. Risks & Anti-Patterns to Avoid

- **Don't assume PreCompact behavior.** Codex has no PreCompact event. Shamt's GUIDE_ANCHOR / Resume Instructions ritual must rely on SessionStart-on-resume + explicit `/compact` discipline, or live as artifact-only state. Don't write a doc claiming PreCompact maps cleanly — it doesn't.
- **Don't fight `agents.max_depth=1`.** Flatten validation patterns to single-layer fan-out. If a workflow genuinely needs deeper nesting, raise depth explicitly in `config.toml` for that workflow only, with documentation explaining why. Default-raising depth invites runaway recursion.
- **Don't ship `requirements.toml` rules ahead of demonstrated need.** It's admin-enforced; child projects can't easily work around mistakes. Conservative bundles only. Each rule should have a known incident or audit finding behind it.
- **Don't mix CLI and Cloud state assumptions.** Cloud tasks see committed state only. Local CLI sees uncommitted edits. Workflows that span both must explicitly commit at handoff points. The "agent and human edit the same buffer" pattern doesn't translate.
- **Don't rely on undocumented Cloud MCP behavior.** Until Cloud-side MCP support is well-documented, target HTTP-served MCP servers and verify per use case. STDIO MCP servers in containers are not guaranteed.
- **Don't over-tune Chronicle (`[memories]`).** Explicit AGENTS.md is the deterministic, version-controlled source of truth. Memories are lazy supplementation. Keep load-bearing facts in artifacts.
- **Don't put secrets in setup-only env vars and expect agent-phase access.** Codex Cloud removes secrets before the agent phase by design. Plan token-refresh from setup, or use service accounts.
- **Don't let `@codex` workflows auto-merge.** Same lesson as Claude doc §3.2. The S7 review checkpoint exists; preserve it via branch protection or explicit reviewer requirement.
- **Don't double-implement what OTel already gives you.** Shamt's metrics MCP should add Shamt-*specific* events on top of stock OTel, not replicate request-duration / token-usage / tool-invocation telemetry that's already free.
- **Don't assume custom prompts will keep working.** They're deprecated. Author skill content host-portably (§2.2) so the migration to the new skills surface is mechanical when it lands.

---

## 7. What I'd Actually Try First

Two candidate experiments, mirrored against the Claude doc's pair:

**Experiment A (bring-up test):** Author the AGENTS.md template (#1), the six core subagent TOMLs (#2), and three stage profiles (#3 — pick `shamt-s2`, `shamt-s5`, `shamt-s6`). Run a real S2.P1.I3 spec validation with `shamt-validator` Haiku-equivalent confirmers on Codex CLI. Compare against the Claude-Code baseline: same artifact, same dimensions, measured tokens (via OTel), measured rounds-to-exit, qualitative "did the agent need less prose bookkeeping." *Validates the host-portability thesis.*

**Experiment B (Codex-native test):** Build the cloud-task pipeline for S6 builder (#9) plus `shamt-requirements.toml` (#6) plus OTel config (#7). Run a real S6 implementation as a cloud task, with `requirements.toml` enforcing sandbox floor and audit-before-export hook. Verify: container disposability gives clean rollback on simulated failure; OTel surfaces token / reasoning / duration breakdowns by stage and subagent; `requirements.toml` blocks an attempted `danger-full-access` escalation. *Validates the Codex-native thesis — the parts of the framework that look better on Codex than on Claude Code.*

**Sequencing and gate criteria:**
- Run **A first.** It's additive, low-risk, exercises the host-portability infrastructure (#1–#5).
- A's success gate: validation loop completes on Codex CLI in fewer or equal rounds than the Claude-Code baseline, OTel-measured tokens within ±15%, no agent-prose bookkeeping that wasn't already needed on Claude. If A clears the bar, ship the broader subagent + skill bundle (#1–#5) as the canonical Shamt-on-Codex starter pack.
- After A ships, run **B.** B's success gate: a real S6 cloud task completes with `requirements.toml`-enforced sandbox, container disposability cleanly recovers from a simulated failure, OTel dashboards show stage / subagent / tool breakdowns. If B clears the bar, the framework can begin advertising "Codex-native deployment" as a first-class option, and items #6, #7, #9, #10 become the next implementation wave.
- If A fails: most likely reason is profile switching mid-session being awkward; investigate before continuing. If B fails: most likely reason is Cloud-MCP friction or `requirements.toml` over-restricting; soften and retry. Either failure is informative — it tells us where Codex's surface area is more friction than help, and re-grounds the rest of the prioritization table.

**Optional Experiment A′ (SDK-flavored variant):** Once A passes, an immediate follow-on is to wrap the same validation loop as a `shamt-validate-pr.py` (#23) and run it as a GitHub Action against a real PR. Same Shamt logic, same skill content, but driven from the Agents SDK rather than interactively. Validates that the host-portability story extends from "Codex CLI" to "Codex via Python SDK in CI" without re-authoring the framework. Low marginal cost if A's infrastructure is in place; high marginal value because it demonstrates Shamt as a CI gate, not just a developer-side workflow.

---

## 8. Comparison: Shamt-on-Codex vs. Shamt-on-Claude-Code

A side-by-side for reference (companion doc: `CLAUDE_INTEGRATION_THEORIES.md`):

| Capability | Claude Code | Codex |
|---|---|---|
| Hierarchical instruction file | CLAUDE.md (auto-discovered any depth) | AGENTS.md (Git-root-anchored) — direct analog |
| Skills | First-class, auto-loading | "Skills" surface in flux; custom prompts deprecated; auto-load uncertain |
| Sub-agents | `.claude/agents/`, model + tools per agent | `.codex/agents/*.toml` — *richer* (sandbox, reasoning effort, MCP allowlist per agent) |
| Sub-agent depth | Effectively unbounded | `max_depth=1` default; raise explicitly |
| Sub-agent parallelism | Per Task call in one assistant message | `max_threads=6` per parent — *better default* |
| Hooks | PreToolUse / PostToolUse / UserPromptSubmit / SessionStart / Stop / SubagentStop / Notification / **PreCompact** | PreToolUse / PostToolUse / UserPromptSubmit / SessionStart / Stop / **PermissionRequest** — *no PreCompact, no SubagentStop, no Notification*; *adds PermissionRequest* |
| MCP | First-class | First-class (CLI); cloud constrained |
| Sandbox modes | Tool-allowlist-driven | `read-only` / `workspace-write` / `danger-full-access` — *first-class, better* |
| Admin policy file | None | **`requirements.toml` — unique to Codex** |
| Cloud / managed agent | Speculative (Agent SDK / managed-agent deployment) | **First-class — `@codex` on GitHub, chatgpt.com/codex** |
| Worktrees | `Agent isolation: "worktree"` | Containers (stronger isolation, automatic) |
| Plan mode | Explicit primitive | `/plan` slash command; semantics differ |
| Memory | Auto-memory file system | Chronicle (`[memories]`) — different shape |
| Push notifications | `PushNotification` tool | Indirect via Stop hook + external script |
| Observability | Build-it-yourself (Claude doc §3.5 proposal) | **OTel built-in — `[otel]` block** |
| Reasoning controls | Extended thinking (binary-ish) | `model_reasoning_effort: minimal/low/medium/high/xhigh` — *more granular* |
| Codex-as-tool | N/A | **Codex-as-MCP-server — agent mesh** |
| Slash commands | `.claude/commands/*.md` | `~/.codex/prompts/*.md` (deprecated) → skills |

**Net assessment:** Codex is a *more rigid* host than Claude Code (admin policy, sandbox modes, depth ceiling) and a *more cloud-native* host (containers, GitHub `@codex`, OTel). For Shamt's "framework with rules" identity, that rigidity is mostly upside — `requirements.toml` and per-agent sandbox modes turn convention into enforcement. For Shamt's interactive developer-collaboration pattern, Claude Code's softer surface and PreCompact hook are stronger. The honest answer is probably **dual-host**: Codex for headless / scheduled / CI-integrated work, Claude Code for interactive epic execution, with a shared core of artifacts + skills + MCP server.

---

*End of theorization.*
