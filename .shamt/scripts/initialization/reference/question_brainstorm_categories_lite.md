# Question Brainstorm Categories

**Extends Pattern 3 (Spec Protocol) in SHAMT_LITE.md — read that first.**

**Purpose:** Extended examples for the 6-category question brainstorm framework used during Spec Protocol Step 4

---

## How to Use This Reference

**During Spec Step 4 (design dialog):** Use these categories to surface open questions that affect which design option to recommend or that the user needs to answer before the spec can be written.

**Show categories with questions; omit empty ones.** The brainstorming happens mentally — consider all 6 categories, but only write output for the ones that produced questions.

**During Spec Step 6 validation:** Use the "Open questions" dimension check to verify you haven't missed any category that should have produced questions.

**Red flag:** Zero questions across all 6 categories for a non-trivial ticket is suspicious. Re-read the ticket looking for ambiguous terms, undefined processes, or hidden assumptions you made without noticing.

---

## The 6 Categories

### 1. Functional Requirements

*What to ask:*
- What does [ambiguous term] actually mean in this context?
- Expected behavior when [condition]?
- What if [edge case occurs]?
- How should [input type] be handled?

*Examples:*
- "What does 'debugging version run' mean?"
- "What constitutes a 'valid' export format?"
- "How should 'better performance' be measured?"
- "What happens when the sync fails midway — resume or restart?"

### 2. User Workflow / Edge Cases

*What to ask:*
- What if only some [items] need this?
- How does this interact with existing [system/feature]?
- What happens at boundary conditions (empty set, maximum size, concurrent access)?
- Who else (users, systems, teams) is affected but not mentioned in the ticket?

*Examples:*
- "What if only some scripts need debug mode?"
- "How does this affect existing users who rely on the current behavior?"
- "What happens under concurrent access — two users exporting at once?"

### 3. Implementation Approach

*What to ask:*
- Extend existing component vs. create new service?
- What architecture options exist (API design, data structure, pattern)?
- How should errors and failures be handled and surfaced?
- What's the deployment / migration strategy?

*Examples:*
- "Should this be a command-line flag or a config file setting?"
- "Extend ExportService or create a new BulkExportService?"
- "REST API or event-driven for the async export?"

### 4. Constraints

*What to ask:*
- Performance targets (latency, throughput, size limits)?
- Security or compliance requirements (auth, data access, logging)?
- Backward compatibility requirements (API versioning, existing integrations)?
- Platform or technology limitations?

*Examples:*
- "Does this need to support 1M rows or 1k rows?"
- "Are there regulatory requirements (GDPR, HIPAA) around the data being exported?"
- "Must work on mobile devices?"
- "What's the acceptable response time for the export operation?"

### 5. Scope Boundaries

*What to ask:*
- What's explicitly in scope vs. out of scope?
- Where does this feature's responsibility end?
- What gets deferred to future work?
- What about cases where this partially overlaps with existing feature Y?

*Examples:*
- "Do all 6 scripts need this, or just a subset?"
- "CSV export only for now, or also JSON/PDF?"
- "Just the dashboard or all data views?"

### 6. Success Criteria

*What to ask:*
- How will the user verify this works correctly?
- What does "done" look like in concrete, observable terms?
- What tests or demonstrations prove completeness?
- What would make the user say "this is exactly what I needed"?

*Examples:*
- "How will we verify the export handles 100k rows without OOM?"
- "What specific scenarios should we test?"
- "What measurable improvement defines success for the performance fix?"

---

## Examples by Request Type

### Vague Feature Request: "Add export functionality"

| Category | Questions to surface |
|----------|---------------------|
| Functional | Export to what format? CSV, JSON, PDF? All three? |
| User workflow | Export all data or allow date range selection? |
| Approach | Server-side generation or client-side? Streaming or in-memory? |
| Constraints | Max rows? Must complete in X seconds? |
| Scope | Just current view or historical data too? |
| Success | Speed target? What does a successful export look like? |

### Bug Fix: "Fix the login timeout issue"

| Category | Questions to surface |
|----------|---------------------|
| Functional | What exactly is timing out — session, DB connection, UI interaction? |
| User workflow | All users or specific scenario (mobile, slow network)? |
| Approach | Fix root cause or increase timeout as workaround? |
| Constraints | Security implications of a longer session timeout? |
| Scope | Just login flow or all authenticated requests? |
| Success | How do we verify it's fixed — specific test scenarios? |

### Performance Request: "Dashboard loads too slow"

| Category | Questions to surface |
|----------|---------------------|
| Functional | Which parts — initial load, widget refresh, interactions? |
| User workflow | Which user scenarios — empty vs full dashboard? High-data vs low-data accounts? |
| Approach | Caching, lazy loading, DB query optimization, or a combination? |
| Constraints | Target load time? Current baseline? Budget for infrastructure changes? |
| Scope | Just dashboard or all data-heavy views? |
| Success | Measured how — Real User Monitoring, Lighthouse, specific user scenarios? |

---

*Extends Pattern 3 (Spec Protocol) in SHAMT_LITE.md*
