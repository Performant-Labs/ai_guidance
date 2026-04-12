# Legacy Architecture Dissection
## Site: `performantlabs.com` · Local path: `~/Sites/pl-performantlabs.com`
## Audited: 2026-04-11 · Runtime: `ddev` (auto-detected via `.ddev/config.yaml`)

This document captures the structural inventory of the legacy `performantlabs.com`
Drupal site. Its findings directly inform template suggestion hooks, sidebar menu
wiring, region declarations, and content type requirements in the new
`performant_labs_20260411` theme.

---

## 1. Site Baseline

| Parameter | Value |
|---|---|
| Runtime wrapper | `ddev` |
| Active theme | `performant_labs` |
| Admin theme | `claro` |
| Front page | `/node/38` (a `landing_page` node) |
| Drupal core | 10.x / 11.x (implied by contrib versions) |

---

## 2. Content Types

| Machine name | Label | Node count | Role |
|---|---|---|---|
| `landing_page` | Landing Page | 16 | Marketing/product pages (Paragraphs-driven) |
| `article` | Article | 14 | Blog / news content |
| `book` | Book page | **83** | **Primary documentation** — hierarchical |
| `page` | Basic page | 7 | Utility pages (Privacy policy, About, etc.) |
| `issue` | Issue | 4 | Bug/feature tracker entries |
| `note` | Note | 3 | Short-form notes |
| `job` | Job | 2 | Job listings |
| `microsite` | Microsite | 1 | Standalone microsite shell |

### Key Finding: Documentation = `book` content type

The `book` content type (83 nodes) is the clear documentation backbone. It uses
Drupal core's **Book module** to build a hierarchical tree with depth tracking:

- **Depth 1** = Top-level book roots (e.g., "Layout Builder Kit", "Campaign Kit")
- **Depth 2** = Chapter pages (Introduction, Setting Up, Components, etc.)
- **Depth 3+** = Sub-pages (Developer Documentation → sub-articles)

Sample hierarchy:
```
node/24: Layout Builder Kit             [depth:1, root]
  node/26: Introduction                 [depth:2]
  node/27: Setting Up Layout Builder    [depth:2]
  node/28: Book Navigation              [depth:2]
  node/29: Icon Text                    [depth:2]
  ...
  node/36: Developer Documentation      [depth:2]
    node/37: Storing Component Config   [depth:3]

node/25: Campaign Kit                   [depth:1, root]
  node/39: Administrator Documentation  [depth:2]
```

**Implication for `.2` site**: The `page--documentation.html.twig` sidebar template
should target `book` nodes. The sidebar `sidebar_first` region should hold the
**Book navigation block** (Drupal core's `book_navigation` block plugin), which
auto-generates a contextual TOC for the current book tree.

---

## 3. Layout & Builder Modules

| Module | Version | Role |
|---|---|---|
| `layout_builder_kit` | 3.0.0-beta2 | Extended Layout Builder component library |
| `layout_builder_modal` | 2.0.0 | Modal UI for Layout Builder editing |
| `layout_builder_restrictions` | 3.0.3 | Restricts which blocks/layouts are available |
| `layout_builder_styles` | 2.1.0 | CSS class applier for Layout Builder sections |
| `mini_layouts` | 2.0.0-alpha1 | Reusable inline layout sections |
| `paragraphs` | 8.x-1.19 | Structured field content (used on landing_page) |
| `entity_reference_revisions` | 8.x-1.12 | Revisioned entity refs (for Paragraphs) |
| `inline_entity_form` | 3.0.0-rc20 | Inline editing of referenced entities |

**Key difference from `.2` site**: The legacy site uses **Layout Builder** as its
primary page composition tool. The `.2` site uses **Drupal Canvas**. These are
architecturally different. Landing pages in the legacy site are Paragraphs-driven;
landing pages in the `.2` site will be Canvas-driven.

---

## 4. Menu Structure

### `main` — Primary Navigation (5 items)
```
Services
How We Do It
Articles
Contact Us
Open Source Projects
```

### `footer` — Footer Navigation (6 items)
```
Contact Us
About Us
Services
Articles
Open Source Projects
[+ 1 more]
```

### `social-links` — Social Links (4 items)
```
RSS
Twitter
Facebook
LinkedIn
```

**Implication**: The new site's main nav should replicate these 5 top-level items.
The footer nav is a near-mirror. Social links can populate
the `social-media-nav` dripyard_base SDC in the footer region.

---

## 5. Taxonomy Vocabularies

| Machine name | Label | Usage |
|---|---|---|
| `tags` | Tags | General article/content tagging |
| `priority` | Priority | Issue tracker priority classification |
| `issue_status` | Issue Status | Issue workflow state |
| `job_location` | Job-Location | Job listing location |
| `pixel_density` | Pixel Density | (Media/image density descriptor) |

**Implication for `.2` site**: Only `tags` is broadly relevant. The others are
tracker/job-specific and likely out of scope for the Keytail theme. Tags may be
used on `article` content to power filtered listings.

---

## 6. Regions (Legacy `performant_labs` theme)

```
header:          Header
content:         Content
sidebar_first:   Sidebar first    ← TOC/book navigation lives here
sidebar_second:  Sidebar second
footer:          Footer
```

**The legacy theme has `sidebar_first` already.** This confirms our decision to add
that region to `performant_labs_20260411.info.yml`. The Book navigation block is
placed in `sidebar_first` on `book` node routes.

---

## 7. Custom Block Types

| Machine name | Label | Purpose |
|---|---|---|
| `basic` | Basic block | Generic rich-text custom block |
| `image` | Image | Standalone image block |
| `render_node` | Render Node | Embeds a rendered node inside another page |

---

## 8. Architectural Implications for `.2` Site

| Finding | Action Required |
|---|---|
| **Documentation = `book` type** | Implement `book` content type (or equivalent) in `.2` site; use `page--documentation.html.twig` for book node routes |
| **Sidebar = Book navigation block** | Wire `book_navigation` block to `sidebar_first` in theme `config/optional/` for book node pages |
| **`page--documentation.html.twig` suggestion hook** | Add `hook_theme_suggestions_page_alter()` in `.theme` file targeting `node.bundle == 'book'` |
| **Landing pages = Canvas** | No Paragraphs needed; Canvas blocks replace the legacy Paragraphs field approach |
| **Main nav = 5 items** | Replicate in `.2` site's `main` menu; place in `header_second` region |
| **Footer nav = 6 items** | Replicate in `footer` menu; wire to `menu-footer` SDC in `footer_left/right` regions |
| **Social links** | Wire to `social-media-nav` SDC in `footer_bottom` region |
| **`article` type** | Blog/news — standard node display; no dedicated template needed initially |
| **`page` type** | Utility pages — default `page.html.twig` is sufficient |
| **`issue`, `job`, `note`, `microsite`** | Out of scope for Phase 5; do not replicate unless user requests |

---

## 9. Template Suggestion Hook — Action Plan

Add to `performant_labs_20260411.theme`:

```php
/**
 * Implements hook_theme_suggestions_page_alter().
 *
 * Routes book nodes to the documentation sidebar template.
 */
function performant_labs_20260411_theme_suggestions_page_alter(
  array &$suggestions,
  array $variables
): void {
  $node = \Drupal::routeMatch()->getParameter('node');
  if ($node instanceof \Drupal\node\NodeInterface && $node->bundle() === 'book') {
    $suggestions[] = 'page__documentation';
  }
}
```

This causes Drupal to use `page--documentation.html.twig` for all `book` nodes,
activating the `sidebar_first` region and the CSS Grid docs layout.
