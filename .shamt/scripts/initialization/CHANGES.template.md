# CHANGES.md — Upstream Candidates

This file accumulates Polish-phase entries that are **generic** (applicable to any Shamt Lite project, not specific to this codebase). The agent appends entries here during Polish Step 5 when root-cause analysis surfaces a generalizable improvement.

## How to share with master Shamt

1. Identify entries worth sharing.
2. Create a file named `{project}-{story-slug}-SHAMT-UPDATE-PROPOSAL.md` copying the entry content.
3. Drop it in master Shamt's `design_docs/incoming/` folder via PR.

Master accepts and propagates improvements to all Shamt Lite deployments on next `init_lite` run.

---

## Entry format

```
## {Date} — {Short title}

**Story:** {slug}
**Target file(s):** {which shamt_lite file(s) were updated}

**Change applied locally:**
{Full diff/snippet of the change made to the local file.}

**Rationale:** {Why this benefits other projects. What issue it prevents.}

**Generic (not project-specific):** {Why this isn't tied to this codebase's domain.}
```

---

<!-- Polish-phase upstream entries — append below -->
