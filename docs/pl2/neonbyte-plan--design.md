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
| `docs/pl2/keytail-design/keytail-desktop.webp` exists | `ls docs/pl2/keytail-design/` |
| `docs/pl2/keytail-design/keytail-mobile.webp` exists | same |
| `magick` (ImageMagick 7) is available | `magick --version` |

> If ImageMagick is not installed: `brew install imagemagick`

---

## Output Artifacts

| Artifact | Location | Purpose |
|---|---|---|
| Clip image files | `docs/pl2/keytail-design/clips/` | One `.webp` per slice, per breakpoint |
| Design map | `docs/pl2/keytail-design/design-map.md` | Component → clip assignment, design intent notes |

The `design-map.md` is the document Stages 1–3 reference for every visual decision. It is not a summary — it is a look-up table with embedded images.

---

## Clip Naming Convention

```
{breakpoint}--s{NN}-{slug}.webp

desktop--s00-header.webp
desktop--s01-hero.webp
mobile--s01-hero.webp
```

- `{breakpoint}` — `desktop` or `mobile`
- `s{NN}` — slice index, two digits, matching the slice IDs in `neonbyte-plan--component-audit.md`
- `{slug}` — short lowercase label for the section

When a component has no unique slice (a button that appears in every section, for example), the clip is taken from the **most canonical occurrence** — the one that shows the component most clearly and completely. The map records which slice it came from.

---

## Execution Phases

### Phase 1 — View and Decompose

Read both design images directly. Claude can render `.webp` files natively — use the Read tool on each file.

```
Read: docs/pl2/keytail-design/keytail-desktop.webp
Read: docs/pl2/keytail-design/keytail-mobile.webp
```

For each image, record:

1. **Total pixel dimensions** — run once, before any cropping:
   ```bash
   magick identify -format "%wx%h\n" \
     docs/pl2/keytail-design/keytail-desktop.webp \
     docs/pl2/keytail-design/keytail-mobile.webp
   ```

2. **Slice inventory** — scan top to bottom. For each horizontal band write down:

   | Slice | Label | Desktop Y-start | Desktop Y-end | Mobile Y-start | Mobile Y-end |
   |---|---|---|---|---|---|
   | s00 | header | | | | |
   | s01 | hero | | | | |
   | … | … | | | | |

   Record pixel rows, not percentages. Estimate from visual inspection — exact pixel-perfection is not required; the clip just needs to contain the relevant elements with a small margin.

> **Phase 1 output:** a completed slice table. Do not proceed to Phase 2 until every row is filled.

---

### Phase 2 — Produce Clips

Create the clips directory:

```bash
mkdir -p docs/pl2/keytail-design/clips
```

For each row in the slice table, run two ImageMagick crops — desktop and mobile:

```bash
# Template — substitute WIDTH, HEIGHT, X, Y for each slice
magick docs/pl2/keytail-design/keytail-desktop.webp \
  -crop {WIDTH}x{HEIGHT}+{X}+{Y} +repage \
  docs/pl2/keytail-design/clips/desktop--s{NN}-{slug}.webp

magick docs/pl2/keytail-design/keytail-mobile.webp \
  -crop {WIDTH}x{HEIGHT}+{X}+{Y} +repage \
  docs/pl2/keytail-design/clips/mobile--s{NN}-{slug}.webp
```

**X is always 0.** Clips are full-width horizontal bands — never a partial column crop, because components span the full width of their section.

After each crop pair, read the output file to confirm it contains the intended content before moving to the next slice. Do not batch all crops and verify at the end.

```bash
# Confirm dimensions match expectation
magick identify -format "%wx%h\n" docs/pl2/keytail-design/clips/desktop--s{NN}-{slug}.webp
```

> **Phase 2 output:** a `clips/` directory containing two files per slice.

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
