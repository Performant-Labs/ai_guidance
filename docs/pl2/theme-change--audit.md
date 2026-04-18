# CSS Override Strategy — Conflict Audit

Verification of `theme-change.md` claims against actual Dripyard source files and Drupal SDC methodology.

Each claim is marked **✅ Confirmed**, **⚠️ Partially correct — needs qualification**, or **❌ Incorrect — must be corrected**.

---

## Claim 1: Dripyard injects color variables as inline styles on `<html>`

**Source checked:** `src/Preprocess/Html/ThemeColorPreprocessor.php`

```php
// Line 43 — exact injection code:
$inline_styles = $inline_styles . "--theme-setting-$color: $hex_value; ";
// ...
$variables['html_attributes']->setAttribute('style', $inline_styles);
```

**Also confirmed:** `src/Preprocess/Html/LayoutSettingsPreprocessor.php` injects **layout settings the same way**:
```php
$inline_styles .= "--theme-setting-container-max-pixel: {$layout_settings['container_max_width']}px; ";
$inline_styles .= "--theme-setting-radius-sm: {$layout_settings['border_radius_sm']}px; ";
// etc.
```

**Result: ✅ Confirmed.** The inline style is set via `setAttribute('style', ...)` on `$variables['html_attributes']`, which renders as `<html style="--theme-setting-base-primary-color: #hex; ...">`. This is exactly as described. The following variables are ALL injected as inline `<html>` styles — meaning none can be overridden from an external CSS file using `:root`:

- `--theme-setting-base-primary-color`
- `--theme-setting-base-secondary-color`
- `--theme-setting-container-max-pixel`
- `--theme-setting-radius-sm` / `-md` / `-lg` / `-button`

**Implication for the CSS strategy:** The guidance to NOT override `--theme-setting-*` variables from CSS is correct. The guidance to NOT override `--theme-setting-container-max-pixel` from CSS is also correct (it too is inline).

---

## Claim 2: `html .theme--white { }` beats `:where(:root), .theme--white` from the base theme

**Source checked:** `css/themes/theme-white.css` (lines 7–8):
```css
:where(:root),
.theme--white {
  --theme-surface: var(--white);
  /* ... */
}
```

**Specificity analysis:**

| Selector | Specificity |
|---|---|
| `:where(:root)` | (0, 0, 0) — `:where()` zeroes all specificity |
| `.theme--white` | (0, 1, 0) |
| `html :where(:root)` | (0, 0, 1) — the `html` element type adds (0,0,1) |
| `html .theme--white` | (0, 1, 1) — beats `.theme--white` by one element |

**Result: ✅ Confirmed.** `html .theme--white { --theme-surface: #value; }` in the subtheme's CSS file has specificity (0,1,1) which **beats the base theme's (0,1,0) `.theme--white` selector**. This is the correct, non-`!important` override.

**Additional finding — `ThemeColorPreprocessor.php` line 64:**
```php
// The site_theme setting also gets applied as a class on <html>:
$variables['html_attributes']->addClass('theme--' . $site_theme);
```
This means the site-wide default theme class (`theme--white`, `theme--primary`, etc.) is also placed on `<html>` itself by PHP. So `html.theme--white .theme--white` might also be a useful selector. But `html .theme--white` is sufficient and simpler.

---

## Claim 3: The `@layer` approach — that unlayered CSS from Dripyard beats `@layer` blocks in the subtheme

**Source checked:** MDN `@layer` reference (read directly):
> *"Styles that are not defined in a layer always override styles declared in named and anonymous layers."*

**Applied to Dripyard:** Every Dripyard CSS file (`theme-white.css`, `variables-colors-semantic.css`, `base.css`, component CSS, etc.) is unlayered. None use `@layer`. Confirmed by reviewing:
- `css/themes/theme-white.css` — no `@layer`
- `css/base/base.css` — no `@layer`
- `components/button/css/button-primary.css` — no `@layer`

