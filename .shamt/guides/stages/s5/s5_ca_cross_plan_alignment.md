# S5-CA: Cross-Plan Alignment (Primary Agent Only)

🚨 **MANDATORY READING PROTOCOL**

**Before starting S5-CA — including when resuming a prior session:**
1. Use Read tool to load THIS ENTIRE GUIDE
2. Verify ALL features completed S5 and sent completion messages
3. Verify all STATUS files show `STATUS: WAITING_FOR_SYNC` and `READY_FOR_SYNC: true`

**This phase is PRIMARY AGENT ONLY — Secondary agents wait**

---

## 🚫 FORBIDDEN SHORTCUTS

You CANNOT:
- Skip pairwise comparison for features that "seem independent" — every pair must be checked for plan conflicts and shared-code assumptions
- Proceed to Gate 5 while any feature's STATUS file still shows IN_PROGRESS — all features must have WAITING_FOR_SYNC before S5-CA begins
- Defer spec discrepancies to S8 — if you find a spec-level contradiction between plans, STOP and escalate to user immediately
- Self-resolve spec discrepancies — update plans only when the resolution is within the existing specs; spec conflicts go to the user

If you are about to do any of the above: STOP and re-read the relevant section.

---

## Overview

**Purpose:** Pairwise comparison of all features' `implementation_plan.md` files, with targeted re-validation after conflict resolution

**When:** After all features complete S5 (all STATUS files: WAITING_FOR_SYNC, READY_FOR_SYNC: true)

**Time:** 0.5–1 hour (depending on feature count and conflicts found)

**Key Outputs:**
- Updated `implementation_plan.md` files (if conflicts resolved)
- `epic/research/S5_CA_PLAN_ALIGNMENT_{DATE}.md` (audit trail)
- S6 sequencing recommendation
- Notifications to secondary agents (listing which plans were updated)

---

## Prerequisites

- [ ] All features completed S5 (implementation_plan.md exists for each feature)
- [ ] All features sent completion messages to Primary
- [ ] All STATUS files show `STATUS: WAITING_FOR_SYNC` and `READY_FOR_SYNC: true`
- [ ] All checkpoints show S5 complete and are not stale (< 60 min since last update)

**If any prerequisite fails:**
- ❌ STOP — Do NOT proceed to S5-CA
- See stale agent protocol if a checkpoint is stale: `parallel_work/stale_agent_protocol.md`

---

## Steps

### Step 0: Sync Verification (5–10 min)

Verify all agents are genuinely complete before beginning.

**0.1 — Check completion messages:**
- Read `agent_comms/{secondary_id}_to_primary.md` for each secondary
- Look for: completion message with subject containing "S5 Complete"
- Verify: feature name matches, "Blockers: None", "Ready for S5-CA: Yes"

**If any secondary has NOT sent a completion message:**
- ❌ STOP — send status check: "Status check — are you complete with S5?"
- Wait 15 minutes for response
- If no response: escalate to user (stale agent)

**0.2 — Verify STATUS files:**
- Read `{feature_folder}/STATUS` for each feature
- Verify: `STATUS: WAITING_FOR_SYNC`, `READY_FOR_SYNC: true`, `BLOCKERS: none`

**If any STATUS shows IN_PROGRESS or BLOCKED:**
- ❌ STOP — send message to the relevant secondary requesting status update
- Wait for clarification

**0.3 — Verify checkpoints (staleness check):**
- Read `agent_checkpoints/{secondary_id}.json` for each secondary
- Verify: `status` shows `WAITING` or `COMPLETE` (checkpoint status, distinct from STATUS file)
- Check: `last_checkpoint` — if >60 min ago: ❌ FAIL (assumed crashed)
- If >30 min ago: ⚠️ Warning — send status check before proceeding

**0.4 — Verify all implementation_plan.md files exist:**
- Confirm `{feature_folder}/implementation_plan.md` exists and is non-empty for each feature
- Confirm each plan shows "Validated: 3 consecutive clean rounds" (or equivalent) — confirming the individual validation loop passed

**If any plan is missing or unvalidated:**
- ❌ STOP — the feature's S5 is not actually complete
- Contact the relevant secondary (or user) to complete S5 before proceeding

---

### Step 1: Prioritized Pairwise Plan Comparison (20–40 min)

**Scope:** All pairs of features.

**Priority order for first pass:**

**First pass — pairs with known integration dependencies:**
- Read all `epic/research/S2_P2_COMPARISON_MATRIX_GROUP_{N}.md` files
- Identify pairs that had integration dependencies noted during S2.P2
- Check these pairs first (they are most likely to have plan-level conflicts)
- Skip first pass entirely if no integration dependencies were found in any S2.P2 matrix

