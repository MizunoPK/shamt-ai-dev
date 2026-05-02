# Shamt AI Service Registry

This file lists known AI coding assistant services and the rules file conventions they use.

During initialization, the init script reads this file to determine how to name and place the rules file template (`RULES_FILE.template.md`) for the user's chosen AI service.

## Wiring Tiers

| Service | Wiring Tier | Description |
|---------|-------------|-------------|
| Claude Code | **full-wiring** | Skills, agents, commands, and settings.json deployed automatically via `init.sh` and `regen-claude-shims.sh` |
| Codex | **full-wiring** | Skills, agents, commands, profiles, hooks, and config.toml deployed automatically via `init.sh` and `regen-codex-shims.sh` (SHAMT-42) |
| All others | **rules-file-only** | Only the rules file is written; no host-specific equivalents |

---

## Claude Code (Anthropic)

- **Rules file name:** `CLAUDE.md`
- **Rules file location:** Project root
- **Notes:** Claude Code reads `CLAUDE.md` at the project root automatically. The file is included in every agent session as system context.

---

## Codex (OpenAI)

- **Rules file name:** `AGENTS.md`
- **Rules file location:** Project root
- **Notes:** Codex reads `AGENTS.md` at the project root automatically. Full-wiring: `regen-codex-shims.sh` deploys skills to `~/.codex/prompts/` (interim), agents to `.codex/agents/`, profiles and hooks to `.codex/config.toml`. Run `init.sh --host=codex` to set up. Use `--host=claude,codex` for dual-host (both `CLAUDE.md` and `AGENTS.md` generated). Model names are resolved from `.shamt/host/codex/.model_resolution.local.toml` (gitignored).

---

## GitHub Copilot

- **Rules file name:** `copilot-instructions.md`
- **Rules file location:** `.github/copilot-instructions.md`
- **Notes:** Copilot reads custom instructions from `.github/copilot-instructions.md`. Create the `.github/` directory if it doesn't exist.

---

## Cursor

Cursor supports two rules file formats:

### Legacy Format (still supported)
- **Rules file name:** `.cursorrules`
- **Rules file location:** Project root
- **Notes:** Legacy format, still widely used and fully supported. Simple markdown file at project root.

### New Format (recommended as of 2026)
- **Rules file name:** `index.mdc`
- **Rules file location:** `.cursor/` directory
- **Notes:** New format introduced in 2026. The `.mdc` file with Rule Type "Always" is the recommended approach. More context-aware and integrated with Cursor's newer features.

---

## Windsurf (Codeium)

- **Rules file name:** `.windsurfrules`
- **Rules file location:** Project root
- **Notes:** Windsurf reads `.windsurfrules` from the project root.

---

## Amazon Q Developer

- **Rules file name:** TBD
- **Rules file location:** TBD
- **Notes:** Amazon Q Developer rules file convention not yet confirmed. If you use Amazon Q and discover the correct setup, please submit a PR to the master Shamt repo with the information.

---

## Azure DevOps MCP Server (Companion Integration — SHAMT-46)

The Azure DevOps MCP Server is not an AI service — it is a **companion MCP integration** that gives the AI agent typed access to ADO PR operations during interactive sessions. It is registered alongside the Shamt MCP server when `--pr-provider=ado` is set.

- **Package:** `@azure-devops/mcp` (npm, official Microsoft package)
- **Usage:** `npx @azure-devops/mcp <org-name> -d core repositories` (stdio transport)
- **Authentication:** Microsoft Entra ID (browser OAuth on first use) or PAT
- **When registered:** `init.sh --pr-provider=ado` → stored in `.shamt/config/ado_org.txt` → `regen-*-shims.sh` writes to `.claude/settings.json` or `.codex/config.toml`
- **Domain filter:** `-d core repositories` loads only PR tools (prevents tool overload from 70+ ADO tools)
- **Full setup:** `.shamt/guides/reference/azure_devops_integration.md`

---

## Adding a New Service

If your AI service is not listed above:

1. Research the service's documentation for how it reads custom rules/instructions
2. During init, select "Other" and provide the filename and location
3. The agent will add the service to this file
4. Consider submitting a PR to the master Shamt repo to contribute the discovery back

**To contribute back:** Run `bash .shamt/scripts/export/export.sh` and open a PR to the master repo. See `.shamt/guides/sync/export_workflow.md` for details.
