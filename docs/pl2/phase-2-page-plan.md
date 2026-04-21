# Phase 2 — Page-Level Plan

*Phase 2 deliverable of the [repositioning runbook](./repositioning-runbook.md). Finalized 2026-04-21.*

This document is the source of truth for which existing pages survive the repositioning, which get rewritten, and which retire. Phase 3 (content briefs + new IA) depends on it.

**Companion artifacts:**
- **[repositioning-framework.md](./repositioning-framework.md)** — approved Phase 1 framework.
- **[repositioning-inventory.xlsx](./repositioning-inventory.xlsx)** — full per-page data, including the *Phase 2 disposition* and *Phase 2 rationale / follow-on* columns added in this pass.

---

## Summary

26 standalone pages from the legacy site were reconciled against the approved framework. Final counts:

| Disposition | Pages | Meaning |
|---|---:|---|
| Rewrite | 7 | Load-bearing positioning work. |
| Keep, reframe | 2 | Copy lightly shifted; structure survives. |
| Light tweak | 3 | Microcopy / CTA only. |
| Keep as-is | 4 | Utility or legal. |
| Rename + curate | 1 | `/articles` → `/insights` archive. |
| Retire | 9 | Dropped from the new IA. |
| **Total** | **26** | |

---

## Group 1 — Rewrite (7 pages)

These are the pages that carry the repositioning. Each needs a Phase 3 content brief.

### Homepage
- **`/` (nid 38)** — Must carry the "tools + AI + people" hero. Load-bearing page for the entire site.

### Core offerings
- **`/services` (nid 8)** — Core offering page. **Must include a sub-section on nearshore testing staff augmentation**, folded in from the retired `/nearshoring` page (decision D). Framing: testing staff, not build-shop developers.
- **`/how-we-do-it` (nid 9)** — Methodology. Pragmatic tone proven through specifics, not adjectives.
- **`/automated-testing` (nid 98)** — Elevated to **hero status**. The autonomous-test-healing showcase.

### Identity and proof
- **`/about-us` (nid 10)** *(NEW vs runbook)* — Fresh About carrying 15+ years of experience, OSS authorship (ATK / Testor), and the dogfooding story.
- **`/how-we-built-this-site` (nid 76)** — **Proof asset.** The load-bearing "we run Claude agents nightly to heal tests on this very site" page. Link from the `/automated-testing` hero and from the homepage.

### Legacy offering, modernized
- **`/cypress-on-drupal` (nid 96)** — Keeps URL (3.5 years of SEO). Rewrite covers both frameworks; Playwright primary (where autonomous healing lives); Cypress still supported. *Phase 3 flag: consider a companion `/playwright-on-drupal` page so Playwright has its own SEO anchor.*

---

## Group 2 — Keep, reframe (2 pages)

Structure survives; copy shifts to match the new positioning.

- **`/open-source-projects` (nid 23)** — ATK and Testor are hero proof points in the new framework. Reframe copy to lead with the autonomous-healing angle.
- **`/introduction-to-atk` (nid 491, microsite)** — Supporting asset under the ATK proof point.

---

## Group 3 — Light tweak (3 pages)

Microcopy / CTA only. No structural change.

- **`/contact-us` (nid 13)** — CTA refresh.
- **`/contact-us-thank-you` (nid 97)** — Microcopy.
- **`/newsletter-signup` (nid 75)** — Microcopy.

---

## Group 4 — Keep as-is (4 pages)

Utility / legal. No rewrite.

- **`/privacy-policy` (nid 69)** — Legal boilerplate.
- **`/terms-of-service` (nid 68)** — Canonical ToS URL. **Flag: content dates to Jan 3, 2020 — legal refresh advised in Phase 3.**
- **`/sitemap` (nid 77)** — SEO / nav utility.
- **`/well-be-back-soon` (nid 85)** — Maintenance mode page; infrastructure, not copy.

---

## Group 5 — Rename + curate (1 page)

