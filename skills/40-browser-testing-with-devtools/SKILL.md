---
name: browser-testing-with-devtools
description: Verify UI changes work in real browsers — visual, interaction, accessibility, performance. Use after UI implementation, before /review. Covers Playwright/Cypress for automation, devtools for manual investigation, axe-core for accessibility, Lighthouse for performance.
requires:
  - UI implementation exists for the feature
produces:
  - Test results in .specs/<feature>/verify.md
  - Screenshots at standard breakpoints
phase: verify
adapted_from: addyosmani/agent-skills (MIT)
---

# Browser Testing with DevTools

## Process

### Step 1 — Define what to test

From spec §3 (success criteria) and §4 (user-visible behaviour), enumerate user-observable behaviours. Each becomes a test.

### Step 2 — Pick the right level

| Level | When | Example |
|---|---|---|
| **Unit** | Pure logic, reducers, validators | `validateEmail('x@y.z')` returns true |
| **Component** | One component in isolation | `<TokenInput onChange>` calls callback with each keystroke |
| **Interaction** | Multiple components, no network | Filling and submitting a form updates state |
| **End-to-end** | Full stack including network | Logging in and reaching the dashboard |

Don't substitute E2E for unit. They are slower, flakier, and worse at locating bugs. Use the lowest level that captures the behaviour.

### Step 3 — Automate with Playwright (preferred) or Cypress

Playwright is recommended for new projects: faster, better trace viewer, multi-browser by default.

```typescript
import { test, expect } from '@playwright/test';

test('refresh token flow keeps user signed in', async ({ page, context }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill('user@example.com');
  await page.getByLabel('Password').fill('hunter2');
  await page.getByRole('button', { name: /sign in/i }).click();

  await expect(page).toHaveURL('/dashboard');
  // Simulate 1h passing (access-token TTL):
  await context.addCookies([{ name: 'access', value: 'expired', ... }]);

  await page.reload();
  // Should silently refresh and stay on /dashboard:
  await expect(page).toHaveURL('/dashboard');
  await expect(page.getByText(/welcome/i)).toBeVisible();
});
```

### Step 4 — Accessibility automated check

```bash
# Add to test suite:
npx -y @axe-core/playwright

# Or per-test:
import AxeBuilder from '@axe-core/playwright';
const results = await new AxeBuilder({ page }).analyze();
expect(results.violations).toEqual([]);
```

axe-core catches ~30-40% of WCAG issues. The rest needs manual verification (keyboard, screen reader).

### Step 5 — Manual keyboard pass

For every interactive flow:

1. Tab through the page. Focus visible at every step?
2. Activate buttons with Enter and Space. Both work?
3. Modal: open with click, close with Esc. Focus returns to trigger?
4. Forms: every input reachable, errors announced?

Document any failure in `.specs/<feature>/verify.md`.

### Step 6 — Screen reader pass (sample)

macOS: Cmd+F5 to toggle VoiceOver. Walk through the critical flow.

Don't skip this because "axe passed". axe catches structural issues; the real test is whether the flow is _comprehensible_ when listened to.

### Step 7 — Performance with Lighthouse

```bash
npm run build && npm run start &
sleep 2
npx -y lighthouse http://localhost:3000/<page> \
  --view --preset=desktop --output html --output-path .specs/<feature>/lighthouse-desktop.html
npx -y lighthouse http://localhost:3000/<page> \
  --view --preset=mobile --output html --output-path .specs/<feature>/lighthouse-mobile.html
```

Targets:

- LCP < 2.5s
- CLS = 0
- INP < 200ms
- Total blocking time < 200ms

If any miss, see `53-performance-optimization`.

### Step 8 — Screenshot the breakpoints

```typescript
test('responsive screenshots', async ({ page }) => {
  for (const w of [375, 768, 1024, 1440]) {
    await page.setViewportSize({ width: w, height: 900 });
    await page.goto('/<page>');
    await page.screenshot({ path: `.specs/<feature>/screenshots/${w}.png`, fullPage: true });
  }
});
```

### Step 9 — Write verify.md

```markdown
# Verify: <feature>

## Automated tests
- Unit:        15/15 passed
- Component:    8/8 passed
- E2E:          3/3 passed
- Accessibility (axe): 0 violations

## Manual checks
- [x] Keyboard navigation: tab order correct, focus visible at every step
- [x] Screen reader: forms read with labels, errors announced
- [x] Reduced motion: animations collapse to instant transitions

## Performance (Lighthouse)
- Desktop: LCP 1.2s, CLS 0, INP 80ms — green
- Mobile:  LCP 2.1s, CLS 0, INP 140ms — green

## Screenshots
- 375px:  ./screenshots/375.png
- 768px:  ./screenshots/768.png
- 1024px: ./screenshots/1024.png
- 1440px: ./screenshots/1440.png
```

## Rationalizations

| Rationalization | Refutation |
|---|---|
| "Tests pass locally, ship it" | Local environment differs from production: latency, fonts, third-party scripts. Run against a staging build. |
| "Lighthouse is too strict for our app" | If you can't justify each failure, you can't justify shipping. Each red item needs an explicit decision. |
| "Manual keyboard testing is tedious" | Three minutes per page. Multiply by zero users-with-disabilities you didn't lose, and it's the highest-ROI testing you do. |

## Red Flags

- Tests that pass without exercising the change (assertions are too weak)
- Lighthouse skipped because "perf isn't a priority"
- Accessibility skipped because "we don't have screen-reader users" (you don't know who you don't have)
- Screenshots only at 1440 (the most generous resolution)
- E2E used to test pure logic that should be a unit test

## Verification

- [ ] Test results in `.specs/<feature>/verify.md`
- [ ] All four breakpoints screenshotted
- [ ] axe-core: zero violations or each documented as waiver
- [ ] Lighthouse desktop + mobile reports saved
- [ ] Manual keyboard + screen-reader checklist completed

## Solo-Developer Adaptation

Devote one session per feature explicitly to verify. Trying to verify while you're still coding leads to skipping the awkward checks (screen reader, mobile breakpoint). Make it a discrete activity.

## macOS Notes

```bash
# Quick local Playwright trace viewer:
npx playwright show-trace .specs/<feature>/trace.zip

# Image diff for screenshot regression:
# (or use Playwright's built-in toHaveScreenshot)
brew install imagemagick
compare -metric AE old.png new.png diff.png

# Throttle CPU/network for realistic mobile testing in Chrome:
# Chrome DevTools → Performance tab → "CPU: 4× slowdown" + "Network: Fast 3G"
```

## Attribution

Adapted from `addyosmani/agent-skills` (MIT, skill `browser-testing-with-devtools`).
