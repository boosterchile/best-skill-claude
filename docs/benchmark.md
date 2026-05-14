# Reading the Benchmark Scorecard

> The scorecard is the calibration loop. Without it, you can't tell whether
> agent-rigor is working for you. With it, the question has a numerical answer.

This document complements `benchmark/README.md` (which is the technical
spec) by interpreting the scorecard from a user's perspective.

## Run it

```bash
# Last 7 days, with comparison vs baseline:
bash benchmark/scripts/compare-to-baseline.sh --since "7 days ago"
```

Aim for once a week. More often is fine but won't change behaviour. Less often risks drifting before you notice.

## A reading walk-through

Sample output:

```
agent-rigor — Comparison vs baseline

  Metric                                Current     Target    Without   Δ vs target
  ------                                -------     ------    -------   ------------
  spec before code rate                    89%        95%        20%        -6 pp
  tdd compliance                           67%        80%        15%       -13 pp
  commits le 100 loc                       92%        90%        55%         2 pp
  review before merge rate                100%       100%        40%         0 pp
  devils advocate invocation rate         100%       100%         0%         0 pp
  adr coverage                             75%        80%        10%        -5 pp
  skip cycle rate                          12%        15%        45%         3 pp
  cooling off respect rate                 78%        95%         0%       -17 pp
  phase artifact completeness              95%        95%        30%         0 pp
  drift block to detect ratio              33%        70%         0%       -37 pp

  ✓ at-or-above target | ⚠ above baseline but below target | ✗ at-or-below baseline
```

How to read this in 90 seconds:

### Green (at or above target)

- **commits le 100 loc** at 92% — you're keeping changes small. Good.
- **review before merge** at 100% — non-negotiable rule is holding. Good.
- **devils advocate** at 100% — the adversarial pass is happening every time. Good.
- **skip cycle rate** at 12% — comfortably under the 15% cap. Good.
- **phase artifact completeness** at 95% — features have their spec/plan/verify/review/ship. Good.

### Yellow (above baseline but below target)

- **spec before code rate** at 89% — short of 95%. Meaningful: you're occasionally writing code before specifying it.
- **adr coverage** at 75% — short of 80%. Meaningful: decisions made without paper trail.
- **tdd compliance** at 67% — short of 80%. Meaningful: tests after the fact more than expected.
- **cooling off respect rate** at 78% — short of 95%. Meaningful: too many `[waiver]`s on `/review`.

### Red (at or below baseline)

- **drift block to detect ratio** at 33% — close to baseline 0%. Meaningful: the agent is justifying drift more than it's getting blocked.

### What to do this week

Pick ONE problem to fix. Multiple at once dilutes the focus and you'll regress on all of them.

The highest-leverage usually is the one with the largest negative delta from target AND the highest cost-of-failure. Here:

- `cooling_off_respect_rate` at -17 pp is the largest delta
- Skipping cooling-off correlates with reviews that miss issues
- Action: this week, refuse every waiver to `/review`. If you can't wait 30 minutes, wait. Re-measure next week.

## What each metric means in plain language

### spec_before_code_rate

% of features where `.specs/<feature>/spec.md` existed before the first source-code commit for that feature.

- High = you're specifying before building. Good.
- Low = you're winging it. The hooks may be letting through too many `[skip-cycle]` declarations.

### tdd_compliance

% of changed source files that have a test file written or modified before them in the commit history.

- High = TDD discipline. Good.
- Low = you're testing after, or not at all.
- Note: this metric is heuristic. Pure refactor commits without test changes don't count against you (no new behaviour).

### commits_le_100_loc

% of commits with net change ≤ 100 LOC.

- High = small commits. Easier to review, easier to revert. Good.
- Low = scope creep within commits, or you're doing large mechanical changes (e.g., renames). The skill `60-git-workflow-and-versioning` recommends splitting; if you can't, log waivers.

### review_before_merge_rate

% of `/ship` events that have a `review.md` produced beforehand.

- This should be 100%. If it's not, the rule is leaking.
- If you see < 100%, audit the ledger to find which ship event was missing its review and why.

### devils_advocate_invocation_rate

% of phase exits (`/spec`, `/plan`, `/review`, `/ship`) where `devils-advocate` was invoked.

- This should be 100% in solo mode. If it's not, the adversarial check isn't happening at one of the gates.

### adr_coverage

ADRs in `docs/adr/` divided by approved specs.

- High = decisions are documented.
- Low = decisions are being made tacitly. You'll regret this in 6 months when you can't remember why you did X.
- Acceptable to be < 100% if some specs don't include credible alternatives (rare).

