# CSS Override Strategy for `pl_neonbyte`

> **Stance.** Per-page, per-symptom CSS is a failure mode. The fix for any styling issue is to climb upward — from the rendered component, to the theme token, to the config — and change the value at its point of origin, not at the point of noticing. This is the principle every rule in this document derives from.

## The Problem

Previous subtheme implementations produced:
- Too many CSS override files (one per symptom)
- `!important` tags accumulating as later fixes fought earlier ones
- Cascade conflicts between Dripyard's inline `<html>` style and external CSS
- Hard-to-maintain stylesheets where any change risked breaking something else

The root cause is a **specificity escalation loop**: override fails → add higher specificity → override that higher specificity → add `!important` → cannot override `!important` → add more `!important`. The loop is fed by making changes at the *point of noticing* (the rendered page) rather than the *point of origin* (the variable or config driving the value). Every rule below exists to force the fix upward.

---

## Why This Loop Starts with Dripyard

Dripyard's OKLCH color engine injects primary/secondary colors as **inline styles on `<html>`**:

```html
<html style="--theme-setting-base-primary-color: #0000d9; ...">
```

Inline styles are at specificity level `(1, 0, 0, 0)` — above every external stylesheet rule. Any attempt to override them from an external CSS file using `:root { --var: value }` will lose silently, prompting the reach for `!important`.

---

## Mandatory Pre-Work: Trace the Chain Before Writing Any CSS

> **Root cause of the "per-page CSS" anti-pattern:** Changes were made at the point of *noticing* the problem (the rendered page) rather than at the point of *origin* in the hierarchy. The result is a stylesheet full of symptom patches that duplicate, fight, and eventually require `!important` to override each other.

**Before writing a single CSS rule, answer these four questions:**

### Q1 — What property am I changing, and what is its current value?

Open browser DevTools on the element. Find the computed value and **trace it to its declaring rule**. The source of truth is never the page — it is the variable chain.

```
Example: I want the hero background to be darker.
DevTools shows: background-color: oklch(1 0 264)
That value comes from: .theme--white { --theme-surface: var(--white); }
Which comes from: --white: white;  (variables-colors-semantic.css)
Which comes from: the config setting base_primary_color (via OKLCH engine)
```

Now I know the property lives in **Layer 3 (theme layer)** and traces back to **Layer 1 (config)**.

---

### Q2 — What is the correct level in the 5-layer hierarchy to change it?

```
Layer 1  CONFIG         [theme].settings — primary/secondary hex, brightness, footer theme,
                         container width, border radius. Set via drush php-eval.
          ↓ reads into
Layer 2  OKLCH ENGINE   --primary-100…1000, --neutral-100…1000, --secondary-100…1000
                         Derived automatically. Cannot be set directly — change Layer 1.
          ↓ maps into
Layer 3  THEME LAYER    --theme-surface, --theme-text-color-loud, --theme-link-color, etc.
                         Defined in theme-white/light/primary/dark/black/secondary.css
                         Override in subtheme: html .theme--white { --theme-surface: #hex; }
          ↓ read by
Layer 4  COMPONENT CSS  .hero, .section, .footer — consume --theme-* tokens directly.
                         Some components (button) have a local token sublayer:
                         .button--primary { --button-background-color: var(--primary); }
          ↓ for complex components
Layer 5  COMPONENT      .button--primary { --button-background-color: var(--primary); }
         LOCAL TOKENS   Override: libraries-extend + .button--primary { --button-background-color: #hex; }
```

**The rule:** Make the change at the **highest layer where it makes architectural sense**. A change that is correct across the whole site belongs in Layer 1 or Layer 3. A change that should apply to one component style belongs at Layer 5 via `libraries-extend`. Never patch Layer 4 (the rendered component output) if the fix belongs at Layer 3.

---

### Q3 — Will this change affect everything that should change, or only the symptom?

This is the test for whether you are at the right layer.

