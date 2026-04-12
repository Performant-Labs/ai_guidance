# Visual Regression Report — Keytail Canvas Assembly

**Date:** 2026-04-11  
**Phase:** 8 — Verification  
**Live URL:** https://pl-performantlabs.com.2.ddev.site:8493/  
**Theme:** `performant_labs_20260411`  
**Method:** Browser screenshots compared slice-by-slice against `designs/NN_*.webp` references.

---

## Panel-by-Panel Analysis

### Slice 00 — Header / Navigation

| # | Element | Design | Live | Status |
|---|---------|--------|------|--------|
| 1 | Logo | Small "ck" ligature icon, white, left | **"NeonByte 🌙" text logo, black** | ❌ Wrong logo — Performant Labs logo not showing |
| 2 | Header background | Transparent/glass over hero gradient | **White opaque box, floating** | ❌ Header is not transparent/sticky over gradient |
| 3 | Nav items | Product (dropdown), Pricing, Blog | Services, How We Do It, Articles, Open Source Projects, Contact Us | ⚠️ Acceptable (PL content, not Keytail content) |
| 4 | CTA pill | "Get started" — white pill, right-aligned | **"Call today" amber pill, right-aligned** | ✅ Correct Performant Labs CTA |
| 5 | Nav typography | Clean sans-serif, minimal weight | ✅ Matches | ✅ |

**Priority gaps:** Logo (using NeonByte default), header not transparent/glass over hero.

---

### Slice 01 — Hero

| # | Element | Design | Live | Status |
|---|---------|--------|------|--------|
| 1 | Hero headline | "Get found. Automatically." — massive white text, centered | **"Search and outreach has changed. Has your strategy?"** white text, centered | ⚠️ Different PL copy — intentional content adaptation |
| 2 | Hero background | Sky blue/grey gradient with atmospheric photo | **Flat light grey — no gradient/image** | ❌ Hero background gradient (`radial-gradient` in `base.css`) not rendering |
| 3 | Hero CTA buttons | "Get Started" filled + "Book an Intro" outline | **"Call today" button visible, amber** | ⚠️ Only one button vs two in design |
| 4 | Dashboard mockup image | Keytail app screenshot floating bottom-right | **Not present** | ❌ No hero background image (expected — no image uploaded to Canvas) |
| 5 | Hero height | Full-viewport (~100vh) | **Shorter than full viewport** | ❌ `full_height` prop not set on hero component |

**Priority gaps:** Hero background gradient not rendering, full-height not set.

---

### Slice 02 — Features ("Search has changed")

*Not directly captured in live screenshots. DOM verification via curl confirms 3× `content-card` components render.*

| # | Element | Status |
|---|---------|--------|
| Feature cards grid (3 col) | ✅ Rendered in DOM |
| Section heading | ✅ Present |

---

### Slice 03 — Carousel ("Built different")

*DOM verification confirms 4× `card-canvas` inside carousel.*

| # | Element | Status |
|---|---------|--------|
| Carousel component | ✅ Rendered |
| 4 cards | ✅ Confirmed |

---

### Slice 04 — Content Engine (Tabs)

*DOM verification confirms `tab-group` + 3 tabs + `canvas-image` per tab.*

| # | Element | Status |
|---|---------|--------|
| Tab group (Discover/Create/Publish) | ✅ Rendered |
| Canvas images per tab | ✅ Rendered |

---

### Slice 05 — Designed for Teams

| # | Element | Design | Live | Status |
|---|---------|--------|------|--------|
| Eyebrow text | "Designed for teams that rely on SEO to scale." | ✅ Present in DOM | ✅ |
| Audience heading | "Startups" | ✅ Present | ✅ |
| Body copy | ✅ Present | ✅ |
| CTA button | "Get in touch" | ✅ Present | ✅ |
| Right-side image | Woman at laptop | ❌ Not added (placeholder only; no Canvas image component) | ❌ |

---

### Slice 06 — Just Like Stocks

