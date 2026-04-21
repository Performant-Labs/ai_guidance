# `performant_labs_20260418` — Book Pages Plan

> **Parent:** [`neonbyte-plan.md`](neonbyte-plan.md)
> **Related:** [`neonbyte-plan--pages.md`](neonbyte-plan--pages.md), [`GET-BACK-TO-THESE.md`](GET-BACK-TO-THESE.md)

Work-stream plan for the book-node page type (`page-node-type-book`). Covers the book title page (`/automated-testing-kit`) and every interior book page (e.g. `/automated-testing-kit/introduction`). Created 2026-04-20 from the `/automated-testing-kit` + `/automated-testing-kit/introduction` audit.

---

## Entry Condition

- [x] Article-detail work-stream committed (commits include `article-full h5` styling, 16:9 hero guard, on-this-page TOC, Section E parking-lot notes — 2026-04-20)
- [x] `performant_labs_20260418` is the active default theme
- [x] `docs-layout` library and page template already in place (renders the `.docs-sidebar` + `.docs-content` grid for book nodes)
- [x] `easy_breadcrumb` module enabled (provides the breadcrumb trail implementation)

---

## Audit Summary (2026-04-20)

Two pages audited via T1 curl, T2 DOM/ARIA probe, T3 screenshots at 1440 + 390:

- `/automated-testing-kit` (title page): body node is **empty**; nothing below the h1 hero band except the "Submitted by" byline and the sidebar nav. User asked for "a title or something nice".
- `/automated-testing-kit/introduction` (interior): real prose body, but **no headings inside the content**, **no breadcrumb**, **no prev/next**, no active-item highlight in the sidebar.

Both pages share the same chrome: gradient hero band with oversize h1, then `.docs-layout` grid (260px sidebar + 985px content). Sidebar is Drupal's book-navigation block (19 links, sticky `top: 160px`, `is-active` class correctly set). On mobile the sidebar stacks **above** the content (19 links to scroll past before reading).

**Ranked findings — see the pass tables below for details:**

| # | Finding | Pass |
|---|---|---|
| F1 | "Submitted by Anonymous (not verified) on Thu, 1 Jun 2023" shows on every book page | 1 |
| F2 | No breadcrumb on book pages (block exists in config at `status: false`) | 1 |
| F3 | No prev/next book pager at the bottom of interior pages | 2 |
| F4 | Title page body is empty — needs a welcome / TOC / landing treatment | 3 |
| F5 | Active book-nav item in sidebar has no visible treatment (`is-active` class unused by CSS) | 1 |
| F6 | Mobile: 19-link sidebar stacks above content; reader has to scroll past the whole TOC | 4 |
| F7 | Hero band wastes ~450px of first screen on book pages (canvas chrome overkill for docs) | 4 |
| F8 | Sidebar `top: 160px` sticky offset is too far down on book pages (no canvas hero to compensate) | 4 |
| F9 | Interior "Introduction" body has no heading structure — editorial gap, not theme | 4 (editorial referral) |

---

## Pass 1 — Universal polish (hide submitted, breadcrumb, active sidebar item)

Small, universally-improves-every-book-page. No editorial decisions required. Lowest risk pass.

### 1.1 — Hide `node__submitted` for book nodes (F1)

**Why:** "Submitted by Anonymous (not verified) on Thu, 1 Jun 2023 - 11:13" rendering on every page is the single biggest visual offender. It appears in the content column where actual content should be.

**Approach options:**
- a) **Config path (preferred):** Edit the `full` view-display config for book nodes to set `display_submitted: false` on the content type. One yml edit in `config/sync/node.type.book.yml` (or whichever node-type config holds the flag) + `drush cim`. Trail-less fix — no CSS, no template.
- b) **CSS path:** Add `.node--type-book .node__submitted { display: none; }` in a subtheme component CSS. Cheapest if the config edit turns out to be tangled.

**Scope:** One config edit (preferred), or ~3 lines of CSS scoped to `.node--type-book`.

**Verification:** T3 at desktop + mobile on both title + interior — "Submitted by" band absent on both.

**Status:** ✅ Completed 2026-04-20 — flipped `display_submitted: true` → `false` in `config/sync/node.type.book.yml`; confirmed via T1 (grep count 0 on both pages) and user T3 signoff.

---

### 1.2 — Enable the breadcrumb block for this theme (F2)

**Why:** Books have clear hierarchy ("Home › Automated Testing Kit › Introduction"). Without a breadcrumb, readers on an interior page have no at-a-glance "where am I" signal except the sidebar's active item (which Pass 1.3 is fixing). Easy Breadcrumb is already enabled and its config looks right for URL-path-based trails.

