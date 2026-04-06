# Model Selection for Token Optimization

**Purpose:** Guide for strategically selecting Haiku, Sonnet, or Opus models when spawning sub-agents
**Audience:** All agents working in .shamt workflows
**Last Updated:** 2026-04-01
**Version:** 1.0 (SHAMT-27)

---

## 🚨 MANDATORY ENFORCEMENT

**Model selection is not optional — it is mandatory for all workflows.**

When workflow guides specify model delegation patterns (e.g., "Spawn Haiku → File operations"), you **MUST** use the Task tool with the specified model parameter. This is enforced for token optimization and cost efficiency.

**Example workflows with mandatory delegation:**
- Validation loops (S1.P3, S2.P1, S5.V2, S7.P2, S9.P2, S9.P4, S10.P1) - Haiku for sub-agent confirmations (70-80% savings)
- **Architect-Builder Pattern (S6 implementation execution)** - Haiku for mechanical implementation execution (60-70% savings)
- Guide audits (audit/stages/stage_5_loop_decision.md) - Haiku for pre-checks and confirmations (40-50% savings)
- Code reviews (code_review/code_review_workflow.md) - Haiku for git ops, Sonnet for ELI5, Haiku for confirmations (30-40% savings)
- Import workflow (sync/import_workflow.md) - Haiku for diff reading, Haiku for confirmations (20-30% savings)

**See inline Task tool examples in each workflow guide** for copy-paste-ready templates.

---

## Table of Contents

