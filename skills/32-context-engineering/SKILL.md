---
name: context-engineering
description: Keep the agent's context window loaded with the right files at the right time. Use when the agent starts making suggestions inconsistent with project conventions, when responses degrade after long sessions, or when you suspect the agent is fabricating because it lacks the right files. Also use proactively at the start of complex tasks.
requires: nothing
produces: clearer agent context — a curated set of files in the working window
phase: cross-cutting
adapted_from: addyosmani/agent-skills (MIT)
---

# Context Engineering

> The agent is only as good as what's in its context window. A loaded context with the wrong files is worse than a small context with the right ones.

## When to use

- Start of any task touching unfamiliar code → load the right files first
- Mid-session, when the agent's quality drops noticeably
- When the agent suggests something inconsistent with existing conventions (it doesn't see the convention)
- When the agent starts making up function names, file paths, or API shapes
- Before invoking an expensive operation (large refactor, multi-file change) — verify the context is right

## Process

### Step 1 — Define what the agent needs to know

For the task at hand, what does the agent need? Categories:

| Category | Examples |
|---|---|
| **Contract** | CLAUDE.md, the relevant SKILL.md |
| **Spec/plan** | `.specs/<feature>/spec.md`, `plan.md` |
| **Direct dependencies** | The files the change directly touches |
| **Convention markers** | `lint.config`, `tsconfig`, `pyproject.toml`, one or two existing modules that establish patterns |
| **Tests** | Tests for the modules being changed |

Avoid:

- Entire `src/` directories (huge cost, little signal)
- Generated files (build output, lock files)
- Vendored dependencies (`node_modules/`, `vendor/`)
- Old/archived code unless directly relevant

### Step 2 — Load deliberately, not greedily

Use `Read` on specific files, not `Glob` on whole directories unless you need a tour. After loading, summarise back what you have in context. The summary itself takes a few hundred tokens; that's fine. It anchors subsequent reasoning.

### Step 3 — Prune

After a long session, context becomes stale. Files you read 50 turns ago may no longer reflect the current state of disk. Prune by:

- Re-reading any file you're about to modify
- Dropping mental references to files you no longer need
- Starting a fresh sub-agent task for unrelated branches of work

### Step 4 — Convention extraction

When entering unfamiliar code, before changing anything, **read 2-3 existing modules** of the same kind. Extract:

- Naming conventions (camelCase, snake_case, prefix patterns)
- Import organisation
- Error handling pattern (exceptions, Result types, callbacks)
- Test organisation (co-located, separate dir, naming)
- File header conventions (license, doc comments)

Reuse the patterns. Don't invent new ones unless the spec calls for it.

### Step 5 — Working context manifest (for big tasks)

For tasks with > 5 file changes, write a small manifest to the spec's `working-context.md`:

```markdown
# Working context — <feature>

## In context
- CLAUDE.md
- skills/30-incremental-implementation/SKILL.md
- src/auth/oauth.ts (touched)
- src/auth/oauth_test.ts (touched)
- src/middleware/session.ts (read; not touched, convention reference)

## Conventions extracted
- Auth modules export a default async function returning `Result<T, AuthError>`.
- Tests are co-located, name suffix `_test.ts`.
- Error types extend `AppError`.

## Out of context (deliberately)
- src/ui/* — not touching UI in this feature
- src/billing/* — independent subsystem
```

This artefact survives session boundaries.

## Rationalizations

| Rationalization | Refutation |
|---|---|
| "I'll just glob everything; the agent can find it" | Globbing dumps thousands of tokens of mostly-irrelevant code into context. The agent can't separate signal from noise. |
| "I'll read files as needed" | "As needed" mid-task means re-derivation of context every turn. Front-load. |
| "The convention will emerge from the code I write" | No — the convention is established. Either follow it or document the deviation. |
| "Smaller context is always better" | False. Too little context produces hallucinations of functions and paths. The goal is _right-sized_. |

## Red Flags

- Agent references files it hasn't read this session
- Agent invents function or class names that don't appear in the loaded files
- Suggestions that contradict naming patterns visible in adjacent code
- Long sessions (> 50 turns) without a context refresh
- Agent makes a change to a file you've never asked it to read

## Verification

- [ ] Before any non-trivial change, the spec + plan + the directly-touched files are in context
- [ ] At least one existing module of the same kind is in context (convention reference)
- [ ] No files are in context that have nothing to do with the task
- [ ] On long tasks, a `working-context.md` manifest exists

## Solo-Developer Adaptation

You are the only one driving context. The agent will not realise on its own that it's drifting. Periodically (every 30-40 turns) ask explicitly: _"Read back the list of files you have in mind for this task. Confirm what you intend to change."_ Use the answer to prune or reload.

## macOS Notes

Quick context summary from the terminal:

```bash
# What's in .specs/<feature>?
ls -1 .specs/<feature>/

# Recently modified files in working tree
git diff --name-only HEAD~5

# Files matching a pattern, but limit output
fd 'oauth' src/ -t f | head -20
```

## Attribution

Adapted from `addyosmani/agent-skills` (MIT, skill `context-engineering`).
