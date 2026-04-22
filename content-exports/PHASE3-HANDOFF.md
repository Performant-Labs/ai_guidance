# Phase 3 Homepage Rebuild — Handoff Notes

Living document. Update as work progresses. Lives in-repo so it versions with the overlay YAMLs and scripts it describes. NOT a substitute for `.auto-memory/` — memory holds cross-conversation rules; this holds current Phase 3 working state that would be expensive to reconstruct after a Claude context compaction.

Last updated: 2026-04-21 (post Section 2 PNG fix; commit `28e32eb`)

---

## TL;DR — where we are right now

- **Section 1 (hero):** applied, live on the homepage.
- **Section 2 (trust bar, 6 client logos):** ✅ **actually rendering** (browser-verified). Two sequential fixes landed:
  1. **Envelope fix** (commit `93f2a3b`): switched the stored image-prop shape from the silently-coerced flat form to the StaticPropSource envelope, so Canvas stopped dropping the prop.
  2. **PNG fix** (commit `28e32eb`): rasterized the 6 source SVGs to 600px-wide PNGs and re-seeded as `image`-bundle media (mids 53–58), because Canvas's `image` component unconditionally emits a responsive srcset via `toSrcSet`, and Drupal's image toolkit can't generate AVIF derivatives from SVG sources — every srcset URL was returning HTTP 500 even though the envelope fix was correct. Current verification: all 54 src+srcset URLs return 200 + `image/png`. Rollback point: commit `28e32eb`.
- **Sections 3–6:** not started.
- **Other pages (/services, /how-we-do-it, /automated-testing, /about-us, /cypress-on-drupal, /open-source-projects, /introduction-to-atk):** not started.

---

## Canvas image-prop storage — the gotcha, explained once so we don't re-derive it

**Rule (corrected 2026-04-21 after Section 2 shipped):** when a Canvas component defines an image prop via `prop_field_definitions` with `field_type: entity_reference, target_type: media`, the **submit-time** shape sent through `apply-canvas-page.php` must be the full StaticPropSource envelope. Canvas then **collapses this on save** to a bare `{"target_id": N}` — do not be alarmed by the collapse; that is the canonical on-entity storage shape, and it renders correctly because Canvas reconstructs the full source from `prop_field_definitions` at render time.

The flat shape `{src, alt, width, height}` is silently dropped at submit time (never reaches storage as anything useful), which is what Section 2 was suffering from before the envelope fix.

**Why the flat shape's failure is silent:**

- `GeneratedFieldExplicitInputUxComponentSourceBase::uncollapse()` (canvas module, ~line 1475): any value without a `sourceType` key is passed to `getDefaultStaticPropSource(...)->withValue($value, allow_empty: TRUE)`. The `allow_empty: TRUE` causes shape mismatches to coerce to empty instead of throwing.
- Canvas then falls back to a `DefaultRelativeUrlPropSource` at render time — which is a render-time fallback only, NOT a valid storage shape. If no fallback asset exists, the image simply doesn't render.
- The consumer template (`themes/contrib/dripyard_base/components/image-or-media/image-or-media.twig`) guards with `{% if image.src %}`, so a coerced-empty value emits no `<img>` at all.

**Empirical confirmation (2026-04-21):** after applying `homepage-section-2-envelope-fix.overlay.yml`, a fresh `dump-canvas-page.php` shows each `logo-item-canvas` inputs JSON as `{"href":null,"image":{"target_id":53}}` (etc, now pointing at the PNG-backed mids after the second fix — see below). Rendered HTML has all 6 `<img>` tags with `data-component-id="canvas:image"` and correct srcset, and every srcset URL resolves to a PNG derivative.

