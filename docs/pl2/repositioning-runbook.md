# Repositioning Runbook — "The Drupal AI Testing Experts"

> **Scope:** Shift Performant Labs' public positioning from "builds and tests Drupal websites" to testing-focused with a strong AI emphasis.
> **Out of scope:** Articles (10 nodes — keep for posterity). Book pages (~85 across 5 books — stay the same). Legal boilerplate (`/privacy-policy`, `/terms-service`).
> **Workflow rules:** Audit-first. One pass at a time. Explicit go required before any live edits. No batched multi-page pushes.

---

## Phase 1 — Messaging framework (strategy before copy)

Lock the strategic question before any copy is drafted. This document becomes the source of truth for every downstream page.

- [ ] Define ideal customer profile (ICP) — which segment(s): Drupal shops without QA depth / enterprise Drupal owners / agencies white-labeling testing / other
- [ ] Write one-sentence positioning statement ("For X who Y, we are Z that…")
- [ ] Pin down what "AI" concretely means in the offering — pick from: AI-assisted test authoring, autonomous test agents, AI-driven visual regression, AI triage of flaky tests, other
- [ ] Name the 2–3 competitors we're positioning against
- [ ] Write 3–5 proof points that make "Drupal AI Testing Experts" defensible (not aspirational) — case studies, open-source assets (ATK, Testor), credentials, metrics
- [ ] Agree tone-of-voice (2–3 adjectives) and what we explicitly are *not*
- [ ] Stakeholder sign-off on the framework before moving to Phase 2

**Exit condition:** Framework doc exists, is signed off, and future decisions can be tested against it.

---

## Phase 2 — Content audit of the live site

No edits. Just inventory. Source of truth is `performantlabs.com`, cross-referenced with `neonbyte-plan--pages.md`.

- [ ] Build audit spreadsheet with columns: URL, page title, current H1/hero, current value prop language, current CTAs, last updated, disposition tag, notes
- [ ] Fill in the 18 standalone pages (see "Page dispositions" section below)
- [ ] Capture live screenshots of each standalone page (desktop + mobile) for before/after comparison
- [ ] Tag each page: **Keep** / **Rewrite** / **Consolidate** / **Retire** / **Investigate**
- [ ] Resolve ambiguous pages: `/configuration`, `/articles-2`, `/home`, `/how-we-do-it-0`, `/open-source-projects-0`
- [ ] Flag any pages with inbound links, good SEO, or campaign traffic before retiring them
- [ ] Record current SEO metadata (title tag, meta description, OG) per page for rewrite reference

**Exit condition:** Spreadsheet complete, every standalone page has a disposition, retired-page list has a redirect plan.

---

## Phase 3 — Content brief (creative brief for copy + new IA)

One short brief per rewritten page, plus a decision on the new menu structure. Still no live edits.

- [ ] Draft new information architecture — primary nav labels, footer, top-tasks menu
- [ ] Decide whether "Services" stays or becomes "Testing" / splits into sub-offerings
- [ ] Decide whether a new top-level menu item is needed (e.g., "AI Testing")
- [ ] For each page tagged Rewrite or Keep-with-revision, write a 1-pager brief: purpose, target reader, desired action, must-say points, must-not-say, tone, success criterion
- [ ] Resolve the site tagline ("builds and tests world-class websites" replacement)
- [ ] Map each page brief back to the messaging framework — does it reinforce the positioning?
- [ ] Review and approve all briefs as a batch before any drafting starts

**Exit condition:** New IA approved. One brief exists per page-to-rewrite. Tagline candidate chosen.

---

## Phase 4 — Implementation, one page at a time

Strict order. Each page completes fully (draft → review → apply → verify → commit) before the next starts.

### 4.1 Homepage `/`
- [ ] Draft new hero + sections per brief
- [ ] Review and approve copy
- [ ] Apply via admin UI paste (editor-owned content)
- [ ] T1 curl → T2 ARIA → T3 screenshot verification
- [ ] Update meta title, meta description, OG tags
- [ ] Commit on host

### 4.2 `/services`
- [ ] Draft → review → apply → T1/T2/T3 → SEO meta → commit

### 4.3 `/how-we-do-it`
- [ ] Draft → review → apply → T1/T2/T3 → SEO meta → commit

### 4.4 `/automated-testing`
- [ ] Draft → review → apply → T1/T2/T3 → SEO meta → commit

### 4.5 `/cypress-drupal`
- [ ] Draft → review → apply → T1/T2/T3 → SEO meta → commit

### 4.6 `/open-source-projects`
- [ ] Reframe intro copy only (pages themselves stay) → review → apply → T1/T2/T3 → SEO meta → commit

