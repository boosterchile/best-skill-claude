# Anti-Drift: How the System Stays Honest

> "La lucha permanente con el agente es terrible." — the problem this pack
> exists to address.

This document explains why agent-rigor uses **active enforcement** (hooks + ledger) instead of just better instructions, and how the layers stack to make drift expensive.

## The drift problem

Long-context AI agents drift. Not because they're broken — because they're built to be helpful, and "helpful" without a contract means "agreeable". Concretely:

- The agent **fills gaps** when context is unclear → invents file paths, function names, requirements
- The agent **mirrors urgency** when you sound rushed → skips tests, skips review, ships rough work
- The agent **rationalises** when it would prefer to act → "for now", "MVP-style", "we can clean up later"
- The agent **forgets** between sessions → re-litigates decisions you already made
- The agent **agrees with the latest framing** → if you keep saying "this is overkill", it agrees

None of these are character flaws. They're attractor states of a helpful assistant that has been asked to ship code with no resistance.

## Why instructions alone aren't enough

You can write a CLAUDE.md that says "always run the test suite before declaring done." The agent will read it, agree with it, and then 40 turns later, after a difficult debugging session, will declare done without running the test suite — and apologise sincerely when you point it out.

This is not a memory problem. It's a problem of incentive shape: there is nothing in the agent's reward for the turn that punishes the skip. The instruction is a request; the agent is built to be agreeable.

The solution is to **shift the cost** of drift onto the agent's turn loop itself. Make skipping more expensive than complying.

## The four enforcement layers

```
1. CLAUDE.md           — the contract (passive; can be ignored)
2. SKILL.md files      — the how-to (active when read, but reading is optional)
3. Hooks               — the bouncer (mandatory; blocks actions)
4. Ledger              — the memory (permanent record; informs hooks)
```

Layers 1-2 are what most skill packs ship. Layers 3-4 are why agent-rigor is different.

### Layer 1: CLAUDE.md (the contract)

A long, opinionated document. The agent reads it (and the hook makes sure it does — see layer 3). But the contract by itself is a guideline. The agent can comply, partially comply, or quietly skip.

What it accomplishes: alignment when the agent is fresh and following text closely.

### Layer 2: SKILL.md files (the how-to)

Phase-specific playbooks. Each one is a tactical guide for what to do in `/spec`, `/plan`, etc. The agent reads them at the start of each phase.

What it accomplishes: gives the agent the right vocabulary, structure, and reference points for the task at hand. Reduces the surface for improvisation.

### Layer 3: Hooks (the bouncer)

This is the layer most skill packs lack. The hooks are scripts that Claude Code runs at lifecycle events. Five hooks ship with agent-rigor:

| Hook | When it runs | What it does |
|---|---|---|
| `session-start.sh` | Once at session begin | Creates the ledger file. Verifies environment. |
| `user-prompt-submit.sh` | After every user message | Scans for drift vocabulary; logs slash commands. |
| `pre-tool-use.sh` | Before every tool call | The bouncer. **Can block.** |
| `post-tool-use.sh` | After every tool call | Records what the agent did. |
| `stop.sh` | After every turn | Persists summary. Tracks last-source-write for cooling-off. |

The critical one is `pre-tool-use.sh`. It can return a non-zero exit code, which tells Claude Code to **refuse the tool call**. Concrete examples:

- Agent attempts to write a source file in `src/` but `.specs/<feature>/spec.md` doesn't exist → block, with a message explaining the rule and how to override
- Agent's last message contained drift vocabulary ("MVP", "for now", "quick fix") without prior justification in the ledger → block, ask for explicit justification
- Agent attempts `/ship` but cooling-off period not elapsed → block, point at the timer

