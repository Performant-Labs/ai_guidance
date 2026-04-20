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