**Result: ✅ Confirmed.** Using `@layer` in `pl_neonbyte/css/base.css` to wrap overrides will **not** reliably beat Dripyard's unlayered base styles. `@layer` is only useful for organising the subtheme's own override rules relative to each other.

**One nuance to add:** Within a layer, a rule with the `html .theme--white` selector (specificity 0,1,1) still beats the base theme's `.theme--white` (specificity 0,1,0) — because the base theme's rules are unlayered and beat the layer, but the `html` ancestor specificity bump still applies when comparing two unlayered selectors. So the two approaches are **complementary, not competing**: use `html .theme--` selectors for the override power, and `@layer` purely for your own internal organisation.

---

## Claim 4: BEM convention — `pl-` prefix for custom classes

**Source checked:** `dripyard_base.info.yml` — `dripyard_theme_level: base`

**Source checked:** Every Dripyard component uses BEM. From `button-primary.css`:
```css
.button--primary:where(:not([disabled])) { … }
.button__prefix, .button__suffix { … }
```

**Confirmed pattern:** Dripyard uses single-dash between words (`.theme--white`, `.hero--height-full-screen`, `.button--primary`, `.button__prefix`). This is BEM.

**Result: ✅ Confirmed.** Using `.pl-banner`, `.pl-banner__title`, `.pl-banner--compact` for any custom Performant Labs components is correct and consistent with Dripyard's own convention.

**One correction to the strategy document:** The document suggests `.pl-banner.is-active`. Dripyard itself uses `body.is-active-mobile-menu` in `base.css`. The `.is-*` state prefix is correct per both Drupal.org standards and Dripyard practice.

---

## Claim 5: SDC component CSS uses `--button-*` local tokens, not directly `--theme-*`

**Source checked:** `components/button/css/button-primary.css`:
```css
.button--primary:where(:not([disabled])) {
  --button-background-color: var(--primary);        /* Layer 2 semantic token */
  --button-text-color: var(--color-primary-text-color);  /* Layer 2 semantic token */
  /* ... */
  background-color: var(--button-background-color); /* Layer 4: consumes local token */
}
```

**This contradicts a nuance in the strategy document.** The document says components consume `--theme-*` variables exclusively (Layer 3 → Layer 4). In reality, button uses **Layer 2 semantic tokens** (`--primary`, `--color-primary-text-color`) directly — not `--theme-button-*` from Layer 3.

The `theme-white.css` defines `--theme-button-*` variables, but the button component doesn't consume them — it has its own local `--button-*` token layer.

**Result: ⚠️ Partially correct.** The document's statement that components map "exclusively to theme layer variables" is a simplification. Actual behaviour:
- Simple components (hero, footer) consume `--theme-surface`, `--theme-text-color-*` etc. (Layer 3 → Layer 4) ✅
- The button component has an **intermediate local token layer** — it defines `--button-background-color: var(--primary)` at the component level, then applies it. This is a 5-layer system for complex components.

**Implication:** To override button primary colour in the subtheme, you do NOT touch `--theme-button-*` — you would need to use `libraries-extend` to add a CSS file that targets `.button--primary { --button-background-color: #hex; }`.

---

## Claim 6: `:root { --font-sans: 'Inter'; }` is safe because fonts are not injected inline

**Source checked:** `ThemeColorPreprocessor.php` and `LayoutSettingsPreprocessor.php` — neither injects any font variable inline. Typography variables are only in `css/_variables/variables-typography.css` as `:root { --font-sans: sans-serif; }`.

**Result: ✅ Confirmed.** Font variables are not inline-injected. They can be safely overridden at `:root` from the subtheme's CSS file. Load order is sufficient — the subtheme CSS loads after the base theme.

---

## Claim 7: SDC overrides — copying the whole component bundle

**Source checked:** Drupal SDC documentation and `hero.component.yml` structure.

**Result: ✅ Confirmed** with an important addition. When overriding a component in a subtheme, the subtheme's component directory shadows the parent theme's entirely. If you only copy `hero.twig` and `hero.css` but omit `hero.component.yml`, the component schema is lost (required props become unvalidated). You must always include all three.

