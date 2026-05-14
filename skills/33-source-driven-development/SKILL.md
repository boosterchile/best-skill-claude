---
name: source-driven-development
description: Work effectively in code you did not write. Use when the project has substantial existing code, when handed a legacy codebase, or when modifying a module whose author has left. Establishes "read before write" discipline and convention discovery.
requires: nothing
produces: convention map + change in unfamiliar code that respects local style
phase: cross-cutting
adapted_from: addyosmani/agent-skills (MIT)
---

# Source-Driven Development

> The code in the repo is the spec, until proven otherwise. The change you want to make may already be expressed (badly) somewhere; the convention you want to invent may already exist.

## When to use

- New project or new area within a project
- Refactor in a module you didn't write
- Bug fix in a module not modified for > 6 months
- Anytime the agent suggests a name or pattern and you have a nagging feeling "that doesn't match what's nearby"

## Process

### Step 1 — Surface scan

Before any change, run:

```bash
# Module overview
fd '\.(ts|tsx|js|jsx|py|rs|go)$' src/<area> -t f | head -30

# Recent activity
git log --since="3 months ago" --oneline -- src/<area> | head -10

# Convention markers
ls -la | grep -E '\.(lint|prettier|editorconfig|tsconfig|pyproject)'
```

This takes < 1 minute. Skipping it costs hours.

### Step 2 — Read 3 sibling modules

Pick **three existing modules** in the same area as your change. Read them. Extract:

- File header / license / preamble convention
- Imports order, style
- Naming: types, functions, files, tests
- Error handling: exceptions / Result / errors-as-values
- Documentation style: docstrings, JSDoc, none
- Test location: co-located, parallel tree, separate dir
- Side-effect patterns: dependency injection, globals, modules-with-state

### Step 3 — Write the convention map

For the duration of your work, keep a small note:

```markdown
# Conventions in src/<area>

## Files
- `kebab-case.ts` for modules, `PascalCase.tsx` for React components
- Tests `kebab-case.test.ts` co-located

## Style
- Default export = primary subject of the file
- Named exports = supporting types/utilities

## Errors
- `Result<T, AppError>` everywhere; never throw across module boundary

## Tests
- `describe(module, () => { it('does X when Y', ...) })`
```

This belongs in your scratch notes or `.specs/<feature>/conventions.md`. It can be deleted when the work is done.

### Step 4 — Honour the convention

When writing new code in this area, **match the conventions**. If you disagree, either:

- Convince yourself this isn't the place to fight that battle, and conform
- Decide to deliberately deviate, document with an ADR (`63-documentation-and-adrs`), and update the convention map

Both are acceptable. What's not acceptable is silent deviation.

### Step 5 — Read before write, every time

For every file you're about to modify in unfamiliar code:

1. Read the file
2. Read its tests
3. Read at least one direct caller (`grep -r 'fnName' src/`)
4. Then write

The 30 seconds you save by skipping these steps gets refunded as 30 minutes of debugging.

### Step 6 — Comment intent only when non-obvious

In unfamiliar code, you'll be tempted to add explanatory comments. Resist unless:

- The behaviour is genuinely non-obvious (Hyrum's Law dependents, undocumented protocol quirk)
- The change is risky and you want to flag it for future readers
- You uncovered a workaround whose reason isn't in the diff

Otherwise: let the code speak. Comments rot; code is type-checked.

## Rationalizations

| Rationalization | Refutation |
|---|---|
| "The existing code is bad; my new code should be better" | Then file an ADR proposing the new style and apply it system-wide, not in one corner. Local "better" creates inconsistency. |
| "I don't have time to read three modules" | You don't have time to write code that breaks because you missed a convention. |
| "The author isn't here, so the convention isn't enforced" | The author isn't here. The CI is, and other future maintainers are. Convention enforces itself via the next reader. |
| "It's just a one-line change" | One-line changes are how style drifts. Even a one-liner uses _some_ convention; pick the local one. |

## Red Flags

- New file in an area, none of the sibling conventions followed
- New function with an idiomatic name from a different stack ("getUser" in a Pythonic codebase, "get_user" in a TypeScript one)
- Re-introduction of a pattern the codebase explicitly removed (check `git log` for negative signal)
- Comments justifying why your code is different from neighbours

## Verification

- [ ] At least 3 sibling modules read before the first edit in unfamiliar area
- [ ] Convention notes captured (mental, scratch, or `conventions.md`)
- [ ] New code matches sibling conventions or deviation is documented (ADR or `.specs/<feature>/conventions.md`)
- [ ] At least one caller of any modified function read before editing

## Solo-Developer Adaptation

When you're the only contributor and revisit a project after months, you _are_ the legacy author. Treat your own old code as unfamiliar. The same six steps apply.

## macOS Notes

Useful exploration combos:

```bash
# All callers of a function:
rg 'authenticateUser\(' src/

# Cohort of files modified together (heuristic for "logical module"):
git log --pretty=format: --name-only --since="6 months ago" -- src/auth | sort | uniq -c | sort -rn | head -20

# Author distribution:
git shortlog -s -n -- src/auth
```

## Attribution

Adapted from `addyosmani/agent-skills` (MIT, skill `source-driven-development`).
