# Phase 3 Homepage Rebuild — Handoff Notes

Living document. Update as work progresses. Lives in-repo so it versions with the overlay YAMLs and scripts it describes. NOT a substitute for `.auto-memory/` — memory holds cross-conversation rules; this holds current Phase 3 working state that would be expensive to reconstruct after a Claude context compaction.

Last updated: 2026-04-21 (post Section 2 envelope-fix)

---

## TL;DR — where we are right now

- **Section 1 (hero):** applied, live on the homepage.
- **Section 2 (trust bar, 6 client logos):** ✅ **rendering.** Envelope fix applied via `content-exports/homepage-section-2-envelope-fix.overlay.yml`; Tier 1 curl verification shows 6 `<img>` tags with full responsive `srcset` chains, correct alt text, and `data-component-id="canvas:image"`. Rollback point: commit `74c8c7f` + ddev snapshot `section2-envelope-20260421-1853`.
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

**Empirical confirmation (2026-04-21):** after applying `homepage-section-2-envelope-fix.overlay.yml`, a fresh `dump-canvas-page.php` shows each `logo-item-canvas` inputs JSON as `{"href":null,"image":{"target_id":41}}` (etc). Rendered HTML has all 6 `<img>` tags with `data-component-id="canvas:image"` and correct srcset.

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

## Homepage UUIDs

- **canvas_page UUID:** `bb5bbbb1-4a16-4b86-bbea-b215ab8096cf`
- **Component UUIDs (Section 2 logo-items):** see `content-exports/homepage-section-2.overlay.yml` for the 6 `logo-item-canvas` UUIDs that need the envelope patch.

(When another section starts, append its component UUID map here — saves re-grepping the overlay file every compaction.)

---

## Seeded media entities (client logos)

Media bundle: `image`. Files at `/sites/default/files/client-logos/`.

| mid | Brand       | Filename (approx)      |
|-----|-------------|------------------------|
| 41  | CBS         | cbs.*                  |
| 42  | DocuSign    | docusign.*             |
| 43  | Orange      | orange.*               |
| 44  | Renesas     | renesas.*              |
| 45  | Robert Half | robert-half.*          |
| 46  | Tesla       | tesla.*                |

Verify via `ddev drush sqlq "SELECT mid, name FROM media_field_data WHERE mid BETWEEN 41 AND 46"` before acting on these IDs — they were seeded earlier but a DB rollback could change them.

---

## Rollback points (code + DB)

Convention: `<slug>-YYYYMMDD-HHMM`. Same tag goes in the git commit message and the `ddev snapshot --name=` so they sort together.

| Tag | What it preserves | Notes |
|-----|-------------------|-------|
| `section2-envelope-20260421-1853` | Pre-envelope-fix homepage DB state (Section 2 broken, flat image shape) + gitignore rule committed at `74c8c7f`. | Use to re-reproduce the broken-flat-shape bug for debugging, or to roll back if Section 2's envelope apply turns out to have had a subtle regression elsewhere. |

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
3. **Section 3:** design + content TBD.
4. **Sections 4–6:** TBD.
5. **Existing `canvas-image` tab-panel fix:** re-apply with the correct envelope once we're back in that area. Now that the submit-time envelope shape is verified, this should be mechanical.
6. **Other pages** (services, how-we-do-it, etc.): post-homepage.
7. **Optional script cleanup (not urgent):** `scripts/dump-canvas-page.php` writes relative to drush CWD (`/var/www/html/web`), so dumps land at `web/content-exports/<uuid>.yml` instead of repo-root `content-exports/`. Harmless (now gitignored) but slightly confusing. A one-line fix would be to resolve the default output path relative to `__DIR__ . '/../content-exports/'`.

---

## Post-compaction checklist (for future Claude)

If you're reading this after a context compaction:

1. Read this whole file.
2. Read `.auto-memory/MEMORY.md` and any linked memories that look relevant.
3. Verify seeded media IDs still exist (see SQL above).
4. Verify the current homepage component state before mutating: `ddev drush php:script scripts/dump-canvas-page.php <homepage-uuid>` and diff against the last known overlay.
5. Check `git log --oneline -20` and `ddev snapshot --list` for the latest rollback tags.
6. Check if `scripts/claude-bridge.sh` is running (ask user or check for `.claude-bridge/` activity).
