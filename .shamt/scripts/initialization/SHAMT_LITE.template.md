# {{PROJECT_NAME}} — Shamt Lite Rules

**Version:** 1.0
**Last Updated:** {{DATE}}
**Purpose:** Standalone agent rules for validation loops, discovery, and code review workflows

---

## What is Shamt Lite?

Shamt Lite is a lightweight quality framework for AI-assisted development. It provides **6 core patterns** that help agents produce better work through systematic validation, thorough discovery, structured code review, and implementation planning.

**Use Shamt Lite when:**
- You want validation loops without a full epic workflow
- You need structured discovery for new features or unclear requirements
- You want consistent code review output
- You're working on a project that doesn't need the full Shamt S1-S10 workflow

**What you get:**
1. **Validation Loops** — Iterative self-review with exit criteria
2. **Severity Classification** — 4-level issue categorization system
3. **Discovery Protocol** — Question brainstorming and solution design
4. **Code Review Process** — Structured branch/PR review workflow
5. **Question Brainstorming** — 6-category framework for uncovering hidden assumptions
6. **Implementation Planning** — Mechanical step-by-step plans with optional builder handoff

---

## How to Use This File

**This file is standalone and complete.** You can execute all 6 patterns using only the instructions in Part 1 below.

**3-Tier Structure:**
- **Part 1: Core Patterns** — Standalone, executable instructions for all workflows
- **Part 2: Reference Files** — Optional deeper reading (severity details, validation mechanics)
- **Part 3: Templates** — Copy-paste-ready markdown templates for discovery, code review, architecture, coding standards

**If you only read Part 1**, you can successfully run validation loops, perform discovery, and conduct code reviews.

---

# Part 1: Core Patterns (Standalone, Complete)

## Pattern 1: Validation Loops

**Purpose:** Iterative self-review of work artifacts until quality threshold is met

**When to use:**
- After creating a discovery document
- After completing a code review
- After writing any significant work artifact
- When you need to ensure work meets quality standards

### The 8-Step Validation Process

**Step 1: Read the artifact completely with fresh perspective**

Approach the artifact as if you've never seen it before. Read it top to bottom without making changes. Your goal is to understand it first, then critique it.

**Step 2: Identify issues across relevant dimensions**

For each artifact type, check different dimensions:

*For Discovery Documents:*
1. Completeness — Are all necessary aspects covered?
2. Correctness — Are factual claims accurate?
3. Consistency — Is the design internally consistent?
4. Helpfulness — Do the proposals solve the stated problem?
5. Improvements — Are there simpler or better ways?
6. Missing proposals — Is anything important left out?
7. Open questions — Are there unresolved decisions?

*For Code Reviews:*
1. Correctness — Logic errors, bugs, incorrect behavior
2. Security — Vulnerabilities, unsafe practices
3. Performance — Inefficiencies, scalability issues
4. Maintainability — Code clarity, organization, complexity
5. Testing — Test coverage, test quality
6. Edge Cases — Unhandled scenarios, missing validation

*For General Work Artifacts:*
1. Completeness — All sections filled out?
2. Clarity — Easy to understand?
3. Accuracy — Facts and references correct?
4. Actionability — Can someone act on this?

**Step 3: Classify each issue by severity**

Use the 4-level system (see Pattern 2 for details):

- **CRITICAL** — Blocks workflow completion, causes failures, or creates security vulnerabilities
- **HIGH** — Causes confusion, significantly reduces quality, or risks problems
- **MEDIUM** — Reduces quality or usability in noticeable ways
- **LOW** — Minor cosmetic issues, trivial wording improvements

**Quick classification questions:**
1. "If this isn't fixed, can workflow complete?" → NO = CRITICAL
2. "Will this cause agent or user confusion?" → YES = HIGH
3. "Does this reduce quality or usability?" → YES = MEDIUM
4. "Is this purely cosmetic?" → YES = LOW

**Step 4: Fix ALL issues immediately**

Don't just document issues — fix them in the artifact right away. Make the changes, then continue to the next issue.

**Step 5: Update consecutive_clean counter**

Track how many clean rounds you've had in a row:

- **Clean round** = ZERO issues found OR exactly ONE LOW-severity issue (which you fixed)
- **Not clean round** = Multiple LOW issues OR any MEDIUM/HIGH/CRITICAL issue

Update your counter:
- If this round was clean: `consecutive_clean = consecutive_clean + 1`
- If this round was not clean: `consecutive_clean = 0`

**Step 6: Check exit condition**

Exit criteria = **primary clean round + 2 independent sub-agent confirmations**

- If `consecutive_clean = 0`: Go back to Step 1 for another round
- If `consecutive_clean = 1`: Spawn 2 parallel sub-agents for independent confirmation (go to Step 7)
- If both sub-agents confirm zero issues: Validation complete ✅
- If either sub-agent finds issues: Fix them, reset `consecutive_clean = 0`, go back to Step 1

**Step 7: Spawn sub-agents for independent confirmation**

When `consecutive_clean = 1`, spawn 2 parallel sub-agents to independently validate the artifact.

Each sub-agent:
- Reads the artifact fresh
- Applies the same dimensions from Step 2
- Reports any issues found (with severity)
- **Must find ZERO issues to confirm**

If both sub-agents find zero issues: Validation complete ✅

If any sub-agent finds issues:
- Fix all issues they reported
- Reset `consecutive_clean = 0`
- Return to Step 1 for another primary round

**Task Tool Example for Sub-Agent Confirmation:**

When `consecutive_clean = 1`, spawn 2 sub-agents using the Task tool:

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Confirm zero issues (sub-agent A)</parameter>
  <parameter name="prompt">You are sub-agent A confirming zero issues after primary validation.

