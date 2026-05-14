---
name: git-workflow-and-versioning
description: Git practices that produce a useful history — atomic commits, conventional messages, clean branches, traceable to specs. Use during /build for every commit and during /ship for tagging. Solo-developer doesn't change the rules; if anything it tightens them, because future-you is the only reviewer.
requires: nothing
produces:
  - Clean commit history
  - Tags for releases
phase: ship / build
adapted_from: addyosmani/agent-skills (MIT)
---

# Git Workflow and Versioning

## Commit philosophy

A commit is a unit of revertibility. If you cannot answer "if this turns out to be wrong, what do I revert?", the commit is wrong-sized.

### Atomic commits

Each commit:

- Compiles
- Tests pass
- Does one thing
- Has a message that explains why (not just what)
- References its task in `plan.md` and ultimately its spec

### Conventional Commits

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:

| Type | Use for |
|---|---|
| `feat` | New user-visible behaviour |
| `fix` | Bug fix |
| `refactor` | Code change without behaviour change |
| `perf` | Performance improvement (with measurements) |
| `test` | Test additions or fixes |
| `docs` | Documentation only |
| `chore` | Tooling, build, deps |
| `revert` | Revert a previous commit |

Examples:

```
feat(auth): add OAuth refresh-token rotation

- Adds refresh_token rotation on every /auth/refresh
- 24h overlap window for in-flight requests with old token
- Adds RefreshTokenStore.rotate and accompanying tests

Closes T3 of .specs/auth-refresh/plan.md
Spec: .specs/auth-refresh/spec.md
```

```
fix(billing): handle null currency in invoice render

Cause: invoices migrated from v1 schema lack `currency`; renderer assumed string.
Fix: default to account's currency at render time; add regression test.
```

```
perf(dashboard): memoize row derived state

Before: p95 render 2.4s (n=20, Lighthouse desktop)
After:  p95 render 0.3s
Method: useMemo on row's computed fields.
```

## Branch strategy for solo developers

The minimum useful structure:

- `main` — always green, always deployable
- `feat/<short-name>` — feature branches (short-lived, ≤ 1 week ideally)
- `fix/<short-name>` — bug-fix branches

Avoid:

- `dev` and `staging` long-lived branches (in solo work, they bitrot)
- Personal forks of your own project

### Branch flow

```bash
git switch -c feat/auth-refresh
# work, commit small slices...
git fetch origin
git rebase origin/main        # keep linear, resolve conflicts now
git push -u origin feat/auth-refresh
# (optional) open a PR for the review record
gh pr create --fill
# After /review approves and /ship is done:
git switch main
git pull --rebase
git merge --ff-only feat/auth-refresh   # fast-forward, linear history
git push
git branch -d feat/auth-refresh
git push origin --delete feat/auth-refresh
```

### Why PRs solo

Even alone, opening a PR captures:

- The diff at a snapshot
- The CI run output
- The conversation with yourself (review.md attached as comment)
- Long-term auditability

This is one of the highest-value rituals in solo work. The cost is 30 seconds (`gh pr create --fill`).

## Rebasing

Solo work allows rebasing branches you haven't shared. Rules:

- **Never rebase shared branches** (`main`, anything someone else might have pulled)
- Use `git rebase -i` to squash trivial commits before merging
- After rebase, `git push --force-with-lease` (not `--force`)
- If a rebase corrupts work, `git reflog` shows the way back

## Tags and releases

Tag every shipped version. Use SemVer (`v0.3.1`, `v1.0.0`) for projects with users, or CalVer (`2026.05`, `2026.05-1`) for projects with continuous deployment.

```bash
# After /ship:
git tag -a v0.3.0 -m "Release v0.3.0: add OAuth refresh"
git push origin v0.3.0

# With gh:
gh release create v0.3.0 --generate-notes
```

## .gitignore for agent-rigor

```gitignore
# agent-rigor session ledgers (typically not committed; keep .gitkeep)
.claude/ledger/*.jsonl
.claude/ledger/.current
.claude/ledger/.last_source_write

# benchmark derived
benchmark/data/
benchmark/reports/*.html
!benchmark/reports/.gitkeep

# Scratch
.specs/_scratch/
```

Decision: commit `.specs/<feature>/` artefacts (yes), commit ledger (usually no — it's session-private noise; but in a regulated environment you might want to).

## Rationalizations

| Rationalization | Refutation |
|---|---|
| "I'll squash everything at the end" | Squashing loses the history of how the change evolved. Squash trivia, keep meaningful steps. |
| "Solo means I don't need PRs" | PRs are the audit log of why. You'll thank yourself in a year. |
| "Conventional commits are bureaucracy" | Tools (changelog generators, release notes) depend on them. They cost 5 seconds to write. |
| "Force push is fine on my own branch" | Use `--force-with-lease`. Plain `--force` will eventually destroy work. |
| "I don't need to tag releases, I just look at main" | Tags are how you say "this was the production state on date X". Without them, you cannot bisect across releases. |

## Red Flags

- Commit message that begins with "wip", "stuff", "fix", "more"
- Commit > 500 LOC delta
- Commit with mixed `feat` + `refactor` + `fix` content
- Merge commits on solo work (use `--ff-only` or rebase)
- Branches named `branch1`, `branch2`, `tmp`
- No tags despite shipping multiple versions
- `.env` committed (use `.env.example`)

## Verification

- [ ] All commits since branching from main pass CI individually
- [ ] Commit messages follow Conventional Commits
- [ ] Each commit references a task in `plan.md` or an issue
- [ ] Branch named with `feat/<name>` or `fix/<name>`
- [ ] PR opened (even for solo) with review.md and verify.md as comments or links
- [ ] Tag created if this is a release commit

## Solo-Developer Adaptation

The temptation to skip PRs and tags is highest when you're alone. The cost is years-from-now, when you need to reconstruct what was deployed when. Pay the small cost now.

## macOS Notes

```bash
# Install gh and configure once:
brew install gh
gh auth login

# Useful aliases (add to ~/.gitconfig):
[alias]
  graph = log --oneline --graph --decorate --all
  conv  = log --pretty=format:'%C(yellow)%h%Creset %s %C(cyan)%an%Creset %C(green)%ar%Creset'
  fixup = "!git commit --fixup=$(git log --oneline -20 | fzf | awk '{print $1}')"

# Show commits per feature directory:
git log --oneline -- src/auth/

# Find commit that introduced a line:
git log -S 'function refreshToken' --source --all
```

## Attribution

Adapted from `addyosmani/agent-skills` (MIT, skill `git-workflow-and-versioning`),
plus Conventional Commits (https://www.conventionalcommits.org).
