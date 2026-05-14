---
name: deprecation-and-migration
description: Retire a public surface (API endpoint, library export, CLI command, schema field, event) without breaking consumers. Use when /spec proposes removing or breaking an existing interface. Defines the deprecation timeline, migration guide, telemetry, and the moment it is safe to delete.
requires:
  - .specs/<feature>/spec.md describing the deprecation
  - The interface to be deprecated is documented somewhere
produces:
  - docs/migrations/NNNN-<surface>.md
  - Code annotated as @deprecated with replacement pointer
  - Telemetry to count remaining callers
phase: build / ship
adapted_from: addyosmani/agent-skills (MIT)
---

# Deprecation and Migration

> The only safe deletion is the one with zero callers. Until then, "delete" means "break someone".

## The phases

```
ANNOUNCE → REPLACE → WARN → MEASURE → REMOVE
```

Each phase has a duration. Skipping or compressing phases is how you break consumers and erode trust.

## When to use

Any time the spec proposes:

- Removing a public function, class, or module
- Removing a HTTP endpoint, GraphQL field, gRPC method
- Removing a CLI command or flag
- Changing the type, name, or semantics of any public surface
- Replacing a public surface with another

Internal-only refactor with no public surface change? Use `51-code-simplification` instead.

## Process

### Step 1 — Identify what's being deprecated

Be precise:

- ❌ "Cleaning up the auth module"
- ✅ "Removing `POST /v1/login` (replaced by `POST /v2/auth/sessions`)"

Each deprecated surface gets one migration document.

### Step 2 — Identify consumers

Who calls this surface? For each consumer class:

- **Internal (you)**: count callers via `grep`, `rg`, language-specific tools
- **First-party clients** (your mobile app, your web app): version they're on, release cadence
- **Third-party / public**: if applicable, who they are and how to reach them

The migration document lists each class with the migration path.

### Step 3 — Author the replacement

The replacement must exist and be at least as capable before you start deprecation. Anti-pattern: deprecating the old without shipping the new.

### Step 4 — Write the migration guide

`docs/migrations/NNNN-<surface>.md`:

```markdown
# Migration NNNN: <surface>

- Announced: <ISO>
- Replacement available since: <ISO / version>
- Deprecation warnings start: <ISO / version>
- Removal: <ISO / version, no earlier than 6 months after warnings>

## What's changing
<one-paragraph summary>

## Why
<brief reasoning>

## Before
<code example using the old surface>

## After
<code example using the replacement>

## Mapping
<table of old field/argument/error → new field/argument/error>

## Behaviour differences
<things the replacement does differently from the old, even if intended as equivalent>

## How to verify your migration
<test patterns, dry-run commands, observability signals>

## Timeline

| Date       | Event |
|------------|-------|
| YYYY-MM-DD | Replacement shipped |
| YYYY-MM-DD | Old surface marked @deprecated |
| YYYY-MM-DD | Telemetry-only — usage tracked |
| YYYY-MM-DD | Hard warning in logs |
| YYYY-MM-DD | Removed — version vN.0.0 |
```

### Step 5 — Annotate the old surface

Mark `@deprecated` in code:

```typescript
/**
 * @deprecated since v0.8.0; use `authenticate(...)` instead.
 *             See docs/migrations/0004-auth-session.md
 *             Removed in v1.0.0.
 */
export function login(...) { ... }
```

For HTTP:

```yaml
paths:
  /v1/login:
    post:
      deprecated: true
      summary: "DEPRECATED. Use POST /v2/auth/sessions. Removed v1.0."
      x-replaced-by: '/v2/auth/sessions'
```

For CLI:

```
$ mycli login
warning: `login` is deprecated; use `mycli auth signin`. See docs/migrations/...
```

### Step 6 — Instrument

Count remaining callers via telemetry:

```typescript
function login(...) {
  recordDeprecated('login', { caller: req.headers['user-agent'], at: Date.now() });
  // ... existing behaviour
}
```

