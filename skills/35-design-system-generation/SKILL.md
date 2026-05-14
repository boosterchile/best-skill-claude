---
name: design-system-generation
description: Generate a complete, industry-aware design system before any UI code is written. Produces design-system/MASTER.md as the global source of truth and design-system/pages/<page>.md for page-specific overrides. Use when starting any UI work, when the project lacks design-system/MASTER.md, or when introducing a new page that may deviate from the master.
requires:
  - .specs/<feature>/spec.md exists (the design system must serve a defined feature, not the other way around)
produces:
  - design-system/MASTER.md (first invocation per project)
  - design-system/pages/<page>.md (per-page invocations, only when deviating from master)
phase: build
---

# Design System Generation

## Overview

Adapted from `nextlevelbuilder/ui-ux-pro-max-skill` (MIT). The original ships a Python script (`search.py`) that ranks 161 industry rules × 67 UI styles × 161 color palettes × 57 font pairings. We replace the script with structured tables embedded in this skill, plus the agent's reasoning, so there is **zero Python dependency** and the data lives in source control alongside the rest of the pack.

The skill produces two kinds of artefacts:

- **`design-system/MASTER.md`** — the project's global source of truth. Colors, typography, spacing, motion, components, anti-patterns. Created once per project, evolved deliberately. **Always read this first before producing UI.**
- **`design-system/pages/<page>.md`** — page-specific overrides. Only created when a page genuinely deviates from the master. Contains only the deltas, not duplicates.

## When to Use

Trigger this skill when **any** of:

- The user requests UI, a component, a page, a screen, a layout, or any visual artefact
- `design-system/MASTER.md` does not yet exist for this project
- A new page is being designed and may deviate from the master (e.g., a marketing landing in a mostly-internal-tool app)
- A redesign is happening and the master needs to be updated explicitly (this requires `/spec` first — design system changes are project-level decisions)

Do **not** trigger this skill for:

- Pure refactors of existing UI that don't change visual identity
- Backend / API / infrastructure work
- Documentation that doesn't render in a UI

## Process

### Step 0 — Read the spec

If `.specs/<feature>/spec.md` doesn't exist, **stop** and tell the user to run `/spec` first. The design system serves the spec; not the other way around.

### Step 1 — Determine the product type

Identify the **product type** from the spec. Use this categorisation (adapted from `ui-ux-pro-max-skill` rules):

#### Tech & SaaS
SaaS dashboard · Micro-SaaS · B2B service · Developer tool / IDE · AI/chatbot platform · Cybersecurity platform · DevOps observability · Data platform

#### Finance
Fintech / crypto · Banking · Insurance · Personal finance tracker · Invoicing & billing · Payroll · Trading platform

#### Healthcare
Medical clinic · Pharmacy · Dental · Veterinary · Mental health · Medication reminder · Telemedicine · EHR

#### E-commerce
General storefront · Luxury · Marketplace (P2P) · Subscription box · Food delivery · Grocery · Fashion · Booking & appointment

#### Services
Beauty / spa · Restaurant · Hotel · Legal · Home services · Real estate · Travel agency

#### Creative
Portfolio · Agency · Photography · Gaming · Music streaming · Photo/video editor · Design tool · Streaming platform

#### Lifestyle & utility
Habit tracker · Recipe & cooking · Meditation · Weather · Diary / journaling · Mood tracker · Fitness · Sleep

#### Emerging tech
Web3 / NFT · Spatial computing (VisionOS / AR) · Quantum computing · Autonomous systems · AI agents · Robotics

If the product fits in **none** of these, define an ad-hoc category in the master with a one-paragraph rationale.

### Step 2 — Apply the matching rule

Each product type has an opinionated default. The agent reasons from this table; the user can override any field, but the deviation must be justified in the master.

