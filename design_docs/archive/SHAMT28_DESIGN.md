# SHAMT-28: Standalone Lightweight Rules File

**Status:** Validated
**Created:** 2026-04-01
**Branch:** `feat/SHAMT-28`
**Validation Log:** [SHAMT28_VALIDATION_LOG.md](./SHAMT28_VALIDATION_LOG.md)

---

## Problem Statement

Shamt provides powerful validation loops, discovery processes, and quality gates, but the full S1-S10 epic workflow is heavyweight for many projects. Developers want the core beneficial patterns (validation rigor, discovery discipline, code review standardization) without committing to the full epic management system.

Currently, adopting Shamt is all-or-nothing: you either use the entire `.shamt/` folder structure with 10-stage workflow, or you don't use Shamt at all. This prevents adoption by teams who would benefit from specific Shamt patterns but don't need comprehensive epic lifecycle management.

---

## Goals

1. Create a standalone rules file (`SHAMT_LITE.md`) capturing the most universally valuable Shamt patterns
2. Support projects that want validation discipline without epic workflow overhead
3. Keep total artifact count to 10 files or fewer (rules file + minimal supporting references)
4. Enable gradual Shamt adoption (start with lite, upgrade to full if needed)
5. Maintain compatibility with full Shamt (lite projects can upgrade without conflicts)

**Non-Goals:**
- Replace the full Shamt system (full system remains the primary offering)
- Support all Shamt features in lite mode (intentionally limited scope)
- Require reading full Shamt guides to use lite mode (SHAMT_LITE.md must be standalone and executable on its own)

---

## Detailed Design

### Proposal 1: Core Rules File Structure

Create `SHAMT_LITE.md` as a **standalone, executable rules file** containing complete instructions for 5 key patterns:

1. **Validation Loop Mechanics** - Complete step-by-step process for running validation rounds with consecutive clean tracking and exit criteria
2. **Severity Classification** - Full 4-level system (CRITICAL/HIGH/MEDIUM/LOW) with decision tree and examples
3. **Discovery Protocol** - Complete process for structured requirements exploration with question brainstorming framework
4. **Code Review Process** - Full standalone review workflow with validation dimensions
5. **Question Brainstorming** - Complete 6-category framework with examples for each category

**Key Principle:** SHAMT_LITE.md must be **executable without reading any supporting files**. An agent should be able to run validation loops, perform discovery, and conduct code reviews using ONLY the instructions in SHAMT_LITE.md. Supporting files add depth and detail but are not required for basic usage.

**Rationale:** These five patterns are independently valuable and don't require epic workflow infrastructure. Making them fully standalone in one file ensures maximum accessibility and ease of adoption.

**Alternative Considered:** Separate file per pattern - rejected because it violates the <10 files constraint and creates management overhead. Index-style rules file with "see reference X" - rejected because it requires reading multiple files to understand any single pattern.

---

### Proposal 2: Supporting Reference Files (Optional Depth)

Include **optional** reference files that enhance the core rules:

```
shamt-lite/
├── SHAMT_LITE.md                              (standalone, executable rules - TIER 1)
├── reference/                                 (optional depth - TIER 2)
│   ├── severity_classification.md             (extended severity examples and edge cases)
│   ├── validation_exit_criteria.md            (advanced clean round mechanics and tracking)
│   └── question_brainstorm_categories.md      (detailed question examples per category)
└── templates/                                 (output formats - TIER 3)
    ├── discovery_template.md                  (discovery document structure)
    └── code_review_template.md                (review output format)
```

**Total: 6 files** (1 rules + 2 templates + 3 references)

**File Tier Structure:**
- **Tier 1 (SHAMT_LITE.md):** Standalone and complete - agent can execute all 5 patterns without reading anything else
- **Tier 2 (reference/):** Optional enhancements - add detail, examples, and edge case handling for users who want more rigor
- **Tier 3 (templates/):** Output formats - provide structure for artifacts created during pattern execution

**Rationale:** SHAMT_LITE.md contains simplified but complete versions of each pattern. Reference files are truly optional - they flesh out capabilities but aren't required for basic usage. This approach balances completeness (everything in one file) with navigability (detail available when needed).

**Alternative Considered:** Make SHAMT_LITE.md an index that requires reading references - rejected because it violates the standalone principle. Inline all content in SHAMT_LITE.md - rejected because it would create a 3000+ line file. Current approach provides best balance: core instructions standalone, depth available optionally.