1. [Quick Reference](#quick-reference)
2. [Decision Framework](#decision-framework)
3. [Task Catalog](#task-catalog)
4. [Task Tool Examples](#task-tool-examples)
5. [Cost & Latency Comparison](#cost--latency-comparison)
6. [When NOT to Delegate](#when-not-to-delegate)
7. [Parallel Delegation Patterns](#parallel-delegation-patterns)
8. [Common Mistakes](#common-mistakes)

---

## Quick Reference

### The Three Model Tiers

| Model | Use For | Estimated Cost | Latency | Token Efficiency |
|-------|---------|----------------|---------|------------------|
| **Haiku** | Mechanical operations, file operations, searches, confirmations | ~20x cheaper than Opus | Fastest | 70-80% savings for simple tasks |
| **Sonnet** | Medium complexity analysis, drafting, pattern identification | Balanced | Medium | 40-50% savings for mid-tier tasks |
| **Opus** | Deep reasoning, validation, design, root cause analysis | Most expensive | Slower | Best for complex decision-making |

### Decision Flowchart

```
Is this a sub-agent confirmation task (verifying zero issues)?
├─ YES → Use Haiku
└─ NO ↓

Does the task involve deep reasoning, multi-dimensional validation, or complex decisions?
├─ YES → Use Opus
└─ NO ↓

Is this a mechanical operation (file ops, grep, counting, status updates)?
├─ YES → Use Haiku
└─ NO ↓

Is this medium-complexity analysis (patterns, drafting, classification)?
├─ YES → Use Sonnet
└─ NO → Default to Sonnet (balanced fallback)
```

### 🚨 CRITICAL: How to Use Models in Task Tool

**When you see "Spawn Haiku/Sonnet/Opus" in delegation patterns, this means:**

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>  <!-- Always use this -->
  <parameter name="model">haiku</parameter>  <!-- OR sonnet OR opus -->
  <parameter name="description">Brief description</parameter>
  <parameter name="prompt">Task details...</parameter>
</invoke>
```

**DO NOT use:**
- ❌ `<parameter name="subagent_type">Haiku</parameter>` - This will fail
- ❌ `<parameter name="subagent_type">Sonnet</parameter>` - This will fail
- ❌ `<parameter name="subagent_type">Opus</parameter>` - This will fail

**Available subagent_type values:**
- `general-purpose` - Use this for model delegation (with `model` parameter)
- `Bash` - For bash-specific tasks
- `Explore` - For codebase exploration
- `Plan` - For planning tasks

**The `model` parameter is what controls Haiku/Sonnet/Opus selection, NOT the subagent_type.**

---

## Decision Framework

### Use Haiku (Fast, Cheap) For:

**File Operations:**
- Create, move, copy, delete files
- Read files for counting lines or extracting specific values
- Check file existence
- List directory contents

**Git Operations:**
- Branch creation, checkout
- Commit, push, pull
- Status checks
- Log formatting
- Extract commit messages

**Search Operations:**
- Grep searches for keywords
- Glob patterns for file matching
- File tree exploration
- Directory listing

**Template Operations:**
- Filling templates with known values
- Creating files from templates
- Copying template structures

**Status & Tracking:**
- Agent Status updates
- STATUS file updates
- Checkpoint writes
- Progress tracking

**Sub-Agent Confirmations:**
- Zero-issue verification after primary validation
- Re-reading artifacts to confirm no missed issues
- Focused verification tasks

**Automated Checks:**
- Running pre-audit check scripts
- Counting files, lines, occurrences
- Checking cross-references (file exists, line number valid)

**Data Extraction:**
- Extracting commit messages
- Generating file lists
- Pulling timestamps or metadata

**Examples:**
- Reading file to count lines → **Haiku**
- Running `grep` to find keyword → **Haiku**
- Updating "Agent Status: Step 3 complete" → **Haiku**
- Sub-agent confirming zero issues after primary validation → **Haiku**
- Creating handoff package file from template → **Haiku**

---

### Use Sonnet (Balanced) For:

**Issue Classification:**
- Assigning severity levels (LOW/MEDIUM/HIGH/CRITICAL)
- Categorizing problems
- Triaging issues

**Separation Decisions:**
- Generic vs project-specific assessment
- Determining what belongs in shared guides vs child-specific
- Medium-judgment calls

**Drafting:**
- Initial spec drafts
- Implementation plan first pass (before deep validation)
- Summary creation

**Structural Validation:**
- File size assessment
- Cross-reference checking (does structure make sense?)
- Template compliance verification

**Diff Review:**
- Import/export diff analysis
- Change impact assessment
- Conflict detection

**Summarization:**
- ELI5 sections
- Overview generation
- Code change summaries

**Integration Work:**
- Lessons learned integration (medium complexity)
- Cross-feature alignment (not deep conflicts)
- Connecting related artifacts

**Pattern Analysis:**
- Identifying existing architecture patterns
- Recognizing code conventions
- Finding structural similarities

**Examples:**
- Reading file to identify architectural patterns → **Sonnet**
- Deciding if guide change is generic or project-specific → **Sonnet**
- Writing ELI5 summary of code changes → **Sonnet**
- Classifying issue severity → **Sonnet**
- Creating initial feature spec draft → **Sonnet**

---

### Use Opus (Deep Reasoning) For:

**Multi-Dimensional Validation:**
- Completeness analysis
- Correctness verification
- Consistency checking
- All validation loop primary rounds

**Root Cause Analysis:**
- Debugging unknown issues
- Investigating cascading failures
- Deep investigation rounds

**Design Work:**
- Writing proposals
- Analyzing tradeoffs
- Implementation planning
- Architectural decisions

**Synthesis:**
- Discovery Phase problem space analysis
- Gap identification
- Connecting disparate information

**Adversarial Self-Check:**
- Challenging own findings in validation loops
- Looking for missed issues
- Critical review

**Complex Decision-Making:**
- Workflow choices with significant tradeoffs
- Multi-factor optimization
- Strategy selection

**Architectural Assessment:**
- System-wide impact analysis
- Cross-cutting concerns
- Integration complexity

**Code Review:**
- Issue classification + actionable comment writing
- Deep code analysis
- Security/performance implications

**Empirical Verification:**
- Validating factual claims (≥3 per round)
- Checking accuracy of references
- Verifying implementation matches spec

**Examples:**
- Validating implementation plan completeness against spec → **Opus**
- Analyzing why bug occurs across multiple systems → **Opus**
- Deciding between 3 architectural approaches with tradeoffs → **Opus**
- Running primary validation round (before sub-agent confirmations) → **Opus**
- Writing design doc proposals → **Opus**

---

## Task Catalog

### By Workflow

#### Guide Audit
| Task | Model | Rationale |
|------|-------|-----------|
| Pre-audit checks script | Haiku | Automated script execution |
| File counting, grep | Haiku | Mechanical operations |
| D11 file size, D12 structural patterns | Sonnet | Structural analysis |
| D2-D5, D7-D9 content/correctness | Opus | Deep validation |
| Adversarial self-check | Opus | Critical review |
| Sub-agent confirmations | Haiku | Zero-issue verification |

#### S5 Implementation Plan Validation
| Task | Model | Rationale |
|------|-------|-----------|
| File existence checks | Haiku | Mechanical verification |
| Step numbering, format | Haiku | Structural checking |
| Testability, clarity | Sonnet | Medium-complexity assessment |
| Completeness vs spec | Opus | Deep validation |
| Edge cases, conflicts | Opus | Complex analysis |
| Empirical verification | Opus | Fact-checking |
| Sub-agent confirmations | Haiku | Zero-issue verification |

#### Discovery Phase (S1.P3)
| Task | Model | Rationale |
|------|-------|-----------|
| File tree exploration | Haiku | Directory listing |
| Keyword searches | Haiku | Grep operations |
| File counting | Haiku | Mechanical counting |
| Architecture pattern analysis | Sonnet | Pattern recognition |
| Problem space synthesis | Opus | Deep synthesis |
| Gap identification | Opus | Complex analysis |
| Sub-agent confirmations | Haiku | Zero-issue verification |

#### Code Review
| Task | Model | Rationale |
|------|-------|-----------|
| Git operations (fetch, list files) | Haiku | Git commands |
| ELI5 section | Sonnet | Summarization |
| Issue classification | Opus | Deep analysis + actionable comments |
| Adversarial self-check | Opus | Critical review |
| Final formatting | Sonnet | Structural work |

#### Import/Export
| Task | Model | Rationale |
|------|-------|-----------|
| Run scripts | Haiku | Script execution |
| Grep for contamination | Haiku | Search operation |
| Generate diffs | Haiku | Automated diff creation |
| Generic vs specific separation | Sonnet | Medium judgment |
| Diff review | Sonnet | Change analysis |
| RULES_FILE integration | Opus | Complex decision-making |
| Validation loop | Opus | Deep validation |
| Sub-agent confirmations | Haiku | Zero-issue verification |

#### Parallel Work
| Task | Model | Rationale |
|------|-------|-----------|
| STATUS file updates | Haiku | Mechanical text replacement |
| Checkpoint writes | Haiku | File operations |
| Handoff package creation | Haiku | Template + data copying |
| Sync point coordination | Opus | Complex coordination |
| Stale agent detection | Opus | Decision-making |

#### Architect-Builder Pattern (SHAMT-30)
| Task | Model | Rationale |
|------|-------|-----------|
| Plan creation (Architect) | Sonnet/Opus | Design + spec translation |
| Plan validation (9 dimensions) | Opus | Deep validation |
| Implementation execution (Builder) | Haiku | Mechanical file operations (MANDATORY) |
| Sub-agent confirmations | Haiku | Zero-issue verification |
| Error diagnosis (Architect) | Sonnet/Opus | Root cause analysis |

**Key Insight:** Builder execution is the highest token-saving opportunity (60-70% reduction). Always use Haiku for builder agents.

**See:** `reference/architect_builder_pattern.md` for complete pattern documentation.

---

## Task Tool Examples

### Example 1: Haiku for File Counting

**Scenario:** During Guide Audit, need to count how many dimension files exist.

**Task Tool Call:**
```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="description">Count dimension guide files</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="prompt">Count the number of dimension guide files in .shamt/guides/audit/dimensions/ (exclude example files like d10_examples.md and d16_examples.md).

Use: ls .shamt/guides/audit/dimensions/ | grep "^d[0-9]" | grep -v example | wc -l

Report the count.</parameter>
</invoke>
```

**Why Haiku:** Simple file counting operation, mechanical task.

---

### Example 2: Sonnet for Issue Classification

**Scenario:** During S7 QC, need to classify issues found.

**Task Tool Call:**
```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="description">Classify issue severity</parameter>
  <parameter name="model">sonnet</parameter>
  <parameter name="prompt">Read the following issue and classify its severity as CRITICAL, HIGH, MEDIUM, or LOW using the criteria from reference/severity_classification_universal.md:

Issue: "The spec.md file references a function `calculateTotal()` but the implementation calls it `computeTotal()`"

Provide classification with rationale.</parameter>
</invoke>
```

**Why Sonnet:** Requires judgment and understanding of severity criteria, medium complexity.

---

### Example 3: Opus for Validation Round

**Scenario:** Running S5 implementation plan validation primary round.

**Task Tool Call:**
```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="description">Validate implementation plan</parameter>
  <parameter name="model">opus</parameter>
  <parameter name="prompt">Read the implementation plan at epics/requests/{epic}/features/{feature}/implementation_plan.md and validate it against all 11 dimensions from stages/s5/s5_v2_validation_loop.md.

Check:
1. Completeness vs spec
2. Correctness
3. Testability
4. Edge cases
5. Dependencies
... (all 11 dimensions)

Report all issues found with severity classification. This is a primary validation round.</parameter>
</invoke>
```

**Why Opus:** Deep multi-dimensional validation requiring complex analysis.

---

### Example 3a: Haiku for Builder Execution (Architect-Builder Pattern)

**Scenario:** S6 implementation execution using architect-builder pattern (SHAMT-30).

**Task Tool Call:**
```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="description">Execute implementation plan</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="prompt">You are a builder agent. Your role is to execute the implementation plan exactly as specified.

**Plan Location:** `.shamt/epics/{epic}/features/{feature}/implementation_plan.md`

**Your Responsibilities:**
1. Read the implementation plan file
2. Execute each step in sequential order (Step 1, 2, 3...)
3. Verify each step as specified
4. Report completion or halt on first error
5. DO NOT make design decisions or deviate from plan
6. DO NOT spawn sub-agents or parallelize work

**Error Handling Protocol:**
- If a step fails, STOP immediately - do not proceed to next step
- Report back to architect with:
  - Step number where error occurred
  - Exact error message received
  - Which verification failed (if applicable)
  - Current state (what was completed before error)
- Do NOT attempt retries, fixes, or workarounds
- Do NOT skip failed steps and continue
- Wait for architect instructions

**Start by reading the implementation plan, then execute it step by step.**</parameter>
</invoke>
```

**Why Haiku:** Builder execution is mechanical - following exact locate/replace instructions without design decisions. Haiku excels at this and provides 60-70% token savings compared to Sonnet/Opus executing the same steps.

**See:** `reference/architect_builder_pattern.md` for complete handoff package format and error recovery protocol.

---

### Example 4: Haiku for Sub-Agent Confirmation

**Scenario:** After primary validation round achieves clean status, spawn confirmations.

**Task Tool Call (spawn 2 in parallel):**
```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="description">Confirm zero issues</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="prompt">You are a sub-agent tasked with confirming zero issues in the implementation plan.

Read epics/requests/{epic}/features/{feature}/implementation_plan.md and verify against all 11 dimensions.

IMPORTANT: Report ANY issue found, even LOW severity. If zero issues found, state "CONFIRMED: Zero issues found".</parameter>
</invoke>
```

**Why Haiku:** Focused verification task after primary validation, 70-80% cost savings.

---

### Example 5: Parallel Delegation (Mixed Models)

**Scenario:** Discovery Phase needs exploration + synthesis.

**Task Tool Calls (parallel):**
```xml
<!-- Haiku for file tree exploration -->
<invoke name="Task">
  <parameter name="subagent_type">Explore</parameter>
  <parameter name="description">Explore codebase structure</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="prompt">List all files in src/ directory and identify main module structure. Report folder organization and key file types found.</parameter>
</invoke>

<!-- Haiku for keyword searches -->
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="description">Search for authentication code</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="prompt">Use grep to search for "auth" or "login" keywords across codebase. Report files containing authentication-related code.</parameter>
</invoke>

<!-- Opus for synthesis (runs after exploration) -->
<!-- This would be called sequentially after the above complete -->
```

**Why Mixed:** Haiku handles mechanical exploration, Opus synthesizes findings into insights.

---

## Cost & Latency Comparison

### Estimated Token Cost Multipliers

Based on typical Anthropic pricing (relative to Opus as baseline):

| Model | Relative Input Cost | Relative Output Cost | Use Case Efficiency |
|-------|---------------------|----------------------|---------------------|
| Haiku | ~20x cheaper | ~20x cheaper | Best for simple tasks (70-80% savings) |
| Sonnet | ~5x cheaper | ~5x cheaper | Good for medium tasks (40-50% savings) |
| Opus | 1x (baseline) | 1x (baseline) | Best for complex tasks (no waste) |

### Latency Characteristics

| Model | Time to First Token | Total Generation Time | Best For |
|-------|---------------------|------------------------|----------|
| Haiku | Fastest (~1-2s) | Fastest | Quick operations, confirmations |
| Sonnet | Medium (~2-4s) | Medium | Balanced workflows |
| Opus | Slower (~3-6s) | Slowest (highest quality) | Deep analysis, validation |

### Real-World Savings Examples

**Guide Audit (23 dimensions, 4.5-6.5 hrs/round):**
- **Before:** All Opus = 100% cost
- **After (SHAMT-27):** Mixed delegation = ~50-60% cost
- **Savings:** 40-50% per round
- **Impact:** 3 rounds = 13.5-19.5 hrs → save ~6-10 hours of Opus tokens

**S5 Implementation Plan Validation (9 dimensions, 3.5-6 hrs):**
- **Before:** All Opus = 100% cost
- **After:** Mixed delegation = ~55-65% cost
- **Savings:** 35-45% per validation
- **Impact:** Per feature validation = ~1.5-2.5 hrs token savings

**Sub-Agent Confirmations (used in S1, S2, S5, S7, S9, design doc, import):**
- **Before:** 2x Opus confirmations = 100% cost
- **After:** 2x Haiku confirmations = ~5% cost
- **Savings:** ~95% (70-80% typical accounting for task overhead)
- **Impact:** Every validation loop saves significant tokens

---

## When NOT to Delegate

### Context Switching Costs

**DON'T delegate if:**

1. **Primary agent already has context**
   - Example: You just read `spec.md`, don't spawn Haiku to update Agent Status in the same file
   - Reason: Context switching overhead exceeds Haiku savings for tiny tasks

2. **Task is part of larger operation**
   - Example: Don't spawn separate agents for each line in a file you're already editing
   - Reason: Spawning 10 agents costs more than doing the work inline

3. **Result needed immediately for next step**
   - Example: Don't spawn Haiku to read a file if you need to analyze it in the next sentence
   - Reason: Sequential dependency creates latency; better to do it yourself

4. **Task is trivial (<10 tokens)**
   - Example: Updating single field in STATUS file when you're already writing to it
   - Reason: Tool call overhead exceeds work itself

### When to Delegate Anyway

**DO delegate even with context if:**

1. **Agent Status is isolated operation**
   - Primary agent finished work, only needs to update status → spawn Haiku
   - Reason: 60-70% savings on isolated updates

2. **Multiple independent operations possible**
   - Can spawn 3 Haiku agents in parallel for file ops while Opus does analysis
   - Reason: Parallelization reduces wall-clock time

3. **Sub-agent confirmations**
   - ALWAYS use Haiku for confirmations (per SHAMT-27 design)
   - Reason: 70-80% savings, no quality degradation

### Decision Rule

```
IF (task takes <30 seconds AND primary agent has context)
  → Do it inline
ELSE IF (task is mechanical OR sub-agent confirmation)
  → Delegate to Haiku
ELSE IF (task is medium complexity)
  → Delegate to Sonnet
ELSE IF (task is deep reasoning)
  → Delegate to Opus
```

---

## Parallel Delegation Patterns

### Pattern 1: Parallel Exploration (Discovery Phase)

**Scenario:** Need to explore codebase from multiple angles.

**Pattern:**
```
Primary Agent (Opus):
├─ Spawn Haiku #1 → File tree (src/)
├─ Spawn Haiku #2 → File tree (tests/)
├─ Spawn Haiku #3 → Grep for "authentication"
├─ Spawn Haiku #4 → Grep for "database"
└─ (all in parallel, single message with 4 Task calls)

[Wait for all 4 results]

Primary Agent synthesizes findings → DISCOVERY.md
```

**Benefit:** 4x parallel exploration, ~70% cost savings on exploration phase.

---

### Pattern 2: Parallel Confirmations (Validation Loops)

**Scenario:** Primary round is clean, need 2 sub-agent confirmations.

**Pattern:**
```
Primary Agent (Opus):
[Completed primary validation, consecutive_clean = 1]

├─ Spawn Haiku Sub-Agent #1 → Confirm zero issues
└─ Spawn Haiku Sub-Agent #2 → Confirm zero issues
   (both in parallel, single message with 2 Task calls)

[Wait for both results]

IF both confirm zero issues:
  → Exit validation (success)
ELSE:
  → Reset consecutive_clean = 0, fix issues, run new round
```

**Benefit:** 70-80% cost savings on confirmations, no latency penalty (parallel).

---

### Pattern 3: Mixed-Model Workflow (Guide Audit)

**Scenario:** Audit round needs mechanical checks + deep validation.

**Pattern:**
```
Primary Agent (Opus):
├─ Spawn Haiku → Pre-audit script (D1-D12 automated)
├─ Spawn Haiku → File counting (D13, D14, D15)
├─ Spawn Sonnet → Structural checks (D11, D12, D16)
   (all 3 in parallel)

[Wait for results]

Primary Agent (Opus):
├─ Run content/correctness dimensions (D2-D5, D7-D9)
└─ Adversarial self-check

IF consecutive_clean = 1:
  ├─ Spawn Haiku Sub-Agent #1 → Confirm
  └─ Spawn Haiku Sub-Agent #2 → Confirm
     (parallel)
```

**Benefit:** 40-50% cost savings per round, maintains quality.

---

### Pattern 4: Sequential with Intermediate Delegation

**Scenario:** S5 validation requires file checks before deep validation.

**Pattern:**
```
Primary Agent (Opus):
Step 1: Spawn Haiku → Verify all files in implementation plan exist

[Wait for result]

IF files missing:
  → Report issue, cannot proceed
ELSE:
  → Continue to deep validation

Primary Agent (Opus):
Step 2: Run 11-dimension validation (Opus handles all)

IF consecutive_clean = 1:
  ├─ Spawn Haiku Sub-Agent #1
  └─ Spawn Haiku Sub-Agent #2
```

**Benefit:** Early failure detection with cheap Haiku, Opus reserved for deep work.

---

## Common Mistakes

### Mistake 1: Using Haiku for Decision-Making

**Wrong:**
```xml
<invoke name="Task">
  <parameter name="model">haiku</parameter>
  <parameter name="prompt">Decide whether this guide change should be exported to master or kept child-specific. Analyze the change and make a recommendation.</parameter>
</invoke>
```

**Why Wrong:** Generic vs project-specific separation requires **medium judgment** → Use Sonnet.

**Correct:**
```xml
<invoke name="Task">
  <parameter name="model">sonnet</parameter>
  <parameter name="prompt">Decide whether this guide change should be exported to master or kept child-specific. Analyze the change and make a recommendation.</parameter>
</invoke>
```

---

### Mistake 2: Using Opus for File Counting

**Wrong:**
```xml
<invoke name="Task">
  <parameter name="model">opus</parameter>
  <parameter name="prompt">Count the number of files in .shamt/guides/stages/</parameter>
</invoke>
```

**Why Wrong:** Mechanical counting operation → Use Haiku (20x cheaper, same result).

**Correct:**
```xml
<invoke name="Task">
  <parameter name="model">haiku</parameter>
  <parameter name="prompt">Count files in .shamt/guides/stages/ using ls | wc -l</parameter>
</invoke>
```

---

### Mistake 3: Using Sonnet for Sub-Agent Confirmations

**Wrong:**
```xml
<invoke name="Task">
  <parameter name="model">sonnet</parameter>
  <parameter name="prompt">Confirm zero issues in the implementation plan after primary validation.</parameter>
</invoke>
```

**Why Wrong:** Sub-agent confirmations are **focused verification** → Always use Haiku (70-80% savings, no quality loss).

**Correct:**
```xml
<invoke name="Task">
  <parameter name="model">haiku</parameter>
  <parameter name="prompt">Confirm zero issues in the implementation plan. Report ANY issue found, even LOW severity.</parameter>
</invoke>
```

---

### Mistake 4: Spawning Many Agents Sequentially When Could Be Parallel

**Wrong:**
```
[Spawn Haiku #1, wait for result]
[Spawn Haiku #2, wait for result]
[Spawn Haiku #3, wait for result]
```

**Why Wrong:** Sequential spawning adds latency. Each spawn waits for previous to complete.

**Correct:**
```xml
<!-- Single message with 3 Task calls -->
<invoke name="Task">
  <parameter name="model">haiku</parameter>
  <parameter name="prompt">Task 1</parameter>
</invoke>
<invoke name="Task">
  <parameter name="model">haiku</parameter>
  <parameter name="prompt">Task 2</parameter>
</invoke>
<invoke name="Task">
  <parameter name="model">haiku</parameter>
  <parameter name="prompt">Task 3</parameter>
</invoke>
```

**Benefit:** All 3 run in parallel, results come back together.

---

### Mistake 5: Over-Delegating Trivial Operations

**Wrong:**
```
Primary Agent reads spec.md (already in context)
↓
Spawn Haiku to update "Agent Status: Step 3" in spec.md
↓
Context switch cost > savings
```

**Why Wrong:** Primary agent already has spec.md context. Spawning Haiku adds overhead for trivial 1-line update.

**Correct:**
```
Primary Agent reads spec.md
↓
Primary Agent updates Agent Status inline (5 seconds of work)
↓
No context switch, faster completion
```

**Rule:** Only delegate Agent Status if it's an **isolated operation** (primary agent isn't already working with the file).

---

### Mistake 6: Using Wrong Model for Primary Validation Rounds

**Wrong:**
```xml
<!-- Primary validation round -->
<invoke name="Task">
  <parameter name="model">sonnet</parameter>
  <parameter name="prompt">Run full 11-dimension validation on implementation plan. This is the primary round.</parameter>
</invoke>
```

**Why Wrong:** Primary validation rounds require **deep multi-dimensional analysis** → Must use Opus.

**Correct:**
```xml
<invoke name="Task">
  <parameter name="model">opus</parameter>
  <parameter name="prompt">Run full 11-dimension validation on implementation plan. This is the primary round.</parameter>
</invoke>
```

**Note:** Sub-agent confirmations (after primary) use Haiku, but primary always uses Opus.

---

## Workflow Guide Cross-References

Each workflow guide includes inline Task tool examples with copy-paste-ready XML. Refer to these guides for context-specific delegation patterns:

### Core Validation Loops (Haiku Sub-Agent Confirmations)

**Stage Guides (S1-S10):**
- `stages/s1/s1_p3_discovery_phase.md` — Discovery validation sub-agent confirmation
- `stages/s2/s2_p1_spec_creation_refinement.md` — Spec validation sub-agent confirmation
- `stages/s5/s5_v2_validation_loop.md` — Implementation plan validation (9 mechanical dimensions) + Model Selection section
- `stages/s7/s7_p2_qc_rounds.md` — Feature QC validation (17 dimensions)
- `stages/s8/s8_p1_cross_feature_alignment.md` — Alignment validation
- `stages/s9/s9_p2_epic_qc_rounds.md` — Epic QC validation (13 dimensions)
- `stages/s9/s9_p4_epic_final_review.md` — Epic final review (5 categories)
- `stages/s10/s10_p1_guide_update_workflow.md` — Proposal doc verification

**Master Protocol:**
- `reference/validation_loop_master_protocol.md` — Sub-Agent Confirmation Protocol with Task tool XML

### Specialized Workflows

**Audit (40-50% savings):**
- `audit/README.md` — Model selection overview + inline examples (file counting, sub-agent confirmation)
- `audit/stages/stage_5_loop_decision.md` — Exit criteria sub-agent confirmation (2x Haiku)

**Code Review (30-40% savings):**
- `code_review/code_review_workflow.md` — 4 Task tool examples:
  - Git operations (Haiku)
  - ELI5 generation (Sonnet)
  - Overview validation sub-agent confirmation (Haiku)
  - Review validation sub-agent confirmation (Haiku)

**Design Doc Validation (20-30% savings):**
- `design_doc_validation/validation_workflow.md` — 7-dimension validation sub-agent confirmation (Haiku)

**Import Workflow (20-30% savings):**
- `sync/import_workflow.md` — Post-import validation sub-agent confirmation (Haiku)

**Shamt Lite (Standalone):**
- `scripts/initialization/SHAMT_LITE.template.md` — Pattern 1 sub-agent confirmation Task tool example

**Architect-Builder Pattern (60-70% savings):**
- `reference/architect_builder_pattern.md` — Pattern overview, handoff package format, Task tool invocation
- `reference/implementation_plan_format.md` — Plan format specification
- `stages/s6/s6_execution.md` — S6 builder handoff workflow (MANDATORY in epic workflow)

**All inline examples follow the standard template:**
```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>  <!-- or sonnet/opus -->
  <parameter name="description">Brief task description</parameter>
  <parameter name="prompt">Detailed prompt with context...</parameter>
</invoke>
```

---

## Standard Templates

The following templates are used across all workflow guides. Copy-paste and adapt for your context.

### Template 1: Sub-Agent Confirmation (Haiku)

**Use:** After primary clean round in validation loops (S1-S10, audit, code review, design doc, import)

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Confirm zero issues (sub-agent A)</parameter>
  <parameter name="prompt">You are sub-agent A confirming zero issues after primary validation.

**Artifact to validate:** {path_or_description}
**Validation dimensions:** {list all dimensions being checked}
**Your task:** Re-read the entire artifact and verify ALL dimensions.

CRITICAL: Report ANY issue found, even LOW severity. If zero issues found, state "CONFIRMED: Zero issues found".

**Context:**
- {relevant context about what was validated}
  </parameter>
</invoke>

<!-- Spawn sub-agent B with identical prompt, changing only "sub-agent A" → "sub-agent B" -->
```

**Why Haiku?** Sub-agent confirmations are focused verification (70-80% token savings). Always use Haiku for confirmations.

### Template 2: Git Operations (Haiku)

**Use:** Branch fetching, file listing, commit history

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Fetch branch and get file list</parameter>
  <parameter name="prompt">Fetch the branch and list changed files.

**Branch:** {branch_name}
**Base branch:** main

Commands to run:
1. git fetch origin {branch_name}
2. git diff --name-only $(git merge-base main {branch_name}) {branch_name}
3. git log main..{branch_name} --oneline

Report: Fetch status, file list, commit messages
  </parameter>
</invoke>
```

**Why Haiku?** Git operations are mechanical (70-80% token savings).

### Template 3: File Counting/Mechanical Operations (Haiku)

**Use:** Counting files, checking existence, simple grep patterns

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Count {what you're counting}</parameter>
  <parameter name="prompt">Count {description of task}.

Command: {specific command or pattern}

Report: {what to report back}
  </parameter>
</invoke>
```

**Why Haiku?** Counting and mechanical operations don't require deep reasoning (70-80% token savings).

### Template 4: Medium Complexity Analysis (Sonnet)

**Use:** ELI5 generation, pattern identification, classification

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">sonnet</parameter>
  <parameter name="description">Generate {artifact} or classify {thing}</parameter>
  <parameter name="prompt">{Description of analytical task requiring medium complexity reasoning}

**Input:** {what you're analyzing}
**Requirements:** {specific requirements}
**Output:** {what format to produce}
  </parameter>
</invoke>
```

**Why Sonnet?** Medium-complexity analysis requires more than mechanical operations but not deep multi-dimensional validation (40-50% token savings vs Opus).

### Template 5: Deep Validation (Opus)

**Use:** Primary validation rounds, multi-dimensional checks, complex decisions

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">opus</parameter>
  <parameter name="description">Validate {artifact} (primary round)</parameter>
  <parameter name="prompt">Run full {N}-dimension validation on {artifact}.

**Dimensions to check:**
1. {Dimension 1}
2. {Dimension 2}
...
{N}. {Dimension N}

**Your task:** Read the artifact, check ALL dimensions, classify issues by severity, fix issues immediately.

This is a primary validation round.
  </parameter>
</invoke>
```

**Why Opus?** Deep multi-dimensional validation requires complex reasoning and pattern recognition. Use Opus for primary rounds, Haiku for sub-agent confirmations.

---

## Summary

**Key Principles:**

1. **Haiku for mechanical operations** — File ops, grep, counting, status updates, sub-agent confirmations
2. **Sonnet for medium complexity** — Drafting, classification, pattern analysis, separation decisions
3. **Opus for deep reasoning** — Validation, design, root cause, complex decisions, adversarial self-check
4. **Always Haiku for sub-agent confirmations** — 70-80% savings, no quality degradation
5. **Parallel delegation when independent** — Use single message with multiple Task calls
6. **Don't over-delegate** — If primary agent has context and task is trivial, do it inline

**Expected Impact:**

- **Guide Audit:** 40-50% token savings per round
- **S5 Validation:** 35-45% token savings
- **Sub-Agent Confirmations:** 70-80% savings
- **Overall Workflows:** 30-50% reduction in token costs

**Next Steps:**

- Apply these patterns in your workflows
- Track token usage to validate savings
- Adjust model selection based on task complexity
- Report any edge cases or pattern improvements

---

**References:**

- Design Doc: `design_docs/archive/SHAMT27_DESIGN.md`
- Severity Classification: `reference/severity_classification_universal.md`
- Validation Loop Protocol: `reference/validation_loop_master_protocol.md`
