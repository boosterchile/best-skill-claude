---
name: documentation-and-adrs
description: Capture decisions (ADRs), maintain README and onboarding, write user-facing docs at the same cadence as code. Use whenever a non-obvious decision is made (ADR), whenever a public surface ships (user doc), and during /ship (changelog + release notes).
requires: nothing
produces:
  - docs/adr/NNNN-<topic>.md
  - README.md updates
  - CHANGELOG.md entry
  - User-facing docs (where applicable)
phase: build / ship
adapted_from: addyosmani/agent-skills (MIT)
---

# Documentation and ADRs

> Code that ships without documentation has been written, not delivered. The first reader who isn't you decides whether the documentation exists or not.

## What gets documented when

| Trigger | Artefact |
|---|---|
| Non-obvious decision with future consequences | ADR in `docs/adr/` |
| Public surface (API, CLI, library) ships or changes | User doc in `docs/` |
| Any release | `CHANGELOG.md` entry + GitHub release notes |
| Onboarding question that you've now answered twice | README or `docs/getting-started.md` |
| Operational behaviour (start, stop, recover, observe) | `docs/operations.md` or runbook |
| Setup steps that differ per platform | `docs/setup/<platform>.md` |

If you're about to explain something in a chat for the second time, it should already have been a document the first time.

## ADRs (Architecture Decision Records)

An ADR captures _why_ a decision was made, given alternatives considered, at a moment in time. It is not a tutorial; it is evidence.

### When to write an ADR

- Choice between two or more credible options where the loser had real merit
- Decision that future readers might want to revisit ("why did we pick library X?")
- Decision that is non-obvious from the code alone
- A "no" decision (rejected a feature, declined a dependency)
- Anything that the agent's `devils-advocate` raised and you addressed

### ADR template

```markdown
# ADR-NNNN: <short title>

- Status: Proposed | Accepted | Superseded by ADR-MMMM | Deprecated
- Date: <ISO>
- Deciders: <names; solo: "alone, after cooling-off and devils-advocate pass">
- Spec: .specs/<feature>/spec.md (if applicable)

## Context

<What's the situation? What forces are at play? What constraints exist?>

## Decision

<What did we choose to do? State the decision in one paragraph, then the
details. Be specific enough that a reader can recognise the decision in code.>

## Alternatives considered

### A. <Option name>
- Pros: ...
- Cons: ...
- Why not: <one sentence>

### B. <Option name>
- Pros: ...
- Cons: ...
- Why not: <one sentence>

## Consequences

### Positive
- <what becomes easier>

### Negative
- <what becomes harder, what we accept>

### Neutral
- <what changes but isn't clearly better or worse>

## Compliance and validation

<How do we know this decision is being followed? Lint rule, CI check, code review checklist.>

## Revisit when

<Concrete signal that should trigger reopening this ADR. e.g., "if we exceed
1000 RPS on this endpoint" or "if a third-party caller appears".>
```

### Numbering

Pad to 4 digits: `0001-`, `0002-`, ... `0042-`. Never reuse a number; superseded ADRs stay in place with status `Superseded by ADR-NNNN`.

### Where to put them

`docs/adr/`. Flat, sortable, greppable. No subdirectories.

```
docs/adr/
├── 0001-monorepo-or-polyrepo.md
├── 0002-react-vs-vue.md
├── 0003-jwt-refresh-rotation.md
├── 0004-deprecate-v1-login.md       # supersedes 0002 partially
└── README.md                         # index, auto-generatable
```

## README

The README answers the first three questions a new reader has:

1. **What is this project?** (one paragraph, concrete)
2. **How do I run it?** (commands, with macOS instructions if applicable)
3. **Where do I look next?** (links to deeper docs)

Anti-patterns:

- README that's a marketing page (move to a separate `MARKETING.md` or website)
- README that documents the codebase architecture in detail (move to `docs/architecture.md`)
- README with no command to run the project locally

Solo-developer template:

```markdown
# <project>

<One-paragraph elevator pitch: what does this do for whom?>

## Quick start

```bash
git clone https://github.com/you/project
cd project
nvm use
npm install
npm run dev
```

Open http://localhost:3000.

## Next steps

- [Architecture](docs/architecture.md)
- [Setup on macOS](docs/setup/macos.md)
- [ADR index](docs/adr/)
- [Contributing](CONTRIBUTING.md) (even solo, the "future you" contributor)
- [Releases](https://github.com/you/project/releases)

## Status

<Active | Maintenance | Archived> · Last release: vX.Y.Z · Built with agent-rigor.
```

## CHANGELOG.md