**Master vs Runtime Structure:**

The file structure shown above represents the **runtime structure** deployed to user projects (in `shamt-lite/` folder). In the master Shamt repo, these files are stored as templates/references at `.shamt/scripts/initialization/` and deployed by the init script. The Files Affected section (below) documents the master repo structure, while this proposal documents the user-facing runtime structure.

---

### Proposal 3: Validation Loop Adaptation

Extract validation loop mechanics from full Shamt but adapt for standalone use:

**Full Shamt:** Validation loops are context-specific (S5 implementation plans, S7 feature specs, guide audits, etc.) with different dimensions and exit criteria per context.

**Lite Version:** Generic validation loop with:
- Universal consecutive_clean counter (0-1 for lite, 0-3 for guide audits in full Shamt)
- Severity classification (identical to full Shamt)
- Exit criteria: Primary clean round (≤1 LOW issue) + 2 sub-agent confirmations
- Applicable to any artifact (design docs, specs, plans, documentation)

**Key Differences from Full Shamt:**
- Lite uses 1 consecutive clean round + sub-agent confirmation (not 3 consecutive like guide audits)
- Lite doesn't specify dimensions per context (user decides what to validate)
- Lite doesn't mandate validation (full Shamt has mandatory gates at S5, S7, S9)

**Rationale:** Validation loops are Shamt's most powerful pattern but currently locked into stage-specific contexts. A generic version enables teams to apply validation rigor anywhere.

---

### Proposal 4: Discovery Protocol Extraction

Extract S1.P3 Discovery Phase mechanics into standalone protocol:

**What to Include:**
- Discovery document structure (Epic Request Summary, Technical Analysis, Key Findings, Solution Options, Recommended Approach, Scope Definition)
- Validation loop for discovery (specific issue types: missing research, unanswered questions, unverified assumptions)
- Question brainstorming framework (6 categories: functional requirements, user workflow/edge cases, implementation approach, constraints, scope boundaries, success criteria) - **Note:** This framework is currently embedded in S1.P3 guide (lines 316-330) and will be extracted into a standalone reference file for lite mode
- Adversarial challenge checklist (force agent to surface unknowns)

**What to Exclude:**
- S1-S10 stage references
- EPIC_TRACKER integration
- Feature breakdown (assumes epic structure)
- Time-boxing by epic size (assumes epic classification)

**Adaptation:** Make discovery protocol applicable to any initiative (feature, bug fix, refactor, tech debt) not just epics.

**Rationale:** Discovery discipline prevents premature implementation and uncovers hidden requirements. It's valuable for any non-trivial software task.

---

### Proposal 5: Code Review Standalone Extraction

Code review workflow (`.shamt/guides/code_review/`) is already designed to be standalone. Include it in lite with minimal adaptation:

**What to Include:**
- Overview.md validation (5 dimensions: ELI5 clarity, What accuracy, Why completeness, How correctness, Holistic coherence)
- Review.md validation (12 categories: correctness, security, performance, maintainability, testing, edge cases, naming, documentation, error handling, concurrency, dependencies, architecture)
- Versioned review outputs (review_v1.md, review_v2.md)
- Sanitized branch folders

**What to Exclude:**
- S9.P4 integration (assumes epic workflow)
- References to EPIC_README.md

**Adaptation:** None needed - code review workflow is already standalone.

**Rationale:** Code review workflow produces high-quality, actionable reviews and is immediately valuable for any team.

---

### Proposal 6: Architecture & Coding Standards Optional Components

Include templates for ARCHITECTURE.md and CODING_STANDARDS.md as optional companions:

**Rationale:**
- These documents provide context for validation loops and code reviews
- Discovery process benefits from understanding existing architecture
- Code reviews use coding standards as evaluation criteria
- They're useful standalone even without Shamt

**Inclusion Method:**
- Templates only (no update workflows, no audit dimensions, no S1/S7/S10 integration)
- SHAMT_LITE.md references them as "recommended but optional"
- Total artifact count: 8 files (6 from Proposal 2 + 2 templates)

**Alternative Considered:** Exclude entirely - rejected because these docs significantly improve the value of discovery and code review protocols.

---

### Proposal 7: Initialization Script

Create `init_lite.sh` (and `init_lite.ps1`) to scaffold the lite structure:

