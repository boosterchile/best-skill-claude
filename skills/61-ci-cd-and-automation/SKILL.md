---
name: ci-cd-and-automation
description: Continuous integration and delivery pipeline. Every commit on a feature branch runs the same checks that gate /ship. Use during /ship and whenever the pipeline is missing a check that should fail builds (security scan, perf budget, accessibility scan, license check).
requires: nothing
produces:
  - .github/workflows/*.yml (or equivalent for your CI)
  - Pipeline that gates merges to main
phase: ship
adapted_from: addyosmani/agent-skills (MIT)
---

# CI/CD and Automation

> The pipeline is the only reviewer that never gets tired, never has an off day, and never forgets a rule. Make it your second pair of eyes.

## When to use

- Project setup: CI doesn't exist yet
- A check that catches problems locally isn't running in CI
- A repeated incident reveals a check that should have failed the build
- Deployment is manual and you keep skipping a step

## The minimum pipeline

```
checkout → install deps → lint → type-check → test → build → security scan → bundle/budget check → upload artifact → deploy
```

Each step:

- Runs on every push to feature branches (fast feedback)
- Gates merge to `main`
- Is fast enough to finish in < 5 minutes (or budget < 15)
- Produces an artifact or report that can be inspected

## Process

### Step 1 — Inventory local checks

What do you run locally before saying "done"? Everything on that list goes in CI:

```
npm run lint
npm run type-check
npm run test -- --coverage
npm run build
npm audit --production
npm run lighthouse:budget   # if a perf budget exists
```

If you don't run these locally, also add them to CI _and_ to a pre-commit / pre-push hook. Hooks catch issues seconds after introduction; CI catches them minutes after.

### Step 2 — Author the workflow

GitHub Actions example (works on macOS runners; pick `ubuntu-latest` for cheaper minutes if compat allows):

```yaml
# .github/workflows/ci.yml
name: ci

on:
  push:
    branches: ['**']
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  verify:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0   # for changelog and bisect

      - uses: actions/setup-node@v4
        with:
          node-version-file: '.nvmrc'
          cache: 'npm'

      - run: npm ci
      - run: npm run lint
      - run: npm run type-check
      - run: npm run test -- --coverage --reporter=json --outputFile=coverage/test-results.json
      - run: npm run build

      - name: Security audit
        run: npm audit --production --audit-level=high

      - name: Secret scan
        uses: gitleaks/gitleaks-action@v2
        env:
          GITLEAKS_LICENSE: ${{ secrets.GITLEAKS_LICENSE || '' }}

      - name: Lighthouse budget (mobile)
        run: |
          npm run start &
          sleep 5
          npx -y @lhci/cli@0.13 autorun --config=./lighthouserc.json

      - name: Accessibility scan
        run: |
          npm run start &
          sleep 5
          npx -y @axe-core/cli http://localhost:3000 --exit

      - name: agent-rigor scorecard
        if: always()
        run: bash benchmark/scripts/score-session.sh --since "7 days ago" --format json > scorecard.json || true

      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: ci-artifacts
          path: |
            coverage/
            scorecard.json
            .lighthouseci/
```

### Step 3 — Branch protection

In GitHub: Settings → Branches → Add rule for `main`:

- Require status checks to pass before merging: ✓
- Require branches to be up to date before merging: ✓
- Required checks: `verify`
- Require linear history: ✓ (matches `60-git-workflow-and-versioning`)
- Restrict who can push to matching branches: only you (or only via PR)

Solo developer caveat: this rule means even you cannot push directly to `main`. That's a feature. It's a guardrail against the 11 pm "just one quick fix" that bypasses CI.

### Step 4 — Deployment

Two patterns work for solo:

#### A. Tag-based deploy

```yaml
# .github/workflows/release.yml
on:
  push:
    tags: ['v*']
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci && npm run build
      - run: <deploy command, e.g. vercel deploy --prod>
```

Trigger by `git tag -a v0.3.0 ... && git push origin v0.3.0`. Combined with `gh release create v0.3.0 --generate-notes`, this is your "ship".

#### B. main-deploys-prod (continuous)

For low-stakes projects:

```yaml
on:
  push:
    branches: [main]
```

Combine with feature flags so unfinished work is hidden but already deployed. Requires a flag system and high test confidence.

### Step 5 — Pipeline budget

CI runs cost time and money. Audit:

- Total pipeline time per push: target < 5 min, cap at 15 min
- Cached dependencies (`actions/setup-node` cache, `actions/cache` for build outputs)
- Tests parallelised if > 60s sequentially
- Heavy jobs (lighthouse, e2e) only on PR-to-main, not every feature branch push

### Step 6 — Make failures actionable

A CI failure should tell you exactly what to do. If the message is "test failed" with no context, the next person (including you, in 3 weeks) will not know where to look.

- Tests report which test, which line, which assertion
- Lint reports which rule, which file
- Lighthouse reports which budget exceeded by how much
- Artifacts uploaded so you can download the failing report

## Rationalizations

| Rationalization | Refutation |
|---|---|
| "I run everything locally, CI is redundant" | CI runs on a clean machine. Your laptop has uncommitted state, stale node_modules, env vars from another project. CI is the only honest run. |
| "CI is slow" | Slow CI is fixable (cache, parallel, smaller surface). Slow CI is still faster than the bug you'd ship without it. |
| "I'll add deploy automation when I have users" | When you have users is too late; that's when the manual mistake costs the most. |
| "Pipeline complexity is overkill solo" | Each step in the pipeline solves a real failure mode. Remove only with measurement that it never fires. |

## Red Flags

- CI green but `npm test` fails locally
- A check exists locally but not in CI (lint rule, env-specific test)
- Pipeline time > 15 minutes (you'll start ignoring failures while it runs)
- Branch protection disabled "while I'm fixing CI"
- Deploy step that runs even when verify fails (verify is gating, not advisory)
- Secrets logged in CI output (`echo $TOKEN` for "debugging")

## Verification

- [ ] CI workflow file exists and runs on every push
- [ ] All local pre-commit checks also run in CI
- [ ] Branch protection on `main` requires CI green
- [ ] Pipeline < 15 minutes (target < 5)
- [ ] Failed builds produce inspectable artifacts
- [ ] Deploy is automated (tag-based or main-based)
- [ ] No secrets in workflow files or logs

## Solo-Developer Adaptation

The biggest solo failure mode: disabling branch protection to push a "small fix". Resist. Use `gh pr create --fill && gh pr merge --auto --squash` to keep flow without breaking the rule.

For deploys: pair tag-based deploy with `gh release create --draft`. The draft release is your ship checklist (see `64-shipping-and-launch`).

## macOS Notes

```bash
# Run CI locally with act:
brew install act
act -j verify                  # simulate the verify job
act push -W .github/workflows/ci.yml

# gh CLI for PR-driven flow:
gh pr create --fill
gh pr checks --watch           # tail CI status from terminal
gh pr merge --auto --squash    # merge when checks pass

# Quick local pre-commit hook:
cat > .git/hooks/pre-push <<'SH'
#!/bin/sh
set -e
npm run lint
npm run type-check
npm run test -- --run
SH
chmod +x .git/hooks/pre-push
```

## Attribution

Adapted from `addyosmani/agent-skills` (MIT, skill `ci-cd-and-automation`).
