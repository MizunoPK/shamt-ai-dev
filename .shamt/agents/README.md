# Sub-Agent Personas — Format Specification

Sub-agent personas are neutral YAML definitions of recurring agent roles used in Shamt workflows. They live in `.shamt/agents/<name>.yaml`. Regen scripts (SHAMT-40 for Claude Code, SHAMT-42 for Codex) translate them to host-specific formats at deployment time.

## Directory Structure

```
.shamt/agents/
├── README.md                          (this file)
├── shamt-validator.yaml
├── shamt-builder.yaml
├── shamt-architect.yaml
├── shamt-guide-auditor.yaml
├── shamt-spec-aligner.yaml
├── shamt-code-reviewer.yaml
└── shamt-discovery-researcher.yaml
```

## Master Applicability

| Persona | Master-Applicable | Notes |
|---------|------------------|-------|
| `shamt-validator` | ✅ yes | Used in validation loops on master |
| `shamt-builder` | ✅ yes | Used in architect-builder executions on master |
| `shamt-architect` | ✅ yes | Used for complex planning tasks on master |
| `shamt-guide-auditor` | ✅ yes | Used in guide audit rounds on master |
| `shamt-code-reviewer` | ✅ yes | Used in code reviews on master |
| `shamt-spec-aligner` | ❌ child-only | S8 spec alignment is a child-project workflow |
| `shamt-discovery-researcher` | ❌ child-only | S1 discovery is a child-project workflow |

Regen scripts on master projects wire only the master-applicable personas. Child regen scripts wire all personas. This is enforced in SHAMT-40 (Claude Code) and SHAMT-42 (Codex) regen scripts.

## Persona YAML Schema

```yaml
name: shamt-validator
description: Independent confirmation of validation rounds
model_tier: cheap        # cheap | balanced | reasoning
reasoning_effort: low    # minimal | low | medium | high | xhigh
sandbox: read-only       # read-only | workspace-write
tools_allowed:
  - Read
  - Grep
  - Glob
prompt_template: |
  You are {name}.
  {description}
  
  Your task: {task_description}
  
  Artifact to validate: {artifact_path}
  ...
```

### Schema Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | yes | Kebab-case persona identifier (matches filename without `.yaml`) |
| `description` | string | yes | One-sentence role description |
| `model_tier` | enum | yes | Host-neutral tier: `cheap`, `balanced`, or `reasoning` |
| `reasoning_effort` | enum | yes | `minimal`, `low`, `medium`, `high`, or `xhigh` |
| `sandbox` | enum | yes | `read-only` (cannot write files) or `workspace-write` (can write files in workspace) |
| `tools_allowed` | list | yes | Tool names the persona may use; enforced by host regen scripts |
| `prompt_template` | multiline string | yes | Persona prompt with `{placeholder}` substitution syntax |

### Placeholder Convention

Prompt templates use `{name}` curly-brace syntax for arguments. Regen scripts translate to host-specific syntax if needed (e.g., `$ARGUMENTS` for Codex custom-prompts). Standard placeholders:

| Placeholder | Meaning |
|-------------|---------|
| `{artifact_path}` | Absolute path to the artifact being processed |
| `{dimension_count}` | Number of dimensions to check |
| `{task_description}` | Caller-provided task description |
| `{name}` | Persona name (for self-reference in prompt) |
| `{description}` | Persona description |

## Model Tier → Host Model Mapping

The `model_tier` field maps to actual host models. This mapping is the single source of truth — update here and re-run regen scripts.

| Tier | Claude Code (Anthropic) | Codex (OpenAI) |
|------|------------------------|----------------|
| `cheap` | `claude-haiku-4-5` | cheapest available Codex model |
| `balanced` | `claude-sonnet-4-6` | default Codex model |
| `reasoning` | `claude-opus-4-7` | frontier Codex model |

**Update cadence:** When model lineups change, update this table and re-run `regen-claude-shims.sh` / `regen-codex-shims.sh` in all active child projects.

## Named Profile → Persona Mapping (SHAMT-45)

The four named profiles from `reference/model_selection.md` map to specific personas and Codex profiles:

| Profile | Intended Use | Claude Code Persona | Codex Profile |
|---------|-------------|---------------------|---------------|
| `validate-cheap` | Sub-agent confirmations, mechanical checks | `shamt-validator` (cheap tier) | `shamt-validator.fragment.toml` (cheap, effort=low) |
| `validate-careful` | Primary validation rounds 3+, stall recovery first step | `shamt-guide-auditor` or inline Opus | frontier model, effort=high |
| `diagnose` | Error diagnosis, stall root-cause | inline Opus, fresh session | frontier model, effort=xhigh, new session |
| `plan` | Implementation plan authoring | `shamt-architect` (reasoning tier) | `shamt-architect.fragment.toml` (frontier, effort=high) |

Profiles are advisory — they describe recommended (model, cache, effort) tuples, not hard constraints. Override per-task when the workflow guide specifies differently.

## Host Translation

Regen scripts translate each `.yaml` persona to host-specific formats:

**Claude Code** → `.claude/agents/<name>.md` (markdown with frontmatter):
```markdown
---
name: shamt-validator
description: Independent confirmation of validation rounds
model: claude-haiku-4-5
tools:
  - Read
  - Grep
  - Glob
---
You are shamt-validator.
...
```

**Codex** → `.codex/agents/<name>.toml` (TOML):
```toml
[agent]
name = "shamt-validator"
description = "Independent confirmation of validation rounds"
model = "cheapest-codex"

[tools]
allowed = ["Read", "Grep", "Glob"]

[prompt]
template = """
You are shamt-validator.
...
"""
```

## Schema Extensibility

The YAML schema is not JSON-Schema-strict — additive fields (e.g., `tags`, `version`, `notes`) do not break existing tooling. Regen scripts ignore unknown fields. Document new fields here when adding them.

## Adding New Personas

1. Create `.shamt/agents/<name>.yaml` using the schema above
2. Determine master vs child-only applicability and update the Master Applicability table
3. Update this README's directory listing
4. The regen scripts pick up new files automatically on the next regen run