| If you change… | …it affects |
|---|---|
| Config (`base_primary_color`) | Every component on every page — the whole OKLCH palette regenerates |
| `html .theme--white { --theme-surface: }` | Every component rendered inside a white/light zone, on every page |
| `html .theme--primary { --theme-surface: }` | Every component rendered inside a primary/dark zone, on every page |
| `.button--primary { --button-background-color: }` via libraries-extend | Only primary buttons, site-wide |
| `.hero { background: #hex; }` (direct property override) | Only elements with class `.hero`, bypasses the token system — **avoid** |

If "it affects only the symptom (one page, one place)" — you are at the wrong layer. Climb up.

---

### Q4 — Does this change already exist at a higher level and just need to be connected?

Check in this order before writing new CSS:

1. **Config** — `ddev drush config:get pl_neonbyte.settings` — is the brand color already set correctly?
2. **Semantic layer** — Does `--primary-600` or `--neutral-400` already have the shade you need?
3. **Theme layer** — Does `--theme-text-color-soft`, `--theme-surface-alt`, etc. already express what you want?
4. **Component local tokens** — Does the component already have a `--button-background-color` token I can target?

Only if the answer to all four is "no" should you write a new CSS custom property or rule.

---

### The Trace Worksheet (run this for every change)

```
CHANGE: [describe what you want to change in plain English]

1. Property being changed: _______________________
2. Current value (from DevTools): _______________________
3. Rule declaring current value: _______________________
4. Variable providing that value: _______________________
5. Variable that variable reads from: _______________________
6. (Keep going until you reach config or a hardcoded :root value)

Trace chain:
  Component CSS → Layer-? token → Layer-? token → ... → Config or :root

Correct layer to change: Layer __ / file: ___________________
Scope of change: [ ] Whole site  [ ] All [white/primary] zones  [ ] One component type
Already exists at higher level? [ ] Yes → connect it   [ ] No → add at Layer __
```

---

### Worked Example — "The hero heading is too light on mobile"

```
1. Property: color on h2 inside .hero
2. Current value (DevTools): oklch(0.4 0 264) — a dark neutral
3. Declaring rule: h1,h2,h3,h4,h5,h6 { color: var(--theme-text-color-loud); }  ← base.css
4. Variable: --theme-text-color-loud
5. That comes from: .theme--white { --theme-text-color-loud: var(--neutral-1000); }  ← theme-white.css
6. --neutral-1000: oklch(from var(--primary) 0.15 0% h)  ← derived from config primary color

Trace chain:
  h2 color → --theme-text-color-loud (Layer 3) → --neutral-1000 (Layer 2) → --primary (Layer 1 config)

Correct layer: Layer 3 override in html .theme--white { --theme-text-color-loud: #1A2128; }
Scope: All headings in white/light zones, every page — correct.
Already exists? If the config primary color is wrong (too light), fix Layer 1 first.
```

**What the previous build did instead:** Added `.hero h2 { color: #1A2128; }` in a page-specific CSS file — a Layer 4 patch that only fixed that one component, didn't flow to other heading elements, and created a conflict the next time a developer tried to change all headings globally.

---

## The Three Options

---

### Option A — Token-at-Source (Recommended for Dripyard)

**Core idea:** Don't fight the CSS cascade at all. Fix the value at its source — in the Drupal config — so the inline style injection already carries the correct brand color. CSS files are then reserved for layout-level adjustments only.

**How it works:**

1. Write brand colors to `[theme].settings` config via `drush php-eval`:
   ```bash
   ddev drush php-eval "
   \$c = \Drupal::configFactory()->getEditable('pl_neonbyte.settings');
   \$c->set('theme_colors.colors.base_primary_color', '#YOUR_HEX');
   \$c->set('theme_colors.colors.base_primary_color_brightness', 'dark');
   \$c->set('theme_colors.colors.base_secondary_color', '#YOUR_HEX');
   \$c->save();
   "
   ddev drush cr
   ```
   **Why CSS alone cannot set these:** `ThemeColorPreprocessor.php` injects `--theme-setting-base-primary-color` and `--theme-setting-base-secondary-color` as inline `style` attributes on `<html>` at render time. `LayoutSettingsPreprocessor.php` does the same for `--theme-setting-container-max-pixel` and all four `--theme-setting-radius-*` values. Inline styles have maximum CSS specificity — no external stylesheet rule can override them. The only correct method is to write these values to `[theme].settings` config, which is what the preprocess class reads.