```bash
#!/bin/bash
# Initialize Shamt Lite in current project

# Create folder structure
mkdir -p shamt-lite/reference
mkdir -p shamt-lite/templates

# Copy files from master initialization folder (where lite templates are stored)
# Note: These source paths will be determined during implementation (Phase 1)
# Source files will be adapted/excerpted versions stored at .shamt/scripts/initialization/
cp .shamt/scripts/initialization/reference/severity_classification_lite.md shamt-lite/reference/severity_classification.md
cp .shamt/scripts/initialization/reference/validation_exit_criteria_lite.md shamt-lite/reference/validation_exit_criteria.md
# ... etc

# Create SHAMT_LITE.md from template
# Generate ARCHITECTURE.md and CODING_STANDARDS.md templates
# Prompt user for AI service (Claude, Cursor, ChatGPT, etc.)

echo "✅ Shamt Lite initialized in ./shamt-lite/"
echo "   See SHAMT_LITE.md for usage instructions"
```

**Rationale:** Lowers adoption friction. Script ensures correct file structure and provides starting templates.

**Total Files:** 10 physical files (2 init scripts for cross-platform support + 8 lite artifacts), counting as 9 deliverables (init scripts are one deliverable with dual platform implementations)

---

### Proposal 8: SHAMT_LITE.md Content Structure

Structure the main rules file as a **standalone, executable guide**:

```markdown
# Shamt Lite - Focused Quality Patterns for Software Development

## Overview
- What is Shamt Lite? (Standalone quality patterns, no epic workflow required)
- When to use Lite vs Full Shamt (decision matrix)
- How to adopt gradually (start simple, add patterns as needed)
- How to use this file (Patterns 1-5 are complete and executable without reading other files)

## Core Patterns

### Pattern 1: Validation Loops
**What:** Iterative validation with exit criteria to ensure artifact quality

**When:** Any artifact needing quality assurance (design docs, specs, code, documentation)

**How to Run a Validation Loop:**
1. Read your artifact completely with fresh perspective
2. Identify issues across relevant dimensions:
   - Completeness: Are all necessary aspects covered?
   - Correctness: Are factual claims accurate?
   - Consistency: Are there internal contradictions?
   - [Add dimensions relevant to your artifact type]
3. Classify each issue by severity:
   - CRITICAL: Blocks workflow or causes cascading failures
   - HIGH: Causes significant confusion or wrong decisions
   - MEDIUM: Reduces quality but doesn't block or confuse
   - LOW: Cosmetic issues with minimal impact
4. Fix ALL issues immediately (zero tolerance for deferred issues)
5. Assess round status:
   - 0 issues found → consecutive_clean = 1 (primary clean round achieved)
   - 1 LOW issue found and fixed → consecutive_clean = 1 (clean with 1 low fix)
   - 2+ LOW issues OR any MEDIUM/HIGH/CRITICAL → consecutive_clean = 0 (not clean, loop again)
6. When consecutive_clean = 1: Spawn 2 independent sub-agents in parallel
7. Each sub-agent reads artifact and validates (ANY issue found by sub-agent → cannot confirm)
8. Exit when BOTH sub-agents confirm zero issues

**Exit Criteria:** Primary clean round (≤1 LOW issue) + both sub-agents confirm zero issues

**For more detail:** See `reference/validation_exit_criteria.md` for advanced tracking and edge cases

---

### Pattern 2: Severity Classification
**What:** 4-level system for classifying issues found during validation or code review

**When:** Any validation loop or code review

**Decision Tree:**
```
Issue Discovered
    ↓
Does it BLOCK workflow?
  YES → CRITICAL
  NO  ↓
Does it CONFUSE users/agents?
  YES → HIGH
  NO  ↓
Does it REDUCE quality/usability?
  YES → MEDIUM
  NO  ↓
Is it purely cosmetic?
  YES → LOW
