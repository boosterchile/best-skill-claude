---
name: code-simplification
description: Reduce complexity without changing observable behaviour. Use during /review when complexity metrics or "this is hard to read" signals fire. Use deliberately as a refactoring session — never mixed with new behaviour in the same commit.
requires:
  - Existing tests pass
produces:
  - Refactored code, same tests passing
phase: review
adapted_from: addyosmani/agent-skills (MIT)
---

# Code Simplification

> Refactor is the act of changing structure without changing behaviour. If you cannot run the tests before and after and get the same green output, you are not refactoring — you are rewriting.

## When to use

- Cyclomatic complexity rises above threshold for the project
- A function exceeds ~50 lines or 1 screen
- Indentation exceeds 4 levels
- The same logic repeats in 3+ places
- Naming has drifted (variables/functions don't say what they mean)
- Comments explain _what_ the code does (a smell — the code should say what; comments say why)

## The cardinal rule

**One commit, one type of change.** Never mix:

- Bug fix + refactor
- New feature + refactor
- Two unrelated refactors

Each commit must answer one question: "what is this trying to accomplish?"

## Process

### Step 1 — Confirm tests are green

```bash
<run-test-suite>
```

If any are failing, fix them first or revert to a green state. You cannot refactor red code.

### Step 2 — Identify the simplification opportunity

Be specific:

- "Extract `validateRefreshToken` from `handleRefresh` to a separate function"
- "Replace the three-arm conditional with a lookup table"
- "Rename `data`, `info`, `payload` to their actual meanings"

Vague refactors ("make it cleaner") lead to scope creep.

### Step 3 — Make one change

Smallest viable change. Run tests. If green, commit. Repeat.

### Step 4 — Common refactors

#### Extract function

When: a block of code has a clear name and is reused, or it's > 10 lines inside a larger function.

```typescript
// Before:
function handleRequest(req) {
  // ... 5 lines of validation
  // ... 10 lines of processing
  // ... 5 lines of response
}

// After:
function handleRequest(req) {
  const validated = validate(req);
  const result = process(validated);
  return respond(result);
}
```

#### Rename

When: a name doesn't say what it means.

```typescript
// Before:
const d = items.filter(i => i.x > t);

// After:
const overdueInvoices = invoices.filter(invoice => invoice.dueDate > today);
```

Run tests after rename. Verify nothing depends on the old name (greps).

#### Replace conditional with polymorphism

When: a `switch` or `if/else` on a type tag appears in multiple places.

```python
# Before (duplicated in three modules):
if shape.kind == 'circle':
    area = pi * shape.r ** 2
elif shape.kind == 'square':
    area = shape.side ** 2

# After:
class Circle:
    def area(self): return pi * self.r ** 2
class Square:
    def area(self): return self.side ** 2
```

#### Replace nested conditional with guard clauses

```typescript
// Before:
function process(req) {
  if (req.user) {
    if (req.user.active) {
      if (req.body) {
        // actual work
      }
    }
  }
}

// After:
function process(req) {
  if (!req.user) return reject('no user');
  if (!req.user.active) return reject('inactive');
  if (!req.body) return reject('no body');
  // actual work
}
```

#### Replace comments with named extractions

```typescript
// Before:
// Check if the user can access this resource based on role and ownership
if (user.role === 'admin' || resource.ownerId === user.id) { ... }

// After:
if (canAccess(user, resource)) { ... }
```

The comment becomes a function name; the function tests itself.

### Step 5 — Update tests if structure changed

If you extracted a function, the new function deserves its own focused tests. Add them in the same commit.

If you renamed across modules, search for any test that hardcoded the old name.

### Step 6 — Re-measure

Compare the complexity numbers before and after. Document the delta in the commit message:

```
refactor(auth): extract token validation

- handleRefresh: 47 → 18 LOC, cyclomatic 8 → 3
- New: validateRefreshToken (15 LOC, cyclomatic 4)

Tests: unchanged, all passing.
```

## Rationalizations

| Rationalization | Refutation |
|---|---|
| "I'll refactor this while I'm in here, just a bit" | Mixed commits are how refactors hide behaviour changes. Separate. |
| "It works, why refactor" | Until the next change needs to touch it. Refactor unlocks future changes. |
| "Refactoring without tests is fine if I'm careful" | You cannot prove preservation without tests. Add tests first or don't refactor. |
| "I'll make it abstract for future flexibility" | Premature abstraction is more expensive than the concrete duplication you started with. Refactor to remove _existing_ duplication, not to enable _imagined_ future cases. |

## Red Flags

- Refactor commit that touches > 200 lines
- Refactor commit with `+15 -20` (suspicious; either it's actually a behaviour change or the tests are weak)
- Refactor that adds a parameter "for future use"
- Comment removed without rename (the rename should make the comment unnecessary)
- Test changed in the same commit ("just adjusting the test to match")

## Verification

- [ ] Tests green before refactor
- [ ] Tests green after refactor (same tests, no modification)
- [ ] If tests were added or split, they were added in a separate prior commit
- [ ] Complexity numbers improved (or hold steady but readability gained)
- [ ] Commit message names the specific refactor pattern

## Solo-Developer Adaptation

When you refactor your own code, you'll be tempted to "fix the bug while you're there". Don't. Stash. Refactor cleanly. Commit. Then unstash and fix the bug. Two commits, two reverts available.

## macOS Notes

Tools:

```bash
# Cyclomatic complexity, JS/TS:
npx -y complexity-report src/

# Python:
pip3 install --user radon
radon cc src/ -a -nc       # cyclomatic complexity, sorted

# Universal duplication detection:
npx -y jscpd src/

# Visualise complexity:
npx -y code-complexity src/ --filter '**/*.ts' --sort score
```

## Attribution

Adapted from `addyosmani/agent-skills` (MIT, skill `code-simplification`).
