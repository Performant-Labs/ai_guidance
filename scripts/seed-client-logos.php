<?php

/**
 * @file
 * Seeds the media library with the six client-logo SVGs used by the homepage
 * trust bar (Section 2 of the Phase 3 homepage brief).
 *
 * Reads SVG files from a staging directory (default: logos-staging/ at
 * project root), copies each into public://client-logos/, and creates a
 * paired file_managed + media:image entity for each one so they become
 * reusable media entities that Canvas can reference.
 *
 * Idempotent: if a media entity with the same derived name already exists,
 * the logo is skipped. Safe to re-run.
 *
 * Usage (from inside DDEV, CWD = /var/www/html/web for drush php:script):
 *   ddev drush php:script scripts/seed-client-logos.php
 *
 * Optional first extra arg: alternate staging directory (relative to
 * project root, i.e. /var/www/html):
 *   ddev drush php:script scripts/seed-client-logos.php my-other-dir
 *
 * Prints a table of (client, media UUID, media ID) at the end — those IDs
 * are what the Section 2 overlay will reference.
 */

declare(strict_types=1);

use Drupal\file\Entity\File;
use Drupal\media\Entity\Media;

/** @var array $extra — provided by drush php:script */
$staging_rel = $extra[0] ?? 'logos-staging';

// drush php:script runs with CWD = /var/www/html/web. Project root is one up.
$project_root = realpath(getcwd() . '/..');
if (!$project_root) {
  fwrite(STDERR, "Cannot resolve project root from CWD " . getcwd() . "\n");
  return 1;
}
$staging_dir = $project_root . '/' . ltrim($staging_rel, '/');

if (!is_dir($staging_dir)) {
  fwrite(STDERR, "Staging directory not found: {$staging_dir}\n");
  return 1;
}

// Map filename → the display name we want on the media entity.
$name_map = [
  'CBS-Interactive' => 'CBS Interactive',
  'DocuSign'        => 'DocuSign',
  'Orange'          => 'Orange',
  'Renesas'         => 'Renesas Electronics',
  'Robert-Half'     => 'Robert Half',
  'Tesla'           => 'Tesla',
];

$svgs = glob($staging_dir . '/*.svg') ?: [];
if (!$svgs) {
  fwrite(STDERR, "No SVGs found in {$staging_dir}\n");
  return 1;
}

$file_system = \Drupal::service('file_system');
$entity_type_manager = \Drupal::service('entity_type.manager');
$media_storage = $entity_type_manager->getStorage('media');

// Ensure destination directory exists inside the managed files tree.
$dest_dir = 'public://client-logos';
$file_system->prepareDirectory(
  $dest_dir,
  \Drupal\Core\File\FileSystemInterface::CREATE_DIRECTORY
  | \Drupal\Core\File\FileSystemInterface::MODIFY_PERMISSIONS
);

$results = [];

foreach ($svgs as $src) {
  $basename = basename($src);

  // Match by prefix so variants like 'Renesas_Electronics_logo.svg' work.
  $display_name = NULL;
  foreach ($name_map as $prefix => $name) {
    if (stripos($basename, $prefix) === 0) {
      $display_name = $name;
      break;
    }
  }
  if (!$display_name) {
    fwrite(STDERR, "Skipping (no name mapping): {$basename}\n");
    continue;
  }

  // Idempotency: skip if a media entity already exists with this name.
  $existing = $media_storage->loadByProperties([
    'bundle' => 'image',
    'name' => $display_name,
  ]);
  if ($existing) {
    $m = reset($existing);
    $results[] = [$display_name, $m->uuid(), (int) $m->id(), 'skipped (already exists)'];
    continue;
  }

  // Copy the SVG into managed files.
  $dest_uri = $dest_dir . '/' . $basename;
  $copied = $file_system->copy(
    $src,
    $dest_uri,
    \Drupal\Core\File\FileExists::Replace
  );
  if (!$copied) {
    fwrite(STDERR, "Copy failed: {$src} → {$dest_uri}\n");
    continue;
  }

  // Create File entity.
  $file = File::create([
    'uri' => $copied,
    'status' => 1,
    'uid' => 1,
    'filename' => $basename,
    'filemime' => 'image/svg+xml',
  ]);
  $file->save();

  // Create Media entity (bundle: image).
  $media = Media::create([
    'bundle' => 'image',
    'uid' => 1,
    'name' => $display_name,
    'status' => 1,
    'field_media_image' => [
      'target_id' => $file->id(),
      'alt' => $display_name . ' logo',
      'title' => $display_name,
    ],
  ]);
  $media->save();

  $results[] = [$display_name, $media->uuid(), (int) $media->id(), 'created'];
}

echo "\nSeeding complete.\n\n";
printf("%-25s %-38s %-6s %s\n", 'Client', 'Media UUID', 'MID', 'Status');
printf("%s\n", str_repeat('-', 90));
foreach ($results as [$name, $uuid, $mid, $status]) {
  printf("%-25s %-38s %-6d %s\n", $name, $uuid, $mid, $status);
}
echo "\nUse these Media UUIDs in content-exports/homepage-section-2.overlay.yml.\n";
