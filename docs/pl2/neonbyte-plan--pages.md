# `pl_neonbyte` — Stage 3: Page Composition

> **Parent:** [`neonbyte-plan.md`](neonbyte-plan.md)
> **Previous:** [`neonbyte-plan--components.md`](neonbyte-plan--components.md)

---

## Entry Condition

Before starting this stage:
- [ ] Stage 2 complete — all priority components pass T2 + T3 in the SDC explorer
- [ ] No open component override commits outstanding
- [ ] `pl_neonbyte` is the active default theme

---

## Purpose

Place verified, branded SDC components into actual Drupal pages. Components are assembled using the Canvas page system and/or Layout Builder. No new component CSS work happens here — if a page reveals a component issue, return to Stage 2.

---

## Page Inventory

Define which pages need to be assembled or verified before declaring Stage 3 complete. Update this table as pages are confirmed:

| Page | Path | Status | Notes |
|---|---|---|---|
| Home | `/` | ⬜ Pending | Canvas page — front page |
| Introduction to ATK | `/introduction-to-atk` | ⬜ Pending | Canvas page |
| Contact | `/contact` | ⬜ Pending | |
| Documentation (book nodes) | `/docs/*` | ⬜ Pending | Uses `page--documentation` template |

---

## Execution Phases

### Phase 1 — Page Audit
- [ ] List all pages that need visual verification under `pl_neonbyte`
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
> git commit -m "feat(pages): assemble [page-name] Canvas page under pl_neonbyte"
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
- [ ] Final commit: `git tag v1.0-pl-neonbyte`

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
