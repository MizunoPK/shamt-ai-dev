# Shamt Codex Host — Layout and Conventions

This directory contains Codex-specific config sources for Shamt.

---

## Directory Structure

```
.shamt/host/codex/
├── config.starter.toml         — starter .codex/config.toml written by init
├── requirements.toml.template  — admin enforcement floor; copied to project root by init
├── .model_resolution.local.toml  (gitignored) — resolved FRONTIER_MODEL / DEFAULT_MODEL
└── profiles/
    ├── shamt-s1.fragment.toml  — per-stage profile fragments (s1–s5, s7–s10; S6 is covered by shamt-s6-builder)
    ├── ...
    ├── shamt-s6-builder.fragment.toml
    ├── shamt-validator.fragment.toml
    ├── shamt-builder.fragment.toml
    └── shamt-architect.fragment.toml
```

---

## Model Resolution

`${FRONTIER_MODEL}` and `${DEFAULT_MODEL}` in profile fragments are placeholder tokens.
`regen-codex-shims.sh` substitutes them from `.model_resolution.local.toml`:

```toml
FRONTIER_MODEL = "o3"
DEFAULT_MODEL = "o4-mini"
```

Init prompts the user for these values on first run and writes this file. The file is
gitignored — each developer has their own copy. Run `regen-codex-shims.sh` after
updating the file to regenerate `.codex/config.toml`.

---

## Skills Surface

Full-Shamt skills are deployed to `.agents/skills/<name>/SKILL.md` (project-local, GA since
December 2025). `regen-codex-shims.sh` writes each skill under a subdirectory named after its
full canonical name (e.g., `.agents/skills/shamt-validator/SKILL.md`). Codex loads skills from
this directory automatically at session start.

**Lite+full coexistence:** Shamt Lite skills (prefixed `shamt-lite-*`) and full-Shamt skills
share the same `.agents/skills/` directory. Each skill is isolated in its own subdirectory, so
there is no naming conflict when both frameworks are installed in the same project.

**Migration note (SHAMT-53):** Prior to December 2025, skills were deployed to the
per-user `~/.codex/prompts/shamt-<name>.md` (interim custom-prompts location). After running
`regen-codex-shims.sh` on SHAMT-53+, run `cleanup-codex-prompts-interim.sh` once to remove
the stale per-user files.

---

## Stage Transitions as Session Boundaries

Codex profiles are loaded at session start; switching a profile mid-session requires
relaunching Codex with `--profile shamt-s<N>`. Stage transitions in the Shamt workflow
are therefore natural session boundaries on Codex. The stage-transition-snapshot.sh
hook writes RESUME_SNAPSHOT.md; the new session picks it up via session-start-resume.sh.

---

## PreCompact Gap Mitigation

Codex has no PreCompact hook. The Shamt triplet:
1. `codex-compact-prompt.txt` is registered as the custom compact_prompt — instructs
   the summarizer to preserve epic tag, stage, phase, step, and consecutive_clean.
2. Before running `/compact`, advance to a stage boundary and let stage-transition-snapshot.sh
   write RESUME_SNAPSHOT.md.
3. On session resume, session-start-resume.sh reads RESUME_SNAPSHOT.md as startup context.

If Experiment A (SHAMT-42 §Validation) reveals state loss during compaction, escalate
to a Codex feature request for PreCompact support.

---

## Cloud MCP

Cloud-side MCP behavior is deferred to SHAMT-43. This config assumes Codex CLI.
Cloud usage may require additional auth and endpoint configuration not covered here.
Do not assume CLI-side MCP registration transfers to Cloud sessions.

---

## `agents.max_depth = 1`

Codex enforces a maximum sub-agent nesting depth of 1. Shamt validation loops flatten
to this constraint: validators run as depth-1 sub-agents of the root session. Do not
attempt to spawn sub-agents inside a sub-agent session under Codex.

---

## requirements.toml Override

The `requirements.toml` in the project root is master-synced (written by init, updated
on import). To locally override a constraint, create `requirements.local.toml` if Codex
supports layered requirement files. Otherwise, modify `requirements.toml` and document
the deviation — guide audit Dimension D-COVERAGE will flag undocumented deviations.
