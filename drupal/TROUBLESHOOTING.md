# Drupal Troubleshooting

Issues specific to Drupal config, modules, fields, taxonomies, and the PHP
runtime. For DDEV container/CLI issues that may surface as Drupal symptoms,
see [`ddev/TROUBLESHOOTING.md`](../ddev/TROUBLESHOOTING.md).

---

## 2.1 Drupal config import hangs

### Symptom
`ddev drush config:import` or `ddev drush php:eval` runs but never completes.

### Root Cause
1. **Module dependency loops**: Importing config that references modules not yet enabled.
2. **Database locks**: A previous import or update left a lock.
3. **Memory exhaustion**: PHP runs out of memory during large imports.

### Detection
```bash
# Check DDEV logs for PHP errors
ddev logs -s web | tail -50

# Check if PHP is still running inside the container
ddev exec ps aux | grep php
```

### Solution
1. `Ctrl+C` the stuck command.
2. `ddev drush cr` to clear caches.
3. Retry the import.
4. If persistent, check `ddev logs -s web` for fatal errors.

### Prevention
- Import configs in dependency order (fields before form displays).
- Clear cache after major config changes: `ddev drush cr`.

---

## 2.2 Taxonomy `event_type` vs `event_types` silent failure

### Symptom
Event Type dropdown appears on the form but has **zero options** — only "- Select a value -". No error is displayed. Tests waiting to select an option hang until timeout.

### Root Cause
The vocabulary machine name is `event_types` (**plural**), but the BUILD_LOG originally created terms with `vid => "event_type"` (singular). Drupal silently accepts terms with a non-existent `vid` — the terms are saved to the database but orphaned. The `taxonomy_access_fix` module's `TermSelection` handler calls `loadTree('event_type')`, which returns nothing because the vocabulary `event_type` doesn't exist.

### Detection
```bash
# Check actual vocabulary names
ddev drush php:eval '
$vocabs = \Drupal::entityTypeManager()->getStorage("taxonomy_vocabulary")->loadMultiple();
foreach ($vocabs as $v) echo $v->id() . " => " . $v->label() . "\n";
'

# Check if terms are in the right vocabulary
ddev drush php:eval '
echo "event_type: " . count(\Drupal::entityTypeManager()->getStorage("taxonomy_term")->loadByProperties(["vid" => "event_type"])) . "\n";
echo "event_types: " . count(\Drupal::entityTypeManager()->getStorage("taxonomy_term")->loadByProperties(["vid" => "event_types"])) . "\n";
'
```

### Solution
Delete orphaned terms and recreate with the correct `vid`:
```bash
ddev drush php:eval '
// Delete orphans
$terms = \Drupal::entityTypeManager()->getStorage("taxonomy_term")->loadByProperties(["vid" => "event_type"]);
foreach ($terms as $t) { $t->delete(); }

// Recreate with correct vid
foreach (["User group meeting", "DrupalCon", "Sprint"] as $name) {
  \Drupal\taxonomy\Entity\Term::create(["vid" => "event_types", "name" => $name])->save();
}
'
```

### Prevention
- The BUILD_LOG Step 170 now uses `event_types` with a `[!CAUTION]` warning.
- Always verify vocabulary machine names before creating terms:
  ```bash
  ddev drush ev 'echo \Drupal::entityTypeManager()->getStorage("taxonomy_vocabulary")->load("event_types")->label();'
  ```

---

## 2.3 `taxonomy_access_fix` blocking select options

### Symptom
Same as §2.2 — Event Type dropdown is empty. But terms DO exist in the correct vocabulary.

### Root Cause
Open Social ships with the `taxonomy_access_fix` module, which overrides Drupal's default entity reference selection handler with `Drupal\taxonomy_access_fix\TermSelection`. This handler checks `$term->access('select')` per-term, which requires the `select terms in {vocabulary_name}` permission. Without it, the handler returns zero results.

### Detection
```bash
ddev drush php:eval '
$handler = \Drupal::service("plugin.manager.entity_reference_selection")->getSelectionHandler(
  \Drupal\node\Entity\Node::create(["type" => "event"])->getFieldDefinition("field_event_type")
);
echo get_class($handler) . "\n";
echo "Options: " . array_sum(array_map("count", $handler->getReferenceableEntities())) . "\n";
'
```

If handler is `TermSelection` and count is 0, this is the issue.

### Solution
Grant the permission:
```bash
ddev drush role:perm:add authenticated "select terms in event_types"
ddev drush role:perm:add administrator "select terms in event_types"
```

