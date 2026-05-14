---
name: incremental-implementation
description: BUILD phase. Execute one task at a time from plan.md, each ending in a working commit. Use after /plan is approved. Never implement more than one task per slot without merging or marking the previous done in plan.md.
requires:
  - .specs/<feature>/plan.md with at least one task
produces:
  - Source code commits, plan.md status updates
phase: build
adapted_from: addyosmani/agent-skills (MIT)
---

# Incremental Implementation

> Big-bang implementations are how you discover, at the end, that the spec was wrong in section 7. Incremental implementation discovers it after T2.

## When to use

Triggered by `/build` after `/plan` is approved. Walks the agent through each task in `plan.md` one at a time.

## Process

### Step 1 — Pick the next task

Read `plan.md`. Pick the first task whose dependencies are all marked complete and which isn't itself complete. State which task you're starting.

### Step 2 — Pre-build articulation (mandatory)

Before writing any code, articulate to the ledger:

```bash
LEDGER="$(cat .claude/ledger/.current)"
cat <<JSON >> "$LEDGER"
{"ts":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","type":"pre_build_articulation","task":"T1","plan":"<short paragraph>","alternatives":["A","B"],"failure_modes":["F1","F2","F3"]}
JSON
```

This is the rubber-duck. Skipping it gets caught by the benchmark.

### Step 3 — Tests first (when applicable)

If the task introduces new behaviour, follow `31-test-driven-development`: write the failing test before the production code. Skip only for tasks that are pure refactor (existing behaviour, new structure).

### Step 4 — Implement in the smallest steps possible

Write a few lines. Save. Run the tests. Commit if green. Repeat. The smallest steps imaginable. The agent should run tests after each non-trivial change, not at the end.

### Step 5 — One task, one commit (ideal) or one branch (if multi-commit)

For tasks ≤ 100 LOC, a single squashed commit is preferred. For genuinely multi-step tasks, a feature branch with multiple commits that squash on merge.

Commit message format:

```
<short imperative summary>

Closes T<N> of .specs/<feature>/plan.md
- <bullet 1>
- <bullet 2>
- <bullet 3>

Tests: <one line>
```

### Step 6 — Update plan.md

Mark the task complete in `plan.md`:

```diff
- ### T1: Add OAuth provider abstraction
+ ### T1: Add OAuth provider abstraction [DONE 2026-05-13]
```

Commit that change with the implementation.

### Step 7 — Stop and reassess

After each task: check whether the next task in `plan.md` is still the right next thing, given what you learned. If not, **stop building** and reopen `/plan`. This is a feature, not a delay.

### Step 8 — Loop

Pick the next task. Repeat.

## Rationalizations

| Rationalization | Refutation |
|---|---|
| "Let me just finish T1, T2, T3 in one go, it's all related" | Then they should be one task. Reopen `/plan`. |
| "I can skip the test for this one, it's simple" | Then add the test after — but **before** marking the task done. |
| "I'll commit at the end, all together" | At the end you have one giant commit no one (including you) can review. |
| "Re-running tests between every change is slow" | If tests are slow, fix the tests. Slow tests are a forcing function against TDD. |
| "I don't need to update plan.md, it's obvious what's done" | Not obvious next month. Not obvious to the benchmark. Update it. |

## Red Flags

- Multiple tasks in flight in the working tree (uncommitted changes touching files from T1, T2, T3 simultaneously)
- Tests not run since "started"
- Commits without task references
- 200+ LOC in a single task (split it; reopen /plan)
- No tests added for tasks introducing behaviour

## Verification

- [ ] One task in flight at a time (clean working tree before starting the next)
- [ ] Tests run and pass before committing
- [ ] Commit message references the task and `.specs/<feature>/plan.md`
- [ ] `plan.md` updated with [DONE <date>] markers
- [ ] Ledger has `pre_build_articulation` for each task

## Solo-Developer Adaptation

Two solo-specific habits:

1. **Time-box each task.** If a task estimated at 60 minutes is at 120 minutes, stop. Either the estimate was wrong (revise) or the approach is wrong (return to `/plan`).
2. **Commit even on "I'll throw this away later".** A commit you can revert is infinitely better than uncommitted work you might lose to a stray `git reset`.

## macOS Notes

Run tests in a watch loop:

```bash
# fswatch is the macOS file watcher:
brew install fswatch
fswatch -o src/ | xargs -n1 -I{} npm test
```

For Python/Node/Rust, prefer the project's own watch mode (e.g. `cargo watch`, `nodemon`, `pytest-watch`).

## Attribution

Adapted from `addyosmani/agent-skills` (MIT, skill `incremental-implementation`).