**Approach:** Flip `status: false` → `status: true` in `config/sync/block.block.performant_labs_20260418_breadcrumbs.yml`. The block is already correctly scoped to the `highlighted` region, uses `system_breadcrumb_block` plugin (which Easy Breadcrumb hooks into), and has `label_display: '0'`.

```yaml
# current
status: false
region: highlighted
plugin: system_breadcrumb_block
```

**Scope:** One yml edit + `drush cim` + `drush cr`.

**Risk:** Low. `highlighted` is the standard breadcrumb region used by docs-layout. Breadcrumb will appear on **every page** that has the region — not just book pages. Intentional; worth confirming it looks right on canvas/front pages too.

**One wrinkle:** Easy Breadcrumb will derive middle segments from the URL slug ("Automated testing kit") rather than the book title's actual casing ("Automated Testing Kit"). If that's visible in T3, two fixes:
- Flip `capitalizator_mode: none` → `title` in `easy_breadcrumb.settings.yml`.
- Or populate per-node `field_breadcrumb_title` (already configured as the `alternative_title_field`).

**Verification:** T3 on title + interior + one non-book page (e.g. `/articles/version-10-automated-testing-kit-ready`). Breadcrumb visible on each, casing acceptable.

**Status:** ✅ Completed 2026-04-20 — flipped `status: false` → `true` in `config/sync/block.block.performant_labs_20260418_breadcrumbs.yml`; user T3 confirmed breadcrumb renders on title + interior + article pages with acceptable casing (no `capitalizator_mode` tuning needed).

---

### 1.3 — Active-item treatment in the sidebar book-nav (F5)

**Why:** The current page's `<a>` already carries `is-active` (confirmed in DOM on `/introduction` — "Introduction" link has `class="is-active"`), but there's no CSS rule targeting it. Readers can't tell at a glance which page they're on, which undermines the sidebar's orienting purpose.

**Approach:** Extend `css/layout/docs.css` with an active-link treatment. Pattern to match: the `article-toc__link.is-active` style we shipped in the article-detail work — left amber border + weight 500 + accent color. Keeps visual vocabulary consistent between the article TOC (right sidebar) and the book nav (left sidebar).

```css
/* Sketch — final values TBD */
.docs-sidebar .block-book-navigation .menu-tree a.is-active {
  color: var(--theme-text-color-accent, var(--color-primary-600, #b45309));
  font-weight: 500;
  /* left border flush with list indent */
}
```

**Scope:** ~10 lines in `css/layout/docs.css`.

**Verification:** T3 interior page — current item visibly distinct from its siblings; navigate to a second interior page and confirm the highlight moves.

**Status:** ✅ Completed 2026-04-20 — added Layer 5 rule `.docs-page .docs-sidebar .block-book-navigation a.is-active { color: accent; font-weight: 500; }` to `css/layout/docs.css`. Verified: no upstream conflict on `.menu-tree` / `.block-book-navigation`. User T3 confirmed active link is amber+bolder and the highlight moves as expected when navigating between chapters.

---

### Pass 1 commit point

After all three items land and verify:

```
git add config/sync/block.block.performant_labs_20260418_breadcrumbs.yml
git add config/sync/<node-type or view-display with display_submitted>
git add web/themes/custom/performant_labs_20260418/css/layout/docs.css
git commit -m "theme(book): hide submitted byline, enable breadcrumb, highlight active sidebar item"
```

---

## Pass 2 — Prev/next book pager (F3)

**Why:** Readers finishing a chapter have no "continue to next" affordance other than returning to the sidebar and hunting for the next link. Drupal's book module natively emits prev/next/up navigation — we just need to render it.

**Approach options:**
- a) **Block placement:** Place the core `book_navigation` block (the block plugin, not the currently-placed menu-tree block) in the `content` region below the node body, configured to show only on book nodes. Simple, no template edit.
- b) **Template path:** Override `node--book--full.html.twig` (or the page template) to render `{{ content.book_navigation }}` / `book_prev_page(node)` / `book_next_page(node)` directly below `{{ content }}`. More control over styling and placement.
- c) **Custom twig:** Build a small `neonbyte-plan--book-pages`-local twig template that renders prev/next as arrow-tile links matching docs-site conventions (title + chapter-number style).

**Recommendation:** Start with (a) for the functional win; if the visual result needs more work, promote to (b) or (c) in a follow-up pass. Keeps Pass 2 small.