**Artifact to validate:** {artifact_path_or_description}
**Validation dimensions:** {list the dimensions from Step 2 for this artifact type}
**Your task:** Re-read the entire artifact and verify ALL dimensions.

CRITICAL: Report ANY issue found, even LOW severity. If zero issues found, state "CONFIRMED: Zero issues found".

{Provide relevant context about what was validated}
  </parameter>
</invoke>

<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Confirm zero issues (sub-agent B)</parameter>
  <parameter name="prompt">You are sub-agent B confirming zero issues after primary validation.

**Artifact to validate:** {artifact_path_or_description}
**Validation dimensions:** {list the dimensions from Step 2 for this artifact type}
**Your task:** Re-read the entire artifact and verify ALL dimensions.

CRITICAL: Report ANY issue found, even LOW severity. If zero issues found, state "CONFIRMED: Zero issues found".

{Provide relevant context about what was validated}
  </parameter>
</invoke>
```

**Why use Task tool?** Spawning sub-agents allows for independent verification, reducing blind spots and ensuring quality.

**Step 8: Document validation completion**

At the end of validation, document:
- Total rounds completed
- Sub-agent confirmation results
- Issues found and resolved during validation
- Final status: Validated ✅

### Validation Loop Example

```
Round 1:
- Found 3 HIGH issues, 2 MEDIUM issues → Fixed all
- Round status: NOT CLEAN (multiple non-LOW issues)
- consecutive_clean = 0

Round 2:
- Found 1 MEDIUM issue → Fixed
- Round status: NOT CLEAN
- consecutive_clean = 0

Round 3:
- Found 1 LOW issue → Fixed
- Round status: CLEAN (exactly 1 LOW issue)
- consecutive_clean = 1
- **Spawn 2 sub-agents**

Sub-agent Round 1:
- Sub-agent A: Found 1 MEDIUM issue
- Sub-agent B: Found 0 issues
- **Not both clean** → Fix issue, consecutive_clean = 0

Round 4:
- Found 0 issues
- Round status: CLEAN
- consecutive_clean = 1
- **Spawn 2 sub-agents**

Sub-agent Round 2:
- Sub-agent A: Found 0 issues ✅
- Sub-agent B: Found 0 issues ✅
- **Both clean** → Validation complete ✅
```

### Key Rules

1. **Always track consecutive_clean explicitly** — State the counter value at the end of every round
2. **Fix issues immediately** — Don't batch them up for later
3. **One LOW issue is allowed per round** — But only one. Two LOW issues = not clean
4. **Sub-agents must both find zero issues** — One clean sub-agent is not enough
5. **Reset to zero on any non-clean round** — No partial credit

---

## Pattern 2: Severity Classification

**Purpose:** Consistent issue categorization for validation and code review

### The 4 Levels

**CRITICAL** — Blocks workflow, causes failures, or creates serious risks

*What qualifies:*
- Workflow cannot complete if not fixed
- Security vulnerability (injection, auth bypass, data exposure)
- Data loss or corruption risk
- Logic error that produces incorrect results
- Missing required section in template
- Broken reference or invalid file path that blocks execution

*Examples:*
- Discovery document missing "Recommended Approach" section
- Code review references file that doesn't exist in the branch
- SQL injection vulnerability in user input handling
- Function returns wrong type, causing downstream crashes

**HIGH** — Causes confusion, significantly reduces quality, or risks problems

*What qualifies:*
- Agent or user will likely be confused or misled
- Significant quality reduction
- Important information missing or incorrect
- Inconsistency that creates ambiguity
- Misleading or unclear instructions

*Examples:*
- Discovery document states "Option 1 is recommended" but later says "Option 2 is better"
- Code review says "no security issues" but file contains hardcoded credentials
- Missing explanation of why a design choice was made
- Template section labeled "Required" but marked as optional

**MEDIUM** — Reduces quality or usability in noticeable ways

*What qualifies:*
- Makes the artifact harder to use or understand
- Reduces clarity without blocking understanding
- Suboptimal structure or organization
- Minor factual errors that don't mislead
- Missing context that would be helpful

*Examples:*
- Discovery document has solution options in wrong order (best option listed last)
- Code review feedback lacks file path and line number
- Inconsistent heading capitalization across document
- Missing example that would clarify instructions

**LOW** — Minor cosmetic issues, trivial improvements

*What qualifies:*
- Typos, grammar, formatting
- Trivial wording improvements
- Minor style inconsistencies
- Optional enhancements

*Examples:*
- Typo: "recieve" instead of "receive"
- Extra blank line between sections
- "TODO" instead of "To-do" (both acceptable)
- Could add bullet point for slightly better readability

### Quick Classification Decision Tree

```
Start here: Is there an issue?
│
├─ NO → No issue, continue reading
│
└─ YES → Answer these questions in order:
    │
    ├─ Q1: "If this isn't fixed, can the workflow complete?"
    │   └─ NO → CRITICAL
    │   └─ YES → Go to Q2
    │
    ├─ Q2: "Will this cause agent or user confusion?"
    │   └─ YES → HIGH
    │   └─ NO → Go to Q3
    │
    ├─ Q3: "Does this reduce quality or usability in a noticeable way?"
    │   └─ YES → MEDIUM
    │   └─ NO → LOW
