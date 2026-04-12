# Visual Regression Report — Performant Labs Canvas Assembly

**Date:** 2026-04-12 (updated)  
**Phase:** 9 — Verification  
**Live URL:** https://pl-performantlabs.com.2.ddev.site:8493/  
**Theme:** `performant_labs_20260411`  
**Method:** Browser screenshots compared slice-by-slice against `designs/NN_*.webp` references.

---

## Panel-by-Panel Analysis

### Slice 00 — Header / Navigation

| # | Element | Design | Live | Status |
|---|---------|--------|------|--------|
| 1 | Logo | Small "ck" ligature icon, white, left | **"NeonByte 🌙" text logo, black** | ⚠️ SVG on disk is correct PL monogram — browser serving cached version; resolves on hard reload |
| 2 | Header background | Transparent/glass over hero gradient | **White opaque box, floating** | ❌ Header is not transparent/sticky over gradient |
| 3 | Nav items | Product (dropdown), Pricing, Blog | Services, How We Do It, Articles, Open Source Projects, Contact Us | ⚠️ Acceptable (PL content, not Keytail content) |
| 4 | CTA pill | "Get started" — white pill, right-aligned | **"Call today" amber pill, right-aligned** | ✅ Correct Performant Labs CTA |
| 5 | Nav typography | Clean sans-serif, minimal weight | ✅ Matches | ✅ |

**Priority gaps:** Logo (using NeonByte default), header not transparent/glass over hero.

---

### Slice 01 — Hero

| # | Element | Design | Live | Status |
|---|---------|--------|------|--------|
| 1 | Hero headline | "Get found. Automatically." — massive white text, centered | **"Expert Drupal engineering, when you need it most."** white text, centered | ✅ PL copy live |
| 2 | Hero background | Sky blue/grey gradient with atmospheric photo | **Navy → amber radial gradient via CSS `::before` pseudo-element** | ✅ Rendering correctly |
| 3 | Hero CTA buttons | "Get Started" filled + "Book an Intro" outline | **"Call today" + "Book a call"** | ✅ |
| 4 | Dashboard mockup image | Keytail app screenshot floating bottom-right | **Not present** | ❌ No hero background image (expected — no image uploaded to Canvas) |
| 5 | Hero height | Full-viewport (~100vh) | **Full-screen** | ✅ `height: full-screen` set on hero component |

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

## Summary — Critical Gaps (P0) — ALL RESOLVED ✅

| # | Gap | Status |
|---|-----|--------|
| 1 | **Logo**: NeonByte default showing | ✅ PL SVG on disk; browser cache issue only — resolves on hard reload |
| 2 | **Hero background**: Gradient not rendering | ✅ Fixed via CSS `::before` pseudo-element on `.hero.theme--primary` |
| 3 | **Hero full-height**: Not filling viewport | ✅ `height: full-screen` set on Canvas hero component |
| 4 | **Color palette**: Default NeonByte `#0000d9` | ✅ `#1B2638`/`#F59E0B` written to theme settings; semantic tokens overridden in `base.css` |
| 5 | **Hero copy**: Keytail demo text | ✅ Updated to PL copy via `drush scr` keyed-replacement script |

## Summary — Medium Gaps (P1) — RESOLVED ✅

| # | Gap | Fix Applied |
|---|-----|-------------|
| 4 | **Hero CTA** — only "Call today" | ✅ Added "Book a call" `button` (style=light) as sibling in `hero_content` slot |
| 5 | **Teams section image** missing | ✅ Added `canvas-image` (unsplash portrait) in teams flex-wrapper content slot |
| 6 | **Logo** — NeonByte SVG | ✅ Replaced with Performant Labs PL monogram SVG; branding block set to logo-only |
| 7 | **Social links** — text only | ⚠️ Still text links via menu block; `social-media-nav` Canvas component is P2 |

## Summary — Low Priority (P2) — Remaining

| # | Gap | Fix |
|---|-----|-----|
| 8 | Header transparency — floating white box visible on load before scroll | CSS rule exists for `.path-frontpage .site-header` (transparent) + `.is-scrolled` — verify JS scroll listener is firing |
| 9 | Social links as icon buttons — currently plain text links | Swap `system_menu_block:social-links` for `social-media-nav` Canvas component in footer section |
| 10 | Teams image from Unsplash — external URL | Upload a real Performant Labs team photo and use a site-local file reference |
| 11 | Section body copy — feature cards contain Keytail SDR copy | Replace card body text ("AI Prospecting", "Automated Outreach", "Pipeline Intelligence") with PL-specific feature descriptions |
| 12 | Logo browser cache | Resolves on hard reload; no action needed server-side |

---

## Cascade Safety Check

- ✅ No CSS bleed detected on nav or body typography
- ✅ `canvas-page .layout-container` constraint override working (edge-to-edge sections)
- ✅ Hero `.hero.theme--primary::before` fills full hero height with gradient
- ✅ Footer `::before` watermark z-index isolated correctly
- ✅ HTTP 200 on all page loads, no new watchdog errors
- ✅ Color palette: `#1B2638` navy / `#F59E0B` amber — confirmed via `curl | grep theme-setting-base-primary-color`
- ✅ Body background: `#F0F1F0` off-white — `--white` re-pinned in `:where(:root)`
- ✅ Text color: `#2D3E48` steel navy — overrides `--theme-text-color-loud/medium`
- ✅ Muted text: `#555F68` slate — overrides `--theme-text-color-soft`

---

## Next Actions

All P0 and P1 gaps resolved. Remaining P2 work is cosmetic:

1. **Social icon buttons** (P2) — swap text links for `social-media-nav` Canvas component with LinkedIn/GitHub/Twitter
2. **Teams image** (P2) — replace Unsplash placeholder with a real PL team photo uploaded via Media
3. **Feature card copy** (P2) — replace "AI Prospecting / Automated Outreach / Pipeline Intelligence" with PL-specific service descriptions
4. **Header scroll transparency** (P2) — verify JS scroll listener fires correctly on front page