```

**Quick Reference:**
- **CRITICAL:** Blocks workflow, cascading failures, policy violations, data loss risks
- **HIGH:** Causes confusion, wrong decisions, time waste, misleading content
- **MEDIUM:** Reduces quality, harder to use, minor inaccuracies, maintenance burden
- **LOW:** Cosmetic issues, trivial typos, spacing, minimal impact

**Borderline Cases:** When uncertain, classify as HIGHER severity

**For more detail:** See `reference/severity_classification.md` for context-specific examples

---

### Pattern 3: Discovery Protocol
**What:** Structured exploration of requirements and solutions before implementation

**When:** Starting any non-trivial work (feature, bug fix, refactor, tech debt)

**How to Run Discovery:**
1. **Summarize Request:** Write 2-4 sentence summary of what's being asked
2. **Conduct Research:** Read relevant code/docs, examine existing patterns, identify affected components
3. **Brainstorm Questions** across 6 categories:
   - Functional requirements: What does X actually mean? What's the desired behavior?
   - User workflow/edge cases: What if only some cases need this? What breaks when...?
   - Implementation approach: What are the API design choices? Data structure options?
   - Constraints: Performance targets? Security requirements? Compatibility needs?
   - Scope boundaries: What's in/out? Where does this feature end?
   - Success criteria: How will user verify this works? What does done look like?
4. **Ask User Questions:** Present questions when they arise, update findings with answers
5. **Identify Solution Options:** Document 2-3 approaches with pros/cons for each
6. **Recommend Approach:** Choose best option with rationale based on user answers
7. **Define Scope:** Explicitly list in-scope, out-of-scope, and deferred items
8. **Run Validation Loop:** Validate discovery document until clean (check for: missing research, unanswered questions, unverified assumptions, unclear scope)

**Output:** Discovery document with summary, research findings, Q&A, solution options, recommended approach, scope definition

**Template:** See `templates/discovery_template.md` for document structure

**For more detail:** See `reference/question_brainstorm_categories.md` for detailed examples per category

---

### Pattern 4: Code Review Process
**What:** Validated, versioned code reviews with structured feedback

**When:** Reviewing branches or PRs (teammate's work, open-source contributions)

**How to Conduct Review:**
1. **Fetch branch:** `git fetch origin branch-name` (read-only, never checkout)
2. **Create review folder:** `.shamt-lite-reviews/branch-name/`
3. **Write overview.md:**
   - ELI5: Explain changes in simple terms
   - What: List specific changes made
   - Why: Explain purpose/motivation
   - How: Describe implementation approach
4. **Validate overview:** Run validation loop (5 dimensions: ELI5 clarity, What accuracy, Why completeness, How correctness, Holistic coherence)
5. **Write review.md** with feedback across 12 categories:
   - Correctness, Security, Performance, Maintainability
   - Testing, Edge Cases, Naming, Documentation
   - Error Handling, Concurrency, Dependencies, Architecture
6. **Validate review:** Run validation loop (12 dimensions above)
7. **For re-reviews:** Create review_v2.md, review_v3.md (never overwrite previous versions)

**Output:** Versioned review files with copy-paste-ready comments

**Template:** See `templates/code_review_template.md` for review format

---

### Pattern 5: Question Brainstorming
**What:** Systematic framework for uncovering hidden assumptions and requirements

**When:** Discovery phase, requirements gathering, design reviews, any time requirements are unclear

**The 6 Categories:**

1. **Functional Requirements**
   - What does [ambiguous term] actually mean?
   - What's the expected behavior when...?
   - What should happen if...?

2. **User Workflow / Edge Cases**
   - What if only some [items] need this feature?
   - How does this interact with existing [system]?
   - What breaks when [condition occurs]?

3. **Implementation Approach**
   - What are the API design options?
   - What data structures should we use?
   - Should we use [library A] or [library B]?

4. **Constraints**
   - Are there performance targets?
   - Security requirements?
   - Backward compatibility needs?
   - Scale expectations?

5. **Scope Boundaries**
   - What's explicitly in-scope?
   - What's explicitly out-of-scope?
   - Where does this feature's responsibility end?

6. **Success Criteria**
   - How will the user verify this works correctly?
   - What does the ideal end state look like in concrete terms?
   - How do we know when we're done?

**Process:**
1. Read request completely
2. Work through all 6 categories
3. For each category: either list questions OR write one-line justification why none apply
4. Present questions to user
5. Document answers
6. Verify no assumptions remain unverified

**Red Flag:** If you have zero questions after reading the entire request, you're under-questioning. Re-read looking for hidden assumptions.

**For more detail:** See `reference/question_brainstorm_categories.md` for extended examples

## Optional Components

### ARCHITECTURE.md
**Why:** Provides context for discovery (understand existing system) and code reviews (evaluate architectural fit)

**What to include:** System overview, component structure, data flow, key design decisions, technology stack

**Maintenance:** Review quarterly or when significant architectural changes made

**Template:** See `templates/architecture_template.md`

### CODING_STANDARDS.md
**Why:** Defines project conventions for consistent code reviews and new code

**What to include:** Style guide, naming conventions, error handling patterns, testing requirements, code organization rules

**Maintenance:** Update when new patterns emerge or team conventions change

**Template:** See `templates/coding_standards_template.md`

## Integration with AI Assistants

### Claude Code
Place SHAMT_LITE.md at project root or reference in CLAUDE.md:
```markdown
# Project Rules

