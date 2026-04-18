<?php

namespace Drupal\pl_theme_preview;

use Drupal\Core\Session\AccountInterface;
use Drupal\Core\Extension\ThemeHandlerInterface;
use Drupal\Core\Routing\RouteMatchInterface;
use Drupal\Core\Theme\ThemeNegotiatorInterface;
use Symfony\Component\HttpFoundation\RequestStack;

class ThemePreviewNegotiator implements ThemeNegotiatorInterface {

  public function __construct(
    protected AccountInterface $currentUser,
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
      && $this->currentUser->hasPermission('administer themes')
      && $this->themeHandler->themeExists($theme);
  }

  public function determineActiveTheme(RouteMatchInterface $routeMatch): ?string {
    $request = $this->requestStack->getCurrentRequest();
    return $request ? $request->query->get('theme') : NULL;
  }

}
