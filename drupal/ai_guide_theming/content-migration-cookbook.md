# Content Migration Cookbook

This document is the authoritative reference for **Phase 9: Content Migration**
in the AI-Guided Theme Generation SOP. It is a companion to
`component-cookbook.md` (Canvas assembly) and
`canvas-scripting-protocol.md` (scripting rules).

Read this document **in full** before writing any script or running any
Drush command in Phase 9.

---

## Dependency Order

Content entities reference configuration and other content entities.
Migrate in this order — do not skip ahead:

| Step | Category | Reason for this position |
|---|---|---|
| **§-1** | **Module Audit** | Modules must be reconciled before content types, Views, or forms are migrated — missing modules will silently block everything downstream |
| §0 | **Site configuration** | Image styles, text formats, Views — everything else depends on these |
| §1 | **Taxonomy** | Nodes reference terms via field |
| §2 | **Media** | Nodes reference media entities via field |
| §3 | **Basic pages** | Standalone — no dependencies after §0 |
| §4 | **Articles** | Require taxonomy (§1) and optional media (§2) |
| §5 | **Book / Documentation pages** | Require assessment before migration |
| §6 | **Canvas marketing copy** | Independent — no entity dependencies |
| §7 | **Custom block content** | May reference nodes |
| §8 | **Forms (Webform vs. DCMS)** | Config entity — requires framework assessment |

---

## DDEV Multi-Project Setup

Both the source and target sites can run simultaneously. DDEV's shared
`ddev-router` container handles multiple projects by subdomain — one per
project `name` in `.ddev/config.yaml`.

To start the source site without stopping the target:

```bash
cd [path-to-source-site]
ddev start
# The router is already running. DDEV registers the new project automatically.
# No conflict expected.
```

Confirm both are running:
```bash
ddev list
# Both projects should show "running" status with their respective URLs.
```

> [!NOTE]
> The router conflict seen in early sessions was caused by a stale Docker
> container (`docker rm -f ddev-router` resolves it). It is not a
> fundamental DDEV limitation.

---

## §-1 — Module Audit (run first, before everything)

> [!IMPORTANT]
> This step was added after a live migration revealed that Webform was
> missing on the target — causing §8 to require a reactive install rather
> than a planned one. Always run this step before §0.

Modules that provide content types, fields, Views, or form builders must
exist on the **target** before their config or content is migrated.
Running a config import for a View that depends on a missing module will
fail silently or throw a schema validation error with a confusing message.

### Inventory commands

```bash
# 1. Export enabled module list from SOURCE:
cd [source-path]
ddev drush pm:list --status=enabled --field=name 2>/dev/null | sort > /tmp/source_modules.txt

# 2. Export enabled module list from TARGET:
cd [target-path]
ddev drush pm:list --status=enabled --field=name 2>/dev/null | sort > /tmp/target_modules.txt

# 3. Show what is on SOURCE but NOT on TARGET (the delta):
comm -23 /tmp/source_modules.txt /tmp/target_modules.txt
```

### Decision framework

For each module in the delta, assign one of these dispositions:

| Disposition | When to use |
|---|---|
| ✅ **Install on target** | Module provides functionality the new site needs (e.g. Webform, Redirect) |
| 🔄 **DCMS equivalent exists** | Source module is superseded by a DCMS module (e.g. `layout_builder` → Canvas/SDC, `entity_browser` → `media_library`) |
| ❌ **Skip** | Internal dev tooling, legacy module, or no content depends on it |

### Common source → DCMS equivalents

| Source module | DCMS equivalent | Notes |
|---|---|---|
| `layout_builder` + `layout_builder_kit` | Canvas / SDC components | DCMS uses Canvas for page building |
| `entity_browser` / `media_entity_browser` | `media_library` | DCMS ships `media_library` |
| `paragraphs` / `entity_reference_revisions` | Canvas component fields | Not needed if Canvas is used |
| `responsive_menu` | Navigation module or theme | DCMS uses the Navigation module |
| `manage_display` | Core display modes | Core handles this natively |
| `publication_date` | Scheduler / core `created` field | DCMS uses Scheduler |
| `allowed_formats` | `content_format` text format | DCMS has a single rich-text format |
| `ga4_google_analytics` | Assess: install or use tag manager | Install if site needs GA4 |

### Install pattern