**Second pass — all remaining pairs:**
- Check every pair not covered in the first pass
- (If first pass was skipped: check all pairs in feature order)

**For each pair, check:**

**1. Interface conflicts (D2):**
- Does Feature A's plan assert an interface (function, class, API) that Feature B also asserts but with a different signature or contract?
- Example: Feature A plans to call `process_data(items: list)` but Feature B plans to refactor it to `process_data(items: list, config: dict)`
- Action: Both plans cannot be correct — resolve to a single interface; update both plans

**2. Shared-code conflicts:**
- Do both plans modify the same file, class, or function in incompatible ways?
- Example: Feature A plans to add a field to `UserModel` and Feature B plans to rename the class to `AccountModel`
- Action: Align to a single approach; update the conflicting plan

**3. Implementation ordering dependencies:**
- Does Feature A's plan depend on code that Feature B plans to create, and therefore Feature B must complete S6 first?
- Example: Feature A plans to call a new helper function that Feature B plans to introduce
- Action: Note this as an ordering dependency (addressed in Step 4)

**4. Cross-feature data flow assumptions (D5):**
- If Feature A produces data consumed by Feature B, do the data formats match?
- Example: Feature A writes a `results.json` with field `"score"` but Feature B reads `results.json` expecting field `"total_score"`
- Action: Align the field names; update the plan that introduced the inconsistency

**Document each finding:**
- Pair checked (Feature A vs Feature B)
- Check type (D2 / shared-code / ordering / D5)
- Conflict found (yes/no; if yes: description)
- Resolution applied (if any)

---

### Step 2: Conflict Resolution

**For each conflict found in Step 1:**

1. **Determine which plan to update** (or both):
   - Prefer updating the plan that diverges from the existing spec
   - If both plans equally diverge: choose the approach that minimizes overall change
   - If you cannot determine a correct resolution without spec clarification: STOP and escalate to user

2. **STOP immediately if the conflict is a spec discrepancy:**
   - A spec discrepancy is when the conflict cannot be resolved without changing what the feature is supposed to do — not just how it does it
   - Example: "Feature A's plan assumes the API returns JSON; Feature B's plan assumes XML. The spec doesn't specify the format."
   - In this case: STOP S5-CA, escalate to user with exact discrepancy, wait for spec update

3. **Update the affected `implementation_plan.md` directly:**
   - Primary has write access to all feature plans
   - Make the minimum change needed to resolve the conflict
   - Add a note in the plan: "Updated during S5-CA [{DATE}]: {brief reason}"

4. **Run targeted re-validation on affected dimensions:**
   - Re-read the updated plan
   - Check the specific dimensions affected by the change: D2 (interfaces), D5 (data flow), D6 (error handling), D7 (integration)
   - Verify the update resolves the conflict without introducing new issues
   - If new issues found: resolve them before continuing

---

### Step 3: Validation Loop — 3 Consecutive Clean Rounds

**After all conflicts from Step 1 are resolved:**

Run pairwise comparison again — need 3 consecutive rounds with zero findings.

**Each round:**
- Re-read all `implementation_plan.md` files
- Check all pairs for all 4 conflict types (D2, shared-code, ordering, D5)
- If any finding: fix immediately (do not batch), reset consecutive count to 0
- If zero findings: increment consecutive count

**Track:**
```
Round 1: [N findings] — consecutive_clean = 0
Round 2: [N findings] — consecutive_clean = 0  (or 1 if Round 1 was clean)
Round 3: 0 findings — consecutive_clean = 1
Round 4: 0 findings — consecutive_clean = 2
Round 5: 0 findings — consecutive_clean = 3  ✅ EXIT
```

**Zero tolerance:** Any finding resets the counter, regardless of severity.

**Exit:** 3 CONSECUTIVE clean rounds required. 3 total rounds with some clean is not sufficient.

---

### Step 4: S6 Sequencing Recommendation

**After validation loop passes:**

**If ordering dependencies were found in Step 1:**

1. **Document recommended S6 sequence** in the alignment file (Step 5):
   - Specify which features must implement before others
   - State the reason (e.g., "Feature 03 depends on helper function introduced by Feature 02")

2. **Add re-verification flag to dependent feature's `implementation_plan.md`:**
   - Add a note at the top of the plan:
     ```
     ## Re-Verification Required Before S6
     This plan has an ordering dependency on {prerequisite_feature}.
     Before beginning S6, verify that {prerequisite_feature}'s completed code matches
     the following assumptions in this plan:
     - [Specific assumption 1, e.g., "function X exists with signature Y"]
     - [Specific assumption 2]
     Re-check dimensions: D2 (interfaces), D5 (data flow), D6 (error handling), D7 (integration)
     Update this plan if any assumption has changed. Escalate if a spec discrepancy is found.
     ```