```

### Borderline Cases

**CRITICAL vs HIGH:**
- If it blocks execution → CRITICAL
- If it misleads but doesn't block → HIGH

**HIGH vs MEDIUM:**
- If it will likely confuse → HIGH
- If it might confuse but context makes it clear → MEDIUM

**MEDIUM vs LOW:**
- If it makes work noticeably harder → MEDIUM
- If it's just inelegant but doesn't impede → LOW

**When uncertain:** Classify higher rather than lower. It's better to fix a MEDIUM issue that might be LOW than to miss a HIGH issue by calling it MEDIUM.

### The "One LOW Issue" Rule

In validation loops, a round with **exactly one LOW-severity issue (which you fix)** still counts as clean.

**Why:** Not every artifact will be 100% perfect. One trivial typo or formatting issue shouldn't force another full validation round.

**Critical rule:** This only applies to ONE LOW issue. Two or more LOW issues = not clean.

---

## Pattern 3: Discovery Protocol

**Purpose:** Systematic exploration of unclear requirements before implementation

**When to use:**
- User request is vague or ambiguous
- Multiple approaches are possible
- Requirements are incomplete
- You're unsure what the user actually wants
- Before starting any non-trivial implementation

### The 8-Step Discovery Process

**Step 1: Capture the request**

Write a 2-4 sentence summary of what's being requested. Don't interpret yet — just capture the essence.

Document:
- What the user asked for (verbatim or paraphrased)
- Any context they provided
- Reference to original request (message, ticket, etc.)

**Step 2: Research existing systems**

Before asking questions or proposing solutions, understand what already exists:

- Search codebase for related functionality
- Read relevant architecture/standards documentation
- Identify patterns you can leverage
- Note any constraints from existing design

Document your findings:
- What components/files/systems are involved
- What patterns exist that can be reused
- Key discoveries (3-5 bullet points)

**Step 3: Brainstorm questions using the 6-category framework**

Work through each category systematically (see Pattern 5 for detailed examples):

1. **Functional requirements** — What does [ambiguous term] mean? Expected behavior?
2. **User workflow / edge cases** — What if only some items need this? Boundary cases?
3. **Implementation approach** — What design options exist? Preferred patterns?
4. **Constraints** — Performance targets? Security requirements? Compatibility needs?
5. **Scope boundaries** — What's in/out? What's deferred?
6. **Success criteria** — How will user verify this works?

**For each category:**
- Either identify specific questions
- OR write one-line justification for why none apply

**Red flag:** Zero questions across all 6 categories means you're under-questioning.

**Step 4: Present questions to user and document answers**

Don't assume answers. Ask the user directly.

Track each question:
- Question text
- User's answer
- How this impacts your approach
- Date resolved

Keep a "Pending Questions" section for any you haven't asked yet.

**Step 5: Design 2-3 solution options**

Based on research and user answers, design multiple approaches:

For each option, document:
- **Description** — How this approach works
- **Pros** — 2-4 advantages
- **Cons** — 2-4 disadvantages
- **Effort estimate** — SMALL / MEDIUM / LARGE
- **Fit assessment** — How well it solves the problem

**Step 6: Recommend an approach**

Choose the best option (or combination) and explain why:

- State which option you recommend
- Provide 3-5 reasons referencing specific findings or user answers
- Document key design decisions made

**Step 7: Define scope boundaries**

Explicitly state:
- **In scope** — What will be implemented
- **Out of scope** — What won't be done (not needed or not requested)
- **Deferred** — Nice-to-haves for future work

This prevents scope creep and sets clear expectations.

**Step 8: Validate the discovery document**

Run a validation loop (Pattern 1) on the discovery document using these 7 dimensions:

1. Completeness — Are all necessary aspects covered?
2. Correctness — Are factual claims accurate?
3. Consistency — Is the design internally consistent?
4. Helpfulness — Do the proposals solve the stated problem?
5. Improvements — Are there simpler or better ways?
6. Missing proposals — Is anything important left out?
7. Open questions — Are there unresolved decisions?

Exit criteria: Primary clean round + 2 sub-agent confirmations

Once validated, present the discovery document to the user for approval before proceeding to implementation.

### Discovery Protocol Example

```markdown
Request: "Add export functionality"

Research Findings:
- Existing ExportService handles CSV generation
- UserDataRepository has getAllUserData() method
- Current exports limited to 1000 rows
- No bulk export UI exists yet

Questions (6 categories):
1. Functional: Export to what format? CSV, JSON, PDF, or all three?
2. Workflow: Export all data or allow user selection?
3. Approach: Server-side generation or client-side?
4. Constraints: Size limits? 100 rows vs 1 million rows?
5. Scope: Just current view or historical data too?
6. Success: What makes a "good" export? Speed? Completeness?

User Answers:
- Q1: CSV only for now, JSON deferred
- Q2: Allow user to select date range
- Q3: Server-side preferred
- Q4: Support up to 100k rows
- Q5: Current view only
- Q6: Must complete in under 30 seconds

Solution Options:
Option 1: Extend ExportService
- Pros: Reuses existing code, consistent with current pattern
- Cons: Tightly coupled to existing implementation
- Effort: SMALL
- Fit: Good

Option 2: New standalone ExportManager
- Pros: More flexible, easier to add JSON later
- Cons: Code duplication
- Effort: MEDIUM
- Fit: Better for future expansion

Recommended Approach: Option 1 (Extend ExportService)
- Minimal code changes
- User only needs CSV now
- Can refactor later if JSON requirement emerges
- Leverages existing tested code

Scope:
- In scope: CSV export with date range selection, up to 100k rows
- Out of scope: JSON/PDF export, scheduled exports
- Deferred: Email export results, export templates
```

---

## Pattern 4: Code Review Process

**Purpose:** Structured review of branches/PRs with validated, copy-paste-ready feedback

**When to use:**
- Reviewing someone else's branch or PR
- User asks to "review branch X" or "code review"
- Before merging significant changes
- As part of your team's PR workflow

### The 7-Step Code Review Process

**Step 1: Fetch branch metadata (read-only)**

**NEVER check out the branch.** Use read-only git commands only:

```bash
# Fetch the branch
git fetch origin <branch-name>

# Get merge base with main/master
git merge-base origin/main origin/<branch-name>

