# `performant_labs_20260418` — Stage 0: Design Analysis

> **Parent:** [`neonbyte-plan.md`](neonbyte-plan.md)
> **Next:** [`neonbyte-plan--theme.md`](neonbyte-plan--theme.md)

---

## Purpose

Produce a set of image clips — crops from the original design snapshots — and assign one clip to every component that will be overridden in Stages 1–3. These clips become the visual specification the agent works against. They replace guesswork: before any CSS is written, the agent opens the relevant clip, not the whole design file.

---

## Entry Condition

| Item | Check |
|---|---|
| Pre-cropped design JPEGs exist in `docs/pl2/keytail-design/` | `ls docs/pl2/keytail-design/*.jpg` |

> **Note:** The original plan assumed full-page `.webp` composites (`keytail-desktop.webp` / `keytail-mobile.webp`) for ImageMagick cropping. Those files were too large to commit. Instead, 7 pre-cropped JPEG slices are committed directly. No ImageMagick step is required — Phases 1 and 2 are satisfied by the existing files.

---

## Output Artifacts

| Artifact | Location | Purpose |
|---|---|---|
| Clip image files | `docs/pl2/keytail-design/` | Pre-cropped `.jpg` slices — one per page section (desktop only; no mobile source available) |
| Design map | `docs/pl2/keytail-design/design-map.md` | Component → clip assignment, design intent notes |

The `design-map.md` is the document Stages 1–3 reference for every visual decision. It is not a summary — it is a look-up table with embedded images.

---

## Clip Naming Convention

The committed JPEG slices use the following naming scheme:

```
keytail-desktop-{slug}.jpg

keytail-desktop-homepage.jpg   ← hero + header (full above-fold)
keytail-desktop-slice1.jpg     ← s01 — content-card section
keytail-desktop-slice2.jpg     ← s02 — tabs section
keytail-desktop-slice3.jpg     ← s03 — audience / icon-list section
keytail-desktop-slice4.jpg     ← s04 — social proof / chart section
keytail-desktop-slice5.jpg     ← s05 — FAQ / accordion section
keytail-desktop-footer.jpg     ← s06 — footer
```

**Mobile:** No mobile source was committed. Mobile behaviour is inferred from desktop slices and verified live at 375px viewport.

When a component has no unique slice, it is assigned to the most canonical occurrence. The map records which slice it came from.

---

## Execution Phases

### Phase 1 — View and Decompose

✅ **Complete.** Read all JPEG slices in `docs/pl2/keytail-design/` directly. The slice inventory is:

| File | Slice | Label | Contents |
|---|---|---|---|
| `keytail-desktop-homepage.jpg` | s00 | hero + header | Transparent header, full-viewport sky/hills hero, headline + search bar + CTAs + product screenshot |
| `keytail-desktop-slice1.jpg` | s01 | content-cards | "Search has changed" — 3 elevated white cards on cream bg |
| `keytail-desktop-slice2.jpg` | s02 | tabs | "Your always content engine" — white pill tabs, dark product screenshot |
| `keytail-desktop-slice3.jpg` | s03 | audience / icon-list | Animated text list left, woman-at-laptop photo right, pill search bar overlay |
| `keytail-desktop-slice4.jpg` | s04 | social proof | "Just like stocks" — analytics chart card on white bg |
| `keytail-desktop-slice5.jpg` | s05 | accordion / FAQ | Minimal FAQ — thin rule rows, `+` icon, white bg |
| `keytail-desktop-footer.jpg` | s06 | footer | Giant `K` watermark, sky gradient bg, footer nav + social icons |

---

### Phase 2 — Produce Clips

✅ **Complete.** Pre-cropped JPEG slices are already committed to `docs/pl2/keytail-design/`. No ImageMagick step required.

**Mobile:** No mobile source was committed. Mobile behaviour must be verified live at 375px viewport using the `?theme=` shim.

---

### Phase 3 — Map Components to Clips

Every component listed in [`neonbyte-plan--component-audit.md`](neonbyte-plan--component-audit.md) must be assigned a clip. Work through the audit document top to bottom. For each component:

1. **Identify its primary slice** — which section in the design best shows this component?
2. **Assign the clip** — use the clip from that slice.
3. **Note if shared** — if the clip is already assigned to another component, mark it as shared. Do not produce a second crop; reference the same file.
4. **Write one-line design intent** — what does the clip tell us about this component? Colour, shape, spacing, state.

#### Shared clip rules

A clip is shared when a component appears in multiple slices and has no slice of its own. Examples:

- **`button--cta`** appears in the hero, feature sections, and footer — clip it from whichever occurrence is largest and most legible (usually the hero).
- **`content-card`** appears inside a carousel and also in a standalone grid — clip from the carousel slice; note the standalone grid variant if it differs.
- **Page-level layouts** (canvas full-width, docs grid) have no design slice — use the full desktop image as the clip and crop only the layout boundary area.

When a clip is shared, the `design-map.md` entry reads:

```
Clip shared from: s01-hero (most canonical appearance)
```

This is not an error — it is the correct answer when a component has no unique visual region.

---

### Phase 4 — Write `design-map.md`

Write `docs/pl2/keytail-design/design-map.md` with one entry per component. The format for each entry:

```markdown
### {component-name}

| | Desktop | Mobile |
|---|---|---|
| **Clip** | ![desktop clip](clips/desktop--s{NN}-{slug}.webp) | ![mobile clip](clips/mobile--s{NN}-{slug}.webp) |
| **Clip source** | Original / Shared from s{NN}-{slug} | Original / Shared from s{NN}-{slug} |
| **Design intent** | One sentence: colour, shape, key behaviour visible in the clip |
| **Stage 2 action** | Port as-is / Improve / Drop |
```

The `Stage 2 action` column is set here, not in Stage 2. Stage 0 is when the design is fresh in view — that is the right moment to make the port/improve/drop call, not after the agent has moved on to scaffolding.

Order entries in the map to match the priority order at the bottom of `neonbyte-plan--component-audit.md`:

1. hero
2. header (transparent sticky)
3. content-card
4. button--cta / button--pill-dark
5. accordion
6. tabs
7. page layouts
8. Twig templates
9. footer patterns

---

## Commit Point

```bash
git add docs/pl2/keytail-design/clips/
git add docs/pl2/keytail-design/design-map.md
git commit -m "docs(design): produce keytail design clips and component map"
```

Rollback: `git revert` removes all clips and the map — design source images are unaffected.

---

## Verification

Before closing Stage 0, confirm:

- [ ] Every component in `neonbyte-plan--component-audit.md` has an entry in `design-map.md`
- [ ] Every entry has both a desktop and mobile clip path
- [ ] All clip paths resolve to files that exist in `clips/`
- [ ] No clip file is 0 bytes (`ls -lh docs/pl2/keytail-design/clips/`)
- [ ] The `Stage 2 action` column is filled for every entry (no blanks)

---

## Stage Complete → Proceed to Stage 1

When `design-map.md` is complete and committed, proceed to:

**[`neonbyte-plan--theme.md`](neonbyte-plan--theme.md)** — Theme scaffolding and brand wiring

Agents working in Stage 1, 2, or 3 must open `design-map.md` and the relevant clip **before** writing any CSS or assembling any Canvas component. The clip is the specification; the stage documents are the procedure.
