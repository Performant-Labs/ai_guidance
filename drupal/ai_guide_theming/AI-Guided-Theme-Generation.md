# AI-Guided Theme Generation

This runbook outlines the standard operating procedure for AI developer agents tasked with safely creating a new testbed theme and translating UI screenshots into functional Drupal pages. 

> [!IMPORTANT]
> **Theme-Specific Run-Time Instruction**: At run-time, you MUST ask the user to provide the documentation folder path for their underlying base theme framework (e.g., `drupal/dripyard_themes`). You must thoroughly review all theme-specific instructions (such as component inventories and color management rules) stored in that folder before making architectural layout assumptions.

## Operating Principles
The primary objective is to ingest a UI screenshot, map its visual elements to the components provided by the user's specified base theme framework, and implement the resulting layout within Drupal. 

To ensure absolute safety and maintain a functional baseline for the host project, **AIs must first duplicate the existing stable theme into a new working directory before making any experimental layout or styling changes.**

> [!IMPORTANT]
> **Visual Remediation Phase**: When fixing structural or CSS gaps against a design reference (i.e., any work after the initial assembly), you MUST follow the `canvas-scripting-protocol.md` in this directory before writing any Drush script or Twig override. That document defines mandatory pre-flight checks, schema verification steps, script writing rules, and verification requirements that apply to all Canvas component work — initial build, additions, and updates alike.

---


## Phase 1: Pre-Execution Discovery
Before cloning repositories or running commands, the AI must collect all foundational environment variables and display them to the user for explicit confirmation.

1. Gather the following run-time parameters:
   - **Primary Active Theme Name** (e.g., `performant_labs`)
   - **Target Local Project Path** (e.g., `~/Sites/pl-performantlabs.com`)
   - **Base Theme Documentation Namespace** (e.g., `drupal/dripyard_themes`)
   - **Location of Target Layout Screenshots**
   - **Existing Site Audit**: Explicitly ask the user: *"Is there an existing version of this website already running locally that I should audit before building?"* If yes, ask for its local path (e.g., `~/Sites/pl-performantlabs.com`). Record the answer — a "yes" makes Phase 4 Step 2 **mandatory**, not optional.
   - **Local Runtime Environment**: Automatically test the target codebase to detect the active container wrapper (e.g., scan for `.ddev/` or `.lando.yml`). Report the detected runtime prefix (e.g., `ddev`, `lando`, or native) to the user rather than blindly assuming.
   - **Git Safety Check**: Run `git status` to verify the working tree is completely clean. If uncommitted changes exist, force the user to stash or commit them. Do not allow execution on a dirty tree.
2. Display these collected values back to the user in a formatted list or table.
3. Explicitly ask: *"Do these setup parameters look correct? Just give me the green light and we'll jump into Phase 2!"* DO NOT proceed until the user approves.

---

## Phase 2: Brand Asset Collection

Before cloning a single file or running any Drush command, the AI must collect all **ancillary brand identity assets**. These items are entirely independent of templates and components — they configure *what the theme looks like* rather than *how it lays out content*. Collecting them here prevents the recurring failure mode where body colors, logos, and the favicon remain as inherited parent-theme defaults until visual regression exposes them near the end of the project.

> [!IMPORTANT]
> Do NOT advance to Phase 3 until every item in the checklist below has been explicitly provided by the user **or** explicitly marked as "use parent theme default / skip."

### 2.1 Required checklist

Ask the user to provide **all of the following** at once. Present it as a single structured prompt so the user can answer in one pass:

| # | Asset | What to ask for | Format requirement |
|---|---|---|---|
| 1 | **Primary brand color** | The dominant brand color (e.g., navy, forest green) | Hex value — e.g., `#1B2638` |
| 2 | **Secondary / accent color** | The CTA / highlight color (e.g., amber, coral) | Hex value — e.g., `#F59E0B` |
| 3 | **Color brightness hints** | Are each of those colors perceived as light or dark backgrounds? | `light` or `dark` per color |
| 4 | **Logo file** | The site logo (SVG strongly preferred; PNG acceptable) | File path or paste SVG source |
| 5 | **Favicon** | A 32×32 or 64×64 icon (SVG or PNG) | File path or paste; `null` = generate from logo |
| 6 | **Site name** | The exact site name string displayed in the `<title>` tag and branding block | Plain text string |
| 7 | **Tagline / slogan** | One-line site tagline (displayed in header branding or footer) | Plain text string, or `none` |
| 8 | **Brand font(s)** | Primary heading font and body font names | Google Font name(s) or `use parent default` |
| 9 | **Social / OG image** | A 1200×630 image for Open Graph / Twitter cards | File path, or `generate from logo` |
| 10 | **Social profile URLs** | LinkedIn, GitHub, X/Twitter, etc. | List of full URLs; omit any that don't apply |

