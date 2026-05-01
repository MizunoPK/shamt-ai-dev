<!-- Managed by Shamt — do not edit. Run regen-claude-shims.sh to regenerate. -->
---
name: shamt-discovery
description: >
  Executes the S1 epic Discovery Phase — reading architecture docs, brainstorming
  questions across 6 categories, conducting iterative research, and running the
  discovery validation loop until primary clean round + 2 sub-agent confirmations.
  Supports multi-modal input (images, PDFs via Read), WebFetch/WebSearch with URL
  citation, and the testing-approach AskUserQuestion gate (A/B/C/D options).
triggers:
  - "start discovery"
  - "run discovery"
  - "do the discovery phase"
  - "S1 discovery"
source_guides:
  - guides/stages/s1/s1_epic_planning.md
  - guides/stages/s1/s1_p3_discovery_phase.md
  - guides/reference/validation_loop_discovery.md
  - guides/stages/s3/s3_epic_planning_approval.md
master-only: false
version: "1.1 (SHAMT-45)"
---

## Overview

The Discovery Phase is **mandatory for every epic**. It is a structured research and validation process where the agent explores the problem space before proposing a feature breakdown. Output: a validated, user-approved `DISCOVERY.md`.

**Prerequisites:** S1 Steps 1-2 complete (git branch created, epic folder exists, initial scope assessed).

**Exit condition:** Validation loop achieves primary clean round + both sub-agents confirm zero issues, AND user approves DISCOVERY.md.

---

## When This Skill Triggers

- User says "start discovery", "run discovery", "do the discovery phase", or "S1 discovery"
- Beginning Step 3 of the S1 Epic Planning stage
- After epic analysis is complete and you are ready to explore the problem space

---

## Protocol

### Phase 1: Initialize DISCOVERY.md (S1.P3.1)

**Step 1 — Create DISCOVERY.md**

Create `.shamt/epics/SHAMT-{N}-{epic_name}/DISCOVERY.md` from template `templates/discovery_template.md`.

**Step 2 — Write epic request summary**

Summarize what the user requested in 2-4 sentences. Capture the essence without interpretation.

**Step 3 — Read architecture docs**

1. Read `ARCHITECTURE.md` (if exists)
2. Read `CODING_STANDARDS.md` (if exists)
3. Check for undocumented additions: compare top-level directories against ARCHITECTURE.md, run `git log --since={LAST_UPDATED}` to surface recent changes
4. Note relevant components and whether this epic requires doc updates

**Step 4 — Conduct initial research**

Research the problem space:
- Grep for referenced file paths, function names, feature names
- Examine existing code patterns relevant to the epic
- Identify affected components, what exists vs. what's missing
- Document findings in DISCOVERY.md sections: Technical Analysis, Key Findings, Solution Options

**Multi-modal input:** If the user attaches a diagram or image, use the `Read` tool on the
image/PDF file, describe its content, and integrate the observations into DISCOVERY.md's
design-context section. Note the filename and a one-line description for reproducibility.

**Web research:** `WebFetch` and `WebSearch` are permitted during Discovery for prior-art
research. Cite every URL in DISCOVERY.md's Research Sources section so the research is
reproducible. Use cached web search mode (`web_search="cached"` in Codex S1 profile) for
reproducibility; switch to live only with explicit user request.

**Step 5 — Extract questions using 6-category brainstorm**

Work through ALL 6 categories before filling the Pending Questions table. Document each category with questions OR a one-line justification if none apply:

| Category | Questions or justification |
|---|---|
| **Functional requirements** | What does X mean exactly? |
| **User workflow / edge cases** | What if only some scripts need this? |
| **Implementation approach** | Which API design pattern? |
| **Constraints** | Any performance or security limits? |
| **Scope boundaries** | Does this include Y or not? |
| **Success criteria** | How will the user verify this worked? |

> CRITICAL: If you have zero questions after reading the entire epic request, stop and re-read using these 6 categories. Zero questions is a red flag indicating under-questioning.

**Ask user questions BEFORE entering the validation loop.** Record answers in the Resolved Questions table.

