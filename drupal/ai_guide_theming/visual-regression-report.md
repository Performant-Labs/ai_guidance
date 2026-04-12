# Visual Regression Report

**Date**: 2026-04-11  
**Live site**: https://pl-performantlabs.com.2.ddev.site:8493/  
**Viewport**: 1728×997 px | **Page height**: ~4962 px  
**Reference slices**: `web/themes/custom/performant_labs_20260411/designs/`  
**Lens**: Structural and CSS gaps only. Copy differences are expected and are not listed.

---

## Panel 00 — Header / Navigation

**Reference**: `designs/00_menu.webp`

| What to check | Reference | Live | Gap? |
|---|---|---|---|
| Header background | Light blue-grey, semi-transparent | Solid dark navy | ❌ |
| Logo position | Left-aligned | Left-aligned | ✅ |
| Nav links position | Right of logo, horizontal | Right of logo, horizontal | ✅ |
| CTA button in header | Present (pill-shaped, right side) | Absent | ❌ |
| Header height / density | Compact ~56 px | Compact ~56 px | ✅ |
| Sticky behaviour | Sticky with transparent-to-opaque scroll | Sticky, always opaque | ⚠️ |

**Actionable fixes:**
- [ ] Add a CTA button (`Call today` or `Get started`) as a third flex item in the header region
- [ ] Change header background from solid navy to semi-transparent; add scroll-triggered opacity via JS or CSS `scrolled` class

---

## Panel 01 — Hero Banner

**Reference**: `designs/01_hero.webp`

| What to check | Reference | Live | Gap? |
|---|---|---|---|
| Section background | Full-bleed photo with overlay | CSS gradient (dark navy → black) with amber glow | ❌ |
| Text alignment | Centered | Left-aligned | ❌ |
| Headline font weight | Black / 900 | Bold / 700 | ⚠️ |
| Headline font size | ~64–72 px display | ~48 px | ⚠️ |
| CTA button count | Two side-by-side (filled + ghost) | One (filled only) | ❌ |
| CTA button layout | `display: flex; gap` row | Single block button | ❌ |
| Hero illustration / mockup | Large dashboard image below CTAs | Absent | ❌ |
| Section min-height | ~600 px | ~400 px | ⚠️ |

**Actionable fixes:**
- [ ] Add a second ghost/outline button alongside the existing primary CTA — wrap both in a flex row container
- [ ] Center-align hero text (`text-align: center; align-items: center`)
- [ ] Increase hero section `min-height` to ~600 px
- [ ] Add a dashboard illustration image below the CTA row (or use a styled `<img>` SDC slot)
- [ ] Increase headline `font-size` and `font-weight` to match display scale

---

## Panel 02 — Features Section

**Reference**: `designs/02_features_search_changed.webp`

| What to check | Reference | Live | Gap? |
|---|---|---|---|
| Section background | White (`#fff`) | Light grey (`~#f2f2f2`) | ⚠️ |
| Card layout | Horizontal scroll / 4-col grid with image backgrounds | Vertical stacked list (1-col) | ❌ |
| Card background | Landscape photo fill per card | Flat white rounded rectangle | ❌ |
| Card image slot | Full-bleed background image | Absent | ❌ |
| Section headline position | Left-aligned, large display | Centered, standard H2 | ⚠️ |

**Actionable fixes:**
- [ ] Change feature cards from stacked vertical list to a CSS Grid or flex row (4 columns at desktop)
- [ ] Add image slot / background image capability to each feature card component
- [ ] Set section background to `#fff`

---

## Panel 03 — Carousel / "Built Different"

**Reference**: `designs/03_carousel_built_different.webp`

| What to check | Reference | Live | Gap? |
|---|---|---|---|
| Card background treatment | Soft cloud/sky gradient image per card | Flat white card | ❌ |
| Card layout | Horizontal, 4 visible, overflow scroll | Vertical, 3 stacked | ❌ |
| Carousel navigation arrows | Present (left/right) | Absent | ❌ |
| Section background | White | Light grey | ⚠️ |

**Actionable fixes:**
- [ ] Implement a horizontal overflow scroll or CSS Scroll Snap container for the card row
- [ ] Add prev/next arrow controls to the carousel container
- [ ] Apply background image/gradient to each card rather than flat white fill

---

## Panel 04 — Dashboard / Tabbed Section

**Reference**: `designs/04_content_engine.webp`

| What to check | Reference | Live | Gap? |
|---|---|---|---|
| Tab component present | Yes (Discover / Create / Publish / Grow) | Yes (Prospects / Sequences / Analytics) | ✅ structure |
| Tab content area — image | Full product dashboard screenshot rendered | **Raw placeholder text visible**: "Prospects dashboard screenshot — to be added." | ❌ **Blocker** |
| Tab content area height | ~500 px filled | Collapses to ~1 line of text | ❌ |
| Dark featured sub-section | Present (dark bg, centered headline, "Explore" CTA button) | Absent | ❌ |
| Section background | Light grey with dark inset panel | Light grey only | ⚠️ |

