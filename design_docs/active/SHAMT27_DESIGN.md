# SHAMT-27: Strategic Model Selection for Token Optimization

**Status:** Draft
**Created:** 2026-04-01
**Branch:** `feat/SHAMT-27`
**Validation Log:** [SHAMT27_VALIDATION_LOG.md](./SHAMT27_VALIDATION_LOG.md)

---

## Problem Statement

Current .shamt workflows use a single model (typically Sonnet or Opus) for all tasks regardless of complexity. This leads to inefficient token usage:

- **Validation loops** (Guide Audit, S5, S7, S9, Code Review) consume 3.5-6.5 hours of Opus/Sonnet tokens even for mechanical tasks like file counting, cross-reference validation, and grep searches
- **Sub-agent confirmations** use Opus/Sonnet for focused "zero issues" verification tasks that don't require deep reasoning
- **Frequent operations** like Agent Status updates, STATUS file writes, and checkpoint tracking use expensive models for mechanical text replacement
- **Discovery Phase** uses expensive models for file tree exploration and keyword searches before synthesis work begins
- **Import/Export workflows** use expensive models for script execution and file copying

**Token cost impact:** Based on analysis of workflow task distribution (~30% simple/repetitive, ~40% complex, ~30% decision-heavy), we estimate **30-50% token savings** are achievable through strategic model selection without quality degradation.

**Why this matters:**
1. **Cost reduction** — Haiku is ~20x cheaper than Opus for equivalent simple tasks
2. **Faster execution** — Haiku has lower latency for mechanical operations
3. **Better model utilization** — Reserve Opus for tasks requiring deep reasoning, use Haiku for grunt work
4. **Scalability** — Enable longer validation loops and more thorough audits within budget constraints

---

## Goals

1. **Reduce token costs by 30-50%** across all .shamt workflows through strategic Haiku/Sonnet/Opus selection
2. **Maintain quality** — No degradation in validation rigor, issue detection, or decision-making
3. **Clear guidance** — Provide explicit model selection rules in guides so agents know when to use which model
4. **Phased rollout** — Start with highest-impact workflows (validation loops), then expand
5. **Measurable impact** — Track token usage before/after to validate savings

---

## Detailed Design

### Proposal 1: Model Selection Decision Framework

**Rationale:** Agents need clear rules for when to spawn sub-agents with specific models. Current guides don't mention model selection.

**Decision framework:**

#### Use Haiku (Fast, Cheap) For:
- File operations: create, read for counting, move, copy, delete
- Git operations: branch, commit, status, push, log formatting
- Search operations: grep, glob, file tree exploration
- Template operations: filling known values, creating from templates
- Status updates: Agent Status, STATUS files, checkpoint writes
- Sub-agent confirmations: focused zero-issue re-verification after primary agent validates
- Automated checks: running scripts, counting files, checking file existence
- Cross-reference validation: mechanical link checking (file exists, line number valid)
- Data extraction: extracting commit messages, file lists, timestamps

#### Use Sonnet (Balanced) For:
- Issue classification: LOW/MEDIUM/HIGH/CRITICAL severity assignment
- Separation decisions: generic vs project-specific (medium judgment)
- Drafting: spec/implementation plan initial drafts (before deep validation)
- Structural validation: file size, cross-references, template compliance
- Diff review: import/export diff analysis
- Summarization: ELI5 sections, overview generation
- Integration work: lessons learned integration, cross-feature alignment (medium complexity)
- Pattern analysis: identifying existing architecture patterns, code conventions

#### Use Opus (Deep Reasoning) For:
- Multi-dimensional validation: completeness, correctness, consistency analysis
- Root cause analysis: debugging unknown issues
- Design work: proposals, tradeoffs, implementation planning
- Synthesis: Discovery Phase problem space analysis, gap identification
- Adversarial self-check: challenging own findings in validation loops
- Complex decision-making: workflow choices with significant tradeoffs
- Architectural assessment: impact analysis, system-wide implications
- Code review: issue classification + actionable comment writing
- Empirical verification: validating factual claims (≥3 per round)

