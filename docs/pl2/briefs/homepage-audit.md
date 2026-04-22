# Homepage Audit — `/page/1`

*Pre-implementation audit for the [homepage brief](./homepage.md). 2026-04-21.*

Read-only inspection of the current homepage state vs. the approved 6-section brief. No edits made.

---

## TL;DR

- The homepage at `/` resolves to Canvas page `/page/1` (set in `system.site.front`).
- The **current hero is off-position**: H1 reads *"Expert Drupal engineering, when you need it most."* — the pre-repositioning framing. The brief requires *"Ship Drupal releases with confidence."*
- The page currently has 7–8 sections; **none** of them match the brief's Sections 2 (trust bar), 4 (dogfooding), 5 (case studies), or 6 (final CTA). The current Section 2 ("Everything your team needs to build better Drupal") looks pillar-like but is 3 generalist columns (Automated Testing / Expert Engineering / Open Source), not the brief's *tools → AI → people* pillars.
- Component coverage is **rich**: 65 SDC Canvas components + 37 block components are registered. Likely **no net-new SDCs** are required for Sections 1–3, 5, and 6. Section 4 (dogfooding proof with code-font card) may need a small new component or CSS polish on an existing card.
- Implementation mechanism is **in-place edit of the existing Canvas page** `/page/1`, replacing and reorganizing component instances — not a fresh page.

---

## Site architecture (confirmed)

| Layer | Value |
|---|---|
| Drupal | 11 |
| Canvas module | `web/modules/contrib/canvas/` — v1.3.2 (formerly Experience Builder) |
| Theme chain | `dripyard_base` → `neonbyte` → `performant_labs_20260418` (custom subtheme) |
| Default theme | `performant_labs_20260418` (`system.theme.yml`) |
| Homepage route | `/page/1` (Canvas page content entity; lives in DB, not config/sync) |
| CSS convention | All edits in `performant_labs_20260418/css/layout/*.css`; Layer-5 discipline (see file headers) |
| Body class signal | `.canvas-page` (from `canvas_preprocess_html()`); `.canvas-page.path-frontpage` on homepage |

Content is **not** in `config/sync` — Canvas pages are content entities. Verifying per-page component layout requires either DB access, a drush command, or visual inspection (screenshots in `/mnt/Performant Labs Theme 2/` cover both dates).

---

## Current homepage state (from 2026-04-20/21 screenshots)

Above the fold (desktop 1440):

1. **Hero** — dark navy with gradient. H1 = *"Expert Drupal engineering, when you need it most."* Two CTAs: amber *"Call today"* + outline *"Book a call."* Subhead names "expert engineering, automated testing, and open source leadership."

Below the fold (full-scroll screenshot):

2. **"Everything your team needs to build better Drupal"** — 3 columns: Automated Testing / Expert Engineering / Open Source.
3. **"Built for every type of Drupal project"** — 4 industry verticals: Government / Higher Ed / Healthcare / Media & Publishing.
4. **"One partner, every layer of the stack"** — tab-component-like.
5. **"Built for the whole Drupal team"** — bullet/checklist.
6. **"Frequently asked questions"** — FAQ accordion (~4 questions).
7. **"Enterprise Teams"** — small band with progress bar.
8. **"The engineering debt compounds. Start before it does."** — closing band with stat/fractal graphic.
9. **Footer** — navy blue, four-column, *"Be the answer. Everywhere."* tagline.

---

## Gap analysis — current vs. brief (section by section)

