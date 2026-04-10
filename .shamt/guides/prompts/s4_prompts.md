# S4 Prompts: Interface Contract Definition

> **Purpose:** Validate feature interface contracts before implementation planning

**Stage:** 4
**Purpose:** Feature-level interface contract definition and validation

---

## Starting S4: Interface Contract Definition

**User says:** "Define feature contracts for {feature_name}" or "Start interface validation" or Agent detects S3 complete

**Prerequisite:** S3 complete (Gate 4 passed — user approved epic plan in S3.P3)

**Agent MUST respond:**

```markdown
I'm beginning S4 (Interface Contract Definition) for {feature_name}.

**Guide I'm following:** stages/s4/s4_interface_contracts.md

**The guide requires:**
- Validate feature interface contracts with all dependencies
- Identify upstream and downstream dependencies
- Verify API/interface contracts match usage in dependent features
- Document interface change impact on dependent features
- Create contract validation document
- Validation Loop: primary clean round + sub-agent confirmation required
- Output: interface_contracts.md (agent-validated only, NO user approval gate)

**Prerequisites I'm verifying:**
✅ S3 complete (Gate 4 passed — user approved epic plan in S3.P3)
✅ Feature spec.md finalized and user-approved (Gate 3 passed from S2)
✅ Feature README.md has Agent Status section

**Updating feature README.md Agent Status:**
- Current Stage: S4 - Interface Contract Definition
- Current Guide: stages/s4/s4_interface_contracts.md
- Guide Last Read: {YYYY-MM-DD HH:MM}
- Critical Rules: "Validate interface contracts", "Identify all dependencies", "Validation Loop required", "NO user approval gate in S4"
- Next Action: Begin interface contract validation for {feature_name}

Starting interface contract validation...
```

---

## S4 Complete: Transition to S5

**Trigger:** Agent completes S4 Validation Loop (primary clean round + sub-agent confirmation), validates all contracts

**Agent MUST confirm:**

```markdown
✅ **S4 Complete — Interface Contract Definition Done**

**interface_contracts.md created for {feature_name}:**
- **Upstream dependencies:** {N} features identified
- **Downstream dependents:** {N} features identified
- **API contracts:** {N} interfaces validated
- **Integration points:** {N} points documented
- **Impact analysis:** Completed

**Validation Loop passed:** primary clean round + sub-agent confirmation
**No user approval needed:** S4 is agent-validated only (Gate 4 was in S3.P3)

**Updating feature README.md Agent Status:**
- Agent Status: S4_COMPLETE
- S4 completion: {YYYY-MM-DD HH:MM}

**Next: S5 (Implementation Planning)**

Reading `stages/s5/s5_v2_validation_loop.md` to create comprehensive implementation plan.
S5.P1 will reference interface_contracts.md for dependency validation.
```

---

*For prompts for other stages, see the [prompts index](../prompts_reference_v2.md)*
