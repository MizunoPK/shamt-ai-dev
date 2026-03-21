# Proposal: Sub-Agent Parallel Confirmation for Validation Loop Exit

**Status:** Design complete — ready for implementation
**Created:** 2026-03-19
**Last Updated:** 2026-03-19
**Relates to:** `validation_loop_master_protocol.md`

---

## Problem Statement

The current 2/3-consecutive-clean-rounds exit requirement is a proxy for confidence that an artifact is genuinely done. It exists because a single agent can mechanically declare a round clean — and repeated self-certification by the same agent does not provide genuine independence. Each "fresh eyes" round still uses the same agent that created and refined the artifact, which has increasing investment in being finished.

The consecutive-round requirement is a "make it hard to fake" heuristic, not a genuine independence guarantee.

---

## Proposed Change

**Completely replace the 2/3-consecutive-clean-rounds system with a single clean round from the primary agent, followed by parallel confirmation from 2 independent sub-agents.**

There is no longer a "2-round checkpoint" or a "3-round standard." The exit condition is:
1. Primary agent declares a clean round
2. Both sub-agents independently confirm clean

That's it.

### New Exit Sequence

```
Primary agent runs validation rounds normally (finding and fixing issues)
                    ↓
Primary agent declares a clean round (zero issues found)
                    ↓
Spawn 2 sub-agents in parallel, each independently validating the full artifact
                    ↓
Both sub-agents confirm zero issues? → EXIT LOOP ✅
Either sub-agent finds issues?       → Fix all issues found, continue loop
                                       (see Failure Protocol below)
```

### Why This Is Stronger Than the Old System

| | Old (2/3 consecutive rounds) | New (1 clean + parallel confirmation) |
|---|---|---|
| Independence | Same agent, attempted fresh eyes | Genuinely independent agents |
| Speed | 2 extra rounds ~60–80 min | 1 parallel batch ~30–40 min |
| Fakeability | Agent can declare rounds clean mechanically | Agent cannot self-confirm; needs independent agreement |
| Context quality | Agent knows full fix history | Sub-agents evaluate current state only |
| Issue-finding after "clean" | Low — agent is biased toward done | High — sub-agents have no stake in the outcome |
| User checkpoint | Formal pause at 2 clean rounds | Removed — sub-agent confirmation is the exit gate |

The primary agent has refined the artifact across multiple rounds and has increasing investment in it being complete. Sub-agents that have never touched the artifact have none. This is a structurally more principled solution to the same underlying problem the consecutive-round requirement was solving.

---

## Sub-Agent Design

### How Many

**2 sub-agents**, each assigned a different reading pattern (one top-to-bottom, one bottom-to-top). This captures cross-cutting inconsistencies a single direction misses without requiring a third full-context spawn. 2 can be increased to 3 later if empirical evidence shows both agents consistently missing the same issue categories.

### What Sub-Agents Receive

Sub-agents receive a **validation bundle** defined per scenario type. The bundle is assembled mechanically: read the artifact, find every file reference, include those files.

**Bundle derivation principle:** Include the artifact being validated plus every upstream document that a scenario-specific dimension is required to cross-check against. For example, S5 Dimension 1 (Requirements Completeness) requires checking against `spec.md`, and Dimension 8 (Test Coverage) requires checking `EPIC_README` for Testing Approach — so both are in the S5 bundle. Apply this principle when defining bundles for scenarios not yet listed below.

| Scenario | Bundle Contents |
|---|---|
| S5 (implementation plan) | artifact + `spec.md` + `EPIC_README` + referenced source files |
| S2 (feature spec) | artifact + epic notes + `EPIC_TICKET.md` |
| S7/S9 QC (code) | artifact (code files) + `spec.md` + referenced source files |
| S3 (epic docs) | artifact + `EPIC_TICKET.md` + feature specs |
| S8 alignment | artifact + all feature specs being aligned |

**Always exclude:**
- Prior validation round history
- The primary agent's findings or declared clean status
- Any information suggesting the expected outcome

Rationale: sub-agents are evaluating the *current state* of the artifact, not auditing the validation history. Prior context would contaminate their independence.

### Sub-Agent Prompt Framing

**Critical:** Do NOT tell sub-agents the primary found the artifact clean. This primes them toward confirmation.

Each sub-agent is assigned a reading pattern in the prompt. Sub-agent A reads top-to-bottom; Sub-agent B reads bottom-to-top. This captures cross-cutting inconsistencies that a single direction misses.

Frame each sub-agent's task as (insert the assigned reading pattern where noted):

> "Independently validate this artifact against all dimensions. Your job is to find problems. Read the artifact **[top-to-bottom / bottom-to-top]** — do not skip around. Approach it as a skeptical reviewer encountering this artifact for the first time. Be conservative: if anything is questionable, flag it. You must call `read_file` to read the artifact and `grep`/`file_search` to verify at least 3 technical claims. Do not produce dimension results without this evidence — your output will be rejected if tool calls are absent."

### Required Sub-Agent Output

Sub-agents must produce:
1. A PASS or ISSUE result per dimension (all master + scenario-specific)
2. **Tool-call evidence** — actual `read_file` and `grep`/`file_search` calls with results documented inline. A sub-agent that produces dimension results without tool calls has not done real validation.
3. A total issue count and clean/not-clean summary

### Threshold for Exit