**Alternatives considered:**
- **Always use Sonnet as default** — Rejected: misses 20x cost savings on mechanical tasks
- **Let agent decide dynamically** — Rejected: leads to inconsistent choices, need explicit rules
- **Use only Haiku + Opus (skip Sonnet)** — Rejected: Sonnet fills important middle ground

---

### Proposal 2: Guide Audit Sub-Agent Delegation

**Rationale:** Guide Audit is the longest-running validation loop (4.5-6.5 hrs per round, 3 consecutive clean rounds required = 13.5-19.5 hrs total). Current implementation uses single Opus agent for all 23 dimensions.

**New pattern:**

```
Primary Agent (Opus):
├─ Spawn Haiku → Pre-audit checks (D1-D12 automated script)
├─ Spawn Haiku → File counting, cross-reference grep (D13, D14, D15)
├─ Spawn Sonnet → Structural dimensions (D11 file size, D16 versioning, D20 templates)
├─ Primary handles → Content/correctness (D2-D5, D7-D9 accuracy, completeness, consistency)
├─ Primary handles → Adversarial self-check
└─ Spawn 2x Haiku (parallel) → Sub-agent confirmations (zero-issue verification)
```

**Estimated savings:** 40-50% per round (9-12.5 hrs total across 3 rounds)

**Implementation:**
1. Update `.shamt/guides/audit/README.md` to document sub-agent delegation pattern
2. Update `audit_workflow.md` with explicit Task tool calls showing `model` parameter usage
3. Update `audit_checklist.md` to indicate which dimensions use which model
4. Add "Model Selection Notes" section to each dimension's detailed guide

---

### Proposal 3: S5 Implementation Plan Validation Sub-Agent Delegation

**Rationale:** S5 validation is 3.5-6 hours (11 dimensions). Currently uses single Opus agent.

**New pattern:**

```
Primary Agent (Opus):
├─ Spawn Haiku → File existence checks, step numbering, checklist format
├─ Spawn Sonnet → Structural dimensions (testability, clarity, breakdown quality)
├─ Primary handles → Deep analysis (completeness vs spec, correctness, edge cases, cross-feature conflicts)
├─ Primary handles → Empirical verification (≥3 claims) + adversarial self-check
└─ Spawn 2x Haiku (parallel) → Sub-agent confirmations
```

**Estimated savings:** 35-45% per validation (2.2-3.6 hrs)

**Implementation:**
1. Update `.shamt/guides/stages/s5/implementation_planning_workflow.md` with sub-agent pattern
2. Update `validation_checklist.md` to show model assignments per dimension
3. Add explicit Task tool examples with `model: "haiku"` / `model: "sonnet"` parameters

---

### Proposal 4: Sub-Agent Confirmations Always Use Haiku

**Rationale:** Sub-agent confirmations are focused "zero issues" verification tasks after primary agent finds clean round. They re-read artifact looking specifically for issues the primary agent might have missed. This is verification, not deep reasoning.

**Current pattern:**
```
Primary Agent (Opus) → Clean round
├─ Spawn Sub-Agent 1 (Opus) → Confirmation
└─ Spawn Sub-Agent 2 (Opus) → Confirmation
```

**New pattern:**
```
Primary Agent (Opus) → Clean round
├─ Spawn Sub-Agent 1 (Haiku) → Confirmation
└─ Spawn Sub-Agent 2 (Haiku) → Confirmation
```

**Estimated savings:** 70-80% on confirmation tasks (Haiku is ~20x cheaper)

