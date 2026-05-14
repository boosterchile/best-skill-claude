# Solo-Developer Patterns

> Working solo is not "team workflow with the cost-saving step of skipping reviews". It is a distinct mode of operation that requires the same rigour with different mechanics.

This document collects the adaptations agent-rigor makes when the team is one human + one agent. Every skill in `skills/` includes a **Solo-Developer Adaptation** section; this file holds the cross-cutting patterns those sections reference.

## The four substitutions

A working team gives you four things automatically. Solo, you reproduce them deliberately or you ship worse software.

### 1. Peer review → cooling-off + adversarial agent

| Team mechanic | Solo substitute |
|---|---|
| Another engineer reviews the PR | (a) Cooling-off period: minimum 30 minutes between last source-file write and `/review`. The `Stop` hook records the last source write timestamp; `/review` refuses to start without 30+ minutes elapsed unless you issue `[waiver: <reason>]`. (b) `devils-advocate` sub-agent invocation, mandatory. (c) `code-reviewer` sub-agent invocation, mandatory. |
| Rotating reviewer pool | Round-robin between `code-reviewer`, `security-auditor`, `ux-designer` so you don't lock in one perspective. |
| Reviewer can pull the cord on shipping | Devils-advocate output goes to `.specs/<feature>/review.md` as a permanent record. If it raised strong objections that you overrode, the override is logged with reasoning. |

**Why cooling-off works**: most quality wins from code review are not from another set of eyes — they're from cold eyes. The reviewer reads your code without the writing-context that papered over the issue. You can buy 80% of that effect by waiting and re-reading cold. The remaining 20% comes from the adversarial agent.

**Hard rule**: do not skip the cooling-off. If your work is urgent enough that you can't wait 30 minutes, your work is urgent enough that someone else is paying the cost when it breaks. Issue the waiver explicitly so the benchmark catches the pattern.

### 2. Pair programming → rubber-duck-with-skeptic

A pair partner forces you to articulate before you act. Solo, articulate to the agent — but configure the agent to be sceptical.

Pattern: before any non-trivial implementation, the agent must write `pre_build_articulation` to the ledger covering:

- What I am about to do (one paragraph)
- Why this approach (must reference at least two alternatives considered and rejected)
- What could go wrong (at least three failure modes)
- What evidence I have that this is the right approach (citations, prior art, benchmark, intuition — but label intuition as such)

Only after this entry does the agent write code. This is the rubber-duck. The fact that the agent argues with you when your articulation is weak is the skeptic part.

### 3. Standups → ledger summary at session start

Standups serve to surface unfinished work, blocked work, and shifted priorities. Solo, the `SessionStart` hook reads the most recent ledger entries and the agent summarises:

```
Last session ended in phase BUILD for feature auth-refresh.
  Pending: tests for the token-rotation edge case (T6 in spec).
  Blocked: nothing.
  Resume here, switch focus, or close this feature?
```

The user answers. The agent does not assume continuation. This is your standup.

### 4. Architecture reviews → ADR cadence

Team architecture reviews are scheduled meetings. Solo, they are forced by the skill `63-documentation-and-adrs`:

- Any decision listed in a spec's §7 (Approach) that changes how a module composes with another module → ADR in `docs/adr/NNNN-*.md`.
- Any change to the design-system MASTER → decision-log entry + considered ADR.
- Any new external dependency added → ADR (this is the only way to catch dependency creep solo).

The benchmark tracks ADR-per-architecturally-relevant-decision. Below 50% triggers a flag.

## The three things you cannot replace

Solo, three team affordances cannot be substituted. Accept the limit.

1. **Truly independent perspectives.** Even with adversarial agents and cooling-off, your blind spots persist. Periodically (every 6 months at minimum) get a real human review of a representative chunk of your work. Pay for it if you have to. The benchmark cannot detect what you don't know to look for.

2. **On-call rotation.** If your software is on-call-critical, you cannot solo it indefinitely. Build for graceful degradation and bounded responsibility; accept that some pager loads need a second human.

3. **Bus factor of >1.** A repo with only you in `CODEOWNERS` is one accident away from orphaned. Mitigation is not technical: document the system so a stranger can pick it up. Skill `63-documentation-and-adrs` is structured around this assumption.

## Anti-patterns specific to solo work

| Anti-pattern | What it looks like | Why it bites |
|---|---|---|
| **"Just-me convention" creep** | Idiomatic decisions made without writing them down because "I'll remember" | Six months later you no longer remember why a module is structured that way; the convention has become a barrier to refactoring |
| **Review theatre** | Running `/review` immediately after writing, agent invocations as a formality | The cooling-off and adversarial agent only work if you actually engage with their output |
| **Spec-as-narration** | Writing the spec _after_ the code, narrating what you did | The spec is the contract; written after, it's documentation. Both are valuable but they are not the same. |
| **Premature freeze** | Marking spec or design-system `Status: Approved` before devils-advocate has run | Skips the only adversarial step you have. Status field is the gate. |
| **"I know my code"** | Skipping tests because the reasoning is "obvious" | Tests are not for the code you can reason about; they are for the code two months from now, when context is gone. |
| **Drift normalisation** | Frequent `[skip-cycle: <weak reason>]` declarations | The skip-cycle is a safety valve, not a default. Benchmark flags users above 20% skip-cycle rate. |

## Cadence

A sustainable solo cadence, anchored in agent-rigor:

- **Daily**: `/spec` for new work, `/build` in small slices, `/test` in red-green pairs
- **Per slice (~100 LOC)**: commit, ledger entry, cooling-off, `/review`
- **Per feature**: `/ship` with checklist
- **Weekly**: `/benchmark`, read the scorecard, address red flags
- **Monthly**: review your own ADRs cold; ask "would I make this decision again?"
- **Quarterly**: get a real human to read a chunk of your work; offer to do the same for theirs

## When you genuinely cannot

If you cannot follow this cadence (life happens, deadlines happen), the integrity is in **how you fail**, not in pretending you didn't. Issue waivers. Note the unmet conditions in the ledger. The benchmark will show you the pattern over time, and you can decide whether to adjust the practice or accept the cost.

What is not acceptable: failing silently and pretending the cycle was respected.