See `shamt-lite/SHAMT_LITE.md` for quality workflows:
- Run validation loops on all design docs and specs
- Use discovery protocol before implementing features
- Follow code review process for all PRs
```

### Cursor
Reference in `.cursorrules`:
```
Quality workflows: See shamt-lite/SHAMT_LITE.md
- Validation loops for artifacts
- Discovery before implementation
- Structured code reviews
```

### ChatGPT / Other
Include relevant sections from SHAMT_LITE.md in project instructions or conversation context as needed.

## Upgrading to Full Shamt

### When to Upgrade
- Need comprehensive epic lifecycle management (S1-S10 workflow)
- Want automated stage gates (mandatory validation at S5, S7, S9)
- Need cross-repo guide synchronization (import/export between projects)
- Managing multiple concurrent epics (need EPIC_TRACKER integration)
- Benefit from feature-level specs and validation (S2 deep dives)

### How to Upgrade
1. Run full Shamt initialization: `.shamt/scripts/initialization/init.sh`
2. Migrate ARCHITECTURE.md and CODING_STANDARDS.md to `.shamt/project-specific-configs/`
3. Convert any discovery documents to S1.P3 format
4. Begin using S1 (Epic Planning) for next major initiative
5. Lite workflows remain valid - full Shamt includes all lite patterns with added structure

### Migration Path
- **Validation loops** → Same mechanics, added to S5.P2, S7.P2, S9.P2 as mandatory gates
- **Discovery protocol** → Becomes S1.P3 Discovery Phase with EPIC_TRACKER integration
- **Code reviews** → Becomes S9.P4 Final Code Review with epic context
- **Question brainstorming** → Embedded in S1.P3 and S2.P1 (feature discovery)

## Learn More

**Full Shamt Documentation:**
If you want deeper understanding of these patterns in full Shamt context:
- Validation loops: `.shamt/guides/reference/validation_loop_master_protocol.md`
- Discovery protocol: `.shamt/guides/stages/s1/s1_p3_discovery_phase.md`
- Code review workflow: `.shamt/guides/code_review/code_review_workflow.md`
- Severity classification: `.shamt/guides/reference/severity_classification_universal.md`

**Note:** These links are for learning only - you don't need to read full Shamt guides to use Shamt Lite successfully.
```

**Length Target:** 1500-2000 lines (standalone and complete with all instructions)

**Rationale:** This structure makes SHAMT_LITE.md fully standalone and executable. An agent can read ONLY this file and successfully run validation loops, perform discovery, and conduct code reviews. The "How" sections contain actual step-by-step instructions, not placeholders. References to supporting files are clearly marked as "for more detail" and optional. Links to full Shamt are explicitly positioned as "for learning" not "required reading".

---

### Proposal 9: Distribution and Versioning Strategy

**Distribution Mechanism:**

Shamt Lite will be distributed as part of the main Shamt repository:
- Lite templates stored at `.shamt/scripts/initialization/` in master repo
- Users run `bash <(curl -s https://raw.githubusercontent.com/{ORG}/{REPO}/main/.shamt/scripts/initialization/init_lite.sh)` OR clone master repo and run `./.shamt/scripts/initialization/init_lite.sh`
  - **Note:** The GitHub org/repo path (`{ORG}/{REPO}`) is a placeholder - actual repository location to be determined before implementation
- Init script creates `shamt-lite/` folder in user's project with all necessary files
- No separate packaging/npm distribution needed (reduces maintenance burden)

**Versioning Strategy:**

- Lite files do NOT have independent version numbers
- Lite files track master Shamt version (e.g., "Shamt v2.1.0 - includes Lite v2.1.0")
- When full Shamt releases a new version, lite files are updated in same release
- SHAMT_LITE.md includes version number at top: `# Shamt Lite v{X.Y.Z}`
- Breaking changes to lite mode trigger minor version bump (e.g., 2.1.0 → 2.2.0)

**Update Mechanism:**

When users want to update their lite installation:
- Re-run init script with `--update` flag: `init_lite.sh --update`
- Script compares versions and updates files if newer version available
- Preserves user's ARCHITECTURE.md and CODING_STANDARDS.md (doesn't overwrite)
- Updates SHAMT_LITE.md and reference files automatically

