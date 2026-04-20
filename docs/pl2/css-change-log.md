# CSS Change Log — `performant_labs_20260418`

Maintained by AntiGravity per `docs/pl2/theme-change--workflow.md`.
Read at the start of every session before any new trace is started.

Format: `[Layer N] property/token  in  selector  →  value  file:line  YYYY-MM-DD  [note]`

---

## Session 2026-04-19 — Stage 1 Foundation

```
[Layer 1] base_primary_color → #1B2638  performant_labs_20260418.settings (drush)  2026-04-18
  Ruling: Primary brand navy — config is the only correct mechanism (ThemeColorPreprocessor.php injects inline).

[Layer 1] base_secondary_color → #F59E0B  performant_labs_20260418.settings (drush)  2026-04-18
  Ruling: Secondary brand amber — same mechanism.

[Layer 3] --theme-surface in html :where(:root), html .theme--white, html .theme--light → #F0F1F0  css/base.css:L34  2026-04-18
  Ruling: L1 correct. L2 OKLCH-derived surface is pure white — brand requires off-white. L3 is correct layer.

[Layer 3] --theme-text-color-loud in html .theme--white, html .theme--light → #2D3E48  css/base.css:L37  2026-04-18
  Ruling: L1 correct. L2 derives a neutral from primary but shade is too dark. L3 correct.

[Layer 3] --theme-text-color-medium in html .theme--white, html .theme--light → #2D3E48  css/base.css:L40  2026-04-18
  Ruling: Same as above.

[Layer 3] --theme-text-color-soft in html .theme--white, html .theme--light → #555F68  css/base.css:L43  2026-04-18
  Ruling: Muted text — L3 correct, brand-specific shade.

[Layer 3] --theme-link-color in html .theme--white, html .theme--light → #F59E0B  css/base.css:L46  2026-04-18
  Ruling: Amber links on light bg — intentional brand deviation from OKLCH-derived link colour.

[Layer 3] --theme-link-color-hover in html .theme--white, html .theme--light → #92600A  css/base.css:L47  2026-04-18
  Ruling: Darkened amber hover. L3.

[Layer 3] --theme-focus-ring-color in html .theme--white, html .theme--light → #F59E0B  css/base.css:L50  2026-04-18
  Ruling: Amber focus ring on light. L3.

[Layer 3] --theme-border-color in html .theme--white, html .theme--light → #555F68  css/base.css:L53  2026-04-18
  Ruling: Steel border on light. L3.

[Layer 3] --theme-surface in html .theme--primary, html .theme--dark, html .theme--black → #1B2638  css/base.css:L63  2026-04-18
  Ruling: Navy surface for dark zones. L3.

[Layer 3] --theme-surface-alt in html .theme--primary etc → #2D3E48  css/base.css:L66  2026-04-18
  Ruling: Lighter navy alt-surface. L3.

[Layer 3] --theme-text-color-loud in html .theme--primary etc → #FFFFFF  css/base.css:L69  2026-04-18
  Ruling: White headings on dark. L3.

[Layer 3] --theme-text-color-medium in html .theme--primary etc → #F0F1F0  css/base.css:L72  2026-04-18
  Ruling: Near-white body on dark. L3.

[Layer 3] --theme-text-color-soft in html .theme--primary etc → #AABBC8  css/base.css:L75  2026-04-18
  Ruling: Muted blue-grey on dark. L3.

[Layer 3] --theme-link-color in html .theme--primary etc → #F59E0B  css/base.css:L78  2026-04-18
  Ruling: Amber links on dark. L3.

[Layer 3] --theme-link-color-hover in html .theme--primary etc → #E8973A  css/base.css:L79  2026-04-18
  Ruling: Warm amber hover on dark. L3.

[Layer 3] --theme-focus-ring-color in html .theme--primary etc → #F59E0B  css/base.css:L82  2026-04-18
  Ruling: Amber focus on dark. L3.

[:root] --font-sans → 'Inter', sans-serif  css/base.css:L23  2026-04-18
  Ruling: Font vars NOT injected inline by Dripyard — :root safe. (theme-change--audit.md Claim 6).
```

---

## Session 2026-04-19 — Stage 2, Component 1: Hero Gradient

