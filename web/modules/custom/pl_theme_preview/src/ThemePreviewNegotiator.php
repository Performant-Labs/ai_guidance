<?php

namespace Drupal\pl_theme_preview;

use Drupal\Core\Session\AccountInterface;
use Drupal\Core\Extension\ThemeHandlerInterface;
use Drupal\Core\Routing\RouteMatchInterface;
use Drupal\Core\Theme\ThemeNegotiatorInterface;

class ThemePreviewNegotiator implements ThemeNegotiatorInterface {

  public function __construct(
    protected AccountInterface $currentUser,
    protected ThemeHandlerInterface $themeHandler,
  ) {}

  public function applies(RouteMatchInterface $routeMatch): bool {
    $theme = \Drupal::request()->query->get('theme');
    return $this->currentUser->hasPermission('administer themes')
      && $theme
      && $this->themeHandler->themeExists($theme);
  }

  public function determineActiveTheme(RouteMatchInterface $routeMatch): ?string {
    return \Drupal::request()->query->get('theme');
  }

}