**Step 5b — Testing-approach selection gate**

Before finalizing DISCOVERY.md, present the testing-approach selection gate using
`AskUserQuestion` so the choice is recorded as a machine-readable artifact:

```python
AskUserQuestion(
    question="S1 testing-approach selection: Which testing strategy should this epic use?",
    options=[
        "A — Manual end-to-end (no integration scripts)",
        "B — Integration scripts opted in",
        "C — Manual + smoke test plan (no integration scripts)",
        "D — Integration scripts + smoke test plan"
    ]
)
```

Record the selected option in EPIC_README.md under `Testing Approach:`. S3.P1 reads this
field to determine whether to run the full (45-60 min) or trimmed (10-15 min) process.

On Codex headless: post the question as a PR comment with the four options; parse the reply.

**Step 6 — Set time-box and update Agent Status**

| Epic Size | Time-Box |
|---|---|
| SMALL (1-2 features) | 1-2 hours |
| MEDIUM (3-5 features) | 2-3 hours |
| LARGE (6+ features) | 3-4 hours |

---

### Phase 2: Validation Loop (S1.P3.2)

Track `consecutive_clean` explicitly. Start at 0.

**Each round follows this structure:**

**A — Re-read DISCOVERY.md completely (fresh perspective, every round)**

Use different reading patterns per round:
- Round 1: Sequential (top to bottom) + completeness check
- Round 2: Different order (by component, or reverse) + integration focus
- Round 3+: Random spot-checks + alignment

**B — Check for issues/gaps**

Issues include ANY of:
- Missing research areas (components mentioned but not researched)
- Unanswered questions or unresolved unknowns
- Assumptions stated as facts ("probably works" vs "verified works")
- Integration gaps (how features interact is unclear)
- Undefined scope (in/out/deferred not documented)
- Zero questions asked of user (treat as under-questioning)
- Adjacent systems not assessed
- Implementation decisions not surfaced
- Non-functional requirements absent (performance, security, compatibility)
- Success criteria not defined

**Run the Adversarial Challenge each round:**
- Did I work through all 6 brainstorm categories?
- Have I asked the user at least one clarifying question?
- Have I identified adjacent systems or affected workflows?
- Have I surfaced high-level implementation decisions?
- Have I considered non-functional constraints?
- Have I documented what success looks like concretely?

**C — Fix ALL issues immediately**

Zero tolerance for deferred issues. Fix each issue before updating the counter:
- Missing research → Research now, document findings
- Incomplete sections → Fill in TBD markers now
- Unanswered questions → Ask user now, record answers
- Unverified assumptions → Ask user to confirm/reject
- Integration gaps → Analyze and document dependencies
- Unclear scope → Define in/out/deferred explicitly

**D — Update counter and check exit**

- **Clean round**: ZERO issues OR exactly ONE LOW-severity issue (fixed)
- **Not clean**: 2+ LOW issues OR any MEDIUM/HIGH/CRITICAL issue
- If clean: `consecutive_clean = consecutive_clean + 1`
- If not clean: `consecutive_clean = 0`

**When `consecutive_clean = 1` → spawn 2 Haiku sub-agents in parallel:**

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Confirm zero issues in DISCOVERY.md (sub-agent A)</parameter>
  <parameter name="prompt">You are sub-agent A confirming zero issues/gaps in DISCOVERY.md.

Artifact: .shamt/epics/SHAMT-{N}-{epic_name}/DISCOVERY.md
Task: Re-read the entire DISCOVERY.md top-to-bottom. Check for missing research,
unanswered questions, unverified assumptions, unclear scope, missing success criteria,
and missing non-functional requirements. Report ANY issue found, even LOW severity.
If zero issues found, state "CONFIRMED: Zero issues found".</parameter>
</invoke>

<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Confirm zero issues in DISCOVERY.md (sub-agent B)</parameter>
  <parameter name="prompt">You are sub-agent B confirming zero issues/gaps in DISCOVERY.md.

