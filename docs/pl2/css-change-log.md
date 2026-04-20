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

---

## Session 2026-04-20 — /services audit (Pass 1): scope narrowing + card grid

```
[Layer 5] Scope of transparent-header / scroll-fill / nav-color / white-CTA rules
          narrowed from (.path-frontpage, .canvas-page) → (.path-frontpage) only
          css/components/header.css §1c, §1d, §5, §6, §7  2026-04-20
  Problem: .canvas-page is a layout class (full-width) — NOT a "has dark hero"
  marker. Services page carries .canvas-page without a dark hero, so the
  translucent-white nav colour rendered invisible over the light page-title
  band (WCAG fail + unreadable).
  Ruling: L1 N/A (layout selector). L3 too broad. L4 body class is the right
  scope, but .canvas-page maps layout, not hero intent — wrong semantic match.
  L5 with .path-frontpage scope is the one page in the theme that has a dark
  hero today. If another page gains a dark hero later, add its selector to
  each block that previously had .canvas-page. ✅
  T2 verification (2026-04-20):
    /services 1440:  nav color rgb(45,62,72) (dark navy)  ✅
                     CTA bg rgb(245,158,11) amber, no border  ✅ (default §4)
    /         1440:  nav color oklab(~white / 0.75)        ✅ (unchanged)
                     CTA bg rgb(255,255,255), 1px border   ✅ (unchanged)

[Layer 4] canvas.css — responsive card grid for .canvas-page .grid-wrapper__grid > .card
          grid-column: span 4 / span 6 / 1 / -1  (1440 / 768 / 375)
          padding 32/40px, 1px token-derived border, hover translateY(-2px)
          css/layout/canvas.css L367-446  2026-04-20
  Problem: grid-wrapper__grid renders a 12-col grid, cards default to span 12
  (rendering as a flat vertical list) unless editor sets column_count on each
  paragraph. Services "What we do specifically" had 20+ cards stacked this way.
  Ruling: L1 unreachable (per-paragraph config). L3 not a token issue.
  L4 layout is correct — scoped to .canvas-page so non-canvas uses of grid-
  wrapper keep their editor-configured behaviour. Media + @container queries
  give responsive 3/2/1-up. ✅
  DOM-inspection gate (T2 probe 2026-04-20):
    .grid-wrapper__grid  display:grid  grid-template-columns: 12 tracks
      > article.card  grid-column: 1 / -1  → before: full-width row
    /services grid-wrapper children ARE .card articles (22 total)
    /        grid-wrapper children are NOT .card — rule does not affect home
  T2 verification:
    /services 1440:  span 4, width 368px (3-up)  ✅
    /services 768:   span 6, width 281px (2-up)  ✅
    /services 375:   1 / -1, width 291px (1-up)  ✅
    /        1440:   cardCount:0 — homepage unaffected  ✅
```

---

## Session 2026-04-20 — /services Pass 2: atmospheric page-title backdrop

```
[Layer 4] canvas.css — --space-for-fixed-header scope split across homepage vs interior
          canvas pages. Originally .canvas-page {=0} zeroed the spacer for every
          canvas page; Pass 1 audit surfaced that only the homepage hero should
          bleed to y=0, while interior pages want content to clear the 80px sticky
          header. Scope now bifurcates:
            .canvas-page.path-frontpage             → --space-for-fixed-header: 0
            .canvas-page:not(.path-frontpage)       → --space-for-fixed-header: 80px
          css/layout/canvas.css §hero-bleed (line 104 area)  2026-04-20
  Problem: Pass 2 T2 probe revealed .block-page-title-block was rendering at y=0
  on /services — the same token-zero that the homepage needs was being applied
  to every canvas page, hiding the top of interior content under the sticky
  header.
  Ruling: L1 N/A (token). L3 too broad (affects every theme zone). L4 body-class
  scope is correct; the bifurcation mirrors the Pass 1 header-scope split. Token-
  first fix (not consumer-rule override): single consumer is neonbyte's
  .layout-container padding-top (grep check confirmed). ✅
  T2 verification (2026-04-20):
    /services 1440:  .block-page-title-block rect.y = 80 (was 0)    ✅
    /services 768:   rect.y = 80                                    ✅
    /services 375:   rect.y = 80                                    ✅
    /        1440:   hero rect.y = 0 (.path-frontpage branch)       ✅ unchanged

[Layer 4] canvas.css — atmospheric backdrop on .canvas-page:not(.path-frontpage)
          .block-page-title-block. Full-bleed 100vw ::before gradient wash
          (4% amber → surface) at z-index -2, full-bleed ::after radial glow
          (12% amber, ellipse at 18% 35%) at z-index -1, hairline border-bottom
          (8% loud-text). Band padding-block clamp(3.5rem, 6vw, 5rem) desktop
          tapering at tablet/mobile. padding-inline = var(--spacing-m) desktop,
          var(--spacing-xs) ≤600 so title text aligns with dy-section content
          below while the backdrop continues to bleed edge-to-edge.
          css/layout/canvas.css §atmospheric-backdrop  2026-04-20
  Problem: Between the 80px sticky header and the first content section,
  Drupal renders .block-page-title-block with only an unstyled h1 (margin:
  80px 0 40px). The resulting 193px of bare off-white reads as a layout gap,
  gives the title no visual weight, and makes the header-to-content handoff
  abrupt. No upstream rule styles the block.
  Architectural pattern introduced: .canvas-page:not(.path-frontpage) is the
  canonical "interior canvas page" scope. It is the inverse of Pass 1's
  .path-frontpage-only header scope. Future interior-page layout work should
  reach for this selector rather than adding one-off path-* rules.
  Ruling: L1 background art is not config. L2 parent themes do not style
  the block — no upstream to override. L3 would affect every theme zone's
  title on every page — too broad. L4 with the :not(.path-frontpage)
  narrowing is exactly the "interior canvas" lever. L5 SDC override would
  need a duplicated library declaration; not warranted here. ✅
  Tokens: --pl-color-amber (primitive), --theme-surface, --theme-text-color-loud.
  No new tokens.
  a11y: h1 uses --theme-text-color-loud (oklch 0.15 ≈ #2D3E48) on a gradient
  surface that averages to ≈ #F0F1F0 with 4% amber tint at top. Contrast
  remains > 8:1 (AA-AAA).
  T1 verification (2026-04-20):
    curl canvas.css?tdssgz | grep "canvas-page:not(.path-frontpage) .block-page-title-block"
    → 7 declarations served                                        ✅
  T2 verification:
    /services 1440:  rect y=80 h=233, padding-block 80/80, h1 margin 0
                     ::before 1440px linear-gradient, ::after 1440px radial
                     border-bottom 1px oklch(.15 .008 260 / .08)      ✅
    /services 768:   padding-block 40/40                              ✅ (container-query tier)
    /services 375:   padding-block 32/32                              ✅ (mobile tier)
    /        1440:   .block-page-title-block NOT present (block
                     visibility hidden on frontpage) — rule no-op     ✅

[Layer 4] canvas.css — h1 inside band zeroed (margin:0) and padding-inline
          propagated so title visually aligns with content sections below.
          Prior to this refinement the h1 sat at x=0 flush to viewport edge;
          content sections sit at --spacing-m (40px) inset. Alignment
          now matches.
          css/layout/canvas.css §atmospheric-backdrop  2026-04-20
  Ruling: cosmetic refinement inside the Pass 2 block. ✅
```