### 2.2 Execution steps (after user provides assets)

1. **Copy assets into the theme**: Place logos, favicons, and OG images into `web/themes/custom/[primary_theme]_[timestamp]/` (logo at root; others under `assets/`). Never reference parent-theme asset paths.
2. **Apply the color palette**: Write the two hex values into the theme's configuration:
   ```bash
   [runtime_wrapper] drush php-eval "
   \$config = \Drupal::configFactory()->getEditable('[theme_machine_name].settings');
   \$config->set('theme_colors.colors.base_primary_color', '#[HEX]');
   \$config->set('theme_colors.colors.base_primary_color_brightness', '[light|dark]');
   \$config->set('theme_colors.colors.base_secondary_color', '#[HEX]');
   \$config->set('theme_colors.colors.base_secondary_color_brightness', '[light|dark]');
   \$config->save();
   "
   [runtime_wrapper] drush cr
   ```
   > [!NOTE]
   > In NeonByte / Dripyard-based themes, the entire palette (all `--primary-*` and `--neutral-*` scale tokens) is derived from these two config values via `oklch()` in `variables-colors-semantic.css`. Setting them here drives all button colors, card borders, body backgrounds, and icon accents — no additional CSS is needed for the base palette.
3. **Wire the logo**: Confirm `system.theme.global` → `logo.path` points to your theme's `logo.svg`, **not** the parent theme's path. Export the config:
   ```bash
   [runtime_wrapper] drush config:get system.theme.global logo.path
   # Must return: themes/custom/[primary_theme]_[timestamp]/logo.svg
   # Must also confirm: use_default = false
   [runtime_wrapper] drush config:export --yes
   git add config/sync/ web/themes/custom/[primary_theme]_[timestamp]/logo.svg
   git commit -m "feat: brand assets — logo, palette, favicon"
   ```
   > [!NOTE]
   > Even with the correct SVG on disk and the correct config path, the **browser will continue to serve the cached NeonByte logo** until its HTTP cache for that asset expires or the user does a hard reload with DevTools open. This is a browser cache issue — not a server-side problem. Confirm via `curl -k https://[site-url]/themes/custom/[theme]/logo.svg | head -1` to verify the correct SVG is on disk.
4. **Apply the favicon**: Place the file at `web/themes/custom/[primary_theme]_[timestamp]/favicon.ico` (or `.png`). Update `system.theme.global` → `favicon.path` to point to it.
5. **Register brand fonts**: If custom Google Fonts are specified, add them to the theme's `.libraries.yml` and reference in `css/base.css`:
   ```css
   @import url('https://fonts.googleapis.com/css2?family=[FontName]:wght@400;600;700&display=swap');
   :root { --font-heading: '[FontName]', sans-serif; }
   ```
6. **Set social profile URLs**: Store these in the theme settings if the base theme provides social link fields, or note them for Twig injection in the footer template (Phase 7/8).

### 2.3 Verification

After applying, confirm in the browser that the `<html>` `style` attribute reflects the correct primary color:

```bash
curl -k -s https://[site-url]/ | grep "theme-setting-base-primary-color"
# Expected: --theme-setting-base-primary-color: #[your-hex];
```

> [!CAUTION]
> **Do not skip this verification.** If the hex value returned is the parent theme's default (e.g., `#0000d9` for NeonByte), the config write did not persist — re-run the `drush php-eval` block and cache rebuild before advancing.

### 2.4 Approval Checkpoint

Display the resolved asset list to the user (confirmed hex values, logo path, favicon path) and ask: *"Brand assets confirmed — shall I proceed to Phase 3?"* Do NOT advance until the user approves.

---

## Phase 3: Establish the Baseline Backup
Before altering any structural CSS or Layout builder templates, preserve the current customized primary theme.

