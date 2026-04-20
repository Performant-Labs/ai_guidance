<?php

namespace Drupal\pl_theme_preview;

use Drupal\Core\Extension\ThemeHandlerInterface;
use Drupal\Core\Routing\RouteMatchInterface;
use Drupal\Core\Theme\ThemeNegotiatorInterface;
use Symfony\Component\HttpFoundation\RequestStack;

/**
 * Switches the active theme via ?theme= URL query parameter.
 *
 * No permission check — dev/preview use only. Do not enable on production.
 */
class ThemePreviewNegotiator implements ThemeNegotiatorInterface {

  public function __construct(
    protected ThemeHandlerInterface $themeHandler,
    protected RequestStack $requestStack,
  ) {}

  public function applies(RouteMatchInterface $routeMatch): bool {
    $request = $this->requestStack->getCurrentRequest();
    if (!$request) {
      return FALSE;
    }
    $theme = $request->query->get('theme');
    return !empty($theme)
      && $this->themeHandler->themeExists($theme);
  }

  public function determineActiveTheme(RouteMatchInterface $routeMatch): ?string {
    $request = $this->requestStack->getCurrentRequest();
    return $request ? $request->query->get('theme') : NULL;
  }

}