The blocks are surfaced to the user (and to the agent's next turn). The agent can either fix the issue or, with the user's explicit permission, override via `[waiver: <reason>]` or `[skip-cycle: <reason>]`. Both are counted by the benchmark.

This is the shift. Instead of "the agent might forget to run tests", it's "the agent literally cannot ship without the verify.md being present, unless the user explicitly waivers the rule." The cost of drift is now non-zero.

### Layer 4: Ledger (the memory)

`.claude/ledger/<date>_<session>.jsonl` is the session's immutable record. Every artefact, every phase transition, every block, every waiver lands here.

The ledger feeds:

- **Hooks**: pre-tool-use checks whether spec.md was produced before allowing source writes by looking at recent ledger entries. Cooling-off check reads `.last_source_write`.
- **Benchmark**: scorecard aggregates ledger events over a time window.
- **Audit**: when something went wrong last week, you read the ledger.

Without the ledger, the hooks would have no memory and the benchmark would have nothing to measure. The ledger is the substrate that makes the rest work.

## How a drift attempt actually fails

Concrete walk-through. The agent is mid-build. The user is tired. The agent writes:

```
I'll add a quick fix for now — we can do this properly later.
```

What happens:

1. **user-prompt-submit.sh** runs (this is on user input, but the same scan runs on agent output via post-tool-use for outputs). Drift pattern matches: "quick fix", "for now", "later".
2. The hook writes a `drift_detected` entry to the ledger and returns success (it doesn't block this output, but it's now on record).
3. Agent then tries to call `Write` to modify a source file.
4. **pre-tool-use.sh** runs. Checks the ledger for recent `drift_detected` without a subsequent `drift_justified`. There isn't one.
5. The hook returns non-zero with a message:
   ```
   ✗ blocked: drift vocabulary "quick fix" + "for now" + "later" detected in recent
     output. If this is deliberate technical debt, include
     [drift_justified: <reason>] in your next message and I will record it.
   ```
6. Claude Code refuses the tool call. The agent sees the block and the message in its next turn.
7. Agent has to either:
   - Justify: "[drift_justified: this is a temporary workaround for a downstream bug we cannot fix this week; tracked as issue #142]" — ledger records `drift_justified`, future writes proceed
   - Rewrite the approach without drift vocabulary
   - User waivers the entire session: `[waiver: I'm aware, ship the quick fix]`

In all three branches, the drift is **visible**, **recorded**, and **counted**. The benchmark next week will show:

```
Drift:
  detected:  12
  blocked:    4
  justified:  8  (top: "quick fix"×3, "MVP"×2)
```

This is the information you need to decide whether the system is calibrated right or whether you're letting too many through.

## The two escape valves

The system is enforcement-heavy, which means it must have well-designed escape valves. If escape is too easy, the enforcement is theatre. If escape is too hard, you'll disable the system.

### Escape valve 1: `[skip-cycle: <reason>]`

For changes that genuinely don't need the cycle. Typo fixes, renames, comment edits, throwaway scripts. You include `[skip-cycle: ...]` in your message and the hooks let the action through. The benchmark counts the rate; healthy is < 20%.

### Escape valve 2: `[waiver: <reason>]`

For overrides of a specific check. Cooling-off waiver, drift-vocabulary waiver, etc. Counted separately. Healthy waiver count is < 5% of phase transitions.

Both valves require **explicit** user input. The agent cannot waiver itself.

## Why this is hard to design well

The temptation when building enforcement is to be either too lax (the system has no teeth) or too strict (the user disables it on day 3). The calibration we've shipped is:

- Block source writes without a spec → strict, but escape valve `[skip-cycle]` is one phrase
- Block drift vocabulary unless justified → strict, but justification is one phrase
- Block /ship without /review → strict, no override (this is the most important rule)
- Cooling-off block → strict, but waiver is allowed and counted

If your project's nature requires different calibration, edit `.claude/hooks/*.sh` and `.claude/settings.json` deliberately. The defaults are opinionated; they shouldn't be sacred.

## When the system has failed

Watch for these in the benchmark over a 4-week window:

- skip_cycle_rate > 30% → the rules don't fit the project (or the project doesn't fit agent-rigor)
- waiver_grant_rate > 15% → the rules are too strict for daily use
- drift_blocked / drift_detected < 0.2 → the agent is justifying its way around, the vocabulary list might be too permissive
- review_before_merge_rate < 1.0 → the /ship rule is leaking somehow; investigate the ledger

If you see these patterns, the fix is either calibration of the hooks or a candid conversation with yourself about whether the project's pace genuinely requires more rigor than you're willing to invest. Both are valid outcomes. The benchmark exists to make the conversation possible.

## What the agent gets out of this

Counter-intuitive but real: the agent is **more useful** with the enforcement than without. The hooks remove the "what should I do here?" ambiguity that produces drift. The ledger gives the agent a memory across turns within a session. The skills give it concrete patterns to follow.

The user reports — and this is the validation that matters — is that instead of fighting the agent, the agent fights for the user. The bouncer is on the user's side.

## In short

- Instructions are advisory; hooks are mandatory. Add hooks.
- The ledger is the substrate; without it, the rest has no memory. Keep it.
- The benchmark is the calibration loop; without it, you can't tell if the system is working. Run it weekly.
- Escape valves are required; without them, you'll disable the system. Use them sparingly and the benchmark will tell you the truth.
