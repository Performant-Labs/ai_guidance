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

### D.1 — Header logo not visible on any page (2026-04-20)

**Observed:** User reports the upper-left logo (intended to be the home link on every page) is not visible on any page. Not just `/articles-2` or `/open-source-projects` — everywhere.

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

## Triage notes

Items in sections A and B are low-medium stakes, defer to pre-launch or a dedicated a11y/visual pass.
Items in section C are decisions, not bugs — they wait on product/content input.
Item D.1 is a site-wide visible-chrome bug — promote before next external review. (Resolved 2026-04-20 via `logo.svg` intrinsic-size fix; leaving entry for reference until branding/placeholder decision is final.)
Item D.2 is a spam-protection concern on `/contact` — resolve before the form goes live for public traffic.
Item D.3 is a small visual alignment issue revealed by Path 1 (Dripyard-owns-the-gutter). Pre-existing, low-stakes — resolve during a dedicated spacing reconciliation pass if at all.
Nothing here is blocking the merge of the `/articles-2` work-stream.