**Actionable fixes:**
- [ ] **Immediately remove** the placeholder string "Prospects dashboard screenshot — to be added." — this is shipping to the browser
- [ ] Add dashboard images to each of the three tab slots (Prospects / Sequences / Analytics)
- [ ] Implement the dark-background featured callout sub-section below the tab row (headline + body + CTA button, dark background, full-width)

---

## Panel 05 — Designed for Teams

**Reference**: `designs/05_designed_for_teams.webp`

| What to check | Reference | Live | Gap? |
|---|---|---|---|
| Layout | 2-column: text left / photo right | Single column, left-aligned | ❌ |
| Right column | Full-bleed lifestyle photo | Absent | ❌ |
| Left column content style | Animated role-selector typographic list | Plain checkmark list | ❌ |
| Section background | White | Light grey | ⚠️ |
| Text CTA link at bottom | Present ("Get in touch →" text link) | Absent | ❌ |

**Actionable fixes:**
- [ ] Apply a 2-column CSS Grid layout to this section (`grid-template-columns: 1fr 1fr`)
- [ ] Add a right-column image slot and populate with a lifestyle/team photo
- [ ] Add a text-link CTA below the checklist
- [ ] Set section background to `#fff`
- [ ] Consider a JS-driven type-cycling animation for the audience role list (or accept static as a PL adaptation)

---

## Panel 06 — Social Proof Section

**Reference**: `designs/06_graph_stocks.webp`

| What to check | Reference | Live | Gap? |
|---|---|---|---|
| Section present | Yes — large headline, graph widget, toggle | **Not present on live page at all** | ❌ |

**Actionable fixes:**
- [ ] Decide: implement a PL-equivalent social proof block (client logos, a stat, or a testimonial) or document as intentionally cut
- [ ] If implementing: a centered headline + stats widget or logo row would cover the structural pattern

---

## Panel 07 — FAQ

**Reference**: `designs/07_faq.webp`

| What to check | Reference | Live | Gap? |
|---|---|---|---|
| Section background | White (`#fff`) | Light grey (`~#f2f2f2`) | ⚠️ |
| Headline style | Large display / "FAQ" as the label, ~80–96 px | Standard H2, ~40 px | ⚠️ |
| Accordion expand icon | `+` (plus) | `∨` (chevron) | ⚠️ |
| Accordion divider lines | Light grey `1px` between items | Present | ✅ |
| Item count | 6 | 4 | ⚠️ |

**Actionable fixes:**
- [ ] Set FAQ section background to `#fff`
- [ ] Increase FAQ headline to display scale (`font-size: clamp(3rem, 6vw, 5rem)`)
- [ ] Swap accordion toggle icon from chevron to `+` / `×`
- [ ] Add 2 additional FAQ items to reach the reference's count of 6

---

## Panel 08 — Footer

**Reference**: `designs/08_footer.webp`

| What to check | Reference | Live | Gap? |
|---|---|---|---|
| Pre-footer CTA block | Present — dark bg, large headline ("Be the answer. Everywhere."), tagline, full width | Absent | ❌ |
| Footer background | Sky/cloud photo with dark overlay | Solid dark navy — acceptable PL adaptation | ⚠️ |
| "K" watermark | Giant typographic letterform, left side | Absent | ❌ |
| Link layout | 3-column labelled grid (Product / More / Company) | Single horizontal row | ❌ |
| Social icons | Right-aligned, icon-only | Right-aligned, text labels (LinkedIn / GitHub / Twitter) | ⚠️ |
| Copyright line | Present, bottom-left | Absent | ⚠️ |

**Actionable fixes:**
- [ ] Add a pre-footer CTA block above the footer bar (dark background, large headline, CTA button)
- [ ] Restructure footer links from a flat row to a 3-column labelled grid
- [ ] Add the "K" (or "PL") brand letterform as a CSS/SVG watermark behind the footer content
- [ ] Replace text social link labels with icon-only links
- [ ] Add a copyright line to the footer base

---

## Priority Order

| Priority | Panel | Fix |
|----------|-------|-----|
| 🔴 Now | 04 | Remove visible placeholder text from tab section |
| 🔴 Now | 04 | Add dashboard images to all three tab slots |
| 🟠 High | 00 | Add CTA button to header |
| 🟠 High | 01 | Add second (ghost) CTA button to hero; add hero illustration |
| 🟠 High | 08 | Implement multi-column footer + pre-footer CTA block |
| 🟠 High | 05 | Implement 2-column layout with right-side photo |
| 🟡 Medium | 01 | Increase hero headline size and weight; center-align text |
| 🟡 Medium | 02 | Switch feature cards to horizontal grid layout with image fill |
| 🟡 Medium | 03 | Implement horizontal scroll/carousel with image-background cards |
| 🟡 Medium | 06 | Add social proof block or document as cut |
| 🟢 Low | 07 | Background colour, display headline scale, `+` icon, 2 more items |
| 🟢 Low | 02–05 | Section backgrounds — grey → white |
