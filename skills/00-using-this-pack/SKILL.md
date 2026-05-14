---
name: using-this-pack
description: Meta-skill. Read this once per project (and again whenever onboarding feels stale) to understand how agent-rigor's skills, hooks, ledger, and benchmark fit together. The agent should read this when /spec, /plan, etc. produce friction or when CLAUDE.md references a mechanism the agent hasn't seen.
phase: meta
adapted_from: addyosmani/agent-skills (MIT)
---

# Using the agent-rigor pack

This is the orientation document. Read it once when starting a new project under agent-rigor, and again any time the workflow stops making sense.

## Mental model

agent-rigor has five layers, each with a specific job:

```
┌─────────────────────────────────────────────────────────┐
│ 1. CLAUDE.md            The contract                    │
│ 2. skills/              The how-to per phase            │
│ 3. .claude/hooks/       The enforcement (blocks drift)  │
│ 4. .claude/ledger/      The memory                      │
│ 5. benchmark/           The score                       │
└─────────────────────────────────────────────────────────┘
```

You don't interact with all five at the same time. Most of the time you write code and the agent reads SKILL.md files. Sometimes a hook blocks you and you have to address it. Once a week you run the benchmark.

## The cycle

```
DEFINE → PLAN → BUILD → VERIFY → REVIEW → SHIP
```

Each phase has:

- A **slash command** to start it (`/spec`, `/plan`, `/build`, `/test`, `/review`, `/ship`)
- A **set of skills** the agent must read at the start
- An **artefact** that gets persisted to `.specs/<feature>/`
- A **transition gate** (user confirmation + ledger entry)

You enter the cycle, walk through it, exit. You may go back (BUILD → SPEC if you learn the spec was wrong) — that's encouraged. What's not allowed is going forward without completing the current step.

## How to onboard a new feature

```
You: I want to add OAuth login.

Agent: (reads CLAUDE.md if not yet this session)
Agent: /spec auth-oauth-login
       (reads skills/11-spec-driven-development/SKILL.md)
       (writes .specs/auth-oauth-login/spec.md)
       (invokes devils-advocate)
       (presents spec, waits for your approval)

You:   approved, proceed

Agent: /plan
       (reads skills/20-planning-and-task-breakdown/SKILL.md)
       (writes .specs/auth-oauth-login/plan.md)
       ...
```

Each phase ends with the agent asking you to confirm before starting the next. **Do not let the agent auto-progress** — the moment you do, the cycle is fiction.

## When a hook blocks you

The most common blocks:

- **CLAUDE.md not read this session** → just have the agent read it
- **Drift vocabulary detected** → reformulate or justify ("yes this is deliberate technical debt, here's why")
- **Spec missing for source-file write** → either run `/spec` first, or declare `[skip-cycle: <reason>]`

Blocks are not punishment. They are seatbelt clicks. The cost of resolving a block is seconds; the cost of skipping is hours of rework later.

## The ledger

Everything is logged to `.claude/ledger/<date>_<session>.jsonl`. You don't normally read it directly — the benchmark does. But it's there if you need to audit a session ("did I actually run devils-advocate on that change?").

To inspect:

```bash
ls -t .claude/ledger/ | head -1 | xargs -I{} jq -s '.' .claude/ledger/{}
```

## When skills feel like overkill

If you have a 5-minute change ("rename a variable in three places"), the cycle does not apply. Declare:

```
[skip-cycle: pure rename, no behaviour change]
```

This goes to the ledger. The benchmark watches your skip-cycle rate. Under 20% is healthy; above means you're either fooling yourself or the project isn't shaped for this workflow.

## The 21 skills at a glance

| # | Skill | When |
|---|---|---|
| 00 | using-this-pack | Onboarding (this doc) |
| 10 | idea-refine | Before writing the first spec — when you have a hunch |
| 11 | spec-driven-development | DEFINE phase. Always. |
| 20 | planning-and-task-breakdown | PLAN phase. Always. |
| 30 | incremental-implementation | BUILD phase. One vertical slice at a time. |
| 31 | test-driven-development | BUILD/VERIFY. Tests first. |
| 32 | context-engineering | When the agent's context window is loaded with irrelevant noise |
| 33 | source-driven-development | When working in a legacy codebase you didn't write |
| 34 | frontend-ui-engineering | BUILD when the work is UI |
| 35 | design-system-generation | Before any UI exists in a project |
| 36 | api-and-interface-design | Any change to a public surface |
| 40 | browser-testing-with-devtools | VERIFY phase, UI work |
| 41 | debugging-and-error-recovery | Anything broken |
| 50 | code-review-and-quality | REVIEW phase. Always. |
| 51 | code-simplification | REVIEW when complexity sneaks in |
| 52 | security-and-hardening | REVIEW when auth/input/network touched |
| 53 | performance-optimization | REVIEW with measured regression |
| 60 | git-workflow-and-versioning | SHIP phase |
| 61 | ci-cd-and-automation | SHIP phase + when pipeline lacks coverage |
| 62 | deprecation-and-migration | Removing a public surface |
| 63 | documentation-and-adrs | SHIP + any decision logged |
| 64 | shipping-and-launch | SHIP phase. Always. |

## Where to look when stuck

- **"I don't know what to do next"** → read CLAUDE.md §2 (the cycle), pick the next phase.
- **"The agent is being annoying"** → that's the hook. Read its error. Comply or waiver.
- **"This is too much process for a small change"** → declare `[skip-cycle: <reason>]`. Don't fight the cycle, route around it explicitly.
- **"I want to know if this is working"** → `bash benchmark/scripts/score-session.sh --since "7 days ago"`.
- **"I want to change a contract rule"** → that's meta-work. Open a `/spec` for it under `.specs/_meta/`.

## When to stop using agent-rigor

Honest answer: when it's costing more friction than it saves on _your_ projects. The way to know is the benchmark scorecard. If after 4 weeks you're not above the `without_agent_rigor` baseline on the metrics that matter to you, something is wrong — either your project isn't shaped for this, or a rule needs adjustment. Open an issue describing what broke down.

## Attribution

Pack structure derived from `addyosmani/agent-skills` (MIT). The meta orientation
pattern is original. The slash-command cycle naming follows community
convention.
