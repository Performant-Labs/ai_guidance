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

## D. Site-wide visual issues

### D.4 — Confirm all interior pages have breadcrumbs (2026-04-20)

**Observed:** Pass 1.2 of the book-pages work-stream enabled the breadcrumb block on `/automated-testing-kit` and its interior children. Breadcrumb rendering was verified on book pages only. Other page types on the site (Canvas pages like `/contact` / `/articles-2` / `/open-source-projects`, article detail pages like `/articles/version-10-automated-testing-kit-ready`, Views pages like `/articles`, and any node types we haven't audited) have not been explicitly confirmed.

**Why it matters:** Breadcrumbs are a site-wide wayfinding and WCAG 2.4.8 affordance. If the block is placed only in the region/theme path that renders for book pages, or only appears where Easy Breadcrumb's rules are satisfied, interior pages of other types may silently lack breadcrumbs.

**When to revisit:** During the next a11y pass, or before shipping for external review. Cheapest check: a scripted curl across a representative URL per page type (book interior, Canvas page, article detail, Views page, user-facing account page, …) grep'ing for `<nav … aria-label="breadcrumb">` or the `.breadcrumb` DOM hook.

**Scope if a page type is missing breadcrumbs:** One of:
- a) Widen the breadcrumb block placement (block UI or `block.block.*.yml` config).
- b) Adjust Easy Breadcrumb settings (`easy_breadcrumb.settings.yml`) if a rule is excluding the page.
- c) Template-level fix if a page-level twig suppresses the region.

### D.3 — 6px title-vs-content horizontal misalignment on Canvas pages (2026-04-20)

**Observed:** On every Canvas page (`/contact`, `/articles-2`, `/open-source-projects`, etc.) at mobile (375px) and on up, the page `<h1>` is inset **20px** from the viewport edge while the content below it — form, views block, card grid, prose — is inset **~14px** (a fractional value from auto-centering). Visible as a small leftward "tuck" between the title and the content stacked beneath it.

**Cause — two different gutter owners:**

- **Title band** (`.block-page-title-block`): padding-inline comes from Pass 2 in `css/layout/canvas.css` and resolves to `var(--spacing-xs, 1.25rem)` = **20px** at <601px viewport.
- **Content** (`.dy-section__container.container` inside a Canvas-placed Basic Section): gutter comes from Dripyard's `.container` class (upstream) which sets a `max-width` and centers via `margin-inline: auto`. At 375px viewport the math works out to **~13–14px** auto-margin on each side — not a token, a byproduct.

The two paddings are declared in different places with different semantics (authored spacing token vs. leftover viewport space from max-width centering), so they don't agree.

**Why deferred:** Not a regression — this misalignment pre-existed the mobile-spacing work and was only made visible once we committed to the "single gutter owner per Canvas page" architecture (Path 1). A few possible reconciliations, each with trade-offs:

- a) **Retune Pass 2** to match Dripyard's `.container` gutter — swap `var(--spacing-xs, 1.25rem)` for the same value `.container` produces. Risk: `.container` is a viewport-derived value, not a fixed token, so "matching" it means either computing or hardcoding. Hardcoding couples Pass 2 to an upstream value we don't own.
- b) **Retune Dripyard's `.container`** (via subtheme override) to emit `padding-inline: var(--spacing-xs)` at mobile instead of auto-margins. Matches tokens exactly; pulls the gutter contract into our subtheme. Risk: `.container` is used in many places by Dripyard, and an override could ripple into non-Canvas contexts.
- c) **Wrap the title in a Basic Section** in the same way content is, so h1 and body share one gutter owner. Matches Canvas composition theory; changes authoring workflow (h1 would need to live inside a section component rather than render from the Drupal page-title region).
- d) **Accept the 6px discrepancy** as a minor visual imperfection; most visitors won't notice. Cheapest; trades pixel perfection for architectural calm.

**When to revisit:** During a dedicated spacing/design-tokens reconciliation pass, or if the visual offset becomes a user-visible complaint. Verify by T3 at 375/1440 on at least `/contact`, `/articles-2`, `/open-source-projects` — confirm h1 x-offset equals content-first-element x-offset.