| Product type | Recommended pattern | Primary style | Color mood | Type pairing | Key effects | Anti-patterns |
|---|---|---|---|---|---|---|
| SaaS dashboard | Bento-grid, sidebar nav | Soft UI Evolution / Minimalism | Cool neutrals + 1 brand accent | Inter / IBM Plex Sans | Subtle transitions 150ms, focus rings | Neon, dark-mode-only without toggle, AI purple/pink gradients |
| Fintech / banking | Hero + trust signals | Minimalism / Swiss Modernism 2.0 | Navy + green/gold accent | Inter / Söhne | Sober motion, no parallax | Y2K, brutalism, neon, soft pink |
| Healthcare | Hero + service grid + booking | Accessible & Ethical / Soft UI Evolution | Calming blues + white | Source Sans / Lora | Gentle hover, no aggressive motion | Brutalism, cyberpunk, dark neon, animated mascots in clinical paths |
| Luxury e-commerce | Editorial grid + product hero | Exaggerated Minimalism / Editorial | Black / cream / single saturated accent | Cormorant Garamond / Inter | Slow reveals 400-600ms, refined hover | Neon, claymorphism, cartoon icons, gradients |
| Beauty / spa / wellness | Hero + testimonials + booking | Soft UI Evolution / Organic Biophilic | Warm soft palette + gold | Cormorant Garamond / Montserrat | Smooth transitions 200-300ms, gentle hover | Bright neon, harsh animations, AI purple/pink gradients |
| Portfolio / agency | Hero + case studies + contact | Brutalism / Editorial / Anti-Polish | High contrast or monochrome | Editorial serif / mono | Bold motion, custom cursors | Generic Bootstrap, stock photo grids, "we innovate" vibes |
| Gaming | Cinematic hero + feature reels | 3D Hyperrealism / Cyberpunk / HUD-FUI | Saturated, high contrast | Display geometric / mono | Particle effects, parallax, sound | Pastel minimalism, corporate blue, sans-only |
| Music streaming | Hero + carousels + player | Dark Mode OLED / Aurora | Black + saturated accent | Display + grotesque | Liquid transitions, album art driven | Light-only, low contrast on dark, brutalist text-only |
| Developer tool / IDE | Docs-first + interactive demo | Minimalism / Dark Mode OLED | Mono palette + accent | JetBrains Mono / Inter | Snappy 100-150ms, keyboard-first | Heavy 3D, illustration-heavy, social-network UI patterns |
| Web3 / NFT | Hero + collection grid | Cyberpunk / Aurora / Glassmorphism | Deep purple / cyan / black | Display geometric / mono | Glow, gradient mesh, holographic | Stock-photo corporate, pastel wellness, paper textures |
| Habit / wellness tracker | Hero + streak visualisation | Claymorphism / Organic Biophilic | Soft warm palette | Rounded geometric | Bouncy micro-interactions | Cold corporate blue, brutalism, dense data |

If the product type isn't in the table, ask the user three questions before choosing:

1. **Audience tone**: clinical / playful / luxurious / utilitarian / counter-cultural?
2. **Density**: information-dense (admin tools) or breathing-room (consumer)?
3. **Conversion or contemplation**: must the user act fast, or are we encouraging considered decisions?

### Step 3 — Resolve concrete tokens

Convert the chosen direction into concrete tokens. The MASTER must contain:

- **Color palette** — at least: `primary`, `secondary`, `accent`, `background`, `surface`, `text`, `text-muted`, `border`, `success`, `warning`, `error`. Each with a hex value AND its semantic intent.
- **Typography** — heading font, body font, mono font (for code), and a scale (e.g., `--text-xs` through `--text-4xl` with concrete values).
- **Spacing** — a scale (4px or 8px base) and its purpose annotations.
- **Radius** — `sm`, `md`, `lg`, `full`. Concrete values.
- **Shadow** — at least three levels: `xs`, `md`, `lg`. Specify if/how they relate to elevation semantics.
- **Motion** — duration scale (e.g., `--motion-fast: 150ms`, `--motion-base: 250ms`, `--motion-slow: 400ms`) and easing tokens.
- **Breakpoints** — concrete: `sm: 375`, `md: 768`, `lg: 1024`, `xl: 1440`. (See checklist in step 5.)
- **Anti-patterns** — explicit list for this product type. What we will _not_ do.

### Step 4 — Write `design-system/MASTER.md`

Use this exact template. Replace tokens; do not omit sections.