**Scope:** One new block config yml + `drush cim`, plus any CSS polish once we see it render.

**Risk:** Low. Core-module behavior; pattern used by every Drupal book implementation. Confirm the block only shows on book nodes (visibility condition).

**Verification:** T3 on three interior pages — first chapter (no prev), middle chapter (prev + next + up), last chapter (no next). Prev/next links navigate correctly.

**Status:** ⬜ Not started

### Pass 2 commit point

```
git add config/sync/block.block.<book_navigation_block>.yml
git add web/themes/custom/performant_labs_20260418/css/components/book-pager.css  # if added
git commit -m "theme(book): add prev/next chapter pager below book node body"
```

---

## Pass 3 — Title page treatment (F4)

**Why:** `/automated-testing-kit` is currently an empty node — just the h1 hero, the "Submitted by" line (gone after Pass 1), and the sidebar. User asked for "a title or something nice". Three directions, cheapest first:

### 3a — Editorial welcome paragraph + CTA

Simplest. A content-editor pass: populate the node body with a short welcome paragraph and a "Start reading: Introduction →" link. Zero theme code. ~5 minutes of work in the Drupal UI.

**Scope:** Single node edit. No deployment.

**Verification:** T3 on title page — content visible; CTA works.

**Status:** ⬜ Not started

### 3b — Auto-rendered table of contents in the content column

Canonical docs-home pattern. Render the book's chapter list as a card grid or numbered list in the main content column. Duplicates the sidebar TOC but promotes it to primary content on the title page.

**Approach:** Template override on the title page (or a Canvas component, if we want to go that route) that calls `book_toc()` / reads `node.book` and renders chapters as content-cards. Could reuse the existing `dripyard_base:content-card` SDC for visual consistency.

**Scope:** One template + one component CSS file. Medium.

**Risk:** Title-page-only logic needs a clean scope guard (only render when viewing the top-level book node, not on children). Easy to get wrong — could accidentally duplicate the TOC on every page.

**Verification:** T3 title page — chapter grid renders; T3 on three interior pages — no chapter grid (confirms scope guard).

**Status:** ⬜ Not started

### 3c — Hero-style overview with feature bullets + CTAs

Biggest lift, most polish. Treat the book title page as a landing page: short value-prop, 3–5 feature bullets, CTAs to Introduction / Quickstart / Contributing. Could be built as a Canvas page that replaces the book-node title page (alias `/automated-testing-kit` points to a Canvas page, and the sidebar still renders via the book structure).

**Scope:** Content-design work + Canvas page assembly (see [`neonbyte-plan--pages.md`](neonbyte-plan--pages.md) Phase 2 for the scripting protocol) + routing decision (replace book title node, or add a new Canvas landing in front).

**Risk:** Architectural — if we swap the title-page route, the book hierarchy in the sidebar may need to be rebuilt to point at the new Canvas page. Defer unless the simpler options are ruled out.

**Verification:** T3 title page at 1440 + 390; compare to reference docs landing pages (Drupal Cms, Storybook, etc.).

**Status:** ⬜ Not started (awaiting product direction)

### Pass 3 decision checkpoint

- [ ] Discuss a / b / c with product/content owner
- [ ] Pick one; close the other two or move to GET-BACK-TO-THESE

---

## Pass 4 — Polish & layout refinements

### 4.1 — Mobile: reorder sidebar below content (F6)

**Why:** On viewports <900px the `.docs-layout` grid collapses to single-column and renders `.docs-sidebar` before `.docs-content`. A reader opening the Introduction has to scroll past 19 chapter links before the prose starts.

**Approach options:**
- a) **CSS reorder:** `.docs-sidebar { order: 2 }` on `.docs-page` at mobile breakpoint. Content first, nav after. Simple, works with existing DOM.
- b) **Collapse nav into `<details>`:** Wrap the sidebar block in a `<details><summary>Table of contents</summary>` via a template override. Nav becomes a disclosure above the content — one tap opens it. Matches Drupal.org docs pattern.
- c) **Off-canvas drawer:** Nav slides in from left on a toggle button; content is always primary. Most polish, most code.

**Recommendation:** (a) for Pass 4; promote to (b) if a `<details>` control reads better in T3.

**Scope:** Few lines in `css/layout/docs.css`.

**Verification:** T3 mobile on interior — content-first; sidebar reachable by scroll or disclosure.

**Status:** ⬜ Not started

### 4.2 — Tighter hero band on book pages (F7)