**Scope if fixed via (a):** Single Pass 2 edit + `drush cr` + re-verify.
**Scope if fixed via (b):** Subtheme CSS override of `.container` + re-verify every page that uses `.container` (more than just Canvas pages).
**Scope if fixed via (c):** Editorial change on every Canvas page (one-time content edit per page) + verify title band visual chrome still reads correctly when emitted from a Basic Section wrapper instead of the theme region.

### D.2 — FriendlyCaptcha sitekey appears unresolved on `/contact` (2026-04-20)

**Observed:** During T3 verification of the new `/contact` Canvas page, the rendered FriendlyCaptcha markup contains a literal `${site_uuid}` token rather than a real sitekey:

```html
<fieldset data-drupal-selector="edit-captcha" class="captcha captcha-type-challenge--friendlycaptcha" data-nosnippet>
  ...
  <div class="frc-captcha" data-sitekey="${site_uuid}" data-lang="en" data-puzzle-endpoint="https://.../api/v1/puzzle">
```

**Hypothesis:** The FriendlyCaptcha module expects a configured sitekey at `/admin/config/people/captcha/friendlycaptcha` (or via the `captcha.settings` / FriendlyCaptcha-specific config). The `${site_uuid}` literal suggests a default/placeholder value shipped with the `drupal_cms_anti_spam` recipe that was never substituted for a real FriendlyCaptcha tenant key. With an invalid sitekey, the captcha challenge likely fails to initialize, which means the form's spam protection may not actually be challenging submissions — it's relying on honeypot alone.

**Why deferred:** Not a page-breaking bug (form still submits, honeypot still works), but anti-spam posture is weaker than intended. Fixing requires obtaining a real FriendlyCaptcha sitekey from the Performant Labs FriendlyCaptcha account and entering it through the admin UI (or updating `captcha.captcha_point.*` / FriendlyCaptcha config in sync).

**When to revisit:** Before relying on `/contact` in production, or as part of a broader spam-protection pass. Verify by inspecting the rendered captcha on `/contact` and confirming `data-sitekey` contains a concrete UUID-like value, then submitting a test message and watching the FriendlyCaptcha admin dashboard for a puzzle event.

**Scope if fixed:** Admin config change + re-export `captcha.*.yml` config + `drush cim` + T3 re-verify.

### D.1 — Header logo not visible on any page (2026-04-20) — resolved, branding decision still open

**Status:** Visibility fix shipped 2026-04-20 via explicit SVG dimensions (commit `10f033d`). The entry is retained only for the outstanding **branding decision**: current SVG is a generic "KEYTAIL" placeholder (navy square, amber K) rather than Performant Labs branding. Replace with the real Performant Labs mark when design provides it.

**Original (resolved) bug — for audit trail:** User reported the upper-left logo (intended to be the home link on every page) was not visible on any page. Not just `/articles-2` or `/open-source-projects` — everywhere.

**DOM/asset audit is clean:**
- `<div data-component-id="dripyard_base:header-logo">` present in every page's `<header>` region
- Anchor wraps with `<a href="/" rel="home">` — correct semantics
- Asset `logo.svg` returns HTTP 200 from nginx (421 bytes, valid SVG markup)
- No filter / opacity / display-none rule in `dripyard_base/components/header-logo/header-logo.css` (only `max-height: 44px`) or in subtheme CSS
- Header background on interior Canvas pages is 55%-amber fill (per canvas.css Pass 1 notes); against that backdrop a navy-square logo should read clearly

**Primary hypothesis — SVG intrinsic-size collapse:**
The SVG declares `width="100%" height="100%"` rather than a concrete size. Used via `<img src="logo.svg">`, some browsers fall back to 0×0 or to the parent's (undefined) width when the SVG uses percentage dimensions without an intrinsic pixel size. The `.header-logo__link` has `display: block` but no explicit width; `.header-logo__image` has only `max-height: 44px`. If intrinsic width resolves to 0, the logo renders at 0×0 and appears absent even though the DOM is correct.

