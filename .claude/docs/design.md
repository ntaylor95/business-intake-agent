# Design — Usage Guide

> The brand's visual **values** live in [`assets/brand.css`](../assets/brand.css). This file explains how to **use** those values — when to pick which color, the rules the pipeline enforces, and what's not yet captured in CSS.

---

## Provenance

The brand values were extracted from the live marketing site by observing actual usage patterns:

- **Navy `#1b365d`** is the dominant tone — body copy and headings throughout.
- **Orange `#ff6c0e`** is the primary CTA color, used on buttons like "Get Started" **and on active tab buttons**.
- **Sky `#59c8e6`** appears on H2s, eyebrow labels, and links.
- **Light `#f5f8fc`** is the off-white section background that breaks up white expanses.
- **Open Sans** is the primary typeface across all text; Calibri/Tahoma are fallbacks.
- **H1 uses weight 800 with tight letter spacing (-0.02em)** for visual impact on hero sections.
- **Four button variants** (`.btn-primary`, `.btn-secondary`, `.btn-ghost`, `.btn-text`) reflect patterns observed in real page layouts — primary action, secondary action, ghost on dark backgrounds, and the distinctive all-caps text+arrow link.

When the brand evolves, update `assets/brand.css` first; this file is descriptive of the CSS, not a parallel source.

---

## Where the values live

**`assets/brand.css`** is the source of truth for:
- Color palette (CSS custom properties: `--color-navy`, `--color-orange`, `--color-sky`, etc.)
- Typography (font family, headings, body, utility text)
- Component recipes: `.btn-primary` (orange CTA), `.btn-secondary` (navy outline), `.btn-ghost` (sky outline for dark backgrounds), `.btn-text` (arrow link with hover gap animation), links (`a`), `.text-small` eyebrow labels, `.text-muted` captions

**Do not duplicate or re-define these in component styles.** Reference them via `var(--color-navy)`, etc.

---

## Scaffold convention

When the executor scaffolds a new React app:

1. Copy the brand stylesheet into the app: `cp assets/brand.css <app>/src/styles/brand.css`
2. Import it once in the app's entry point (e.g. `src/main.tsx`): `import './styles/brand.css'`
3. Use the CSS custom properties in all new components: `color: var(--color-navy)`
4. Use the existing component classes where applicable: `<button className="btn-primary">Click</button>`

**Do not introduce Tailwind, styled-components, or CSS-in-JS.** The brand uses plain CSS with custom properties; that's what stays.

---

## Color usage intent

Values are in `brand.css`. These rules govern *when* to use which.

- **Navy (`--color-navy`)** — structural color. Headings, body text, secondary-button borders. The dominant visual weight on the page.
- **Orange (`--color-orange`)** — reserved for primary actions AND active selection states (e.g., the active tab in a tab group). At most one primary orange CTA per view; tab indicators don't count toward that limit. Multiple competing primary CTAs dilute the hierarchy.
- **Sky (`--color-sky`)** — links, H2 emphasis, badges, info accents. Use sparingly — overuse drains its highlight power.
- **Light (`--color-light`)** — section backgrounds, cards. The neutral that breaks up white expanses.
- **Muted (`--color-muted`)** — subtext and captions only. Not for primary information.
- **Dark (`--color-dark`)** — body copy on light backgrounds (lighter than navy; less assertive).

---

## Brand rules the pipeline enforces

These are checked by pm (at spec time) and reviewer (at code time):

- **Don't introduce new colors.** If a spec requires a color that isn't in `brand.css`, pm returns `NEEDS CLARIFICATION` — bounce to the user. Never invent.
- **Sharp corners are part of the brand.** Buttons and cards use `border-radius: 0`. Don't add rounded corners unless the spec explicitly calls for them.
- **Avoid drop shadows and gradients.** The aesthetic is flat and structured.
- **One primary CTA per view.** Orange is for **the** primary action.
- **All UI imports `brand.css`.** New components must reference `var(--color-*)`, not hardcoded hex values.

---

## Accessibility

- **Sky on white is borderline.** Small body text in `#59c8e6` on white is ~2.5:1 contrast — fails WCAG AA. Inline links may need underline-on-focus to compensate. The reviewer flags small sky text on light backgrounds.
- **Orange CTA buttons** (white text on `#ff6c0e`) pass AA at button text sizes. Confirm any new orange-on-light combinations against a contrast tool.
- All buttons must have a visible focus state. The brand's hover-only state is insufficient for keyboard users.

---

## Not yet captured in `brand.css`

These categories are referenced informally but **not** defined in the brand stylesheet yet. The executor must NOT invent values — surface the need in the spec, and the team adds them to `brand.css` as they're agreed on.

- **Spacing scale** — no `--space-*` tokens defined yet
- **Border radius beyond `0`** — sharp corners are the brand; pills/avatars (`9999px`) are the only exception
- **Shadows** — not used by the brand currently
- **Breakpoints** — the brand uses fluid `clamp()` typography rather than discrete breakpoints
- **Semantic colors** — `success` / `warning` / `error` not defined; pm should ask if a spec needs one
- **Mono font** — not specified; pick at the spec stage if code blocks are needed
- **Dark mode** — not addressed in the current brand stylesheet