```bash
cd [target-path]

# Install a module:
ddev composer require drupal/[module_name]
ddev drush pm:enable --yes [module_machine_name]
ddev drush cr

# Export the updated config immediately:
ddev drush config:export --yes
```

> [!CAUTION]
> Install all required modules **before** importing any config that depends
> on them. A `config:import --partial` run against a module that is not
> yet installed will fail with a dependency error.

---

## §0 — Site Configuration (migrate first)

Configuration entities are the foundation everything else depends on.
Import them **before** creating any taxonomy, media, or nodes.

### Inventory (source site)

```bash
cd [source-path]

# List all image styles:
ddev drush php-eval "
\$styles = \Drupal::entityTypeManager()
  ->getStorage('image_style')->loadMultiple();
foreach(\$styles as \$s) echo \$s->id().' | '.\$s->label().'\n';"

# List responsive image styles:
ddev drush php-eval "
\$styles = \Drupal::entityTypeManager()
  ->getStorage('responsive_image_style')->loadMultiple();
foreach(\$styles as \$s) echo \$s->id().' | '.\$s->label().'\n';"

# List text formats:
ddev drush php-eval "
\$formats = \Drupal::entityTypeManager()
  ->getStorage('filter_format')->loadMultiple();
foreach(\$formats as \$f) echo \$f->id().' | '.\$f->label().'\n';"

# List Views:
ddev drush php-eval "
\$views = \Drupal::entityTypeManager()
  ->getStorage('view')->loadMultiple();
foreach(\$views as \$v) if(\$v->status()) echo \$v->id().' | '.\$v->label().'\n';"

# List Pathauto patterns:
ddev drush php-eval "
\$patterns = \Drupal::entityTypeManager()
  ->getStorage('pathauto_pattern')->loadMultiple();
foreach(\$patterns as \$p) echo \$p->id().' | '.\$p->label().' | '.\$p->getPattern().'\n';"
```

### Migration pattern

Export source config, copy specific files, partial import on target:

```bash
# 1. Export all config from source:
cd [source-path] && ddev drush config:export --yes

# 2. Copy only the relevant files to the target config/sync:
cp [source]/config/sync/image.style.*.yml         [target]/config/sync/
cp [source]/config/sync/responsive_image.styles.*.yml [target]/config/sync/
cp [source]/config/sync/filter.format.*.yml       [target]/config/sync/
cp [source]/config/sync/editor.editor.*.yml       [target]/config/sync/
cp [source]/config/sync/views.view.*.yml          [target]/config/sync/
cp [source]/config/sync/pathauto.pattern.*.yml    [target]/config/sync/
cp [source]/config/sync/core.date_format.*.yml    [target]/config/sync/
cp [source]/config/sync/redirect.redirect.*.yml   [target]/config/sync/
# Copy field display modes selectively (check for conflicts first):
# cp [source]/config/sync/core.entity_view_display.node.[type].*.yml [target]/config/sync/

# 3. Partial import on target site:
cd [target-path]
ddev drush config:import --partial --yes
ddev drush cr
```

> [!CAUTION]
> **Never run a full `drush config:import` (without `--partial`)** using
> source site config. It will override the target site's theme, Canvas
> setup, and block placements. `--partial` imports only the files present
> in the sync directory without touching anything else.

> [!CAUTION]
> **Check for dependency conflicts before importing Views.** A View
> that references a field or content type that does not exist on the
> target site will throw a schema validation error on import. **Views
> that reference article/book content types must not be imported until
> those content types exist on the target.** Inspect each
> `views.view.*.yml` file before copying.

> [!CAUTION]
> **Do not import `field.storage.*` configs that already exist on the
> target.** DCMS 2.0 ships its own `field_tags`, `field_featured_image`,
> etc. Importing source versions will cause a "Delete" action in the
> diff which removes the target's field storage. Check with
> `drush php-eval` before copying any `field.storage.node.*.yml`.

> [!NOTE]
> **Text format mapping**: Source sites commonly use `basic_html` or
> `full_html` for body fields. DCMS 2.0 uses `content_format` as its
> single rich-text format. When importing `field.field.node.article.body.yml`
> or similar, patch the format reference before import:
> `sed -i '' 's/full_html/content_format/g' field.field.node.article.body.yml`
> and use `'format' => 'content_format'` in all `Node::create()` calls.

---

## §1 — Taxonomy

### Inventory (source site)

