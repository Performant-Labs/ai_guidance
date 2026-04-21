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

**Status:** ✅ Completed 2026-04-20 (functional) — took a different path from (a)/(b)/(c) once tracing revealed the book module's extra-field mechanism. Added `book_navigation_without_tree` to the `node.book.default` view display at `region: content, weight: 110`. This flips the book-module's `book_node_view` hook to inject the prev/next/up render array (was previously suppressed because neither `book_navigation` nor `book_navigation_without_tree` was present in the display config — see `BookHooks.php:183`). `_without_tree` variant chosen so we don't duplicate the full book TOC that the sidebar already renders. T1 confirmed `<nav aria-label="Book traversal links for ...">` with correct prev/up/next on interior pages. Drupal treats the book root as the predecessor of the first chapter — that's expected behavior, not a bug.

**Visual state:** Currently browser-default styling (plain `<ul>`). User signed off at this stage. Amber pill/arrow-tile polish deferred to Pass 2b if/when desired.

### Pass 2 commit point

```
git add config/sync/block.block.<book_navigation_block>.yml
git add web/themes/custom/performant_labs_20260418/css/components/book-pager.css  # if added
git commit -m "theme(book): add prev/next chapter pager below book node body"
```

---

## Pass 3 — Title page treatment (F4)

**Why:** `/automated-testing-kit` is currently an empty node — just the h1 hero, the "Submitted by" line (gone after Pass 1), and the sidebar. User asked for "a title or something nice". Original three directions (3a / 3b / 3c) recapped below for the record, then the 2026-04-20 architectural decision + sub-passes.

### 3a — Editorial welcome paragraph + CTA (superseded)

Simplest. A content-editor pass: populate the node body with a short welcome paragraph and a "Start reading: Introduction →" link. Zero theme code. ~5 minutes of work in the Drupal UI.

**Status:** ⬜ Superseded by 3.A — retained as a fallback if the hero treatment is judged too heavy.

### 3b — Auto-rendered table of contents in the content column (deferred)

Canonical docs-home pattern. Render the book's chapter list as a card grid or numbered list in the main content column. Duplicates the sidebar TOC but promotes it to primary content on the title page.

**Approach:** Template override on the title page (or a Canvas component, if we want to go that route) that calls `book_toc()` / reads `node.book` and renders chapters as content-cards. Could reuse the existing `dripyard_base:content-card` SDC for visual consistency.

**Scope:** One template + one component CSS file. Medium.

**Risk:** Title-page-only logic needs a clean scope guard (only render when viewing the top-level book node, not on children). Easy to get wrong — could accidentally duplicate the TOC on every page.

**Status:** ⬜ Deferred — a good Pass 3b follow-up once 3.A ships, for readers who want a visible chapter map alongside the hero.

### 3c — Hero-style overview with feature bullets + CTAs (chosen)

User-chosen direction (2026-04-20). Treat the book title page as a landing page: short value-prop, 3–5 feature bullets, CTAs to Introduction / Quickstart / Contributing.

**Status:** ✅ Direction accepted — implementation via the 3.A sub-passes below.

### 3 — Architectural decision (2026-04-20)

The plan's original 3c wording ("Canvas page that replaces the book-node title page") was scoped on 2026-04-20. Three naive approaches were ruled out:

| Approach | Verdict |
|---|---|
| **α — Replace book root with a `page` (Canvas) node at `/automated-testing-kit`** | **Blocker.** Book hierarchy requires the root to be a book node; swapping the URL alias to a `page` node orphans the 18 chapters' book-nav sidebar, breadcrumb, and prev/next. |
| **β — Point the URL to a Canvas page while keeping the book node at a new path** | **Blocker.** `block_book_navigation` only renders on book-node routes; sidebar would disappear at the landing URL. Same for the Pass 1.2 breadcrumb and Pass 2 prev/next. |
| **γ — Canvas page at a new URL + redirect from the book root** | **Blocker (same reason as β).** The landing URL ends up on a non-book route, losing all three things we just shipped. |

Three viable approaches were surfaced from config inspection:

