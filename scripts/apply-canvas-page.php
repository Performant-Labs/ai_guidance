<?php

/**
 * @file
 * Applies a sparse overlay YAML to an existing canvas_page entity.
 *
 * Companion to scripts/dump-canvas-page.php. Designed for iterative,
 * section-by-section content swaps during the Phase 3 homepage rebuild
 * where each pass touches only a handful of components and we want a
 * reviewable diff per pass.
 *
 * Overlay YAML shape:
 *
 *   _meta:
 *     version: '1.0'
 *     entity_type: canvas_page
 *     uuid: bb5bbbb1-4a16-4b86-bbea-b215ab8096cf
 *   overlay:
 *     title: "New page title"                # optional
 *     status: true                            # optional
 *     description: "Meta description"         # optional
 *     component_inputs:
 *       <component-instance-uuid>:
 *         <input_key>: <new_value>
 *         <input_key>: <new_value>
 *
 * For `component_inputs`, the script loads the current components array,
 * finds each targeted component by UUID, decodes its JSON-encoded inputs,
 * array_merges the patch over the existing inputs (preserving untouched
 * keys), and re-encodes to match Canvas's on-disk format.
 *
 * Structural additions are supported via `add_components` (append a block
 * of one-or-more components after a named anchor in the stored array).
 * Removals, reorders, and in-place component_id / slot / parent_uuid
 * changes are still out of scope — those require a full YAML replace.
 *
 * `add_components` shape:
 *
 *   add_components:
 *     after_uuid: <existing-component-uuid>   # insertion anchor
 *     components:
 *       - uuid: <new-uuid>
 *         component_id: sdc.foo.bar
 *         component_version: <hash>
 *         parent_uuid: <uuid-or-omit-for-root>
 *         slot: <slot-or-omit-for-root>
 *         inputs: { ... raw object; script json_encodes it ... }
 *
 * The whole block is inserted as a contiguous run right after the anchor
 * in the stored components array. Children must appear after their parent
 * in the list (Canvas stores the tree flattened in traversal order).
 *
 * Idempotency: if the FIRST new uuid already exists on the page, the
 * entire add block is skipped and reported — safe to re-run.
 *
 * Usage (from inside DDEV, CWD = /var/www/html/web for drush php:script):
 *   ddev drush php:script scripts/apply-canvas-page.php \
 *     ../content-exports/homepage-section-1.overlay.yml
 *
 * Add `dry-run` as the second extra arg to preview without saving. (No
 * leading dashes — drush's own option parser intercepts `--foo` flags
 * before they reach the script.)
 *   ddev drush php:script scripts/apply-canvas-page.php \
 *     ../content-exports/homepage-section-1.overlay.yml dry-run
 */

declare(strict_types=1);

use Symfony\Component\Yaml\Yaml;

/** @var array $extra — provided by drush php:script */
$path = $extra[0] ?? NULL;
$dry_run = in_array('dry-run', $extra, TRUE) || in_array('dryrun', $extra, TRUE);

if (!$path) {
  fwrite(STDERR, "Usage: drush php:script scripts/apply-canvas-page.php <path-to-overlay.yml> [dry-run]\n");
  return 1;
}
if (!is_readable($path)) {
  fwrite(STDERR, "Cannot read {$path}\n");
  return 1;
}

$data = Yaml::parseFile($path);
$uuid = $data['_meta']['uuid'] ?? NULL;
$entity_type = $data['_meta']['entity_type'] ?? 'canvas_page';

if (!$uuid) {
  fwrite(STDERR, "Overlay missing _meta.uuid\n");
  return 1;
}

$entity = \Drupal::service('entity.repository')
  ->loadEntityByUuid($entity_type, $uuid);

if (!$entity) {
  fwrite(STDERR, "No {$entity_type} found with UUID {$uuid}\n");
  return 1;
}

$overlay = $data['overlay'] ?? [];
$changes = [];

// Simple scalar fields.
foreach (['title', 'status', 'description'] as $field) {
  if (array_key_exists($field, $overlay)) {
    $old = $entity->get($field)->value;
    $new = $overlay[$field];
    if ($old !== $new) {
      $entity->set($field, $new);
      $changes[] = "{$field}: " . var_export($old, TRUE) . " → " . var_export($new, TRUE);
    }
  }
}