2. `pl_neonbyte.settings.yml` pre-seeds these values so they travel with the codebase.
3. `css/base.css` contains **only structural/layout overrides** — not color overrides.

**CSS file count: 1** (`css/base.css`)

**Pros:**
- Zero CSS specificity problems — the OKLCH engine does all the work, generating correct palettes automatically
- Colors are stored in config, versionable, export-safe
- No `!important` needed — ever
- Easiest to maintain long-term

**Cons:**
- Requires all palette decisions to be expressible as primary + secondary variations
- Cannot set a specific shade precisely (e.g., "I want `--primary-400` to be exactly `#FF8C00`") — you control only the anchor, not derived shades
- Requires understanding which config key to set

**Verdict: Use this as the default. Only reach for Option B when the OKLCH palette output doesn't match brand requirements.**

---

### Option B — Scoped Descendant Override (Targeted CSS)

**Core idea:** Override only `--theme-*` variables (Layer 3 — the theme layer), using `html .theme--white { }` selectors. This pattern has higher specificity than `:where(:root)` used in Dripyard's source but does not fight the inline style, which only carries `--theme-setting-*` variables (Layer 1), not `--theme-*` variables. The two don't conflict.

### Component-level CSS rule

Simpler components (hero, section, footer) consume `--theme-*` variables from Layer 3:
```css
.hero {
  background-color: var(--theme-surface);
  color: var(--theme-text-color-loud);
}
```

> **Audit finding:** Complex components like `button` have an **intermediate local token layer** of their own. `button-primary.css` defines `--button-background-color: var(--primary)` at the component level, then applies `background-color: var(--button-background-color)`. This is effectively a 5-layer system for those components. To override button colours, target `--button-background-color` on `.button--primary { }` via `libraries-extend` — do not target `--theme-button-*`.

**How it works:**

```css
/* css/base.css — only override theme-layer variables */

html :where(:root),
html .theme--white,
html .theme--light {
  --theme-surface:           #F5F5F2;
  --theme-text-color-loud:   #1A2128;
  --theme-link-color:        #C07A20;
}

html .theme--primary,
html .theme--dark,
html .theme--black {
  --theme-surface:           #1B2638;
  --theme-text-color-loud:   #FFFFFF;
  --theme-link-color:        #F4A942;
}

/* Typography override */
:root {
  --font-sans: 'Inter', sans-serif;
}
```

**CSS file count: 1** (`css/base.css`)

**Why `html .theme--white` and not `:root`:**

| Selector | Specificity | Wins against `:where(:root)` (0,0,0)? |
|---|---|---|
| `:root { }` | (0, 1, 0) | Yes |
| `:where(:root)` | (0, 0, 0) | Tied — load order decides |
| `html .theme--white { }` | (0, 1, 1) | Yes |
| `html :where(:root) { }` | (0, 0, 1) | Yes |

The `html .theme--white` selector has specificity (0, 1, 1) which beats the base theme's `:where(:root)` at (0, 0, 0). **No `!important` needed.**

**Pros:**
- Clean, predictable cascade — easy to reason about
- Works as a complement to Option A (color anchor via config + surface adjustments via this CSS)
- Single file, all token overrides in one place
- No `!important`

**Cons:**
- More CSS knowledge required to write correctly
- Overrides apply to every component using those tokens — intentional, but must be understood

**Verdict: Combine with Option A. Use Option A for primary/secondary color, use Option B for fine-grained surface/text/link adjustments if brand requires them.**

---

### Option C — CSS Cascade Layers (`@layer`)

