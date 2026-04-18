# `pl_neonbyte` — Stage 1: Theme Scaffolding

> **Parent:** [`neonbyte-plan.md`](neonbyte-plan.md)
> **Next:** [`neonbyte-plan--components.md`](neonbyte-plan--components.md)

---

## Pre-Execution Requirements

Before creating any files, these must be resolved:

| Item | Status | Source |
|---|---|---|
| Primary brand hex | ⬜ Pending | Performant Labs brand guide |
| Secondary brand hex | ⬜ Pending | Performant Labs brand guide |
| Primary colour brightness (`light`/`dark`) | ⬜ Pending | Confirm via `ThemeColors::isLightColor()` |
| Logo SVG | ⬜ Pending | Brand guide or AI-generated |
| Favicon | ⬜ Pending | Brand guide |
| Font family | ⬜ Pending | Brand guide |
| `license_uuid` + `dripyard_uid` | ⬜ Pending | Copy from `neonbyte_subtheme.settings.yml` |

> See `ai-guided-theme-generation.md` Phase 2 for the full asset collection checklist and exact `ddev drush php-eval` commands.

---

## Directory Structure

```
themes/custom/pl_neonbyte/
├── pl_neonbyte.info.yml
├── pl_neonbyte.libraries.yml
├── pl_neonbyte.theme
├── dripyard-classloader.php
├── logo.svg
├── screenshot.png              (optional)
├── css/
│   └── base.css
├── config/
│   └── install/
│       └── pl_neonbyte.settings.yml
└── src/                        (empty initially — for future PHP classes)
```

---

## File Inventory

### `pl_neonbyte.info.yml`
Declares the theme. Sets `base theme: neonbyte`. Lists all 11 NeonByte regions verbatim. Registers the `pl_neonbyte/base` library.

```yaml
name: 'PL NeonByte'
type: theme
base theme: neonbyte
description: 'Performant Labs child theme of NeonByte.'
core_version_requirement: ^11.2
libraries:
  - pl_neonbyte/base
regions:
  header_first: 'Header first (logo)'
  header_second: 'Header second (center)'
  header_third: 'Header third (right)'
  highlighted: Highlighted
  content: Content
  fixed_middle_right: 'Fixed middle right (local actions tabs)'
  fixed_bottom_right: 'Fixed bottom right (messages)'
  footer_top: 'Footer top'
  footer_left: 'Footer left'
  footer_right: 'Footer right'
  footer_bottom: 'Footer bottom'
dripyard_theme_level: subtheme
```

> Template: `neonbyte_subtheme/neonbyte_subtheme.info.yml` — regions sourced directly from `neonbyte/neonbyte.info.yml`

---

### `pl_neonbyte.libraries.yml`
Defines the `base` library (loaded globally via `info.yml`). Scaffolds commented-out component library entries for future `libraries-extend` overrides.

> Template: `neonbyte_subtheme/neonbyte_subtheme.libraries.yml`
> CSS decisions: → [`theme-change.md`](theme-change.md)

---

### `css/base.css`
Single global stylesheet. Contains only brand token overrides — no component-specific rules, no `!important`. Initially minimal; grows only when the OKLCH-derived palette is insufficient for brand requirements.

> All decisions about what goes in this file, at what selector, and at what layer are governed by:
> - [`theme-change.md`](theme-change.md) — the rules
> - [`theme-change--audit.md`](theme-change--audit.md) — the source verification
> - [`theme-change--workflow.md`](theme-change--workflow.md) — the process for making each change

---

### `pl_neonbyte.theme`
Thin PHP file. Includes the Dripyard class-loader. Hosts `hook_preprocess_*` overrides if needed in future phases.

> Template: `neonbyte_subtheme/neonbyte_subtheme.theme`
>
> ⚠️ **Path fix required:** The scaffold uses `__DIR__ . '/../dripyard-classloader.php'` which resolves correctly for the scaffold's location at `themes/neonbyte_subtheme/` but is **wrong** for `themes/custom/pl_neonbyte/`. Change the path to:
> ```php
> if (file_exists(__DIR__ . '/dripyard-classloader.php')) {
>   require_once __DIR__ . '/dripyard-classloader.php';
> }
> ```