1. **Clone**: Duplicate the primary stable directory (`web/themes/custom/[primary_theme]`) to a new working directory appending a date/timestamp (e.g., `web/themes/custom/[primary_theme]_20260411`).
2. **Refactor**: Perform a targeted find-and-replace to rename all machine names inside configuration files only. Scope this strictly to `.info.yml`, `.breakpoints.yml`, `.theme`, `.libraries.yml`, and `.yml` files. Do NOT run a broad replacement across all files — binary assets, images, and generic CSS class names must not be touched.
3. **Activate**: Enable the newly cloned layout theme and set it as the default theme via Drush, utilizing the runtime wrapper detected in Phase 1:

   ```bash
   [runtime_wrapper] drush theme:enable [primary_theme]_[timestamp]
   [runtime_wrapper] drush config:set system.theme default [primary_theme]_[timestamp] -y
   [runtime_wrapper] drush cr
   ```
4. **Result**: This preserves the original theme untouched. If the experimental implementations collapse the site layout, AIs can instantly revert the active system theme to the known-good configuration.
5. **Version Control Snapshot**: Add and commit only the cloned theme directory using its explicit path (e.g. `git add web/themes/custom/[primary_theme]_[timestamp] && git commit -m "chore: Branch new component testbed theme"`). Do NOT use `git add .` here — only stage the new theme directory to avoid accidentally committing unrelated working files.
6. **Canvas DB Snapshot**: Immediately after activating the new theme, take a snapshot of the Canvas component table. This is the rollback point if any assembly script puts the DB into a bad state:
   ```bash
   [runtime_wrapper] drush sql-dump --tables-list=canvas_page__components > drupal/ai_guide_theming/canvas_snapshot_pre_assembly.sql
   ```
   To restore: `[runtime_wrapper] drush sql-query --file=drupal/ai_guide_theming/canvas_snapshot_pre_assembly.sql`

   > [!IMPORTANT]
   > This snapshot file must NOT be committed to git — add it to `.gitignore`. It exists only as a local recovery tool.

---

## Phase 4: Screenshot Ingestion & Component Mapping
Once the user provides the target design:

1. **Asset Storage**: Immediately save the provided screenshot into a `/designs` or `/reference` directory inside the newly created active theme (e.g., `web/themes/custom/[primary_theme]_[timestamp]/designs/screenshot.png`). This ensures the AI context and layout references are permanently shipped alongside the theme files.
2. **Legacy Architecture Audit** *(mandatory if the user confirmed an existing site in Phase 1 — do not skip)*: Before making any assumptions about content types, block regions, menus, or page templates, you must audit the existing site. Skipping this step when a legacy site exists will cause structural mismatches in templates and sidebar wiring.

   - Target the local legacy codebase path recorded in Phase 1 (e.g., `~/Sites/pl-performantlabs.com`). **First, independently detect its runtime wrapper** (scan for `.ddev/`, `.lando.yml`, etc.) — it may differ from the primary project detected in Phase 1.
   - Audit all of the following via Drush introspection and structural analysis:
     - **Content types** and their field structures (which types serve as documentation, landing pages, articles, etc.)
     - **Menu structure** (primary nav, footer nav, any sidebar/TOC navigation menus)
     - **Block regions and placements** (which blocks go in which regions)
     - **Taxonomy vocabularies** (how content is organised and categorised)
     - **Active modules** that affect layout or routing (Views, Layout Builder, Paragraphs, etc.)
   - Draft this architectural dissection into an explicit Markdown file and save it within an `/audits` directory inside the new active theme (e.g., `web/themes/custom/[primary_theme]_[timestamp]/audits/legacy_dissection.md`).
   - The dissection output directly informs: template suggestion hooks, sidebar menu block choices, region wiring, and any additional content types to replicate.
