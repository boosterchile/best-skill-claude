---
description: Start REVIEW phase — five-axis review with code-reviewer, devils-advocate, and applicable specialists
argument-hint: <feature-slug>
---

# /review <feature-slug>

You are entering the REVIEW phase for `$ARGUMENTS`.

## Pre-checks

1. `.specs/$ARGUMENTS/verify.md` exists with all tests green.
2. Cooling-off period elapsed (≥ 30 min since last source-file write).
   ```bash
   LAST="$(cat .claude/ledger/.last_source_write 2>/dev/null || echo 0)"
   NOW="$(date -u +%s)"
   LAST_EPOCH="$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$LAST" +%s 2>/dev/null || echo 0)"
   ELAPSED=$((NOW - LAST_EPOCH))
   if [ "$ELAPSED" -lt 1800 ]; then
       echo "Cooling-off: need $(((1800-ELAPSED)/60)) more minutes."
       echo "If you must override, include [waiver: <reason>] in your next message."
   fi
   ```

## What to do

1. **Read** `skills/50-code-review-and-quality/SKILL.md` end to end.
2. **Read the spec, plan, and verify cold.** You're reviewing the diff against these, not against your sense of "good code".
3. **Generate the diff** for review:
   ```bash
   git diff main...HEAD > /tmp/agent-rigor-diff.patch
   git diff main...HEAD --stat
   ```
4. **Walk the five axes** yourself first (correctness, clarity, complexity, consistency, coverage), making notes per file/function.
5. **Invoke the sub-agents in order:**
   - `code-reviewer` (always)
   - `devils-advocate` (always, mandatory in solo mode)
   - `security-auditor` if the diff touches auth, authorization, user input, secrets, network, persistence, or dependencies
   - `ux-designer` if the diff touches UI
   - `test-engineer` if the test-quality picture is unclear

   Each appends its findings section to `review.md`.
6. **Address every BLOCKING finding.** For each:
   - Fix it, OR
   - Update the spec if the finding reveals a missed requirement, OR
   - Accept as residual risk with explicit rationale and a review-by date
7. **Final read-through** of the entire diff end-to-end as a coherent change.
8. **Write the verdict** in `review.md`:
   - `Approved for /ship`
   - `Send back to /build` (with specific items)
   - `Send back to /spec` (with rationale)
9. **Update spec status** to `Reviewed` on approval.
10. **Ledger:**
    ```bash
    LEDGER="$(cat .claude/ledger/.current)"
    echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"artifact_produced\",\"kind\":\"review\",\"path\":\".specs/$ARGUMENTS/review.md\"}" >> "$LEDGER"
    echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"phase_exit\",\"phase\":\"review\",\"feature\":\"$ARGUMENTS\",\"verdict\":\"<verdict>\"}" >> "$LEDGER"
    ```

## What NOT to do

- Do not start `/ship` while BLOCKING findings remain.
- Do not silently dismiss findings. Every finding gets a fix, a justification, or a documented acceptance.
- Do not bypass cooling-off without an explicit `[waiver: <reason>]` — the benchmark counts every waiver.
- Do not skip sub-agents to "save time". The whole point of REVIEW is the adversarial pass.

## Success of this command

`review.md` complete with all sub-agents' findings, every BLOCKING addressed, verdict written, spec status updated, ledger written. The feature is eligible for `/ship`.
