# `performant_labs_20260418` — Component Audit

> **Parent:** [`neonbyte-plan--components.md`](neonbyte-plan--components.md)
> **Source:** `performant_labs_20260411` overrides — inventoried 2026-04-18
> **Purpose:** Phase 1 output of Stage 2. Lists every component and CSS pattern that was developed in `20260411` and must be re-evaluated (and ported or improved) in `20260418`.

---

## How to use this document

For each item:
1. View the component in the SDC explorer under `?theme=performant_labs_20260411` (baseline)
2. View it under `?theme=performant_labs_20260418` (currently inherits neonbyte default)
3. Decide: **Port as-is | Improve | Drop**
4. Implement in `20260418` via `libraries-extend` or component bundle copy
5. Mark status and commit

---

## SDC Component Overrides

These components have dedicated CSS files in `20260411/components/`.

### `accordion`

| | |
|---|---|
| **File** | `components/accordion/accordion.css` |
| **Design intent** | Ultra-thin border rows, no background fill, `+` icon in amber |
| **Key rules** | `border-top: 1px solid #e5e7eb`, `border-radius: 0`, no `box-shadow`, `.accordion-item__icon { color: #F59E0B }` |
| **Override type** | CSS-only → use `libraries-extend` |
| **Status** | ⬜ Pending |
| **Decision** | Port / Improve / Drop |

---

### `content-card`

| | |
|---|---|
| **File** | `components/content-card/content-card.css` |
| **Design intent** | Elevated card — `box-shadow`, `border-radius: 1rem`, hover lift animation |
| **Key rules** | `box-shadow: 0 8px 32px rgba(0,0,0,.10)`, `transform: translateY(-2px)` on hover, `16:9` image aspect ratio, `.content-card__title { color: #1B2638 }` |
| **Override type** | CSS-only → use `libraries-extend` |
| **Status** | ⬜ Pending |
| **Decision** | Port / Improve / Drop |

---

### `tabs`

| | |
|---|---|
| **File** | `components/tabs/tabs.css` |
| **Design intent** | Underline-only active indicator — no boxed/pill tabs, amber bottom border |
| **Key rules** | `wa-tab::part(base) { border-bottom: 3px solid transparent }`, `wa-tab[active]::part(base) { border-bottom-color: #F59E0B }`, full-width images inside panes |
| **Override type** | CSS-only → Web Components `::part()` selector — use `libraries-extend` |
| **Status** | ⬜ Pending |
| **Decision** | Port / Improve / Drop |

---

## Global `base.css` Patterns

These are patterns in `css/base.css` that target layout sections, page-level contexts, or component variants. Grouped by the page section/slice they affect.

### Header — Slice 00

| Pattern | Selector | Intent | Status |
|---|---|---|---|
| Header CTA button | `.header-cta` | Amber pill button in header nav | ⬜ Pending |
| Sticky header base | `.site-header` | `position: sticky`, `z-index: 100`, scroll transition | ⬜ Pending |
| Transparent header (canvas/front) | `.canvas-page .site-header`, `.path-frontpage .site-header` | Header floats transparent over hero | ⬜ Pending |
| Opaque on scroll | `.site-header.is-scrolled` | `rgba(255,255,255,0.95)` + `backdrop-filter: blur(8px)` | ⬜ Pending |

---

### Hero — Slice 01

| Pattern | Selector | Intent | Status |
|---|---|---|---|
| Navy-to-amber gradient | `.hero.theme--primary::before` | `radial-gradient` from `#1e4a6b` → `#1B2638` → amber | ⬜ Pending |
| Hero background variable | `.hero.theme--primary { --hero-background }` | Sets base colour to `#1B2638` | ⬜ Pending |
| Hero media image positioning | `.hero__media img` | Absolute position, `inset-inline-end: -5%`, clipped with `border-radius` | ⬜ Pending |

---

### Buttons — Global

| Pattern | Selector | Intent | Status |
|---|---|---|---|
| Amber CTA button | `.button--cta` | `#F59E0B` fill, `#1B2638` text, `border-radius: 999px` | ⬜ Pending |
| Black pill button | `.button--pill-dark` | `#1B2638` fill, hover → amber, pill radius | ⬜ Pending |

---

### Carousel — Slice 03

| Pattern | Selector | Intent | Status |
|---|---|---|---|
| Horizontal snap scroll | `.carousel__track` | `overflow-x: auto`, `scroll-snap-type: x mandatory`, hidden scrollbar | ⬜ Pending |
| Card flex sizing | `.carousel__track > *` | `flex: 0 0 calc(25% - 1.125rem)`, `min-width: 260px` | ⬜ Pending |

---

### Icon List — Slice 05

| Pattern | Selector | Intent | Status |
|---|---|---|---|
| Amber checkmarks | `.icon-list .icon-list-item__icon` | `color: #F59E0B` | ⬜ Pending |

---

### Footer — Slice 08

| Pattern | Selector | Intent | Status |
|---|---|---|---|
| `K` watermark | `.site-footer::before` | Ghost letter, `font-size: clamp(16rem, 40vw, 32rem)`, `opacity: 0.04` | ⬜ Pending |
| Social icon row | `.footer-social-icons` | Flex row of circular icon links, amber on hover | ⬜ Pending |
| Footer CTA link | `.footer-cta__link` | Amber text link with animated gap on hover | ⬜ Pending |

---

### Page Layouts

| Pattern | Selector | Intent | Status |
|---|---|---|---|
| Canvas full-width | `.canvas-page .layout-container` | `max-width: none; padding-inline: 0` | ⬜ Pending |
| Docs two-column grid | `.docs-page .docs-layout` | `grid-template-columns: 260px 1fr`, sticky sidebar | ⬜ Pending |
| Docs responsive | `@media (max-width: 900px)` | Single column, sidebar un-stickied | ⬜ Pending |

---

## Twig Template Overrides

These templates exist in `20260411/templates/` and have no equivalent in `20260418` yet.

| Template | Path | Intent | Status |
|---|---|---|---|
| `node--article--teaser.html.twig` | `templates/content/` | Custom article teaser card layout | ⬜ Pending |
| `page--front.html.twig` | `templates/layout/` | Canvas front page — footer social icons injected into `footer_bottom` | ⬜ Pending |
| `page--documentation.html.twig` | `templates/layout/` | Documentation two-column layout with sidebar | ⬜ Pending |

---

## Priority Order for Stage 2

High-visibility items to tackle first:

1. **Hero gradient** (Slice 01) — most prominent, immediately visible
2. **Transparent sticky header** — affects every canvas page
3. **`content-card`** — used in carousel/features sections
4. **Amber CTA button** — used across CTAs
5. **`accordion`** — FAQ section
6. **`tabs`** — feature tabs section
7. **Page layouts** (canvas full-width, docs grid)
8. **Twig templates** — after all CSS is confirmed
9. **Footer patterns** (watermark, social, CTA)