// Component input patches.
if (!empty($overlay['component_inputs'])) {
  $components = $entity->get('components')->getValue();
  $target_uuids = $overlay['component_inputs'];
  $touched = [];

  foreach ($components as &$component) {
    if (!isset($target_uuids[$component['uuid']])) {
      continue;
    }
    $patch = $target_uuids[$component['uuid']];
    $inputs = is_string($component['inputs'])
      ? json_decode($component['inputs'], TRUE)
      : ($component['inputs'] ?? []);
    $before = $inputs;
    $inputs = array_replace($inputs, $patch);

    // Canvas stores inputs as a JSON string. Match default encode flags
    // (escaped slashes + unicode) to minimize diff noise.
    $component['inputs'] = json_encode($inputs);

    foreach ($patch as $k => $v) {
      $changes[] = "component {$component['uuid']} ({$component['component_id']}) → {$k}: "
        . var_export($before[$k] ?? NULL, TRUE) . " → " . var_export($v, TRUE);
    }
    $touched[] = $component['uuid'];
  }
  unset($component);

  // Warn about any UUIDs in the overlay that weren't found on the page.
  $missing = array_diff(array_keys($target_uuids), $touched);
  foreach ($missing as $m) {
    fwrite(STDERR, "WARNING: overlay UUID {$m} not found on the page — skipped.\n");
  }

  $entity->set('components', $components);
}

// Structural additions: append a contiguous block of new components after
// a named anchor in the stored array.
if (!empty($overlay['add_components'])) {
  $add = $overlay['add_components'];
  $anchor = $add['after_uuid'] ?? NULL;
  $new_components = $add['components'] ?? [];

  if (!$anchor) {
    fwrite(STDERR, "add_components missing after_uuid — skipped.\n");
  }
  elseif (empty($new_components)) {
    fwrite(STDERR, "add_components.components is empty — nothing to add.\n");
  }
  else {
    // Reload components fresh so we layer cleanly on top of any
    // component_inputs patches applied above.
    $components = $entity->get('components')->getValue();
    $existing_uuids = array_column($components, 'uuid');

    // Idempotency: if the first new uuid already lives on the page, assume
    // the whole block has been applied before and skip.
    $first_new_uuid = $new_components[0]['uuid'] ?? NULL;
    if ($first_new_uuid && in_array($first_new_uuid, $existing_uuids, TRUE)) {
      $changes[] = "add_components: skipped (first new uuid {$first_new_uuid} already present — assumed previously applied)";
    }
    else {
      // Locate anchor index.
      $anchor_index = NULL;
      foreach ($components as $i => $c) {
        if (($c['uuid'] ?? NULL) === $anchor) {
          $anchor_index = $i;
          break;
        }
      }
      if ($anchor_index === NULL) {
        fwrite(STDERR, "add_components: anchor {$anchor} not found on the page — skipped.\n");
      }
      else {
        // Build the normalized component records Canvas expects.
        $built = [];
        foreach ($new_components as $nc) {
          if (empty($nc['uuid']) || empty($nc['component_id']) || empty($nc['component_version'])) {
            fwrite(STDERR, "add_components: entry missing uuid/component_id/component_version — aborting add.\n");
            $built = NULL;
            break;
          }
          if (in_array($nc['uuid'], $existing_uuids, TRUE)) {
            fwrite(STDERR, "add_components: uuid {$nc['uuid']} already on page — aborting add (partial prior apply?).\n");
            $built = NULL;
            break;
          }
          $record = [
            'uuid' => $nc['uuid'],
            'component_id' => $nc['component_id'],
            'component_version' => $nc['component_version'],
            // Canvas stores inputs as a JSON string on content entities.
            'inputs' => json_encode($nc['inputs'] ?? (object) []),
            'label' => $nc['label'] ?? NULL,
          ];
          if (!empty($nc['parent_uuid'])) {
            $record['parent_uuid'] = $nc['parent_uuid'];
          }
          if (!empty($nc['slot'])) {
            $record['slot'] = $nc['slot'];
          }
          $built[] = $record;
        }

        if ($built !== NULL) {
          $before = array_slice($components, 0, $anchor_index + 1);
          $after = array_slice($components, $anchor_index + 1);
          $components = array_merge($before, $built, $after);
          $entity->set('components', $components);
          foreach ($built as $b) {
            $parent_note = !empty($b['parent_uuid']) ? " (parent {$b['parent_uuid']}, slot {$b['slot']})" : ' (root)';
            $changes[] = "+ component {$b['uuid']} {$b['component_id']}{$parent_note}";
          }
          $changes[] = "inserted " . count($built) . " components after anchor {$anchor} (position " . ($anchor_index + 1) . ")";
        }
      }
    }
  }
}

if (empty($changes)) {
  echo "No changes to apply.\n";
  return 0;
}

echo "Planned changes:\n";
foreach ($changes as $c) {
  echo "  - {$c}\n";
}

if ($dry_run) {
  echo "\n--dry-run — not saving.\n";
  return 0;
}

$entity->save();
\Drupal::service('cache_tags.invalidator')
  ->invalidateTags($entity->getCacheTagsToInvalidate());

echo "\nSaved canvas_page {$uuid}.\n";
