---
name: shipping-and-launch
description: SHIP phase. Final checklist before a change reaches users, plus the launch ritual itself — version bump, changelog, release notes, deploy, post-deploy verification, and the moment the spec moves to Shipped. Use after /review approves. Solo-developer mode adds explicit rollback rehearsal.
requires:
  - .specs/<feature>/review.md with verdict Approved
  - All CI checks green on main branch
produces:
  - .specs/<feature>/ship.md
  - Git tag and GitHub release
  - Updated CHANGELOG.md
phase: ship
adapted_from: addyosmani/agent-skills (MIT)
---

# Shipping and Launch

> Shipping is not pressing a button. Shipping is the deliberate act of moving a change from "approved" to "users feel it", with the ability to take it back if it was a mistake.

## When to use

`/ship` triggers this skill. It runs after `/review` produces a verdict of `Approved for /ship`. The hook checks for the review.md and refuses to start without it.

## The 12-point checklist

Run through every item before tagging. Mark each in `ship.md` as ✓ or `[waiver: <reason>]`.

### 1. Tests green on the merge commit

Not the feature branch — the merge commit on `main`. CI must have run after merge and passed.

```bash
gh run list --branch main --limit 1
gh run view <id>
```

### 2. Changelog updated

`CHANGELOG.md` `## [Unreleased]` section has entries for everything shipping. Move them to a versioned section:

```diff
- ## [Unreleased]
+ ## [Unreleased]
+
+ ## [0.4.0] - 2026-05-13
```

### 3. Version bumped

Follow SemVer:

- Patch: bug fixes only
- Minor: backward-compatible additions
- Major: any breaking change

```bash
npm version minor --no-git-tag-version   # for Node
# or edit pyproject.toml / Cargo.toml manually for other stacks
```

Bump in a commit on `main`, not in the feature branch.

### 4. Migration guides referenced (if breaking)

If any `62-deprecation-and-migration` is part of this release, the changelog links to the migration doc. Removal commits are explicit about consumer impact.

### 5. Feature flags configured

For risky changes, ship behind a flag, off by default:

```typescript
if (flags.isOn('auth.refresh-rotation-v2')) {
  return v2Path();
}
return v1Path();
```

Then enable progressively (1% → 10% → 50% → 100%). Each step waits for monitoring to confirm health.

### 6. Rollback plan documented

For each change in the release, exactly _how_ would you roll back?

- Revert the deploy (works for stateless changes)
- Revert + DB migration reversal (works if the migration is reversible)
- Flag-flip back to v1 (works if you used feature flags)
- Hotfix on top (works if the bug is contained and a fix is fast)

The rollback plan goes in `ship.md`. If you cannot articulate it, you cannot deploy.

### 7. Migrations are reversible (or explicit one-way)

DB migrations: include the `down` migration. If a migration is truly one-way (data drop, type narrowing), label it as such with explicit acknowledgement.

```sql
-- migrations/0042_refresh_token_pair.up.sql
-- IRREVERSIBLE: this drops the old session column.
-- See ADR-0007 for rationale.
ALTER TABLE sessions DROP COLUMN access_token;
```

### 8. Telemetry in place

Before shipping, the relevant metrics, logs, and alerts must already be live. Otherwise you ship blind.

- Counter: how many times the new code path runs
- Latency: p50, p95, p99 for new endpoints
- Errors: rate per error class
- Business: the success criterion from spec §3, observable

### 9. Configuration / secrets in place

Production has the right values:

- New env vars set in the runtime
- New secrets in the vault
- New flags created in the flag system
- New permissions granted to service accounts

This is the most common "I forgot" failure mode. Make a literal list, check each.

### 10. Documentation updated

User-facing docs reflect the new behaviour. The README mentions any new step. New ADRs are linked from the index.

### 11. Communication ready

Solo-developer minimum: the release notes (auto-generated from changelog).

If this is a public project: release tweet drafted, blog post drafted if applicable, support docs updated.

### 12. Rollback rehearsed (mandatory for irreversible / risky)

For changes touching auth, money, data integrity, or with a non-trivial rollback plan: walk through the rollback once in staging. Time it. Document the actual steps.

## Process

### Step 1 — Verify all 12 boxes

Write `ship.md`:

```markdown
# Ship: <feature>

- Spec: .specs/<feature>/spec.md
- Review: .specs/<feature>/review.md (Verdict: Approved)
- Date: <ISO>
- Version: vX.Y.Z

## Checklist
- [x] CI green on merge commit (run #<id>)
- [x] Changelog updated
- [x] Version bumped (vX.Y.Z)
- [x] Migration guides referenced (N/A | links)
- [x] Feature flags configured (N/A | flag-name=off)
- [x] Rollback plan: <how>
- [x] Migrations reversible (or explicit one-way: <yes/no>)
- [x] Telemetry in place: <metrics/dashboards>
- [x] Config/secrets in place: <list>
- [x] Documentation updated
- [x] Communication ready
- [x] Rollback rehearsed: <yes / N/A — reason>

## Rollback procedure

Step-by-step, copy-pasteable:

```bash
# 1. Disable feature flag
flagctl set auth.refresh-rotation-v2 false --env=production