**Secondary hypothesis — placeholder content:** Current SVG is a generic "KEYTAIL" mark (navy square, amber K, white KEYTAIL label) rather than Performant Labs branding. Even if sized correctly, the user may be looking for a different glyph.

**When to revisit:** Next session or this session with explicit go-ahead. Run T3 screenshots at desktop 1440 / mobile 375 on /, /articles-2, /open-source-projects to see exactly what renders. Likely fix is one of:
- a) Edit `logo.svg`: replace `width="100%" height="100%"` with `width="100" height="100"` (intrinsic size matches viewBox). Cheapest. Should resolve intrinsic-size issue immediately.
- b) Add explicit width rule: `.header-logo__image { width: auto; height: 44px; }` in subtheme CSS. Forces concrete sizing regardless of SVG attributes.
- c) Replace the SVG entirely with the real Performant Labs logo — solves (D.1) and the branding concern at once.

**Verification after fix:** T3 screenshot of any page — upper-left should show the logo as a 44px-tall clickable element linking to `/`.

---

## E. Article detail page findings (2026-04-20)

From the `/articles/version-10-automated-testing-kit-ready` audit. Three issues were resolved in this session and are listed at the bottom for reference. Remaining items below are deferred.

### E.1 — Heading hierarchy inside the article body is all `<h3>`, no `<h2>`

**Observed:** The article `/articles/version-10-automated-testing-kit-ready` contains 12 section headings, all `<h3>`. The only higher-level heading in reading order is the article `<h1>` (title). There is no `<h2>` anywhere in the body. The h3 chain continues with `<h5>` elements nested under them (the `@alters-db` / `@smoke` / … labels).

**Cause:** Editorial, not template. The WYSIWYG editor is offering h2/h3/h4/h5 freely and content editors have consistently picked h3. Matches the pattern found in **A.1** (the `/articles-2` views block also emits h3 cards with no intervening h2).

**Why deferred:** Editorial fix, not a plumbing change. Also: the "On this page" TOC implemented in this session works fine across a flat h3 list, and upgrading the first-level body headings from h3 → h2 will need an editorial review of every article at once so the TOC nesting stays sensible.

**Before fixing:** Decide whether the Article content type should enforce h2 as the first body-level heading (via text-format filter or editorial guideline). Survey the other articles to see whether any are already using h2.

**Scope if fixed:** Content-editor pass on every article node (batch find-and-replace across `node.*.body` might work if WYSIWYG is using consistent markup, otherwise per-article manual). No code change required.

### E.2 — `.header-article` wrapper has `margin-inline: -14.4062px 0`

**Observed:** The `.header-article` element (neonbyte SDC) renders with `margin-inline: -14.4062px 0` — a sub-pixel negative value pulling the hero to the left of its container.

**Cause:** Neonbyte's header-article component sets `margin-inline-start: calc(50% - 50cqw)` or similar to break out of the content container. The fractional px is a layout-math byproduct, not an authored value. The right side is 0 (not balanced), which creates an asymmetric break-out.

**Why deferred:** Visually minor — at most viewports the hero still fills the viewport width and the imbalance reads as "close enough". Not a regression; it's been there since the neonbyte install. Fixing it requires an override of the upstream break-out formula, which might ripple into other header-article consumers.

**When to revisit:** If design surfaces the asymmetry as a visual complaint, or during a pass that addresses page-break-out math generally.

**Scope if fixed:** Subtheme override of `.header-article` margin rule — set both sides explicitly (e.g. `margin-inline: auto`) or recompute the break-out with symmetric math. Small CSS, easy to reason about.

### E.3 — No kicker/byline/date rendered in the article hero

**Observed:** The article hero shows only the title and the hero image. There is no category pill/kicker, no byline, no publication date displayed to the reader.

**Cause:** Two contributing factors:
- `display_submitted` on the Article content type (or on the `full` view mode) is likely false, suppressing the `By {{ author_name }} on {{ date }}` block that the `header-article` embed would otherwise render (see the `meta_content` block in `node--article--full.html.twig` at lines 84–89).
- `field_tags` are rendered into the hero as the `tags` slot but may be empty on individual articles.