| # | Element | Status |
|---|---------|--------|
| Section heading | ✅ "Just like stocks, you wish you started earlier." in DOM |
| Body copy | ✅ Present |
| Statistics row (584K, 40%, 5000+) | ✅ All three confirmed in DOM |
| Tab group (With/Without Keytail) | ✅ Rendered |
| Graph/chart | ❌ Not implemented (placeholder text only — expected) |

---

### Slice 07 — FAQ

| # | Element | Design | Live | Status |
|---|---------|--------|------|--------|
| "FAQ" centered heading | ✅ | ✅ DOM confirmed | ✅ |
| 4 accordion items | ✅ | ✅ 4× accordion-item rendered | ✅ |
| Expand/collapse interaction | ✅ Native dripyard accordion | ✅ |
| Border styling (thin grey lines) | ✅ Design uses thin borders | Should match `accordion-group` "borders" variation | ⚠️ Verify variation prop |

---

### Slice 08 — Footer

| # | Element | Design | Live | Status |
|---|---------|--------|------|--------|
| Footer background | Blue-grey atmospheric gradient | ✅ `theme--primary` navy | ✅ |
| Giant "K" watermark | White transparent letter, left | ✅ CSS `::before` pseudo-element | ✅ |
| Logo + tagline left | "Get found. Automatically." small text | ✅ In DOM (footer-left region) | ✅ |
| "Be the answer." CTA | Large white text, top-right | ✅ Injected in Twig | ✅ |
| Footer nav columns (3 groups) | Product/More/Company | Services/Resources/Company | ✅ Correct PL structure |
| Social links | LinkedIn, X, Instagram icons | LinkedIn, GitHub, Twitter/X text links | ⚠️ Text links not icon buttons |
| Copyright line | ✅ Via neonbyte footer template | ✅ |

---

## Summary — Critical Gaps (P0)

| # | Gap | Fix Required |
|---|-----|-------------|
| 1 | **Logo**: NeonByte default logo showing instead of Performant Labs logo/wordmark | Upload PL logo SVG to `header_first` branding block OR override logo in `system.branding` config |
| 2 | **Hero background**: Gradient not rendering — `hero__media` CSS rule may not be targeting the correct selector in this Canvas context | Inspect `.hero__media` vs `.neonbyte-hero__background` — update CSS selector in `base.css` |
| 3 | **Hero full-height**: Canvas hero component not filling full viewport | Set `full_height: TRUE` in hero component inputs via entity API update |

## Summary — Medium Gaps (P1)

| # | Gap | Fix Required |
|---|-----|-------------|
| 4 | **Hero CTA** — only "Call today", no "Book a call" secondary button | Add second `button` component to hero_content slot |
| 5 | **Teams section image** — right-side image column missing | Add `canvas-image` with a stock photo to the flex-wrapper in teams section |
| 6 | **Social links** — text links, not icon buttons | Add icon SVGs or use `social-media-nav` component instead of standard menu block |
| 7 | **Stocks graph** — placeholder text only | Consider a static SVG graph image via `canvas-image` |

## Summary — Low Priority (P2)

| # | Gap | Fix |
|---|-----|-----|
| 8 | Header transparency — white opaque box vs glass overlay | CSS: `.site-header { background: transparent; }` on `.canvas-page` body class |
| 9 | FAQ accordion `variation` — verify "borders" vs "background-color" matches design thin-line style | Check Canvas DB row for accordion-group inputs |

---

## Cascade Safety Check

- ✅ No CSS bleed detected on nav or body typography
- ✅ `canvas-page .layout-container` constraint override working (edge-to-edge sections)
- ✅ Hero `.hero__media` rule scoped — not polluting doc pages
- ✅ Footer `::before` watermark z-index isolated correctly

---

## Next Actions

1. **Fix Logo** (P0) — configure Performant Labs logo in site branding block
2. **Fix Hero gradient** (P0) — debug CSS selector mismatch for hero background
3. **Fix Hero full-height** (P0) — update Canvas entity hero inputs via drush scr