```
[Layer 5] --hero-background in .hero.theme--primary → #1B2638  css/components/hero.css:L31  2026-04-19
  Mechanism: libraries-extend on core/components.neonbyte--hero
  Ruling: L1 config correct but cannot express gradient. L3 (html .theme--primary) RULED OUT —
  hero.css re-declares --hero-background directly on .hero (specificity 0,1,0), overriding any
  inherited ancestor value. L5 (.hero.theme--primary, specificity 0,2,0) beats hero.css (0,1,0).

[Layer 5] ::before gradient in .hero.theme--primary → radial-gradient(ellipse at 30% 40%, #1e4a6b 0%, #1B2638 45%, #3d1f00 80%, #F59E0B 130%)  css/components/hero.css:L36  2026-04-19
  Mechanism: Pseudo-element — no conflict with existing rules.
  Ruling: New pseudo-element at Layer 5. No higher layer can express a gradient. Correct.

[Layer 5] z-index in .hero.theme--primary .hero__container, .hero__media → z-index: 1  css/components/hero.css:L53  2026-04-19
  Ruling: Belt-and-suspenders lift above ::before. .hero__content already has z-index:1 in hero.css.
```

---

## Session 2026-04-19 — Stage 2, Component 2: Transparent Sticky Header

```
[Layer 5] --header-background-color-percent in .path-frontpage .site-header, .canvas-page .site-header → 0%  css/components/header.css:L34  2026-04-19
  Mechanism: libraries-extend on core/components.neonbyte--header
  Ruling: L1 config has no transparency setting. L3 (html .theme--light) RULED OUT —
  header.theme.css re-declares --header-background-color-percent on .site-header (0,1,0),
  overriding inherited ancestor values. L5 (.canvas-page .site-header, 0,2,0) beats (0,1,0). ✅
  Note: backdrop-filter: blur(10px) already present in header.theme.css — not duplicated.

[Layer 5] --header-background-color-percent in .path-frontpage .site-header.is-scrolled, .canvas-page .site-header.is-scrolled → 100%  css/components/header.css:L41  2026-04-19
  Ruling: L5 state rule. Specificity (0,3,0) beats transparent rule (0,2,0). ✅
  Note: .is-scrolled fired by js/header-scroll.js Drupal behavior (scroll threshold: 80px).

[JS] plHeaderScroll Drupal.behavior — adds/removes .is-scrolled on .site-header  js/header-scroll.js  2026-04-19
  Mechanism: header-override library (libraries-extend on core/components.neonbyte--header)
  Dependencies: core/drupal, core/once
  Note: neonbyte header.js has NO scroll behavior — .is-scrolled was never implemented.
  This is the first and only implementation of scroll-to-opaque in this theme chain.

[Layer 5] transition on .site-header__container → background-color 0.3s ease  css/components/header.css:L50  2026-04-19
  Ruling: No transition for background-color in header.theme.css. New rule at L5. ✅
  guard: @media (prefers-reduced-motion: no-preference)

[Layer 5] .header-cta → amber pill (#F59E0B fill, #1B2638 text, border-radius 999px)  css/components/header.css:L57  2026-04-19
  Ruling: Custom class, no Dripyard token chain. Direct L5 style.
```

---

## Session 2026-04-19 — Stage 2, Component 3: content-card

```
[Layer 5] --content-card-border-radius in .content-card → var(--radius-lg)  css/components/content-card.css:L33  2026-04-19
  Mechanism: libraries-extend on core/components.dripyard_base--content-card
  Ruling: Same specificity (0,1,0) as component rule; later load wins. ✅

[Layer 5] --content-card-background in .content-card.content-card--has-background → #FFFFFF  css/components/content-card.css:L46  2026-04-19
  Ruling: L3 (html .theme--white { --theme-surface-alt }) too broad — affects all
  surface-alt consumers. Ruled out. L5 scoped to .content-card.content-card--has-background
  (0,2,0) = same specificity as component rule; later load wins. Dark-zone cards unaffected. ✅
  Note: --theme-border undefined in all contrib CSS → border: 1px solid var(--theme-border)
  resolves to invalid → no visible border. No action needed.

[Layer 5] box-shadow on .content-card → 0 2px 8px rgba(27,38,56,0.08), 0 1px 2px rgba(27,38,56,0.04)  css/components/content-card.css:L36  2026-04-19
  Ruling: New property, no token chain. L5 direct addition. ✅

[Layer 5] transform + box-shadow on .content-card:hover → translateY(-3px) + deeper shadow  css/components/content-card.css:L55  2026-04-19
  Ruling: New rule, L5. Transition guarded by prefers-reduced-motion. ✅
```

---

## Session 2026-04-19 — Stage 2, Component 4: button--cta / button--pill-dark

