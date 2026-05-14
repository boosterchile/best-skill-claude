---
name: spec-driven-development
description: Write a Product Requirements Document (PRD) that fully defines the change BEFORE any code, plan, or test exists. Covers objective, success criteria, user-visible behaviour, technical boundaries, out-of-scope, risks, and the test list. Use whenever entering the DEFINE phase via /spec — that means any change that touches more than one file or any code that will land on main.
requires:
  - Project has a CLAUDE.md (agent-rigor contract)
produces:
  - .specs/<feature>/spec.md
phase: define
adapted_from: addyosmani/agent-skills (MIT)
---

# Spec-Driven Development

> **Without a written spec, you are not writing software. You are gambling with code.**

## Overview

The `/spec` command produces a single artefact: `.specs/<feature>/spec.md`. This artefact is the **input** to every later phase. No `plan.md`, no test, no commit, no review can reference a spec that doesn't exist on disk.

The spec is not documentation written after the fact. It is the contract written **before** the fact. It will be wrong in places — fine, you revise it. What is not fine is implementing without one.

## When to Use

Trigger `/spec` whenever:

- A change will touch more than one file
- A change will land on `main`
- A change adds, removes, or modifies user-visible behaviour
- A change modifies a public interface (API, CLI, library export, schema)
- A change is non-trivial in time (>30 minutes of work)
- You are unsure whether a spec is needed (default: write one)

Do **not** trigger `/spec` for:

- Typo fixes
- Comment-only changes
- Reformatting (whitespace, lint auto-fix)
- Adding a missing `.gitignore` line

For these, declare `[skip-cycle: <reason>]` in your first response and proceed. The ledger records this; the benchmark watches for over-use of the escape hatch.

## Process

### Step 1 — Identify the feature

Pick a short kebab-case name. Examples: `auth-refresh`, `csv-export`, `team-invitations`. The name becomes the directory: `.specs/<name>/`.

If the change doesn't fit a single feature name, the change is too big — break it down before specifying.

### Step 2 — Verify CLAUDE.md was read

Before producing the spec, confirm in the ledger that this session has a `skill_read` event for `CLAUDE.md`. If not, read it first:

```bash
LEDGER="$(cat .claude/ledger/.current)"
# After reading CLAUDE.md:
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"skill_read\",\"file\":\"CLAUDE.md\"}" >> "$LEDGER"
```

The `PreToolUse` hook enforces this; we record it deliberately for benchmark purposes.

### Step 3 — Draft the spec

Use this template. Every section is required; if a section has no content, write _"Not applicable. Reason: ..."_ instead of omitting it.

```markdown
# Spec: <feature-name>

- Author: <human-name> (with agent-rigor)
- Date: <ISO>
- Status: Draft | Approved | Implemented | Shipped
- Linked: <issue/ticket if any>

## 1. Objective
<One paragraph. What does this change accomplish, in plain language, for whom?>

## 2. Why now
<Two-three sentences. What problem are we solving, what triggered the work, what happens if we don't ship this?>

## 3. Success criteria
<Measurable. Each criterion is testable in finite time.>
- [ ] <Criterion 1>
- [ ] <Criterion 2>
- [ ] <Criterion 3>

## 4. User-visible behaviour
<What changes for the user. Include affected screens, endpoints, CLI commands, outputs. Use BEFORE/AFTER if helpful.>

## 5. Out of scope
<What we are explicitly NOT doing. The unwritten "we'll also fix X" is the enemy.>

## 6. Constraints
<Technical, regulatory, performance, security, accessibility. Numbered, specific.>
- Performance: <e.g., p95 latency must remain ≤ 200ms>
- Compatibility: <e.g., must continue to work on Node 18>
- Accessibility: <e.g., WCAG 2.1 AA>
- ...

## 7. Approach
<2-4 paragraphs OR a bulleted list. The shape of the solution, not the line-by-line code. Mention the modules/files touched and the major decisions taken.>

## 8. Alternatives considered
<At least two alternatives, each with one paragraph on why it was rejected. If you can't list two, you haven't thought hard enough.>

- **A. <Alternative>** — Rejected because: <reason>
- **B. <Alternative>** — Rejected because: <reason>

## 9. Risks and mitigations
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| ... | L/M/H | L/M/H | ... |

## 10. Test list
<Every behaviour in §3 and §4 must appear here as a test description. This is the input to /test.>
- T1: <description>
- T2: <description>
- ...

## 11. Rollout
- Feature-flagged? Yes/No. If yes, flag name: <X>
- Migration needed? Yes/No. If yes, summary: <X>
- Rollback plan: <2-3 sentences>
- Monitoring: <what we will watch after deploy>

## 12. Open questions
<Things you need answered before /plan can start. If empty, write "None as of <date>".>

## 13. Decision log
<Append-only. Each non-trivial decision during /plan, /build, /test gets a line here.>
- <date> — Initial draft.
```