**Core idea:** Use CSS cascade layers to explicitly define a priority order that is independent of selector specificity. A rule in a later-declared layer wins over any rule in an earlier layer, regardless of selector specificity.

**How it works:**

```css
/* css/base.css */

/* Declare the layer order — last layer wins. */
@layer dripyard-base, pl-overrides;

/* All base theme rules are implicitly in no layer (unlayered).
   Unlayered styles beat layered styles — so we can't layer Dripyard itself.
   Instead, we put ONLY our overrides in a layer to keep them organized. */

@layer pl-overrides {
  .theme--white {
    --theme-surface: #F5F5F2;
  }

  .theme--primary {
    --theme-surface: #1B2638;
  }

  :root {
    --font-sans: 'Inter', sans-serif;
  }
}
```

> **Critical caveat for Dripyard:** Unlayered CSS (which is everything Dripyard currently ships) **beats layered CSS** in the cascade. This means `@layer` in your subtheme can *not* beat Dripyard's unlayered `:where(:root)` rules. So `@layer` helps organise *your own* overrides but does not solve the base-vs-subtheme specificity battle by itself.

**Where this is genuinely useful:** Organising multiple override files when the project grows large.

```css
/* css/base.css */
@layer tokens, typography, layout, components;

@layer tokens {
  /* Color token overrides */
}

@layer typography {
  /* Font overrides */
}

@layer layout {
  /* Container, spacing */
}

@layer components {
  /* Per-component overrides */
}
```

**CSS file count: 1** (one layered file instead of many scattered files)

**Pros:**
- Explicitly documents the intended override order — readable
- Eliminates the need to count CSS specificity manually within your own code
- Prevents future regressions when adding overrides (later layer always wins)
- Browser support: all current browsers (Chrome 99+, Firefox 97+, Safari 15.4+, Edge 99+)

**Cons:**
- Does not help beat Dripyard's unlayered base theme styles (they always win over layered styles)
- More complex — requires understanding `@layer` semantics before using
- Overkill for a small subtheme with one CSS file

**Verdict: A useful organisational pattern for the future, but not the primary solution for the Dripyard inline-style-override problem. Viable as a structure inside `css/base.css` once the project grows beyond one file.**

---

## Recommendation: Combined Approach

| Problem | Solution |
|---|---|
| Brand primary/secondary colors | **Option A** — set in config via `drush php-eval` / `.settings.yml` |
| Surface/text/link token tweaks | **Option B** — `html .theme--white/primary` selectors in `css/base.css` |
| Typography (font family) | `:root { --font-sans: ...; }` — no conflict here, no inline style for fonts |
| Per-component layout tweaks | Component-scoped CSS in `css/[component].css` + `libraries-extend` |
| Future multi-file organisation | **Option C** — `@layer` block structure inside `css/base.css` |

> Do not copy the entire schema if you only need to add CSS. For CSS-only overrides, use `libraries-extend` to augment the parent component's library. The library name for an SDC component is `core/components.[theme_machine_name]--[component-name]`. Example:
> ```yaml
> # pl_neonbyte.info.yml
> libraries-extend:
>   core/components.neonbyte--hero:
>     - pl_neonbyte/hero-override
> ```
> Always copy `.component.yml` if you are also providing an overriding Twig template — omitting it drops required prop validation.

### Rules That Eliminate `!important` Entirely

1. **Never write a CSS property override** when a theme token (`--theme-*`) override achieves the same result.
2. **Never use `:root` to override Dripyard color tokens.** Use `html .theme--white { }` instead.
3. **Never write per-symptom CSS files.** A new file is only justified when it carries a distinct concern (a component override via `libraries-extend`, or a page-context layout file like `layout/canvas.css`). Symptom-patching files belong at the layer above, not in a new file.
4. **Never override `--theme-setting-*` variables in CSS.** These are only correctly set via Drupal config. CSS overrides of them fail silently.
5. **One concern per file, loaded deliberately.** `base.css` holds tokens, `@property` registrations, and `html .theme--*` zone overrides — nothing else. Component overrides live in `components/[name].css`, one per component, loaded via `libraries-extend`. Page-context layout rules (canvas, documentation, etc.) live in `layout/[context].css`, loaded as global libraries scoped by a body class. Keep each file narrow enough that a single git revert rolls back exactly one concern. *(The earlier "no more than 2 CSS files" formulation was a provisional guardrail for the seed of the theme; once the subtheme has components and page-contexts, it is outgrown.)*

