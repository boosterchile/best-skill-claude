---
description: Start PLAN phase — decompose .specs/<feature>/spec.md into atomic tasks
argument-hint: <feature-slug>
---

# /plan <feature-slug>

You are entering the PLAN phase for `$ARGUMENTS`.

## Pre-checks

1. `.specs/$ARGUMENTS/spec.md` must exist with `Status: Approved`. If not, refuse and tell the user to run `/spec` first.
2. CLAUDE.md must be in context.

## What to do

1. **Read** `skills/20-planning-and-task-breakdown/SKILL.md`.
2. **Re-read the spec cold.** Especially §3 (success criteria), §7 (approach), §10 (test list).
3. **Identify the modules touched.** If > 10, the feature is too big — go back to `/spec` and split.
4. **Decompose into vertical slices.** Each task:
   - Compiles, tests, mergeable independently
   - ≤ 100 LOC net change (waiver if larger, with reason)
   - Has acceptance criteria traceable to spec §3 or §10
   - Has a rollback plan
5. **Order by dependency**, with high-risk early when possible.
6. **Write** `.specs/$ARGUMENTS/plan.md` per the template in the skill.
7. **Invoke `devils-advocate`** sub-agent on the plan. Objections are most often "T_n is two tasks pretending to be one" — listen.
8. **Present to user.** Wait for approval.
9. **On approval:**
   ```bash
   LEDGER="$(cat .claude/ledger/.current)"
   echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"artifact_produced\",\"kind\":\"plan\",\"path\":\".specs/$ARGUMENTS/plan.md\"}" >> "$LEDGER"
   echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"phase_exit\",\"phase\":\"plan\",\"feature\":\"$ARGUMENTS\"}" >> "$LEDGER"
   ```

## What NOT to do

- Do not start implementing. `/build` is next.
- Do not skip task estimates. The 100 LOC threshold is the simplest discipline you have against scope creep mid-task.
- Do not horizontal-slice ("do all DB first, then all API, then all UI"). Vertical slices only.

## Success of this command

`.specs/$ARGUMENTS/plan.md` exists with all tasks vertical and ≤ 100 LOC, devils-advocate captured, user approved.
