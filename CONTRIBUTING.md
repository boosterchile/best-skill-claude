# Contributing

Thanks for considering a contribution to agent-rigor.

## Philosophy

This pack practises what it preaches. Contributions go through the same cycle the pack enforces: spec → plan → build → verify → review → ship. The repository's own `.claude/` config applies.

If your change would relax discipline or add convenience at the cost of rigor, expect pushback. If it would tighten discipline without adding friction, expect a fast merge.

## Ways to contribute

### 1. Bug reports

Open an issue with:

- macOS version and architecture (`sw_vers`, `uname -m`)
- bash version (`bash --version`)
- jq version
- Output of `bash benchmark/scripts/collect-metrics.sh --self-check`
- The relevant ledger excerpt (`cat $(ls -t .claude/ledger/*.jsonl | head -1) | tail -20`)
- Reproduction steps if possible

### 2. Documentation fixes

PRs welcome. For typos, grammar, broken links — no spec needed; mention `[skip-cycle: doc fix]` in the PR description.

### 3. Skill or hook improvements

These require a spec. Process:

1. Open an issue describing the change you propose
2. Wait for "go ahead" or feedback
3. Branch, write `.specs/<change-slug>/spec.md` (use the project's own .specs directory)
4. Walk the full cycle
5. PR with the spec, plan, verify, review, and ship artifacts included

### 4. Porting to Linux

The hooks use BSD date / sed idioms (macOS default). A clean Linux port would need:

- BSD `date -u -j -f` → GNU `date -d`
- Conditional logic for both
- Test on Ubuntu LTS and Fedora

If you do this, open an issue first so we can coordinate.

### 5. New sub-agent

The pack ships five. If you have a use case for a sixth (e.g., a `database-migrator`, `accessibility-auditor` distinct from `ux-designer`), the bar is:

- The need can be articulated in a spec
- The agent has a clear non-overlapping scope vs the existing five
- The agent integrates with the ledger (records its findings)
- The benchmark metrics either accommodate it or are extended

## Style

### Markdown

- Single H1 per file
- Tables for comparisons
- Code blocks fenced with language tag
- No trailing whitespace
- Line length: soft 100, hard 120 in prose; code blocks unconstrained
- Use sentence case for headings
- Use the existing tone: declarative, dense, concrete

### Bash

- Target bash 3.2 (macOS default). No `mapfile`, no `&>`, no `local -n`, no `[[ =~ ]]` extensions that require bash 4+
- Set `set -euo pipefail` in scripts that aren't sourced
- Quote all variable expansions: `"$VAR"` not `$VAR`
- Functions: `function_name() { ... }`
- No `eval` unless you can prove it's safe and necessary

### Skills

Every SKILL.md follows the template visible in existing skills:

- Frontmatter with name, description, requires, produces, phase, adapted_from
- ## Overview
- ## When to use
- ## Process (numbered steps)
- ## Rationalizations (table of excuse → refutation)
- ## Red Flags
- ## Verification (checklist)
- ## Solo-Developer Adaptation
- ## macOS Notes
- ## Attribution

Deviation from this template needs a reason.

## Local development of agent-rigor itself

1. Clone:
   ```bash
   git clone https://github.com/boosterchile/best-skill-claude
   cd agent-rigor
   ```

2. Make hooks executable:
   ```bash
   chmod +x .claude/hooks/*.sh benchmark/scripts/*.sh
   ```

3. Self-check:
   ```bash
   bash benchmark/scripts/collect-metrics.sh --self-check
   ```

4. Make changes on a branch:
   ```bash
   git checkout -b feat/<your-change>
   ```

5. The repository has its own `.specs/` directory; track your change there:
   ```bash
   mkdir -p .specs/<your-change>
   ```

6. Walk the cycle. Use the repo's own slash commands during your Claude Code session.

7. Open a PR with the artifacts present.

## Testing changes

The pack is markdown + bash; there's no formal test runner. Validation:

- `bash benchmark/scripts/collect-metrics.sh --self-check` passes
- Hooks don't throw under normal usage
- JSON files (settings.json, marketplace.json, baseline.json) parse:
  ```bash
  jq empty .claude/settings.json
  jq empty .claude-plugin/marketplace.json
  jq empty benchmark/baseline.json
  ```
- New skills have all frontmatter fields present
- New skills are listed in `.claude-plugin/marketplace.json` components.skills

## Releases

Maintainer-only:

```bash
# After review verdict Approved:
npm version <patch|minor|major> --no-git-tag-version
# (or edit a VERSION file by hand)

# Move CHANGELOG entries from Unreleased to versioned section.

git commit -am "chore(release): vX.Y.Z"
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push --follow-tags

gh release create vX.Y.Z --generate-notes
```

## Code of conduct

Be precise. Be kind. Be willing to say "I was wrong" and to hear "you were wrong". The same discipline this pack encourages in code applies to conversations about the pack.

Disagreements about technical direction are welcome and expected. Disagreements about whether someone deserves a respectful response are not.

## Licensing

By contributing, you agree your contribution is MIT-licensed under this project's LICENSE, and that you have the right to grant that license.

## Questions

Open a discussion (not an issue) for questions that aren't bug reports. Issues are for actionable items; discussions are for "is this the right approach?" and "how would I…".
