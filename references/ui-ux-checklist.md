# UI/UX Pre-Delivery Checklist

> Apply this before claiming any UI work is `done`. Every box must be checked or have a documented waiver in the spec's §5 (Out of scope) or §9 (Risks).

Adapted and expanded from `nextlevelbuilder/ui-ux-pro-max-skill` (MIT) plus WCAG 2.1 AA requirements and platform-specific notes.

## A. Visual / aesthetic

- [ ] Design tokens used everywhere (`var(--color-...)`, `var(--space-...)`, `var(--text-...)`). No hex literals or raw px values in component code.
- [ ] Page reads against `design-system/MASTER.md` and any matching `design-system/pages/<page>.md` override.
- [ ] No emojis used as functional icons. SVG (Heroicons / Lucide / custom) only.
- [ ] No stock photography that signals "we are a generic SaaS template".
- [ ] Anti-patterns listed in MASTER §11 are absent (verify each).

## B. Interaction

- [ ] Every clickable element has `cursor: pointer` (or appropriate cursor for the action).
- [ ] Every clickable element has a hover state with transition between `--motion-fast` and `--motion-base`.
- [ ] Every interactive element has an active/pressed state distinguishable from hover.
- [ ] Disabled states are visually distinct and do not look interactable.
- [ ] Loading states present for any action taking >200ms (skeleton, spinner, or progress).
- [ ] Error states present with actionable copy ("Retry" / "Try a different file" not just "Error").
- [ ] Empty states present and informative ("No results yet — try X" not just an empty container).
- [ ] Destructive actions confirmed (delete, discard, archive) with explicit copy ("Delete 12 items?" not "Are you sure?").

## C. Accessibility (WCAG 2.1 AA)

### Contrast
- [ ] Body text ≥ 4.5:1 against background.
- [ ] Large text (≥ 18pt or ≥ 14pt bold) ≥ 3:1.
- [ ] Non-text UI (borders, icons) ≥ 3:1.
- [ ] Focus indicators ≥ 3:1 against adjacent colors.

### Keyboard
- [ ] All functionality reachable via keyboard (Tab, Shift+Tab, Enter, Space, Esc, arrows).
- [ ] Focus order is logical (visual order = DOM order).
- [ ] Focus indicators visible. `outline: none` only acceptable when replaced with an equally visible alternative (ring, custom outline).
- [ ] Skip-to-content link on pages with persistent navigation.
- [ ] Modal/dialog: focus trapped while open, returns to trigger on close, Esc closes.

