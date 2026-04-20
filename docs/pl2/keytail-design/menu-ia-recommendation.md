# Main-Menu IA Recommendation — Keytail Match

**Date:** 2026-04-20
**Scope:** `performant_labs_20260418` canvas/frontpage header
**Layer:** L1 Drupal config (menu content), NOT theme CSS

---

## Current vs. Keytail

| | Keytail | Performant Labs (current) |
|---|---|---|
| **# items** | 3 | 5 |
| **Item 1** | Product ▾ | Services |
| **Item 2** | Pricing | How We Do It |
| **Item 3** | Blog | Articles |
| **Item 4** | — | Open Source Projects |
| **Item 5** | — | Contact Us |
| **CTA** | `Get started` | `Call today` |

Keytail's pattern: few items, each maps to an unmistakable intent (what is it → what does it cost → what else can I read). Ours is heavier because it includes two items that read as corporate-information rather than product-decision (Open Source Projects, Contact Us).

---

## Recommendation

**Keep in main menu (3 items):**

1. **Services** — the primary offering. Maps to Keytail's "Product". The pivot point for every prospect visit.
2. **How We Do It** — differentiator / method. Maps to Keytail's "Pricing" slot positionally (the "what it takes to work with us" item). Keeps interior-page depth without adding a sub-menu yet.
3. **Articles** — content hub. Maps to Keytail's "Blog". Signals the firm writes and teaches.

**Remove from main menu:**

- **Open Source Projects** — move to **Services → Sub-item** OR a footer column. It's an asset, but the front-page main nav is not the right spot to advertise it; a visitor in discovery mode won't click through here.
- **Contact Us** — **redundant** with the `Call today` / `Get started` CTA already in the header. Two paths to "talk to us" in the same row splits attention. Move to the footer (which typically carries it anyway) and let the CTA do its job.

---

## How to apply

**UI path (fastest):**

1. Log in as admin.
2. `/admin/structure/menu/manage/main`
3. For `Open Source Projects` and `Contact Us` rows: uncheck **Enabled** → Save.

Those items remain in the menu structure (so you can re-enable later if the IA changes), they just stop rendering.

**CLI alternative (drush):**

```bash
ddev drush ev '
foreach ([
  "open-source-projects", // adjust to your actual menu-link slug/id
  "contact",              // or the contact-us link id
] as $slug) {
  $links = \Drupal::entityTypeManager()
    ->getStorage("menu_link_content")
    ->loadByProperties(["menu_name" => "main", "link__uri" => "internal:/" . $slug]);
  foreach ($links as $link) { $link->set("enabled", 0)->save(); }
}
\Drupal::service("plugin.manager.menu.link")->rebuild();
'
```

> ⚠ Look up the actual `link__uri` values first via `ddev drush ev 'foreach (\Drupal::entityTypeManager()->getStorage("menu_link_content")->loadByProperties(["menu_name" => "main"]) as $l) { print $l->label() . " → " . $l->getUrlObject()->toString() . PHP_EOL; }'` before running the disable loop.

**Footer pickup:**

If Open Source Projects and Contact Us need to remain reachable, add them to the footer menu at `/admin/structure/menu/manage/footer` (or whatever the PL footer menu machine name is). Typical footer-IA carries both.

---

## Why this is config, not theme

Menu membership is content-layer data stored in `menu_link_content` entities, not a CSS/theming concern. The theme's job is to *render* whatever menu the site admin has configured. That separation is why this recommendation is in `docs/pl2/keytail-design/` (IA) rather than in the subtheme CSS.

If the decision here is locked in long-term, consider exporting the menu-link changes to config sync (`ddev drush config:export`) so the shape of the main menu is version-controlled alongside the theme.

---

## Trade-off to be aware of

Reducing to 3 items is a brand bet: it favours atmosphere and decisiveness over findability. If the site analytics show meaningful traffic to Open Source Projects or Contact Us from the front-page header, revisit. The CTA on the right (`Call today` → muted-white per the CSS change 2026-04-20) should pick up the lost Contact Us click-through.
