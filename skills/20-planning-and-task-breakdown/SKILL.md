---
name: planning-and-task-breakdown
description: PLAN phase. Convert an approved spec.md into a sequence of atomic, individually shippable tasks. Produce plan.md with tasks ordered by dependency, each estimated and scoped to ~100 LOC or less. Use after /spec is approved, before any code is written.
requires:
  - .specs/<feature>/spec.md with Status Approved
produces:
  - .specs/<feature>/plan.md
phase: plan
adapted_from: addyosmani/agent-skills (MIT)
---

# Planning and Task Breakdown

> A plan is not a Gantt chart. It is a sequence of commits where each commit, alone, leaves the system in a working state.

## When to use

Trigger `/plan` after `/spec` is approved. Do not start planning while the spec is still in `Draft`.

## Process

### Step 1 — Read the spec cold

Re-read `.specs/<feature>/spec.md`. Specifically §3 (Success criteria), §7 (Approach), §10 (Test list). The plan must trace back to these.

### Step 2 — Identify modules touched

List every directory, file, or module the change will touch. If the list exceeds 10 modules, the spec is too large — go back to `/spec` and split.

### Step 3 — Define vertical slices

Each task is a **vertical slice**:

- It compiles
- It tests
- It can be merged independently behind a feature flag if needed
- It moves the system one step closer to the success criteria

Anti-pattern: horizontal slices ("first do the DB migration, then the API, then the UI"). These produce broken intermediate states.

### Step 4 — Estimate

For each task, estimate LOC delta. If any task exceeds **100 LOC net change**, split it. The 100 LOC limit is empirical: above it, review quality drops and reverts become painful.

### Step 5 — Order by dependency

A task may depend on another. Order such that:

- Dependencies come first
- Earlier tasks are more reversible
- The highest-risk task lands as early as possible while still respecting dependencies (so you learn fast)

### Step 6 — Write plan.md

```markdown
# Plan: <feature>

- Spec: .specs/<feature>/spec.md
- Created: <ISO>
- Status: Active | Complete

## Tasks

### T1: <one-line description>
- Files: <list>
- LOC estimate: <N>
- Depends on: <none | T0>
- Acceptance: <how we know T1 is done; should map to a test in spec §10>
- Rollback: <how to revert if T1 lands and is wrong>

### T2: ...

(repeat)

## Out-of-band tasks
Items that are not in the critical path but should not be forgotten.

- <e.g., update .env.example>
- <e.g., add migration to staging>

## Open questions
Anything that emerged during planning and must be resolved before /build.
```

### Step 7 — Devils-advocate pass

Invoke the `devils-advocate` sub-agent. The most common objection it raises is "T_n is two tasks pretending to be one" — listen.

### Step 8 — User confirmation

Present the plan. Wait for explicit approval. Update status, commit `plan.md`, write ledger entry.

## Rationalizations

| Rationalization | Refutation |
|---|---|
| "I'll figure it out as I go" | You'll figure out the wrong sequencing as you go. Plan now, commit small chunks, adjust. |
| "Tasks are too small" | Smaller tasks = faster reverts = faster recovery from wrong calls. There is no such thing as too-small for a vertical slice that still represents value. |
| "100 LOC is arbitrary" | It is. Pick a different number if you have data. Default is conservative; raise it deliberately and log why. |
| "Horizontal slicing is simpler" | Simpler to write. More expensive to debug because every intermediate commit is broken. |

## Red Flags

- A task with no acceptance criterion
- A task with no rollback plan when the deployment is real
- Plan has 1 task only (the feature is one big commit — split it)
- Plan has 15+ tasks (the feature is too big — split the spec)
- Tasks reference files that don't exist in the spec's approach section

## Verification

- [ ] All tasks vertical slices (compile + test + mergeable independently)
- [ ] All tasks ≤ 100 LOC estimate (or waiver logged)
- [ ] Acceptance traces to spec §3 or §10 for every task
- [ ] Rollback plan for each task that lands in production
- [ ] Devils-advocate output captured

## Solo-Developer Adaptation

In solo mode, the cooling-off rule applies between `/plan` and `/build`. Once `plan.md` is approved, leave it. Come back to it before starting T1 and re-read. If anything looks suspect with fresh eyes, revise.

## macOS Notes

Quick task lister:

```bash
grep '^### T' .specs/<feature>/plan.md | sed 's/^### //'
```

## Attribution

Adapted from `addyosmani/agent-skills` (MIT, skill `planning-and-task-breakdown`).