**If no ordering dependencies were found:**

Document in the alignment file: "No ordering constraints identified — features may implement in any order."

---

### Step 5: Document and Notify

**5.1 — Create alignment document:**

Create `epic/research/S5_CA_PLAN_ALIGNMENT_{DATE}.md`:

```markdown
## S5-CA: Cross-Plan Alignment

**Date:** {YYYY-MM-DD HH:MM}
**Epic:** {epic_name}
**Parallel Mode:** Yes (Primary + {N} secondaries)

---

## Sync Verification

- [x] All completion messages received
- [x] All STATUS files: WAITING_FOR_SYNC
- [x] All checkpoints: not stale
- [x] All implementation_plan.md files exist and validated

---

## Pairwise Comparison Results

| Feature A | Feature B | D2 | Shared-Code | Ordering | D5 | Action |
|-----------|-----------|-----|-------------|----------|----|--------|
| Feature 01 | Feature 02 | None | None | None | None | No change |
| Feature 01 | Feature 03 | Conflict: ... | None | None | None | Updated Feature 03 plan |
| Feature 02 | Feature 03 | None | None | Feature 02 first | None | Ordering dep noted |

---

## Conflicts Resolved

### Conflict 1: {Description}
- **Pair:** Feature 01 vs Feature 03
- **Type:** D2 (interface conflict)
- **Issue:** {Exact conflict description}
- **Resolution:** {What was changed and why}
- **Files Updated:** feature_03_{name}/implementation_plan.md

[Continue for each conflict...]

---

## Validation Loop

- Round 1: {N} findings
- Round 2: {N} findings
- Round 3: 0 findings — consecutive_clean = 1
- Round 4: 0 findings — consecutive_clean = 2
- Round 5: 0 findings — consecutive_clean = 3 ✅

---

## S6 Sequencing Recommendation

{Recommended sequence, or "No ordering constraints — features may implement in any order"}

---

## Plans Updated During S5-CA

- feature_03_{name}/implementation_plan.md — UPDATED (D2 conflict resolution)
- feature_01_{name}/implementation_plan.md — NO CHANGE
- feature_02_{name}/implementation_plan.md — NO CHANGE

---

**Audit Trail:** This file documents that cross-plan alignment was performed and all conflicts were
resolved before proceeding to combined Gate 5.
```

**5.2 — Notify secondary agents:**

For each secondary, send a notification to their inbox:

```markdown
## Message N (TIMESTAMP) ⏳ UNREAD
**Subject:** S5-CA Complete — Re-read Your Plan If Updated
**Action:** {See Details below}
**Details:**
S5-CA (Cross-Plan Alignment) is complete.

Plans updated during S5-CA:
- {feature_folder}/implementation_plan.md — {UPDATED (section X) | NO CHANGE}
- {feature_folder}/implementation_plan.md — {UPDATED (section X) | NO CHANGE}

If your plan was UPDATED: please re-read implementation_plan.md now.
If your plan was NOT UPDATED: no action needed.

Proceeding to combined Gate 5 (user review of all plans together).
**Next:** Await Gate 5 notification (informational — no action needed)
**Acknowledge:** No action needed
```

**5.3 — Update EPIC_README.md:**

Add to Agent Status:
```markdown
**S5-CA:** Complete {timestamp}
**S5-CA Result:** {N} conflicts found and resolved / No conflicts found
**Combined Gate 5:** Pending user review
```

---

## Exit Criteria

**S5-CA is complete when ALL true:**

- [ ] Sync verification passed (Step 0): all agents confirmed complete, all plans present
- [ ] All feature pairs checked for D2, shared-code, ordering, and D5 conflicts (Steps 1–2)
- [ ] All conflicts resolved (plans updated directly) and targeted re-validation passed
- [ ] 3 consecutive clean pairwise comparison rounds achieved (Step 3)
- [ ] S6 sequencing recommendation documented (Step 4)
- [ ] `epic/research/S5_CA_PLAN_ALIGNMENT_{DATE}.md` created (Step 5)
- [ ] All secondary agents notified of plan updates (Step 5)

---

## Next Phase

**After S5-CA complete:**

Proceed to combined Gate 5. Present all implementation plans (post-S5-CA) to user for review and approval.

📖 **See:** `parallel_work/s5_primary_agent_guide.md` → Phase 5 (Combined Gate 5 and SP4)

---

*End of s5_ca_cross_plan_alignment.md*