**Workflows affected:**
- S1.P3 Discovery validation (2 sub-agents)
- S2.P1 Spec Refinement (2 sub-agents × 3 gates)
- S5 Implementation Plan validation (2 sub-agents)
- S7.P2 Feature QC validation (2 sub-agents per round)
- S9.P2 Epic QC validation (2 sub-agents per round)
- Design Doc validation (2 sub-agents)
- Implementation validation (2 sub-agents)
- Import post-validation (2 sub-agents)
- Code Review validation (if using sub-agent pattern)

**Implementation:**
1. Update `reference/validation_loop_universal.md` to specify Haiku for confirmations
2. Update all workflow guides that spawn sub-agent confirmations
3. Add explicit `model: "haiku"` parameter to all Task tool examples for confirmations

---

### Proposal 5: Agent Status Updates Use Haiku When Isolated

**Rationale:** Agent Status updates are the most frequent operation (after every major step across all stages). They're mechanical find-and-replace operations.

**Rule:**
- **If updating Agent Status as part of other file work** → Primary agent handles it (avoid context switching)
- **If Agent Status is the only operation** → Spawn Haiku sub-agent

**Example (S2.P1 Step 5):**
```
Primary Agent (Opus) writes spec.md → Also updates Agent Status in spec.md (no delegation)

vs.

Primary Agent (Opus) completes validation → Spawn Haiku to update Agent Status in feature README (isolated operation)
```

**Estimated savings:** 60-70% on isolated status updates

**Implementation:**
1. Update `reference/agent_status_universal.md` with delegation rule
2. Add examples showing when to delegate vs. handle inline
3. Update workflow guides to show Haiku delegation for isolated updates

---

### Proposal 6: Discovery Phase Exploration Uses Haiku

**Rationale:** S1.P3 Discovery Phase starts with 1-4 hours of codebase exploration (file tree, grep, file reads) before synthesis work. Exploration is mechanical; synthesis requires Opus.

**New pattern:**

```
Primary Agent (Opus):
├─ Spawn Haiku → File tree exploration (glob patterns, ls)
├─ Spawn Haiku → Keyword searches (grep for relevant terms)
├─ Spawn Haiku → File counting, dependency extraction
├─ Spawn Sonnet → Architecture pattern analysis
├─ Primary handles → Problem space synthesis, gap identification
├─ Primary writes → DISCOVERY.md
└─ Primary runs → Discovery validation loop (Haiku confirmations)
```

**Estimated savings:** 30-40% on Discovery Phase

**Implementation:**
1. Update `.shamt/guides/stages/s1/discovery_phase_guide.md` with exploration delegation
2. Add explicit Task tool examples for Haiku-based exploration
3. Update `s1_workflow.md` to show phased approach (exploration → synthesis)

---

### Proposal 7: Code Review Workflow Sub-Agent Delegation

**Rationale:** Code review involves mechanical git operations, summarization, and deep issue analysis.

**New pattern:**

```
Primary Agent (Opus):
├─ Spawn Haiku → Git operations (branch fetch, file list, commit messages)
├─ Spawn Sonnet → Overview.md ELI5 section
├─ Primary handles → Issue classification, actionable comments, adversarial self-check
├─ Primary writes → review_vN.md
└─ Spawn Sonnet → Final formatting and file creation
```

**Estimated savings:** 30-40% on code reviews

**Implementation:**
1. Update `.shamt/guides/code_review/code_review_workflow.md` with delegation pattern
2. Add model selection examples to `code_review_checklist.md`
3. Update validation dimensions to show Opus for deep analysis, Sonnet for structure

---

### Proposal 8: Import/Export Mechanical Operations Use Haiku

**Rationale:** Import/export workflows involve script execution, file copying, grep searches, then validation.

**New pattern (Export):**

```
Primary Agent (Sonnet):
├─ Spawn Haiku → Run export script, grep for epic contamination
├─ Primary handles → Generic vs project-specific separation
└─ Delegate to Audit → Full guide audit (uses Proposal 2 delegation)
```

**New pattern (Import):**

