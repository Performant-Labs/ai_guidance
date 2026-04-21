<?php

/**
 * @file
 * Dumps a canvas_page entity to DefaultContent-compatible YAML.
 *
 * Bypasses Canvas's DefaultContentSubscriber, which (as of canvas v1.3.2)
 * trips an assertion in ReferenceFieldTypePropExpression::calculateDependencies
 * when a component input references a non-fieldable entity.
 *
 * We read the fields directly from the content entity and emit the same
 * YAML shape produced by `php core/scripts/drupal content:export canvas_page`.
 *
 * Usage (from inside DDEV):
 *   ddev drush php:script scripts/dump-canvas-page.php <uuid> [output-path]
 *
 * If output-path is omitted, writes to content-exports/<uuid>.yml relative
 * to the project root.
 *
 * Example:
 *   ddev drush php:script scripts/dump-canvas-page.php \
 *     bb5bbbb1-4a16-4b86-bbea-b215ab8096cf
 */

declare(strict_types=1);

use Symfony\Component\Yaml\Yaml;

/** @var array $extra — provided by drush php:script */
$uuid = $extra[0] ?? NULL;
$out_path = $extra[1] ?? NULL;

if (!$uuid) {
  fwrite(STDERR, "Usage: drush php:script scripts/dump-canvas-page.php <uuid> [output-path]\n");
  return 1;
}

if (!$out_path) {
  $out_path = "content-exports/{$uuid}.yml";
}

$entity = \Drupal::service('entity.repository')
  ->loadEntityByUuid('canvas_page', $uuid);

if (!$entity) {
  fwrite(STDERR, "No canvas_page found with UUID: {$uuid}\n");
  return 1;
}

$export = [
  '_meta' => [
    'version' => '1.0',
    'entity_type' => 'canvas_page',
    'uuid' => $entity->uuid(),
    'default_langcode' => $entity->language()->getId(),
  ],
  'default' => [
    'status' => [['value' => (bool) $entity->get('status')->value]],
    'title' => [['value' => $entity->get('title')->value]],
    // component_tree field: getValue() returns the stored tree array verbatim
    // — [[uuid, component_id, inputs, parent_uuid?, slot?, component_version?]]
    'components' => $entity->get('components')->getValue(),
    'owner' => [['target_id' => (int) $entity->get('owner')->target_id]],
    'created' => [['value' => (int) $entity->get('created')->value]],
  ],
];

$description = $entity->get('description')->value;
if ($description !== NULL && $description !== '') {
  $export['default']['description'] = [['value' => $description]];
}

// Path alias, if set (computed field — may be empty).
$alias = $entity->get('path')->alias ?? '';
if ($alias) {
  $export['default']['path'] = [[
    'alias' => $alias,
    'langcode' => $entity->language()->getId(),
  ]];
}

// Ensure output directory exists.
$dir = dirname($out_path);
if ($dir && !is_dir($dir)) {
  mkdir($dir, 0755, TRUE);
}

file_put_contents(
  $out_path,
  Yaml::dump($export, 20, 2, Yaml::DUMP_MULTI_LINE_LITERAL_BLOCK),
);

echo "Wrote {$out_path}\n";
echo "Title: {$entity->label()}\n";
echo "Components: " . count($export['default']['components']) . "\n";
