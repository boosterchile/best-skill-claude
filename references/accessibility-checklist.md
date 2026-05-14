# Accessibility Checklist

> Used by `ux-designer` agent and skill `34-frontend-ui-engineering`. WCAG 2.2
> AA as the floor, not the ceiling. The agent should walk this for every UI
> change.

## Principle

Accessibility is not a feature for a minority. It's defensive design for **every** user under bad conditions: bright sun, broken trackpad, slow network, distracted moment, single hand, screen reader. Build for the worst case and the best case follows.

## Quick automated scan

```bash
npx -y @axe-core/cli http://localhost:3000
npx -y pa11y http://localhost:3000
npm i -D @axe-core/playwright   # use in Playwright tests
```

Automated tools catch ~30-40% of issues. The rest needs manual verification.

## Semantic HTML

- [ ] Headings: one `<h1>` per page; `<h2>`-`<h6>` in order, no skipping levels
- [ ] Landmarks: `<header>`, `<nav>`, `<main>`, `<aside>`, `<footer>` used (or `role` equivalents)
- [ ] Buttons are `<button>`, not `<div onclick>`
- [ ] Links are `<a>` with `href`, not `<span onclick>`
- [ ] Lists are `<ul>`/`<ol>`/`<dl>`
- [ ] Tables for tabular data only, with `<th scope>`
- [ ] Forms: every `<input>` has an associated `<label>`
- [ ] Images: `<img alt="…">` always — alt text describes purpose, empty `alt=""` for decorative

## Keyboard