---

### `dripyard-classloader.php`
PSR-4 autoloader for `src/` classes. Adapted from `neonbyte_subtheme/dripyard-classloader.php`.

Two substitutions required (beyond the namespace):

| Find | Replace |
|---|---|
| `Drupal\\NeonbyteSubtheme\\` | `Drupal\\PlNeonbyte\\` |
| `NEONBYTE_SUBTHEME_AUTOLOADER_LOADED` | `PL_NEONBYTE_AUTOLOADER_LOADED` |

> Template: `neonbyte_subtheme/dripyard-classloader.php`

---

### `config/install/pl_neonbyte.settings.yml`
Pre-seeds all theme settings so installation produces correct brand output without manual UI steps. This is the **primary mechanism for setting brand colours** — not `css/base.css`.

Adapt from `neonbyte_subtheme/config/install/neonbyte_subtheme.settings.yml`. The complete structure with required changes marked:

```yaml
social_media_links:
  bluesky: ''
  facebook: ''
  instagram: ''
  linkedin: ''
  twitter: ''
  youtube: ''              # add/remove channels as needed

theme_colors:
  color_scheme: default
  colors:
    base_primary_color: '#REPLACE_WITH_BRAND_HEX'        # ← REQUIRED
    base_primary_color_brightness: 'dark'                # ← 'light' or 'dark'
    base_secondary_color: '#REPLACE_WITH_BRAND_HEX'      # ← REQUIRED
    base_secondary_color_brightness: 'dark'              # ← 'light' or 'dark'
  site_theme: 'white'      # default page zone — white|light|primary|dark|black|secondary

footer:
  theme: primary           # zone applied to footer region

favicon:
  use_default: false
  path: ''                 # ← set after favicon is wired

features:
  comment_user_picture: false
  comment_user_verification: true
  favicon: false
  node_user_picture: false

logo:
  use_default: true        # ← set to false once logo.svg is wired

third_party_settings:
  shortcut:
    module_link: true

layout_settings:
  container_max_width: '1440'
  border_radius_sm: '4'
  border_radius_md: '8'
  border_radius_lg: '16'
  border_radius_button: '40'

header_settings:
  full_width: 0
  remove_sticky: 0
  remove_transparency: 0
  theme: 'light'           # zone applied to header region

license_uuid: 'c14f4bdc-9260-401a-922e-a55523c688c9'   # ← copy verbatim from scaffold
dripyard_uid: 42                                        # ← copy verbatim from scaffold
```

> `license_uuid` and `dripyard_uid` are on the final two lines of `neonbyte_subtheme/config/install/neonbyte_subtheme.settings.yml`. Copy them verbatim — they are licence identifiers tied to the Dripyard installation and must not be changed.
> Config is written at install time. For live updates during development, use `ddev drush php-eval` — see `ai-guided-theme-generation.md` Phase 2.

---

### `logo.svg`
Performant Labs SVG logo. Must use `<text>` elements — not hand-crafted `<path>` data.

> See `operational-guidance.md` §5 (SVG logo rules) and §6 (two config locations that must both be set).

---

## Execution Phases

### Phase 1 — Pre-flight
- [ ] Confirm DDEV is running: `ddev describe`
- [ ] Confirm git status is clean: `git status` — no uncommitted changes
- [ ] Resolve all Pre-Execution Requirements above

> **Commit point:** Git is clean. This is the implicit rollback baseline — no commit needed.

---

### Phase 2 — Scaffold
- [ ] Create `themes/custom/pl_neonbyte/` directory structure
- [ ] Create `pl_neonbyte.info.yml` from template
- [ ] Create `pl_neonbyte.libraries.yml` from template
- [ ] Create `pl_neonbyte.theme` from template (apply path fix — see §File Inventory)
- [ ] Create `dripyard-classloader.php` from template (apply two substitutions — see §File Inventory)
- [ ] Create `css/base.css` (empty, with file comment block only)
- [ ] Create `config/install/pl_neonbyte.settings.yml` from template

> **Commit point:** All scaffold files exist. Theme can be enabled even if unstyled.
> ```bash
> git add themes/custom/pl_neonbyte/
> git commit -m "feat(theme): scaffold pl_neonbyte child theme"
> ```
> *Rollback: `git revert` removes all theme files, returning to a clean slate.*