### Prevention
- BUILD_LOG Step 170 now includes these permission grants with a `[!CAUTION]` block.
- After creating taxonomy terms, always verify they appear in form selects.

---

## 2.4 Missing form display configs

### Symptom
A form field (e.g., Event Type dropdown, revision log textarea) does not appear on the node add/edit form. Tests waiting for it hang until timeout.

### Root Cause
Drupal's form display configs (`core.entity_form_display.node.*.default.yml`) control which fields appear on forms and in what order. If these configs aren't imported, the field exists in the database but isn't rendered on the form.

### Detection
```bash
# Check what fields are in the form display
ddev drush php:eval '
$fd = \Drupal::entityTypeManager()->getStorage("entity_form_display")->load("node.event.default");
print_r(array_keys($fd->getComponents()));
'
```

### Solution
Import the form display config:
```bash
ddev drush config:import --partial --source=/path/to/config/sync
# or import specific file
ddev drush php:eval '...'
```

### Prevention
- BUILD_LOG Steps 145 and 205 import Event and Page form display configs.
- Always verify form fields appear after config imports.

---

## 2.5 PHP opcode cache stale class

*Discovered in session 85f9e13e*

### Symptom
The web process throws "class not found" errors (e.g., `WikiLinkFilter`) even though CLI (`ddev drush`) can see the class just fine. The module is installed, the file exists, but the web server can't find it.

### Root Cause
PHP's opcode cache (`opcache`) caches compiled bytecode in memory. When a module's PHP files are added or modified while the web server is running, the opcache may still serve the old (or absent) bytecode. CLI uses a separate opcache instance, so it works fine.

### Detection
- `ddev drush php:eval 'echo class_exists("Drupal\\mymodule\\MyClass") ? "YES" : "NO";'` returns YES
- But the web interface throws "class not found" or filter plugin errors

### Solution
```bash
ddev restart
```
This flushes the PHP opcode cache by restarting the web container.

### Prevention
- Always run `ddev restart` (not just `ddev drush cr`) after copying new PHP files into `web/modules/`.
- `ddev drush cr` clears Drupal caches but does NOT flush PHP's opcache.

---

## 2.6 Custom module stale registry (flat copy)

*Discovered in session 85f9e13e*

### Symptom
A custom module (e.g., `pl_opensocial_wiki`) is installed and the files exist in `web/modules/custom/`, but Drupal can't find it or reports "module not found" errors. The module was previously working.

### Root Cause
The module files were copied flat into `web/modules/custom/` (e.g., files like `pl_opensocial_wiki.info.yml` directly in `custom/`) instead of inside a proper subdirectory (`custom/pl_opensocial_wiki/pl_opensocial_wiki.info.yml`). Alternatively, the module was moved or renamed after being enabled, and Drupal's extension discovery cache still points to the old location.

### Detection
```bash
# Verify directory structure
ls web/modules/custom/pl_opensocial_wiki/
# Should contain: pl_opensocial_wiki.info.yml, src/, etc.

# If info.yml is directly in custom/ — that's the problem
ls web/modules/custom/*.info.yml
```

### Solution
1. Uninstall the module: `ddev drush pmu pl_opensocial_wiki -y`
2. Remove the incorrectly placed files
3. Re-copy with correct structure:
   ```bash
   cp -r ~/Sites/pl-opensocial/web/modules/custom/pl_opensocial_wiki \
         ~/Sites/pl-opensocial-rework/web/modules/custom/pl_opensocial_wiki
   ```
4. Clear cache: `ddev drush cr`
5. Re-enable: `ddev drush en pl_opensocial_wiki -y`
6. Restart to flush opcache: `ddev restart`

### Prevention
- Always copy module directories, not individual files.
- Always use `cp -r source/module_name/ destination/module_name/` preserving the directory structure.
- After copying modules, `ddev restart` (not just `ddev drush cr`) to ensure opcache picks up the new files.

---

## 2.7 WSOD from missing field storage

*Discovered in session e86dfac3*

### Symptom
White Screen of Death (WSOD) or a PHP fatal error immediately after importing a field configuration. The site becomes completely inaccessible via web browser. Drush commands may also fail.

### Root Cause
A field configuration YAML (e.g., `field.field.node.event.field_event_url`) was imported, but the underlying database storage table for that field doesn't exist. Drupal tries to query a non-existent table and crashes.

### Detection
```bash
# Check DDEV web logs for the PHP fatal
ddev logs -s web | tail -20
# Look for: "SQLSTATE[42S02]: Base table or view not found"
```