3. **Visual Decomposition**: Analyze the screenshot to break down the UI into logical horizontal bands (e.g., Hero Banners, Feature Grids, Logo Arrays, Call-to-Action blocks).
4. **Component Cross-referencing**: Check these visual bands against your base theme's component library (identified via the documentation folder provided by the user) to identify completely reusable Twig structures and native CSS modifier classes.
5. **Gap Analysis**: Identify any bespoke elements in the screenshot that do not have a native equivalent in the base theme. These will require entirely custom CSS implementations.
6. **Implementation Plan Generation**: Synthesize your structural component findings and draft your `theme_component_mapping_plan.md` strategy directly into the specific theme documentation folder that the user provided natively at run-time (e.g., `drupal/dripyard_themes/`).
7. **Version Control Snapshot**: Immediately commit the raw target assets, the legacy audit (if generated), and your drafted component plan using explicit paths (e.g., `git add web/themes/custom/[primary_theme]_[timestamp]/designs web/themes/custom/[primary_theme]_[timestamp]/audits drupal/[theme_docs_namespace]/theme_component_mapping_plan.md && git commit -m "docs: Scaffold layout target assets and implementation mapping"`). Do NOT use `git add .` here.
8. **Component Cookbook** *(gate — must be complete before Approval Checkpoint)*: Before requesting user sign-off, build a lookup table of every component you plan to use in Phase 7 assembly. For each component, read its `.component.yml` and record:
   - The exact `component_id` string (e.g. `sdc.dripyard_base.flex-wrapper`)
   - Every **required** prop name with its valid enum values, copied verbatim from the schema
   - Every **slot** name, copied verbatim from the schema

   Save this table to `drupal/ai_guide_theming/component-cookbook.md`. It becomes the authoritative prop reference for every Phase 7 assembly script — no prop name may be written from memory during assembly.

   > [!CAUTION]
   > Do not guess prop names. A wrong prop name causes a silent drop or a `RuntimeError` on save. The cookbook prevents the "fix the fix" cycle.
   >
   > **Reference document**: [`drupal/ai_guide_theming/component-cookbook.md`](component-cookbook.md) — read this file in full at the start of Phase 7 before writing a single assembly script. It contains verbatim prop/slot names and a "Common Mistakes" table of props that have caused silent failures in past sessions.

9. **Approval Checkpoint**: With the plan and cookbook safely tracked in version control, you must explicitly STOP execution. Display your mapped strategy to the user and wait for their explicit manual approval before advancing into Phase 5 layout executions.

---

## Phase 5: Page Template Architecture
Before writing any component markup or CSS, define the page shells that those components will inhabit. This prevents building components that have no route to render into.

1. **Inventory page types in scope**: Determine all page structures the theme must support (e.g., full-width Canvas marketing page, documentation interior page with sidebar, standard utility page). Do not assume a single template covers the site.
2. **Identify the Canvas homepage node**: Confirm which node (or path) is the site front page. Do not create a new node if one already exists — verify via `system.site` configuration.
3. **Author the full-width Canvas page template**: Create `page--front.html.twig` (or `page--node--[nid].html.twig` if a specific node is the target) inside `web/themes/custom/[primary_theme]_[timestamp]/templates/layout/`. This template must:
   - Suppress the page title block (`page.page_title` or the `page-title.html.twig` region)
   - Remove any sidebar or constrained-width wrappers
   - Render `{{ page.content }}` edge-to-edge so Canvas blocks fill the full viewport width
   - Include the header and footer via the base theme's standard embeds
4. **Author the interior documentation page template**: Create a sidebar variant (e.g., `page--documentation.html.twig` or use a Layout Builder layout) that provides:
   - A persistent left sidebar region wired to a block region (e.g., `sidebar_first`) for the documentation index/TOC menu
   - A main content region for the body
   - Standard header and footer
   - Consider using a CSS Grid or Flexbox two-column layout scoped to this template; add the CSS to `css/base.css` under a page-level body class
5. **Wire up block regions**: Ensure the `[primary_theme]_[timestamp].info.yml` declares any new regions (e.g., `sidebar_first: Sidebar first`) required by the new templates. Verify the theme's `config/optional/` block placements cover these regions.
6. **Version Control Snapshot**: Commit all new template files and any `info.yml` region additions using explicit paths before advancing:
   ```bash
   git add web/themes/custom/[primary_theme]_[timestamp]/templates \
           web/themes/custom/[primary_theme]_[timestamp]/[primary_theme]_[timestamp].info.yml
   git commit -m "feat: scaffold page template variants (Canvas full-width + docs sidebar)"
   ```
7. **Structural Verification Gate** *(all checks must pass before proceeding)*:

   | Check | Command | Pass condition |
   |---|---|---|
   | Theme is active | `[runtime_wrapper] drush php-eval "echo \Drupal::config('system.theme')->get('default');"` | prints custom theme machine name (e.g. `performant_labs_20260411`) |
   | No PHP/Twig errors | `[runtime_wrapper] drush watchdog:show --count=20 --severity=3` | 0 new errors after `drush cr` — see watchdog interpretation note in `canvas-scripting-protocol.md` |
   | Front page returns 200 | `curl -k -o /dev/null -s -w "%{http_code}" [site-url]/` | `200` |
   | Front page template fires | `curl -sk [site-url]/ \| grep [unique-class-in-page--front.html.twig]` | match found |
   | Declared regions present | `curl -sk [site-url]/ \| grep -E "region-(header\|content\|footer)"` | all three match |

   **Fail path**: fix the specific template or region → re-run the gate → do not advance until all checks are green.

