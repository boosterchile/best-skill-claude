---
description: Start SHIP phase — 12-point checklist, version bump, tag, release, deploy, monitor
argument-hint: <feature-slug>
---

# /ship <feature-slug>

You are entering the SHIP phase for `$ARGUMENTS`.

## Pre-checks

1. `.specs/$ARGUMENTS/review.md` exists with verdict `Approved for /ship`.
2. All CI checks green on the merge commit (or on the latest commit if you haven't merged yet).
3. Working tree clean.

## What to do

1. **Read** `skills/64-shipping-and-launch/SKILL.md` and `skills/60-git-workflow-and-versioning/SKILL.md`. If documentation needs updating, also `skills/63-documentation-and-adrs/SKILL.md`.
2. **Walk the 12-point checklist.** For each, mark ✓ or `[waiver: <reason>]` in `ship.md`. Items: CI green / Changelog / Version / Migration / Flags / Rollback plan / Reversibility / Telemetry / Secrets-config / Docs / Communication / Rollback-rehearsed.
3. **Bump version** (SemVer):
   ```bash
   # Node:
   npm version <patch|minor|major> -m "chore(release): v%s"
   # Or edit manually for non-Node stacks.
   ```
4. **Move changelog entries** from `## [Unreleased]` to `## [vX.Y.Z] - <date>`.
5. **Write** `.specs/$ARGUMENTS/ship.md` per the template in the skill, including rollback procedure and post-deploy verification plan.
6. **Final devils-advocate pass** for irreversibility:
   - Invoke `devils-advocate` with `ship.md` + the planned rollback procedure
   - Address objections before tagging
7. **Tag and release:**
   ```bash
   VERSION="v$(node -p "require('./package.json').version" 2>/dev/null || cat VERSION 2>/dev/null)"
   git push --follow-tags
   gh release create "$VERSION" --generate-notes
   ```
8. **Watch deploy**, run smoke checks listed in `ship.md`.
9. **Progressive rollout** (if feature flags): 1% → 10% → 50% → 100%, monitoring between each step.
10. **Update spec status** to `Shipped vX.Y.Z on <ISO>`.
11. **Ledger:**
    ```bash
    LEDGER="$(cat .claude/ledger/.current)"
    echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"artifact_produced\",\"kind\":\"ship\",\"path\":\".specs/$ARGUMENTS/ship.md\"}" >> "$LEDGER"
    echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"shipped\",\"feature\":\"$ARGUMENTS\",\"version\":\"$VERSION\"}" >> "$LEDGER"
    ```
12. **Schedule a 24h self-postmortem.** Three lines: what worked, what surprised, what you'd do differently. Append to `ship.md`.

## What NOT to do

- Do not skip rollback rehearsal for changes touching auth, money, or data integrity.
- Do not batch unrelated changes into one release.
- Do not deploy on a Friday afternoon without explicit waiver and a Saturday plan.
- Do not announce until smoke checks pass.

## Success of this command

`ship.md` complete, tag pushed, GitHub release created, deploy verified, telemetry monitored, spec status `Shipped`, ledger updated.
