# Shamt — AI Dev Framework

Shamt is a portable, AI-agent-driven development workflow framework. It provides:

- A structured **epic-driven workflow** (S1–S10) for planning, executing, and reviewing software features with an AI agent
- A **standalone code review workflow** for reviewing any branch or PR with structured, validated, copy-paste-ready comments
- A **sync system** for sharing guide improvements between projects and back to master
- An **initialization system** for onboarding any project in minutes

**Parallel work (S2 and S5):** When an epic has 2+ features, spec creation (S2) and implementation planning (S5) can be parallelized across multiple agent sessions. See `.shamt/guides/parallel_work/README.md`.

When you import Shamt into a project, you get your own version of Shamt — an AI agent persona configured for your codebase.

---

## What's in This Repo

```text
shamt-ai-dev/
├── README.md                   (this file)
├── CLAUDE.md                   (rules file for developing the master Shamt repo itself)
├── design_docs/
│   └── unimplemented/          (design docs + guide update proposal docs from child projects)
└── .shamt/
    ├── guides/                 (the full workflow guide system)
    ├── scripts/
    │   ├── initialization/     (init scripts + template files)
    │   ├── export/             (export improvements to master)
    │   └── import/             (import updates from master)
    └── epics/                  (master Shamt's own epic work)
```

---

## How to Initialize a New Project

### 1. Clone this repo

```bash
git clone https://github.com/[your-username]/shamt-ai-dev.git
```

### 2. Run the init script from inside your project

**Linux / Mac (Bash):**
```bash
bash /path/to/shamt-ai-dev/.shamt/scripts/initialization/init.sh
```

**Windows (PowerShell):**
```powershell
& "C:\path\to\shamt-ai-dev\.shamt\scripts\initialization\init.ps1"
```

The script will:
- Ask you a few questions (AI service, epic tag, project name, etc.)
- Create the `.shamt/` folder structure inside your project
- Copy and configure the guides and templates
- Write a handoff file (`.shamt/project-specific-configs/init_config.md`) for your AI agent

### 3. Start your AI agent and complete initialization

Open your project in your AI coding assistant and say:

> "Read `.shamt/project-specific-configs/init_config.md` and complete the Shamt initialization."

The agent will analyze your codebase and write `ARCHITECTURE.md`, `CODING_STANDARDS.md`, and customize the guides for your project.

---

## Keeping Your Guides Up to Date

Shamt uses import and export scripts to sync guide improvements between projects. For a full overview of how the sync system works, see `.shamt/guides/sync/README.md`.

### Getting updates from master

Run the import script from inside your project:

```bash
bash .shamt/scripts/import/import.sh
# or on Windows:
# & ".shamt\scripts\import\import.ps1"
```

The script compares your guides and scripts against master, applies any changes, and generates a diff for your agent to review. See `.shamt/guides/sync/import_workflow.md` for the full post-import validation process.

### Contributing improvements back

If you've made improvements to your guides that others could benefit from:

1. Document your changes in `.shamt/CHANGES.md` (your agent does this during S10 and audit work)
2. Run the export script: `bash .shamt/scripts/export/export.sh`
3. Open a PR to this repo with the exported changes

The master maintainer reviews the PR for generality and merges it. Other projects receive the improvement on their next import. See `.shamt/guides/sync/export_workflow.md` for details.

---

## License

*(Licensing decision deferred — see planning documentation)*
