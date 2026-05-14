---
name: frontend-ui-engineering
description: Implement UI components and pages that respect the design-system tokens, pass the pre-delivery checklist, and don't drift from spec. Use whenever the work touches HTML/CSS/JSX/Vue/Svelte/SwiftUI/Compose or any visual component. Always run after /design (or after confirming design-system/MASTER.md exists).
requires:
  - design-system/MASTER.md exists for the project
  - .specs/<feature>/spec.md exists
produces:
  - UI components / pages
  - .specs/<feature>/ui-checklist.md (filled-in pre-delivery checklist)
phase: build
adapted_from: addyosmani/agent-skills (MIT) + nextlevelbuilder/ui-ux-pro-max-skill (MIT)
---

# Frontend UI Engineering

## Process

### Step 1 — Verify design system exists

```bash
test -f design-system/MASTER.md || echo "Run /design first"
```

If `MASTER.md` is absent, **stop** and run `/design`. UI without a system is decoration; you'll regret every token decision later.

### Step 2 — Check for page override

```bash
PAGE=<inferred-page-name>
test -f "design-system/pages/${PAGE}.md" && cat "design-system/pages/${PAGE}.md"
```

Page override (if it exists) wins over MASTER for that page only.

### Step 3 — Read the spec

Read `.specs/<feature>/spec.md`, especially §4 (User-visible behaviour) and §6 (Constraints).

### Step 4 — Establish the file structure

For most stacks, prefer co-location of component + test + styles when CSS-in-JS is in use; separate `<Component>.tsx`, `<Component>.test.tsx`, and `<Component>.module.css` when using CSS modules.

Match the convention already in the project. See `33-source-driven-development`.

### Step 5 — Implement with tokens

**Never hardcode tokens that exist in MASTER.md.** Always:

```jsx
// ❌ Don't:
<button style={{ background: '#1f6feb', padding: '12px 24px' }}>

// ✅ Do:
<button className="bg-primary px-4 py-3">
// or with CSS vars:
<button style={{ background: 'var(--color-primary)', padding: 'var(--space-3) var(--space-6)' }}>
```

### Step 6 — Apply the pre-delivery checklist

Run through `references/ui-ux-checklist.md` before claiming done. Save the filled-in checklist as `.specs/<feature>/ui-checklist.md`. Every box checked or waiver documented.

### Step 7 — Visual verification

If the change is non-trivial visually, capture a screenshot at each breakpoint (375 / 768 / 1024 / 1440). Save to `.specs/<feature>/screenshots/` (gitignore'd if you prefer not to commit images).

### Step 8 — Ledger and handoff

```bash
LEDGER="$(cat .claude/ledger/.current)"
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"artifact_produced\",\"kind\":\"ui_checklist\",\"path\":\".specs/<feature>/ui-checklist.md\"}" >> "$LEDGER"
```

## Stack-specific notes

### React + Tailwind + shadcn/ui

- Prefer `cn()` utility (clsx + tailwind-merge) for conditional classes
- Co-locate hooks with components; promote to `hooks/` only when reused
- Server vs client components in Next.js: `"use client"` only when needed (state, effects, event handlers)

### Vue 3 + Tailwind

- Single-file components with `<script setup lang="ts">`
- Co-locate composables; promote to `composables/` when reused

### SwiftUI

- ViewModifiers for repeated styling
- `@Environment(\.colorScheme)` for dark/light
- Accessibility: `.accessibilityLabel()`, `.accessibilityHint()`, traits

### Jetpack Compose

- Theme tokens via `MaterialTheme`
- `Modifier.semantics { ... }` for accessibility

## Rationalizations

| Rationalization | Refutation |
|---|---|
| "I'll style it inline for speed, refactor later" | Inline styles become permanent. Token discipline now is cheap. |
| "Design system is overkill for this small component" | Components compose. Small inconsistent components produce a noticeably ad-hoc product. |
| "Lighthouse is too strict" | Lighthouse is a fast feedback loop. If it complains, the user with a screen reader will complain louder. |
| "Accessibility can be a separate ticket" | It can be, but the cost of retrofitting is 10× building accessibly the first time. |

## Red Flags

- Hex literals in component code that match (but don't reference) tokens
- `margin` / `padding` in pixel values
- `<div onClick>` without `role="button"` and keyboard handlers
- Components without any test
- Components rendered without verifying responsive breakpoints
- Pre-delivery checklist not filled

## Verification

- [ ] All tokens via CSS vars / Tailwind classes / framework theme; no hex or px in components
- [ ] Pre-delivery checklist (`references/ui-ux-checklist.md`) executed and saved
- [ ] Component has at least one test (unit or interaction)
- [ ] Responsive behaviour verified at 375 / 768 / 1024 / 1440
- [ ] Keyboard navigation works (tab order, Enter/Space activation)
- [ ] Screen-reader pass: `npx -y @axe-core/cli http://localhost:3000` returns no violations

## Solo-Developer Adaptation

Without a designer to push back, you're the one enforcing token discipline. The easiest way: a lint rule that fails on hex literals in component code (`stylelint-no-magic-numbers`, custom `eslint-plugin-tailwindcss` rule, or grep in CI).

## macOS Notes

```bash
# Local Lighthouse on production build:
npm run build && npm run start &
sleep 2
npx -y lighthouse http://localhost:3000 --view --preset=desktop --output html

# Quick accessibility scan:
npx -y @axe-core/cli http://localhost:3000

# Screen reader test:
# System Settings → Accessibility → VoiceOver → Enable
# Or: Cmd+F5 to toggle
```

## Attribution

Derived from `addyosmani/agent-skills` (MIT, `frontend-ui-engineering`) plus
practices from `nextlevelbuilder/ui-ux-pro-max-skill` (MIT, pre-delivery
checklist, stack-specific guidelines).