**Rationale:** Keeping lite bundled with main repo ensures consistency and reduces divergence risk. Single version number simplifies communication and ensures lite/full compatibility.

**Alternative Considered:** Separate npm package or GitHub repo for lite - rejected because it increases maintenance burden and risk of divergence.

**Handling User Modifications:**

When users update their lite installation (via `--update` flag):
- **ARCHITECTURE.md and CODING_STANDARDS.md:** Never overwritten. These are user-owned documents. If users want latest templates, they manually delete existing files before running update.
- **SHAMT_LITE.md and reference files:** Overwritten by default (assumed to be read-only). Users who customize these should use version control to manage updates.
- **templates/:** Overwritten by default. Users who customize discovery/code review templates should save customizations elsewhere before updating.

**Rationale:** ARCHITECTURE/CODING_STANDARDS are project-specific and should never be auto-updated. Core rules and references are framework files that should stay in sync with upstream.

---

## Files Affected

| File Path | Change Type | Description |
|-----------|-------------|-------------|
| `.shamt/scripts/initialization/init_lite.sh` | CREATE | Bash initialization script for lite mode |
| `.shamt/scripts/initialization/init_lite.ps1` | CREATE | PowerShell initialization script for lite mode |
| `.shamt/scripts/initialization/SHAMT_LITE.template.md` | CREATE | Template for main rules file |
| `.shamt/scripts/initialization/templates/architecture_lite.template.md` | CREATE | Lite version of architecture template (deployed as ARCHITECTURE.md in user projects) |
| `.shamt/scripts/initialization/templates/coding_standards_lite.template.md` | CREATE | Lite version of coding standards template (deployed as CODING_STANDARDS.md in user projects) |
| `.shamt/scripts/initialization/templates/discovery_lite.template.md` | CREATE | Lite version of discovery template (deployed as templates/discovery_template.md in user projects) |
| `.shamt/scripts/initialization/templates/code_review_lite.template.md` | CREATE | Lite version of code review template (deployed as templates/code_review_template.md in user projects) |
| `.shamt/scripts/initialization/reference/severity_classification_lite.md` | CREATE | Lite version of severity classification (excerpted from universal, deployed as reference/severity_classification.md in user projects) |
| `.shamt/scripts/initialization/reference/validation_exit_criteria_lite.md` | CREATE | Lite version of validation loop mechanics (deployed as reference/validation_exit_criteria.md in user projects) |
| `.shamt/scripts/initialization/reference/question_brainstorm_categories_lite.md` | CREATE | Question brainstorming framework (extracted from S1.P3, deployed as reference/question_brainstorm_categories.md in user projects) |
| `README.md` | MODIFY | Add Shamt Lite section explaining the two modes |
| `CLAUDE.md` | MODIFY | Document Shamt Lite in initialization section |

**Total New Files:** 10 physical files (2 init scripts + 8 lite artifacts)

**Note on Structure:** The paths above show where lite files are **stored in master repo** (at `.shamt/scripts/initialization/`). When users run the init script, these files are copied to their project as `shamt-lite/reference/`, `shamt-lite/templates/`, etc. All `_lite` files are **copies/adaptations** of canonical Shamt guides, NOT references. This ensures lite users have a standalone, self-contained system that works without the full `.shamt/` folder.

---

## Implementation Plan

### Phase 1: Extract and Adapt Core Content

**Source Mapping (Canonical → Lite):**
- Pattern 1 (Validation Loops) ← `.shamt/guides/reference/validation_loop_master_protocol.md`
- Pattern 2 (Severity Classification) ← `.shamt/guides/reference/severity_classification_universal.md`
- Pattern 3 (Discovery Protocol) ← `.shamt/guides/stages/s1/s1_p3_discovery_phase.md`
- Pattern 4 (Code Review) ← `.shamt/guides/code_review/code_review_workflow.md`
- Pattern 5 (Question Brainstorming) ← Extract from `.shamt/guides/stages/s1/s1_p3_discovery_phase.md` lines 316-330 (embedded, not standalone)
- ARCHITECTURE template ← `.shamt/scripts/initialization/ARCHITECTURE.template.md`
- CODING_STANDARDS template ← `.shamt/scripts/initialization/CODING_STANDARDS.template.md`