---

## CSS File Structure for `pl_neonbyte`

```
css/
├── base.css                ← tokens, @property registrations, html .theme--* overrides.
│                             No !important. No component rules. No layout rules.
├── layout/
│   └── [context].css       ← page-context layout (canvas, docs, …), scoped by body class,
│                             loaded as a global library.
└── components/
    └── [name].css          ← one file per component override, loaded via libraries-extend.
```

The `pl_neonbyte` seed starts with just `base.css`; `layout/` and `components/` populate only when a concrete component or page context demands an override that a token change cannot express.

### `css/base.css` template

```css
/**
 * @file
 * pl_neonbyte — brand overrides for NeonByte.
 *
 * Rules:
 * - No !important.
 * - No --theme-setting-* variable overrides (set those in config).
 * - Use html .theme--* selectors for all color token overrides.
 * - :root is only used for variables Dripyard does NOT inject inline (fonts, etc.).
 */

/* ─── Typography ───────────────────────────────────────────────── */
/* Safe to set at :root — Dripyard does NOT inject font vars inline. */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap');

:root {
  --font-sans: 'Inter', sans-serif;
}

/* ─── Light / white zones ──────────────────────────────────────── */
/* Overrides Dripyard's :where(:root) — specificity (0,1,1) > (0,0,0). */
html :where(:root),
html .theme--white,
html .theme--light {
  --theme-surface:           #F5F5F2;
  --theme-text-color-loud:   #1A2128;
  --theme-text-color-medium: #2D3540;
  --theme-link-color:        #C07A20;
  --theme-link-color-hover:  #92600A;
  --theme-focus-ring-color:  #C07A20;
}

/* ─── Dark / primary zones ─────────────────────────────────────── */
html .theme--primary,
html .theme--dark,
html .theme--black {
  --theme-surface:           #1B2638;
  --theme-surface-alt:       #2D3E48;
  --theme-text-color-loud:   #FFFFFF;
  --theme-text-color-medium: #F0F1F0;
  --theme-text-color-soft:   #AABBC8;
  --theme-link-color:        #F4A942;
  --theme-link-color-hover:  #E8973A;
  --theme-focus-ring-color:  #F4A942;
}
```

---

## What Must Be in Config, Not CSS

| Setting | Mechanism | Why |
|---|---|---|
| Primary brand hex color | `drush php-eval` → `theme_colors.colors.base_primary_color` | Drives OKLCH engine — CSS can't reach it |
| Primary color brightness | `drush php-eval` → `base_primary_color_brightness` | Sets `html.primary-color-is-dark` class on `<html>` |
| Secondary brand hex color | Same | Same |
| Footer theme | `footer.theme` in `.settings.yml` | PHP reads this at preprocess time |
| Header theme | `header_settings.theme` | PHP reads this at preprocess time |
| Logo path | `logo.path` in both `system.theme.global` and `[theme].settings` | Two independent locations |
| Container max width | `layout_settings.container_max_width` | Injected as `--theme-setting-container-max-pixel` |

---

*Sources: Drupal.org theming docs, CSS-Tricks cascade layers guide, Lullabot `@layer` integration, direct inspection of `dripyard_base` source, prior live-run failure patterns in `docs/ai_guidance/operational-guidance.md`.*

---

## Additional Guidance from Online Research

The following was sourced by reading the actual documentation pages, not just search summaries.

---

### From Drupal.org: Official CSS Architecture Standards

