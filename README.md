# Shamt — AI Dev Framework

Shamt is a portable, AI-agent-driven development workflow framework. It provides:

- A structured **epic-driven workflow** (S1–S10) for planning, executing, and reviewing software features with an AI agent
- A **changelog system** for syncing guide improvements between projects
- An **initialization system** for onboarding any project in minutes

When you import Shamt into a project, you get your own version of Shamt — an AI agent persona configured for your codebase.

---

## What's in This Repo

```
shamt-ai-dev/
├── README.md                   (this file)
├── CLAUDE.md                   (rules file for developing the master Shamt repo itself)
└── .shamt/
    ├── guides/                 (the full workflow guide system)
    ├── initialization/         (init scripts + template files)
    ├── epics/                  (master Shamt's own epic work)
    ├── changelogs/             (changelogs received from child projects)
    └── outbound_changelogs/    (changelogs published for child projects to consume)
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
bash /path/to/shamt-ai-dev/.shamt/initialization/init.sh
```

**Windows (PowerShell):**
```powershell
& "C:\path\to\shamt-ai-dev\.shamt\initialization\init.ps1"
```

The script will:
- Ask you a few questions (AI service, epic tag, project name, etc.)
- Create the `.shamt/` folder structure inside your project
- Copy and configure the guides and templates
- Write a handoff file (`.shamt/init_config.md`) for your AI agent

### 3. Start your AI agent and complete initialization

Open your project in your AI coding assistant and say:

> "Read `.shamt/init_config.md` and complete the Shamt initialization."

The agent will analyze your codebase and write `ARCHITECTURE.md`, `CODING_STANDARDS.md`, and customize the guides for your project.

---

## Keeping Your Guides Up to Date

Shamt uses a **changelog system** to share guide improvements between projects.

### Getting updates from master

1. Check `.shamt/outbound_changelogs/CHANGELOG_INDEX.md` in this repo for new versions
2. Download any versions not already in your project's `.shamt/changelogs/applied_external_changes/`
3. Place downloaded files in your project's `.shamt/changelogs/unapplied_external_changes/`
4. Tell your agent: "Apply the changelogs in `.shamt/changelogs/unapplied_external_changes/`"

### Contributing improvements back

If you've made improvements to your guides that others could benefit from:

1. Write a changelog entry in your project's `.shamt/changelogs/outbound/` (your agent can help)
2. Submit the file to this repo by opening an issue or PR with the changelog file attached
3. The master Shamt agent will review, apply relevant improvements, and publish a new outbound changelog

---

## Versioning

Shamt versions correspond to outbound changelog numbers. A project at version `v0005` has applied changelogs v0001 through v0005. See `.shamt/outbound_changelogs/CHANGELOG_INDEX.md` for the full version history.

---

## License

*(Licensing decision deferred — see planning documentation)*
