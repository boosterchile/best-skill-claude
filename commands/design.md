---
description: Generate or update design-system/MASTER.md and optionally a page override
argument-hint: [optional: page=<page-slug>] [optional: product=<product-context>]
---

# /design [page=<slug>] [product=<context>]

You are establishing or updating the design system.

## When to run

- Before any UI work in a new project (no `design-system/MASTER.md` yet)
- When a major product reframing changes the visual direction
- When adding a page that deserves an override (e.g., a marketing page in an otherwise utilitarian product)
- When the agent's UI output keeps drifting from the intended style

## What to do

1. **Read** `skills/35-design-system-generation/SKILL.md` end to end.
2. **Determine mode:**
   - If `design-system/MASTER.md` does NOT exist → generate it now.
   - If `MASTER.md` exists and `page=<slug>` provided → create `design-system/pages/<slug>.md`.
   - If `MASTER.md` exists and you want to revise it → propose the diff to the user first.
3. **Gather product context.** If not provided in arguments, ask the user:
   - Product name and one-paragraph description
   - Primary user (role, context, expertise)
   - Industry / domain
   - Tone the brand should project (5-7 adjectives)
   - Direct or aspirational reference products (visual or product-experience)
   - Anti-references (what we explicitly do NOT want to feel like)
   - Hard constraints (must work on low-end Android, must support RTL, must meet WCAG 2.2 AA, etc.)
4. **Reason through the mapping tables** from `35-design-system-generation`. For each product class:
   - Pattern family
   - Visual style (typography pairing, color palette, density, motion)
   - Component conventions
   - Accessibility commitments
   - Anti-patterns specific to this product
5. **Generate MASTER.md** with the 14 mandatory sections. Be opinionated and specific — no "depending on context" hedges.
6. **Invoke `ux-designer`** sub-agent to review the draft.
7. **Present to user.** Wait for explicit approval.
8. **On approval:**
   ```bash
   LEDGER="$(cat .claude/ledger/.current)"
   echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"artifact_produced\",\"kind\":\"design_master\",\"path\":\"design-system/MASTER.md\"}" >> "$LEDGER"
   ```

## For page override mode

1. Read `design-system/MASTER.md`.
2. Identify only what differs for this page (not the whole system).
3. Write `design-system/pages/<page>.md` with ONLY the deltas, plus a `## Rationale` section explaining why this page differs.
4. Link from MASTER.md's page index.
5. Invoke `ux-designer` for review.

## What NOT to do

- Do not generate a generic "modern minimal" system. The whole point of MASTER is opinionated specificity. Pick a side; document why.
- Do not override at the page level for cosmetic preference. Page overrides need justification.
- Do not include Python search.py or any external dependency. The reasoning happens in the agent + tables.
- Do not skip the anti-patterns section. "What this product is not" is as important as what it is.

## Success of this command

`design-system/MASTER.md` exists with 14 sections, opinionated and specific, ux-designer approved, user approved, ledger updated. (Or a page override created.)
