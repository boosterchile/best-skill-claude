---
name: debugging-and-error-recovery
description: Systematically locate, understand, and fix bugs. Use the moment something doesn't behave as expected — not after guessing for 30 minutes. Covers observation, hypothesis, minimal reproduction, instrumentation, and the discipline of fixing root causes rather than symptoms.
requires: nothing
produces:
  - Fix + regression test
  - Optionally a debug-log entry in .specs/<feature>/debug.md for non-trivial bugs
phase: cross-cutting / verify
adapted_from: addyosmani/agent-skills (MIT)
---

# Debugging and Error Recovery

> Guessing is not debugging. If you cannot state the hypothesis you're testing, you are guessing.

## The cycle

```
OBSERVE → HYPOTHESIZE → MINIMAL REPRO → INSTRUMENT → CONFIRM → FIX → REGRESSION TEST
```

Each box has a deliverable. Skipping any box means re-doing it later, usually under more pressure.

## When to use

The moment behaviour deviates from expectation, before you change any code.

## Process

### Step 1 — OBSERVE

Describe what happens, with precision:

- What did you do?
- What did you expect?
- What actually happened?
- Where did you see it (logs, UI, error message, exception stack)?
- When did it start? (Last known good state — commit, deploy, env change)

Write this to `.specs/<feature>/debug.md` for non-trivial bugs. The act of writing forces precision.

### Step 2 — HYPOTHESIZE

State a falsifiable hypothesis:

> "The 401 happens because the refresh token rotates faster than the access token's grace window, so the second request after a rotation has an access token signed by the old key."

Vague hypotheses ("the auth code is broken") aren't testable. Sharpen.

### Step 3 — MINIMAL REPRO

Reduce to the smallest scenario that reproduces the bug.

- One file, one function, one input → ideal
- A trimmed-down branch with the change isolated → acceptable
- "It happens in production sometimes" → not a repro; reduce further

If you can't reduce, instrument to learn (step 4) until you can.

### Step 4 — INSTRUMENT

Add observation without changing behaviour:

- `console.log` / `print` with **named values**, not just the value: `console.log({ tokenAge, gracePeriodMs })`
- Stack traces at the point of failure
- Network tab inspection for HTTP issues
- DB logs / query plans for data issues
- Breakpoints in the debugger for stepwise inspection

Use the debugger, not just logs, when state is complex. macOS: VS Code's "JavaScript Debug Terminal" or `node --inspect` + Chrome devtools.

### Step 5 — CONFIRM

Re-run with instrumentation. The hypothesis is either confirmed or refuted by the data. **Refuted is progress.** Update the hypothesis and re-do step 3.

### Step 6 — FIX

Now you can fix. The fix should:

- Address the **root cause**, not the symptom
- Be minimal — change only what's needed
- Not introduce new behaviour unrelated to the bug
- Have a regression test (step 7) before being committed

If the fix is large, the bug was a symptom of a design issue — open a `/spec` and address it properly.

### Step 7 — REGRESSION TEST

Write a test that:

- Fails with the buggy code
- Passes with the fix
- Has a name that describes the bug, not the fix: `test_refresh_token_grace_period_handles_concurrent_requests` not `test_oauth_refresh_works`

Commit the test in the same commit as the fix. The next maintainer sees them together.

### Step 8 — Document non-obvious causes

If the bug had a counter-intuitive root cause, leave a comment near the fix:

```typescript
// The 401 storm during rotation was caused by the refresh-rotation race
// (see .specs/auth-refresh/debug.md). The grace window must overlap to
// allow in-flight requests signed by the old key to validate.
```

## Rationalizations

| Rationalization | Refutation |
|---|---|
| "Let me try changing X and see if it helps" | That's guessing. Stop. State the hypothesis first. |
| "I'll fix the symptom now, fix it properly later" | Later means "never". The deployed fix becomes the permanent fix by inertia. |
| "I don't need a regression test, I know what I fixed" | The next person doesn't. The you in three months doesn't. |
| "The bug is hard to reproduce, ship the fix anyway" | Then you don't know it's fixed. You know it's no longer happening _now_. |
| "Adding logs and reverting them later is wasteful" | Logs help diagnose the next bug too. Leave them at a sensible level (debug) instead of removing. |

## Red Flags

- "Try-and-see" cycle without explicit hypothesis
- Fix that touches code unrelated to the symptom
- Fix without a regression test in the same commit
- Multiple "small fixes" stacking up — root cause not yet found
- `try / catch` added to suppress an error without understanding why it occurred
- A retry loop added to mask intermittent failures

## Verification

- [ ] Bug reproducible reliably before fix
- [ ] Hypothesis stated explicitly
- [ ] Root cause identified (one sentence, not "various things")
- [ ] Fix is minimal
- [ ] Regression test added, same commit as fix
- [ ] Non-obvious causes documented in code comment

## Solo-Developer Adaptation

The discipline most often broken solo: skipping minimal reproduction. You think you understand the bug; you spend 90 minutes trying fixes; the actual cause is something else entirely. Force yourself to reduce to a minimal case, even (especially) when you're sure you understand.

When you've spent 30 minutes guessing without progress, **stop and restart from OBSERVE**. Write what's happening to debug.md. Re-state the hypothesis. The 5 minutes spent restarting save the next 90.

## macOS Notes

```bash
# Watch logs from a Node process:
node --inspect server.js
# Then open chrome://inspect → Inspect

# Profile a slow function:
node --prof server.js
# Generates isolate-*.log; then:
node --prof-process isolate-*.log

# Inspect macOS system logs (occasional cause of "this works on Linux"):
log stream --predicate 'process == "node"' --info

# Network: see all outbound from a process:
sudo tcpdump -i any -A 'host api.example.com'
```

## Attribution

Adapted from `addyosmani/agent-skills` (MIT, skill `debugging-and-error-recovery`).