**Why deferred:** Editorial/design decision: does Performant Labs want a visible byline and date on articles? Some content strategies omit them deliberately (perceived-evergreen content); others consider them credibility signals. A kicker/category in the hero would also need a field decision (reuse `field_tags`? add a `field_category`?).

**When to revisit:** During a content-model review or when the article page design gets a formal revisit. If enabled, the existing template slots will handle it — just toggle `display_submitted` and verify hero layout still holds.

**Scope if enabled:** Config edit (`display_submitted: true` on `node.type.article` and/or `core.entity_view_display.node.article.full`) + `drush cim` + T3 re-verify that the hero meta band reads correctly against the dark gradient.

### E.4 — Focal-point image styles named "16:9" actually render 5:3

**Observed:** The Dripyard focal-point image style suite ships entries whose machine names / labels imply 16:9 (e.g. `focal_point_16_9_*`) but whose effect chain is configured for a 5:3 crop. When `field_image` on articles was originally displayed via a plain `image.style.large`, the upscaling issue in **Issue C** (fixed this session) was magnified by the square source image; the focal-point styles would have added a second layer of mismatch if they had been selected.

**Cause:** Upstream Dripyard config — the style's crop action uses 1000×600 or 800×480 dimensions (5:3 = 1.67) rather than 1600×900 or 1280×720 (16:9 = 1.78). Either the labels are wrong or the crops are wrong; the two don't match.

**Why deferred:** Not a live bug — the article full display was switched to a clean `16_9_wide` responsive image style this session, so no article currently consumes the mis-labeled focal-point styles. But future content editors who see a style named "focal_point_16_9" and expect 16:9 output will be confused.

**When to revisit:** Either rename the styles (cheapest, editorial) or re-crop them to true 16:9 (more ripple — existing images referenced via these styles would re-render at new dimensions). Choice depends on whether any current image usage relies on the 5:3 actual output.

**Scope if renamed:** `image.style.focal_point_16_9_*.yml` label edit + machine-name considerations + `drush cim`.

### E.5 — Audits not yet performed on article detail pages

These passes are valuable but scoped out of the current session. Listed here so they don't get forgotten.

- **SEO meta.** `<title>`, `meta description`, canonical URL, Open Graph and Twitter card tags. Verify via curl/headless — confirm each article node emits a usable OG image (likely the `field_image` rendered through a dedicated OG-sized style), a description field (either `body` summary or a dedicated `field_seo_description`), and a canonical URL that resolves to the article's own path.
- **Color contrast (WCAG 2.1 AA).** Body text, link color, code block fg/bg, TOC active-link amber against white sidebar, h5 amber-monospace against body. Spot check with a tool like axe or the contrast ratio math; flag anything below 4.5:1 for body or 3:1 for large text.
- **Keyboard navigation.** Tab through the page — order should flow header → main content → TOC → footer; focus indicators visible on every interactive element; TOC links reachable and activating on Enter. Verify no keyboard trap in embedded code fences or any interactive widgets.
- **Performance.** Lighthouse run at mobile/desktop on at least two articles. Watch for LCP (likely the hero image — verify the 16:9 derivative picked is the correct size for the viewport), CLS (hero `aspect-ratio` fix should resolve it but confirm), and JS bundle cost of the newly-added `article-toc.js`.
- **Print stylesheet.** Browser print preview a long article. Current state will likely show the header/nav and footer in the printed output, which wastes paper. A `@media print` rule in the article-full library could hide nav/footer/TOC and widen the content column. Low priority but easy win.

### E.6 — Resolved this session (reference)

Listed for audit trail; no further action needed.