```bash
ddev drush php-eval "
\$vocabs = \Drupal::entityTypeManager()
  ->getStorage('taxonomy_vocabulary')->loadMultiple();
foreach(\$vocabs as \$v) {
  \$terms = \Drupal::entityTypeManager()
    ->getStorage('taxonomy_term')
    ->loadByProperties(['vid' => \$v->id()]);
  echo PHP_EOL.'Vocabulary: '.\$v->id().' ('.\$v->label().')'.PHP_EOL;
  foreach(\$terms as \$t) echo '  ['.\$t->id().'] '.\$t->label().PHP_EOL;
}"
```

### Migration pattern

```php
<?php
use Drupal\taxonomy\Entity\Term;

// Create vocabulary first if it doesn't exist on target:
// (Usually handled by config import in §0 — check before creating)

Term::create([
  'vid'    => 'tags',           // vocabulary machine name
  'name'   => 'Automated Testing',
  'weight' => 0,
])->save();
```

> [!NOTE]
> Record the new term IDs as you create them — article nodes reference
> terms by entity ID, which will differ between source and target.

---

## §2 — Media

### Inventory (source site)

```bash
ddev drush php-eval "
\$items = \Drupal::entityTypeManager()->getStorage('media')->loadMultiple();
foreach(\$items as \$m) {
  echo \$m->bundle().' | ['.\$m->id().'] '.\$m->label().PHP_EOL;
}"
```

### Migration pattern

```php
<?php
use Drupal\media\Entity\Media;

// 1. Fetch the file and write to the target's managed filesystem:
\$source_url = 'https://[source-site-url]/[path-to-image]';
\$data = file_get_contents(\$source_url);
\$file = \Drupal::service('file.repository')->writeData(
  \$data,
  'public://[year-month]/[filename.ext]',
  \Drupal\Core\File\FileSystemInterface::EXISTS_REPLACE
);

// 2. Create the media entity:
\$media = Media::create([
  'bundle'            => 'image',
  'name'              => 'Descriptive label (used as alt text fallback)',
  'field_media_image' => [
    'target_id' => \$file->id(),
    'alt'       => 'Descriptive alt text',
    'title'     => '',
  ],
  'status' => 1,
]);
\$media->save();
echo 'Media ID: '.\$media->id().PHP_EOL;
```

> [!CAUTION]
> `file_save_data()` is deprecated in Drupal 10+. Always use
> `\Drupal::service('file.repository')->writeData()`.

> [!NOTE]
> Record the new media IDs as you create them — article nodes reference
> media by entity ID, which will differ between source and target.

---

## §3 — Basic Pages

### Inventory (source site)

```bash
ddev drush php-eval "
\$nodes = \Drupal::entityTypeManager()->getStorage('node')
  ->loadByProperties(['type' => 'page', 'status' => 1]);
foreach(\$nodes as \$n) {
  \$alias = \Drupal::service('path_alias.manager')
    ->getAliasByPath('/node/'.\$n->id());
  \$body  = strip_tags(substr(\$n->body->value ?? '', 0, 120));
  echo '['.\$n->id().'] '.\$n->label().' | '.\$alias.PHP_EOL;
  echo '  '.trim(\$body).'...'.PHP_EOL;
}"
```

### Migration pattern

> [!NOTE]
> DCMS 2.0 uses `field_content` (text_long) instead of `body`, and
> `content_format` instead of `basic_html`/`full_html`. Check what
> fields the target page type has before running:
> `drush php-eval "foreach(\Drupal::service('entity_field.manager')->getFieldDefinitions('node','page') as \$n=>\$d) if(str_starts_with(\$n,'field_')||\$n==='body') echo \$n.' ('.$d->getType().')\n';"`

```php
<?php
use Drupal\node\Entity\Node;
use Drupal\path_alias\Entity\PathAlias;

\$node = Node::create([
  'type'          => 'page',
  'title'         => 'Services',
  'field_content' => [            // DCMS uses field_content not body
    'value'  => '<p>Body copy here.</p>',
    'format' => 'content_format', // DCMS text format (not basic_html)
  ],
  'status' => 1,
]);
\$node->save();

// Set URL alias immediately after save:
PathAlias::create([
  'path'     => '/node/' . \$node->id(),
  'alias'    => '/services',
  'langcode' => 'en',
])->save();

echo 'Page created: '.\$node->id().' at /services'.PHP_EOL;
```