**Unanimous zero-issue confirmation required.** If either sub-agent finds any issue, the round is not clean. The exit condition requires both to agree independently.

### What to Log in VALIDATION_LOG.md

When the sub-agent confirmation step runs, the primary must record:
- That confirmation was triggered (which primary round it followed)
- Sub-agent A: reading pattern assigned, tool evidence present (yes/no), verdict (clean/not-clean), issues found (if any)
- Sub-agent B: same
- Overall result: CONFIRMED CLEAN (proceed to exit) or NOT CONFIRMED (issues found — list them, continue loop)

### If a Sub-Agent Produces No Tool-Call Evidence

Count it as non-clean. The primary runs another full validation round checking all dimensions against the full artifact, then triggers the sub-agent confirmation again. Do not re-run the sub-agent or spawn a replacement — a sub-agent that didn't use tools once will likely not use them on a retry. The prompt requirement for tool calls is the prevention; this is the fallback when prevention fails.

---

## Failure Protocol (Sub-Agent Finds Issues)

When one or both sub-agents find issues after the primary declared a clean round:

1. Fix **all** issues found across both sub-agents — no adjudication by the primary
2. Run another primary validation round
3. If that round is clean, spawn the 2 sub-agents again
4. Repeat until both sub-agents confirm clean

**On fixing sub-agent findings:** "Fix all" does not mean "implement every suggested change verbatim." It means treat every flagged item as a signal that something was unclear or concerning to an independent reviewer. The primary's job per flagged item is: *how do I address this concern?* — not *is this concern valid?* Even a genuine false positive means an independent reviewer found something ambiguous; the response is to make the artifact less ambiguous in that area. The primary does not have adjudication power to dismiss sub-agent findings.

**On loop continuation:** The prior rounds of issue-finding and fixing remain valid history. The primary continues running rounds until it gets another clean one, then spawns sub-agents again. Only the exit sequence restarts — the primary does not return to Round 1.

---

## Protocol Edge Cases

### 10-Round Re-Evaluation Threshold

The master protocol specifies that if the loop exceeds 10 rounds, the agent should re-evaluate the approach (possible structural issue with the artifact). This threshold still applies to the **primary agent's rounds** and is unchanged by this proposal.

The 10-round threshold was previously coupled with the 2-round checkpoint in the master protocol (both could fire simultaneously at round 9–10). Since the 2-round checkpoint is removed, the interaction section in the master protocol should be simplified: the 10-round threshold stands alone, and when it fires the agent presents it directly to the user without the combined-checkpoint framing.

### If Sub-Agents Are Unavailable

If the execution environment does not support spawning sub-agents (API restrictions, rate limiting, context budget exhausted), the primary agent must:

1. Document the unavailability in the VALIDATION_LOG.md
2. Fall back to the old exit standard: 3 consecutive clean rounds from the primary agent
3. Note the fallback in Agent Status

This fallback preserves protocol correctness at the cost of the independence guarantee. It should be rare and always documented when it occurs.

---

## Relationship to Existing Prohibition

The master protocol currently contains **Shortcut 4: "Delegated Validation"**, which prohibits using sub-agents for validation rounds.

The rationale: *"Subagents don't have the context of previous rounds. They can't provide 'fresh eyes' because they've never seen the artifact before — they provide 'no eyes.'"*

This proposal does not contradict that prohibition's intent. The prohibition targets sub-agents used to *replace* the primary agent's issue-finding and fixing work. This proposal uses sub-agents specifically *because* they have never seen the artifact — that's the feature, not the bug. The primary agent still does all the work of finding and fixing issues; sub-agents only confirm the exit condition.

When this proposal is implemented, Shortcut 4 must be updated to clarify:
- Using sub-agents to run validation rounds (replacing primary work) → **still prohibited**
- Using sub-agents to confirm a clean exit condition (after primary work is complete) → **the new protocol**

---

## Guide Changes Required on Implementation

**Stage-level guides (contain full exit criteria sections):**
1. **`reference/validation_loop_master_protocol.md`** — Replace exit criteria section. Remove the 2/3-consecutive-round requirement and the 2-round user checkpoint entirely. Replace with the new exit sequence. Update Shortcut 4. Simplify the 10-round threshold section (remove the combined-checkpoint framing since the 2-round checkpoint is gone).
2. **`stages/s5/s5_v2_validation_loop.md`** — Update exit criteria, round-by-round section, and FORBIDDEN SHORTCUTS to reference new protocol.
3. **`stages/s7/s7_p2_qc_rounds.md`** — Same.
4. **`stages/s9/s9_p2_epic_qc_rounds.md`** — Same. Also update FORBIDDEN SHORTCUTS ("Stop before the 2-round checkpoint without user input") and CRITICAL RULES block ("3 CONSECUTIVE CLEAN ROUNDS REQUIRED (OR USER CHECKPOINT AT 2)").

**Reference guides (contain exit criteria in their own Exit Criteria sections):**
5. **`reference/validation_loop_alignment.md`** — Update Exit Criteria section (currently references 3 consecutive rounds and 2-round checkpoint).
6. **`reference/validation_loop_discovery.md`** — Same.
7. **`reference/validation_loop_qc_pr.md`** — Same.
8. **`reference/validation_loop_s7_feature_qc.md`** — Same.
9. **`reference/validation_loop_s9_epic_qc.md`** — Same.
10. **`reference/validation_loop_spec_refinement.md`** — Same.

---

*End of proposal.*
