# Stale-Work Janitor Composite

**What this is:** Scheduled cleanup and follow-up routines assembled from SDK cron
scripts, Claude Code cron jobs, and Stop hooks. Two categories of scheduled work are
documented here: recurring weekly scans and one-shot post-event triggers.

---

## Component Map

| Component | Where it lives | Role |
|-----------|---------------|------|
| `shamt-cron-janitor.py` | `.shamt/sdk/` | Recurring weekly scan script |
| GitHub Actions schedule | `.github/workflows/shamt-cron-janitor.yml` | Triggers weekly scan on Codex |
| Claude Code cron (CronCreate) | Built into Claude Code | Triggers recurring and one-shot routines |
| `shamt-validation-loop` skill | `.shamt/skills/` | Validates janitor output if proposals are promoted |
| `pre-push-tripwire.sh` hook | `.shamt/hooks/` | Final guard before stale-resolved changes ship |

**Primitive home guides:**
- SDK cron script: `.shamt/sdk/README.md`
- Cron job template: `.shamt/sdk/.github/workflows/shamt-cron-janitor.yml.template`

---

## Category 1: Recurring Weekly Scans

Run weekly on a schedule. Three scan targets:

### Incoming proposals triage (`design_docs/incoming/`)
- Find proposals older than 30 days with no PROMOTE or REJECT decision
- For each stale proposal: emit a GitHub issue labeled `shamt-janitor` asking for a
  decision (promote → design doc, implement directly, or reject)
- Do NOT auto-decide — only surface the signal

### Active design doc sweep (`design_docs/active/`)
- Find design docs with no git commit in the last N weeks (default: 4 weeks, configurable via `SHAMT_ACTIVE_MAX_WEEKS`)
- Check if the doc is marked "In Progress" or "Draft" — if so and it's stale, create
  a GitHub issue prompting the owner to update or archive it

### Child sync timestamp check
- Read `.shamt/config/last_import.txt` in each configured child project
- If no import in N weeks (default: 4 weeks), emit a reminder issue

**Running on Claude Code (CronCreate):**

```
CronCreate(
    name="shamt-weekly-janitor",
    schedule="0 9 * * 1",  # Monday 9am
    prompt="Run the Shamt weekly janitor scan: check design_docs/incoming/ for
            proposals >30d, design_docs/active/ for stale docs, and
            .shamt/config/last_import.txt for stale child syncs.
            Create GitHub issues for anything that needs attention."
)
```

**Running on Codex (GitHub Actions):** Copy
`.shamt/sdk/.github/workflows/shamt-cron-janitor.yml.template` to
`.github/workflows/shamt-cron-janitor.yml`. Requires `OPENAI_API_KEY` secret.

### Master-internal scan targets

Master repo activates additional scan targets:

- **`design_docs/incoming/` proposals >30 days:** Same as above — surface proposals
  that haven't been decided. On master, these are child project proposals awaiting
  review.
- **`design_docs/active/` stale docs:** Stale active docs on master are SHAMT-N design
  docs being worked on. Surface these so the current developer knows they may be
  abandoned or need a decision.
- **Child sync timestamps:** Master can optionally track child projects that have not
  imported master changes recently. This is advisory — child projects control their
  own import cadence.

---

## Category 2: One-Shot Post-Event Triggers

One-shot routines fire once at a scheduled offset after a specific event. They are set
up by the primary agent at the event trigger point.

### Post-S10 merge → +1 week: lessons-learned propagation check

**Trigger:** S10.P3 merge completes.
**Offset:** +7 days.
**Action:** Check that:
1. S11 lessons-learned items were propagated to guides (not just written and forgotten)
2. `EPIC_METRICS.md` final metrics were populated
3. Design doc was archived if applicable

**Why offset:** At S11.P3, context is exhausted and the team is moving to the next epic.
Scheduling a 7-day follow-up is more honest than declaring propagation complete at merge
time.

**Setting up on Claude Code:**
```
CronCreate(
    name="s11-lessons-check-{epic_id}",
    schedule="<7 days from now as cron expression>",
    prompt="Check that SHAMT epic {epic_id} post-merge items are complete: (1) S11
            lessons-learned propagated to .shamt/guides/ — check git log for commits
            after the S10 merge; (2) EPIC_METRICS.md final values populated; (3) design
            doc archived. Report any outstanding items."
)
```

### Post-export PR open → +3 days: import follow-up

**Trigger:** Child project export script opens a PR on master.
**Offset:** +3 days.
**Action:** Check if master merged the PR. If yes, initiate import on the originating
child project (closes the upstream/downstream loop automatically).

**Setting up on Claude Code:**
```
CronCreate(
    name="import-followup-{epic_id}",
    schedule="<3 days from now as cron expression>",
    prompt="Check if the export PR for epic {epic_id} was merged to master. If merged,
            run import.sh on this child project to pull the merged changes. Report the
            result."
)
```

---

## Master Dev Variant

For master work, the janitor's recurring scan covers:
- Stale child proposals in `design_docs/incoming/` (primary signal for master maintainers)
- Stale active SHAMT-N design docs

One-shot triggers are not used for master dev work (no S10/S11 epic lifecycle, no export
PRs). The stale-proposal scan is the highest-value routine for master repos.

Set up the weekly scan via `CronCreate` or by enabling the GitHub Actions workflow.
