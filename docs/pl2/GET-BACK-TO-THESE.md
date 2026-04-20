# GET BACK TO THESE!

Deferred items — accessibility gaps, pending visual sign-offs, and architectural questions flagged during work but intentionally not fixed in the moment. Review and triage at the start of the next session; promote items into an active pass or close them out.

Created 2026-04-20 during the `articles-2` Canvas page work-stream.

---

## A. Accessibility advisories from `/articles-2` T2 audit (2026-04-20)

### A.1 — Heading hierarchy skip: `h1 → h3` inside the Articles Block view

**Observed:** On `/articles-2`, reading order goes `<h1>Articles</h1>` → `<h3>Version 1.0 of Automated Testing Kit Is Ready!</h3>` (first card) → further h3 cards → `<h4>Pagination</h4>`. No intermediate h2.

**Cause:** `canvas.component.block.views_block.articles-block_1.yml` sets `label_display: '0'` (block heading hidden), matching the four pre-existing `canvas.component.block.views_block.*.yml` entities. Card template (`dripyard_base:card`) renders title as h3.

**Why deferred:** Design/editorial choice, not a plumbing bug. Three fix options exist:
- a) Flip `label_display: '0'` → `'visible'` on the Canvas component entity or at the instance level; block label renders as h2. Cheapest.
- b) Drop a heading SDC above the view in the Canvas editor (e.g. `dripyard_base:heading` with level 2). More editorial control.
- c) Override the view's row template to render card titles as h2 instead of h3. Biggest ripple — affects every use of `dripyard_base:card` in a view-row context.

**Before fixing:** Check whether `/articles` (the existing Views Page display) already has the same h1→h3 skip. If so, consistency argument favors leaving both alone or fixing both together.

**Scope if fixed:** Single Canvas component config edit + `drush cim` + re-verify T1/T2.

### A.2 — `<h2>Main navigation</h2>` appears in DOM before `<h1>Articles</h1>`

**Observed:** First heading in reading order on every page is an h2 "Main navigation" (from the header nav block), before the page's h1.

**Cause:** Standard Drupal nav-a11y pattern — the header nav block renders a labeling h2 (likely `.visually-hidden`) so the `<nav>` landmark gets an accessible name.

**Why deferred:** Not introduced by Canvas work; it's site-wide and pre-existing. Common Drupal pattern accepted by most a11y auditors. Moving or removing it would risk breaking nav-landmark accessibility.

**When to revisit:** If a formal WCAG 2.4.6 audit (part of a pre-launch accessibility review) flags it. At that point, investigate whether it's truly `.visually-hidden` and whether a screen-reader test flags it as noise.

### A.3 — No `aria-current="page"` on active pager item

**Observed:** On `/articles-2`, the active pager `<li>` has class `pager__item--active` but no `aria-current="page"` attribute. Screen readers will not announce "current page" when navigating the pager.

**Cause:** Theme-level pager template gap. Likely affects every paginated listing on the site, not just `/articles-2`.

**Why deferred:** Not introduced by this work; site-wide; minor.

**When to revisit:** During an a11y pre-launch pass. Fix would be a template override — `pager.html.twig` (or equivalent in `dripyard_base`/`neonbyte`) that adds `aria-current="page"` on the `.is-active` item.

---

## B. Visual sign-off deferrals from `/articles-2` (2026-04-20)

### B.1 — T3 visual sign-off for `/articles-2` not yet taken

**Status:** T1 (curl) and T2-grep passed. Option B (Playwright install + T3 screenshots at desktop 1440 / mobile 375) was intentionally skipped to avoid the ~60s Playwright install overhead.

**When to revisit:** Before declaring the `articles-2` work-stream shippable for external review, or before merging to production. Specifically verify:
- Pass 2 atmospheric band renders (amber gradient + radial glow on `.block-page-title-block`).
- Pass 1 nav crossover works on this page (interior page, dark-navy nav text on light backdrop).
- Card grid spacing rhythm matches `/articles` (the existing Views Page display) for visual parity.
- Mobile: header clearance (`--space-for-fixed-header: 80px`) leaves the h1 appropriately clear of the sticky header.

**Follow `docs/ai_guidance/frameworks/drupal/theming/visual-regression-strategy.md` protocol.** Save screenshots to the workspace folder as `t3-articles-2-<viewport>-<date>.png`. Append findings to `visual-regression-report.md`.

---

## C. Architectural questions still open

### C.1 — Should `/articles` itself be migrated to Canvas?

**Context:** `/articles` is currently rendered by the Views Page display (`views.view.articles` `page_1`). It does not get `body.canvas-page`, so Pass 1 / Pass 2 chrome does NOT apply to it. `/articles-2` proves the Canvas + Views-block pattern works and inherits Pass 1/2 chrome for free.

**Options:**
- a) Migrate: delete or disable the Views page display, point `/articles` alias at a new Canvas page using the same Articles Block component. Gives `/articles` the chrome. Risk: redirects, SEO, any internal links assuming page-display behavior.
- b) Keep both: `/articles` stays as the Views Page display for continuity; `/articles-2` becomes the canonical going forward and `/articles` gets retired later.
- c) Retrofit: keep `/articles` as a Views Page but add a template-level `body.canvas-page` class for it so Pass 1/2 CSS applies. Risky — couples CSS to a non-Canvas route; defeats the point of the body-class key.

**Decision deferred to:** a product/content call, not a technical one. Flag during next review.

### C.2 — Should `canvas.component.block.page_title_block` be enabled in the Canvas picker?

**Current:** `status: false` in config. Canvas's auto-discovery disables core-provided blocks except a small whitelist. Currently the page-title-block renders automatically via a theme region — that's what Pass 2 CSS keys off.

**Why it might matter:** Future Canvas pages might want to place a page-title-block in a non-standard slot, or omit it entirely on specific pages (e.g. a landing page with a custom hero). That flexibility is unavailable while the component is hidden from the picker.

**Risk of enabling:** None I can see — the theme region continues to render it for pages that don't explicitly place one. Enabling only adds authoring flexibility.

**Scope if enabled:** Single edit (`status: false` → `status: true`) + `drush cim`. Verify no duplicate page-title-block renders on pages that inherit from a template placing one.

---

## Triage notes

Items in sections A and B are low-medium stakes, defer to pre-launch or a dedicated a11y/visual pass.
Items in section C are decisions, not bugs — they wait on product/content input.
Nothing here is blocking the merge of the `/articles-2` work-stream.