### Solution
Synchronize the field storage definitions:
```bash
ddev drush entity-updates
# or for specific fields:
ddev drush php:eval '
$update_manager = \Drupal::entityDefinitionUpdateManager();
$update_manager->applyUpdates();
echo "Storage updates applied.\n";
'
```

### Prevention
- Always import field **storage** configs before field **instance** configs.
- If a field already existed but was removed, ensure the storage table is recreated before re-importing.
- Check `ddev logs -s web` immediately after config imports for early warning signs.

---

## 2.8 Markdown filter escaping HTML

*Discovered in session e86dfac3*

### Symptom
Content with `<strong>`, `<a>`, or other HTML tags displays the raw HTML as text instead of rendering it. For example, `<strong>bold</strong>` shows as literal text on the page. Tests checking for rendered HTML fail.

### Root Cause
The `markdown` filter is enabled in the `full_html` text format. When active, it processes the content through a Markdown parser that escapes HTML entities, converting `<` to `&lt;`. This means raw HTML typed into CKEditor gets double-escaped.

### Detection
- View a node's rendered output and see literal `<strong>` text instead of bold.
- Check text format config:
```bash
ddev drush php:eval '
$format = \Drupal\filter\Entity\FilterFormat::load("full_html");
foreach ($format->filters() as $id => $filter) {
  if ($filter->status) echo "$id (weight: " . $filter->weight . ")\n";
}
'
```
If `filter_markdown` or `markdown` appears, that's the issue.

### Solution
Disable the markdown filter in `full_html`:
```bash
ddev drush php:eval '
$format = \Drupal\filter\Entity\FilterFormat::load("full_html");
$config = $format->filters("filter_markdown");
// Disable it
$format->setFilterConfig("filter_markdown", ["status" => FALSE]);
$format->save();
echo "Markdown filter disabled in full_html.\n";
'
```

### Prevention
- The BUILD_LOG Step 186 notes that the markdown filter should be disabled in `full_html`.
- Markdown and CKEditor are fundamentally incompatible — don't use both on the same text format.

---

## 2.9 Missing enrollment sub-modules

*Discovered in session e86dfac3*

### Symptom
The "Enroll" button is missing from event pages, or clicking it returns a 403 Forbidden error. Tests checking for enrollment functionality fail.

### Root Cause
Open Social's enrollment feature requires specific sub-modules that are not enabled by default:
- `social_event_an_enroll` — enables anonymous enrollment
- `social_event_max_enroll` — enables max enrollment limits

Additionally, the `authenticated` and `anonymous` roles need explicit enrollment permissions.

### Detection
```bash
# Check if enrollment modules are enabled
ddev drush pm:list --status=enabled | grep enroll

# Check enrollment permissions
ddev drush role:perm:list authenticated | grep enroll
```

### Solution
```bash
ddev drush en social_event_an_enroll social_event_max_enroll -y
ddev drush role:perm:add authenticated "add event enrollment entities"
ddev drush role:perm:add authenticated "view event enrollment entities"
ddev drush role:perm:add anonymous "add event enrollment entities"
```

### Prevention
- BUILD_LOG Phase 1/2 include these module enables and permission grants.
- Always verify enrollment UI after enabling event modules.

---

## 2.10 Missing frontend libraries

*Discovered in session e86dfac3*

### Symptom
JavaScript errors in the browser console. UI animations don't work. Buttons may appear unstyled. PHP warnings about missing `file_get_contents` for library files.

### Root Cause
Some libraries required by Open Social (e.g., `node-waves`, `autosize`) are not installed by Composer by default or are expected in `web/libraries/` but are missing.

### Detection
```bash
# Check for missing libraries
ls web/libraries/node-waves 2>/dev/null || echo "MISSING: node-waves"
ls web/libraries/autosize 2>/dev/null || echo "MISSING: autosize"

# Check PHP warnings in DDEV logs
ddev logs -s web | grep "file_get_contents.*libraries"
```

### Solution
Copy libraries from the source project:
```bash
cp -r ~/Sites/pl-opensocial/web/libraries/node-waves ~/Sites/pl-opensocial-rework/web/libraries/
cp -r ~/Sites/pl-opensocial/web/libraries/autosize ~/Sites/pl-opensocial-rework/web/libraries/
```
Or install via Composer if the source project uses asset-packagist.

### Prevention
- The BUILD_LOG includes steps to restore missing libraries.
- After `composer install`, verify `web/libraries/` contains all expected packages.
