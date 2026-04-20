# S5 v2 Quick Reference

**Purpose:** Quick lookup for S5 v2 Validation Loop structure and mapping from S5 v1 iterations

**Full Guide:** `stages/s5/s5_v2_validation_loop.md`

---

## S5 v2 Structure Overview

**Phase 1: Draft Creation (60-90 minutes)**
- Create complete implementation plan draft
- Focus on content, not perfection
- Output: `implementation_plan.md` (ready for validation)

**Phase 2: Validation Loop (3.5-6 hours, typically 6-8 rounds)**
- Systematic validation across 9 mechanical dimensions
- Fix ALL issues immediately (zero deferred issues)
- Exit criteria: primary clean round + sub-agent confirmation (all dimensions passing)
- Maximum: 10 rounds (escalate to user if exceeded)

---

## The 9 Mechanical Validation Dimensions

| # | Dimension | Focus Area | Key Checks |
|---|-----------|------------|------------|
| **D1** | Step Clarity | Unambiguous steps | Exact file paths, operations specified, no interpretation needed |
| **D2** | Mechanical Executability | Builder can execute | No design choices required, all decisions made in plan |
| **D3** | File Coverage Completeness | All files covered | All spec files in plan, test files present, no missing files |
| **D4** | Operation Specificity | Precise operations | EDIT: exact locate/replace strings; CREATE: full content; DELETE/MOVE: precise |
| **D5** | Verification Completeness | Checkable verification | Every step has mechanical verification method, builder can verify |
| **D6** | Error Handling Clarity | Explicit criteria | Success/failure criteria for each step, edge cases documented |
| **D7** | Dependency Ordering | Correct execution order | Steps in right order (create before edit), dependencies explicit |
| **D8** | Pre/Post Checklist Completeness | Both checklists complete | Pre-execution prerequisites covered, post-execution confirms completion |
| **D9** | Spec Alignment | All requirements → steps | All spec requirements translated to mechanical steps, no scope creep |

---

## S5 v1 to S5 v2 Migration Guide

### Complete Iteration Mapping

| S5 v1 Iteration | S5 v1 File Name | Focus | S5 v2 Dimension | S5 v2 Section |
|-----------------|-----------------|-------|-----------------|---------------|
| **Phase 1: Round 1 (Draft Creation)** |
| I1 | `s5_p1_i1_requirements.md` | Requirements coverage | **D1** | Requirements Completeness |
| I2 | `s5_p1_i2_algorithms.md` | Algorithm mapping | **D3** | Algorithm Traceability |
| I3 | `s5_p1_i3_integration.md` | Interface verification | **D2** | Interface & Dependency Verification |
| I4 (Gate 4a) | Embedded in I2 | TODO specification | **D4** | Task Specification Quality (Gate 4a) |
| I5 | `s5_p1_i3_iter5_dataflow.md` | Data transformations | **D5** | Data Flow & Consumption |
| I5a | `s5_p1_i3_iter5a_downstream.md` | Data consumers | **D5** | Data Flow & Consumption |
| I6 | `s5_p1_i3_iter6_errorhandling.md` | Error scenarios | **D6** | Error Handling & Edge Cases |
| I6a | `s5_p1_i3_iter6a_dependencies.md` | Dependencies audit | **D9** | Performance & Dependencies |
| I7 | `s5_p1_i3_iter7_integration.md` | Integration points | **D7** | Integration & Compatibility |
| I7a (Gate 7a) | `s5_p1_i3_iter7a_compatibility.md` | Backward compatibility | **D7** | Integration & Compatibility |
| **Phase 2: Round 2 (Verification)** |
| I8 | `s5_p2_i1_test_strategy.md` | Test coverage | **D8** | Test Coverage Quality |
| I9-16 | `s5_p2_i2_reverification.md` | Re-verify all aspects | **All Dimensions** | Validation Loop Round 1 |
| I16 | `s5_p2_i3_final_checks.md` | Final verification | **All Dimensions** | Validation Loop (mid-rounds) |
| **Phase 3: Round 3 (Final Review)** |
| I17 | `s5_p3_i1_iter17_phasing.md` | Implementation phases | **D8** | Pre/Post Checklist Completeness |
| I18 | `s5_p3_i1_iter18_rollback.md` | Rollback strategy | **D8** | Pre/Post Checklist Completeness |
| I19 | `s5_p3_i1_iter19_traceability.md` | Algorithm traceability | **D3** | Algorithm Traceability |
| I20 | `s5_p3_i1_iter20_performance.md` | Performance analysis | **D9** | Performance & Dependencies |
| I21 | `s5_p3_i1_iter21_mockaudit.md` | Mock spec audit | **D9** | Spec Alignment |
| I22 | `s5_p3_i1_iter22_consumers.md` | Data consumers | **D5** | Data Flow & Consumption |
| I23 (Gate 23a) | `s5_p3_i2_gates_part1.md` | Pre-implementation audit | **D9** | Spec Alignment (Gate 23a) |
| I24 (Gate 24) | `s5_p3_i3_gates_part2.md` | GO/NO-GO decision | **exit** | See validation exit criteria (Gate 24) |
| I25 (Gate 25) | `s5_p3_i3_gates_part2.md` | Spec validation check | **D9** | Spec Alignment (Gate 25) |