- **(B)** `<h5>` tags inside `.article-full .node__content` now render as monospace amber code-identifier labels, restoring visual hierarchy for code-annotation terms (`@alters-db`, `@smoke`, `@skip`, …). `css/components/article-full.css` at (0,3,1) via `article-full-override` library.
- **(C)** Hero image on article full display switched from `image.style.large` to `responsive_image_style.16_9_wide`, and a CSS guard (`.header-article__image img { aspect-ratio: 16/9; object-fit: cover; height: auto; }`) prevents 480×480 source uploads from rendering as 1800×1080 upscale squares. Desktop page height dropped ~1,620px; mobile picks a correct-sized derivative.
- **"On this page" TOC.** `js/article-toc.js` scans h2/h3 in `.grid-area--content`, assigns slug IDs, builds a sticky right-column nav. `css/components/article-toc.css` overrides neonbyte's `.grid` at >=1024px so sidebar-second always renders; hidden below that breakpoint. IntersectionObserver drives active-link amber highlight.

---

## F. Book pages deferrals (2026-04-20)

From the `/automated-testing-kit` (title) + `/automated-testing-kit/introduction` (interior) audit and Pass 2 implementation. See [`neonbyte-plan--book-pages.md`](neonbyte-plan--book-pages.md) for the full work-stream.

### F.1 — Book prev/next/up nav renders with browser-default styling

**Observed:** After Pass 2 of the book-pages work (added `book_navigation_without_tree` to the `node.book.default` view display), interior book pages now render a `<nav aria-label="Book traversal links for ...">` below the body content, containing prev/up/next `<a>` elements wrapped in `<li class="book-traversal__item">`. Currently presents as a plain bulleted list with default link colors and no horizontal rhythm.

**Why deferred:** Functional win landed; visual polish wasn't part of the Pass 2 scope and editorial/design direction isn't yet set. User signed off on the unstyled render at Pass 2.

**Polish options when resumed, cheapest → richest:**
- a) **Inline row + thin top border.** Hide `<li>` bullets, set the `<ul>` to `display: flex; justify-content: space-between`, top border separating the nav from the body. ~15 lines of CSS, matches the understated docs aesthetic.
- b) **Arrow-tile treatment.** Prev on the left, Up centered, next on the right; amber hover; heavier weight for the chapter titles. The `rel="prev"` / `rel="next"` attributes make this selector-friendly.
- c) **Full prev/next cards.** Two equal-width tiles below the body reading "← Previous: Introduction" and "Next: Frequently Asked Questions →", chapter titles bold; Up link as a small text link above or inline with the breadcrumb. Richest look; more CSS; may need a template tweak to get the "Previous:" / "Next:" labels added (currently just `<b>‹</b>` / `<b>›</b>` glyphs from the core template).