**Correct submit-time envelope (for the `logo-item-canvas` component's `image` prop):**

```yaml
image:
  sourceType: 'static:field_item:entity_reference'
  value:
    target_id: <media entity id>
  expression: 'ℹ︎entity_reference␟entity␜[␜entity:media:image␝field_media_image␞␟{src↠src_with_alternate_widths,alt↠alt,width↠width,height↠height}][␜entity:media:svg_image␝field_media_svg_image␞␟{src↠src_with_alternate_widths,alt↠alt,width↠width,height↠height}]'
  sourceTypeSettings:
    storage:
      target_type: media
    instance:
      handler: 'default:media'
      handler_settings:
        target_bundles:
          image: image
          svg_image: svg_image
```

The `expression` is the active `logo-item-canvas` version `3c9e4bde3fcefeed` (see `config/sync/canvas.component.sdc.dripyard_base.logo-item-canvas.yml`). If the component version changes, re-derive from the active config.

**Where the envelope came from:** `web/modules/contrib/canvas/tests/src/TestSite/CanvasTestSetup.php` around lines 285–320 has a concrete working example. Use it as the template for any future `entity_reference/media` prop.

**Known side-effect discovery (not caused by us):** the existing homepage's `canvas-image` instances (inside the tab-groups) also store the flat shape and are silently dropped. Proven empirically — `pl-dashboard`, `Team working on SEO` strings are absent from rendered body despite panels server-rendering. Out of scope for Section 2 but worth noting when we get to those tabs.

**Memory correction done (2026-04-21):** `.auto-memory/project_pl2_canvas_content_flow.md` has been rewritten. The "always use the flat shape" rule was wrong; the corrected rule now describes the submit-time envelope → on-save collapse behavior.

---

## Canvas image component + SVG sources — the second gotcha (2026-04-21)

After the envelope fix above, the 6 `logo-item-canvas` components correctly stored `{"image":{"target_id":41..46}}` and rendered HTML with 6 `<img data-component-id="canvas:image">` tags. But the trust bar was still visually blank in the browser.

**What was happening:** Canvas's `image` component template (`web/modules/contrib/canvas/components/image/image.twig`) unconditionally expands its src into a responsive srcset via `{% set srcset = src|toSrcSet(width) %}`. The `src_with_alternate_widths` computed property produces URLs that go through Drupal's image-style pipeline, requesting AVIF derivatives. Drupal's image toolkit cannot rasterize SVG into AVIF → each of the 48 srcset URLs (6 logos × 8 widths) returned **HTTP 500 "Error generating image."** Browsers prefer srcset over src, so they saw 8 broken derivative URLs per img and rendered nothing.

**First remediation attempt (didn't work — documented so we don't repeat it):** Re-seeded the 6 media entities in the `svg_image` bundle (mids 47–52) on the theory that bypassing `field_media_image` would skip the raster image-style pipeline. It didn't — the srcset is emitted by the *component* template, not chosen by the media bundle, so swapping bundles made no visible difference. The 48 derivative URLs still 500'd.

**Working fix (PNG rasterization):**

1. Convert each source SVG to a 600px-wide PNG using ImageMagick inside DDEV (`convert -background none -density 300 input.svg -resize 600x PNG32:output.png`). 600px wide comfortably exceeds the largest srcset width (384px) so the down-scale stays sharp.
2. Place PNGs at `public://client-logos-png/`.
3. Seed 6 new `image`-bundle media entities (mids 53–58) pointing at the PNG files.
4. Apply `content-exports/homepage-section-2-pngfix.overlay.yml` to re-target the 6 `logo-item-canvas` components at the new mids.
5. `ddev drush cr` to invalidate the Canvas render cache.
6. Verify: `curl` the homepage, extract every src + each comma-separated srcset entry, HEAD each URL. All 54 URLs return 200 + `image/png`.

**Guidance amendment (docs/ai_guidance/frameworks/drupal/theming/verification-cookbook.md):** Tier 1 now requires a "Check E — srcset URLs must actually resolve" step before declaring any image-prop component green. Check C (srcset presence) only proves the HTML attribute exists; Check E proves the browser has something to display. Full incident write-up in the cookbook's Incident Appendix.

**Rule of thumb for future components consuming SVG media:** if the component renders through Canvas's `image` component (or anything else that calls `toSrcSet`), rasterize the source to PNG/JPEG first. SVG media is only safe in contexts that emit raw `<img src=...>` with no srcset derivatives — e.g., a custom template that inlines the file or uses `<picture>` with explicit sources.

---

## Homepage UUIDs

- **canvas_page UUID:** `bb5bbbb1-4a16-4b86-bbea-b215ab8096cf`
- **Component UUIDs (Section 2 logo-items):** see `content-exports/homepage-section-2.overlay.yml` for the 6 `logo-item-canvas` UUIDs that need the envelope patch.

(When another section starts, append its component UUID map here — saves re-grepping the overlay file every compaction.)

---

## Seeded media entities (client logos)

**Current working set** — bundle `image`, PNG files at `/sites/default/files/client-logos-png/`:

| mid | Brand               | Filename                          |
|-----|---------------------|-----------------------------------|
| 53  | CBS Interactive     | CBS-Interactive-logo.png          |
| 54  | DocuSign            | DocuSign-logo.png                 |
| 55  | Orange              | Orange-logo.png                   |
| 56  | Renesas Electronics | Renesas_Electronics_logo.png      |
| 57  | Robert Half         | Robert-Half-logo.png              |
| 58  | Tesla               | Tesla-logo.png                    |

Sources preserved in `logos-staging/` (SVG originals, gitignored workspace).

**Deleted (do not reference):**
- mids 41–46 — original `image` bundle, SVG files. Dropped because of the SVG/AVIF mismatch described above.
- mids 47–52 — intermediate `svg_image` bundle, SVG files. Red herring — bundle swap didn't change the render pipeline.

Verify via `ddev drush sqlq "SELECT mid, name FROM media_field_data WHERE mid BETWEEN 53 AND 58"` before acting on these IDs — a DB rollback could change them.

---

## Rollback points (code + DB)

Convention: `<slug>-YYYYMMDD-HHMM`. Same tag goes in the git commit message and the `ddev snapshot --name=` so they sort together.

| Tag | What it preserves | Notes |
|-----|-------------------|-------|
| `section2-envelope-20260421-1853` | Pre-envelope-fix homepage DB state (Section 2 broken, flat image shape) + gitignore rule committed at `74c8c7f`. | Use to re-reproduce the broken-flat-shape bug for debugging, or to roll back if Section 2's envelope apply turns out to have had a subtle regression elsewhere. |
| Post-PNG-fix state | Current working homepage DB + commit `28e32eb`. Trust bar rendering with PNG-backed mids 53–58. | No paired ddev snapshot was taken for this step — the fix is purely additive on top of the envelope-fix snapshot. The PNG source files at `web/sites/default/files/client-logos-png/*.png` persist across DB rollbacks; if a rollback to `section2-envelope-20260421-1853` is ever needed, re-create the 6 `image`-bundle media entities pointing at those files, then re-apply `content-exports/homepage-section-2-pngfix.overlay.yml` (the committed record of the fix) and adjust the `target_id`s if the new mids aren't 53–58. If you want a paired snapshot for the current state, run `ddev snapshot --name=section2-pngfix-20260421`. |

When creating a new rollback point, update this table with one line — the tag plus a ~10-word summary of the state it captures. Future-you will thank present-you when sorting through a dozen of these.

---

## The host-command bridge

New as of this phase: `scripts/claude-bridge.sh`. When running, Claude can drop shell commands into `.claude-bridge/req-<id>.sh` and read back `res-<id>.out` / `res-<id>.exit`. Runs with repo-root CWD. Executes with user's privileges — only run while actively collaborating. Cleans stale results on startup. `.claude-bridge/` is gitignored.

Start: `./scripts/claude-bridge.sh` (Ctrl-C to stop).

Claude's side-effect cleanup: bridge requests start with `find .claude-bridge -type f -mmin +5 -delete` so the sandbox (which can't delete host-owned files directly) doesn't accumulate stale request/response pairs.

