<!-- Managed by Shamt — do not edit. Run regen-claude-shims.sh to regenerate. -->

# /shamt-start-epic

**Purpose:** Begin a new Shamt epic workflow — set up the epic folder structure, initialize tracking files, and enter S1 (Discovery).

**Invokes:** The S1-S11 epic workflow, starting with S1.P3 Discovery

---

## Usage

```
/shamt-start-epic {epic_request}
```

## Arguments

- `{epic_request}` (required) — the user's epic request (can be a title, a description, or a path to an existing epic request file). Examples:
  - `"Add OAuth2 login with Google and GitHub"`
  - `EPIC_TRACKER.md line 5` — reference an existing request
  - `epics/requests/oauth-login.md` — path to an existing request file

## What Happens

1. Creates the epic folder: `.shamt/epics/{EPIC-TAG}/`
2. Initializes `EPIC_README.md` with the epic request
3. Initializes `AGENT_STATUS.md` for progress tracking
4. Reads `EPIC_TRACKER.md` to assign the next available epic tag
5. Marks the epic as `S1 In Progress` in `EPIC_TRACKER.md`
6. Loads the `shamt-discovery` skill and begins S1.P3 Discovery
7. Reads ARCHITECTURE.md and CODING_STANDARDS.md
8. Begins the question brainstorm across 6+ categories
9. Asks ONE question at a time, waiting for user answers

## Expected Output

- Epic folder structure initialized
- EPIC_TRACKER.md updated
- Discovery underway — agent asks first question

## Notes

- Do not batch questions — the ONE-question-at-a-time rule is mandatory
- If an epic request already has a folder (e.g., from a partial previous session), this command will detect that and resume from the current stage rather than re-initializing
- For master dev work, use the master dev workflow (`design_docs/active/`) instead of this command