**Scope if fixed via (a):** One new file `css/components/book-pager.css` + library entry + libraries-extend mapping (or add to `docs.css` if that's the shared home for docs-page polish).

**Scope if fixed via (b) or (c):** Same structure, more CSS; (c) may also want a `node--book--full.html.twig` (or a `book-navigation.html.twig`) override for the prepended labels.

**Verification:** T3 at desktop + mobile on first/middle/last chapter. Confirm prev/next links read clearly, don't collide with footer, match the "docs" visual vocabulary used elsewhere in this theme (amber accent, understated borders).

### F.2 — Hero body not yet authored on 5 of 6 book roots

**Observed:** Pass 3.A.3 wired `hook_theme_suggestions_node_alter()` to apply `node--book--landing.html.twig` to **every** book root (any node where `bid === nid`). The site currently has six book roots:

| nid | Title                    | Path                                  |
| --- | ------------------------ | ------------------------------------- |
| 18  | Layout Builder Kit       | `/layout-builder-kit` (or alias)      |
| 19  | Campaign Kit             | `/campaign-kit` (or alias)            |
| 20  | Automated Testing Kit    | `/automated-testing-kit`              |
| 21  | Automated Testing Kit D7 | `/automated-testing-kit-d7` (or alias)|
| 22  | Configuration            | `/configuration` (or alias)           |
| 23  | Testor                   | `/testor` (or alias)                  |

Only node 20 has the hand-authored hero body (the seven-block structure: eyebrow `<p><strong>…</strong></p>` → value-prop `<h2>` → lede `<p>` → CTA row `<p>` with 2–3 `<a>` → "What's inside" `<h2>` → features `<ul>` → trailing caveat `<p><em>…</em></p>`). The other five will now also get wrapped in `.book-landing` and hit the positional CSS in `css/components/book-landing.css`, but their bodies won't match the expected structure so selectors will miss their targets — likely rendering a random oversized first-paragraph treatment and no styled CTAs.

**Why deferred:** Option #3 (author matching hero bodies for all five) is an editorial task, not a plumbing one — copy for each kit needs product input. User explicitly parked this to come back and fill in the five pages.

**When to revisit:** Before the book-pages work-stream is considered shippable for external review. Until then, either:
- Accept that nodes 18, 19, 21, 22, 23 will render oddly (acceptable if they're not being linked-to yet), or
- Temporarily narrow the hook to nid 20 only as a stop-gap (hard-codes a nid into the theme — fragile).

**Scope when resumed:** Editorial — paste a hero body matching the seven-block structure into each of the five remaining book roots via the node edit UI. No code change required. Copy template available on node 20 as a reference. Verify T3 on each URL after populating.

**See:** `neonbyte-plan--book-pages.md` Pass 3.A for the authored-content contract.

### F.3 — Mobile T3 sign-off for `/automated-testing-kit` not captured (2026-04-20)

**Observed:** Pass 3.A.3 closed out with desktop T3 (1440 viewport) verified in Chrome — primary CTA visible (white on amber), secondaries outlined, hero structure rendering correctly. Mobile T3 at 375 viewport could not be captured in-session because the Chrome-extension `resize_window` call succeeded at the browser-chrome layer but the rendering viewport stayed at the host window's width (`window.innerWidth` remained 1728 after a resize call that reported success).

**Why deferred:** The mobile CSS path in `css/components/book-landing.css` is simple — `@media (min-width: 640px)` switches the features list to a 2-column grid; below that it's a 1-column stack. CTA row uses `flex-wrap: wrap`. No complex responsive behavior to regress.

**When to revisit:** Next session, via Chrome DevTools device toolbar manually, or any tool that can genuinely emulate a 375px viewport. Verify:
- Eyebrow / h2 / lede / CTA row stack cleanly and remain readable.
- CTA row wraps to a column without awkward truncation.
- "What's inside" features list renders as a single column.
- No horizontal overflow from the value-prop h2 or any long anchor label.

**Scope if a regression is found:** Narrow CSS tweak in `book-landing.css` media-query blocks.

---

## Triage notes

Items in sections A and B are low-medium stakes, defer to pre-launch or a dedicated a11y/visual pass.
Items in section C are decisions, not bugs — they wait on product/content input.
Item D.1 is a site-wide visible-chrome bug — promote before next external review. (Resolved 2026-04-20 via `logo.svg` intrinsic-size fix; leaving entry for reference until branding/placeholder decision is final.)
Item D.2 is a spam-protection concern on `/contact` — resolve before the form goes live for public traffic.
Item D.3 is a small visual alignment issue revealed by Path 1 (Dripyard-owns-the-gutter). Pre-existing, low-stakes — resolve during a dedicated spacing reconciliation pass if at all.
Item D.4 is a site-wide breadcrumb verification task — fold into the next a11y pass or run as a scripted check before external review.
Section E items are deferred article-detail-page issues. E.1 and E.3 are editorial decisions; E.2 is a minor visual imperfection; E.4 is a naming/config mismatch that will bite later content editors; E.5 lists unperformed audits.
Section F tracks book-pages polish that was intentionally deferred from the Pass 2 functional landing. See `neonbyte-plan--book-pages.md` for the active work-stream. **F.2** is an editorial follow-up from Pass 3.A.3: five book roots need hero bodies authored so they don't render oddly under the new `node--book--landing.html.twig` template. **F.3** is the mobile T3 sign-off for `/automated-testing-kit` — low risk, worth knocking out at the start of the next session.
Nothing here is blocking the merge of the `/articles-2` work-stream or the article-detail improvements landed this session.
