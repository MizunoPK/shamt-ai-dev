# {{PROJECT_NAME}} — Coding Standards

**Last Updated:** {{DATE}}
**Purpose:** Define project conventions for consistent code reviews and new code

---

## Update History

| Date | Change | Reason |
|------|--------|--------|
| {{DATE}} | Initial creation | Project initialization |

---

## When to Update

Update this document when:
- New coding patterns emerge that should be standard
- Team agrees on new conventions
- Linting or formatting rules change
- Common code review feedback becomes a pattern

**Maintenance:** Update when new patterns emerge or team conventions change

---

## Code Style

### Formatting

**Language:** [e.g., Python, TypeScript, Java]

**Formatter:** [e.g., black, prettier, gofmt]
- Configuration: [link to .prettierrc, pyproject.toml, etc.]
- Run before commit: [command]

**Linter:** [e.g., ruff, eslint, clippy]
- Configuration: [link to config file]
- Run: [command]

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Variables | [snake_case / camelCase] | `user_count` / `userCount` |
| Functions | [snake_case / camelCase] | `get_user()` / `getUser()` |
| Classes | [PascalCase] | `UserManager` |
| Constants | [UPPER_SNAKE_CASE] | `MAX_RETRIES` |
| Files | [snake_case / kebab-case] | `user_manager.py` / `user-manager.ts` |

---

## File Organization

### Project Structure

- **One class per file** (when practical)
- **Group related functionality** in same directory
- **Separate concerns:** models, services, utilities, etc.

### Import Order

[e.g., For Python:]
1. Standard library
2. Third-party packages
3. Local application imports

```python
# Standard library
import os
import sys

# Third-party
import requests
from flask import Flask

# Local
from .models import User
from .services import AuthService
```

---

## Documentation

### Code Comments

**When to comment:**
- Complex algorithms or business logic
- Non-obvious design decisions
- Workarounds for known issues

**When NOT to comment:**
- Obvous code (`i += 1  # increment i`)
- Restating what the code does

### Docstrings/JSDoc

**Required for:**
- All public functions/methods
- All classes
- Module-level documentation

**Format:** [e.g., Google style, NumPy style, JSDoc]

```python
def calculate_score(user_id: int, weight: float = 1.0) -> float:
    """
    Calculate weighted score for a user.

    Args:
        user_id: Unique user identifier
        weight: Score multiplier (default: 1.0)

    Returns:
        Weighted score value

    Raises:
        ValueError: If user_id is invalid
    """
```

---

## Error Handling

### Exception Handling

**Do:**
- Catch specific exceptions, not generic `Exception`
- Log errors with context
- Re-raise when you can't handle
- Clean up resources (use context managers)

**Don't:**
- Swallow exceptions silently
- Use exceptions for control flow
- Catch without logging

```python
# Good
try:
    result = risky_operation()
except SpecificError as e:
    logger.error(f"Operation failed for {user_id}: {e}")
    raise

# Bad
try:
    result = risky_operation()
except Exception:
    pass  # Silent failure
```

### Error Messages

- Be specific about what went wrong
- Include context (IDs, values, state)
- Suggest remediation when possible

---

## Testing

### Test Organization

- **One test file per source file:** `user_manager.py` → `test_user_manager.py`
- **Group related tests** in classes/describe blocks
- **Name tests descriptively:** `test_get_user_returns_none_when_not_found()`

### Test Coverage

**Minimum coverage:** [e.g., 80%]

**Must test:**
- Happy path
- Edge cases
- Error conditions
- Boundary values

**Run tests:** `[command]`

### Test Structure (Arrange-Act-Assert)

```python
def test_user_creation():
    # Arrange
    user_data = {"name": "Test User", "email": "test@example.com"}

    # Act
    user = User.create(user_data)

    # Assert
    assert user.name == "Test User"
    assert user.email == "test@example.com"
```

---

## Security

### Common Patterns

- **Never commit secrets** (use environment variables)
- **Validate all user input**
- **Sanitize output** (prevent XSS)
- **Use parameterized queries** (prevent SQL injection)
- **Check authentication** on all protected routes
- **Log security events** (failed auth, etc.)

---

## Performance

### Common Patterns

- **Avoid N+1 queries** (use joins or batch loading)
- **Cache expensive operations**
- **Use connection pooling**
- **Paginate large result sets**
- **Index database columns** used in WHERE clauses

---

## Common Code Patterns

### Pattern 1: [Name]

**When to use:** [scenario]

**Example:**
```[language]
[code example]
```

### Pattern 2: [Name]

**When to use:** [scenario]

**Example:**
```[language]
[code example]
```

---

## Code Review Checklist

When reviewing code, check for:

- [ ] Follows naming conventions
- [ ] Has appropriate documentation
- [ ] Tests cover new functionality
- [ ] Error handling is appropriate
- [ ] No security vulnerabilities
- [ ] No obvious performance issues
- [ ] Consistent with existing codebase style

---

*Template for Coding Standards documentation in Shamt Lite*
