---
description: Start BUILD phase — execute the next task in .specs/<feature>/plan.md
argument-hint: <feature-slug> [optional: task-id like T2]
---

# /build <feature-slug> [task-id]

You are entering the BUILD phase for `$ARGUMENTS`.

## Pre-checks

1. `.specs/$ARGUMENTS/plan.md` exists and was approved.
2. The previous task's `[DONE]` marker is set if you're picking up mid-plan.
3. Working tree is clean (no uncommitted changes from another task).

## What to do

1. **Read** `skills/30-incremental-implementation/SKILL.md`. If the change introduces new behaviour, also read `skills/31-test-driven-development/SKILL.md`. If unfamiliar code, also `skills/33-source-driven-development/SKILL.md`. If UI, also `skills/34-frontend-ui-engineering/SKILL.md`.

2. **Pick the next task.** From `plan.md`, the first task whose dependencies are all `[DONE]` and which isn't itself done. State it: "I'm starting T<N>: <description>."

3. **Pre-build articulation** (mandatory rubber-duck):
   ```bash
   LEDGER="$(cat .claude/ledger/.current)"
   cat >> "$LEDGER" <<JSON
   {"ts":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","type":"pre_build_articulation","feature":"$ARGUMENTS","task":"T<N>","plan":"<one sentence>","alternatives":["A","B"],"failure_modes":["F1","F2"]}
   JSON
   ```

4. **TDD when applicable.** New behaviour → write the failing test first. Watch it fail for the right reason. Then write the minimum code to pass. Then refactor with all green.

5. **Smallest steps possible.** Run tests after each non-trivial change. Commit at green moments. Use Conventional Commits referencing the task:
   ```
   <type>(<scope>): <summary>

   Closes T<N> of .specs/$ARGUMENTS/plan.md
   - <bullet>
   - <bullet>

   Tests: <one line>
   ```

6. **Mark the task done** in `plan.md`:
   ```diff
   - ### T<N>: <description>
   + ### T<N>: <description> [DONE <ISO-date>]
   ```
   Commit that change with the implementation (or as part of the same commit, your choice).

7. **Stop and reassess.** Is the next task still the right next thing? If your understanding changed, reopen `/plan` rather than improvise.

## What NOT to do

- Do not start more than one task in flight. Clean working tree before starting the next.
- Do not skip the pre-build articulation. The benchmark tracks it.
- Do not skip tests for behaviour-introducing tasks. If you must, declare `[test-after: <reason>]` in the commit message.
- Do not exceed 100 LOC in a single task — split first.

## Success of this command

The next task in `plan.md` is `[DONE]`, with a clean commit, passing tests, and the ledger updated.