```markdown
# Design System — <Product Name>

Generated by agent-rigor / design-system-generation skill on <ISO date>.
Spec: .specs/<feature>/spec.md

## 1. Product context
- Product type: <type>
- Audience: <one sentence>
- Tone: <one sentence>
- Density: <dense | balanced | breathing>

## 2. Pattern
- Landing pattern: <e.g., Hero-Centric + Social Proof>
- Section order: <e.g., Hero → Features → Testimonials → CTA → Footer>
- CTA strategy: <where, how often, what wording style>

## 3. Style
- Primary style: <e.g., Soft UI Evolution>
- Secondary influences: <0..2>
- Justification: <2-3 sentences linking style to product context>

## 4. Color
| Token | Value | Intent |
|---|---|---|
| --color-primary    | #...    | Brand identity, primary CTAs |
| --color-secondary  | #...    | Supporting actions |
| --color-accent     | #...    | High-emphasis moments |
| --color-bg         | #...    | App background |
| --color-surface    | #...    | Cards, modals |
| --color-text       | #...    | Body text (contrast ≥ 7:1 on bg) |
| --color-text-muted | #...    | Secondary text (contrast ≥ 4.5:1) |
| --color-border     | #...    | Dividers, input borders |
| --color-success    | #...    | Positive states |
| --color-warning    | #...    | Warning states |
| --color-error      | #...    | Error / destructive states |

(Add dark-mode variants if the product needs them. Decide explicitly; do not default.)

## 5. Typography
- Heading: <font-family>, <google-fonts-share-url>
- Body: <font-family>, <google-fonts-share-url>
- Mono: <font-family>, <google-fonts-share-url>

| Token | Size | Line height | Weight | Use |
|---|---|---|---|---|
| --text-xs   | 12px | 1.4 | 400 | Captions, tags |
| --text-sm   | 14px | 1.5 | 400 | Secondary body |
| --text-base | 16px | 1.5 | 400 | Primary body |
| --text-lg   | 18px | 1.5 | 500 | Lead paragraphs |
| --text-xl   | 24px | 1.3 | 600 | Section titles |
| --text-2xl  | 32px | 1.2 | 700 | Page titles |
| --text-3xl  | 48px | 1.1 | 700 | Hero headings |
| --text-4xl  | 64px | 1.0 | 800 | Display |

## 6. Spacing
4px base scale. Tokens: --space-1 (4) through --space-16 (64). Use --space-N consistently; never magic numbers in components.

## 7. Radius
--radius-sm: 4px · --radius-md: 8px · --radius-lg: 16px · --radius-full: 9999px

## 8. Shadow
--shadow-xs: 0 1px 2px rgba(0,0,0,.05)
--shadow-md: 0 4px 12px rgba(0,0,0,.08)
--shadow-lg: 0 12px 32px rgba(0,0,0,.12)
Elevation semantics: <e.g., xs for resting cards, md for hover, lg for modals>

## 9. Motion
--motion-fast: 150ms · --motion-base: 250ms · --motion-slow: 400ms
Easing: --ease-out: cubic-bezier(0.16, 1, 0.3, 1)
Respect prefers-reduced-motion: collapse all motion to instantaneous transitions.

## 10. Breakpoints
375 (mobile-S) · 768 (tablet) · 1024 (laptop) · 1440 (desktop)
Mobile-first. Components must work at 320px (smallest supported) without horizontal scroll.

## 11. Anti-patterns (we will NOT do)
- <Specific list for this product type>
- Examples: "AI purple/pink gradients" for banking, "emoji as icons", "carousel as primary nav", etc.

## 12. Stack-specific notes
- Framework: <e.g., Next.js 15 + Tailwind 4>
- Icon system: <e.g., Heroicons or Lucide> — never emojis as icons
- Component library: <e.g., shadcn/ui, custom, headless-ui>
- Animation library if any: <e.g., framer-motion, motion-one>

## 13. Pre-delivery checklist (every page must pass)
- [ ] No emojis as functional icons (SVG only)
- [ ] cursor-pointer on all clickable elements
- [ ] Hover states with --motion-fast or --motion-base
- [ ] Text contrast ≥ 4.5:1 (body), ≥ 7:1 preferred
- [ ] Focus states visible for keyboard nav (outline or ring, never outline:none without a replacement)
- [ ] prefers-reduced-motion respected
- [ ] Responsive verified at 375 / 768 / 1024 / 1440
- [ ] No layout shift at load (CLS = 0)
- [ ] Images have explicit width/height
- [ ] Forms have labels (not just placeholders)

## 14. Decision log
Append-only. Each material change to this MASTER gets a dated entry.

- <date> — Initial generation. Product type: <X>. Style: <Y>.
```

### Step 5 — Page-specific overrides

When designing a specific page (e.g., `/checkout`, `/dashboard`), check whether you need a `design-system/pages/<page>.md`. You only need one if the page **deviates** from the MASTER. Examples:

- The login page uses a different layout than the rest of the app — yes, page file.
- The dashboard uses additional motion tokens specific to charts — yes, page file.
- The settings page uses the same tokens as the master with no deviation — **no**, do not create a page file just to repeat.

If you create one, the format is:

