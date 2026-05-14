# Solo Developer Guide

> The default workflows in most engineering literature assume a team. agent-rigor
> is explicitly designed for the solo developer. This document collects every
> adaptation in one place.

## What's different when you're alone

In a team, several forces protect you from yourself:

- **Code review** by a colleague catches what you missed
- **Pull request comments** from someone with different priors expose blind spots
- **The act of explaining** to another human surfaces your own confusions
- **Different schedules** force a cooling-off between writing and approving
- **Shared documentation** is necessary because the next reader is not you

When you're solo, all of these vanish. You write, you review, you ship. The errors that a team would have caught now ship.

agent-rigor's solo adaptations are designed to **synthesise** these forces from the tools and discipline available.

## The five solo-developer adaptations

### 1. The cooling-off period

Before `/review` runs, at least 30 minutes must have elapsed since the last source-file write — ideally a sleep cycle.

Why: the first review you give your own code is **bad**. Fresh from writing, you see what you intended, not what's there. A 30-minute gap lets the implementation context fade enough for you to read the diff as a stranger would.

The hook enforces this. To override, include `[waiver: <reason>]` in your message. The benchmark counts every waiver. Healthy: < 5% of reviews.

Optimal: review the next morning. Most strong reviews happen after sleep, not after coffee.

### 2. The adversarial sub-agent

In a team, the adversary is the reviewer who disagrees with you. Solo, you must construct the adversary explicitly.

`devils-advocate` is auto-invoked at every phase exit (`/spec` exit, `/plan` exit, `/review` exit, `/ship` exit). It walks a seven-axis attack on your work:

1. **Premise** — is the user / problem real?
2. **Scope** — is anything out-of-scope sneaking in?
3. **Alternatives** — what wasn't considered?
4. **Failure modes** — what would break this?
5. **Reversibility** — can this be undone?
6. **Drift signals** — is there rationalisation in the wording?
7. **Evidence quality** — are the claims supported by data?

It does not approve. It either lists objections or says "no objection on axes X, Y, Z". Objections must be addressed before progressing.

This is the single highest-value adaptation. The cost is ~1 minute per phase exit. The benefit is finding the issue your team would have caught.

### 3. Pull requests against yourself

Even for code only you will ever see, open a PR before merging to main:

```bash
gh pr create --fill
```

Why:

- Branch protection on `main` (CI green required) actually fires
- The diff at a snapshot is preserved in GitHub's history
- The CI run output is permanently attached to that point in time
- Future-you debugging next year has a structured record
- The act of "opening a PR" creates a tiny ritual gap that surfaces last-minute concerns

Cost: 30 seconds. Benefit: a year from now, when you wonder "why was this change made in March?", the answer is right there.

### 4. The ledger as standup

Engineering teams have daily standup. The point isn't the meeting; it's the periodic articulation of "what I'm doing and what's stuck".

Solo, the ledger replaces standup. Pre-build articulation entries record:

```json
{"type":"pre_build_articulation","task":"T3","plan":"...","alternatives":["A","B"],"failure_modes":["F1","F2"]}
```

You're forced to articulate. Reviewing yesterday's entries before starting today is the solo equivalent of "what I did yesterday, what I'm doing today, what's blocked." Five minutes, free.

```bash
# Yesterday's articulations:
jq -c 'select(.type == "pre_build_articulation")' \
  $(ls -t .claude/ledger/*.jsonl | head -3)
```

### 5. Quarterly benchmark + retrospective

Once a quarter, run:

```bash
bash benchmark/scripts/score-session.sh --since "90 days ago"
bash benchmark/scripts/compare-to-baseline.sh --since "90 days ago"
```

Then write 3 lines:

- What's working (one metric you're meeting that you weren't before)
- What's slipping (one metric trending wrong)
- What you'll change next quarter (one specific behaviour or rule)

Save as `docs/retrospectives/<YYYY-Q>.md`.

This replaces the team retrospective. The cost is 15 minutes per quarter. The benefit is that the four metrics that matter to you stay visible and you don't slowly drift back to your pre-agent-rigor habits.