### 4.7 `/introduction-to-atk`
- [ ] Light reframing → review → apply → T1/T2/T3 → SEO meta → commit

### 4.8 `/how-we-built-site`
- [ ] Decide final disposition (retire / repurpose as case study / rewrite)
- [ ] If retire: add 301 redirect, remove from menus and sitemap
- [ ] If rewrite: follow standard draft → review → apply → T1/T2/T3 → SEO meta → commit

### 4.9 Contact / webform pages
- [ ] `/contact` — CTA/microcopy tweak → review → apply → T1/T2/T3 → commit
- [ ] `/contact-us-thank-you` — microcopy tweak → review → apply → T1/T2/T3 → commit
- [ ] `/newsletter-signup` — microcopy tweak → review → apply → T1/T2/T3 → commit

### 4.10 Menu + footer changes
- [ ] Rename primary nav labels per Phase 3 decisions
- [ ] Update footer menu to match
- [ ] Verify menu rendering on desktop and mobile (T3 screenshots)
- [ ] Commit

### 4.11 Site-wide cleanup
- [ ] Prune stale aliases flagged in `neonbyte-plan--pages.md` (`/home`, `/-0` suffixes, `/articles-2` if duplicate)
- [ ] Regenerate `sitemap.xml`
- [ ] Submit updated sitemap to Google Search Console / Bing Webmaster
- [ ] Verify 301s in place for all retired URLs

---

## Phase 5 — Post-launch verification

- [ ] Visual regression pass across all rewritten pages vs. pre-repositioning baseline
- [ ] Internal link audit — no remaining "builds websites" / "web development" language in navigation, footers, or adjacent body copy
- [ ] Crawl for broken links introduced by retirements
- [ ] Confirm Articles (10) and Books (~85) still render correctly (no collateral damage)
- [ ] 30-day check: bounce rate, time-on-page, contact form submissions vs. pre-launch baseline

---

## Page dispositions (quick reference)

| Path | Disposition | Notes |
|---|---|---|
| `/` | Rewrite | Hero line is the most visible change |
| `/services` | Rewrite | Biggest copy rewrite; offering re-centered |
| `/how-we-do-it` | Rewrite | Positioning narrative page |
| `/automated-testing` | Rewrite (strengthen) | Becomes a hero page under new positioning |
| `/cypress-drupal` | Rewrite (strengthen) | Add AI angle if it fits the framework |
| `/open-source-projects` | Keep, reframe intro | ATK/Testor reinforce the new positioning |
| `/introduction-to-atk` | Light reframe | Land it inside the new narrative |
| `/how-we-built-site` | Decide (retire / repurpose / rewrite) | Title is off-brand under new positioning |
| `/contact` | Light CTA tweak | Microcopy only |
| `/contact-us-thank-you` | Light tweak | Microcopy only |
| `/newsletter-signup` | Light tweak | Microcopy only |
| `/privacy-policy` | Keep as-is | Legal boilerplate |
| `/terms-service` | Keep as-is | Legal boilerplate |
| `/configuration` | Investigate | Ambiguous — confirm content type first |
| `/articles-2` | Investigate | Likely view or duplicate |
| `/home` | Retire | Stale duplicate of `/` |
| `/how-we-do-it-0` | Retire | Stale alias |
| `/open-source-projects-0` | Retire | Stale alias |
| `/articles` (view) | Keep | View listing — no content change |
| All 10 Articles | Keep as-is | Posterity (per instruction) |
| All ~85 Book pages | Keep as-is | Per instruction |

---

## Menu / label change candidates

| Element | Current | Status | Notes |
|---|---|---|---|
| Primary nav → Services | "Services" | Review in Phase 3 | Candidate to rename to "Testing" or restructure |
| Primary nav → How We Do It | "How We Do It" | Review in Phase 3 | May need clearer label under new positioning |
| Primary nav → Articles | "Articles" | Keep | Per instruction |
| Primary nav → Open Source Projects | "Open Source Projects" | Keep label | Reinforces testing positioning |
| Primary nav → Contact Us | "Contact Us" | Keep | |
| New primary nav item (optional) | — | Review in Phase 3 | Possible "AI Testing" top-level |
| Footer menu | mirrors primary nav | Mirror primary decisions | |
| Site tagline (homepage hero) | "Performant Labs builds and tests world-class websites" | Rewrite | Site-wide brand asset |

---

## Rollback

| Scope | Method |
|---|---|
| Single page regression | `git revert <commit>` for that page's apply commit |
| Full reposition rollback | Revert the series of page commits in reverse order; menu/footer commits last |
| Menu/IA regression only | Revert menu + footer commits; leave page copy in place if individually approved |
