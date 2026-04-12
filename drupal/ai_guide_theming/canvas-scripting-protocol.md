# Canvas Scripting Protocol

This document defines the mandatory pre-flight checklist that must pass before any Drush script or Twig override is written that touches Canvas page components. It applies equally to initial assembly, additions, and corrections. It was created after a session where multiple fix scripts were required because these checks were skipped.

---

## The Core Problem

Every failure in that session shared one root cause: **writing code before verifying the constraints the code must operate within**. The fixes broke because:

- Prop names were guessed instead of read from the schema
- Module availability was assumed instead of verified
- Component rendering behaviour was inferred instead of read from the Twig template

The rule is simple: **read before you write.** This applies equally whether building from scratch or making a targeted change.

---

## Mandatory Pre-Flight Checklist

Run this checklist **before writing any fix script or template override**. If any item cannot be confirmed, find the answer before continuing.

### 1. Canvas Component Schema Check (required for every Canvas component being created or modified)

```bash
# Find and print the schema before writing the inputs JSON
cat web/themes/contrib/dripyard_base/components/<component-name>/<component-name>.component.yml
```

**What to confirm before writing the script:**
- [ ] Every `required` prop is included in the `inputs` JSON with valid enum values
- [ ] Every prop name is copied exactly from the schema (no guessing `direction` vs `flex_direction`)
- [ ] Every slot name used in `$c['slot']` is copied exactly from the `slots:` block in the schema
- [ ] The `component_id` string is `sdc.<theme-namespace>.<component-name>` — verify the namespace from the schema file's path

### 2. Component Template Read (required when changing layout or nesting)

```bash
# Read the actual Twig before deciding on a layout approach
cat web/themes/contrib/<base-theme>/components/<component-name>/<component-name>.twig
```

**What to confirm:**
- [ ] Understand what the component renders internally — if it already renders a button, wrapping it in a flex container won't affect the button's layout
- [ ] Identify which CSS classes are applied to the outer wrapper — this determines what CSS selectors will work
- [ ] Identify the slot variable names used in the template (e.g., `{{ content }}` vs `{{ flex_items }}`) — these must match the `slot` field in the DB row

### 3. Module Availability Check (required before using any entity type or API class)

```bash
ddev drush pml --status=enabled | grep <module-name>
```

**What to confirm:**
- [ ] The module is `Enabled` before using its entity type (e.g., `block_content`, `paragraphs`)
- [ ] If not enabled, choose an alternative approach that does not require it

### 4. Image / Asset Reachability Check (required before referencing any file path in `inputs` JSON)

```bash
curl -k -o /dev/null -s -w "%{http_code}" "https://<local-site>/<path-to-asset>"
# Must return 200 before using the path
```

### 5. Existing DB State Check (required before any mutation script)

```bash
ddev drush sql-query "SELECT delta, components_uuid, components_component_id, components_parent_uuid, components_slot, components_inputs FROM canvas_page__components WHERE entity_id=1 AND deleted=0 ORDER BY delta;"
```

**What to confirm:**
- [ ] The UUIDs you intend to modify actually exist in the current DB state
- [ ] The parent/slot relationships you intend to create don't already exist (avoid duplicates)
- [ ] After any previous script ran, verify it actually committed before running the next one

### 6. Logo Path Verification (required when branding changes are involved)

```bash
[runtime_wrapper] drush php-eval "
\$g = \Drupal::config('system.theme.global')->get();
echo 'use_default: ' . var_export(\$g['logo']['use_default'], true) . PHP_EOL;
echo 'path: ' . \$g['logo']['path'] . PHP_EOL;
"
# use_default must be FALSE and path must point to the custom theme, not contrib
curl -k -s https://[site-url]/[expected-logo-path] | head -1
# Must return the correct SVG opening tag, not the parent theme's fallback
```

> [!NOTE]
> Browser cache will continue to serve the old logo even after the correct SVG is on disk. Confirm server-side via `curl` rather than a browser screenshot. Hard reload (Cmd+Shift+R with DevTools open, "Disable cache" checked) is required to verify visually.

### 7. Placeholder Content Scrub (required before Phase 10.1 Content Audit)

Base themes ship demo copy in Canvas components. Before any visual regression screenshot is taken, scan for and replace all non-client text:

```bash
[runtime_wrapper] drush sql-query \
  "SELECT delta, components_component_id, components_inputs FROM canvas_page__components WHERE entity_id=1 ORDER BY delta;" \
  | grep -i 'keytail\|neonbyte\|SDRs hit\|Get found\|Search and outreach'
```

If any matches appear, update them via the entity API (see **Keyed replacement pattern** in Script Writing Rules below).

---

## Script Writing Rules

### One script, one responsibility
Each Drush script must do exactly one thing. Never combine unrelated mutations. If fixing the tab section and the hero, write `fix_tabs.php` and `fix_hero.php` separately.

**Why:** When a multi-mutation script fails mid-way, the DB is left in a partially-mutated state that requires investigation before continuing.

### Always include a verification query at the end of every script

