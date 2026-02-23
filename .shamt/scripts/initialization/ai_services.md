# Shamt AI Service Registry

This file lists known AI coding assistant services and the rules file conventions they use.

During initialization, the init script reads this file to determine how to name and place the rules file template (`RULES_FILE.template.md`) for the user's chosen AI service.

---

## Claude Code (Anthropic)

- **Rules file name:** `CLAUDE.md`
- **Rules file location:** Project root
- **Notes:** Claude Code reads `CLAUDE.md` at the project root automatically. The file is included in every agent session as system context.

---

## GitHub Copilot

- **Rules file name:** `copilot-instructions.md`
- **Rules file location:** `.github/copilot-instructions.md`
- **Notes:** Copilot reads custom instructions from `.github/copilot-instructions.md`. Create the `.github/` directory if it doesn't exist.

---

## Cursor

- **Rules file name:** `.cursorrules`
- **Rules file location:** Project root
- **Notes:** Cursor reads `.cursorrules` from the project root. The file uses the same markdown format.

---

## Windsurf (Codeium)

- **Rules file name:** `.windsurfrules`
- **Rules file location:** Project root
- **Notes:** Windsurf reads `.windsurfrules` from the project root.

---

## Amazon Q Developer

- **Rules file name:** TBD
- **Rules file location:** TBD
- **Notes:** Amazon Q Developer rules file convention not yet confirmed. If you use Amazon Q and discover the correct setup, please contribute a changelog entry.

---

## Adding a New Service

If your AI service is not listed above:

1. Research the service's documentation for how it reads custom rules/instructions
2. During init, select "Other" and provide the filename and location
3. The agent will add the service to this file
4. When prompted, consider writing a changelog entry to contribute the discovery back to the master Shamt repo

**Changelog template:** `.shamt/guides/changelog_application/` → write entry in `.shamt/changelogs/outbound/`