---

## §4 — Articles

### Inventory (source site)

```bash
ddev drush php-eval "
\$nodes = \Drupal::entityTypeManager()->getStorage('node')
  ->loadByProperties(['type' => 'article', 'status' => 1]);
foreach(\$nodes as \$n) {
  \$alias = \Drupal::service('path_alias.manager')
    ->getAliasByPath('/node/'.\$n->id());
  \$tags  = [];
  if (\$n->hasField('field_tags')) {
    foreach(\$n->field_tags as \$ref) \$tags[] = \$ref->entity->label();
  }
  echo '['.\$n->id().'] '.\$n->label().PHP_EOL;
  echo '  alias: '.\$alias.PHP_EOL;
  echo '  tags: '.implode(', ', \$tags).PHP_EOL;
}"
```

### Content type migration

The `article` content type may not exist on the target DCMS site. Import
it via config before creating any article nodes:

```bash
# 1. Export source config:
cd [source-path] && ddev drush config:export --yes

# 2. Copy minimal config (do NOT copy display/form displays — they have
#    module dependencies that will fail on the target):
cp [source]/config/sync/node.type.article.yml            [target]/config/sync/
cp [source]/config/sync/field.storage.node.body.yml      [target]/config/sync/
cp [source]/config/sync/field.storage.node.field_summary.yml [target]/config/sync/
cp [source]/config/sync/field.storage.node.field_image.yml   [target]/config/sync/
cp [source]/config/sync/field.field.node.article.body.yml    [target]/config/sync/
cp [source]/config/sync/field.field.node.article.field_tags.yml  [target]/config/sync/
cp [source]/config/sync/field.field.node.article.field_summary.yml [target]/config/sync/
cp [source]/config/sync/field.field.node.article.field_image.yml   [target]/config/sync/
# DO NOT copy: field.storage.node.field_tags (already exists on target)
# DO NOT copy: core.entity_view_display.node.article.* (has module deps)
# DO NOT copy: core.entity_form_display.node.article.* (has module deps)

# 3. Patch text format references in the field configs:
sed -i '' 's/full_html/content_format/g' [target]/config/sync/field.field.node.article.body.yml
sed -i '' 's/basic_html/content_format/g' [target]/config/sync/field.field.node.article.field_summary.yml

# 4. Import:
cd [target-path] && ddev drush config:import --partial --yes
```

### Node migration pattern

```php
<?php
use Drupal\node\Entity\Node;
use Drupal\path_alias\Entity\PathAlias;

// Use term IDs recorded during §1 migration:
\$node = Node::create([
  'type'       => 'article',
  'title'      => 'Why Drupal?',
  'body'       => [
    'value'    => '<p>...</p>',
    'format'   => 'content_format', // NOT basic_html
  ],
  'field_tags'  => [['target_id' => \$term_id_automated_testing]],
  'field_image' => [['target_id' => \$media_id_hero]],  // optional
  'status'      => 1,
  'created'     => strtotime('2023-06-15'), // preserve original date
]);
\$node->save();

PathAlias::create([
  'path'     => '/node/' . \$node->id(),
  'alias'    => '/articles/why-drupal',
  'langcode' => 'en',
])->save();
```

---

## §5 — Book / Documentation Pages

### Assessment (run before migration)

Before migrating any book pages, the agent must determine whether
migration is needed. Run this check on the **target** site:

```bash
cd [target-path]

# How many book nodes currently exist?
ddev drush php-eval "
\$count = \Drupal::entityQuery('node')
  ->condition('type','book')->condition('status',1)
  ->accessCheck(FALSE)->count()->execute();
echo 'Book nodes on target: '.\$count.PHP_EOL;"

# List their titles and compare to the source:
ddev drush php-eval "
\$nodes = \Drupal::entityTypeManager()->getStorage('node')
  ->loadByProperties(['type'=>'book','status'=>1]);
foreach(\$nodes as \$n) echo \$n->id().' | '.\$n->label().PHP_EOL;"
```

**Decision logic:**
- If target has **≥ source book node count** and titles match → **skip §5**, book pages are current from the ATK repository.
- If target has **fewer or different** book pages → migrate the missing pages using the pattern below.
- Present the comparison to the user before executing any migration scripts.

### Migration pattern (if needed)

