# AI-Guided Theme Generation

This runbook outlines the standard operating procedure for AI developer agents tasked with safely creating a new testbed theme and translating UI screenshots into functional Drupal pages. 

> [!IMPORTANT]
> **Theme-Specific Run-Time Instruction**: At run-time, you MUST ask the user to provide the documentation folder path for their underlying base theme framework (e.g., `drupal/dripyard_themes`). You must thoroughly review all theme-specific instructions (such as component inventories and color management rules) stored in that folder before making architectural layout assumptions.

## Operating Principles
The primary objective is to ingest a UI screenshot, map its visual elements to the components provided by the user's specified base theme framework, and implement the resulting layout within Drupal. 

To ensure absolute safety and maintain a functional baseline for the host project, **AIs must first duplicate the existing stable theme into a new working directory before making any experimental layout or styling changes.**

---

## Phase 1: Pre-Execution Discovery
Before cloning repositories or running commands, the AI must collect all foundational environment variables and display them to the user for explicit confirmation.

1. Gather the following run-time parameters:
   - **Primary Active Theme Name** (e.g., `performant_labs`)
   - **Target Local Project Path** (e.g., `~/Sites/pl-performantlabs.com`)
   - **Base Theme Documentation Namespace** (e.g., `drupal/dripyard_themes`)
   - **Location of Target Layout Screenshots**
   - **Existing Site Audit**: Explicitly ask the user: *"Is there an existing version of this website already running locally that I should audit before building?"* If yes, ask for its local path (e.g., `~/Sites/pl-performantlabs.com`). Record the answer — a "yes" makes Phase 3 Step 2 **mandatory**, not optional.
   - **Local Runtime Environment**: Automatically test the target codebase to detect the active container wrapper (e.g., scan for `.ddev/` or `.lando.yml`). Report the detected runtime prefix (e.g., `ddev`, `lando`, or native) to the user rather than blindly assuming.
   - **Git Safety Check**: Run `git status` to verify the working tree is completely clean. If uncommitted changes exist, force the user to stash or commit them. Do not allow execution on a dirty tree.
2. Display these collected values back to the user in a formatted list or table.
3. Explicitly ask: *"Do these setup parameters look correct? Just give me the green light and we'll jump into Phase 2!"* DO NOT proceed until the user approves.

---

## Phase 2: Establish the Baseline Backup
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

---

## Phase 3: Screenshot Ingestion & Component Mapping
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
8. **Approval Checkpoint**: With the plan safely tracked in version control, you must explicitly STOP execution. Display your mapped strategy to the user and wait for their explicit manual approval before advancing into Phase 4 layout executions.

---

## Phase 4: Page Template Architecture
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
7. **Approval Checkpoint**: Confirm with the user that all required page structures are covered before proceeding to implementation.

---

## Phase 5: Implementation Execution
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

## Phase 6: Verification
1. **Manual Canvas Assembly Hold**: Because you just scaffolded structural SDC bundles into the `components/` directory, these elements are not inherently attached to a live route. You must STOP execution and explicitly instruct the user to:
   - Clear the Drupal cache (e.g., `[runtime_wrapper] drush cr`) so the theme registry discovers your new SDCs.
   - Assemble the layout inside the Drupal Canvas UI using your generated components.
   - Provide you with the URL of the finalized page.
2. **Browser Verification**: Once the user provides the rendered URL, load the Canvas page in the headless browser.
3. **Visual Regression**: Visually compare the rendered DOM output against the original target screenshot.
4. **Cascade Safety Check**: Verify that your custom CSS overrides remained perfectly encapsulated within the Canvas components and did not accidentally poison the broader global typography or color matrices expected natively by the host site.
5. **Failure Path**: If visual regression fails or the cascade check identifies layout pollution, do NOT leave the broken state committed. Immediately report the specific discrepancy to the user, revert the Phase 4 implementation commit (e.g. `git revert HEAD`), and return to Phase 4 Step 1 with the identified failures explicitly documented as constraints for the next attempt.

---

## Phase 7: Canvas Page Programmatic Assembly

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

### 8.4 Verify your work

After any programmatic wiring, always use the browser subagent to verify the rendered output. For items that may be in the DOM but not visually obvious (e.g., footer items that wrap to a second line), confirm with `curl`:

```bash
curl -s https://[site-url]/ -k | grep -i "[expected link text]"
```

Screenshots alone are not sufficient — a link that appears absent in a screenshot may simply be off-screen.