**Why:** The canvas-page hero band (big h1 on gradient, ~450px tall) is overkill for a docs book. Book readers want to read; wasting the first screen on a restatement of what they clicked is a usability tax. A compact page-title treatment would surface ~150px more real content above the fold.

**Approach:** Body-class-scoped override: `.page-node-type-book .block-page-title-block { /* compact treatment */ }`. Smaller h1, no gradient band, tighter padding. Keep a visible page-title but right-size it for docs.

**Scope:** ~15 lines in a new `css/components/book-page-title.css` (or folded into `canvas.css` if that's the shared home for page-title chrome).

**Risk:** Must be careful to not break other uses of `.block-page-title-block` on Canvas or article pages. Body-class scope is the guard.

**Verification:** T3 title + interior at 1440 + 390. Compare above-the-fold content between before/after.

**Status:** ⬜ Not started

### 4.3 — Sidebar sticky-top fine-tune (F8)

**Why:** `top: 160px` (via `--space-for-fixed-header: 160px`) leaves a large empty band above the sidebar on scroll. The 160px value was chosen for canvas pages where the hero chrome consumed that space; book pages don't have the same chrome. ~80–100px feels more natural.

**Approach:** Override `--space-for-fixed-header` on `.page-node-type-book` (and maybe `.page-node-type-article`) in `css/layout/canvas.css` — matches the existing pattern where the value is already set per-route (canvas pages get 160, others get narrower).

**Scope:** One rule in `canvas.css`.

**Risk:** Don't accidentally break canvas pages or the article-TOC sticky-top (which also consumes this var). Scope tightly.

**Verification:** T3 interior — scroll partway; sidebar sits closer to the header.

**Status:** ⬜ Not started

### 4.4 — Editorial referral: heading structure inside interior bodies (F9)

**Why:** The Introduction body is a wall of paragraphs with no h2/h3 — the on-this-page TOC pattern we built for articles can't apply here, and long pages without structure are harder to skim. This is editorial work, not theme.

**Approach:** Flag to the content owner: add h2 section breaks to the Introduction (and audit the other 18 book pages). If they cooperate, the article-TOC pattern could be applied to book pages as a follow-up.

**Scope:** No theme change in this pass. Adds a row to GET-BACK-TO-THESE.md if not fixed quickly.

**Status:** ⬜ Not started (deferred to content owner)

### Pass 4 commit points

One commit per sub-item as they land; grouping optional.

---

## Open Questions

- **Canvas chrome vs. docs chrome:** Should book pages continue to inherit `.canvas-page`-style hero treatment, or is the goal a fully distinct "docs" visual identity? Pass 4.2 nudges toward distinct; bigger-scope decision is whether to formalize a "docs" body-class chrome in layer 2.
- **Sidebar breadcrumb duplication:** Once Pass 1.2 (breadcrumb block) lands, the interior page will show both a breadcrumb at the top *and* a sidebar TOC showing the same hierarchy visually. Acceptable? Probably — breadcrumb is a pointer to ancestors; sidebar is siblings — but worth T3-verifying they don't fight.
- **Prev/next within a chapter with sub-pages:** The Automated Testing Kit book is currently flat (all 19 pages are children of the title page). If nested chapters are added later, the core `book_navigation` prev/next semantics handle it but the `up` link becomes more visible in UX — plan for that or defer.

---

## Verification Protocol

Follow [`visual-regression-strategy.md`](../ai_guidance/frameworks/drupal/theming/visual-regression-strategy.md) once it exists. Until then: per-pass T1 → T2 → T3 at desktop 1440 and mobile 390 on:

- `/automated-testing-kit` (title)
- `/automated-testing-kit/introduction` (interior, first chapter — prev-less edge case)
- `/automated-testing-kit/troubleshooting-and-known-issues` (interior, last chapter — next-less edge case)
- `/automated-testing-kit/running-tests` (interior, middle — both prev and next)
- Screenshots saved as `t3-book-<slug>-<viewport>-<YYYYMMDD>.png`.

---

## Sign-off

- [x] Pass 1 complete + committed (2026-04-20)
- [ ] Pass 2 complete + committed
- [ ] Pass 3 path chosen + committed
- [ ] Pass 4 items either landed or promoted to GET-BACK-TO-THESE
- [ ] Re-audit pass: T1 → T2 → T3 on all four verification URLs
- [ ] Updated `GET-BACK-TO-THESE.md` with anything deferred

---

## Change Log

- 2026-04-20 — plan created from the `/automated-testing-kit` + `/automated-testing-kit/introduction` audit
