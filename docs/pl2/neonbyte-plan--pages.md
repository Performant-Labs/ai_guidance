# `performant_labs_20260418` — Stage 3: Page Composition

> **Parent:** [`neonbyte-plan.md`](neonbyte-plan.md)
> **Previous:** [`neonbyte-plan--components.md`](neonbyte-plan--components.md)

---

## Entry Condition

Before starting this stage:
- [ ] Stage 2 complete — all priority components pass T2 + T3 in the SDC explorer
- [ ] No open component override commits outstanding
- [ ] `performant_labs_20260418` is the active default theme

---

## Purpose

Place verified, branded SDC components into actual Drupal pages. Components are assembled using the Canvas page system and/or Layout Builder. No new component CSS work happens here — if a page reveals a component issue, return to Stage 2.

---

## Page Inventory

Refreshed 2026-04-21 from `/sitemap.xml` + `config/sync/views.view.*.yml`.
Classification by path pattern; confirm content-type column against:

```bash
ddev drush sqlq "SELECT n.nid, n.type, n.title, u.alias
  FROM node_field_data n
  LEFT JOIN path_alias u ON u.path = CONCAT('/node/', n.nid)
  WHERE n.status=1 ORDER BY n.type, u.alias"
```

### Standalone pages (basic / Canvas)

Single-path items — no book hierarchy. `/` and pages listed in primary nav
are Canvas; long-form marketing pages like `/how-we-do-it` are also Canvas.
Utility pages (`/privacy-policy`, `/terms-service`, `/contact-us-thank-you`,
`/newsletter-signup`) are basic `page` nodes.

| Path | Status | Notes |
|---|---|---|
| `/` | ⬜ | Homepage — Canvas front page |
| `/home` | ⬜ | Likely duplicate of `/` — confirm + prune |
| `/services` | ⬜ | |
| `/how-we-do-it` | ⬜ | Canvas interior |
| `/how-we-do-it-0` | ⬜ | `-0` suffix = stale duplicate alias, prune |
| `/open-source-projects` | ⬜ | |
| `/open-source-projects-0` | ⬜ | `-0` suffix = stale duplicate alias, prune |
| `/introduction-to-atk` | ⬜ | |
| `/articles-2` | ⬜ | Looks like a view or duplicate — investigate |
| `/automated-testing` | ⬜ | |
| `/cypress-drupal` | ⬜ | |
| `/how-we-built-site` | ⬜ | |
| `/configuration` | ⬜ | Ambiguous — confirm content type |
| `/contact` | ⬜ | Webform page |
| `/contact-us-thank-you` | ⬜ | Webform confirmation |
| `/newsletter-signup` | ⬜ | Webform page |
| `/privacy-policy` | ⬜ | |
| `/terms-service` | ⬜ | |

### View listings

Defined in `config/sync/views.view.*.yml`. Not emitted in sitemap.

| Path | View machine name | Display | Status |
|---|---|---|---|
| `/articles` | `articles` | `page_1` | ✅ Row-gap fix applied 2026-04-21 |
| (admin) `/admin/content/canvas-pages` | `canvas_pages` | admin | n/a |

### Article nodes (10)

Under `/articles/*` — `node.type.article`.

- `/articles/badcamp-2020-talk`
- `/articles/cypress-drupal-cheat-sheet`
- `/articles/introducing-automated-testing-kit`
- `/articles/introducing-layout-builder-kit-beta-1`
- `/articles/layout-builder-can-break-your-site-part-1`
- `/articles/our-talk-drupalcon-layout-builder-components-can-break-your-site-heres-how`
- `/articles/version-10-automated-testing-kit-ready`
- `/articles/we-all-benefit-open-source`
- `/articles/why-drupal`

### Book nodes (~85 across 5 books)

All under `node.type.book`. Each book has a root page (listed) plus its
children. Children follow `page--documentation.html.twig` rendering.

| Book root | Children | Notes |
|---|---|---|
| `/automated-testing-kit` | 22 | Primary ATK docs — main book |
| `/automated-testing-kit-d7` | 10 | Drupal 7 legacy docs |
| `/campaign-kit` | 30+ | Campaign Kit module docs |
| `/layout-builder-kit` | 13 | Layout Builder Kit docs |
| `/testor` | 5 | Testor docs |

Full child path list in `/sitemap.xml`.

### Summary

| Type | Count | Verification strategy |
|---|---|---|
| Standalone pages | 18 | Page-by-page T3 screenshots |
| View listings | 1 public (`/articles`) | Row-gap + uniform-card sanity check |
| Article nodes | 10 | Sample 2–3 for article-full layout |
| Book nodes | ~85 across 5 books | Sample 1 root + 1 child per book (10 total) |

**Total: ~115 public-facing pages.**

---

## Execution Phases

### Phase 1 — Page Audit
- [ ] List all pages that need visual verification under `performant_labs_20260418`
- [ ] For each page, confirm it loads (T1) and renders structurally (T2)
- [ ] Note any component appearing broken that was not caught in Stage 2

> If a component issue is found: **stop, return to Stage 2**, fix in explorer, commit, then resume here.

---

### Phase 2 — Canvas Page Assembly (new or missing pages)

For pages that do not yet exist or need to be rebuilt as Canvas pages:

1. Follow [`canvas-scripting-protocol.md`](../ai_guidance/frameworks/drupal/theming/canvas-scripting-protocol.md) for the scripting approach
2. Use `drush php-eval` with the Drupal Entity API — **not** manual UI block placement
3. Verify the Canvas tree structure before saving (correct parent-child slot relationships)
4. T1 → T2 → T3 verification after each page is assembled

> **Commit point:** One commit per page assembled.
> ```bash
> git add config/sync/
> git commit -m "feat(pages): assemble [page-name] Canvas page under performant_labs_20260418"
> ```

---

### Phase 3 — Full-Site Visual Regression
- [ ] Run Backstop.js (or equivalent) across all pages in the Page Inventory
- [ ] Compare against `performant_labs_20260411` baseline screenshots
- [ ] Approve or flag each page diff

> See [`visual-regression-strategy.md`](../ai_guidance/frameworks/drupal/theming/visual-regression-strategy.md) for the full Backstop.js workflow.

---

### Phase 4 — Sign-off
- [ ] All pages in inventory pass T3
- [ ] No regressions flagged from Phase 3
- [ ] Final commit: `git tag v1.0-performant-labs-20260418`

---

## Verification (per page)

| Tier | Method | Pass condition |
|---|---|---|
| T1 — HTTP | `curl -sk -o /dev/null -w "%{http_code}" https://[site]/[path]` | `200` |
| T2 — ARIA | `read_browser_page` on the page | Page structure correct; no missing regions or empty slots |
| T3 — Visual | Screenshot | Brand colours, layout, and component rendering match design intent |

---

## Rollback Strategy

| Scope | Method |
|---|---|
| Single page regression | `git revert <commit>` for that page's assembly commit |
| Full stage rollback | `git revert` to the Stage 2 completion commit — theme and components intact, page assemblies removed |
| Emergency | `ddev drush config:set system.theme default performant_labs_20260411` — reverts to previous default theme instantly |