| Approach | Verdict |
|---|---|
| **A — Rich-HTML body + `.book-landing-hero` CSS class** | **Chosen.** Node stays a book node (sidebar/breadcrumb/prev-next intact). Hero markup lives in the body field via `content_format` (allows `<h2>`–`<h6>`, `<a>`, alignment classes, `<drupal-media>`, etc.). Light CSS in the subtheme styles the hero band. Editor-tweakable. Low architectural risk. |
| **B — Theme template override + preprocess detecting book root** | Deferred alternative. Landing layout lives in `node--book.html.twig` with a `$node->book['bid'] == $node->id()` branch. Dev-controlled; copy lives in Twig. Consider if A proves insufficient. |
| **C — Canvas content template for `node.book.full`** | Deferred / rejected for this pass. Creates `core.entity_view_display.node.book.full.yml` + `canvas.content_template.node.book.full.yml`, applies to all 19 book pages, and would re-do Pass 2's `book_navigation_without_tree` wiring. Too much blast radius for a single-landing-page need. |

**Chosen path: Option A.** Rich-HTML body + `.book-landing-hero` CSS class.

Rationale (why not B or C):
- A keeps everything Passes 1 + 2 just shipped working — zero re-wiring.
- Editor can tweak copy post-launch without a deploy.
- Upgrade path to B or C remains open if the hero-in-body approach hits limits (e.g. needs Mercury components).

### Pass 3.A — Hero-style landing (body HTML + CSS class)

Broken into three sub-steps. Each pauses for explicit go-ahead, per workflow memory.

#### 3.A.1 — Draft hero copy + markup for review

**Deliverable:** Proposed HTML snippet for the `/automated-testing-kit` node body, using `content_format`-allowed tags. Pattern:

```html
<div class="book-landing-hero">
  <p class="book-landing-hero__eyebrow">Automated Testing Kit</p>
  <h2 class="book-landing-hero__title">{{ one-line value prop }}</h2>
  <p class="book-landing-hero__lede">{{ two-sentence description }}</p>
  <p class="book-landing-hero__ctas">
    <a class="button button--primary" href="/automated-testing-kit/introduction">Start with Introduction →</a>
    <a class="button button--secondary" href="/automated-testing-kit/quickstart">Quickstart</a>
    <a class="button button--tertiary" href="/automated-testing-kit/contributing">Contributing</a>
  </p>
</div>
<h2>What you'll find inside</h2>
<ul class="book-landing-features">
  <li>{{ feature bullet 1 }}</li>
  <li>{{ feature bullet 2 }}</li>
  <li>{{ feature bullet 3 }}</li>
</ul>
```

Copy draft blocks: value prop (1 line), lede (2 sentences), 3–5 feature bullets. User to approve / rewrite before 3.A.2 lands.

**Verification:** User reads the draft, approves or edits.

**Status:** ⬜ Not started — awaiting user copy direction.

#### 3.A.2 — Populate book root node body

Paste the 3.A.1-approved markup into `/node/<nid-of-automated-testing-kit>/edit` body field via the Drupal admin UI. Select the "Content" text format. Save.

**Why admin UI and not a drush snippet:** Content should live in the admin UI's revision history where editors can see and tweak it. No hidden DB mutations from scripts — see memory `feedback_editor_owned_content.md`.

**Scope:** One node edit. No code / config change.

