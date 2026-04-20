# Visual Regression Report

Running log of T3 findings, newest at top. Written from the subagent/worker that took the screenshot, before returning.

---

## 2026-04-20 — Canvas atmosphere pass: hero bleed + nav re-tune + muted CTA

**Changes (three-part pass, done together):**

1. `css/layout/canvas.css` — new L4 block zeroes `--space-for-fixed-header` on `.canvas-page`. The hero now starts at y=0 instead of y=160. Fixed transparent header floats over it.
2. `css/components/header.css` §5 (retuned) — nav color on canvas re-pointed from `--theme-text-color-soft` (dark-grey, correct for light bg) to `color-mix(in oklch, var(--white) 75%, transparent)` (light-grey, correct for dark hero). Contrast ratio moved 2.33:1 → 9.15:1. WCAG AA body ✅.
3. `css/components/header.css` §6 (new) — `.canvas-page/.path-frontpage .header-cta` becomes white-on-dark instead of amber-on-dark. Non-canvas pages keep the amber (§4 still rules).

**Reference:** `docs/pl2/keytail-design/keytail-desktop-homepage.jpg`

**Screenshots:**
- Desktop before: `t3-home-header-desktop-2026-04-20.png`
- Desktop after (single menu-tune pass): `t3-home-header-desktop-after-2026-04-20.png`
- Desktop final (all three changes + AA retune): `t3-home-desktop-final-2026-04-20.png`
- Mobile final: `t3-home-mobile-final-2026-04-20.png`

**T1 facts:**
- Aggregated CSS contains all three new rules (grep confirmed).
- Computed `--space-for-fixed-header` on `.canvas-page` = `0`.
- Computed `.layout-container` `padding-top` = `0px`.
- Computed `.hero` `top` = `0`, `height` = `900` (full viewport).
- Computed `.header-cta` bg = `rgb(255,255,255)`, color = `rgb(45,62,72)`.
- Computed `.primary-menu__link--level-1` color = `oklch(~1 0 none / 0.75)` → composites to `rgb(198,201,205)` on hero bg.

**T2 facts:**
- Token override approach preserves neonbyte's cascade intent. `--space-for-fixed-header` still ships a single-consumer contract; we just narrowed it for canvas.
- Specificity math:
  - `.canvas-page` override of token (0,1,0) ties with `:root` default (0,1,0); cascade proximity favours the body-closer declaration. ✅
  - `.canvas-page .site-header .primary-menu` (0,3,0) beats neonbyte's `.primary-menu` (0,1,0). ✅
  - `.canvas-page .site-header .header-cta` (0,3,0) beats our own `.header-cta` default (0,1,0). ✅
- Nav color direction flipped from light-bg-appropriate to dark-bg-appropriate; the rule now encodes which way contrast must travel. Rationale comment in source.

**T3 judgement:**
- ✅ Hero fills viewport edge-to-edge from top. Header floats over it transparently.
- ✅ Nav reads as "present but not demanding" — matches Keytail's quiet-nav aesthetic (direction-inverted for our dark hero vs. their light sky).
- ✅ White CTA reads as a primary action without competing with the hero.
- ✅ Mobile layout stacks correctly; hamburger in upper-right, hero content centered, headline + dual CTA visible above the fold.

**Accessibility (WCAG 2.1):**
- Nav-on-hero contrast: 9.15:1 (AAA pass for body and large text). The retune from 2.33:1 was the critical accessibility fix of the pass.
- CTA button: white bg + dark-navy text on any surface → ≥15:1 everywhere. ✅

**Residual / separable:**
- Menu still carries 5 items vs. Keytail's 3 — that's a Drupal menu-config (L1) change, not a theme-CSS change. Recommendation written to `docs/pl2/keytail-design/menu-ia-recommendation.md`.
- Logo wordmark vs. Keytail's icon-only mark — asset swap, separable.

**Status:** PASS for the three deltas flagged after the initial main-menu pass. Menu IA remains as the user-executable follow-up.

---

## 2026-04-20 — Main menu understatement (canvas/frontpage) [first pass, now superseded by the block above]

**Change:** `css/components/header.css` §5 added — re-points `--top-level-link-color` to `var(--theme-text-color-soft)` on `.path-frontpage .site-header .primary-menu` / `.canvas-page .site-header .primary-menu`.

**Reference:** `docs/pl2/keytail-design/keytail-desktop-homepage.jpg`

**Slice:** above-fold desktop header + first hero band (1440×900 viewport).

**Before:** `/sessions/.../Performant Labs Theme 2/t3-home-header-desktop-2026-04-20.png`

**After:** `/sessions/.../Performant Labs Theme 2/t3-home-header-desktop-after-2026-04-20.png`

**T1 facts:**
- Aggregated header.css contains the new rule (grep count 1).
- Computed `--top-level-link-color` on `.primary-menu` moved from `rgb(45,62,72)` → `rgb(85,95,104)`.
- Computed `color` on `.primary-menu__link--level-1` tracks the token change; no consumer-rule edit required.

**T2 facts:**
- Specificity: our declaration at `.canvas-page .site-header .primary-menu` (0,3,0) beats neonbyte's at `.primary-menu` (0,1,0). No `!important`, no layer tricks.
- Token chain: `--top-level-link-color` → `--theme-text-color-soft` → `--neutral-700` on `.theme--light`. L3 theme-layer fix, not L5 component-local.
- Weight and size untouched (still `normal`, `16px`). Neonbyte defaults already match Keytail on these axes.

**T3 judgement:**
- ✅ Nav items read as softer, blending into the light band rather than punching against it.
- ⚠ Residual deltas vs. Keytail (NOT addressed in this pass — flagged for user decision):
  1. Hero does not bleed to top of viewport; the transparent header sits over a light `theme-surface` band that is distinct from the hero's dark-navy section below. Keytail's hero fills the viewport under a floating header.
  2. Five nav items vs. Keytail's three (information-architecture question, not CSS).
  3. `Call today` pill remains high-saturation amber; Keytail's CTA is a muted white pill.

**Status:** PASS for the narrow "make the main menu not stand out" request. Adjacent atmospherics (hero bleed, CTA saturation) are separable follow-ups.
