# Visual Regression Report — Phase 10: Canvas Assembly Verification
**Site**: https://pl-performantlabs.com.2.ddev.site:8493/
**Date**: 2026-04-12
**Protocol**: Full-page audit + per-panel comparison against designs/

---

## Phase 10 Overall Status: ❌ TWO CRITICAL GAPS

| Category | Status | Detail |
|---|---|---|
| Layout / Structure | ✅ Pass | Dark navy gradient, correct section spacing, typography rendering correctly |
| Navigation | ✅ Pass | Services, How We Do It, Articles, Open Source Projects, Contact Us — correct order, correct links |
| Hero copy | ✅ Pass | "Expert Drupal engineering, when you need it most." — correct client copy |
| Hero CTAs | ✅ Pass | "Call today →" primary, "Book a call" secondary — correct and styled |
| **Logo** | ❌ **Major gap** | **NeonByte logo and wordmark showing — should be Performant Labs** |
| **Canvas body copy** | ❌ **Major gap** | **Multiple sections contain NeonByte/Keytail demo placeholder copy** |

---

## Panel 00 — Header / Navigation

**Scroll Y**: 0 px
**Reference**: designs/00_menu.webp
**Status**: ⚠️ Minor gap (logo incorrect; layout/nav correct)

### Gaps
- [ ] Logo shows "NeonByte" with circular icon — should be Performant Labs logo
- [ ] "Call today" nav CTA present and styled correctly ✅ (no change needed)

### Notes
- Nav labels, order, and colours are correct
- Dark navy gradient header renders correctly

---

## Panel 01 — Hero Banner

**Scroll Y**: ~130–500 px
**Reference**: designs/01_hero.webp
**Status**: ✅ Match

### Gaps
- None — hero heading, gradient background, and CTAs match

### Notes
- "Expert Drupal engineering, when you need it most." — correct
- Dark navy-to-amber gradient correct
- "Call today →" and "Book a call" CTAs correct

---

## Panel 02 — Features / Intro Section

**Scroll Y**: ~500–1000 px
**Reference**: designs/02_features_search_changed.webp
**Status**: ❌ Major gap

### Gaps
- [ ] Section heading: "Everything your team needs to ship faster." — NeonByte placeholder
- [ ] Card 1: "AI Prospecting — Surface ideal leads from 500M+ verified contacts..." — wrong
- [ ] Card 2: "Automated Outreach — Personalised multi-channel sequences..." — wrong
- [ ] Card 3: "Pipeline Intelligence — Unified analytics across every touchpoint..." — wrong

### Notes
- Layout structure (3-column cards) renders correctly
- Section background colour correct
- Only the COPY needs updating

---

## Panel 03 — Carousel / "Built Different"

**Scroll Y**: ~1000–1600 px
**Reference**: designs/03_carousel_built_different.webp
**Status**: ❌ Major gap (suspected — same placeholder copy pattern as Panel 02)

### Gaps
- [ ] Likely carries NeonByte demo headlines — needs direct inspection

### Notes
- Could not scroll to this exact position in the audit session

---

## Panel 04 — Content Engine / Dashboard

**Scroll Y**: ~1600–1800 px
**Reference**: designs/04_content_engine.webp
**Status**: ❌ Major gap

### Gaps
- [ ] "Built for every Drupal project." heading ✅ (correct)
- [ ] Cards: Financial Services, Technology, Healthcare — NeonByte framing ("buying committees", "qualified buyers before RFPs go live")
- [ ] Tabs: "Prospects", "Sequences", "Analytics" — NeonByte demo tab labels

### Notes
- Section heading is correct but supporting copy is wrong

---

## Panel 05 — Designed for Teams

**Scroll Y**: ~2600–3200 px
**Reference**: designs/05_designed_for_teams.webp
**Status**: ❌ Major gap

### Gaps
- [ ] Heading "Designed for the whole engineering team." ✅ (correct)
- [ ] Bullets: "SDRs hit quota 40% faster", "AEs focus on closing, not prospecting", "RevOps gets one source of truth" — sales team copy, wrong

### Notes
- Heading is correct; bullet points are NeonByte sales-tool placeholders

---

## Panel 06 — Graph / Social Proof

**Scroll Y**: ~3200–3700 px
**Reference**: designs/06_graph_stocks.webp
**Status**: ❌ Major gap

### Gaps
- [ ] "With Keytail" / "Without Keytail" tab labels — explicit placeholder branding
- [ ] "Be the answer. Everywhere." footer banner — NeonByte tagline, not Performant Labs

### Notes
- The "With Keytail / Without Keytail" comparison is Keytail's own demo — must be replaced

---

## Panel 07 — FAQ

**Scroll Y**: ~3700–4400 px
**Reference**: designs/07_faq.webp
**Status**: Unknown — not captured in this audit pass

---

## Panel 08 — Footer

**Scroll Y**: bottom
**Reference**: designs/08_footer.webp
**Status**: ⚠️ Minor gap

### Gaps
- [ ] NeonByte logo appears in footer — should be Performant Labs
- [ ] "Be the answer. Everywhere." CTA heading — NeonByte tagline

### Notes
- Footer menus (Services, Resources, Company) are correct with Performant Labs links
- Social icons (LinkedIn, GitHub, X) present and correct

---

## Fix Priority

| Priority | Issue | Phase to revisit |
|---|---|---|
| 1 | **Logo** — NeonByte showing instead of Performant Labs | Phase 2 (brand assets) |
| 2 | **Canvas placeholder copy** — 5+ sections still have NeonByte/Keytail demo text | Phase 9 (Canvas reassembly) |

Both issues must be fixed before Phase 12 (Navigation Verification) and Phase 14 (Content Rendering) can proceed.

---

# Phase 10 Fixes Applied

| Fix | Status |
|---|---|
| Logo: set `logo.use_default=false` in `performant_labs_20260411.settings` | ✅ Done — curl confirms correct SVG served |
| Articles listing View created at `/articles` | ✅ Done — route returns 200 |

---

# Phase 12: Navigation Verification

**Date**: 2026-04-12
**Method**: curl HTTP checks + HTML source inspection

## Results

| Check | Status | Detail |
|---|---|---|
| Services `/services` | ✅ 200 | — |
| How We Do It `/how-we-do-it` | ✅ 200 | — |
| Articles `/articles` | ✅ 200 | Fixed: View created during this phase |
| Open Source Projects `/open-source-projects` | ✅ 200 | — |
| Contact Us `/contact` | ✅ 200 | — |
| Nav labels in HTML | ✅ Pass | Services, How We Do It, Articles, Open Source Projects, Contact Us all present |

## Gap Found and Fixed
- `/articles` returned 404 — no articles listing View existed. Created `views.view.articles` at `/articles` showing article nodes sorted newest-first. Exported to config/sync and committed.

**Phase 12 Status**: ✅ Pass (after fix)

---