```php
// At the end of every fix script, after $page->save():
$verify = \Drupal::database()->select('canvas_page__components', 'c')
  ->fields('c', ['components_uuid', 'components_component_id', 'components_inputs'])
  ->condition('c.entity_id', 1)
  ->condition('c.components_uuid', $the_uuid_you_just_wrote)
  ->execute()
  ->fetchAll();
echo "Verification:\n";
print_r($verify);
```

### Always delete the script file in the same command

```bash
ddev drush scr fix_something.php && rm fix_something.php
```

If the script fails, the file remains for inspection. If it succeeds, it's gone. Never leave `.php` scripts in the project root.

### Use `json_decode(..., true)` to read existing inputs before overwriting

```php
// WRONG — overwrites everything:
$c['inputs'] = json_encode(['new_prop' => 'value']);

// CORRECT — preserves existing values:
$inputs = json_decode($c['inputs'], true);
$inputs['new_prop'] = 'value';
$c['inputs'] = json_encode($inputs);
```

### Do not use static class references in Drush scripts

```php
// WRONG — class may not be autoloaded:
$entity = \Drupal\block_content\Entity\BlockContent::create([...]);

// CORRECT — always use the entity type manager:
$entity = \Drupal::entityTypeManager()->getStorage('block_content')->create([...]);
```

### Keyed replacement pattern for bulk content updates

When replacing multiple placeholder strings across many components, use a keyed array and iterate — never write one script per field:

```php
<?php
$replacements = [
  'Old demo headline text'   => 'New client headline text',
  'Another demo string'      => 'Another client string',
];

$page = \Drupal::entityTypeManager()->getStorage('canvas_page')->load(1);
$comps = $page->get('components')->getValue();

foreach ($comps as &$comp) {
  $inputs = json_decode($comp['inputs'] ?? '{}', true);
  $changed = false;
  foreach (['title', 'text'] as $field) {
    if (isset($inputs[$field])) {
      $clean = strip_tags($inputs[$field]);
      if (array_key_exists($clean, $replacements)) {
        $inputs[$field] = $replacements[$clean];
        $changed = true;
      }
    }
  }
  if ($changed) { $comp['inputs'] = json_encode($inputs); }
}
unset($comp);

$page->set('components', $comps)->save();
```

> [!NOTE]
> `strip_tags()` is required before the key lookup because some text fields contain HTML (`<p>` wrappers). The replacement value is stored as plain text — the SDC template wraps it appropriately.

---

## Template Override Rules

### Always copy-then-modify — never write a template from scratch

```bash
# Copy the base theme template first
cp web/themes/contrib/<base-theme>/templates/layout/page.html.twig \
   web/themes/custom/<custom-theme>/templates/layout/page.html.twig
```

Then modify only the specific lines that need to change. This ensures the surrounding Twig structure (variable names, embed blocks) stays in sync with the base theme.

### Verify the slot variable name in the header component before overriding

```bash
# Check what variable name the header SDC actually uses
cat web/themes/contrib/neonbyte/components/header/header/header.twig | grep header_third
```

Only then write the Twig `set` injection.

---

## Watchdog Error Interpretation

When checking `drush watchdog:show` during a gate, not every error record is a live page error. Failed `drush scr` runs log their schema validation failures to watchdog at severity=3, making them look identical to runtime rendering errors.

**How to tell them apart — check the backtrace:**

| Backtrace contains | Means |
|---|---|
| `/var/www/html/fix_*.php` or `/var/www/html/[script_name].php` | Error from a **failed `drush scr` run** — not a live page error. Check the script's exit status instead. |
| `HtmlRenderer.php`, `HttpKernel.php`, `PageCache.php` | Error from a **live page request** — must be investigated and fixed before proceeding. |

**Timestamp as a secondary signal**: errors from script runs will have a timestamp matching when you ran the script, not matching a browser page load. Use:
```bash
# Convert a watchdog timestamp to human-readable:
[runtime_wrapper] drush php-eval "echo date('Y-m-d H:i:s', [wid_timestamp]);"
```

> [!NOTE]
> A watchdog error from a failed script does not mean the page is broken — it means the script itself failed. Confirm the page still returns 200 and the component tree is intact before concluding there is a live issue.

---

## Verification After Every Fix

After every script or template change, always confirm the fix via the browser **before** moving to the next item on the checklist.

```
Confirm → Screenshot → Check visually → Mark item done → Next
```

Never batch multiple unverified fixes. A second broken fix on top of a broken first fix creates a compound state that is very hard to debug.

---

## Priority Order Reference

When executing visual remediation, always work from this table — top to bottom, one row at a time:

| Priority | Indicator | Fix type |
|---|---|---|
| 🔴 Now | Site is broken / content is visibly wrong for anonymous users | Must fix before anything else |
| 🟠 High | Major structural gap vs. design (missing layout, missing section) | Fix in current session |
| 🟡 Medium | Visual gap that requires CSS or component extension | Fix in next session |
| 🟢 Low | Minor polish (colour, spacing, icon swap) | Fix in polish pass |
