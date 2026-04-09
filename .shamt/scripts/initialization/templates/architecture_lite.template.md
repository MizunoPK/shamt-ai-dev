# {{PROJECT_NAME}} — Architecture

**Last Updated:** {{DATE}}
**Purpose:** High-level system overview for context during discovery and code reviews

---

## Update History

| Date | Change | Reason |
|------|--------|--------|
| {{DATE}} | Initial creation | Project initialization |

---

## When to Update

Update this document when:
- New modules, services, or major components are added
- Data flow between components changes
- Integration patterns are added or modified
- Significant dependencies are added
- Architectural decisions affect multiple features

**Maintenance:** Review quarterly or when significant changes are made

---

## Overview

[1-3 paragraph description of what this project does, its purpose, and its primary users.]

---

## Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Language | [e.g., Python 3.11] | |
| Framework | [e.g., FastAPI, React] | |
| Database | [e.g., PostgreSQL, MongoDB] | |
| Testing | [e.g., pytest, jest] | |
| Package manager | [e.g., npm, poetry] | |

---

## Project Structure

```
[project root]/
├── [dir/]          — [what it contains]
├── [dir/]          — [what it contains]
└── ...
```

**Key directories:**
- `[dir]/` - [purpose]
- `[dir]/` - [purpose]

---

## Core Modules

### Module 1: [Name]

**Purpose:** [what it does]

**Key files:**
- `path/to/file.ext` - [role]
- `path/to/file.ext` - [role]

**Dependencies:**
- Internal: [other modules]
- External: [libraries]

### Module 2: [Name]

[Repeat structure]

---

## Data Flow

[Describe how data moves through the system from input to output.]

**Example flow:**
```
User Input → [Component A] → [Component B] → [Component C] → Output
```

---

## Key Design Decisions

### Decision 1: [Title]

**Context:** [What problem or choice]

**Decision:** [What was chosen]

**Rationale:** [Why]

**Alternatives considered:** [What was rejected and why]

### Decision 2: [Title]

[Repeat structure]

---

## Integration Points

### External Services

- **[Service Name]:** [Purpose, how integrated]

### APIs

- **[API Name]:** [Endpoints, authentication, purpose]

### Data Sources

- **[Source Name]:** [Type, format, how accessed]

---

## Security Considerations

[Authentication methods, authorization patterns, data protection, key security requirements]

---

## Performance Considerations

[Key performance targets, bottlenecks, caching strategies, scaling approaches]

---

*Template for Architecture documentation in Shamt Lite*
