# Getting Started

> 10 minutes to install agent-rigor, 30 minutes to ship your first feature
> through the cycle.

## What you're installing

agent-rigor is a Claude Code skills pack with five layers:

1. **Skills** — 22 SKILL.md files the agent reads at the right phase
2. **Hooks** — enforcement scripts that block drift before it produces bad output
3. **Sub-agents** — adversarial reviewers (devils-advocate, code-reviewer, security-auditor, ux-designer, test-engineer)
4. **Slash commands** — `/spec`, `/plan`, `/build`, `/test`, `/review`, `/ship`, `/design`, `/code-simplify`, `/benchmark`
5. **Benchmark** — measures compliance; tells you whether the system is working

## Prerequisites

- **macOS** (Linux works but the hooks are tested on macOS)
- **Claude Code** installed (`brew install --cask claude` or via the official installer)
- **bash 3.2+** (macOS ships with 3.2; install 5.x via `brew install bash` if you prefer)
- **jq** (`brew install jq`) — used by hooks and benchmark
- **git 2.30+** (ships with Xcode Command Line Tools: `xcode-select --install`)
- **gh** for GitHub flow (`brew install gh && gh auth login`) — optional but recommended

Quick check:

```bash
bash --version       # ≥ 3.2
jq --version         # 1.6+
git --version        # 2.30+
gh --version         # 2.0+ (optional)
```

## Install into a new project

```bash
# 1. From your project root:
cd ~/your-project

# 2. Clone agent-rigor into a temp dir and copy what you need:
git clone https://github.com/<you>/agent-rigor /tmp/agent-rigor
cp -r /tmp/agent-rigor/.claude .
cp /tmp/agent-rigor/CLAUDE.md .
cp -r /tmp/agent-rigor/skills .
cp -r /tmp/agent-rigor/references .
cp -r /tmp/agent-rigor/benchmark .
chmod +x .claude/hooks/*.sh benchmark/scripts/*.sh

# 3. Verify install:
bash benchmark/scripts/collect-metrics.sh --self-check
```

You should see all green checks. If not, follow the hint each failed check prints.

## Install into an existing project

Same as above, but **review the merged `.claude/settings.json`**. If you already have hooks configured, you'll need to merge by hand. The agent-rigor hooks are designed to compose with others.

## First-time orientation

Open Claude Code in your project. The first message:

```
read CLAUDE.md and skills/00-using-this-pack/SKILL.md, then summarize how
the cycle works for me.
```

The agent reads, summarises, and is now oriented. The session_start hook has
created your ledger.

## Your first feature

Pick something small. A real feature, but small enough to walk the full cycle in 30-60 minutes.

```
You: I want to add a "copy to clipboard" button on the result page.

Agent: (reads CLAUDE.md and skill 11)
Agent: /spec result-copy-button
       → writes .specs/result-copy-button/spec.md
       → invokes devils-advocate
       → presents to you for approval

You: approved

Agent: /plan result-copy-button
       → writes .specs/result-copy-button/plan.md
       → presents tasks

You: approved

Agent: /build result-copy-button
       → picks T1
       → writes the failing test first
       → makes it pass, refactors
       → commits

You: continue

Agent: /build result-copy-button
       → picks T2
       → ...

Agent: /test result-copy-button
       → fills verify.md

(After 30+ min cooling-off — go get coffee.)

You: /review result-copy-button

Agent: → walks the five axes
       → invokes code-reviewer + devils-advocate + ux-designer (UI work)
       → writes review.md
       → verdict: Approved for /ship

You: /ship result-copy-button

Agent: → walks the 12-point checklist
       → bumps version, tags, releases
       → watches deploy
```

That's the full loop. The artefacts now live in `.specs/result-copy-button/` — spec, plan, verify, review, ship — and act as the permanent record of why this thing exists in the codebase.

## What to expect from the hooks

You'll occasionally hit a block message like:

```
✗ blocked: source-file write without spec in .specs/<feature>/spec.md
  if this is deliberate, include [skip-cycle: <reason>] in your next prompt
```

This is the hook doing its job. Two paths:

1. The block is right — run `/spec` first.
2. The block is wrong for this case — re-issue your prompt with `[skip-cycle: <reason>]` (e.g., `[skip-cycle: typo fix in comment]`). The benchmark will count it.

Skip-cycle is fine in moderation. The benchmark tracks the rate; if you're > 20%, the system isn't working for you and we should figure out why.

## What to read next

- `docs/anti-drift.md` — understand how the hooks and ledger conspire to keep the agent honest
- `docs/solo-developer.md` — the specific adaptations for working alone
- `docs/macos-setup.md` — macOS-specific setup detail
- `docs/benchmark.md` — how to read the scorecard
- `skills/00-using-this-pack/SKILL.md` — the agent's orientation document

## When something doesn't work

1. Re-run `bash benchmark/scripts/collect-metrics.sh --self-check` — fix what it reports.
2. Look at the most recent ledger file: `ls -t .claude/ledger/ | head -1 | xargs -I{} cat .claude/ledger/{}` — the last few lines often tell you what blocked.
3. Open an issue at https://github.com/<you>/agent-rigor/issues with the ledger excerpt and the message.

The goal is to make this useful for you. If it isn't, that's a bug to fix, not a discipline issue on your part.
