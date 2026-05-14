---
description: Run the agent-rigor scorecard for a time window
argument-hint: [optional: since="7 days ago" | --last | --all] [optional: --format=json]
---

# /benchmark [args]

Run the agent-rigor scorecard.

## What to do

1. **Read** `benchmark/README.md` if you haven't this session.
2. **Run the self-check first** (only on first invocation per session):
   ```bash
   bash benchmark/scripts/collect-metrics.sh --self-check
   ```
   If any check fails, surface that to the user. Common fixes:
   - `brew install jq` if jq missing
   - `chmod +x .claude/hooks/*.sh` if hooks not executable
3. **Run the scorecard** with the user's arguments (default `--last` if none):
   ```bash
   bash benchmark/scripts/score-session.sh $ARGUMENTS
   ```
4. **Run the comparison** against baseline:
   ```bash
   bash benchmark/scripts/compare-to-baseline.sh $ARGUMENTS
   ```
5. **Interpret the results.** For each metric:
   - ✓ at-or-above target — congratulate briefly, move on
   - = within tolerance — note as on-track
   - ⚠ above baseline but below target — propose ONE concrete change
   - ✗ at-or-below baseline — flag as priority; investigate the ledger for the root cause
6. **Drift section.** If drift_detected > 0:
   - List top triggers
   - Distinguish "blocked" (good — hook caught it before action) from "justified" (acceptable in moderation; review if frequent)
7. **Skills not read.** If a SKILL.md was never referenced in the window and the user touched relevant code, flag it specifically (e.g., "you shipped auth changes but never read security-and-hardening").
8. **Save the report** (optional):
   ```bash
   DATE="$(date -u +%Y-%m-%d)"
   bash benchmark/scripts/score-session.sh $ARGUMENTS > "benchmark/reports/${DATE}_scorecard.txt"
   ```

## What NOT to do

- Do not invent metrics not in `baseline.json`.
- Do not pretend a low score is good news. Honest numbers are the point.
- Do not skip the comparison against the baseline — that's the calibration.

## Success of this command

Scorecard printed, deltas vs baseline visible, top drift triggers listed, at most one or two concrete actions proposed. The user sees where they are on the curve.