## The two friction points solo developers hit

### Friction 1: "All this process for a one-liner change"

Yes, the full cycle is overkill for a typo. That's what `[skip-cycle: <reason>]` is for. Use it. The benchmark watches your skip-cycle rate; under 20% is healthy, which means about 4 out of 5 changes go through the cycle.

If you find yourself skip-cycling everything, two diagnostics:

- Your changes are genuinely all small → the project is at a stage where formality doesn't add value; consider pausing agent-rigor and resuming when the stakes rise
- You're avoiding the cycle for psychological reasons (it feels slow, you're impatient) → that's the drift the cycle exists to catch; force yourself to /spec the next non-trivial change and see if it goes well

### Friction 2: "I just want to ship; this is dragging me down"

Two reframes:

- The cycle isn't the obstacle to shipping; it's the path to shipping. Shipping bad code is fast. Shipping correct code that doesn't need rollback is faster overall.
- Your benchmark scorecard is the evidence. If your rates are above the baseline ("without agent-rigor"), the system is working — your friction is the friction of doing the work properly, not the friction of doing extra work.

If the benchmark says you're worse than baseline on the metrics that matter, something is wrong with the system, not with you. Open an issue.

## Habits to add to your daily flow

### At session start

- Read CLAUDE.md if it's been a few days
- Glance at the last session's ledger: `cat $(ls -t .claude/ledger/*.jsonl | head -1)`
- Check the current feature's spec status: `grep ^Status .specs/*/spec.md`

### Mid-session

- After any non-trivial decision, ask: "is this an ADR moment?"
- Before a long debug session, run `41-debugging-and-error-recovery`'s articulation step
- When tempted to skip a step, ask yourself why — is it overkill, or is it discomfort?

### At session end

- `stop.sh` writes the turn summary; glance at it
- For ongoing features, update plan.md task statuses
- If a decision was made, write the ADR now while context is fresh

### Weekly

- `bash benchmark/scripts/score-session.sh --since "7 days ago"`
- Review the top drift triggers; if "quick fix" appeared more than 3 times, ask why
- Re-read any ADR younger than two weeks; does it still make sense?

### Quarterly

- Full benchmark + retrospective (above)
- Review open ADRs; update statuses (Accepted → Superseded as needed)
- Clean up `.specs/_scratch/` if it exists

## Tools that compose with solo flow

| Tool | Why |
|---|---|
| `gh` CLI | PR creation, releases, watching CI from terminal |
| `jq` | Inspecting ledger entries without leaving the shell |
| `fswatch` | Watch source for test re-runs |
| `tmux` or `screen` | Multiple terminals: agent, test watcher, log tail |
| `direnv` | Per-project environment without polluting global env |
| `Raycast` or `Alfred` | Quick snippets for ledger inspection, scorecard, etc. |

## A note on burnout

Solo development has a specific failure mode: working in long unbroken stretches and only realising afterwards that the last 4 hours of code was bad. agent-rigor's cooling-off is partly a defence against this. Honour it.

If the cooling-off keeps feeling like an obstacle, ask honestly whether you're trying to do team-scale work without a team — that path leads to burnout, regardless of how good the tooling is.

## Reading order for new solo users

1. `getting-started.md` (you've read this)
2. `anti-drift.md` (why the system is shaped this way)
3. `solo-developer.md` (this document)
4. `macos-setup.md` (specific environment tips)
5. `benchmark.md` (how to read the scorecard)
6. The skills in numerical order (00, 10, 11, 20, ...)

You don't need to memorise the skills. The agent reads them at the right moment. You need to know they exist and where they live, so you can override or argue with one when it's wrong for your case.

## And finally

The whole point: solo developers are not less capable than teams. They are differently constrained. agent-rigor's job is to give you the constraints back — the artificial friction, the adversarial check, the structured memory — that teams provide as a side effect of having multiple humans.

Done well, you ship with the same quality as a small team. Done badly, you ship faster than them with worse code. The benchmark tells you which is which.