```markdown
# <Page name> overrides

Inherits from design-system/MASTER.md. Only deviations below.

## Deviations
- <Token or behaviour>: <override value> · Reason: <one sentence>
- ...

## Additions
- <New tokens specific to this page if needed>
- ...

## Anti-patterns specific to this page
- <e.g., No carousels on the checkout page>
```

### Step 6 — Apply on every UI write

When the agent writes UI code:

1. Read `design-system/MASTER.md`.
2. Check `design-system/pages/<inferred-page>.md`; if exists, its rules win.
3. Use CSS variables / tokens. Never hard-code colors or sizes that exist as tokens.
4. Apply the pre-delivery checklist before claiming the work is done.

### Step 7 — Ledger

Write to the session ledger:

```bash
LEDGER="$(cat .claude/ledger/.current)"
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"artifact_produced\",\"kind\":\"design_master\",\"path\":\"design-system/MASTER.md\"}" >> "$LEDGER"
```

## Rationalizations (and refutations)

| Rationalization | Refutation |
|---|---|
| "Just use Tailwind defaults, it's fine" | Tailwind defaults are excellent _primitives_, not a design system. Two designers using Tailwind defaults will produce inconsistent results. The MASTER says which Tailwind tokens we use, in which combinations, and why. |
| "The product type doesn't fit any row in the table" | Then you have a research question, not a design question. Ask the three audience/density/conversion questions in step 2 and pick the closest neighbour. Document the choice in §1. |
| "I'll add the design system after I see a working version" | The "working version" anchors all subsequent decisions. By the time you see it, refactoring tokens costs 10× more. The system goes first. |
| "Dark mode can come later" | Then explicitly write in §4 that this product does not support dark mode. Don't leave it undecided — undecided is the worst state. |
| "Accessibility checks slow me down" | They take ~3 minutes per page and prevent bugs that take 3 hours to fix in audit. Non-negotiable. |
| "The user wants a quick mockup" | A mockup is not exempt; it sets the visual reference. Generate the MASTER even for the mockup; reusing it on the real version is free. |

## Red Flags

- The agent is producing UI code and there is no `design-system/MASTER.md` → **stop and run this skill first**
- Hard-coded hex values or px sizes in component code that should be tokens
- Multiple pages with conflicting design tokens (e.g., `--color-primary` defined twice in two files)
- The MASTER is older than the latest spec and was not reviewed when the spec changed
- Anti-patterns section is empty (means no thinking was done about what NOT to do)
- Pre-delivery checklist is empty or unchecked on shipping UI

## Verification

Before claiming this skill is done:

- [ ] `design-system/MASTER.md` exists and follows the template above
- [ ] All 14 sections are filled (no `<placeholder>`)
- [ ] At least 3 anti-patterns listed in §11
- [ ] Color tokens have contrast verified against background (manually or via tool)
- [ ] Decision log §14 has at least the initial entry
- [ ] Ledger has `artifact_produced` entry of kind `design_master`

## Solo-Developer Adaptation

Solo developers benefit most from this skill because there is no design partner to push back on token decisions. To compensate:

1. After generating the MASTER, invoke the `ux-designer` sub-agent (or `devils-advocate`) with the MASTER as input. Their objections feed into a `revision` decision-log entry in §14.
2. After 24 hours, re-read the MASTER cold. Any token that doesn't make sense without context is a token whose intent wasn't captured well — revise the "Intent" column in §4.
3. Lock the MASTER (`git tag design-system/v1.0`) before starting UI work. Subsequent changes require an explicit `/spec`-style discussion.

## macOS Notes

- Generate Google Fonts share URLs locally without a browser using `pbcopy`:
  ```bash
  echo "https://fonts.google.com/share?selection.family=Inter:wght@400;500;600;700|Cormorant+Garamond:wght@500;700" | pbcopy
  ```
- Use `osascript -e 'display notification "MASTER.md ready" with title "agent-rigor"'` to surface completion.
- Color contrast spot-check from terminal:
  ```bash
  # Requires: pip3 install wcag-contrast-ratio
  python3 -c "from wcag_contrast_ratio import rgb; print(rgb((0,0,0),(0xfa,0xfa,0xfa)))"
  ```
  If you'd rather not, use the Sim Daltonism app from the App Store for visual verification.

## Attribution

Data tables and the MASTER-overrides pattern are adapted from
`nextlevelbuilder/ui-ux-pro-max-skill` (MIT). The Python search engine was
deliberately removed — its function is now performed by the agent reasoning
against the tables in this file. This keeps the skill self-contained and
auditable in git.