Tag the metric with as much context as possible to identify the source.

### Step 7 — Wait

The wait period is the **deprecation window**. Minimum 2 release cycles for internal, 6 months for public, 12 months for security-sensitive surfaces. Faster than this guarantees breakage.

Use the time to:

- Migrate your own first-party callers
- Reach out to identified third-party callers
- Watch telemetry drop

### Step 8 — Decision to remove

Remove only when:

- [ ] Migration document published
- [ ] Replacement available for at least the deprecation window
- [ ] Telemetry shows < 1% of pre-deprecation usage (or your defined threshold)
- [ ] Affected consumers contacted (if reachable)
- [ ] Removal communicated in changelog / release notes
- [ ] Hard timeline in the migration doc has passed

If telemetry still shows meaningful usage, **do not remove**. Extend the window. The deprecation succeeded only when usage is near zero.

### Step 9 — Remove

In a single commit:

- Delete the deprecated code
- Delete its tests (keep one regression-of-absence test if applicable)
- Update changelog and release notes
- Bump SemVer major (if SemVer) or note as breaking in CalVer
- Update the migration document with the actual removal date

### Step 10 — Devils-advocate before /ship

Removal commits get an extra devils-advocate pass. Common objections:

- "Telemetry undercounts callers in environments that don't report"
- "The replacement has edge case X that the old surface handled"
- "The removal coincides with another breaking change — too much for one release"

## Rationalizations

| Rationalization | Refutation |
|---|---|
| "Nobody uses it; I just checked" | "Just checked" means `grep` your repo. Production telemetry is the real check. |
| "We can move fast and break things" | Until the things you break include trust. Trust is months to rebuild. |
| "Two weeks is enough warning" | Two weeks doesn't pass through most release cycles. The first you hear of breakage is from the user, not from telemetry. |
| "I'll keep both forever, no harm done" | Duplicate surfaces double the test matrix, double the docs, and create choice ambiguity. Remove eventually. |
| "Internal API doesn't need migration discipline" | Internal teams are users too. They expect the same predictability. |

## Red Flags

- Deletion commit not preceded by deprecation period
- `@deprecated` annotation without a replacement pointer
- Migration doc without a removal date
- Removal while telemetry still shows usage
- Multiple breaking changes batched in one release ("v2.0 changes auth, billing, and webhooks") — split into separate releases
- Deprecation period < 30 days for anything public

## Verification

- [ ] Migration document published and linked from changelog
- [ ] Replacement exists and is at parity (or documented as not-at-parity with rationale)
- [ ] `@deprecated` annotations point to migration doc
- [ ] Telemetry counting remaining usage
- [ ] Wait period elapsed
- [ ] Telemetry below threshold for removal
- [ ] Removal in a single, clear commit with bumped version
- [ ] Devils-advocate pass on removal

## Solo-Developer Adaptation

Solo, you control all the callers. The temptation to skip the deprecation period is enormous: "I know who calls it — me — and I'll update everything in one commit."

The discipline is to still do the dance, because:

- You probably have callers you forgot (an old script, a CI step, an integration)
- The act of doing it teaches the muscle for when you do have other consumers
- The migration document is for future-you, who will not remember why the old surface existed

Compressed timeline for solo internal-only: minimum 7 days between announce and remove, with telemetry actually shipped.

## macOS Notes

```bash
# Find callers in your repo:
rg 'oldFunctionName\(' --type-add 'src:*.{ts,tsx,js,jsx}' -t src

# Find callers across git history (signal: was once heavily used):
git log -p -S 'oldFunctionName' | head -200

# Telemetry tail (if logging locally):
tail -F /usr/local/var/log/myapp.log | grep 'deprecated:'
```

## Attribution

Adapted from `addyosmani/agent-skills` (MIT, skill `deprecation-and-migration`).