```
Primary Agent (Opus):
├─ Spawn Haiku → Run import script, generate diffs
├─ Spawn Sonnet → Read diffs, check supplement accuracy
├─ Primary handles → RULES_FILE.template.md integration, validation loop
└─ Spawn 2x Haiku → Sub-agent confirmations
```

**Estimated savings:** 35-45% on import/export

**Implementation:**
1. Update `.shamt/guides/sync/export_workflow.md` with delegation
2. Update `.shamt/guides/sync/import_workflow.md` with delegation
3. Add Task tool examples showing model parameter usage

---

### Proposal 9: Design Doc Lifecycle Operations

**Rationale:** Design doc lifecycle includes mechanical file operations and deep validation.

**New pattern (Creation):**

```
Primary Agent (Opus):
├─ Spawn Haiku → Read NEXT_NUMBER.txt, increment, create from template
├─ Spawn Sonnet → Problem statement draft, affected files enumeration
└─ Primary writes → Proposals, tradeoffs, implementation plan
```

**New pattern (Validation - 7 dimensions):**

```
Primary Agent (Opus):
├─ Spawn Haiku → Files affected table verification
├─ Spawn Sonnet → Completeness, consistency
├─ Primary handles → Correctness, helpfulness, improvements, missing proposals, open questions
├─ Primary handles → Adversarial self-check
└─ Spawn 2x Haiku → Sub-agent confirmations
```

**New pattern (Implementation Validation - 5 dimensions):**

```
Primary Agent (Opus):
├─ Spawn Haiku → Files affected accuracy check
├─ Spawn Sonnet → Completeness check (proposals vs implementation)
├─ Primary handles → Correctness, no regressions, documentation sync
└─ Spawn 2x Haiku → Sub-agent confirmations
```

**Estimated savings:** 40-50% on design doc validation

**Implementation:**
1. Update `.shamt/guides/design_doc_validation/validation_workflow.md` with delegation
2. Update `master_dev_workflow/master_dev_workflow.md` to show Haiku for file operations
3. Add model selection examples to validation checklists

---

### Proposal 10: Parallel Work STATUS Updates Use Haiku

**Rationale:** Parallel work system requires STATUS file updates every checkpoint (every 15 minutes), handoff package creation, checkpoint writes. All mechanical.

**New pattern:**

```
Secondary Agent (Sonnet) working on feature spec:
├─ Every 15 min → Spawn Haiku for STATUS update + checkpoint write
└─ At handoff → Spawn Haiku for handoff package creation

Primary Agent (Opus) at sync points:
├─ Spawn Haiku → Read all STATUS files
├─ Primary handles → Sync point coordination, stale detection
└─ Spawn Haiku → Update STATUS files post-sync
```

**Estimated savings:** 25-35% on parallel work overhead

**Implementation:**
1. Update `.shamt/guides/parallel_work/parallel_work_system.md` with Haiku delegation
2. Update checkpoint examples to show Task tool with `model: "haiku"`
3. Add STATUS file operation examples with Haiku

---

### Proposal 11: Debugging Protocol Mechanical Operations

**Rationale:** Debugging involves ISSUES_CHECKLIST updates, Agent Status updates, file searches, then analysis.

**New pattern:**

```
Primary Agent (Opus):
├─ Spawn Haiku → ISSUES_CHECKLIST.md updates, Agent Status updates
├─ Spawn Haiku → File searches for error messages, stack traces
├─ Spawn Sonnet → Investigation rounds (hypothesis generation)
├─ Primary handles → Root cause analysis, fix design
└─ Spawn Sonnet → Lessons learned integration
```

**Estimated savings:** 25-30% on debugging

**Implementation:**
1. Update `.shamt/guides/debugging/debugging_protocol.md` with delegation
2. Add Haiku examples for checklist/status operations
3. Update investigation round examples to show Sonnet for hypothesis work

---

