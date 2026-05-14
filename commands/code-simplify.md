---
description: Run a dedicated code-simplification session — refactor without behaviour change, in small atomic commits
argument-hint: <path-or-module> [optional: scope=light|deep]
---

# /code-simplify <target> [scope]

You are entering a dedicated simplification session for `$ARGUMENTS`.

This is NOT a phase of the cycle. It is a refactoring session that may happen between phases or as part of `/review`.

## Pre-checks

1. All existing tests pass on the current branch.
2. Working tree is clean (no in-flight changes).
3. The target is one module or one clearly-scoped area — not "the whole codebase".

## What to do

1. **Read** `skills/51-code-simplification/SKILL.md` end to end.
2. **Confirm tests are green:**
   ```bash
   <run-test-suite>
   ```
3. **Measure baseline complexity** (where possible):
   ```bash
   # JS/TS:
   npx -y complexity-report <target>
   # Python:
   radon cc <target> -a -nc
   ```
   Capture in a scratch note.
4. **List candidate refactors.** Be specific:
   - "Extract `validateRefreshToken` from `handleRefresh`"
   - "Replace the three-arm conditional in `pricingTier` with a lookup table"
   - "Rename `data`, `info`, `payload` to their concrete meanings"
5. **Apply ONE refactor at a time:**
   - Make the change
   - Run tests — must remain green
   - Commit with Conventional Commits message starting with `refactor`:
     ```
     refactor(<scope>): <one-line summary>

     Pattern: <extract-function|rename|replace-conditional|...>
     Before:  <N LOC, complexity N>
     After:   <N LOC, complexity N>
     Tests:   unchanged, all passing.
     ```
6. **Stop when:**
   - Complexity has dropped to acceptable, OR
   - You hit diminishing returns, OR
   - You're tempted to mix in a bug fix or behaviour change (stop, complete the refactor, then `/spec` the change separately)
7. **Optional**: write a short ADR if the refactor introduced a new structural pattern (e.g., "we now use Result types for auth errors"). See `skills/63-documentation-and-adrs/SKILL.md`.

## What NOT to do

- Do not change behaviour. If you can't promise the tests cover the behaviour, ADD tests first, in a separate prior commit.
- Do not mix refactor + bug fix + new feature in one commit.
- Do not invent abstractions for "future flexibility". Refactor to remove existing duplication, not imagined future cases.
- Do not refactor on red. All tests must be green at start and at every commit.

## Success of this command

Several small `refactor:` commits. Tests unchanged. Complexity measurably lower or readability measurably better. No behaviour change.