**Tasks:**
- [x] Identify canonical sources for each pattern (see mapping above)
- [ ] Create lite templates by extracting relevant sections from canonical sources
- [ ] Remove S1-S10 references and epic workflow dependencies from extracted content
- [ ] Adapt validation loop for generic use (remove context-specific dimensions)
- [ ] Create question brainstorm categories reference by extracting framework from S1.P3
- [ ] Map source file paths in init script (Proposal 7) based on above mapping

### Phase 2: Draft SHAMT_LITE.md (Standalone Executable)
- [ ] Write overview section (emphasizing standalone nature, no external reading required)
- [ ] Document Pattern 1 (Validation Loops) - **COMPLETE INSTRUCTIONS** (8 steps, exit criteria, examples)
- [ ] Document Pattern 2 (Severity Classification) - **COMPLETE DECISION TREE** (4 levels, quick reference, borderline rules)
- [ ] Document Pattern 3 (Discovery Protocol) - **COMPLETE PROCESS** (8 steps, 6-category framework, validation)
- [ ] Document Pattern 4 (Code Review Process) - **COMPLETE WORKFLOW** (7 steps, 12 categories, versioning)
- [ ] Document Pattern 5 (Question Brainstorming) - **COMPLETE 6 CATEGORIES** (with examples per category, process, red flags)
- [ ] Write optional components section (clarify ARCHITECTURE/CODING_STANDARDS enhance but aren't required)
- [ ] Write AI assistant integration section (how to reference SHAMT_LITE.md in each tool)
- [ ] Write upgrade path section (when/how to move to full Shamt, pattern mapping)
- [ ] Write "Learn More" section (links to full Shamt as optional learning resources, not required reading)
- [ ] Verify: Agent can execute all 5 patterns using ONLY SHAMT_LITE.md without reading any other file

### Phase 3: Create Supporting Files
- [ ] Create severity_classification_lite.md
- [ ] Create validation_exit_criteria_lite.md
- [ ] Create question_brainstorm_categories_lite.md
- [ ] Create discovery_lite.template.md
- [ ] Create code_review_lite.template.md
- [ ] Create architecture_lite.template.md
- [ ] Create coding_standards_lite.template.md

### Phase 4: Build Initialization Scripts
- [ ] Create init_lite.sh with scaffolding logic
- [ ] Create init_lite.ps1 (Windows equivalent)
- [ ] Test on sample project (non-Shamt repo)
- [ ] Verify all files created correctly
- [ ] Verify standalone usability (no dependencies on `.shamt/`)

### Phase 5: Update Master Documentation
- [ ] Update README.md with Lite vs Full comparison
- [ ] Update CLAUDE.md initialization section
- [ ] Add lite mode to ai_services.md registry
- [ ] Document upgrade path in master_dev_workflow

### Phase 6: Validation and Testing
- [ ] Run design doc validation loop on SHAMT28_DESIGN.md
- [ ] Test init scripts on Windows and Unix
- [ ] Verify SHAMT_LITE.md is 1500-2000 lines (long enough to be complete and standalone)
- [ ] Verify total artifact count = 10 physical files
- [ ] Test discovery protocol without epic workflow
- [ ] Test validation loop on non-Shamt artifact
- [ ] Test code review workflow in lite context
- [ ] Create example project demonstrating lite usage (sample-lite-project/ in master repo)
- [ ] Test update mechanism (--update flag)

---

## Validation Strategy

### Design Doc Validation
Run 7-dimension validation loop on this design doc per `design_doc_validation/validation_workflow.md`:
1. Completeness - all sections filled, all proposals detailed, all files identified
2. Correctness - factual claims accurate, proposals technically sound
3. Consistency - no internal contradictions, aligns with Shamt principles
4. Helpfulness - actually solves the stated problem
5. Improvements - simplest approach that could work
6. Missing proposals - anything important omitted
7. Open questions - unresolved decisions surfaced

Exit criteria: Primary clean round + 2 sub-agent confirmations

### Implementation Validation
After Phases 1-5 complete, run 5-dimension implementation validation:
1. Completeness - all proposals implemented
2. Correctness - implementation matches design
3. Files Affected Accuracy - all files created/modified as specified
4. No Regressions - nothing broken
5. Documentation Sync - CLAUDE.md and README.md reflect new lite mode

### End-to-End Testing
After Phase 6, test lite mode in real scenario:
1. Initialize lite in non-Shamt project
2. Run discovery protocol for sample feature
3. Run validation loop on discovery document
4. Run code review workflow on sample branch
5. Verify all patterns work without full Shamt

---

## Open Questions

1. **File count tradeoff:** Should we stay strict on 10 files, or allow 12-15 if it improves usability?
   - Current design: 10 files (9 lite + 1 init script deliverable)
   - Alternative: 12 files if we add validation_loop_master_protocol_lite.md and examples

2. **Sub-agent confirmation requirement:** Should lite version require 2 sub-agent confirmations or simplify to 1?
   - Current design: Matches full Shamt (2 sub-agents)
   - Alternative: 1 sub-agent for lite (simpler, still rigorous)

3. **Templates vs References:** Should supporting files be templates (user fills in) or references (read-only guides)?
   - Current design: Mix (discovery/code review are templates, severity/validation are references)
   - Alternative: All templates (more consistent, but some don't need filling in)

4. **AI service integration:** Should init script prompt for AI service and customize SHAMT_LITE.md accordingly?
   - Current design: Generic SHAMT_LITE.md with sections for each AI assistant
   - Alternative: Generate service-specific file (CLAUDE.md, CURSOR.md, etc.)

5. **Upgrade path mechanics:** Should we provide a script to upgrade from lite to full, or just documentation?
   - Current design: Documentation only
   - Alternative: `upgrade_to_full.sh` script that migrates lite to `.shamt/`

6. **Lite file maintenance process:** When full Shamt patterns evolve (e.g., new validation dimensions, updated severity rules), who is responsible for updating lite files? Should this be part of the normal master dev workflow, or a separate periodic review?
   - Current design: Update lite files in same commit when full Shamt changes (mentioned in Risk 1 mitigation)
   - Alternative: Quarterly review process to sync lite with full
   - **Decision needed:** Should this be documented in CLAUDE.md as a mandatory step?
   - **Decision criteria:**
     - If patterns change frequently (>1/month): Quarterly review reduces overhead
     - If patterns change rarely (<1/quarter): Same-commit update ensures no divergence
     - If critical for compatibility: Same-commit update mandatory
     - Recommendation: Same-commit for severity classification and validation exit criteria (critical), quarterly for other content

7. **GitHub repository location:** What is the actual GitHub org/repo path for distribution?
   - Current design: Placeholder `{ORG}/{REPO}` in Proposal 9
   - Needs resolution: Actual path before init script can be published
   - Affects: curl-based installation command in Proposal 9

---

## Risks & Mitigation

### Risk 1: Lite version diverges from full Shamt over time
**Impact:** HIGH - Lite users learn patterns that don't match full Shamt, making upgrade painful

**Mitigation:**
- Lite files reference canonical Shamt guides for deeper details
- When full Shamt patterns change, update lite versions in same commit
- Include upgrade path documentation that maps lite → full
- Design doc validation catches inconsistencies

### Risk 2: 10-file constraint forces oversimplification
**Impact:** MEDIUM - Patterns might be too condensed to be actionable

**Mitigation:**
- Allow overflow to 12 files if user testing shows gaps
- Prioritize clarity over strict file count
- Use references to full Shamt for deep dives (lite is entry point, not comprehensive guide)

### Risk 3: Users pick lite when they should use full
**Impact:** MEDIUM - Teams that need epic workflow use inadequate lite version

**Mitigation:**
- Clear decision matrix in SHAMT_LITE.md overview
- Emphasize upgrade path (start lite, upgrade when needed)
- README.md prominently explains when to use each version

### Risk 4: Initialization script fails on diverse environments
**Impact:** LOW - Users can't scaffold lite structure easily

**Mitigation:**
- Test on multiple platforms (macOS, Linux, Windows)
- Provide both .sh and .ps1 versions
- Include manual setup instructions if script fails

### Risk 5: Lite mode confuses full Shamt semantics
**Impact:** MEDIUM - Validation loops in lite use different exit criteria than full Shamt contexts

**Mitigation:**
- Document differences explicitly in SHAMT_LITE.md
- Use consistent terminology (consecutive_clean, primary clean round, sub-agent confirmation)
- Explain: lite uses 1 consecutive clean, full Shamt guide audits use 3 consecutive clean

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-01 | Initial draft created |
| 2026-04-01 | Design doc validated (5 validation rounds, 3 sub-agent confirmation rounds) |
| 2026-04-01 | Updated to reflect standalone philosophy - SHAMT_LITE.md must be executable without reading supporting files (requires re-validation) |