### Proposal 12: S10.P1 Guide Updates Use Haiku for File Operations

**Rationale:** S10.P1 mandatory guide updates involve reading current guides, drafting proposals, and creating files.

**New pattern:**

```
Primary Agent (Opus):
├─ Spawn Haiku → Read current guide files, extract relevant sections
├─ Spawn Sonnet → Draft guide update proposals from lessons learned
├─ Primary handles → Generic vs project-specific assessment, export recommendation
└─ Spawn Haiku → Update EPIC_README.md Guide Impact Assessment
```

**Estimated savings:** 30-35% on S10.P1

**Implementation:**
1. Update `.shamt/guides/stages/s10/s10_workflow.md` with delegation
2. Update `guide_updates_mandatory.md` with model selection examples
3. Add Haiku examples for file read/update operations

---

### Proposal 13: Add Model Selection Reference Guide

**Rationale:** All proposals above need a single source of truth for model selection rules.

**New file:** `.shamt/guides/reference/model_selection.md`

**Contents:**
1. Decision framework (Haiku/Sonnet/Opus criteria)
2. Task catalog with model assignments
3. Task tool examples showing `model` parameter
4. Cost/latency comparison table
5. When NOT to delegate (context switching costs)
6. Parallel delegation patterns
7. Common mistakes to avoid

**Implementation:**
1. Create new reference guide
2. Link from all workflow guides that spawn sub-agents
3. Add to audit scope (new dimension or extend existing)

---

## Files Affected

### New Files
| Path | Type | Description |
|------|------|-------------|
| `.shamt/guides/reference/model_selection.md` | New | Model selection decision framework and examples |

### Modified Files - Core Workflows
| Path | Changes |
|------|---------|
| `.shamt/guides/audit/README.md` | Add sub-agent delegation pattern overview |
| `.shamt/guides/audit/audit_workflow.md` | Add Haiku/Sonnet delegation for dimensions, update Task examples |
| `.shamt/guides/audit/audit_checklist.md` | Indicate model per dimension |
| `.shamt/guides/stages/s1/discovery_phase_guide.md` | Add exploration delegation to Haiku |
| `.shamt/guides/stages/s1/s1_workflow.md` | Update Discovery Phase with phased approach |
| `.shamt/guides/stages/s2/s2_workflow.md` | Add Haiku confirmations to spec validation |
| `.shamt/guides/stages/s5/implementation_planning_workflow.md` | Add sub-agent delegation pattern |
| `.shamt/guides/stages/s5/validation_checklist.md` | Show model assignments per dimension |
| `.shamt/guides/stages/s7/s7_workflow.md` | Add Haiku confirmations to P2 QC |
| `.shamt/guides/stages/s9/s9_workflow.md` | Add Haiku confirmations to P2 QC |
| `.shamt/guides/stages/s10/s10_workflow.md` | Add Haiku delegation for file operations |
| `.shamt/guides/stages/s10/guide_updates_mandatory.md` | Add model selection examples |

### Modified Files - Supporting Workflows
| Path | Changes |
|------|---------|
| `.shamt/guides/code_review/code_review_workflow.md` | Add sub-agent delegation pattern |
| `.shamt/guides/code_review/code_review_checklist.md` | Add model selection notes |
| `.shamt/guides/design_doc_validation/validation_workflow.md` | Add Haiku/Sonnet delegation |
| `.shamt/guides/master_dev_workflow/master_dev_workflow.md` | Add Haiku for file operations |
| `.shamt/guides/debugging/debugging_protocol.md` | Add Haiku for checklist/status |
| `.shamt/guides/parallel_work/parallel_work_system.md` | Add Haiku for STATUS/checkpoints |
| `.shamt/guides/sync/export_workflow.md` | Add Haiku for script/grep operations |
| `.shamt/guides/sync/import_workflow.md` | Add Haiku for script/diff generation, confirmations |
| `.shamt/guides/missed_requirement/missed_requirement_protocol.md` | Add Haiku for file operations |