---

## Key Differences: V1 vs V2

### Structure
- **V1:** Linear 22 iterations (I1 → I2 → ... → I25)
- **V2:** Iterative validation loop (Draft → Validate 9 mechanical dimensions → Fix → Repeat until primary clean round + sub-agent confirmation)

### Time
- **V1:** 9-11 hours (fixed iterations)
- **V2:** 4.5-7 hours typical (variable rounds based on quality)

### Quality Assurance
- **V1:** Sequential checks (could skip or defer issues)
- **V2:** Systematic validation with ZERO deferred issues, primary clean round + sub-agent confirmation required

### File Structure
- **V1:** 25+ separate files (one per iteration)
- **V2:** 1 comprehensive guide (`s5_v2_validation_loop.md`)

---

## Common Mappings (Quick Lookup)

**Looking for Gates?**
- Gate 4a (TODO spec) → Dimension 4
- Gate 7a (Compatibility) → Dimension 7
- Gate 23a (Spec audit) → Dimension 9 (Spec Alignment)
- Gate 24 (GO/NO-GO) → exit criteria (no dedicated dimension)
- Gate 25 (Spec validation) → Dimension 9 (Spec Alignment)

**Looking for specific checks?**
- Requirements coverage → D1
- Algorithm implementation → D3
- Interface verification → D2
- Data flow → D5
- Error handling → D6
- Test coverage → D8
- Performance → D9
- Integration points → D7
- Implementation readiness → see validation exit criteria
- Final spec alignment → D9 (Spec Alignment)

**Looking for task quality checks?**
- See Dimension 4 (Task Specification Quality)
- Embeds Gate 4a checks

---

## When to Reference This Guide

**Use this guide when:**
- Updating documentation that references S5 v1 files
- Migrating bug reports or lessons learned from S5 v1 format
- Understanding which dimension covers a specific S5 v1 iteration
- Creating new documentation that needs to reference S5 structure

**Primary Guide:**
- For actual S5 workflow: See `stages/s5/s5_v2_validation_loop.md`

---

## File Reference Format (Standard)

**When referencing S5 v2 in documentation:**

✅ **Correct format:**
- `stages/s5/s5_v2_validation_loop.md` (general reference)
- `stages/s5/s5_v2_validation_loop.md` (Dimension N) - when referring to specific dimension
- `stages/s5/s5_v2_validation_loop.md` (Gate Xa) - when referring to specific gate

❌ **Incorrect format (S5 v1):**
- `stages/s5/s5_p1_i1_requirements.md` (file doesn't exist)
- `stages/s5/s5_p3_i3_gates_part2.md` (file doesn't exist)
- Any reference to `s5_p[0-9]` files

---

## Cross-References

- **Full S5 v2 Guide:** `stages/s5/s5_v2_validation_loop.md`
- **Prompts:** `prompts/s5_s8_prompts.md`
- **S5 Reference Card:** `reference/stage_5/stage_5_reference_card.md` (updated for v2)

---

**Last Updated:** 2026-02-10 (Round 5.1 audit fixes)