> [!CAUTION]
> Setting `'book' => [...]` inside `Node::create()` does **not** persist
> the book hierarchy. The `book` table is a separate database record.
> Always use `\Drupal::database()->merge('book')` after `->save()`.
> Sort nodes by `depth` ascending before iterating so parents are
> created before their children, and build a `source_nid → target_nid`
> map to resolve `pid` (parent ID) references.

```php
<?php
use Drupal\node\Entity\Node;
use Drupal\path_alias\Entity\PathAlias;

// $items = nodes sorted by depth ASC (roots first)
// $nid_map = [source_nid => target_nid] built as nodes are created

\$node = Node::create([
  'type'   => 'book',
  'title'  => 'Getting Started',
  'body'   => ['value' => '<p>...</p>', 'format' => 'content_format'],
  'status' => 1,
]);
\$node->save();
\$new_nid = \$node->id();
\$nid_map[\$source_nid] = \$new_nid;

// For root nodes (bid == nid on source), target_bid = own new nid:
\$target_bid = (\$source_bid === \$source_nid)
  ? \$new_nid
  : \$nid_map[\$source_bid];
\$target_pid = \$nid_map[\$source_pid] ?? 0;

// Write book hierarchy directly to the book table:
\Drupal::database()->merge('book')
  ->key('nid', \$new_nid)
  ->fields([
    'nid'    => \$new_nid,
    'bid'    => \$target_bid,
    'pid'    => \$target_pid,
    'weight' => \$item['weight'],
    'depth'  => \$item['depth'],
  ])
  ->execute();

// Set alias:
PathAlias::create([
  'path' => '/node/' . \$new_nid, 'alias' => \$item['alias'], 'langcode' => 'en',
])->save();
```

---

## §6 — Canvas Marketing Copy

The Canvas homepage marketing copy is independent — it does not reference
taxonomy, media, or nodes. It can be migrated at any point after §0.

Cross-reference: **`canvas-scripting-protocol.md` §Keyed Replacement Pattern**

### Inventory (target site)

```bash
cd [target-path]
ddev drush sql-query \
  "SELECT delta, components_component_id, components_inputs
   FROM canvas_page__components WHERE entity_id=1 ORDER BY delta;"
```

Present this as a section-by-section table to the user for copy approval.

### Migration pattern

```php
<?php
\$page = \Drupal::entityTypeManager()->getStorage('canvas_page')->load(1);
\$comps = \$page->get('components')->getValue();

foreach (\$comps as &\$comp) {
  if (\$comp['uuid'] !== '[target-uuid]') continue;
  \$inputs = json_decode(\$comp['inputs'], true);
  // Strip HTML tags before string comparison (inputs may be HTML-encoded):
  \$inputs['text'] = '<p>[Approved copy from user]</p>';
  \$comp['inputs'] = json_encode(\$inputs);
}
unset(\$comp);
\$page->set('components', \$comps)->save();
```

---

## §7 — Custom Block Content

### Inventory (source site)

```bash
ddev drush php-eval "
\$blocks = \Drupal::entityTypeManager()
  ->getStorage('block_content')->loadMultiple();
foreach(\$blocks as \$b) {
  \$body = strip_tags(substr(\$b->body->value ?? '', 0, 80));
  echo \$b->bundle().' | ['.\$b->id().'] '.\$b->label().PHP_EOL;
  echo '  '.trim(\$body).'...'.PHP_EOL;
}"
```

### Migration pattern

```php
<?php
use Drupal\block_content\Entity\BlockContent;

\$block = BlockContent::create([
  'type'  => 'basic',
  'info'  => 'Footer CTA',
  'body'  => ['value' => '<p>...</p>', 'format' => 'content_format'],
]);
\$block->save();
```

---

## §8 — Forms

### Framework Assessment (run first)

The target site was built on Drupal CMS 2.0. Before deciding how to
migrate the contact form, the agent must assess what form builder is
available:

```bash
cd [target-path]

# Check if Webform is installed:
ddev drush php-eval "echo \Drupal::moduleHandler()->moduleExists('webform') ? 'Webform: YES' : 'Webform: NO';"

# Check Contact module (Drupal core):
ddev drush php-eval "echo \Drupal::moduleHandler()->moduleExists('contact') ? 'Contact module: YES' : 'Contact module: NO';"

# Check for any DCMS-specific form builders:
ddev drush pm:list --status=enabled 2>/dev/null | grep -iE "form|webform|contact|eform"
```

