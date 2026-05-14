---
name: code-review-and-quality
description: REVIEW phase. Apply a five-axis review (correctness, clarity, complexity, consistency, coverage) to every change before merge. Invoke code-reviewer and devils-advocate sub-agents. Solo-developer mode requires the 30-minute cooling-off before this skill can run.
requires:
  - Implementation complete with passing tests
  - At least 30 minutes elapsed since last source-file write (or waiver)
produces:
  - .specs/<feature>/review.md
phase: review
adapted_from: addyosmani/agent-skills (MIT)
---

# Code Review and Quality

> The first review you write of code you wrote is bad. That's why solo-developer mode requires the cooling-off — to give the cold reviewer (you, hours later) the same advantage a team reviewer has by default.

## When to use

`/review` is triggered after `/build` and `/test` are complete. The hook verifies the cooling-off period or refuses to start without a waiver.

## Process

### Step 0 — Cooling-off check

```bash
# Read .claude/ledger/.last_source_write
LAST="$(cat .claude/ledger/.last_source_write 2>/dev/null)"
# If now - LAST < 30 min, refuse unless [waiver: ...]
```

If you need to override, issue `[waiver: <reason>]` and continue. The benchmark tracks waiver frequency.

### Step 1 — Read the spec and plan cold

Before reading any code, re-read `.specs/<feature>/spec.md` and `plan.md`. The review is against the spec, not against your sense of "good code".

### Step 2 — The five axes

Walk the diff (or working tree) through each axis. Make notes per file/function.

#### Correctness

Does the code do what the spec says it does?

- Every success criterion in spec §3 verified by a test that passes?
- Every behaviour in spec §4 observable in the implementation?
- Edge cases from spec §10 handled?
- Error paths return the right thing?

#### Clarity

Can the next reader understand this without a synchronous handoff?

- Naming reads naturally?
- Functions do one thing?
- Comments explain _why_, not _what_?
- Public surface (exports, props) is minimal and necessary?

#### Complexity

Is the implementation as simple as it can be while solving the problem?

- Indentation depth (rule of thumb: > 4 levels = refactor)
- Function length (rule of thumb: > 50 lines or > 1 screen = refactor)
- Number of parameters (rule of thumb: > 4 = consider an object)
- Cyclomatic complexity (run a tool: `npx complexity-report`, `radon` for Python)

If any feels too high, run `51-code-simplification`.

#### Consistency

Does the change fit the codebase's existing patterns?

- Naming matches sibling modules (`33-source-driven-development`)?
- Error handling pattern consistent?
- Import organisation matches?
- Test structure matches?
- Token discipline followed (`design-system/MASTER.md`)?

#### Coverage

Are tests adequate?

- Unit tests for new logic
- Integration tests for new wiring
- E2E for new user flows
- Coverage of changed lines ≥ 80%
- No skipped or `.only`-ed tests
- No `TODO: test later`

### Step 3 — Invoke `code-reviewer` sub-agent

```
Task: Use code-reviewer sub-agent. Inputs: spec.md, plan.md, the full diff.
```

Capture its output to `.specs/<feature>/review.md`.

### Step 4 — Invoke `devils-advocate` sub-agent

Mandatory in solo-developer mode. The output appends to or merges with `review.md`.

### Step 5 — Other sub-agents as applicable

- UI work → `ux-designer` (`35-design-system-generation` checklist + `references/ui-ux-checklist.md`)
- Auth, input, network, secrets → `security-auditor` (`52-security-and-hardening`)
- Measurable performance claims or large data → `test-engineer` for perf tests

### Step 6 — Address objections

For each strong objection from the sub-agents, do one of:

- Fix the code
- Update the spec (if the objection reveals a missed requirement)
- Record as residual risk in `review.md` with rationale

Never silently dismiss.

### Step 7 — Final read-through

Now re-read the diff one more time end-to-end. The same diff you reviewed in pieces; now as a coherent change. Anything stands out?

### Step 8 — Sign off

Mark `Status: Reviewed` in spec.md. Write to the ledger. The change is now eligible for `/ship`.

## review.md template

```markdown
# Review: <feature>

- Reviewer: <human-name> with agent-rigor
- Date: <ISO>
- Cooling-off respected: <Yes / Waiver: ...>

## Five-axis review

### Correctness
<observations, fixes applied, residual concerns>

### Clarity
<...>

### Complexity
<cyclomatic numbers if measured, any refactors applied>

### Consistency
<convention adherence, any deviations and why>

### Coverage
<test summary, any gaps>

## Sub-agent output

### code-reviewer
<verbatim or summary, with response>

### devils-advocate
<verbatim or summary, with response per objection>

### <other sub-agent if invoked>
<...>

## Residual risks
- <risk> — accepted because <reason> — review-by <date>

## Verdict
<Approved for /ship | Send back to /build | Send back to /spec>
```

## Rationalizations

| Rationalization | Refutation |
|---|---|
| "I just wrote this, I know it" | That's why cooling-off exists. You know what you _intended_, not what's _there_. |
| "The tests pass, that's the review" | Tests verify intent. Review verifies design, clarity, consistency, surprises. |
| "Devils-advocate always objects, it's noise" | Then read the objections, judge each, and write down why you dismissed it. The discipline is in the act, not the verdict. |
| "I don't have time for a full five-axis review" | Then your changes are too big. Smaller PRs make full review cheap. |

## Red Flags

- Review completed in < 5 minutes for a non-trivial change
- No sub-agents invoked
- review.md mentions all five axes but every section is "looks fine"
- Cooling-off waiver issued every time
- Residual risks listed but no review-by date
- Approved for /ship while tests are skipped or failing

## Verification

- [ ] Cooling-off respected or explicit waiver in ledger
- [ ] Five axes covered in review.md
- [ ] `code-reviewer` sub-agent invoked
- [ ] `devils-advocate` sub-agent invoked
- [ ] Applicable specialised sub-agents invoked (ui, security)
- [ ] All strong objections addressed (fixed, spec-updated, or accepted-with-rationale)
- [ ] Final read-through performed
- [ ] Spec status updated to Reviewed

## Solo-Developer Adaptation

The whole skill is shaped for solo mode. The two non-negotiables are the cooling-off (30 min minimum, ideally next session) and the adversarial sub-agent. If you do the rest perfectly but skip those, you've done a self-review, not a code review.

## macOS Notes

```bash
# Compute cooling-off remaining:
LAST="$(cat .claude/ledger/.last_source_write 2>/dev/null)"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Last source write: $LAST"
echo "Now: $NOW"

# Diff overview before review:
git diff main --stat
git diff main | wc -l    # total changed lines

# Complexity for JS/TS:
npx -y complexity-report src/auth/

# Complexity for Python:
brew install radon 2>/dev/null || pip3 install --user radon
radon cc src/auth/ -a
```

## Attribution

Adapted from `addyosmani/agent-skills` (MIT, skill `code-review-and-quality`).
