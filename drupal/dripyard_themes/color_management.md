# Dripyard Color Management & Custom Overrides

This document captures the proper architectural approach to bypassing the automatic color generation system natively utilized by Dripyard's `dripyard_base` and its subthemes (such as `neonbyte`).

## The Dripyard 4-Layer Color Architecture

Dripyard uses a complex 4-layer color system powered by CSS `oklch()` color math to maintain WCAG 2.2 AA accessibility ratios automatically. 

1. **Theme Settings Layer**: The two anchor colors (Base Primary and Base Secondary) configured in the Drupal UI.
2. **Semantic Scale Layer**: The core engine uses the anchors to automatically extrapolate two full 10-shade scales (e.g., `--primary-100` through `--primary-1000` and `--neutral-100` through `--neutral-1000`) using `oklch` lightness interpolation. 
3. **Theme Layer**: It distributes those semantic scales into 5 built-in theme wrappers (`White, Light, Primary, Dark, Black`). These map out specific variables like `--theme-surface`, `--theme-text-color-loud`, and `--theme-border-color`.
4. **Component Layer**: Every block or menu inherits styles natively based on the overarching wrapper classes (e.g. `<footer class="site-footer theme--primary">`).

## The Overriding Pitfall (CSS Specificity Wars)

If you attempt to inject hardcoded static Hex codes by overriding Layer 3 Theme Variables (e.g. `--theme-surface`) inside a custom `base.css` file, you will likely encounter frustrating UI inconsistencies. 

For example, simply overriding `:root { --theme-surface: #F0F1F0; }` will fail on certain blocks (like headers or footers) because those blocks utilize highly specific descendant wrappers like `.theme--primary` or `.theme--dark`. Thus, your overrides will lose the CSS specificity battle against the theme's core engine, resulting in random elements reverting to the original OKLCH-calculated bright blue `#0000d9` defaults.

**Do not use `!important` tags.** CSS pipelines and preprocessors natively used in Drupal's aggregation often choke on `!important` declarations injected inside CSS custom property variables. 

## The Architecturally Correct Solution: Override the Semantic Layer

The safest and most upgrade-proof way to bypass the "fancy system" while ensuring all components inherit your colors flawlessly is to declare static values against the **Layer 2 Semantic Variables** at the `:where(:root)` pseudo-class level in your custom subtheme's `base.css`. 

By intercepting the underlying shades _before_ the Theme Layer uses them, the 5 core theme wrappers (White/Light/Primary/Dark/Black) will dynamically consume your exact colors across the entire site layout. 

### Example Configuration Snippet

Place this in your subtheme's stylesheet (`web/themes/custom/[subtheme_name]/css/base.css`):

```css
/* Architecturally Correct Semantic Overrides */
:where(:root) {
  /* 1. Base Primary & Secondary Anchors */
  /* Re-declare the anchors so the OKLCH engine calculates shades cleanly off your hexes */
  --base-primary-color: #1B2638;
  --base-secondary-color: #F59E0B;

  /* 2. Specific Neutral/Scale Overrides */
  /* Intercept explicit mathematical shades and force them to your specific brand palette */
  --neutral-100: #F0F1F0;   /* Lightest background shade (Used in Light/White themes) */
  --neutral-600: #555F68;   /* Medium borders and subdued UI text */
  --neutral-800: #2D3E48;   /* Deep slate body/accent text */
  
  --secondary-700: #92600A; /* Dark amber hover states */
}
```

This single configuration perfectly bridges a completely custom 6-color palette smoothly onto the robust block rendering systems expected by Dripyard!