- [ ] Every interactive element reachable via Tab
- [ ] Tab order matches visual reading order
- [ ] Visible focus indicator on every interactive element (not just default browser ring if it's removed)
- [ ] `:focus-visible` preferred over `:focus` (keyboard vs mouse distinction)
- [ ] No keyboard traps (you can always tab out)
- [ ] Enter activates links and submit buttons
- [ ] Space activates buttons and checkboxes
- [ ] Esc closes modals, popovers, dropdowns
- [ ] Arrow keys navigate within composite widgets (menus, tabs, listboxes)
- [ ] Custom keyboard shortcuts documented; not in conflict with assistive tech defaults

## Screen reader

- [ ] Page has a `<title>` that's descriptive (each page differs)
- [ ] Decorative SVG: `aria-hidden="true"` or `role="presentation"`
- [ ] Informative SVG: `<title>` child or `aria-label`
- [ ] Icon-only buttons have `aria-label`
- [ ] Live regions for dynamic updates: `aria-live="polite"` (or `assertive` for urgent)
- [ ] Errors announced via `role="alert"` or live region
- [ ] Loading states announced (not just visual spinner)
- [ ] Modal: `role="dialog"`, `aria-modal="true"`, `aria-labelledby` pointing at title
- [ ] Form errors associated via `aria-describedby`, with `aria-invalid="true"` on the field
- [ ] `aria-expanded` on disclosure triggers
- [ ] `aria-current="page"` on the active nav item

## ARIA

- [ ] No ARIA where semantic HTML suffices (the first rule of ARIA is don't use ARIA)
- [ ] When ARIA is used, roles/states/properties match the pattern (see [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/patterns/))
- [ ] Don't change semantic role with ARIA (e.g., `<button role="link">` — use the right element)
- [ ] `aria-hidden` not on focusable elements

## Color & contrast

- [ ] Body text contrast ≥ 4.5:1 against background
- [ ] Large text (≥ 24px, or ≥ 18.66px bold) contrast ≥ 3:1
- [ ] UI components (borders, focus rings, icons) contrast ≥ 3:1
- [ ] Information never conveyed by color alone (icon, text, pattern alongside color)
- [ ] Dark mode contrast also checked
- [ ] Don't rely on hue distinctions for color-blind users (use lightness)

Quick check:

```bash
# Contrast checker tools (in browser dev tools, or):
# https://webaim.org/resources/contrastchecker/
# Built into Chrome DevTools Inspector → Accessibility panel
```

## Motion & animation

- [ ] `prefers-reduced-motion` respected:
  ```css
  @media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
      animation-duration: 0.01ms !important;
      animation-iteration-count: 1 !important;
      transition-duration: 0.01ms !important;
    }
  }
  ```
- [ ] No content flashes more than 3 times per second
- [ ] Animations that move don't run > 5s without pause control
- [ ] Auto-rotating carousels have pause/stop controls

## Responsive & zoom

- [ ] Layout works at 200% zoom without horizontal scroll
- [ ] Layout works at 400% zoom (WCAG 2.1 SC 1.4.10 — reflow)
- [ ] Tested at 375 / 768 / 1024 / 1440px widths
- [ ] Touch targets ≥ 44×44 px on mobile (WCAG 2.5.5)
- [ ] No fixed `font-size` in px for body text — use `rem` so user's font-size preference is respected

## Forms

- [ ] Every input has a `<label>` (not just `placeholder`)
- [ ] Required fields marked with both visual indicator AND `aria-required="true"` / HTML `required`
- [ ] Errors:
  - Inline, near the field
  - Programmatically associated with the field (`aria-describedby`)
  - Field has `aria-invalid="true"`
  - Error message uses both text and (optionally) icon — not color alone
- [ ] Autocomplete attributes set: `autocomplete="email"`, `autocomplete="current-password"`, etc.
- [ ] Form submission doesn't require pointing precision (large click targets)
- [ ] Clear focus state shows where you are mid-form

## Multimedia

- [ ] Video: captions for spoken content
- [ ] Video: transcript available
- [ ] Audio: transcript available
- [ ] Audio doesn't autoplay
- [ ] Players have keyboard-accessible controls
- [ ] Sign-language interpretation for high-stakes content (WCAG 2.1 AAA)

## Language

- [ ] `<html lang="…">` set
- [ ] Inline language changes marked with `lang` attribute (`<span lang="es">…</span>`)
- [ ] Reading level appropriate (consider [Hemingway Editor](https://hemingwayapp.com/) for marketing pages)

## Tables

- [ ] `<th scope="col">` for column headers, `<th scope="row">` for row headers
- [ ] `<caption>` describes the table
- [ ] Complex tables: use `headers` attribute
- [ ] Layout tables: don't use `<table>`; use CSS

## Manual testing protocol

For each major user flow, before declaring done:

### Keyboard pass (5 min)
1. Refresh the page
2. Press Tab repeatedly — note where focus goes, whether it's visible
3. Try to complete the flow with keyboard only
4. Open any modal — close with Esc; focus returns to trigger?
5. Submit a form with errors — are errors visible and announced?

### Screen-reader pass (10 min)
macOS: Cmd+F5 to toggle VoiceOver.

1. Use VO+arrow keys to walk the page
2. Do landmarks make sense? (`VO+U` for landmarks)
3. Are headings useful? (`VO+U` for headings)
4. Read the form aloud — labels, errors clear?
5. Trigger a state change (loading, error) — is it announced?

### Mobile pass (5 min)
1. Touch targets reachable with thumb
2. Pinch zoom works
3. Form inputs don't get hidden by keyboard
4. Tap and hold doesn't accidentally trigger context menus on interactive elements

### Reduced motion (1 min)
1. macOS: System Settings → Accessibility → Display → Reduce motion
2. Visit the page; animations should collapse to instant or near-instant

## When to break a rule

You may deviate from a checklist item if:

- The deviation makes the experience demonstrably better for users with disabilities (rare)
- The technology doesn't support the standard yet, and a graceful fallback exists
- The item conflicts with a higher-priority WCAG SC

Document the deviation in `design-system/MASTER.md` § Accessibility commitments.

## Tools and references

- WCAG 2.2 quick reference: https://www.w3.org/WAI/WCAG22/quickref/
- WAI-ARIA Authoring Practices: https://www.w3.org/WAI/ARIA/apg/
- axe-core: https://www.deque.com/axe/
- VoiceOver (macOS): Cmd+F5
- NVDA (Windows; free): https://www.nvaccess.org/
- TalkBack (Android): Settings → Accessibility
- VoiceOver (iOS): Settings → Accessibility → VoiceOver

## macOS-local

```bash
# axe + pa11y at the command line:
npm i -g pa11y @axe-core/cli
pa11y http://localhost:3000
npx -y @axe-core/cli http://localhost:3000

# Chrome Lighthouse Accessibility audit:
npx -y lighthouse http://localhost:3000 --only-categories=accessibility --view
```