However, the strategy document's note — *"for CSS-only overrides, use `libraries-extend` rather than duplicating the full bundle"* — is **correct and important**. If you only need to add CSS to an existing component, do:

```yaml
# pl_neonbyte.info.yml
libraries-extend:
  core/components.neonbyte--hero:
    - pl_neonbyte/hero-override
```

And in `pl_neonbyte.libraries.yml`:
```yaml
hero-override:
  css:
    component:
      css/hero-override.css: {}
```

This avoids duplicating the Twig and schema files — the subtheme CSS loads alongside the parent component's CSS. This is the preferred approach for visual-only tweaks.

---

## Claim 8: CUBE CSS `--pl-*` custom tokens are additive — do they conflict with Dripyard's token namespace?

**Source checked:** `variables-colors-semantic.css` — uses `--primary`, `--primary-100...1000`, `--neutral-*`, `--secondary-*`, `--color-*` prefixes.

`theme-white.css` — uses `--theme-*` prefix.

`ThemeColorPreprocessor.php` — uses `--theme-setting-*` prefix.

**Result: ✅ No conflict.** The `--pl-*` namespace does not collide with any Dripyard token prefix. The strategy is sound. The only caution: `--pl-*` tokens should only be consumed by custom `pl_neonbyte` components — never mixed into Dripyard component overrides, which must use `--theme-*` tokens.

---

## Claim 9: SMACSS categories map to Dripyard's `libraries.yml` weight keys

**Source checked:** `dripyard_base.libraries.yml`:
```yaml
global:
  css:
    base:       css/base/base.css            # ← SMACSS: Base
    component:  css/components/form.css      # ← SMACSS: Component
    layout:     css/layout/layout.css        # ← SMACSS: Layout
    theme:      css/utilities/...css          # ← SMACSS: Theme/Utilities
```

**Result: ✅ Confirmed.** Dripyard uses exactly the same weight category names as the SMACSS system described in the Drupal.org docs: `base`, `layout`, `component`, `theme`. When adding CSS files in `pl_neonbyte.libraries.yml`, placing a token override in `theme` weight and a layout utility in `layout` weight is architecturally correct and consistent with Dripyard's own approach.

---

## Summary of Required Corrections to `theme-change.md`

| # | Location | Issue | Correction |
|---|---|---|---|
| 1 | §3 Options (Layer 3 description) | States components "map exclusively to `--theme-*` variables" | Some components (button) have an intermediate local token layer. Not universal. |
| 2 | §3 Option A (inline CSS var list) | `--theme-setting-container-max-pixel` not mentioned | The container max-width AND all border-radius values are also injected inline — do not override from CSS |
| 3 | §7 SDC component override section | Suggests only CSS-only approach | Clarify: always copy `.component.yml` if also overriding Twig; for CSS-only use `libraries-extend` with correct library name `core/components.[theme]--[component]` |
| 4 | `@layer` section | Implies `@layer` is almost useless for subthemes | Clarify: useful for internal organisation of YOUR rules; `html .theme--` selectors still provide the override power |

---

## What Is Fully Valid and Consistent

- **Token-at-source (Option A):** Setting colors via `drush php-eval` writing to `[theme].settings` config is the **only architecturally correct approach** for primary/secondary colors. Confirmed by reading `ThemeColorPreprocessor.php` directly.
- **`html .theme--white/primary` selectors (Option B):** Correct specificity mathematics, confirmed against actual source selectors in `theme-white.css` and `theme-light.css`.
- **BEM naming with `pl-` prefix:** Consistent with Dripyard and Drupal core conventions.
- **No `!important` except for error/disabled states:** Confirmed by Drupal.org standards and consistent with Dripyard's own source (zero `!important` found in any Dripyard component CSS).
- **Single `css/base.css` file strategy:** Consistent with how `neonbyte_subtheme` is scaffolded (its `css/base.css` is also a single blank file with the instruction "Add custom styles here").
- **Decision tree:** All routing paths are correct against the actual source architecture.