Artifact: .shamt/epics/SHAMT-{N}-{epic_name}/DISCOVERY.md
Task: Re-read the entire DISCOVERY.md bottom-to-top (reverse order). Check for missing
research, unanswered questions, unverified assumptions, unclear scope, missing success
criteria, and missing non-functional requirements. Report ANY issue found, even LOW severity.
If zero issues found, state "CONFIRMED: Zero issues found".</parameter>
</invoke>
```

- Both confirm zero issues → proceed to exit verification
- Either sub-agent finds issues → fix all, reset `consecutive_clean = 0`, continue loop

**Exit verification checklist (after sub-agent confirmation):**
- [ ] Primary clean round achieved + both sub-agents confirmed zero issues
- [ ] All sections of DISCOVERY.md complete (no TBD, no placeholders)
- [ ] All pending questions resolved (Pending Questions table empty)
- [ ] All assumptions verified
- [ ] Scope clearly defined (in/out/deferred documented)
- [ ] Solution approach identified with rationale
- [ ] Feature breakdown drafted with Discovery basis for each feature
- [ ] All 6 question brainstorm categories addressed
- [ ] Success criteria confirmed with user

If any unchecked: reset `consecutive_clean = 0`, continue loop.

---

### Phase 3: Synthesize Findings (S1.P3.3)

After the loop exits, compile findings into recommendations.

1. **Check Approaches to Avoid**: Read epic request for already-rejected patterns; document what's ruled out
2. **Document solution options**: For each approach — description, pros, cons, effort estimate, fit assessment
3. **Create comparison summary**: Table of options with effort, fit, recommendation
4. **Document recommended approach**: State recommendation + rationale tied to specific Discovery findings and user answers
5. **Define scope**: Explicit in/out/deferred lists
6. **Draft feature breakdown**: Each feature needs purpose, scope, dependencies, Discovery basis

---

### Phase 4: User Approval (S1.P3.4)

Present Discovery summary to user:
- Brief summary of findings (2-3 sentences)
- Recommended approach with rationale
- Proposed scope (in/out/deferred)
- Proposed feature breakdown

**Wait for explicit user approval before proceeding to S1 Step 4.**

If user requests changes: update DISCOVERY.md, re-present.

After approval: mark DISCOVERY.md status as COMPLETE, update Agent Status for S1 Step 4.

---

## Exit Criteria

Discovery Phase is complete when ALL of the following are true:

- [ ] Validation loop exited: primary clean round achieved + both sub-agents confirmed zero issues
- [ ] DISCOVERY.md complete with all required sections (Executive Summary, Key Findings, Technical Analysis, Solution Options, Recommended Approach, Scope Definition, Feature Breakdown, all questions resolved)
- [ ] User approved DISCOVERY.md and recommended approach
- [ ] Feature breakdown drafted with Discovery basis for each feature
- [ ] EPIC_README.md updated with Discovery completion status
- [ ] Agent Status points to S1 Step 4 (Feature Breakdown Proposal)

**Hard rule:** Do NOT create feature folders until Discovery is approved. Discovery informs the breakdown — you cannot know the features until Discovery is complete.

---

## Quick Reference

### Severity classification for counter logic

| Level | Definition | Counter impact |
|---|---|---|
| CRITICAL | Blocks workflow or causes failure | Reset to 0 |
| HIGH | Causes confusion or wrong decisions | Reset to 0 |
| MEDIUM | Reduces quality noticeably | Reset to 0 |
| LOW | Cosmetic only | 1 LOW allowed per round; 2+ resets to 0 |

### Common mistakes

- "This epic is clear, I'll skip Discovery" → STOP. Discovery is mandatory.
- "I found no questions after reading the request" → STOP. Re-read using the 6 categories.
- "One clean round is enough" → STOP. Must also trigger and pass 2 sub-agent confirmations.
- "I'll defer these issues to the next round" → STOP. Fix ALL issues immediately.
- "User approved, so I'll add another feature" → STOP. The breakdown is what the user approved.

### Model selection

- File exploration, grep searches: Haiku
- Architecture pattern analysis: Sonnet
- Problem space synthesis, DISCOVERY.md writing: Opus (primary)
- Sub-agent confirmations: Haiku (always)