# Get commit range
git log origin/main..origin/<branch-name> --oneline

# Get files changed
git diff --stat origin/main...origin/<branch-name>

# Get full diff
git diff origin/main...origin/<branch-name>
```

If branch cannot be fetched, halt immediately and report to user.

**Step 2: Create review directory structure**

Create output directory: `.shamt/code_reviews/<sanitized-branch>/`

Example: Branch `feat/add-export` → `.shamt/code_reviews/feat-add-export/`

**Step 3: Write overview.md**

Create an overview document with 3 sections:

**Section 1: ELI5 — What Changed?**
- 2-4 sentences in plain English
- No jargon
- Focus on what the user would notice, not implementation details

**Section 2: What Does This Branch Do?**
- Clear description of purpose and outcomes
- What problem does it solve?
- What feature does it add?
- What does the system do differently after merge?

**Section 3: Why Was It Built?**
- Intent and motivation from commit messages, PR description, code reading
- If intent not explicit, state "inferred from commit messages / code structure"

**Section 4: How Does It Work?**
- Technical walkthrough
- Which files were changed
- Key logic and design choices
- How components interact
- Organize by area of change when multiple subsystems touched

**Step 4: Validate overview.md**

Run validation loop (Pattern 1) on overview.md:

Dimensions:
1. Completeness — All sections filled?
2. Clarity — Easy to understand?
3. Accuracy — Claims match code?
4. Helpfulness — Gives clear picture of changes?

Exit criteria: Primary clean round + 2 sub-agent confirmations

**Step 5: Write review.md with categorized feedback**

Review the code changes and create `review.md` with findings grouped by severity, then by category.

**4 Severity Levels:**
- **BLOCKING** — Must be fixed before merge (bugs, security, data loss)
- **CONCERN** — Should be addressed (quality, performance, maintainability)
- **SUGGESTION** — Optional improvement (code works but could be better)
- **NITPICK** — Minor style or preference (author decides)

**12 Review Categories:**
1. Correctness
2. Security
3. Performance
4. Maintainability
5. Testing
6. Edge Cases
7. Naming
8. Documentation
9. Error Handling
10. Concurrency
11. Dependencies
12. Architecture

**Format each finding:**

```markdown
#### [SEVERITY] Category — <Category Name>

**File:** `path/to/file.ext`, line N

<Description of issue. Be specific: what line, what it does wrong, what the consequence is.>

**Suggested fix:** <Concrete direction — what to change and why.>
```

**Omit severity sections with no findings.**

**Step 6: Validate review.md**

Run validation loop (Pattern 1) on review.md:

Dimensions:
1. Correctness — Are issues accurately described?
2. Completeness — Did you review all changed files?
3. Helpfulness — Are suggested fixes actionable?
4. Severity accuracy — Correctly classified?
5. Evidence — Do line numbers and file paths match the diff?

Exit criteria: Primary clean round + 2 sub-agent confirmations

**Step 7: Document validation summary**

At the end of review.md, add:

```markdown
## Validation Summary

**Rounds completed:** N
**Exit criteria:** Primary clean round + sub-agent confirmation
**Sub-agent A:** 0 issues ✅
**Sub-agent B:** 0 issues ✅
**Issues found and resolved during validation:** N
```

### Code Review Versioning

**Re-reviews:** If user asks to review the same branch again later, create `review_v2.md`, `review_v3.md`, etc.

Never overwrite previous review versions — they provide historical context.

### Code Review Example Output

```markdown
# Branch Overview: feat/add-export

**Date:** 2026-04-02
**Base:** main (merge base: a1b2c3d)
**Commits:** 4 commits (a1b2c3d..e5f6g7h)
**Files changed:** 6 files (+142 -23 lines)

---

## ELI5 — What Changed?

Users can now export their data to a CSV file. They pick a date range,
click "Export", and download a file with all their records from that period.

---

## What Does This Branch Do?

Adds CSV export functionality to the user dashboard. Users can select a
start and end date, then export all records within that range. The system
generates a CSV file with standard columns (date, user, action, status)
and triggers a browser download.

## Why Was It Built?

Inferred from commit messages: Users requested ability to download their
data for offline analysis. Previous system only allowed viewing data
in-browser with no export option.

## How Does It Work?

**Backend (2 files changed):**
- `ExportService.java` — New method `generateCSV(startDate, endDate)` that
  queries UserDataRepository and formats results as CSV string
- `ExportController.java` — New endpoint `/api/export` that calls
  ExportService and returns CSV with proper headers

**Frontend (3 files changed):**
- `Dashboard.tsx` — Added date range picker and "Export" button
- `exportUtils.ts` — Helper function to trigger browser download
- `Dashboard.css` — Styling for export controls

**Tests (1 file changed):**
- `ExportServiceTest.java` — 4 new tests covering empty results, single
  record, date range filtering, and large dataset (1000 rows)
```

```markdown
# Code Review: feat/add-export

**Reviewed:** 2026-04-02
**Overview:** See `overview.md` for full description

---

## Review Comments

### CONCERN

#### [CONCERN] Performance — Large Dataset Handling

**File:** `ExportService.java`, line 45

The current implementation loads all records into memory before formatting
as CSV. For date ranges spanning years, this could load 100k+ records and
cause OutOfMemoryError.

**Suggested fix:** Implement streaming: query in batches of 1000 records,
write each batch to output stream, release memory between batches.

---

#### [CONCERN] Edge Cases — Missing Date Validation

**File:** `ExportController.java`, line 23

No validation that `endDate` is after `startDate`. User could request
2026-01-01 to 2025-01-01, which would return empty results with no error
message.

**Suggested fix:** Add validation in controller: if endDate < startDate,
return 400 Bad Request with error message "End date must be after start date".

---

### SUGGESTION