**Verification:** T1 curl on `/automated-testing-kit` — new markup present; T3 screenshot desktop + mobile (will look unstyled until 3.A.3 lands, that's expected).

**Status:** ✅ Completed 2026-04-20. Discovered mid-step that the Body field row was disabled on the book form display (no `core.entity_form_display.node.book.default.yml` in `config/sync`; Drupal's auto-generated fallback had been overridden via admin UI previously). User enabled the Body row at `/admin/structure/types/manage/book/form-display` and pasted the markup with "Content" format. T1 confirmed: 1× "End-to-end testing utilities", 6× "Cypress", 1× "What's inside", 2× "Read the Introduction". **But:** 0× `book-landing-hero`, 0× `book-landing-features` — confirming the `content_format` filter strips `<div>` and `class=` attributes from authored body HTML on render. Pivots 3.A.3 from "plain CSS against authored BEM classes" to Option A' (theme-emitted wrapper + positional CSS).

**Follow-up:** The form-display change (enabling Body) lives in the DB active store, not in `config/sync`. Run `ddev drush cex --diff`, review the resulting `core.entity_form_display.node.book.default.yml`, and commit it with the Pass 3.A artifacts so it survives a future `drush cim`.

#### 3.A.3 — Theme-emitted wrapper + positional CSS (Option A')

Because `content_format`'s `filter_html` strips `<div>` and `class=` attrs from authored body HTML, we can't depend on BEM hooks in the pasted markup. Instead, the theme emits the container hook, and CSS targets the body's surviving DOM positionally.

**Files created 2026-04-20:**

1. `web/themes/custom/performant_labs_20260418/performant_labs_20260418.theme` — new `hook_theme_suggestions_node_alter` adds a `node__book__landing` suggestion only when the viewed node is the book root (`node.book.bid === node.id()`). Interior chapters fall through to `node.html.twig`.

2. `web/themes/custom/performant_labs_20260418/templates/content/node--book--landing.html.twig` — copy of the base `node.html.twig` with one change: wraps `{{ content.body }}` in `<div class="book-landing">`. Other content children (e.g. the Pass 2 `book_navigation_without_tree` prev/next) render after the wrapper via `{{ content|without('body') }}`.

3. `web/themes/custom/performant_labs_20260418/css/components/book-landing.css` — positional CSS targeting `.book-landing > .field--name-body > *:nth-of-type(…)`: eyebrow, value-prop title, lede, CTA row with primary/secondary button treatment, features heading, 2-col feature grid with "›" markers, trailing caveat paragraph with top border.

4. `web/themes/custom/performant_labs_20260418/performant_labs_20260418.libraries.yml` — registered `book-landing` library, attached from the twig template via `{{ attach_library(...) }}`.

**Known tradeoff:** reordering/inserting paragraphs in the body via the admin UI will shift the `:nth-of-type` selectors. Documented inline in `book-landing.css`. Promote to Option A'' (loosen `content_format`) or add a dedicated field if editorial drift bites.

**Verification:** after `ddev drush cr`, T1 expects `class="node--book-landing"` on the `<article>`, `<div class="book-landing">` wrapping the body field; T3 at 1440 + 390 should show the hero band, eyebrow, value-prop title, lede, two CTA styles (primary solid amber + secondary outline), 2-column feature grid with amber chevrons, and a bordered caveat paragraph.

**Status:** 🟡 Files written; awaiting cache clear + user T3.

### Pass 3.A commit point

After 3.A.3 verifies:

```
# Theme changes (Option A' — wrapper + CSS):
git add web/themes/custom/performant_labs_20260418/performant_labs_20260418.theme
git add web/themes/custom/performant_labs_20260418/templates/content/node--book--landing.html.twig
git add web/themes/custom/performant_labs_20260418/css/components/book-landing.css
git add web/themes/custom/performant_labs_20260418/performant_labs_20260418.libraries.yml
# Config (the form-display export from the 3.A.2 follow-up):
git add config/sync/core.entity_form_display.node.book.default.yml
# Plan doc update:
git add docs/pl2/neonbyte-plan--book-pages.md
git commit -m "theme(book): hero-style landing on /automated-testing-kit via theme-emitted wrapper (Pass 3.A)"
```

The body-field edit (3.A.2) is data — authored through the admin UI and lives in the DB with Drupal's revision history as the audit trail. Not committed to git; that's Option A's intended separation of content from code.

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
- [x] Pass 2 complete + committed (2026-04-20, functional only — styling polish deferred)
- [ ] Pass 3 path chosen + committed
- [ ] Pass 4 items either landed or promoted to GET-BACK-TO-THESE
- [ ] Re-audit pass: T1 → T2 → T3 on all four verification URLs
- [ ] Updated `GET-BACK-TO-THESE.md` with anything deferred

---

## Change Log

- 2026-04-20 — plan created from the `/automated-testing-kit` + `/automated-testing-kit/introduction` audit
- 2026-04-20 — Pass 1 committed (`f1aebda`); Pass 2 committed (`9dbaca7`)
- 2026-04-20 — Pass 3 architectural decision: user chose 3c direction; investigation ruled out α/β/γ (Canvas page swap) as blockers because they break sidebar/breadcrumb/prev-next; adopted Option A (rich-HTML body + `.book-landing-hero` CSS). Broken into sub-passes 3.A.1 / 3.A.2 / 3.A.3.
- 2026-04-20 — Pass 3.A.2 completed: Body field was disabled on book form display; user enabled it and pasted approved markup. T1 curl confirmed `content_format` strips `<div>` + `class=` (predicted) — authored BEM hooks do not survive to render. Pivoted 3.A.3 to Option A' (theme-emitted `.book-landing` wrapper + positional CSS).
- 2026-04-20 — Pass 3.A.3 files written: `hook_theme_suggestions_node_alter` in the `.theme` (adds `node__book__landing` suggestion for book root), new `templates/content/node--book--landing.html.twig` (wraps `content.body` in `.book-landing`), new `css/components/book-landing.css` (positional selectors; hero band + eyebrow + CTAs + 2-col feature grid + bordered caveat), library registered in `libraries.yml`. Awaiting `drush cr` + T1/T3 verification.
