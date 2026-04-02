# Design Doc Validation

This guide describes how to validate design docs in the master shamt-ai-dev repository using the 7-dimension validation loop.

---

## When to Validate

Run design doc validation when:
- A new design doc has been created and is in Draft status
- The user requests validation (e.g., "validate the design doc")
- Before beginning implementation to ensure the design is sound

---

## What Gets Validated

Design docs are validated using a 7-dimension framework that checks:
1. **Completeness** — All necessary aspects covered
2. **Correctness** — Factual claims accurate
3. **Consistency** — Internal consistency, no conflicts with existing guides
4. **Helpfulness** — Proposals solve the stated problem
5. **Improvements** — Simpler or better alternatives considered
6. **Missing proposals** — Important items not left out of scope
7. **Open questions** — Unresolved decisions surfaced

---

## Exit Criterion

Validation completes when:
1. **Primary clean round** — All 7 dimensions pass with ≤1 LOW-severity issue
2. **Sub-agent confirmation** — 2 independent sub-agents both confirm zero issues

A round is clean if it has ZERO issues OR exactly ONE LOW-severity issue (fixed). Multiple LOW-severity issues OR any MEDIUM/HIGH/CRITICAL severity issue resets `consecutive_clean` to 0.

---

## The Validation Process

See `validation_workflow.md` for the full step-by-step process.

---

## Validation Log

Every design doc should have an accompanying validation log that tracks:
- Round-by-round findings
- Issues found and fixed
- Sub-agent confirmation results
- Final validation status

Use the template at `validation_log_template.md` to create a new validation log.

---

## Severity Classification

Issues are classified using the universal severity system:
- **CRITICAL**: Blocks workflow or causes cascading failures
- **HIGH**: Causes significant confusion or wrong decisions
- **MEDIUM**: Reduces quality but doesn't block or confuse
- **LOW**: Cosmetic issues with minimal impact

See `reference/severity_classification_universal.md` for detailed definitions.

---

## After Validation

When validation completes successfully:
1. Update design doc Status field to "Validated"
2. Move validation log to the same folder as the design doc
3. Design doc is ready for implementation