#### [SUGGESTION] Testing — Missing Large Dataset Test

**File:** `ExportServiceTest.java`, line 67

Test with 1000 rows exists but doesn't verify performance. For 100k row
support (per requirements), should test larger dataset.

**Suggested fix:** Add test with 10k rows and assert completion under 5
seconds. If too slow for CI, make it an integration test that runs separately.

---

### NITPICK

#### [NITPICK] Naming — Inconsistent Method Name

**File:** `exportUtils.ts`, line 12

Method named `triggerDownload` but other utils use verb-noun pattern
like `downloadFile`, `parseJSON`.

**Suggested fix:** Consider renaming to `downloadCSV` for consistency, but
current name is acceptable if preferred.

---

## Validation Summary

**Rounds completed:** 3
**Exit criteria:** Primary clean round + sub-agent confirmation
**Sub-agent A:** 0 issues ✅
**Sub-agent B:** 0 issues ✅
**Issues found and resolved during validation:** 7
```

---

## Pattern 5: Question Brainstorming

**Purpose:** Systematic framework for uncovering hidden assumptions and requirements

**When to use:**
- Starting discovery on a vague request
- User gives incomplete requirements
- Multiple valid interpretations exist
- Before implementing anything non-trivial

### The 6 Categories

Work through each category to brainstorm questions. For each category, either identify specific questions OR write a one-line justification for why none apply.

**Category 1: Functional Requirements**

*What to ask:*
- What does [ambiguous term] actually mean?
- What's the expected behavior when [condition]?
- What should happen if [edge case occurs]?
- How should the system respond to [input]?

*Examples:*
- "What does 'debugging version run' mean?"
- "What constitutes a 'valid' request?"
- "How should 'better performance' be measured?"

---

**Category 2: User Workflow / Edge Cases**

*What to ask:*
- What if only some [items] need this feature?
- How does this interact with existing [system/feature]?
- What breaks when [condition occurs]?
- Are there workflows or users not mentioned that will be impacted?
- What happens at boundary cases?

*Examples:*
- "What if only some scripts need debug mode?"
- "How does this affect existing users who rely on current behavior?"
- "What happens when system is under heavy load?"

---

**Category 3: Implementation Approach**

*What to ask:*
- What are the API design options?
- What data structures should we use?
- Should we use [library A] or [library B]?
- What high-level architecture choices need to be made?
- How should errors be handled?

*Examples:*
- "Should this be a command-line flag or config file setting?"
- "Should we use REST API or GraphQL?"
- "Do we need a database or is file-based storage sufficient?"

---

**Category 4: Constraints**

*What to ask:*
- Are there performance targets?
- Security requirements or compliance needs?
- Backward compatibility requirements?
- Scale expectations (users, data volume)?
- Platform or technology limitations?
- Budget or resource constraints?

*Examples:*
- "Does this need to support 1000 concurrent users or 10?"
- "Are there regulatory requirements (GDPR, HIPAA)?"
- "Must it work on mobile devices?"
- "What's the acceptable response time?"

---

**Category 5: Scope Boundaries**

*What to ask:*
- What's explicitly in-scope?
- What's explicitly out-of-scope?
- Where does this feature's responsibility end?
- What about cases where this overlaps with existing feature Y?
- What gets deferred to future work?

*Examples:*
- "Do all 6 scripts need this, or just a subset?"
- "Is offline mode in scope or deferred?"
- "Should this handle CSV and JSON, or just CSV for now?"

---

**Category 6: Success Criteria**

*What to ask:*
- How will the user verify this works correctly?
- What does the ideal end state look like in concrete terms?
- How do we know when we're done?
- What tests or demonstrations will prove this is complete?
- What would make the user say "this is exactly what I needed"?

*Examples:*
- "How will the user verify debug mode works correctly?"
- "What specific scenarios should we test?"
- "What measurable improvement defines success?"

---

### How to Use the Framework

**Step 1: Create a brainstorming table**

| Category | Questions identified (or justification if none) |
|----------|------------------------------------------------|
| **Functional requirements** | ? |
| **User workflow / edge cases** | ? |
| **Implementation approach** | ? |
| **Constraints** | ? |
| **Scope boundaries** | ? |
| **Success criteria** | ? |

**Step 2: Fill in each row**

For each category, either:
- List specific questions you need to ask
- OR write why no questions apply (e.g., "None identified — approach is clear from request")

**Step 3: Check for red flags**

🚨 **Zero questions across all 6 categories?**

You're almost certainly under-questioning. Re-read the request looking for:
- Ambiguous terms ("better", "faster", "improved")
- Undefined processes ("sync", "validate", "optimize")
- Hidden assumptions you're making
- Missing context

**Step 4: Present questions to user**

Don't assume answers. Ask the user and document their responses.

**Step 5: Update your discovery document**

Incorporate answers into your discovery document, spec, or plan.

### Question Brainstorming Examples

**Example 1: Vague Feature Request**

*Request:* "Add export functionality"

| Category | Questions |
|----------|-----------|
| Functional requirements | Export to what format? CSV, JSON, PDF? All three? |
| User workflow / edge cases | Export all data or allow selection? One-time or scheduled? |
| Implementation approach | Server-side generation or client-side? |
| Constraints | Size limits? 100 rows vs 1 million rows? |
| Scope boundaries | Just current view or historical data too? |
| Success criteria | What makes a "good" export? Speed? Completeness? |

---

**Example 2: Bug Fix Request**

*Request:* "Fix the login timeout issue"

| Category | Questions |
|----------|-----------|
| Functional requirements | What exactly is timing out? Session? Connection? UI interaction? |
| User workflow / edge cases | Affecting all users or specific scenarios? |
| Implementation approach | Fix root cause or increase timeout duration? Both? |
| Constraints | Security implications of longer timeouts? |
| Scope boundaries | Just login or all authentication flows? |
| Success criteria | How will we verify it's fixed? Specific test cases? |

---

**Example 3: Performance Request**

*Request:* "Make the dashboard load faster"

| Category | Questions |
|----------|-----------|
| Functional requirements | Which parts? Initial load? Data refresh? Interactions? |
| User workflow / edge cases | Fast for which scenarios? Empty dashboard vs full of widgets? |
| Implementation approach | Caching? Lazy loading? Database optimization? |
| Constraints | What's the target load time? Currently how slow? |
| Scope boundaries | Just dashboard or entire app navigation? |
| Success criteria | How will user measure improvement? Perceived or actual time? |

---

## Pattern 6: Implementation Planning

**Purpose:** Create mechanical, step-by-step implementation plans that separate planning from execution

**When to use:**
- Before implementing any non-trivial feature or change
- When a task involves more than 5 file operations
- After discovery is complete and you're ready to implement
- When you want to validate your implementation approach before coding
- When implementation will be delegated to another agent or developer

**Key benefit:** By creating a validated plan first, you catch design issues early and can optionally delegate execution to a cheaper model (60-70% token savings when using builder handoff).

### The 5-Step Implementation Planning Process

**Step 1: Read the specification completely**

Before creating a plan, understand what you're implementing:

- Read the discovery document, user request, or feature brief completely
- Identify all requirements (explicit and implied)
- Note any constraints or design decisions already made
- List all files that will be affected

**Step 2: Create a mechanical implementation plan**

Write a step-by-step plan using the standard format below. Each step must be **mechanical** — meaning anyone (or any agent) can execute it without making design decisions.

**Implementation Plan Format:**

```markdown
# Implementation Plan

