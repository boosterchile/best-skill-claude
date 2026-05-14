---
description: Start VERIFY phase — run the full test suite, fill gaps, produce verify.md
argument-hint: <feature-slug>
---

# /test <feature-slug>

You are entering the VERIFY phase for `$ARGUMENTS`.

## Pre-checks

1. `.specs/$ARGUMENTS/plan.md` exists with at least one task `[DONE]`.
2. The current branch's tests pass locally.

## What to do

1. **Read** `skills/31-test-driven-development/SKILL.md` (for principle) and `skills/40-browser-testing-with-devtools/SKILL.md` (for UI work).
2. **Run the full test suite.** Capture output.
3. **Map tests to spec §3 and §10.** For each criterion and listed test, find its implementation. Gaps → add them now.
4. **Invoke `test-engineer`** sub-agent. It evaluates test quality, not just coverage.
5. **Add tests for any gaps it identifies.** Specifically:
   - Negative paths for every success criterion
   - Boundary cases for every numeric / size / time constraint
   - Concurrency for any parallel path
   - Observability for §6 logging/metrics requirements
6. **UI work**: add the browser-testing checklist (axe-core, Lighthouse, keyboard, screenshots at 4 breakpoints). See `40-browser-testing-with-devtools`.
7. **Write** `.specs/$ARGUMENTS/verify.md`:
   ```markdown
   # Verify: $ARGUMENTS

   ## Test results
   - Unit:        N/N
   - Component:   N/N
   - Integration: N/N
   - E2E:         N/N

   ## Test-engineer findings
   <from sub-agent>

   ## Coverage of changed lines: N%

   ## UI verification (if applicable)
   - axe-core: 0 violations
   - Lighthouse desktop: <numbers>
   - Lighthouse mobile:  <numbers>
   - Keyboard nav: <pass/fail>
   - Screen reader: <pass/fail>
   - Screenshots: 375 / 768 / 1024 / 1440 ✓

   ## Performance verification (if §6 budgets)
   <measurements vs budgets>
   ```
8. **Ledger:**
   ```bash
   LEDGER="$(cat .claude/ledger/.current)"
   echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"artifact_produced\",\"kind\":\"verify\",\"path\":\".specs/$ARGUMENTS/verify.md\"}" >> "$LEDGER"
   ```

## What NOT to do

- Do not declare verify done while tests are skipped or `.only`-ed.
- Do not lower the spec to match what the implementation does. The spec stays; close the gap.
- Do not skip the test-engineer sub-agent.
- Do not include performance numbers from your dev laptop only — staging or production-like environment when possible.

## Success of this command

All tests green, `verify.md` written, test-engineer objections addressed, ledger updated. The feature is ready for `/review`.