8. **Approval Checkpoint**: Confirm with the user that all required page structures are covered before proceeding to implementation.

---

## Phase 6: Implementation Execution
1. **Component Markup (Twig)**: For each mapped component in the approved strategy, author its structural markup as a Twig template (`.twig`) inside the relevant SDC bundle. Apply the proper `theme--[name]` CSS scoping wrappers inside the Twig output so each component inherits the theme's color palette overrides from `css/base.css` without hardcoding color values.
2. **Global CSS Overrides (Native Components)**: If the design dictates nuanced spacing or styling modifications for existing native components, append custom CSS explicitly targeting the Component Layer inside the new canvas theme's `css/base.css` file. DO NOT attempt to override semantic variables directly.
3. **Integration Strategy (Bespoke SDCs Enforced)**: When generating custom layout elements that do not exist natively, you MUST exclusively output standard **Single Directory Components (SDCs)** formatted within the active theme's `components/` directory (e.g., creating the `.component.yml`, `.twig`, and `.css` bundle). The styling for these bespoke components must be encapsulated entirely inside their local `.css` file, NOT in `base.css`. Do NOT output raw disconnected HTML payloads, and do NOT architect the output using custom Drupal Blocks, Layout Builder, or root Twig templates.
4. **AI Autonomous Content Population**: When structural components (like the "Product, Pricing, Blog" header navigation or dynamic card grids) require functional Drupal content to render, DO NOT manually construct UI configurations or write raw database queries.

   > [!WARNING]
   > **`drush scr -` (stdin pipe) does NOT accept `<?php` opening tags and will fail silently.** The heredoc-to-stdin pattern is unreliable. Instead, write a temporary `.php` file to the **project root** (never to `/tmp` or theme directories), execute it, then immediately delete it:
   > ```bash
   > cat > menus_populate.php << 'EOF'
   > <?php
   > // Drupal bootstrap is automatic via drush scr
   > use Drupal\menu_link_content\Entity\MenuLinkContent;
   > MenuLinkContent::create([...]) ->save();
   > EOF
   > [runtime_wrapper] drush scr menus_populate.php && rm menus_populate.php
   > ```
   > Writing to the project root keeps the file within the DDEV-mounted volume. Delete immediately after execution — never commit these scripts.
5. **Version Control Snapshot**: Commit the newly generated SDC bundles and CSS wrappers before handing off to the verification stage (e.g. `git commit -m "feat: Implement Canvas SDC component suite"`).

---

## Phase 7: Canvas Page Programmatic Assembly

> [!IMPORTANT]
> **Mandatory pre-reading before writing any script in this phase:**
> 1. [`drupal/ai_guide_theming/component-cookbook.md`](component-cookbook.md) — authoritative prop/slot names for every component. Never write an `inputs` JSON from memory.
> 2. [`drupal/ai_guide_theming/canvas-scripting-protocol.md`](canvas-scripting-protocol.md) — mandatory pre-flight checklist (schema check, template read, module availability, asset reachability, DB state, logo path, placeholder content scrub), script writing rules, and verification cadence.
>
> Both documents must be read **in full** before the first `drush scr` is written. Skipping either document is the single most common cause of multi-session fix loops.

The Canvas module stores home pages as `canvas_page` entities — **not** standard nodes. They cannot be created with `node_create`. All structural page content must be wired via the `canvas_page`'s `components` field.

### 7.1 Locating the Canvas home page

```bash
# Confirm the site front page route:
[runtime_wrapper] drush config:get system.site page.front
# output: /page/1  →  canvas_page entity ID 1. Edit at /page/[id]/edit
```

> [!IMPORTANT]
> Do NOT assume the front page is a node. `system.site page.front` may return `/page/[id]` (Canvas), not `/node/[nid]`.

### 7.2 Canvas component tree structure

The `components` field is a **flat array**. Nesting is expressed by `parent_uuid` references — not by PHP array nesting. Every component item requires these keys:

| Key | Notes |
|---|---|
| `component_id` | Full SDC ID e.g. `sdc.dripyard_base.section` |
| `component_version` | Set to `NULL` — Canvas auto-resolves on `preSave()`. Never hard-code a hash. |
| `uuid` | Must be unique. Use `Uuid::generate()` or a deterministic `md5(seed)` formatted as UUID. |
| `parent_uuid` | `NULL` for root items. Must exactly match the parent's `uuid`. |
| `slot` | `NULL` for root. Must match a named slot in the parent's `.component.yml`. |
| `inputs` | JSON array. **Must exactly match the component's schema props.** |
| `label` | `NULL` is safe. |
| `weight` | Integer position relative to siblings. |