```
[NO ACTION — Layer 1 handles all button properties]

Two-pass trace (2026-04-19):
  .button--secondary (hero "Call today"):
    --button-background-color: var(--secondary)
    --secondary ← OKLCH engine ← base_secondary_color: #F59E0B config anchor.
    L1 already produces the amber fill and dark text via OKLCH-generated
    --color-secondary-text-color. No CSS override needed or permitted.

  border-radius:
    --button-border-radius: var(--radius-button)
    --radius-button ← --theme-setting-radius-button: 40px (inline <html> from config).
    L1 already produces the fully-rounded pill at 40px. No CSS override needed.

  button--cta / button--pill-dark custom classes (from 20260411):
    NOT present in any DOM element on 20260418 site. Those classes were manual
    workarounds that pre-dated the OKLCH config engine. Adding them would be dead CSS.

  button--light (hero "Book a call"):
    Uses --neutral-100 / --neutral-900. Legible ghost style. Design map = port as-is.
    No brand requirement to change it.

Decision: No libraries-extend, no CSS file, no libraries.yml or info.yml changes.
          This is the intended outcome of the trace-first protocol — Layer 1 handles
          the visual goal; Layer 5 is not the correct layer.
```

---

## Session 2026-04-20 — Stage 2, Component 5: Tabs pill indicator

```
[Layer 5] --tab-active-background-color → var(--pl-color-amber)  css/components/tabs.css  2026-04-20
  Mechanism: libraries-extend on core/components.neonbyte--tabs
  Ruling: Token not wired to OKLCH engine. L3 ruled out (too broad). L5 scoped to
  .tabs__tab[aria-selected="true"] (0,2,0). ✅

[Layer 5] --tab-active-text-color, --tab-active-icon-color → var(--pl-color-navy)  css/components/tabs.css  2026-04-20
  Ruling: Contrast pair for amber pill. L5 direct. ✅

[Layer 5] --tab-active-border-radius → var(--radius-lg)  css/components/tabs.css  2026-04-20
  Ruling: Pill shape. No upstream token. L5 correct. ✅
```

---

## Session 2026-04-20 — Stage 2, Component 6: Accordion amber chevron

```
[Layer 5] color on .accordion-item__summary svg → var(--pl-color-amber, #F59E0B)  css/components/accordion.css  2026-04-20
  Mechanism: libraries-extend on core/components.dripyard_base--accordion
  Ruling: --accordion-item-icon-color exists but setting at L3 affects all theme contexts.
  L5 scoped selector (0,2,0) preferred. ✅

[Layer 5] border-top on .accordion-item → 1px solid var(--theme-border-color-soft)  css/components/accordion.css  2026-04-20
  Ruling: Separator using semantic token. No hardcoded value. ✅
```

---

## Session 2026-04-20 — Stage 2, Component 7: Footer

```
[Layer 5] .site-footer watermark — font-size: clamp(16rem, 40vw, 32rem); opacity: 0.04  css/components/footer.css  2026-04-20
  Mechanism: libraries-extend on core/components.neonbyte--footer
  Ruling: Decorative element. No token. clamp() is fluid — no mobile breakpoint needed. ✅

[Layer 5] .footer-social-icons — display:flex, gap, icon button sizing  css/components/footer.css  2026-04-20
  Ruling: New element injected via page--front.html.twig. No token chain. L5 correct. ✅

[Layer 5] .site-footer .footer-cta__link → color + hover via var(--pl-color-amber)  css/components/footer.css  2026-04-20
  Ruling: .site-footer scope raises specificity (0,2,1) to beat neonbyte link reset without
  !important. Tokens used throughout. ✅
```

---

## Session 2026-04-20 — Stage 2, Layouts

```
[Layout] canvas.css — .canvas-page .layout-container { max-width:none; padding-inline:0 }  2026-04-20
  Mechanism: global library (performant_labs_20260418/canvas-layout) in .info.yml
  Ruling: Nullifies dripyard_base layout constraint for canvas pages. Layout file correct per
  strategy Rule 2. ✅

[Layout] docs.css — .docs-layout { display:grid; grid-template-columns:260px 1fr }  2026-04-20
  Mobile breakpoint at 900px: single-column stack. Rule 8 met. ✅
  sidebar_first region added to info.yml; book_navigation block moved from header_first. ✅
```

---

## Session 2026-04-20 — Bug Fixes

```
[Fix] page.html.twig — removed button--primary from header CTA anchor class  2026-04-20
  Problem: button--primary overriding .header-cta amber pill on interior pages with neonbyte's
  dark-navy button style.
  Fix: class="header-cta" only — matches page--front.html.twig. Amber pill now consistent. ✅
  Note: Twig template change only — no CSS layer implications.
```