---

## Scripts reference

- `scripts/apply-canvas-page.php` — applies an overlay YAML to an existing `canvas_page`. Supports `component_inputs` (patch existing component inputs), `add_components` (insert new components after an anchor), `remove_components` (delete by UUID + descendants). `dry-run` second arg previews without saving. Idempotent on `add_components`.
- `scripts/dump-canvas-page.php` — companion export script.

---

## Next steps (in order)

1. ~~**Section 2 envelope fix**~~ — done 2026-04-21.
2. ~~**Memory cleanup** (`project_pl2_canvas_content_flow.md`)~~ — done 2026-04-21.
3. ~~**Section 2 PNG fix**~~ — done 2026-04-21 (commit `28e32eb`).
4. ~~**Tier 1 cookbook amendment (srcset resolution check)**~~ — done 2026-04-21; pushed upstream to `Performant-Labs/ai_guidance`.
5. **Section 3:** design + content TBD.
6. **Sections 4–6:** TBD.
7. **Existing `canvas-image` tab-panel fix:** re-apply with the correct envelope once we're back in that area. Same two-gotcha pair applies — use the StaticPropSource envelope AND rasterize source SVG to PNG if the `canvas:image` component is in the render path.
8. **Other pages** (services, how-we-do-it, etc.): post-homepage.
9. **Optional script cleanup (not urgent):** `scripts/dump-canvas-page.php` writes relative to drush CWD (`/var/www/html/web`), so dumps land at `web/content-exports/<uuid>.yml` instead of repo-root `content-exports/`. Harmless (now gitignored) but slightly confusing. A one-line fix would be to resolve the default output path relative to `__DIR__ . '/../content-exports/'`.

---

## Post-compaction checklist (for future Claude)

If you're reading this after a context compaction:

1. Read this whole file.
2. Read `.auto-memory/MEMORY.md` and any linked memories that look relevant.
3. Verify seeded media IDs still exist (see SQL above).
4. Verify the current homepage component state before mutating: `ddev drush php:script scripts/dump-canvas-page.php <homepage-uuid>` and diff against the last known overlay.
5. Check `git log --oneline -20` and `ddev snapshot --list` for the latest rollback tags.
6. Check if `scripts/claude-bridge.sh` is running (ask user or check for `.claude-bridge/` activity).