### 7.3 SDC schema validation rules

> [!CAUTION]
> Canvas validates every `inputs` array against the component's `.component.yml` schema on save. Any violation silently drops the component or throws a `RuntimeError` during rendering. Always cross-reference the actual `.component.yml` file before setting props.

Known schema gotchas from `dripyard_base`:

| Component | Common mistake | Correct prop |
|---|---|---|
| `heading` | Key named `heading` | Use `text` for the heading string |
| `heading` | `margin_top: 0` (integer) | Must be an enum string e.g. `"none"`, `"sm"`, `"md"`, `"lg"` |
| `canvas-image` | Omitting `loading` | `loading` is **required**: `"eager"` or `"lazy"`. Null throws a `RuntimeError` from `image-or-media`. |
| `icon-list-item` | Using `text` for the label | Use `title` |

> [!TIP]
> If a `canvas-image` has no real image source yet, **replace it with `sdc.[theme].text`** as a placeholder. The `text` component has no required props that cause rendering failures.

### 7.4 Diagnosing Canvas rendering errors

```bash
# Check watchdog for RuntimeError entries:
[runtime_wrapper] drush watchdog:show --count=10 --severity=3

# Inspect the raw stored component by UUID:
[runtime_wrapper] drush sql-query "SELECT components_component_id, components_component_version, \
  components_inputs FROM canvas_page__components WHERE components_uuid='[uuid]';"

# If DB data is correct but error persists — flush render cache at DB level:
[runtime_wrapper] drush sql-query "TRUNCATE TABLE cache_render; TRUNCATE TABLE cache_menu;"
[runtime_wrapper] drush cr
```

> [!NOTE]
> A `RuntimeError` referencing a UUID whose DB data is correct usually means a **stale render cache** — not bad data. Always truncate `cache_render` before concluding the stored data is wrong.

### 7.5 Canvas assembly cadence

Assemble the Canvas page one visual section at a time, in top-to-bottom order matching the design. Each section is one script, one verification, one commit.

```
[Section name]  →  write script  →  per-section gate  →  commit  →  next section
```

**Rules:**
- One script covers exactly one visual section (hero, features, carousel, tabbed section, etc.). Never combine unrelated mutations in a single script.
- Every script ends with a DB verification query before clearing cache:
  ```php
  // At the end of every assembly script, before cache clear:
  $rows = \Drupal::database()->select('canvas_page__components', 'c')
    ->fields('c', ['components_uuid', 'components_component_id', 'components_inputs'])
    ->condition('c.components_uuid', $uuid_you_just_wrote)
    ->execute()->fetchAll();
  print_r($rows); // Must return exactly one row with correct data
  ```
- Commit after each verified section: `git commit -m "feat(canvas): assemble [section name] section"`
- If a script fails, restore from the Phase 3 Canvas DB snapshot rather than writing a second fix script on top of an uncertain state.

### 7.6 Per-section structural gate *(run after every assembly script)*

Before committing a section and moving to the next, two checks must pass:

```bash
# 1. UUID exists in DB (replace [uuid] with the root component UUID you just wrote):
[runtime_wrapper] drush sql-query \
  "SELECT components_uuid, components_component_id FROM canvas_page__components \
   WHERE entity_id=1 AND components_uuid='[uuid]';"
# Must return exactly 1 row.

# 2. Section renders in the DOM:
curl -sk [site-url]/ | grep -i "[unique class or landmark text from this section]"
# Must return a match.
```

**Fail path**: do not write a second fix script on top of uncertain state. Restore from the Phase 3 Canvas DB snapshot, identify the root cause against the pre-flight checklist in `canvas-scripting-protocol.md`, and re-run the section script.

### 7.7 End-of-phase full tree audit *(run once after all sections assembled)*

