/**
 * @file
 * performant_labs_20260418 — header scroll behavior.
 *
 * Adds .is-scrolled to .site-header when the user has scrolled past the
 * threshold. The CSS in css/components/header.css then toggles
 * --header-background-color-percent from 0% (transparent) to 100% (opaque).
 *
 * Why JS is required here (not pure CSS):
 *   - The IntersectionObserver approach requires a sentinel element inside the
 *     hero, which would require a Twig override.
 *   - scroll-driven animations (animation-timeline: scroll()) cannot toggle
 *     a CSS custom property value between 0% and 100% without a workaround.
 *   - The simplest, most maintainable solution is a Drupal behavior with a
 *     passive scroll listener.
 *
 * Threshold: 80px — enough to clear the hero top edge before the header
 * becomes opaque, so there is a visible transparency effect over the hero.
 */
((Drupal, once) => {
  const SCROLL_THRESHOLD = 80;

  /**
   * Initialise scroll-to-opaque on a site-header element.
   *
   * @param {Element} header - The .site-header element.
   */
  function initScrollHeader(header) {
    // Set initial state immediately (handles page reload mid-scroll).
    header.classList.toggle('is-scrolled', window.scrollY > SCROLL_THRESHOLD);

    window.addEventListener(
      'scroll',
      () => {
        header.classList.toggle('is-scrolled', window.scrollY > SCROLL_THRESHOLD);
      },
      { passive: true },
    );
  }

  Drupal.behaviors.plHeaderScroll = {
    attach(context) {
      // once() prevents double-attaching if Drupal re-runs behaviors (AJAX etc.)
      once('pl-header-scroll', '.site-header', context).forEach(initScrollHeader);
    },
  };
})(Drupal, once);
