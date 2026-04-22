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
 * `add_components` shape (single block):
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
 * `add_components` shape (multiple blocks — a list of the above):
 *
 *   add_components:
 *     - after_uuid: <uuid-1>
 *       components: [ ... ]
 *     - after_uuid: <uuid-2>
 *       components: [ ... ]
 *
 * Multi-block shape is needed when one overlay must insert new
 * components at more than one anchor point in the flat components array
 * (e.g. new hero children in §1 AND new root sections between §3 and
 * §4 in the same pass). Each block inserts as a contiguous run right
 * after its own anchor; blocks are processed in listed order and each
 * block sees the in-memory state left by the prior block. Children must
 * still appear after their parent within each block's component list
 * (Canvas stores the tree flattened in traversal order).
 *
 * Idempotency: each block is checked independently — if the FIRST new
 * uuid of a block already exists on the page, that block is skipped and
 * reported, while subsequent blocks continue to be evaluated. Safe to
 * re-run.
 *
 * `remove_components` shape:
 *
 *   remove_components:
 *     - <uuid-1>
 *     - <uuid-2>
 *
 * Removes each named UUID AND all descendants (anything whose parent_uuid
 * transitively matches a to-remove UUID), so removing a section wrapper
 * cleans up its whole subtree and nothing is orphaned. Idempotent: UUIDs
 * not present are silently ignored.
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

// Structural additions: append one or more contiguous blocks of new
// components after named anchors in the stored array. Accepts either a
// single block (associative shape with 'after_uuid' + 'components' at
// top level) or a list of blocks (numerically indexed array of such
// blocks).
if (!empty($overlay['add_components'])) {
  $adds = $overlay['add_components'];
  $blocks = array_key_exists('after_uuid', $adds) ? [$adds] : array_values($adds);

  foreach ($blocks as $block_index => $add) {
    $label = count($blocks) > 1 ? "add_components[{$block_index}]" : "add_components";
    $anchor = $add['after_uuid'] ?? NULL;
    $new_components = $add['components'] ?? [];

    if (!$anchor) {
      fwrite(STDERR, "{$label}: missing after_uuid — skipped.\n");
      continue;
    }
    if (empty($new_components)) {
      fwrite(STDERR, "{$label}: components is empty — nothing to add.\n");
      continue;
    }

    // Reload components fresh each iteration so this block layers cleanly
    // on top of any component_inputs patches + any prior add blocks
    // already applied in this run (each block does $entity->set() below,
    // and $entity->get() reflects that in-memory state on re-read).
    $components = $entity->get('components')->getValue();
    $existing_uuids = array_column($components, 'uuid');

    // Idempotency: if the first new uuid already lives on the page, assume
    // the whole block has been applied before and skip it.
    $first_new_uuid = $new_components[0]['uuid'] ?? NULL;
    if ($first_new_uuid && in_array($first_new_uuid, $existing_uuids, TRUE)) {
      $changes[] = "{$label}: skipped (first new uuid {$first_new_uuid} already present — assumed previously applied)";
      continue;
    }

    // Locate anchor index.
    $anchor_index = NULL;
    foreach ($components as $i => $c) {
      if (($c['uuid'] ?? NULL) === $anchor) {
        $anchor_index = $i;
        break;
      }
    }
    if ($anchor_index === NULL) {
      fwrite(STDERR, "{$label}: anchor {$anchor} not found on the page — skipped.\n");
      continue;
    }

    // Build the normalized component records Canvas expects.
    $built = [];
    $abort = FALSE;
    foreach ($new_components as $nc) {
      if (empty($nc['uuid']) || empty($nc['component_id']) || empty($nc['component_version'])) {
        fwrite(STDERR, "{$label}: entry missing uuid/component_id/component_version — aborting this block.\n");
        $abort = TRUE;
        break;
      }
      if (in_array($nc['uuid'], $existing_uuids, TRUE)) {
        fwrite(STDERR, "{$label}: uuid {$nc['uuid']} already on page — aborting this block (partial prior apply?).\n");
        $abort = TRUE;
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
    if ($abort) {
      continue;
    }

    $before = array_slice($components, 0, $anchor_index + 1);
    $after = array_slice($components, $anchor_index + 1);
    $components = array_merge($before, $built, $after);
    $entity->set('components', $components);
    foreach ($built as $b) {
      $parent_note = !empty($b['parent_uuid']) ? " (parent {$b['parent_uuid']}, slot {$b['slot']})" : ' (root)';
      $changes[] = "+ component {$b['uuid']} {$b['component_id']}{$parent_note}";
    }
    $changes[] = "{$label}: inserted " . count($built) . " components after anchor {$anchor} (position " . ($anchor_index + 1) . ")";
  }
}

// Structural removals: delete named UUIDs + all descendants from the tree.
if (!empty($overlay['remove_components'])) {
  $remove_uuids = $overlay['remove_components'];
  if (!is_array($remove_uuids)) {
    fwrite(STDERR, "remove_components must be a list of UUIDs — skipped.\n");
  }
  else {
    // Reload components fresh so we layer cleanly on top of any prior
    // overlay sections that ran above.
    $components = $entity->get('components')->getValue();

    // Expand the removal set to include descendants (parent_uuid chain).
    // Iterate until no new descendants are discovered.
    $to_remove = array_fill_keys($remove_uuids, TRUE);
    do {
      $added = FALSE;
      foreach ($components as $c) {
        if (!empty($c['parent_uuid'])
          && isset($to_remove[$c['parent_uuid']])
          && !isset($to_remove[$c['uuid']])) {
          $to_remove[$c['uuid']] = TRUE;
          $added = TRUE;
        }
      }
    } while ($added);

    $kept = [];
    $removed = [];
    foreach ($components as $c) {
      if (isset($to_remove[$c['uuid']])) {
        $removed[] = $c;
      }
      else {
        $kept[] = $c;
      }
    }

    if ($removed) {
      $entity->set('components', $kept);
      foreach ($removed as $r) {
        $changes[] = "- component {$r['uuid']} ({$r['component_id']})";
      }
      $changes[] = "removed " . count($removed) . " components (including descendants); " . count($kept) . " remain";
    }
    else {
      $changes[] = "remove_components: none of the listed UUIDs were on the page — no-op";
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