Follow [Keep a Changelog](https://keepachangelog.com/):

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- Refresh token rotation with 24h grace window. See ADR-0003.

### Changed
- POST /v1/login deprecated (see migrations/0001-v2-auth-sessions.md).

### Fixed
- Null currency in invoice render (issue #42).

## [0.3.0] - 2026-05-13

### Added
- ...
```

For releases, run:

```bash
# Use gh release with --notes-from-tag or --generate-notes:
gh release create v0.3.0 --generate-notes
```

## User-facing docs

If your project has users beyond yourself:

```
docs/
├── getting-started.md       # 5-minute tutorial
├── concepts/                # the mental model
├── how-to/                  # task-oriented recipes
├── reference/               # API and CLI complete reference
└── operations/              # for those running it
```

This follows [Diátaxis](https://diataxis.fr/) — tutorial / how-to / reference / explanation. Don't mix them in one page.

## Process

### Step 1 — Decide if the change deserves an ADR

Ask:

- Were there credible alternatives? → ADR
- Will the rationale be obvious in code? → No ADR
- Could this be reversed silently? → No ADR
- Did `devils-advocate` raise alternatives? → ADR

### Step 2 — Write the ADR before committing the decision

The ADR is part of the same commit as the change, not a follow-up.

### Step 3 — Update the changelog

Every PR touches `CHANGELOG.md` under `## [Unreleased]`. No "I'll batch them at release time" — by then you've forgotten.

### Step 4 — Update README if affected

A new dependency, a new env var, a new top-level command: README needs an update.

### Step 5 — Cross-reference

In code: comment near the implementation references the ADR.

```typescript
// See ADR-0003 for the rationale on rotation overlap.
const GRACE_WINDOW_MS = 24 * 60 * 60 * 1000;
```

In ADRs: link to the code path via permalink (`https://github.com/.../blob/<sha>/src/auth.ts#L42`).

## Rationalizations

| Rationalization | Refutation |
|---|---|
| "I'll document at the end" | At the end, the context that justified the decision is forgotten. Document while it's fresh. |
| "The code is self-documenting" | Code shows _what_, not _why_. ADRs are about _why_. |
| "Solo developers don't need ADRs" | Solo developers need ADRs more. There's no colleague to ask. |
| "We'll write docs when we have users" | Users arrive with five-minute attention spans. Docs aren't ready in a week; write them as you build. |
| "The README is already long enough" | Length isn't the metric. Answering the first three questions correctly is. |

## Red Flags

- Decision in code with no ADR, where alternatives existed
- ADRs without status (everything is "Proposed" forever)
- Changelog only updated at release ("v0.3.0: many improvements")
- README that doesn't say how to run the project
- Docs scattered without an index
- ADR superseded silently (old ADR has `Accepted`, new ADR doesn't reference it)
- Three-month-old ADR with `Status: Proposed`

## Verification

- [ ] Each decision spec → ADR existence checked
- [ ] ADR has Status, Date, Context, Decision, Alternatives, Consequences
- [ ] `CHANGELOG.md` updated this commit
- [ ] README quick-start works on a clean macOS install
- [ ] Public surface change has a user-facing doc update
- [ ] Cross-references between code and ADRs in place

## Solo-Developer Adaptation

Two solo-specific habits:

1. **Write the ADR before the implementation.** If you can write the ADR convincingly, you understand the decision. If you cannot, you don't yet — slow down.
2. **Quarterly ADR review.** Once a quarter, re-read open ADRs and update status. ADRs that became obsolete get marked `Superseded`. Saves you from "what did I decide about X in 2024?" in 2026.

## macOS Notes

```bash
# Bootstrap a new ADR:
N=$(printf '%04d' $(( $(ls docs/adr/ | grep -c '^[0-9]') + 1 )))
SLUG="auth-refresh-rotation"
F="docs/adr/${N}-${SLUG}.md"
mkdir -p docs/adr
cp templates/adr.md "$F"
sed -i '' "s/NNNN/${N}/g; s/TITLE/$(echo $SLUG | tr '-' ' ')/g; s/DATE/$(date -u +%F)/g" "$F"
open "$F"

# Generate an index of ADRs:
{
  echo "# ADR index"
  echo
  for f in docs/adr/[0-9]*.md; do
    title=$(grep -m1 '^# ' "$f" | sed 's/^# //')
    status=$(grep -m1 '^- Status:' "$f" | sed 's/^- Status: //')
    printf -- "- [%s](%s) — %s\n" "$title" "${f#docs/adr/}" "$status"
  done
} > docs/adr/README.md

# Spell-check docs:
brew install hunspell
find docs -name '*.md' -exec hunspell -l {} \; | sort -u
```

## Attribution

Adapted from `addyosmani/agent-skills` (MIT, skill `documentation-and-adrs`).
ADR format derived from Michael Nygard's "Documenting Architecture Decisions"
(public domain). Doc taxonomy from Diátaxis (CC BY-SA 4.0, https://diataxis.fr).
