# `performant_labs_20260418` — Master Plan

## Purpose

This document is the entry point for all work on the `performant_labs_20260418` child theme. It defines the inheritance chain, the document family structure, and the sequence of execution across three stages.

**Inheritance chain:**
```
dripyard_base  →  neonbyte  →  performant_labs_20260418
(foundation)      (design)     (brand)
```

All customisation lives in `themes/custom/performant_labs_20260418/`. Neither `neonbyte` nor `dripyard_base` are ever modified directly.

---

## Document Family

This plan is split into four stage documents. Execute them in order. Each stage has its own pre-conditions, phases, and commit points.

| Document | Stage | Entry condition |
|---|---|---|
| [`neonbyte-plan--design.md`](neonbyte-plan--design.md) | 0 — Design analysis and clip extraction | Design snapshots present in `keytail-design/`; ImageMagick available |
| [`neonbyte-plan--theme.md`](neonbyte-plan--theme.md) | 1 — Theme scaffolding and brand wiring | Stage 0 complete; `design-map.md` committed; brand assets resolved (hex, logo, favicon) |
| [`neonbyte-plan--components.md`](neonbyte-plan--components.md) | 2 — SDC component work | Stage 1 complete; theme active and verified (T1+T2 pass) |
| [`neonbyte-plan--pages.md`](neonbyte-plan--pages.md) | 3 — Page composition | Stage 2 complete; all targeted components verified in explorer |

---

## Session Initialization

Before starting any working session on this theme, you must complete the following two steps in order:

1. **Verify Branch:** Ensure you are on the correct active theme branch:
   ```bash
   git branch  # must show * aa/performant-labs-20260418-theme
   ```
2. **Execute Pre-Flights:** Read and execute the checklist in [`pre-flight-checks.md`](pre-flight-checks.md) before making any code or config changes. This prevents environment failures from masquerading as codebase regressions.

---

## Supporting Document Families

### CSS strategy (`theme-change` family)
All CSS decisions — at any stage — defer to this family before any edit is made:

| Document | Role |
|---|---|
| [`theme-change.md`](theme-change.md) | Rules and layer hierarchy |
| [`theme-change--audit.md`](theme-change--audit.md) | Source verification against Dripyard |
| [`theme-change--workflow.md`](theme-change--workflow.md) | Operating procedure per change |

### References
| Document | Purpose |
|---|---|
| [`ai-guided-theme-generation.md`](../ai_guidance/frameworks/drupal/theming/ai-guided-theme-generation.md) | Environment preflight, asset collection, drush commands |
| [`operational-guidance.md`](../ai_guidance/frameworks/drupal/theming/operational-guidance.md) | Known failure patterns — logo dual-location, drush hangs, SVG rules |
| [`component-cookbook.md`](../ai_guidance/frameworks/drupal/theming/component-cookbook.md) | Authoritative prop/slot names before any SDC override |
| [`verification-cookbook.md`](../ai_guidance/frameworks/drupal/theming/verification-cookbook.md) | Three-tier verification protocol |

---

## Open Questions (blocks Stage 1)

| # | Question | Blocks |
|---|---|---|
| 1 | Exact hex values for primary and secondary brand colours | Stage 1, Phase 3 |
| 2 | Logo — supply file or AI-generate? | Stage 1, Phase 3 |
| 3 | Favicon — supply file or AI-generate? | Stage 1, Phase 3 |
| 4 | Font family — confirm or use system sans-serif initially? | Stage 1, Phase 4 |
| 5 | `neonbyte_subtheme` disposition — leave untouched or archive? | Stage 1, Phase 1 |
| 6 | Any additional `libraries-override` needed beyond what NeonByte inherits? | Stage 1, Phase 2 |