---

### Phase 3 — Brand Asset Wiring
- [ ] Set brand colours in `pl_neonbyte.settings.yml`
- [ ] Wire logo: update both `system.theme.global` and `pl_neonbyte.settings` config locations
- [ ] Wire favicon

> **Commit point:** Brand assets configured in settings before theme activation.
> ```bash
> git add themes/custom/pl_neonbyte/config/install/pl_neonbyte.settings.yml
> git add themes/custom/pl_neonbyte/logo.svg
> git commit -m "feat(theme): wire pl_neonbyte brand colours, logo and favicon"
> ```
> *Rollback: reverts to placeholder colours and default logo — theme still scaffolded.*

---

### Phase 4 — Enable and Verify
- [ ] Enable the theme: `ddev drush theme:enable pl_neonbyte`
- [ ] Set as default: `ddev drush config:set system.theme default pl_neonbyte`
- [ ] Apply theme settings via `ddev drush php-eval` (see below) — **do not use `config:import`** *(site has config drift that would affect unrelated config)*
- [ ] Rebuild caches: `ddev drush cr`
- [ ] Run T1 → T2 verification — **do not proceed until both pass**
- [ ] Run T3 visual sign-off

> **Why not `config:import`?** `config:import` reconciles the entire sync directory against the DB. If the site has config drift (items only in DB, or only in sync dir), it will apply or delete those too — unrelated to the theme. Use `ddev drush php-eval` to set only the theme settings:
> ```bash
> # Set brand colours
> ddev drush php-eval "
>   \$config = \Drupal::configFactory()->getEditable('pl_neonbyte.settings');
>   \$config->set('theme_colors.colors.base_primary_color', '#BRAND_HEX');
>   \$config->set('theme_colors.colors.base_primary_color_brightness', 'dark');
>   \$config->set('theme_colors.colors.base_secondary_color', '#BRAND_HEX');
>   \$config->set('theme_colors.colors.base_secondary_color_brightness', 'dark');
>   \$config->save();
> "
> ```
> See `ai-guided-theme-generation.md` Phase 2 for the full set of `ddev drush php-eval` commands including logo and favicon wiring.

> **Commit point:** Theme is active and structurally verified. Safe baseline before any CSS work.
> ```bash
> git add themes/custom/pl_neonbyte/
> git commit -m "feat(theme): activate pl_neonbyte as default theme"
> ```
> *Rollback: reverts theme activation — site returns to previous default theme.*

---

### Phase 5 — CSS Brand Tuning (if needed)
- [ ] If OKLCH-derived palette is insufficient, follow the CSS change workflow
- [ ] Each change must go through [`theme-change--workflow.md`](theme-change--workflow.md) — no direct CSS edits

> **Commit point:** One commit per CSS change, as directed by `theme-change--workflow.md` Step 7.
> The workflow's change log entry and commit message travel together.
> *Rollback: `git revert <commit>` removes exactly one CSS change without touching others.*

---

## Verification Plan

All verification follows the Three-Tier Hierarchy. Never escalate to a higher tier before the lower tier passes.

| Tier | Method | Pass condition |
|---|---|---|
| T1 — Headless | `curl -s -o /dev/null -w "%{http_code}" http://pl-performantlabs.com.2.ddev.site/` | HTTP `200` |
| T1 — CSS served | `curl -s http://pl-performantlabs.com.2.ddev.site/ \| grep pl_neonbyte` | Theme CSS link present |
| T1 — Colour config | `ddev drush config:get pl_neonbyte.settings` | Brand hex values present |
| T2 — Structural | `read_browser_page` on home | `<html>` carries `theme--white` class and `--theme-setting-base-primary-color` inline style |
| T3 — Visual | Screenshot | PL brand colours visible; logo renders correctly |

> Full protocol: `verification-cookbook.md`
> T3 visual sign-off process: `visual-regression-strategy.md`

---

## Stage Complete → Proceed to Stage 2

When Phase 5 is done (or confirmed not needed), the theme is verified and branded. Proceed to:

**[`neonbyte-plan--components.md`](neonbyte-plan--components.md)** — SDC component work