**Created:** [Date]
**Feature/Task:** [Brief description]
**Related Requirements:** [Reference to discovery doc or request]

---

## Pre-Execution Checklist

- [ ] Requirements clearly documented
- [ ] All affected files identified
- [ ] Dependencies understood
- [ ] Backup/version control current
- [ ] Plan validated (see validation step below)

---

## Implementation Steps

### Step N: [Clear action description]
**Operation:** CREATE | EDIT | DELETE | MOVE
**File:** `path/to/file.ext`
**Details:**
- [Operation-specific details — see format spec below]

**Verification:** [How to verify this step completed correctly]

---

## Post-Execution Checklist

- [ ] All steps executed in order
- [ ] Each verification passed
- [ ] No unintended side effects
- [ ] Tests pass (if applicable)
- [ ] Feature works per requirements
```

**Operation Format Specification:**

**CREATE operations:**
- Specify file purpose
- Provide complete initial content OR reference template
- Example: "Create `src/utils/export.ts` — CSV export utility with `generateCSV(data, headers)` function"

**EDIT operations:**
- Provide exact locate string (5-10 lines of context)
- Provide exact replacement string
- Example:
  ```
  Locate:
  ```
  function handleExport() {
    console.log('TODO: implement');
  }
  ```

  Replace with:
  ```
  function handleExport() {
    const data = getUserData();
    const csv = generateCSV(data, CSV_HEADERS);
    downloadFile(csv, 'export.csv');
  }
  ```
  ```

**DELETE operations:**
- State file/function/section to delete
- Provide justification
- Example: "Delete `src/legacy/oldExport.ts` — replaced by new export utility"

**MOVE operations:**
- Specify source → destination paths
- State reason for move
- Example: "Move `utils/export.ts` → `services/export.ts` — aligns with service layer convention"

**Step 3: Validate the implementation plan**

Run a validation loop on your plan using these **7 dimensions**:

1. **Step Clarity** — Does every step have a clear action description? Can someone execute it without guessing?

2. **Mechanical Executability** — Are all design decisions already made? Or does the executor need to make choices?
   - ❌ BAD: "Add error handling" (what kind? where?)
   - ✅ GOOD: "Wrap API call in try-catch, log error to console, show user toast message"

3. **File Coverage** — Are all affected files listed in steps? Any missing from the plan?

4. **Operation Specificity** — For EDIT operations, are locate/replace strings exact? For CREATE, is content specified?

5. **Verification Completeness** — Does each step have a verification method? Can executor confirm success?

6. **Dependency Ordering** — Are steps in correct sequence? Does step N depend on step N-1 completing first?

7. **Requirements Alignment** — Does the plan cover all documented requirements? Any requirements missing from steps?

**Exit criterion:** **1 clean round** (simplified for implementation plans)

Unlike general validation loops (primary clean + 2 sub-agents), implementation plan validation uses a lighter exit criterion:

- Run validation rounds until you achieve 1 clean round (0 issues OR 1 LOW issue fixed)
- No sub-agent confirmations required
- **Rationale:** Implementation plans are narrower scope than discovery docs; single clean round provides sufficient quality assurance

Track `consecutive_clean`:
- Clean round (0 issues OR 1 LOW issue) → `consecutive_clean = 1` → Exit ✅
- Not clean (2+ LOW OR any M/H/C issues) → `consecutive_clean = 0` → Continue

**Step 4: Execute the plan (or hand off to builder)**

Two execution options:

**Option A: Execute yourself**
- Work through steps sequentially
- Follow each step exactly as written
- Run verification after each step
- Mark off pre-execution and post-execution checklist items

**Option B: Hand off to builder agent (optional)**

If your plan is large (>20 steps) and execution is purely mechanical, you can delegate to a cheaper model:

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Execute implementation plan</parameter>
  <parameter name="prompt">You are a builder agent executing a validated implementation plan.

**Your task:** Execute the implementation plan at `implementation_plan.md` step by step.

**Critical rules:**
1. Follow steps exactly as written — make ZERO design decisions
2. Execute steps sequentially (Step 1, then 2, then 3...)
3. Run verification after each step
4. If verification fails: STOP and report to architect immediately
5. If any step is unclear: STOP and report to architect immediately
6. Mark off checklist items as you complete them

**What to report:**
- Success: "All steps completed. Post-execution checklist passed."
- Error: "Step N failed verification: [describe what failed]"
- Unclear: "Step N is unclear: [describe ambiguity]"

Do not proceed if you encounter errors or ambiguity. Report immediately.
  </parameter>
</invoke>
```