**Decision logic based on findings:**

| Target has | Recommendation |
|---|---|
| Webform enabled | Export source `webform.[id].yml` → `config:import --partial`. Webform field config travels with the config entity. |
| Webform not installed | Install: `ddev composer require "drupal/webform:^6.3@beta"` (Drupal 11 requires 6.3.x; 6.2.x is D10 only) then `ddev drush pm:enable webform && ddev drush cr`. Then recreate the form fields via the API or export/import. |
| A DCMS-native form module | Recreate the form fields using that module's API/UI. Note which fields existed on the source form. |

### Source form inventory

```bash
cd [source-path]

# List all webforms:
ddev drush php-eval "
if (\Drupal::moduleHandler()->moduleExists('webform')) {
  \$forms = \Drupal::entityTypeManager()
    ->getStorage('webform')->loadMultiple();
  foreach(\$forms as \$f) {
    echo \$f->id().' | '.\$f->label().PHP_EOL;
    foreach(\$f->getElementsDecodedAndFlattened() as \$key => \$el) {
      echo '  '.\$key.': '.(\$el['#type'] ?? '?').
           ' | '.(\$el['#title'] ?? '').PHP_EOL;
    }
  }
} else echo 'Webform not enabled on source.'.PHP_EOL;"
```

### Webform migration pattern (if applicable)

```bash
cd [source-path] && ddev drush config:export --yes
cp [source]/config/sync/webform.[machine_name].yml [target]/config/sync/
cd [target-path] && ddev drush config:import --partial --yes
```

---

## User Selection Protocol

Present each category as a Markdown table before migrating it.
One category at a time — do not present all categories simultaneously.

```markdown
**Category: Articles — 8 items found**

| ID | Title | Tags | Path | Disposition |
|---|---|---|---|---|
| 42 | Why Drupal? | Drupal, Strategy | /articles/why-drupal | ✅ |
| 43 | We all benefit from Open Source | Community | /articles/we-all-benefit | ✅ |
| 44 | Layout Builder Can Break Your Site | Testing | /articles/layout-builder-... | ✏️ |
```

**Disposition key:**
- ✅ **Bring across as-is** — migrate verbatim
- ✏️ **Bring across with changes** — user provides edits inline in the same table row
- ⏸️ **Placeholder stub** — create the node/term with title only, body TBD
- ❌ **Skip** — do not migrate

---

## Verification Gate

Run after all categories are complete, before Phase 10:

```bash
cd [target-path]

# Node counts by type:
ddev drush php-eval "
foreach(['page','article','book'] as \$type) {
  \$c = \Drupal::entityQuery('node')->condition('type',\$type)
    ->condition('status',1)->accessCheck(FALSE)->count()->execute();
  echo \$type.': '.\$c.PHP_EOL;
}"

# Taxonomy term count:
ddev drush php-eval "
\$c = \Drupal::entityQuery('taxonomy_term')
  ->accessCheck(FALSE)->count()->execute();
echo 'Taxonomy terms: '.\$c.PHP_EOL;"

# Media count:
ddev drush php-eval "
\$c = \Drupal::entityQuery('media')
  ->accessCheck(FALSE)->count()->execute();
echo 'Media entities: '.\$c.PHP_EOL;"

# Image styles landed:
ddev drush php-eval "
\$styles = \Drupal::entityTypeManager()
  ->getStorage('image_style')->loadMultiple();
echo 'Image styles: '.count(\$styles).PHP_EOL;"

# Path aliases — spot check:
ddev drush php-eval "
\$mgr = \Drupal::service('path_alias.manager');
foreach(['/services','/articles','/contact'] as \$a) {
  echo \$a.' => '.\$mgr->getPathByAlias(\$a).PHP_EOL;
}"

# Canvas: no placeholder copy remaining:
ddev drush sql-query \
  \"SELECT delta, components_component_id, components_inputs
    FROM canvas_page__components WHERE entity_id=1;\" \
  | grep -iE 'keytail|neonbyte|lorem ipsum|placeholder'
# Must return 0 matches.
```

**Pass**: counts match approved selections, aliases resolve, no placeholder
copy → Phase 10 (Verification).
**Fail**: fix the specific missing item, re-run only the affected sub-step,
re-run only the relevant gate check.