Source: [drupal.org/docs CSS Architecture for Drupal 9](https://www.drupal.org/docs/develop/standards/css/css-architecture-for-drupal-9) *(note: content moved to GitLab but still the authoritative reference)*

The Drupal community's own CSS standards define four goals for well-architected CSS:

1. **Predictable** — Changes should do what you expect with no side-effects.
2. **Reusable** — Rules should be abstract enough to build new components from existing parts without recoding.
3. **Maintainable** — Adding or modifying CSS should not break existing styles.
4. **Scalable** — CSS should be manageable by one developer or a large distributed team.

#### The five SMACSS categories (used by Drupal core)

These map directly to Dripyard's own CSS weight categories in `libraries.yml`:

| Category | Purpose | `libraries.yml` weight key |
|---|---|---|
| **Base** | HTML element resets only. No class selectors. | `base` |
| **Layout** | Page-level arrangement, grid systems. | `layout` |
| **Component** ("module") | Reusable, discrete UI elements. The bulk of all CSS. | `component` |
| **State** | Transient changes: hover, active, open. Use `.is-*` prefix. | (inline via JS usually) |
| **Theme** | Pure visual: colors, borders, shadows, fonts. | `theme` |

#### The five common CSS pitfalls (identified by Drupal.org)

These are the exact patterns that caused the `!important` accumulation in previous theme work:

| Pitfall | What it looks like | Why it's harmful |
|---|---|---|
| **Modifying by context** | `.sidebar .component {}` | Unpredictable — the same component looks different based on where it lives |
| **Relying on HTML structure** | `nav > ul > li > a {}` | Brittle — any markup change breaks it; very high specificity |
| **Overly generic class names** | `.widget .title {}` | A later `.title` component accidentally styles widget titles |
| **Making a rule do too much** | One rule sets color + border + padding + font | Cannot reuse pieces of it |
| **Needing to undo styles** | `.component-no-padding {}` | Signals the original rule did too much |

> **Key principle from Drupal.org:** *"Never use `!important` to resolve specificity problems for general CSS rules."* It is only acceptable for forced states (error, disabled) that must always apply regardless of context.

#### BEM naming conventions (as used by Dripyard)

Dripyard follows BEM exactly. For any custom CSS added in `pl_neonbyte`:

```css
/* Component block */
.pl-banner {}

/* Component elements (double underscore) */
.pl-banner__title {}
.pl-banner__media {}

/* Variants / modifiers (double dash) */
.pl-banner--compact {}
.pl-banner--full-width {}

/* State classes (always .is- prefix, applied via JS) */
.pl-banner.is-active {}
.pl-banner.is-hidden {}

/* JS hooks (never styled — only used in JS) */
/* .js-banner-toggle — do not put in any .css file */
```

Rules:
- Maximum 2 combinators in any selector: `.pl-banner > .pl-banner__media` — beyond this, add a class.
- Never use `#id` selectors in CSS.
- Never use element + class qualifiers: `a.pl-button {}` — use `.pl-button {}` alone.

---

### From MDN: The `@layer` Rule — What It Actually Does

Source: [developer.mozilla.org/en-US/docs/Web/CSS/@layer](https://developer.mozilla.org/en-US/docs/Web/CSS/@layer)

**The single most important fact about `@layer`:**

> *"Styles that are not defined in a layer always override styles declared in named and anonymous layers."*

This means if Dripyard ships unlayered CSS (which it does), your `@layer` blocks will **lose** to it by default. This is the opposite of what most people expect.

The correct mental model:

```
Priority (highest to lowest):
  1. Inline styles (style="...")       ← Dripyard injects here
  2. Unlayered CSS                     ← All of Dripyard's .css files
  3. @layer last-defined               ← Your subtheme layers
  4. @layer first-defined
```

**Where `@layer` IS genuinely useful in `pl_neonbyte`:**

Organising your OWN subtheme CSS into a predictable order — the `html .theme--*` selectors still provide the override power; `@layer` just keeps your own rules organised so later-declared layers win without specificity tricks between them:

```css
/* css/base.css — declare order once at the top */
@layer tokens, typography, layout, components, states;

@layer tokens {
  /* html .theme--white / .theme--primary overrides */
  html :where(:root), html .theme--white, html .theme--light {
    --theme-surface: #F5F5F2;
  }
}

@layer typography {
  :root {
    --font-sans: 'Inter', sans-serif;
  }
}

@layer components {
  /* Any custom pl_neonbyte component CSS goes here.
     A rule here always beats a rule in @layer tokens,
     regardless of selector specificity. */
}

@layer states {
  /* .is-active, .is-hidden, error/disabled states.
     Always wins — even over component layer. */
  .is-hidden { display: none; }
}
```

**Browser support:** All current browsers since March 2022 (Chrome 99, Firefox 97, Safari 15.4, Edge 99). Safe to use now.

---

### From CUBE CSS: Semantic Token Naming

Source: [cube.fyi](https://cube.fyi) + community research

CUBE CSS (Composition, Utility, Block, Exception) is the methodology closest to how Dripyard itself is structured. Its token guidance is directly applicable:

**Name tokens by intent, not by value:**

```css
/* ❌ Value-based — breaks when the color changes */
--color-blue-700: #1d4ed8;

/* ✅ Intent-based — still correct even if the brand color changes */
--color-action-primary: #1d4ed8;
--color-surface-page: #ffffff;
--color-text-body: #1a2128;
```

For `pl_neonbyte`, this means any custom tokens added to `css/base.css` should use the `--pl-*` prefix with intent-based names:

```css
/* Custom PL tokens (supplement Dripyard's --theme-* system) */
:root {
  --pl-color-brand-accent: #F4A942;       /* CTA highlights */
  --pl-color-brand-muted:  #AABBC8;       /* Secondary text */
  --pl-spacing-section:    var(--spacing-xxxl);  /* Reuse Dripyard scale */
}
```

> **Do not pair `var()` with a hex fallback in component rules.** The pattern `color: var(--pl-color-amber, #F59E0B)` is redundant when the token is registered via `@property` with a static `initial-value` in `base.css`. The `@property` fallback is strictly stronger: it survives *successful-but-invalid* declarations (e.g., a downstream rule sets `--pl-color-amber: broken`), whereas the `var()` hex fallback only catches *missing* declarations. Duplicating the hex at every callsite costs real maintenance for a weaker safety net. Register the token with `@property` once; reference it as `var(--pl-color-amber)` everywhere.

**Keep overrides at the highest sensible scope:**

> CUBE CSS principle: *"Override tokens as high up the DOM tree as possible so they are automatically inherited by all relevant components."*

For Dripyard, the highest correct scope is `html .theme--white` and `html .theme--primary` — not per-component selectors. Setting tokens there means every component in that theme zone automatically picks up the brand values without needing component-specific overrides.

---

### Synthesis: The Decision Tree for Any CSS Override

When you find yourself about to write a CSS override in `pl_neonbyte`:

```
Is it a color?
  → Is it primary or secondary brand color?
      YES → Use drush php-eval to set theme_colors config. Not CSS.
      NO  → Is it a surface/text/link/border adjustment?
              YES → Override the --theme-* variable in html .theme--white/primary block.
              NO  → Is it a per-component tint?
                      YES → Override in component's own .css file via libraries-extend.

Is it typography?
  → Font family: :root { --font-sans: ...; } — safe, no inline conflict.
  → Font size: Use Dripyard's --h1-size, --body-m-size etc. tokens. Override at :root.

Is it layout / spacing?
  → Use Dripyard's --spacing-* and --sp* scale tokens. Override at :root.
  → Custom layout class? Write it in @layer layout { } in base.css.

Is it a state (hover, active, open, error, disabled)?
  → Write in @layer states { }. Prefix class with .is-*.
  → This is the ONE case where !important is sometimes justified (error/disabled).

Is it JavaScript-driven?
  → Never write .js-* classes in CSS. Use .is-* state classes instead.
```