# 2. Verify v1 path is serving
curl https://api.example.com/health | jq .auth_version
# Expect: "v1"

# 3. If still hot, revert deploy
vercel rollback --token=$VERCEL_TOKEN <deployment-id>
```

## Post-deploy verification plan

What to watch for the first <N hours/days>:
- Metric A: <expected baseline>
- Error rate: < <threshold>
- Spec §3 success criterion: <how to observe>
```

### Step 2 — Tag

```bash
# After merging release-prep commit (changelog + version bump):
git tag -a v0.4.0 -m "Release v0.4.0: <feature title>"
git push origin v0.4.0
```

### Step 3 — GitHub release

```bash
gh release create v0.4.0 --generate-notes \
  --notes-file <(awk '/^## \[0.4.0\]/{flag=1;next}/^## /{flag=0}flag' CHANGELOG.md)
```

This triggers the `release.yml` workflow (see `61-ci-cd-and-automation`), which deploys.

### Step 4 — Watch the deploy

Open the deploy log. Wait for completion. Run the smoke checks listed in `ship.md` Post-deploy section.

### Step 5 — Progressive rollout (if flags)

```bash
flagctl set auth.refresh-rotation-v2 --percent=1 --env=production
# Wait 30 min. Check telemetry.
flagctl set auth.refresh-rotation-v2 --percent=10 --env=production
# Wait 2 hours.
flagctl set auth.refresh-rotation-v2 --percent=50
# Wait until next morning.
flagctl set auth.refresh-rotation-v2 --percent=100
```

Each step: monitor first, advance second. If anything looks off at 1% or 10%, flip back to 0 and investigate before any user-facing communication.

### Step 6 — Update spec status

```diff
- - Status: Reviewed
+ - Status: Shipped vX.Y.Z on <ISO>
```

Commit, push.

### Step 7 — Write the ledger entry

```bash
LEDGER="$(cat .claude/ledger/.current)"
cat >> "$LEDGER" <<JSON
{"ts":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","type":"shipped","feature":"$F","version":"v0.4.0"}
JSON
```

### Step 8 — Close the cycle

The cycle for this feature is done. Next feature starts a new cycle. `.specs/<feature>/` is now a permanent record — do not delete it.

## Rationalizations

| Rationalization | Refutation |
|---|---|
| "Tests passed, just deploy" | Tests verify what you thought to test. Production verifies what you didn't. Watch telemetry. |
| "Rollback plan is just `git revert`" | For stateless code, yes. For DB migrations, payment integrations, third-party state — no. Spell it out. |
| "Feature flags are overkill for solo" | Until a 100% deploy breaks 100% of users. Flags scale your error blast radius. |
| "I'll do progressive rollout if the change is risky" | Past tense. Decide in advance which changes are risky and ship them on flags. |
| "I tagged but didn't announce" | The release notes are the announcement. They exist whether you publish or not. |

## Red Flags

- Tag without changelog entry
- Release without verified rollback plan
- "Just push to main and see" without any monitoring
- Migration that drops data with no backup
- Deploying on a Friday afternoon (solo: yes, this rule applies to you)
- Skipping progressive rollout for a change touching auth/money/data
- Telemetry added _after_ noticing a problem
- Multiple unrelated changes in one release ("v0.4.0: auth refresh + billing fixes + dashboard redesign")

## Verification

- [ ] All 12 checklist items ✓ or waiver
- [ ] `ship.md` written and committed
- [ ] Version bumped according to SemVer
- [ ] Changelog moved from Unreleased to versioned section
- [ ] Git tag pushed
- [ ] GitHub release created with notes
- [ ] Deploy completed and verified
- [ ] Post-deploy smoke checks run
- [ ] Telemetry watched for the documented window
- [ ] Spec status updated to Shipped

## Solo-Developer Adaptation

The forces against rigor on `/ship` are highest because you're closest to done. Three solo-specific habits:

1. **Friday rule**: don't ship Fridays unless the rollback can be executed by you on a Saturday. This is not about work-life balance (it is, but not only). It's about cognitive bandwidth when something breaks.
2. **Two-window rule**: schedule a 10-minute "watch the deploy" window and a 60-minute "watch telemetry" window. Block them. Don't multitask.
3. **Self-postmortem at 24h**: 24 hours after ship, write 3 lines: what worked, what surprised you, what would you do differently. Add to `ship.md`. Over time these compound into the most valuable training data you have.

## macOS Notes

```bash
# Bump and tag in one go (Node project):
npm version minor -m "chore(release): v%s"
git push --follow-tags

# Release notes from CHANGELOG:
gh release create "v$(jq -r .version package.json)" \
  --notes-file <(awk '/^## \[.*\] - /{if(found){exit}found=1}found' CHANGELOG.md)

# Watch a deploy log in a separate terminal:
gh run watch  # interactive

# Quick smoke check (curl with timing):
curl -w '@-' -o /tmp/health -s https://api.example.com/health <<'EOF'
HTTP %{http_code}  in  %{time_total}s
EOF
```

## Attribution

Adapted from `addyosmani/agent-skills` (MIT, skill `shipping-and-launch`).
