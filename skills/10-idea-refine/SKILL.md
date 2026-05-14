---
name: idea-refine
description: Use BEFORE /spec when the change is still vague ("I want OAuth", "make it faster", "users are confused on the dashboard"). Produces a short refined statement that becomes the basis for spec §1 (Objective) and §2 (Why now). Trigger when the user's request is one sentence and ambiguous, or when the agent doesn't know what to write in spec §3 (Success criteria).
requires: nothing
produces:
  - .specs/<feature>/idea.md (optional but recommended)
phase: define-pre
adapted_from: addyosmani/agent-skills (MIT)
---

# Idea Refine

> A vague request becomes a wrong implementation faster than a vague request becomes a refined one. Spend 10 minutes here to save 10 hours later.

## When to use

Trigger this skill when:

- The user's request fits in one sentence ("I want OAuth", "make the dashboard faster", "improve onboarding")
- You cannot write measurable success criteria from the request as stated
- You would have to invent the user, the problem, or the constraint to start specifying

Skip this skill when:

- The user has already provided the refinement (linked a doc, written a paragraph with user/problem/criterion)
- The change is mechanical (rename, refactor with no behaviour change)

## Process

### Step 1 — Five questions

Ask the user (one at a time if the channel allows; together if not):

1. **Who is the user / actor affected?** Be specific. "Users" is wrong. "First-time visitors arriving from a paid ad campaign" is right.
2. **What are they trying to do, and what's stopping them today?** The problem must precede the solution.
3. **What does success look like, observable from outside?** Not "it's faster" — "p95 page load on /dashboard drops from 2.4s to under 1.0s".
4. **What's the budget?** Time, complexity tolerance, willingness to accept breaking changes downstream.
5. **What's explicitly out of scope?** Make the user say no to something. If they can't, the scope is open-ended and dangerous.

If after these questions you cannot answer, **stop and tell the user you cannot proceed**. Do not invent.

### Step 2 — Write the refined statement

Format:

```markdown
# Idea: <kebab-name>

- Date: <ISO>
- Status: Refined | Spec'd | Implemented | Shipped

## Actor
<Specific user / role>

## Problem
<What they cannot do today, or do badly>

## Outcome
<Observable result, measurable in finite time>

## Budget
<Time, complexity, willingness-to-break>

## Out of scope (explicitly)
<At least one item the user has said NO to>

## Open questions
<Things needed before /spec>
```

Save as `.specs/<feature>/idea.md`. This is informal — it's the seed for the spec.

### Step 3 — Hand off to /spec

When the idea is refined, run `/spec` next. The agent should populate spec §1, §2, §3 from the idea.md directly.

## Rationalizations

| Rationalization | Refutation |
|---|---|
| "I know what I mean" | The agent doesn't. The you in 3 months doesn't. Write it down. |
| "We can refine while specifying" | The spec is a contract; mixing refinement and specification produces wishy-washy specs. Refine first, then specify. |
| "It's obvious who the user is" | The exercise of writing it out reveals when "the user" is actually three different users with conflicting needs. |
| "I don't want to be slowed down by process" | The process here is 5 questions. The thing that slows you down is shipping the wrong thing. |

## Red Flags

- The idea says "we should" without identifying who benefits
- Outcome is unmeasurable ("better UX", "more engagement")
- No explicit out-of-scope item
- Three users with different needs mashed into one
- A solution stated as a problem ("Add OAuth" is a solution; the problem is "users abandon at signup")

## Verification

- [ ] All five questions answered (or `idea.md` Open questions section listed)
- [ ] Actor specific enough that you could write a test that simulates them
- [ ] Outcome measurable in finite time
- [ ] At least one out-of-scope item
- [ ] Saved to `.specs/<feature>/idea.md`

## Solo-Developer Adaptation

When you are both the requester and the implementer, you'll be tempted to skip this skill because "I already know". You don't — you have an intuition. Forcing yourself to write the five answers reveals which parts of the intuition are real and which are vapour.

Optional: ask the `devils-advocate` sub-agent to challenge the refined statement before moving to `/spec`.

## macOS Notes

Scaffold:

```bash
F="$1"; mkdir -p ".specs/$F" && open ".specs/$F/idea.md"
```

## Attribution

Adapted from `addyosmani/agent-skills` (MIT, skill `idea-refine`).