### Modified Files - Universal References
| Path | Changes |
|------|---------|
| `.shamt/guides/reference/validation_loop_universal.md` | Specify Haiku for sub-agent confirmations |
| `.shamt/guides/reference/agent_status_universal.md` | Add delegation rule for isolated updates |
| `.shamt/guides/reference/task_tool_usage.md` | Add `model` parameter examples (if exists) |

### Modified Files - Audit
| Path | Changes |
|------|---------|
| `.shamt/guides/audit/dimensions/*.md` | Add "Model Selection Notes" section to each dimension guide |

**Total:** 1 new file, ~30 modified files

---

## Implementation Plan

### Phase 1: Foundation (2-3 hours)
- [x] Create design doc (SHAMT27_DESIGN.md)
- [ ] Reserve SHAMT-27 number
- [ ] Create validation log (SHAMT27_VALIDATION_LOG.md)
- [ ] Create `feat/SHAMT-27` branch
- [ ] Run design doc validation loop
- [ ] Get user approval to proceed

### Phase 2: Reference Guide (1-2 hours)
- [ ] Create `.shamt/guides/reference/model_selection.md`
- [ ] Write decision framework section
- [ ] Write task catalog with model assignments
- [ ] Add Task tool examples with `model` parameter
- [ ] Add cost/latency comparison table
- [ ] Add "When NOT to delegate" section
- [ ] Add common mistakes section
- [ ] Commit reference guide

### Phase 3: Universal References (1-2 hours)
- [ ] Update `reference/validation_loop_universal.md` (Proposal 4 - Haiku confirmations)
- [ ] Update `reference/agent_status_universal.md` (Proposal 5 - delegation rule)
- [ ] Link model_selection.md from both universal guides
- [ ] Commit universal reference updates

### Phase 4: High-Impact Workflows (4-6 hours)
**Priority order: Highest token savings first**

- [ ] Update Guide Audit workflow (Proposal 2)
  - [ ] `.shamt/guides/audit/README.md`
  - [ ] `.shamt/guides/audit/audit_workflow.md`
  - [ ] `.shamt/guides/audit/audit_checklist.md`
  - [ ] Add "Model Selection Notes" to dimension guides (23 files)
- [ ] Update S5 Implementation Planning (Proposal 3)
  - [ ] `stages/s5/implementation_planning_workflow.md`
  - [ ] `stages/s5/validation_checklist.md`
- [ ] Update Discovery Phase (Proposal 6)
  - [ ] `stages/s1/discovery_phase_guide.md`
  - [ ] `stages/s1/s1_workflow.md`
- [ ] Update Code Review (Proposal 7)
  - [ ] `code_review/code_review_workflow.md`
  - [ ] `code_review/code_review_checklist.md`
- [ ] Commit Phase 4 changes

### Phase 5: Stage Workflows (3-4 hours)
- [ ] Update S2 Spec Refinement (sub-agent confirmations)
  - [ ] `stages/s2/s2_workflow.md`
- [ ] Update S7 Feature QC (sub-agent confirmations)
  - [ ] `stages/s7/s7_workflow.md`
- [ ] Update S9 Epic QC (sub-agent confirmations)
  - [ ] `stages/s9/s9_workflow.md`
- [ ] Update S10 Guide Updates (Proposal 12)
  - [ ] `stages/s10/s10_workflow.md`
  - [ ] `stages/s10/guide_updates_mandatory.md`
- [ ] Commit Phase 5 changes

### Phase 6: Supporting Workflows (2-3 hours)
- [ ] Update Design Doc workflows (Proposal 9)
  - [ ] `design_doc_validation/validation_workflow.md`
  - [ ] `master_dev_workflow/master_dev_workflow.md`
