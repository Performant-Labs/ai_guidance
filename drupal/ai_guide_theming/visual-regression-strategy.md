# Visual Regression Strategy

This document defines **how AI agents must execute Phase 10.2 (Visual Regression)**
for this project. It covers pixel-level layout comparison only — content correctness
is verified in Phase 10.1 (Content Audit) before this document's protocol begins.
It exists because three consecutive agent sessions crashed attempting this phase.
Read it in full before starting any comparison work.

> [!IMPORTANT]
> **Pre-condition: Phase 10.1 Content Audit must pass before running any VR subagent.** If any Canvas component still contains demo copy (Keytail, NeonByte, or other base-theme defaults), run Phase 10.1 first. A Phase 10.2 finding should never be "wrong text" — if it is, return to 10.1.

---

## Why Previous Attempts Crashed

The browser subagent has a hard context/output budget per call. Every prior
attempt crashed for the same compounding set of reasons:

| # | Root Cause | Evidence |
|---|-----------|----------|
| 1 | **Single-call scope too large** | Each session tried to load the live site, scroll 6–7 full-viewport screenshots, load the reference design, and write a full panel-by-panel report in *one* subagent call. The call exhausted its budget after the screenshot phase and exited with the report unwritten. |
| 2 | **Wrong reference asset** | Sessions passed `designs/keytail-desktop.webp` (2000×9902 px, 447 KB) as the reference image. Processing one massive composite image alongside 6+ live screenshots is enough on its own to blow the context budget. |
| 3 | **No incremental writes** | Observations were accumulating in the subagent's scratchpad but never flushed to a persistent file mid-run. When the call crashed, all analysis was lost. |
| 4 | **"Side-by-side" is not possible in one pass** | A 9,902 px reference and a 4,962 px live page = ~17 viewport-equivalent images. No single agent call can reason across all of them simultaneously. |

---

## Correct Execution Pattern

### Core Rule

> **One subagent call = One design slice vs. one live viewport.**

The `designs/` directory already contains pre-sliced assets that exactly match
the required granularity. Use these — never the full composite.

```
designs/
  00_menu.webp          ← header/nav bar
  01_hero.webp          ← hero banner
  02_features_search_changed.webp
  03_carousel_built_different.webp
  04_content_engine.webp
  05_designed_for_teams.webp
  06_graph_stocks.webp
  07_faq.webp
  08_footer.webp
```

### Execution Sequence

Run **nine sequential subagent calls**, one per slice. Each call must:

1. Navigate to `https://pl-performantlabs.com.2.ddev.site:8493/` (or the URL
   already open — no need to reload if the previous call left it there).
2. Scroll to the vertical position corresponding to the slice being examined.
3. Take a **single viewport screenshot** of that live section.
4. Load **only the matching `designs/NN_name.webp` slice** as the MediaPath
   reference — never the full composite.
5. Compare the two images and write findings **immediately** to
   `drupal/ai_guide_theming/visual-regression-report.md` before returning.
6. Return a summary of gaps found in that panel.

The outer agent (not the subagent) is responsible for issuing all nine calls
sequentially and aggregating the results.

### Scroll Positions

Use these approximate scroll targets to align with each design slice:

| Slice | Scroll Y (approx) | Live Section |
|-------|------------------|--------------|
| `00_menu.webp` | 0 | Header / navigation bar |
| `01_hero.webp` | 0–400 | Hero banner |
| `02_features_search_changed.webp` | 400–900 | Features intro row |
| `03_carousel_built_different.webp` | 900–1600 | Carousel / built different |
| `04_content_engine.webp` | 1600–2600 | Content engine / dashboard |
| `05_designed_for_teams.webp` | 2600–3200 | Designed for teams |
| `06_graph_stocks.webp` | 3200–3700 | Graph / social proof |
| `07_faq.webp` | 3700–4400 | FAQ accordion |
| `08_footer.webp` | 4400–4962 | Footer |

> [!NOTE]
> These Y values are approximate for the 1728×997 viewport currently in use and
> a live page height of ~4962 px. Adjust by eye on first scroll.

---

## Report File

All findings must be written incrementally to:

```
drupal/ai_guide_theming/visual-regression-report.md
```

Each subagent call must **append** its panel findings to this file before
returning. Do not accumulate findings in scratchpad only — the report must
survive a crash.

### Report Format Per Panel

```markdown
## Panel 00 — Header / Navigation

**Scroll Y**: 0 px  
**Reference**: designs/00_menu.webp  
**Status**: ✅ Match / ⚠️ Minor gap / ❌ Major gap

### Gaps
- [ ] Gap description ...

### Notes
- ...
```

---

## Constraints and Guardrails

- **Never pass `keytail-desktop.webp` as a MediaPath.** It is 9,902 px tall.
  It will exhaust context on its own. It exists only as a human reference for
  reviewing the full composition visually.
- **Never ask the subagent to compare more than one panel per call.** If a
  panel is complex (e.g., `04_content_engine.webp`), split it into two calls
  (top half / bottom half) rather than expanding scope.
- **Always write to the report file inside the subagent call.** Do not defer
  writing to the outer agent — the subagent may be the last thing that runs
  before a crash.
- **The outer agent must check the report file exists** before launching the
  first subagent. If it does not exist, create it with a header block first.

---

## Reference to This Document

This strategy is referenced from the master SOP at:

```
drupal/ai_guide_theming/AI-Guided-Theme-Generation.md
```

under **Phase 10.2: Visual Regression**.
