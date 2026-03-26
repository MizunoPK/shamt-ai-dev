# S5 v2 Validation Loop: Troubleshooting

**Parent Guide:** `stages/s5/s5_v2_validation_loop.md`
**Purpose:** Common issues, fixes, and anti-patterns for the S5 v2 validation loop

---

## ⚠️ COMMON ISSUES & FIXES

### Issue 1: "Can't find all algorithms in spec"

**Symptom:** Algorithm matrix only 20-30 mappings, but need 40+

**Cause:** Only mapped main algorithms, missed helpers, edge cases, error handling

**Fix:**
- Re-read spec.md "Algorithms" section completely
- Look for implicit algorithms (error handling, validation, normalization)
- Check "Edge Cases" section for algorithm variations
- Check "Error Handling" section for recovery algorithms

---

### Issue 2: "Interface verification taking too long"

**Symptom:** Spending >30 minutes verifying interfaces in validation round

**Cause:** Trying to verify too thoroughly in single round

**Fix:**
- In Round 1: Verify 3-5 most critical interfaces
- In Round 2: Verify next 3-5 interfaces
- In Round 3: Verify remaining interfaces
- Don't block on interface verification - spread across rounds

---

### Issue 3: "Fixes introducing new issues"

**Symptom:** Round 4 finds issues in sections that were clean in Round 3

**Cause:** Normal! Fixes can introduce new issues. That's why the primary clean round must find zero issues before triggering sub-agent confirmation.

**Fix:**
- This is expected behavior, not a problem
- Keep fixing issues and re-validating
- Counter resets when issues found (by design)
- Eventually, fixes won't introduce new issues → primary clean round + sub-agent confirmation → exit

---

### Issue 4: "Validation loop stuck at 8-9 rounds"

**Symptom:** Approaching 10 round limit, still finding issues

**Cause:** May indicate fundamental problem (unclear requirements, wrong approach)

**Fix:**
- Before Round 10: Ask yourself "What pattern do I see in recent issues?"
- If same dimension keeps failing: Root cause may be spec clarity issue
- If issues scattered: May need to slow down and be more thorough
- At Round 10: Escalate to user (don't force to continue)

---

### Issue 5: "Unsure if something is an issue"

**Symptom:** Found something that might be wrong, but not sure if it counts as issue

**Cause:** Unclear validation criteria

**Fix:**
- **If in doubt, call it an issue**
- Better to flag and fix than miss a real issue
- Validation loop will catch if fix was unnecessary (next round will be clean)
- Conservative approach: assume everything is wrong until proven right

---

## 🚫 ANTI-PATTERNS TO AVOID

### ❌ Anti-Pattern 1: "Working from Memory"

**Wrong:** "I remember I checked this in Round 1, so I'll skip it in Round 2"

**Right:** Re-read ENTIRE implementation_plan.md every round using Read tool

**Why:** Memory-based validation misses issues. Fresh eyes each round catches what memory overlooks.

---

### ❌ Anti-Pattern 2: "Deferring Minor Issues"

**Wrong:** "This is a minor typo, I'll fix it later" (mark as low priority, continue)

**Right:** Fix ALL issues immediately before next round, no matter how minor

**Why:** "Later" never comes. Small issues compound. Validation loop requires zero deferred issues.

---

### ❌ Anti-Pattern 3: "Stopping at 3 Rounds Total"

**Wrong:** "I've done 3 rounds (found 5, 3, 1 issues), I'm done"

**Right:** Need a primary clean round (zero issues found) then sub-agent confirmation (might be rounds 4, 5, 6+)

**Why:** Exit criteria is a primary clean round + sub-agent confirmation, not just completing N rounds total.

---

### ❌ Anti-Pattern 4: "Batching Fixes"

**Wrong:** "I'll note all issues from Rounds 1-3, then fix them all at once"

**Right:** Fix all issues from Round N immediately before Round N+1

**Why:** Fixes from Round 1 might change what you find in Round 2. Can't batch.

---

### ❌ Anti-Pattern 5: "Skipping Re-Reading After Small Fix"

**Wrong:** "I only changed one line, I don't need to re-read everything"

**Right:** Re-read ENTIRE implementation_plan.md every round (fixes can introduce new issues)

**Why:** One-line fix in Dimension 1 might create issue in Dimension 7 (integration). Must check everything.

---

### ❌ Anti-Pattern 6: "Saying 'Efficiently' or 'Quickly'"

**Wrong:** "I'll efficiently complete this validation round"

**Right:** Follow every step systematically, checking all dimensions

**Why:** "Efficiently" is code for "cutting corners." Validation loop exists to prevent mistakes from cutting corners.

---

## See Also

- `stages/s5/s5_v2_validation_loop.md` — main S5 v2 guide (workflow, dimensions, exit criteria)
- `stages/s5/s5_v2_example.md` — complete worked example of a validation loop