- [ ] Update Import/Export (Proposal 8)
  - [ ] `sync/export_workflow.md`
  - [ ] `sync/import_workflow.md`
- [ ] Update Parallel Work (Proposal 10)
  - [ ] `parallel_work/parallel_work_system.md`
- [ ] Update Debugging Protocol (Proposal 11)
  - [ ] `debugging/debugging_protocol.md`
- [ ] Update Missed Requirement Protocol
  - [ ] `missed_requirement/missed_requirement_protocol.md`
- [ ] Commit Phase 6 changes

### Phase 7: Validation & Audit (5-8 hours)
- [ ] Run full guide audit on entire `.shamt/guides/` tree
  - [ ] Use NEW delegation pattern in audit itself (dogfooding)
  - [ ] Track token usage for comparison
  - [ ] Achieve 3 consecutive clean rounds
- [ ] Fix any audit issues
- [ ] Commit audit fixes

### Phase 8: Implementation Validation (2-3 hours)
- [ ] Run implementation validation loop (5 dimensions)
  - [ ] Completeness: All proposals implemented?
  - [ ] Correctness: Implementation matches design?
  - [ ] Files Affected Accuracy: All files created/modified?
  - [ ] No Regressions: Nothing broken?
  - [ ] Documentation Sync: CLAUDE.md, guides updated?
- [ ] Achieve primary clean + 2 Haiku confirmations
- [ ] Commit any fixes

### Phase 9: Master-Only File Updates (1 hour)
- [ ] Update CLAUDE.md
  - [ ] Add model selection strategy to "Critical Rules" or new section
  - [ ] Link to model_selection.md reference guide
- [ ] Update root README.md (if model selection mentioned)
- [ ] Update `scripts/initialization/RULES_FILE.template.md` (if relevant)
- [ ] Commit master-only updates

### Phase 10: Finalization (1 hour)
- [ ] Archive design doc to `design_docs/archive/SHAMT27_DESIGN.md`
- [ ] Archive validation log to `design_docs/archive/SHAMT27_VALIDATION_LOG.md`
- [ ] Update design doc status to "Implemented"
- [ ] Create PR from `feat/SHAMT-27` to `main`
- [ ] Merge PR
- [ ] Delete feature branch

**Total estimated time:** 22-32 hours (spread across implementation + validation)

---

## Validation Strategy

### During Implementation
1. **Each phase commit:** Verify changes match proposals (self-check)
2. **After Phase 4:** Test guide audit with new delegation (dogfooding)
3. **After Phase 7:** Full guide audit using new patterns (must pass 3 consecutive clean)

### Implementation Validation (Phase 8)
Run 5-dimension implementation validation loop:
1. **Completeness:** Walk through all 13 proposals, verify each is implemented in affected files
2. **Correctness:** Sample 5-10 workflow guides, check Task tool examples have correct `model` parameter
3. **Files Affected Accuracy:** Verify all 30+ files were created/modified as specified
4. **No Regressions:** Verify existing workflow steps still work, no broken references
5. **Documentation Sync:** Check CLAUDE.md references model selection, links to model_selection.md

**Exit criterion:** Primary clean round (≤1 LOW-severity issue) + 2 Haiku sub-agent confirmations

### Post-Merge Validation
1. **Token usage tracking:** Monitor first 3-5 epics/audits using new patterns
2. **Success metrics:**
   - Guide Audit: ≥40% token reduction per round
   - S5 Validation: ≥35% token reduction
   - Sub-agent confirmations: ≥70% token reduction
3. **Quality check:** No increase in issues found by users, validation loops still catch problems

---

## Open Questions

1. **Should we add token usage tracking to validation logs?**
   - Proposal: Add "Token Usage" field to validation log template showing model distribution
   - Benefit: Empirical data on savings
   - Cost: Extra tracking overhead
   - **Decision needed:** User preference