- **`/articles` (nid 14)** — Rename to `/insights` (or similar; exact URL decided in Phase 3 IA work). Curated archive, not active blog. No posting cadence commitment.
  - **Keep ~6 on-message pieces** (testing + community presence):
    - ATK launch article (nid 110)
    - ATK 1.0 Ready (nid 116)
    - Cypress on Drupal Cheat Sheet (nid 99)
    - BADCamp 2020 — Components Can Break Your Site Part 2 (nid 94)
    - DrupalCon talk: Layout Builder components can break your site (nid 93)
  - **Retire ~4 off-message pieces:** Layout Builder Part 1 (nid 88), LB Kit Beta (nid 15), Why Drupal? (nid 91), We all benefit from Open Source (nid 92).
  - **Stranded drafts:** publish the **Stanford Web Camp talk** (nid 114, drafted 2023) — on-message content about Cypress AND Playwright testing for Drupal. Triage the rest (nid 17 placeholder, nid 95 Cypress intro draft, nid 115 Retrofit walkthrough, nid 753 Private File Tests).

---

## Group 6 — Retire (9 pages)

| NID | Path | Notes |
|---|---|---|
| 12 | `/frontpage2` | Stale duplicate of real homepage. 301 → `/`. |
| 67 | `/style-guide` | Drupal dev utility; not customer-facing. |
| 79 | `/terms-service` | Empty duplicate shell. 301 → `/terms-of-service`. |
| 72 | `/nearshoring` | Already unpublished. 2020 build-shop pitch; collides with framework boundary. Concept folds into `/services`. |
| 73 | `/join-the-team` | Already unpublished. 2020 Drupal 8 content. |
| 74 | `/team-culture` | Already unpublished. 277 chars, one-day 2020 effort. |
| 80 | `/jobs` | Stale since 2020. 301 → `/about-us` or `/`. |
| 82 | `/job/full-stack-drupal-developer` | Stale 2020 req. If hiring resumes, fresh page. |
| 83 | `/job/front-end-developer` | Stale 2020 req. If hiring resumes, fresh page. |

---

## Follow-on requirements for Phase 3

These are not page dispositions but context the Phase 3 content briefs must carry:

1. **`/services` brief** must include a nearshore testing staff-augmentation sub-section (from decision D).
2. **`/cypress-on-drupal` brief** should consider a companion `/playwright-on-drupal` page for SEO symmetry (from decision A).
3. **`/insights` (renamed `/articles`)** should prioritize publishing the Stanford Web Camp talk (nid 114) as early post-launch content (from decision C).
4. **`/terms-of-service`** is 6 years old; include a legal refresh in the Phase 3 brief even though the disposition is "Keep as-is" for structure (from decision B).

---

## Open IA / menu questions for Phase 3

Issues surfaced by this pass that don't live at the page-disposition level but need Phase 3 decisions:

- **Primary nav IA** — the current menu structure predates the new positioning. Phase 3 must decide top-level nav: likely some combination of *Services, Automated Testing, Open Source, Insights, About, Contact*.
- **`/jobs` URL disposition** — retired, but where does the 301 go? `/about-us` is the honest answer (team lives there), but `/` is simpler. Phase 3 IA call.
- **`/articles` → `/insights` URL slug** — final decision held for Phase 3 IA work. Options include `/insights`, `/testing-notes`, `/writing`.
- **Companion `/playwright-on-drupal` page** — if created, sits alongside `/cypress-on-drupal` or replaces it as primary.

---

## Not in scope for this pass

The legacy site also contains content *not* covered in the 26-page standalone set:

- **14 articles** (posterity sheet in the xlsx) — dispositions described in Group 5 at a cluster level; per-article triage happens in the Phase 3 `/insights` brief.
- **83 books** (posterity sheet) — outside this repositioning.
- **227 path aliases** (full sheet) — redirects to reconcile once new IA is finalized.
- **Webforms, menus, redirects** — captured in their respective sheets for Phase 3 reference.

---

## Approval

| Stage | Approved by | Date |
|---|---|---|
| Phase 1 framework | André Angelantoni | 2026-04-21 |
| Phase 2 page plan | André Angelantoni | 2026-04-21 |

**Next step:** Phase 3 — content briefs for the 7 Rewrite pages and 2 Keep-reframe pages, plus the new IA / menu decisions listed above.
