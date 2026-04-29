# /shamt-promote

**Purpose:** (Master-only) Promote an incoming child project proposal from `design_docs/incoming/` to an active design doc in `design_docs/active/`, assigning a SHAMT-N number.

**Invokes:** `shamt-master-reviewer` skill (partial — the promotion sub-step)

**Restriction:** This command is only wired on the master Shamt repo. Child regen scripts skip wiring it.

---

## Usage

```
/shamt-promote {proposal_file}
```

## Arguments

- `{proposal_file}` (required) — path or filename of the proposal in `design_docs/incoming/`. Example:
  - `design_docs/incoming/myproject-EPIC-005-SHAMT-UPDATE-PROPOSAL.md`

## What Happens

1. Reads the proposal file in `design_docs/incoming/`
2. Reads `design_docs/NEXT_NUMBER.txt` and reserves the next SHAMT-N number
3. Increments `NEXT_NUMBER.txt` (writes N+1)
4. Creates `design_docs/active/SHAMT{N}_DESIGN.md` using the design doc template, incorporating the proposal's content
5. Creates `design_docs/active/SHAMT{N}_VALIDATION_LOG.md`
6. Commits the reservation and new design doc on a `feat/SHAMT-N` branch
7. Optionally deletes or archives the original proposal file from `incoming/`

## Expected Output

- `design_docs/active/SHAMT{N}_DESIGN.md` created, status: Draft
- `design_docs/NEXT_NUMBER.txt` incremented
- Branch `feat/SHAMT-N` created with the new design doc
- Message: "SHAMT-{N} reserved. Design doc at design_docs/active/SHAMT{N}_DESIGN.md — ready for validation."

## Notes

- If the proposal does not warrant a full design doc (can be handled as a direct guide update), use a lightweight approach instead: make the change directly, reference the proposal in the commit message, archive the proposal to `design_docs/archive/`
- If the proposal should be rejected: move it to `design_docs/archive/rejected/` with a rejection note at the top explaining why
- SHAMT-N numbers are sequence markers for change sets, not epic identifiers