```bash
# Count total components — must match your cookbook's expected total:
[runtime_wrapper] drush sql-query \
  "SELECT COUNT(*) FROM canvas_page__components WHERE entity_id=1 AND deleted=0;"

# Check for orphaned components:
[runtime_wrapper] drush php-eval "
\$rows = \Drupal::database()->select('canvas_page__components','c')
  ->fields('c',['components_uuid','components_parent_uuid','components_component_id'])
  ->condition('entity_id',1)->condition('deleted',0)->execute()->fetchAll();
\$uuids = array_column(\$rows,'components_uuid');
foreach (\$rows as \$r) {
  if (\$r->components_parent_uuid && !in_array(\$r->components_parent_uuid,\$uuids)) {
    echo 'ORPHAN: '.\$r->components_uuid.' parent='.\$r->components_parent_uuid.PHP_EOL;
  }
}
echo 'Done.'.PHP_EOL;
"
# Must return 'Done.' with zero ORPHAN lines.
```

**Pass**: all sections verified, no orphans → commit the full assembly snapshot → proceed to Phase 8.
**Fail**: fix the specific orphan or missing component → re-run 7.7 before proceeding.

---

## Phase 8: Menu & Block Wiring (Programmatic)

Never use the Drupal admin UI to wire menus or place blocks. Use `drush scr` scripts for all wiring.

### 8.1 Menu population pattern


```php
<?php
use Drupal\menu_link_content\Entity\MenuLinkContent;

// Clear before repopulating to avoid duplicates:
$old = \Drupal::entityTypeManager()->getStorage('menu_link_content')
  ->loadByProperties(['menu_name' => 'main']);
foreach ($old as $item) { $item->delete(); }

MenuLinkContent::create([
  'title'     => 'Services',
  'link'      => ['uri' => 'internal:/services'],
  'menu_name' => 'main',
  'weight'    => 0,
  'expanded'  => FALSE,
])->save();

\Drupal::service('plugin.manager.menu.link')->rebuild();
```

> [!WARNING]
> **Menu links to inaccessible routes are silently hidden for anonymous users.** If a menu item disappears, check the target node's publication state. If content moderation is active, `$node->set('status', 1)->save()` alone does NOT publish a node — you must set `$node->set('moderation_state', 'published')->save()`. Verify with: `drush php-eval "\$n = \Drupal::entityTypeManager()->getStorage('node')->load([nid]); echo \$n->moderation_state->value;"`

### 8.2 Block placement pattern

```php
<?php
use Drupal\block\Entity\Block;

Block::create([
  'id'       => '[theme_machine_name]_book_navigation',
  'theme'    => '[theme_machine_name]',
  'region'   => 'sidebar_first',
  'plugin'   => 'book_navigation',
  'weight'   => 0,
  'status'   => TRUE,
  'settings' => ['id' => 'book_navigation', 'label_display' => '0',
                 'block_mode' => 'book pages', 'provider' => 'book'],
  'visibility' => [
    'node_type' => [
      'id'      => 'entity_bundle:node',
      'bundles' => ['book' => 'book'],
      'negate'  => FALSE,
      'context_mapping' => ['node' => '@node.node_route_context:node'],
    ],
  ],
])->save();
```

### 8.3 Config sync directory

DDEV defaults `config_sync_directory` to `sites/default/files/sync` (gitignored) unless overridden. To track config in the project root's `config/sync` directory, add this to `settings.php` **before** the DDEV include block:

```php
// Point config sync to the tracked directory at the project root.
// Must appear BEFORE the IS_DDEV_PROJECT include so DDEV's fallback is skipped.
$settings['config_sync_directory'] = '../config/sync';
```

Then export: `[runtime_wrapper] drush config:export --yes`

> [!NOTE]
> `settings.php` is gitignored (contains secrets). This setting must be added on each environment or via a post-provision hook. It does not get committed.

### 8.4 Structural Verification Gate *(all checks must pass before proceeding to Phase 9)*

| Check | Command | Pass condition |
|---|---|---|
| Main nav has items | `[runtime_wrapper] drush php-eval "print_r(\Drupal::entityTypeManager()->getStorage('menu_link_content')->loadByProperties(['menu_name'=>'main']));"` | ≥ 1 item returned |
| Footer nav has items | same, swap `'main'` for footer menu machine name | ≥ 1 item returned |
| Expected blocks in regions | `[runtime_wrapper] drush php-eval "\$blocks=\Drupal::entityTypeManager()->getStorage('block')->loadByProperties(['theme'=>'[theme_machine_name]']); foreach(\$blocks as \$b){echo \$b->id().': '.\$b->getRegion().PHP_EOL;}"` | all expected blocks show a region ≠ `none` |
| Anonymous front page | `curl -k -o /dev/null -s -w "%{http_code}" [site-url]/` | `200` (not `403` or `302`) |
| Nav items visible to anon | `curl -sk [site-url]/ \| grep -i "[first nav item text]"` | match found |
| No new errors | `[runtime_wrapper] drush watchdog:show --count=10 --severity=3` | 0 new errors |

