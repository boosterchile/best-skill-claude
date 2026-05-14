# Attribution

agent-rigor is an original work that builds on prior MIT-licensed projects. This file documents what was adapted, what is original, and which upstream files each component traces to.

The agent-rigor repository is MIT-licensed (see LICENSE). Each upstream project's MIT notice and copyright are preserved below.

## Upstream projects

### addyosmani/agent-skills

- Repository: https://github.com/addyosmani/agent-skills
- License: MIT
- Reference version: 0.5.0
- Copyright (c) Addy Osmani and contributors

Adapted from this project:

- **Phase taxonomy** (Define → Plan → Build → Verify → Review → Ship)
- **Skill structure** (frontmatter conventions, SKILL.md as the unit of guidance)
- **Slash-command pattern** for triggering phases
- **The names of all 20 skills from upstream**, mapped 1:1 into agent-rigor's numbered taxonomy. agent-rigor adds two skills not present upstream: `00-using-this-pack` and `35-design-system-generation`.

### Skill-level derivation map

| agent-rigor skill | adapted_from | nature of adaptation |
|---|---|---|
| `00-using-this-pack` | conceptual analog only | new; orients the agent to agent-rigor's own hooks and ledger |
| `10-idea-refine` | `agent-skills/idea-refine` | structure preserved; added "scope test" before promotion to spec |
| `11-spec-driven-development` | `agent-skills/spec-driven-development` | 13-section template expanded; added §10 test list and §12 devils-advocate pass as mandatory |
| `20-planning-and-task-breakdown` | `agent-skills/task-decomposition` | added 100 LOC ceiling per task and rollback-plan-per-task requirement |
| `30-incremental-implementation` | `agent-skills/incremental-impl` | added pre-build articulation requirement and clean-tree precondition |
| `31-test-driven-development` | `agent-skills/tdd` | added [test-after: <reason>] waiver protocol; clock/random injection patterns |
| `32-context-engineering` | `agent-skills/context-eng` | added explicit "context budget" framing and refresh triggers |
| `33-source-driven-development` | `agent-skills/source-reading` | added "read N callsites" baseline before modification |
| `34-frontend-ui-engineering` | `agent-skills/frontend-eng` | bridges to skill 35; references accessibility-checklist |
| `35-design-system-generation` | `nextlevelbuilder/ui-ux-pro-max-skill` v2.5.0 | substantial rewrite; eliminated Python search.py dependency; MASTER + pages pattern preserved |
| `36-api-and-interface-design` | `agent-skills/api-design` | versioning and deprecation discipline expanded |
| `40-browser-testing-with-devtools` | `agent-skills/browser-testing` | macOS-specific tooling (Cmd+Opt+I, fswatch) |
| `41-debugging-and-error-recovery` | `agent-skills/debugging` | added structured pre-debug articulation |
| `50-code-review-and-quality` | `agent-skills/code-review` | five-axis framework explicit; cooling-off as hook-enforced |
| `51-code-simplification` | `agent-skills/simplification` | one-refactor-per-commit rule |
| `52-security-and-hardening` | `agent-skills/security` | OWASP Top 10 walkthrough; references security-checklist |
| `53-performance-optimization` | `agent-skills/performance` | measure-first protocol; budgets in spec §6 |
| `60-git-workflow-and-versioning` | `agent-skills/git-workflow` | Conventional Commits + PR-against-self for solo developers |
| `61-ci-cd-and-automation` | `agent-skills/cicd` | macOS runners, fswatch local CI |
| `62-deprecation-and-migration` | `agent-skills/deprecation` | grace-period and removal-commit protocol |
| `63-documentation-and-adrs` | `agent-skills/docs-adrs` | Diátaxis taxonomy + Nygard ADR template |
| `64-shipping-and-launch` | `agent-skills/shipping` | 12-point checklist; rollback rehearsal mandatory for irreversibles |

### nextlevelbuilder/ui-ux-pro-max-skill

- Repository: https://github.com/nextlevelbuilder/ui-ux-pro-max-skill
- License: MIT
- Reference version: 2.5.0
- Copyright (c) nextlevelbuilder and contributors

Adapted from this project:

- The **MASTER + page-override** pattern (lives in `skills/35-design-system-generation/SKILL.md` and `references/ui-ux-checklist.md`)
- The **product-class → pattern/style/color/typography mapping table** (compressed and embedded in skill 35; the upstream's 161 industry rules are condensed to 11 categories with extension guidance)
- The **anti-pattern emphasis** (every MASTER.md includes an explicit "what this product is not" section)

What is NOT adapted:

- The Python `search.py` runtime is **deliberately omitted**. agent-rigor's design principle is zero non-essential runtime dependencies, and the reasoning is moved into the SKILL.md tables so the agent applies it directly. This is a behavioural change from the upstream and the reason a clean rewrite was necessary rather than a fork.

## Other references

- **Michael Nygard, "Documenting Architecture Decisions" (2011)** — the ADR format used in `skills/63-documentation-and-adrs/SKILL.md` and `docs/adr/` directory expectation. Public-domain article.
- **Diátaxis** (https://diataxis.fr, CC BY-SA 4.0) — the four-mode documentation taxonomy (tutorials / how-tos / reference / explanation) referenced in skill 63.
- **Keep a Changelog** (https://keepachangelog.com, CC BY 4.0) — the CHANGELOG.md format used in skill 64 and skill 60.
- **Conventional Commits** (https://www.conventionalcommits.org, CC BY 3.0) — commit message format in skill 60.

## Original to agent-rigor

The following components have no upstream and are wholly original to this project:

- **The five hooks** (`.claude/hooks/*.sh`) — design, semantics, and the ledger contract
- **The session ledger format** (JSONL with `pre_build_articulation`, `phase_exit`, `drift_detected`, `drift_justified`, `artifact_produced`, etc.)
- **The five sub-agents in their current form**:
  - `devils-advocate` — seven-axis attack protocol
  - `code-reviewer` — five-axis findings format
  - `test-engineer` — test-list drafting + quality eval with tags
  - `security-auditor` — eight-category walkthrough format
  - `ux-designer` — three-mode operation (MASTER gen / page override / pre-delivery)
- **The 10 benchmark metrics** in `benchmark/baseline.json` and the comparison scripts
- **The cooling-off enforcement** as a hook with explicit waiver protocol
- **The drift vocabulary list** and `drift_justified` ledger pattern
- **The `[skip-cycle: <reason>]` and `[waiver: <reason>]` markers** as user-facing escape valves
- **The macOS-first orientation** throughout (bash 3.2 compatibility, BSD utilities, osascript notifications, fswatch)
- **The CLAUDE.md contract structure** (12 sections with prohibited vocabulary and senior-engineering rules)
- **All `docs/*.md` content** (getting-started, anti-drift, solo-developer, macos-setup, benchmark)
- **All `references/*.md` content** as currently written

## License notice replication

### MIT License (addyosmani/agent-skills)

```
MIT License

Copyright (c) addyosmani/agent-skills contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### MIT License (nextlevelbuilder/ui-ux-pro-max-skill)

```
MIT License

Copyright (c) nextlevelbuilder/ui-ux-pro-max-skill contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Concerns about derivation

If you are a maintainer of either upstream project and believe any part of agent-rigor exceeds fair-use derivation under MIT terms, please open an issue at https://github.com/boosterchile/best-skill-claude/issues. The intent of this file is to document derivation honestly; corrections are welcome.