### skip_cycle_rate

% of turns containing `[skip-cycle: <reason>]`.

- Healthy: 5-15%
- Below 5% means either you have only big changes (unlikely) or you're forcing yourself through the cycle when you shouldn't (overkill).
- Above 20% means most of your changes are bypassing the cycle. Either the project doesn't fit agent-rigor or you're avoiding the cycle.

### cooling_off_respect_rate

% of `/review` invocations that respected the 30-minute cooling-off period (i.e., did not include `[waiver]`).

- Target 95%. Some legit waivers (urgent fix) are fine but rare.
- Low = you're rushing reviews. The reviews aren't catching what they should.

### phase_artifact_completeness

Average completeness across the five phase artifacts (spec/plan/verify/review/ship) per feature.

- High = features are walking the full cycle.
- Low = some features are partial. Could be in-flight (fine if recent) or abandoned mid-cycle (less good — clean up).

### drift_block_to_detect_ratio

drift_blocked events divided by drift_detected events.

- High = when drift vocabulary appears, it's getting blocked (and you fix or justify).
- Low = drift is being detected and recorded but slipping through (probably via `[drift_justified]` more than necessary).
- This is the metric closest to the original pain point ("la lucha permanente con el agente"). Watch it.

## Drift section

```
Drift:
  detected:  12
  blocked:    4
  justified:  8
  top triggers:
    for now: 4
    quick fix: 3
    MVP: 2
    later: 2
    temporal: 1
```

How to read:

- 12 instances of drift vocabulary appeared in agent output or user prompt
- 4 of those were caught and blocked before any action
- 8 were justified via `[drift_justified]` and proceeded
- `"for now"` appeared 4 times — most common rationalisation

If justifications dominate the blocks consistently, ask whether the justifications are legitimate or whether you've trained yourself to justify reflexively.

## Skills section

```
Skills most read:
  11-spec-driven-development — 12 reads
  31-test-driven-development — 9 reads
  50-code-review-and-quality — 9 reads
```

The skills you read most are the skills shaping your work most.

```
Skills NOT read in this period:
  52-security-and-hardening
  62-deprecation-and-migration
  53-performance-optimization
```

If you shipped auth changes this week and never read `52-security-and-hardening`, that's a signal. The benchmark surfaces it; the next week's habit should change.

## Suggested actions section (if implemented)

The scorecard may end with concrete suggestions:

```
Sugerencias accionables:
  - 2 cooling-off respetados con waiver. Revisar: ledger 2026-05-08, 2026-05-11.
  - "MVP" usado 2 veces sin justificación robusta. Revisar contexto.
  - 0 lecturas de security-and-hardening: si tocaste auth/input/red este mes,
    `/review` debería haber leído este skill.
```

These are heuristics. They're not commands. Read, judge, act on the ones that apply.

## When the scorecard tells you to stop using agent-rigor

If after 4 weeks:

- Your skip-cycle rate is > 30% consistently
- Your scores are below baseline on the metrics that matter to your work
- You feel the friction is consistently higher than the value

Then agent-rigor may not be the right tool for your project. Possible reasons:

- Your project's pace genuinely requires less ceremony
- The skills/hooks are calibrated for a different kind of work than yours
- You're at an early prototyping stage where rigor is premature

In any of these, pause agent-rigor. Come back to it when stakes rise.

The opposite indication: if you can show meaningful improvement on at least 5 of the 10 metrics versus the "without" baseline within 4 weeks, the system is working. Stay the course.

## Storing reports

`bash benchmark/scripts/score-session.sh --since "7 days ago" > benchmark/reports/$(date +%F)_scorecard.txt`

Commit the reports if you want a long-term trend. Most useful at quarterly retrospectives — compare Q1's scorecard to Q4's and the trajectory is the conversation.

## Calibrating the targets

`benchmark/baseline.json` ships with defaults derived from observed solo-developer behaviour. They may be wrong for your context.

To calibrate to your own pace:

```bash
# After 4 weeks of agent-rigor use:
bash benchmark/scripts/score-session.sh --capture-baseline --since "30 days ago"
```

This updates `baseline.json` with your observed values as the new target. Now you're improving against your own self.

Don't recalibrate weekly — you'll erase the signal.

## In short

- Run the scorecard weekly. 5 minutes.
- Pick one yellow metric. Fix it next week.
- Watch the drift block/detect ratio especially.
- The skills you don't read are signals about gaps in your habits.
- Quarterly: retrospective, recalibrate.
