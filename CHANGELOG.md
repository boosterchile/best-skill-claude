# Changelog

All notable changes to agent-rigor are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning: [SemVer](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-13

### Added

- **Initial release.**
- 22 skills covering the full engineering cycle:
  - Define: `10-idea-refine`, `11-spec-driven-development`
  - Plan: `20-planning-and-task-breakdown`
  - Build: `30-incremental-implementation`, `31-test-driven-development`, `32-context-engineering`, `33-source-driven-development`, `34-frontend-ui-engineering`, `35-design-system-generation`, `36-api-and-interface-design`
  - Verify: `40-browser-testing-with-devtools`, `41-debugging-and-error-recovery`
  - Review: `50-code-review-and-quality`, `51-code-simplification`, `52-security-and-hardening`, `53-performance-optimization`
  - Ship: `60-git-workflow-and-versioning`, `61-ci-cd-and-automation`, `62-deprecation-and-migration`, `63-documentation-and-adrs`, `64-shipping-and-launch`
  - Orientation: `00-using-this-pack`
- 5 hooks providing active enforcement:
  - `session-start.sh`, `user-prompt-submit.sh`, `pre-tool-use.sh`, `post-tool-use.sh`, `stop.sh`
- 5 sub-agents:
  - `devils-advocate` (mandatory adversarial pass)
  - `code-reviewer` (five-axis review)
  - `test-engineer` (test list and quality)
  - `security-auditor` (OWASP + threat-model)
  - `ux-designer` (MASTER + page overrides + pre-delivery)
- 9 slash commands aligned to phases plus `/design`, `/code-simplify`, `/benchmark`
- Session ledger format (`.claude/ledger/*.jsonl`) with structured event types
- Benchmark suite with 10 metrics, baseline.json, and three scripts (collect / score / compare)
- 7 reference documents (solo-developer-patterns, macos-environment, ui-ux-checklist, testing-patterns, security-checklist, performance-checklist, accessibility-checklist)
- 5 user-facing docs (getting-started, anti-drift, solo-developer, macos-setup, benchmark)
- `[skip-cycle: <reason>]` and `[waiver: <reason>]` escape valves with usage tracking
- macOS-first design with bash 3.2 compatibility
- `.claude-plugin/marketplace.json` for Claude Code plugin discovery
- Attribution to upstream MIT projects (addyosmani/agent-skills, nextlevelbuilder/ui-ux-pro-max-skill) in ATTRIBUTION.md

[Unreleased]: https://github.com/boosterchile/best-skill-claude/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/boosterchile/best-skill-claude/releases/tag/v0.1.0
