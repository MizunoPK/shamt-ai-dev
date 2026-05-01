# Memory Tier Separation

**Purpose:** Define what belongs in harness memory vs. Shamt artifacts
**Audience:** All agents working in .shamt workflows
**Created:** 2026-04-30
**Version:** 1.0 (SHAMT-45)

---

## Decision Rule

> **Would another agent on another machine need this information to resume work?**
>
> - **YES** → Shamt artifact (`.shamt/epics/<active>/`)
> - **NO, this is a preference, project fact, or external reference** → Harness memory

When in doubt, put it in the artifact. Artifacts are version-controlled, portable, and
machine-readable. Memory is host-local and session-scoped.

---

## Harness Memory

**Claude Code:** `~/.claude/projects/<path>/memory/`  
**Codex:** `[memories]` Chronicle section

### What belongs here

| Category | Examples |
|----------|---------|
| **User preferences** | Terse responses, preferred review style, language conventions |
| **Project facts** | Child project version, primary language, validated approaches that didn't change |
| **External references** | Where bugs are tracked, Slack channel for design questions, Grafana dashboard URL |
| **Feedback** | Past corrections ("don't mock the DB"), confirmed non-obvious approaches |

### What does NOT belong here

- Current SHAMT-N being worked
- Active stage, phase, or step pointer
- Validation round counters or `consecutive_clean` values
- Spec contents, design doc proposals, acceptance criteria
- Anything another agent on another machine needs to continue work

---

## Shamt Artifacts

**Location:** `.shamt/epics/<active>/` — version-controlled, portable

### What belongs here

| Artifact | Content |
|----------|---------|
| `AGENT_STATUS.md` | Current stage, phase, step; active model/effort; last action; blockers |
| `VALIDATION_LOG.md` | All rounds, consecutive_clean counter, issues, verification evidence |
| `spec.md` | Feature requirements, acceptance criteria, user answers |
| `DISCOVERY.md` | Research findings, solution options, feature breakdown |
| `implementation_plan.md` | Mechanical plan steps, verified and validated |
| `RESUME_SNAPSHOT.md` | Context snapshot written by precompact and session-start hooks |
| `STALL_ALERT.md` | Stall notification with current model/effort and escalation recommendation |

### What does NOT belong here

- User preference notes ("user prefers concise commits")
- Project-fact caches that are also in git history
- External URL bookmarks
- Chat history or rationale for user decisions (belongs in spec checklist as source citations)

---

## AGENT_STATUS.md — Required Fields

The `validation-stall-detector.sh` hook (Proposal 2) and `shamt-statusline.sh` (Proposal 7)
both grep AGENT_STATUS.md for these fields. Always include them:

```markdown
**Model:** claude-opus-4-7
**Reasoning:** high
```

or equivalently:

```markdown
**Model:** claude-opus-4-7
**Effort:** high
```

Both `Reasoning:` and `Effort:` are accepted by the grep patterns. Omitting these fields
causes the stall detector to fall back to `"see AGENT_STATUS.md"` in STALL_ALERT.md and
the status line to omit the `effort:` field from its render.

---

## Common Violations

| Anti-pattern | Why it's wrong | Fix |
|--------------|---------------|-----|
| Storing `consecutive_clean` in memory | A new agent session won't see it; stale | Put in VALIDATION_LOG.md |
| Storing user preferences in AGENT_STATUS.md | Artifacts are per-epic, not per-user | Put in harness memory |
| Storing the active SHAMT-N in memory | Different machines won't sync | Put in AGENT_STATUS.md |
| Caching full spec content in memory | Memory size limits; artifacts are the source of truth | Read spec.md directly |
| Putting design rationale in RESUME_SNAPSHOT.md | Snapshot is for resumption context, not design history | Record in spec checklist or design doc Change History |

---

## Cross-Links

- `AGENT_STATUS.md` template: `.shamt/scripts/initialization/templates/AGENT_STATUS.template.md`
- Stall detector: `.shamt/hooks/validation-stall-detector.sh` (reads `Model:` / `Reasoning:` fields)
- Status line: `.shamt/scripts/statusline/shamt-statusline.sh` (reads `Stage:` / `Reasoning:` fields)
- Validation loop skill: `.shamt/skills/shamt-validation-loop/SKILL.md`
