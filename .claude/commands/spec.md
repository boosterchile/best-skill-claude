---
description: Start DEFINE phase — produce or update .specs/<feature>/spec.md
argument-hint: <feature-slug>
---

# /spec <feature-slug>

You are entering the DEFINE phase for `$ARGUMENTS`.

## What to do, in order

1. **Read CLAUDE.md** if not yet this session. (The pre-tool-use hook will block you if you haven't.)
2. **Read** `skills/11-spec-driven-development/SKILL.md` end to end. The 13 mandatory sections of `spec.md` are defined there.
3. **Check if `.specs/$ARGUMENTS/idea.md` exists.**
   - If yes: use it as the seed; lift Actor / Problem / Outcome into spec §1, §2, §3.
   - If no, and the user's intent is still vague: read `skills/10-idea-refine/SKILL.md` and produce `idea.md` first. Then come back to spec.
4. **Scaffold the spec:**
   ```bash
   F="$ARGUMENTS"
   mkdir -p ".specs/$F"
   test -f ".specs/$F/spec.md" || cat > ".specs/$F/spec.md" <<'SPEC'
   # Spec: $F

   - Status: Draft
   - Created: <ISO>
   - Updated: <ISO>

   ## 1. Objective
   ## 2. Why now
   ## 3. Success criteria (measurable)
   ## 4. User-visible behaviour
   ## 5. Out of scope
   ## 6. Constraints
   ## 7. Approach
   ## 8. Risks
   ## 9. Alternatives considered (rejected)
   ## 10. Test list
   ## 11. Open questions
   ## 12. Devils-advocate pass
   ## 13. Approval
   SPEC
   ```
5. **Fill the spec deliberately.** Every section. Empty sections are a smell that the spec isn't ready.
6. **Invoke the `devils-advocate` sub-agent** with the draft spec as input. Capture its objections into §12. Address each one (fix the spec, justify, or accept as residual risk).
7. **Present the spec to the user.** Wait for explicit approval. Do not progress to `/plan` without an "approved" or equivalent.
8. **On approval:**
   - Update Status: Approved
   - Update §13 with date and any caveats
   - Write a ledger entry:
     ```bash
     LEDGER="$(cat .claude/ledger/.current)"
     echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"artifact_produced\",\"kind\":\"spec\",\"path\":\".specs/$ARGUMENTS/spec.md\"}" >> "$LEDGER"
     echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"phase_exit\",\"phase\":\"define\",\"feature\":\"$ARGUMENTS\"}" >> "$LEDGER"
     ```

## What NOT to do

- Do not start planning. `/plan` is a separate command.
- Do not write code. Specs precede code. Always.
- Do not skip the devils-advocate pass. The benchmark tracks it.
- Do not present an empty-sectioned spec for approval.

## Success of this command

`.specs/$ARGUMENTS/spec.md` exists with Status: Approved, all 13 sections filled (or the empty ones explicitly marked N/A with rationale), devils-advocate output captured, ledger entries written.