| Brief section | Current state | Gap |
|---|---|---|
| **1. Hero** | Off-position H1/subhead/CTAs | Replace H1, subhead, and both CTAs. Visual container (gradient + transparent nav) stays. |
| **2. Trust bar** | **Not present.** No client-logo strip visible. | New: add logo-strip component. (`dripyard_base/logo-grid` + `logo-item-canvas` available.) Logos already exist on site somewhere (legacy site has CBS, Orange, DocuSign, Robert Half, Tesla, Goldman, Renesas) — need to confirm they're in `.com.2` media library. |
| **3. Three pillars** | Partially present — current "Everything your team needs" is 3 cards but the content is different (Automated Testing / Expert Engineering / Open Source vs. brief's Tools / AI / People). | Repurpose the existing 3-card row: rewrite card content, keep the structural component. |
| **4. Dogfooding proof** | **Not present.** No section about nightly heal workflow. | New. Requires a heading, body text, and a code-font card showing workflow filename or recent autonomous-fix one-liner. No existing SDC is perfectly shaped; may need CSS polish on `card-canvas` or a small new code-display component. |
| **5. Selected engagements** | **Not present.** Current page has generalist verticals (Gov / Higher Ed / Healthcare / Media) but no named-client case-study strip. | New 3-card horizontal strip. `dripyard_base/card-canvas` or `mercury/card-testimonial` both fit. Blocked on Task #7 (write up 2–3 case studies from raw notes). |
| **6. Final CTA** | Not as drafted. Current closer is *"The engineering debt compounds. Start before it does."* — wrong framing. Final CTA heading from brief: *"Ready for a release you don't have to babysit?"* | New CTA block. `mercury/cta` or `dripyard_base/title-cta` available. |

### Sections currently on the page that are NOT in the brief

These need to be **removed or relocated** on the homepage:

- Industry-vertical band (Gov / Higher Ed / Healthcare / Media).
- "One partner, every layer of the stack" tab section.
- "Built for the whole Drupal team" checklist.
- FAQ accordion.
- "Enterprise Teams" band.
- "The engineering debt compounds" closer.

Most are relevant content that can move elsewhere in the new IA (some belong on `/services`, `/how-we-do-it`, or `/automated-testing`), but they do not belong on the homepage per the 6-section brief.

---

## SDC coverage for the 6 brief sections

Component inventory (registered as Canvas components in `config/sync`):

- **65 SDCs** across `dripyard_base` (37), `mercury` (24), `neonbyte` (2), `performant_labs_20260418` (1 — just a `dry_run_test`).
- **37 block components** (page-title, navigation, events, etc. — mostly utility; one or two may apply, e.g., `views_block:*` displays for case-study or logo-strip if preferred over SDC path).

Proposed per-section mapping:

| Brief section | Primary SDC | Alternate | Status |
|---|---|---|---|
| 1. Hero | `neonbyte/hero` (already overridden in `hero-override` for navy-to-amber) | `mercury/hero-billboard`, `mercury/hero-side-by-side` | Already on page; content-only change. |
| 2. Trust bar | `dripyard_base/logo-grid` + `logo-item-canvas` | — | Component exists; logos need verification in media. |
| 3. Three pillars | `dripyard_base/grid-wrapper` wrapping 3× `dripyard_base/content-card` (already overridden) | 3× `dripyard_base/icon-card` | Current page has this pattern; rewrite content. |
| 4. Dogfooding proof | `dripyard_base/section` + `heading` + `text` + `card-canvas` (for code-font card) | Custom small SDC if code styling insufficient | Needs content + possible CSS polish. |
| 5. Selected engagements | `dripyard_base/grid-wrapper` with 3× `dripyard_base/card-canvas` | `mercury/card-testimonial` | Needs Task #7 case-study content first. |
| 6. Final CTA | `dripyard_base/title-cta` (heading + body + button) | `mercury/cta` | Straightforward. |

### Theme overrides already in place

From `performant_labs_20260418.info.yml` → `libraries-extend`:

- `neonbyte/hero` → custom gradient + padding
- `neonbyte/header` → transparent-on-canvas-front, amber CTA
- `dripyard_base/content-card` → white bg, radius-lg, shadow, hover lift
- `dripyard_base/accordion-item` → amber chevron
- `dripyard_base/tab-group` → amber filled-pill active indicator
- `neonbyte/footer` → 'PL' watermark, social, footer CTA
- `dripyard_base/statistic` → min-width fix for flex-wrapper
- `neonbyte/header-article` → 16:9 aspect ratio (for articles, not homepage)
- `neonbyte/article-full` → typography + TOC (for articles)

---

## Net-new work required

Concrete list, in implementation order:

1. **Section 1 content swap** — H1, subhead, CTAs (primary + secondary targets). Canvas inputs edit. *No code.*
2. **Section 2 (trust bar) — new component instance** — Place `logo-grid` in a new slot. Requires verifying logos exist in `.com.2` media; may need to upload if not. *Possibly new media entities.*
3. **Section 3 content swap** — Rewrite the 3 existing content-cards with tools / AI / people copy. *No code.*
4. **Section 4 (dogfooding) — new component assembly** — New Canvas section with heading + text + code-font card. May need CSS polish on `card-canvas` to support monospace styling. *Small CSS change possible.*
5. **Section 5 (case studies) — new component assembly** — 3-card horizontal strip; content blocked on Task #7. *Content-blocked.*
6. **Section 6 (final CTA) — new component or content swap** — Replace the current "engineering debt" closer with the brief's CTA. *Content + possibly component swap.*
7. **Removals** — Delete or relocate: industry verticals, "One partner" tabs, "Built for the whole Drupal team", FAQ, "Enterprise Teams", current closer. *Canvas structure edit.*

---

## Implementation mechanism — recommended

The homepage is a single Canvas page entity. All section changes are **Canvas editor edits** (add/remove/reorder component instances, edit their inputs). No theme-file edits are required for content changes.

Where Code IS required (vs. editor-only):

- **Possibly** a small CSS addition to `performant_labs_20260418/css/layout/` for Section 4's code-font card styling.
- **Possibly** uploading trust-bar logos as media entities if not already present.
- **No** new SDCs expected. If a custom code-display SDC becomes necessary, it goes in `performant_labs_20260418/components/` (the subtheme's components slot) and registers as a Canvas component via its `.component.yml`.

This aligns with the existing workflow: Canvas editor for content/structure, subtheme CSS for polish, no drush scripts for content mutations (per the editor-owned-content preference).

---

## Open questions before implementation

1. **Logos in media library** — Do the 7 client logos (CBS Interactive, Orange, DocuSign, Robert Half, Tesla, Goldman Environmental Prize, Renesas) exist as media entities in `.com.2`? If not, they need to be uploaded before Section 2 can ship.
2. **Case study content** — Task #7 is open. Do we ship Section 5 thin (placeholder cards) and backfill, or gate the homepage launch on the case-study writeups?
3. **Canvas page access** — How does the implementation happen from here? Three paths:
   - **(a)** User (André) performs the edits in the Canvas editor while we walk through them section-by-section here.
   - **(b)** Claude generates a Canvas page export / config snippet that the user imports.
   - **(c)** Hybrid: Claude drafts the production copy; user pastes into Canvas editor field-by-field.
4. **Nav IA change** — The current nav reads *Services / How We Do It / Articles / Open Source Projects / Contact Us*. Phase 2 plan renames `/articles` → `/insights` and suggests adding `/automated-testing`. Do these nav edits happen as part of the homepage pass, or as a separate IA pass?
5. **Removed sections — where do they go?** Industry verticals, tab-component, FAQ, etc. Do they move to `/services` / `/how-we-do-it`, or retire entirely?

---

## Dependencies

- Task #7 (case studies) — blocks Section 5 with real content.
- `/contact-us?intent=testing-review` target — shared with homepage brief; verify the form variant or query-param handler exists.
- ATK canonical GitHub URL — shared dependency with `/how-we-built-this-site` brief.
- Canvas page `/page/1` must be editable (no uncommitted schema changes; editor should be accessible via the Canvas UI).