### Screen reader
- [ ] Semantic HTML used (`<button>`, `<nav>`, `<main>`, `<article>`, not `<div>` everywhere).
- [ ] Icons-only buttons have `aria-label`.
- [ ] Images have `alt` text (or `alt=""` if decorative).
- [ ] Form inputs have associated `<label>` (not placeholder-only).
- [ ] Dynamic content changes announced (`aria-live="polite"` for status, `aria-live="assertive"` for errors).
- [ ] Landmark roles do not duplicate native semantics (don't add `role="navigation"` to `<nav>`).

### Motion
- [ ] `prefers-reduced-motion: reduce` respected. All non-essential animations collapse to instantaneous or fade-only.
- [ ] No motion that could trigger vestibular disorders (parallax, large-scale zoom) without opt-out.
- [ ] No flashing > 3 times per second.

### Forms
- [ ] Labels present, visible, and clickable (focus the input).
- [ ] Error messages identify the field and the fix.
- [ ] Required fields indicated programmatically (`required` attribute) AND visually.
- [ ] Autocomplete attributes set where applicable (`autocomplete="email"`, `autocomplete="new-password"`, etc.).
- [ ] Inputs sized to fit expected content (don't show a 4-char zip-code field as a `width: 100%`).

## D. Responsive

- [ ] Verified at 375px width (smallest target).
- [ ] Verified at 768px width.
- [ ] Verified at 1024px width.
- [ ] Verified at 1440px width.
- [ ] No horizontal scroll at any breakpoint (unless explicitly opt-in like a data table).
- [ ] Touch targets ≥ 44×44px on mobile/tablet.
- [ ] Tap-spacing: adjacent touch targets have ≥ 8px gap.
- [ ] Text size ≥ 16px on mobile inputs (prevents iOS auto-zoom).

## E. Performance

- [ ] LCP < 2.5s on the page's primary content.
- [ ] CLS = 0 (no layout shift after initial paint).
- [ ] INP / FID < 200ms.
- [ ] Images have explicit `width` and `height` attributes (prevents CLS).
- [ ] Images optimized: WebP/AVIF with fallback, appropriate sizes via `srcset`.
- [ ] Above-the-fold critical CSS inlined or top of bundle.
- [ ] No render-blocking third-party scripts in the critical path.
- [ ] Fonts loaded with `font-display: swap` and `<link rel="preload">` for hero fonts.

Verify with Lighthouse in incognito on a throttled 4G connection — not on your dev machine.

## F. Internationalization (if applicable)

- [ ] Strings extracted to translation files, not hard-coded.
- [ ] Date/time/number formats use `Intl.*` APIs, not manual formatting.
- [ ] Text containers tolerate ~30% expansion (German-length).
- [ ] RTL layout works if any target language uses it (`dir="rtl"`).
- [ ] Plural rules handled via `Intl.PluralRules`, not manual `if (n === 1)`.

## G. Browser / device coverage

- [ ] Safari (macOS latest + previous major)
- [ ] Safari iOS (latest)
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Edge if your audience uses it
- [ ] Reduced-motion mode (System Settings → Accessibility on macOS)
- [ ] Dark mode (if the design supports it; if it doesn't, ensure it's _explicitly_ disabled in CSS)

## H. Content

- [ ] Copy reviewed for tone alignment with MASTER §1 (Product context).
- [ ] No placeholder Lorem Ipsum left anywhere.
- [ ] No "test" or "TODO" copy.
- [ ] Spelling and grammar — run a checker.
- [ ] Numbers / data / claims are accurate. Anything quoted from a source is correctly attributed.
- [ ] Legal copy (terms, privacy, cookies) present where required.

## I. Edge cases

- [ ] Long content does not break layout (try a 200-character heading).
- [ ] Zero content does not show "(undefined)" or "null".
- [ ] Network failure: offline mode or clear error.
- [ ] Slow network: see "loading states" in B above.
- [ ] Authentication expired mid-session: graceful redirect or in-place re-auth.
- [ ] Permission denied: clear copy explaining what permission is needed and how to grant it.

## J. Telemetry / observability

- [ ] Key user actions instrumented (without tracking PII unless consented).
- [ ] Errors caught and reported (Sentry or equivalent).
- [ ] Performance metrics (Core Web Vitals) reported in production.
- [ ] User can opt out of telemetry where required by law (GDPR, CCPA).

## K. Final hand-off

- [ ] Spec §3 (Success criteria) — every box checked.
- [ ] Devils-advocate review on the implementation completed and saved to `.specs/<feature>/review.md`.
- [ ] Pre-delivery checklist (this file) saved alongside (`.specs/<feature>/ui-checklist.md`) with check marks and any waivers documented inline.
- [ ] Cross-references in MASTER §14 (Decision log) updated if the work caused token changes.
- [ ] Ledger has `artifact_produced` events of `kind: ui-checklist`.

---

## Waivers

A box can remain unchecked only if documented as a waiver. Waiver format:

```markdown
- [ ] <criterion> — WAIVER: <reason> · review-by: <YYYY-MM-DD>
```

The review-by date is the deadline for revisiting. If it passes without action, the benchmark flags it.

## Quick verification commands (macOS)

```bash
# Lighthouse CI (one-shot run):
npx -y lighthouse https://localhost:3000 --view --preset=desktop

# axe-core via Playwright:
npx -y @axe-core/cli https://localhost:3000

# Color contrast in terminal:
python3 -m pip install --user wcag-contrast-ratio
python3 -c "from wcag_contrast_ratio import rgb; print(rgb((34,34,34),(255,255,255)))"

# Manual responsive sweep:
open -a "Safari" https://localhost:3000     # → Develop → Responsive Design Mode
```
