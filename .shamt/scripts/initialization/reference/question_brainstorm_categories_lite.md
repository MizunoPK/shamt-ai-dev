# Question Brainstorming Categories

**Purpose:** Systematic framework for uncovering hidden assumptions and requirements

---

## The 6 Categories

Use these categories to brainstorm questions when exploring requirements, starting new work, or clarifying ambiguous requests.

### 1. Functional Requirements

**What to ask:**
- What does [ambiguous term] actually mean?
- What's the expected behavior when [condition]?
- What should happen if [edge case occurs]?
- How should the system respond to [input]?

**Examples:**
- "What does 'debugging version run' mean?"
- "What constitutes a 'valid' request?"
- "How should 'better performance' be measured?"

---

### 2. User Workflow / Edge Cases

**What to ask:**
- What if only some [items] need this feature?
- How does this interact with existing [system/feature]?
- What breaks when [condition occurs]?
- Are there workflows or users not mentioned in the request that will be impacted?
- What happens at the boundary cases?

**Examples:**
- "What if only some scripts need debug mode?"
- "How does this affect existing users who rely on the current behavior?"
- "What happens when the system is under heavy load?"

---

### 3. Implementation Approach

**What to ask:**
- What are the API design options?
- What data structures should we use?
- Should we use [library A] or [library B]?
- What high-level architecture choices need to be made?
- How should errors be handled?
- What's the deployment strategy?

**Examples:**
- "Should this be a command-line flag or a config file setting?"
- "Should we use REST API or GraphQL?"
- "Do we need a database or is file-based storage sufficient?"

---

### 4. Constraints

**What to ask:**
- Are there performance targets?
- Security requirements or compliance needs?
- Backward compatibility requirements?
- Scale expectations (number of users, data volume)?
- Platform or technology limitations?
- Budget or resource constraints?

**Examples:**
- "Does this need to support 1000 concurrent users or 10?"
- "Are there regulatory requirements (GDPR, HIPAA, etc.)?"
- "Must it work on mobile devices?"
- "What's the acceptable response time?"

---

### 5. Scope Boundaries

**What to ask:**
- What's explicitly in-scope?
- What's explicitly out-of-scope?
- Where does this feature's responsibility end?
- What about cases where this partially overlaps with existing feature Y?
- What gets deferred to future work?

**Examples:**
- "Do all 6 scripts need this, or just a subset?"
- "Is offline mode in scope or deferred?"
- "Should this handle CSV and JSON, or just CSV for now?"

---

### 6. Success Criteria

**What to ask:**
- How will the user verify this works correctly?
- What does the ideal end state look like in concrete terms?
- How do we know when we're done?
- What tests or demonstrations will prove this is complete?
- What would make the user say "this is exactly what I needed"?

**Examples:**
- "How will the user verify debug mode works correctly?"
- "What specific scenarios should we test?"
- "What measurable improvement defines success?"

---

## How to Use This Framework

### Step 1: Work Through All Categories

For each category, either:
- **Identify specific questions**, OR
- **Write a one-line justification** for why none apply

**Example Brainstorm Table:**

| Category | Questions identified (or justification if none) |
|----------|--------------------------------------------------|
| **Functional requirements** | What does "faster sync" mean? Seconds? Minutes? |
| **User workflow / edge cases** | What if sync fails midway? Resume or restart? |
| **Implementation approach** | None identified — approach is clear from request |
| **Constraints** | Performance target? Current sync takes how long? |
| **Scope boundaries** | Just user data or system config too? |
| **Success criteria** | How will user measure "faster"? |

### Step 2: Present Questions to User

Don't assume answers. Ask the user and document their responses.

### Step 3: Update Requirements

Incorporate answers into your discovery document, spec, or plan.

---

## Red Flags

🚨 **Zero questions across all categories?**

You're almost certainly under-questioning. Re-read the request looking for:
- Ambiguous terms ("better", "faster", "improved")
- Undefined processes ("sync", "validate", "optimize")
- Hidden assumptions you're making
- Missing context

---

## Common Patterns

### Pattern: Vague Feature Request

**Request:** "Add export functionality"

**Questions by Category:**
1. Functional: Export to what format? CSV, JSON, PDF? All three?
2. Workflow: Export all data or allow selection? One-time or scheduled?
3. Approach: Server-side generation or client-side?
4. Constraints: Size limits? 100 rows vs 1 million rows?
5. Scope: Just current view or historical data too?
6. Success: What makes a "good" export? Speed? Completeness?

---

### Pattern: Bug Fix Request

**Request:** "Fix the login timeout issue"

**Questions by Category:**
1. Functional: What exactly is timing out? Session? Connection? UI interaction?
2. Workflow: Affecting all users or specific scenarios?
3. Approach: Fix root cause or increase timeout duration? Both?
4. Constraints: Security implications of longer timeouts?
5. Scope: Just login or all authentication flows?
6. Success: How will we verify it's fixed? Specific test cases?

---

### Pattern: Performance Request

**Request:** "Make the dashboard load faster"

**Questions by Category:**
1. Functional: Which parts? Initial load? Data refresh? Interactions?
2. Workflow: Fast for which scenarios? Empty dashboard vs full of widgets?
3. Approach: Caching? Lazy loading? Database optimization?
4. Constraints: What's the target load time? Currently how slow?
5. Scope: Just dashboard or entire app navigation?
6. Success: How will user measure improvement? Perceived or actual time?

---

*Adapted from Shamt S1.P3 Discovery Phase Question Brainstorming Framework*