**Fail path**: fix the specific wiring issue → re-run only the failed check → commit → proceed to Phase 9 only when all checks are green.

---

## Phase 9: Content Migration

> [!IMPORTANT]
> **Mandatory pre-reading**: Read [`drupal/ai_guide_theming/content-migration-cookbook.md`](content-migration-cookbook.md) in full before writing any script or running any Drush command in this phase. It contains all inventory commands, migration patterns, dependency ordering, the form framework assessment, and the verification gate.

1. **DDEV multi-project**: Start the source site alongside the target — `cd [source-path] && ddev start`. Both run simultaneously; the shared `ddev-router` handles both by subdomain. No conflict expected.
2. **Run inventory** (cookbook §0–§8 inventory commands): Execute against the source site. Present each category as a structured table — one category at a time. Do not dump all categories simultaneously.
3. **User selection gate**: For each category, the user assigns a disposition to every item (bring as-is / modify / placeholder stub / skip). **Do NOT proceed to migration until all categories have explicit dispositions.**
4. **Execute migration in dependency order** (cookbook §0 → §1 → §2 → §3 → §4 → §5 → §6 → §7 → §8). One category per script. Verify each category before moving to the next. Commit after each verified category.
5. **Verification gate** (cookbook §Verification): Run node counts, alias spot-checks, media counts, image style audit, and Canvas placeholder scan. Must pass before Phase 10.

---

## Phase 10: Verification

Verification is split into two sequential sub-phases. **Phase 10.2 must not begin until Phase 10.1 passes.** Structure was verified inline during Phases 5, 7, and 8 — Phase 10 tests visual presentation only.

### Phase 10.1 — Content Audit

Scan every Canvas text-bearing component for placeholder copy before any screenshot is taken. Base themes (NeonByte, Keytail, Dripyard) ship demo content that is structurally invisible — it passes layout checks but contains the wrong words.

```bash
# Scan all Canvas inputs for known placeholder phrases:
[runtime_wrapper] drush sql-query \
  "SELECT delta, components_component_id, components_inputs \
   FROM canvas_page__components WHERE entity_id=1 ORDER BY delta;" \
  | grep -iE "keytail|neonbyte|SDRs hit|Get found|lorem ipsum|Search and outreach"
# Must return 0 matches.

# Verify hero h1 contains approved client copy:
curl -sk [site-url]/ | grep -i "[approved hero headline]"
# Must return a match.

# Verify nav labels match approved content:
curl -sk [site-url]/ | grep -iE "[nav-label-1]|[nav-label-2]"
```

**Pass**: 0 placeholder matches, all approved copy present → proceed to Phase 10.2.
**Fail**: update via the keyed-replacement pattern in `canvas-scripting-protocol.md` → re-run the scan → do not open a browser until this gate is green.

> [!CAUTION]
> A Phase 10.2 visual regression finding should **never** be "wrong text." If it is, Phase 10.1 was not run correctly. Return to 10.1.

### Phase 10.2 — Visual Regression

Visually compare the rendered page against the original target design slices, panel by panel.

> [!IMPORTANT]
> **Do not attempt visual regression in a single subagent call.** Previous sessions crashed repeatedly because the scope (6+ screenshots + a 9,902 px reference image) exceeded the agent's context budget. You MUST follow the panel-by-panel protocol defined in:
> **[`drupal/ai_guide_theming/visual-regression-strategy.md`](visual-regression-strategy.md)**
>
> Key rules:
> - One subagent call = one design slice vs. one live viewport. Nine slices = nine sequential calls.
> - Use the pre-sliced assets in `designs/` (`00_menu.webp` … `08_footer.webp`). Never pass the full composite image as a MediaPath — it will exhaust context alone.
> - Each subagent call must append its findings to `drupal/ai_guide_theming/visual-regression-report.md` before returning.
> - Phase 9.2 evaluates layout, color, spacing, and typography **only**. Content correctness is not re-evaluated here.

**Cascade Safety Check**: After visual regression, confirm custom CSS overrides remained encapsulated and did not pollute global typography or color tokens expected by the host site.

**Failure path**: If visual regression fails, do NOT leave the broken state committed. Report the specific discrepancy, revert the Phase 6 implementation commit (`git revert HEAD`), and return to Phase 6 with the failures documented as explicit constraints.

