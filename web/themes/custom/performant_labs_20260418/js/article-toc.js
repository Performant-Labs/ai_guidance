/**
 * @file
 * article-toc — build an "On this page" navigation for article-full nodes.
 *
 * Scans h2 + h3 inside .article-full .node__content .grid-area--content,
 * assigns stable slug IDs, and injects a sibling <nav> with
 * .grid-area--sidebar-second so the existing grid slot holds the TOC.
 *
 * Layer 5: new behavior; no upstream conflict. CSS in article-toc.css
 * overrides neonbyte's grid template at >=1024px so the sidebar slot
 * always renders as a right column on desktop.
 *
 * IntersectionObserver handles scroll-spy (active link highlighting).
 * Guard: if fewer than 2 headings qualify, the TOC is not rendered.
 */
(function (Drupal, once) {
  'use strict';

  /**
   * Slugify heading text into a url-fragment-safe id.
   */
  function slugify(text) {
    return String(text || '')
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .replace(/^-|-$/g, '');
  }

  /**
   * Return an id not already used in this document nor in `seen`.
   */
  function ensureUniqueId(base, seen) {
    var slug = base || 'section';
    var candidate = slug;
    var n = 2;
    while (document.getElementById(candidate) || seen.has(candidate)) {
      candidate = slug + '-' + n;
      n++;
    }
    seen.add(candidate);
    return candidate;
  }

  Drupal.behaviors.plArticleToc = {
    attach: function (context) {
      once('pl-article-toc', '.article-full .node__content .grid', context).forEach(function (grid) {
        var content = grid.querySelector('.grid-area--content');
        if (!content) {
          return;
        }

        // Consider only top-level section headings inside the article body.
        var headings = Array.from(content.querySelectorAll('h2, h3'));
        if (headings.length < 2) {
          return;
        }

        // Give every heading a stable id so TOC links resolve.
        var seen = new Set();
        headings.forEach(function (h) {
          if (!h.id) {
            h.id = ensureUniqueId(slugify(h.textContent), seen);
          }
          else {
            seen.add(h.id);
          }
          // Ensure anchor scroll clears the fixed header.
          h.style.scrollMarginTop = 'calc(var(--space-for-fixed-header, 5rem) + 1rem)';
        });

        // Build nav.
        var nav = document.createElement('nav');
        nav.className = 'article-toc grid-area--sidebar-second';
        nav.setAttribute('aria-label', Drupal.t('On this page'));

        var title = document.createElement('p');
        title.className = 'article-toc__title';
        title.textContent = Drupal.t('On this page');
        nav.appendChild(title);

        var list = document.createElement('ol');
        list.className = 'article-toc__list';

        headings.forEach(function (h) {
          var li = document.createElement('li');
          li.className = 'article-toc__item article-toc__item--' + h.tagName.toLowerCase();
          var a = document.createElement('a');
          a.className = 'article-toc__link';
          a.href = '#' + h.id;
          a.textContent = (h.textContent || '').trim();
          a.setAttribute('data-toc-target', h.id);
          li.appendChild(a);
          list.appendChild(li);
        });
        nav.appendChild(list);
        grid.appendChild(nav);

        // Scroll-spy.
        if ('IntersectionObserver' in window) {
          var linkByHeadingId = {};
          nav.querySelectorAll('.article-toc__link').forEach(function (a) {
            linkByHeadingId[a.getAttribute('data-toc-target')] = a;
          });
          var activeId = null;
          function setActive(id) {
            if (activeId === id) {
              return;
            }
            if (activeId && linkByHeadingId[activeId]) {
              linkByHeadingId[activeId].classList.remove('is-active');
            }
            if (id && linkByHeadingId[id]) {
              linkByHeadingId[id].classList.add('is-active');
            }
            activeId = id;
          }

          var observer = new IntersectionObserver(
            function (entries) {
              // Prefer the topmost currently-intersecting heading.
              var visible = entries.filter(function (e) { return e.isIntersecting; });
              if (visible.length) {
                visible.sort(function (a, b) {
                  return a.boundingClientRect.top - b.boundingClientRect.top;
                });
                setActive(visible[0].target.id);
                return;
              }
              // Fallback: last heading scrolled past (above the header band).
              var candidate = null;
              var threshold = 120;
              headings.forEach(function (h) {
                if (h.getBoundingClientRect().top <= threshold) {
                  candidate = h.id;
                }
              });
              if (candidate) {
                setActive(candidate);
              }
            },
            {
              // Trigger when the heading crosses into the top ~25% of the viewport.
              rootMargin: '-100px 0px -70% 0px',
              threshold: [0, 1]
            }
          );
          headings.forEach(function (h) { observer.observe(h); });
        }
      });
    }
  };
})(Drupal, once);