### Step 4 — Devils-advocate pass (mandatory)

Solo-developer mode: invoke the `devils-advocate` sub-agent with the draft spec as input.

```
Task: Use the devils-advocate sub-agent to challenge .specs/<feature>/spec.md.
```

Capture its output and address each strong objection by either revising the spec or recording the residual risk in §9.

### Step 5 — User confirmation

Present the spec to the user. Wait for an explicit "approved" or revision request. Do **not** proceed to `/plan` on the user's silence or implicit acceptance.

Once approved, mark `Status: Approved` in §1 and write to the ledger:

```bash
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"phase_exit\",\"phase\":\"spec\",\"feature\":\"<name>\"}" >> "$LEDGER"
```

## Rationalizations (and refutations)

| Rationalization | Refutation |
|---|---|
| "It's just a small change" | Then the spec will be short. Write the short spec. The cost is minutes; the cost of skipping it is a wrong implementation discovered at review time. |
| "I already know what I'm going to do" | Then write it down. If you can't write it down, you don't know it. |
| "We can spec after we see it working" | What you'll see "working" is a proof of concept against requirements you've never articulated. You'll then ship the PoC because it "works". |
| "Specs slow me down" | Compared to what? They prevent the 10× cost of rework when the implementation drifts from intent. |
| "The ticket is the spec" | Tickets are conversation, not contract. Tickets get edited, comments scroll off, links rot. The spec is in the repo, versioned with the code. |
| "I'll fill in §8 (alternatives) later" | If you don't articulate alternatives now, you've already chosen, and you've chosen without thinking. Fill §8 first if you have to. |
| "Open questions block me" | Open questions are the most valuable section. They are the seam between what you know and what you don't. Resolve them before /plan. |

## Red Flags

- The spec has empty sections marked "TBD" or "(see code)" — those are deferral, not specification
- §3 (success criteria) is unmeasurable ("works well", "is fast", "is intuitive")
- §5 (out of scope) is empty — scope creep is guaranteed
- §8 (alternatives) is empty — you've not actually decided, you've drifted
- §10 (test list) is empty — you have no plan for verification
- Status is `Implemented` but spec.md was last modified before the first commit on the feature branch
- A `/build` or `/plan` event is logged in the ledger and `.specs/<feature>/spec.md` does not exist

## Verification

The skill is complete when:

- [ ] `.specs/<feature>/spec.md` exists
- [ ] All 13 sections have content (no `<placeholder>`, no `TBD`)
- [ ] At least 2 alternatives listed in §8
- [ ] At least 1 risk listed in §9
- [ ] At least 3 test items in §10
- [ ] Devils-advocate output captured in `.specs/<feature>/review.md` (or appended)
- [ ] User has confirmed approval
- [ ] Status field reads `Approved`
- [ ] Ledger has `phase_exit` event with `phase: spec`

## Solo-Developer Adaptation

Without a reviewer, the spec is the **only** chance to catch wrong intent before code is written. To compensate:

1. **Write the spec, walk away for an hour**, then re-read it cold. If a section reads as "of course we'd do X", check whether you actually wrote that or whether you only thought it. Anything implicit must become explicit.
2. **The devils-advocate sub-agent is mandatory**, not optional. Solo means no peer, so the adversarial agent fills the role.
3. **Test list (§10) is non-negotiable**. In a team, missing tests get caught at PR review. Solo, they get caught in production.

## macOS Notes

Create the spec directory and open it in your editor:

```bash
mkdir -p .specs/<feature>
${EDITOR:-open} .specs/<feature>/spec.md
```

Quick template scaffold:

```bash
cat > .specs/<feature>/spec.md <<'TEMPLATE'
# Spec: <feature>

- Author:
- Date:
- Status: Draft

## 1. Objective

## 2. Why now

## 3. Success criteria
- [ ]

## 4. User-visible behaviour

## 5. Out of scope

## 6. Constraints

## 7. Approach

## 8. Alternatives considered

## 9. Risks and mitigations

## 10. Test list
- T1:

## 11. Rollout

## 12. Open questions

## 13. Decision log
- $(date -u +%Y-%m-%d) — Initial draft.
TEMPLATE
```

## Attribution

Derived from `addyosmani/agent-skills` (MIT, skill `spec-driven-development`).
Modifications: enforcement hooks, mandatory devils-advocate step, ledger
integration, solo-developer adaptation, macOS scaffolding.