2. **Should model selection be enforced or recommended?**
   - Option A: Guides say "MUST use Haiku for..." (strict)
   - Option B: Guides say "Prefer Haiku for..." (flexible)
   - **Current design:** Option A (strict) for clarity
   - **Decision needed:** User preference for flexibility

3. **Should we create model selection audit dimension?**
   - Proposal: New dimension D24 "Model Selection Compliance" checks if guides properly specify models
   - Benefit: Ensures consistency
   - Cost: Adds dimension to already long audit
   - **Decision needed:** User preference

4. **Should we update parallel work to use mixed models for secondary agents?**
   - Current: All secondary agents use Sonnet (balanced)
   - Proposal: If 5+ features, some secondaries use Haiku for simple specs
   - Complexity: Need logic to assign models based on feature complexity
   - **Decision needed:** Wait for Phase 1 results, revisit in future SHAMT

5. **Should we add cost estimates to implementation plan steps?**
   - Proposal: Show "Estimated tokens: 50K (Opus) + 30K (Sonnet) + 10K (Haiku)" per workflow
   - Benefit: Helps users understand ROI
   - Cost: Extra calculation work, may be inaccurate
   - **Decision needed:** User preference

---

## Risks & Mitigation

### Risk 1: Quality Degradation from Haiku
**Scenario:** Haiku misses issues in sub-agent confirmations that Opus would catch

**Mitigation:**
- Sub-agent confirmations are AFTER primary agent (Opus) validates
- Confirmations are focused "zero issues" checks, not discovery
- If Haiku reports issue, primary agent re-validates
- Monitor first 5 epics/audits for false negatives
- If quality drops: revert Proposal 4, keep other optimizations

**Likelihood:** Low (confirmations are verification, not reasoning)

### Risk 2: Context Switching Overhead
**Scenario:** Spawning many sub-agents slows down overall execution

**Mitigation:**
- Use parallel delegation where possible (2x Haiku confirmations in parallel)
- Don't delegate if primary agent already has context (Agent Status inline updates)
- Measure wall-clock time, not just token cost
- If slower: adjust delegation thresholds in guides

**Likelihood:** Low (parallel spawning minimizes latency)

### Risk 3: Inconsistent Model Selection
**Scenario:** Agents don't follow model selection rules, use wrong models

**Mitigation:**
- Explicit Task tool examples in every workflow guide
- model_selection.md as single source of truth
- Consider audit dimension for compliance (Open Question 3)
- Training period: first 2-3 epics may need user corrections

**Likelihood:** Medium (new pattern, requires learning)

### Risk 4: Haiku Capabilities Change
**Scenario:** Future Haiku version degrades, breaks assumptions

**Mitigation:**
- Document which Haiku capabilities we depend on (file operations, grep, counting)
- Monitor Anthropic model updates
- Have rollback plan: revert to Sonnet for affected tasks
- Most tasks are simple enough that any LLM can handle them

**Likelihood:** Very Low (tasks are basic)

### Risk 5: Over-Optimization Complexity
**Scenario:** Too many model selection rules make guides hard to follow

**Mitigation:**
- Start with clear decision framework (Proposal 1)
- Use consistent patterns (all confirmations = Haiku)
- Don't optimize every single operation (diminishing returns)
- Keep model_selection.md concise and scannable
- If too complex: consolidate rules in future SHAMT

**Likelihood:** Medium (13 proposals touch 30+ files)

### Risk 6: Token Savings Don't Materialize
**Scenario:** Actual savings are <20%, not worth implementation effort

**Mitigation:**
- Phased rollout: measure after Phase 4 (high-impact workflows)
- If <20% savings after Phase 4: pause, reassess
- If ≥30% savings: continue with Phases 5-6
- Post-merge: track 3-5 epics/audits for empirical data
- Document findings in SHAMT27_VALIDATION_LOG.md

**Likelihood:** Low (task analysis shows 30% simple/repetitive = big opportunity)

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-01 | Initial draft created |
