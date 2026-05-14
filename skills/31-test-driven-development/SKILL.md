---
name: test-driven-development
description: Write the failing test first, watch it fail, write the minimum code to make it pass, refactor. Use for any task that introduces new behaviour. Use partially (test-after) for tasks that are pure refactor or trivial config. Mandatory for code paths affecting auth, money, or data integrity.
requires:
  - The behaviour to be implemented is specified in spec.md §3 or §10
produces:
  - Test file(s), then matching production code, then refactored production code
phase: build / verify
adapted_from: addyosmani/agent-skills (MIT)
---

# Test-Driven Development

> The test is not for the code that exists. It is for the code that will exist in six months, in a slightly different shape, after a refactor someone forgot to verify.

## The cycle

```
RED  → write a failing test that describes the next bit of behaviour
GREEN → write the minimum production code to make the test pass
REFACTOR → improve structure without changing behaviour, all tests still green
```

Loop until all tests in spec §10 pass.

## When to use

**Mandatory** for:

- Authentication, authorization
- Anything handling money or charges
- Data integrity (writes, migrations, schema changes)
- Public APIs / interfaces
- Anything that has previously caused an incident
- Anything you don't fully understand (the test forces clarity)

**Recommended** for:

- All new feature work

**Optional** for:

- Pure refactors (existing behaviour preserved; instead, run existing tests before and after)
- Trivial config (a constant changed)

For optional cases, declare `[test-after: <reason>]` in the commit message. The benchmark tracks the ratio.

## Process

### Step 1 — Find the next test from the test list

Spec §10 lists tests T1..Tn. Pick the next one in order, or the one that exercises the next slice of behaviour.

### Step 2 — Write the test (RED)

Write the test, expressing the expected behaviour as an assertion. Run it. **Verify it fails for the right reason** (e.g., "function doesn't exist" or "returns wrong value"). A test that fails for the wrong reason is worse than no test.

The test should:

- Be **isolated**: no dependence on other tests' state
- Be **fast**: < 100ms for unit, < 1s for integration; otherwise it gets skipped under pressure
- Have a **descriptive name**: `test_user_with_invalid_token_receives_401` not `test_auth_1`
- Use **Arrange-Act-Assert** structure

### Step 3 — Make it pass (GREEN)

Write the minimum production code to make the failing test pass. **Minimum**. Hardcoded return value is acceptable if it makes the test pass. The next test will force you to generalise.

This is counter-intuitive but important: don't anticipate the next test. You'll either anticipate wrong or you'll write unused complexity.

### Step 4 — Refactor

Now improve the production code (and tests, if they're ugly). Eliminate duplication, rename for clarity, restructure for separation of concerns. **All tests must remain green throughout.** If a refactor breaks a test, undo and try a smaller step.

### Step 5 — Commit

Commit at green moments. A commit with red tests is a corrupt save state.

### Step 6 — Repeat

Pick the next test from §10. Loop.

## Prove-It pattern

For load-bearing tests, the assertion should be **specific** enough that it would catch a deliberately-broken implementation:

- ❌ `assert result is not None`
- ✅ `assert result.user_id == 'abc' and result.expires_at > now`

A test you could pass by returning `True` is not a test.

## Rationalizations

| Rationalization | Refutation |
|---|---|
| "Writing the test first is slow" | Writing the test after takes longer total time because you have to undo assumptions baked into the implementation. |
| "I'll add tests at the end" | At the end you write tests that confirm the code does what it does, not tests that confirm the code does what it should. Different artefact. |
| "This logic is too simple for a test" | Then the test is short. Cost is minutes. |
| "TDD doesn't work for UI" | TDD works for UI logic (state machines, reducers, computed values). Visual regression and accessibility are separate concerns; see `40-browser-testing-with-devtools`. |
| "Mocks are a pain" | Excessive mocking is a smell that your design has too many seams. Refactor seams, not tests. |
| "100% coverage is the goal" | No. The goal is that every behaviour in spec §3 and §10 has a corresponding test. Coverage is downstream metric. |

## Red Flags

- Tests that don't fail when you delete the production code (the assertion is too weak)
- Tests that always pass (no observable behaviour being checked)
- Tests sharing state via global variables
- Tests that take > 5 seconds (will be skipped under deadline pressure)
- Production code without any test in the same commit (in TDD mode)
- "TODO: test later" comments

## Verification

- [ ] Every behaviour in spec §3 has at least one test
- [ ] Every test in spec §10 exists in code
- [ ] All tests pass (`<run-tests>` output captured in `.specs/<feature>/verify.md`)
- [ ] No skipped tests without a documented reason
- [ ] Coverage of changed code ≥ 80% (run language-specific tool)

## Solo-Developer Adaptation

Solo, the temptation to skip TDD is highest because there's no review. To compensate:

1. **Hard rule**: code that handles authentication, money, or data integrity is TDD-mandatory. No waiver.
2. **For everything else**: the rule is "test in the same commit as the code". If you cannot do TDD, do test-after-but-same-commit. Tests in a later commit, or "later PR", or "later sprint" rarely happen.
3. Run `bash benchmark/scripts/score-session.sh --since "30 days ago"` monthly. If TDD compliance is below 50%, you are sliding toward "tests later".

## macOS Notes

Run tests with watch:

```bash
# Node: vitest in watch mode (default)
npm test

# Python:
pip install pytest-watch
ptw -- -x

# Rust:
cargo install cargo-watch
cargo watch -x test
```

## Attribution

Adapted from `addyosmani/agent-skills` (MIT, skill `test-driven-development`).