**When to use builder handoff:**
- Plan has >20 steps
- You have access to Haiku model
- Implementation is truly mechanical (no design decisions needed)
- **Token savings:** 60-70% by using Haiku for execution

**When NOT to use builder handoff:**
- Plan requires judgment calls during execution
- Steps need context from prior conversation
- Rapid iteration/prototyping work
- Plan is small (<10 steps)

**Step 5: Verify implementation completeness**

After all steps executed (by you or builder):

- Review post-execution checklist
- Test the implemented feature against original requirements
- Verify no unintended side effects in related files
- Confirm all verifications from individual steps passed

If builder reports errors:
- Read the error report
- Fix the plan if step was unclear
- Re-run builder with updated plan
- OR take over execution yourself if builder approach isn't working

### Implementation Planning Example

```markdown
# Implementation Plan

**Created:** 2026-04-02
**Feature/Task:** Add CSV export to user dashboard
**Related Requirements:** See discovery_export_feature.md

---

## Pre-Execution Checklist

- [x] Requirements documented in discovery_export_feature.md
- [x] Affected files: ExportService.java, ExportController.java, Dashboard.tsx, exportUtils.ts (4 files)
- [x] Dependencies: None (self-contained feature)
- [x] Version control: Clean branch `feat/csv-export` created
- [x] Plan validated (1 clean round on 2026-04-02)

---

## Implementation Steps

### Step 1: Create CSV generation utility
**Operation:** CREATE
**File:** `src/services/ExportService.java`
**Details:**
- Create new service class with method `generateCSV(Date startDate, Date endDate)`
- Method queries UserDataRepository.findByDateRange(startDate, endDate)
- Formats results as CSV string with headers: Date, User, Action, Status
- Returns CSV string

**Verification:** Compile succeeds, class exists at correct path

---

### Step 2: Add export API endpoint
**Operation:** CREATE
**File:** `src/controllers/ExportController.java`
**Details:**
- Create REST controller with POST endpoint `/api/export`
- Accepts JSON body: {startDate: string, endDate: string}
- Validates dates (endDate must be after startDate)
- Calls ExportService.generateCSV()
- Returns CSV with headers: Content-Type: text/csv, Content-Disposition: attachment

**Verification:** Server starts without errors, endpoint appears in route list

---

### Step 3: Add export UI controls
**Operation:** EDIT
**File:** `src/components/Dashboard.tsx`
**Details:**

Locate (line 45):
```typescript
return (
  <div className="dashboard">
    <h1>User Dashboard</h1>
    <DataTable data={userData} />
  </div>
);
```

Replace with:
```typescript
return (
  <div className="dashboard">
    <h1>User Dashboard</h1>
    <div className="export-controls">
      <DateRangePicker
        onStartChange={setStartDate}
        onEndChange={setEndDate}
      />
      <button onClick={handleExport}>Export CSV</button>
    </div>
    <DataTable data={userData} />
  </div>
);
```

**Verification:** UI renders without errors, export button visible

---

### Step 4: Implement export handler
**Operation:** EDIT
**File:** `src/components/Dashboard.tsx`
**Details:**

Locate (line 12):
```typescript
function Dashboard() {
  const [userData, setUserData] = useState([]);
```

Replace with:
```typescript
function Dashboard() {
  const [userData, setUserData] = useState([]);
  const [startDate, setStartDate] = useState(null);
  const [endDate, setEndDate] = useState(null);

  const handleExport = async () => {
    const response = await fetch('/api/export', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({startDate, endDate})
    });
    const csv = await response.text();
    downloadFile(csv, 'export.csv');
  };
```

**Verification:** TypeScript compiles without errors, no undefined variables

---

## Post-Execution Checklist

- [ ] All 4 steps executed in order
- [ ] Each step's verification passed
- [ ] Feature tested manually (select dates, click export, CSV downloads)
- [ ] No console errors
- [ ] Tests pass (run `npm test`)
```

### Key Rules

1. **Plans must be mechanical** — No design decisions left to executor
2. **Validate before executing** — Run 7-dimension validation (1 clean round exit)
3. **One step at a time** — Execute sequentially, verify after each
4. **Builder handoff is optional** — Use when plan >20 steps and execution is mechanical
5. **Stop on errors** — Don't continue if verification fails

---

# Part 2: Reference Files (Optional Depth)

The files below provide deeper details on concepts introduced in Part 1. **You don't need to read them to execute the 6 core patterns**, but they're available if you want more context.

## reference/severity_classification_lite.md

Expanded severity classification guidance including:
- Detailed examples for each severity level
- Edge case classification rules
- Escalation criteria
- Common classification mistakes

**When to read:** If you're uncertain about severity classification or encountering borderline cases frequently.

## reference/validation_exit_criteria_lite.md

Detailed mechanics of validation loops including:
- Why we use consecutive_clean counter
- Sub-agent spawning process
- Historical context on exit criteria design
- Troubleshooting validation loops that don't converge

**When to read:** If validation loops aren't converging or you want to understand the theoretical foundation.

## reference/question_brainstorm_categories_lite.md

Extended question brainstorming guidance including:
- 20+ examples per category
- Common patterns (vague requests, bug fixes, performance issues)
- Red flags for under-questioning
- How to present questions to users effectively

**When to read:** If you're struggling to generate questions or want more examples for specific request types.

---

# Part 3: Templates (Copy-Paste Ready)

## templates/discovery_lite.template.md

Template structure for discovery documents. Includes sections for:
- Request Summary
- Research Findings (Technical Analysis, Key Findings)
- Discovery Questions (Resolved and Pending, with 6-category brainstorm table)
- Solution Options (with Pros/Cons/Effort/Fit for each)
- Recommended Approach
- Scope Definition (In/Out/Deferred)
- Validation Status
- User Approval

**When to use:** Starting discovery on any unclear or non-trivial request.

---

## templates/code_review_lite.template.md

Template structure for code review output. Includes:
- **overview.md** template — ELI5, What/Why/How sections
- **review.md** template — Severity-based grouping, 12 categories, validation summary
- Severity definitions (BLOCKING/CONCERN/SUGGESTION/NITPICK)
- Review category list

**When to use:** Reviewing any branch or PR.

---

## templates/implementation_plan_lite.template.md

Template structure for implementation plans. Includes sections for:
- Metadata (Created date, Feature/Task, Related Requirements)
- Pre-Execution Checklist (requirements documented, files identified, plan validated)
- Implementation Steps (step-by-step CREATE/EDIT/DELETE/MOVE operations with verifications)
- Post-Execution Checklist (all steps complete, verifications passed, tests pass)
- Notes section

**When to use:** Before implementing any non-trivial feature or change. Use after discovery is complete.

---

## templates/architecture_lite.template.md

Template for documenting project architecture. Includes sections for:
- Overview (1-3 paragraph description)
- Tech Stack (language, framework, database, testing, package manager)
- Project Structure (directory tree with annotations)
- Core Modules (purpose, key files, dependencies)
- Data Flow (how data moves through the system)
- Key Design Decisions (context, decision, rationale, alternatives)
- Integration Points (external services, APIs, data sources)
- Security Considerations
- Performance Considerations
- Update History

**When to use:** Onboarding to a new project or documenting architecture for future reference.

---

## templates/coding_standards_lite.template.md

Template for documenting team coding standards. Includes sections for:
- Code Style (formatting, linter, naming conventions)
- File Organization (structure, import order)
- Documentation (when to comment, docstring format)
- Error Handling (exception handling patterns, error messages)
- Testing (organization, coverage requirements, test structure)
- Security (common patterns, what to avoid)
- Performance (common patterns, optimization approaches)
- Common Code Patterns (examples with when/how to use)
- Code Review Checklist
- Update History

**When to use:** Establishing team conventions or onboarding new developers.

---

## Quick Reference

### When to use which pattern?

| Situation | Pattern to Use |
|-----------|---------------|
| Just wrote a discovery doc | Pattern 1: Validation Loops |
| Just completed a code review | Pattern 1: Validation Loops |
| Just created an implementation plan | Pattern 1: Validation Loops |
| Unsure if issue is HIGH or MEDIUM | Pattern 2: Severity Classification |
| User request is vague | Pattern 3: Discovery Protocol |
| User asks "review branch X" | Pattern 4: Code Review Process |
| Can't think of questions to ask | Pattern 5: Question Brainstorming |
| Ready to implement after discovery | Pattern 6: Implementation Planning |
| Starting any unclear work | Pattern 3 + Pattern 5 together |

### Validation Loop Cheat Sheet

```
1. Read artifact completely
2. Find issues across dimensions
3. Classify each issue (CRITICAL/HIGH/MEDIUM/LOW)
4. Fix ALL issues immediately
5. Update consecutive_clean counter:
   - Clean round (0 issues OR 1 LOW issue) → +1
   - Not clean (2+ LOW OR any M/H/C) → reset to 0
6. Check exit:
   - consecutive_clean = 0 → repeat
   - consecutive_clean = 1 → spawn 2 sub-agents
   - Both sub-agents find 0 issues → DONE ✅
```

### Severity Classification Cheat Sheet

```
CRITICAL → Blocks workflow, causes failure, or serious risk
HIGH     → Causes confusion or significantly reduces quality
MEDIUM   → Reduces quality or usability noticeably
LOW      → Minor cosmetic issues

Quick questions:
1. Can't complete if not fixed? → CRITICAL
2. Will cause confusion? → HIGH
3. Noticeably worse quality? → MEDIUM
4. Just cosmetic? → LOW
```

### Discovery Protocol Cheat Sheet

```
1. Capture request (2-4 sentences)
2. Research existing systems
3. Brainstorm questions (6 categories)
4. Ask user, document answers
5. Design 2-3 solution options
6. Recommend approach with rationale
7. Define scope (in/out/deferred)
8. Validate discovery doc (loop)
```

### Code Review Cheat Sheet

```
1. Fetch branch metadata (read-only git commands)
2. Create .shamt/code_reviews/<branch>/ directory
3. Write overview.md (ELI5 + What/Why/How)
4. Validate overview.md
5. Write review.md (severity → category grouping)
6. Validate review.md
7. Document validation summary
```

### Implementation Planning Cheat Sheet

```
1. Read specification completely
2. Create mechanical plan (CREATE/EDIT/DELETE/MOVE steps)
3. Validate plan (7 dimensions, 1 clean round exit)
4. Execute plan yourself OR hand off to builder
5. Verify completeness (post-execution checklist)

Operation formats:
- CREATE: Specify purpose + initial content
- EDIT: Exact locate string + replacement
- DELETE: File/section + justification
- MOVE: Source → destination + reason

Builder handoff: Use when >20 steps + mechanical execution
Token savings: 60-70% with Haiku builder
```

---

*Shamt Lite v1.0 — Standalone rules for validation, discovery, code review, and implementation planning*
