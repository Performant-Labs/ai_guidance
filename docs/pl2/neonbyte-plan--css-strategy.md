# `performant_labs_20260418` — CSS Strategy

> **⚠ Superseded — 2026-04-20.** The operative CSS strategy is [`theme-change.md`](theme-change.md). The operating procedure is [`theme-change--workflow.md`](theme-change--workflow.md). The 8 rules below are preserved as historical context for `20260418` only — read them to understand *why* the current approach was adopted, then follow `theme-change.md` for any new work.
>
> **Parent:** [`neonbyte-plan--components.md`](neonbyte-plan--components.md)
> **Replaces the approach used in:** `performant_labs_20260411`

---

<details>
<summary><strong>Legacy — the 8-rule strategy as written for `20260418` (kept for historical reference; do not cite as authoritative)</strong></summary>

## What Went Wrong in `20260411`

| Problem | Symptom |
|---|---|
| Screenshot-driven CSS | Rules written to match a visual, not to extend the design system |
| One flat `base.css` | Globals, component overrides, layout hacks, and button variants all in one file |
| Hardcoded hex everywhere | `#F59E0B`, `#1B2638` copied into every rule — not referenced from tokens |
| No layer strategy | Rules fought each other; specificity escalated to fix specificity |
| Reactive, not deliberate | CSS added when something "looked wrong," not from an audit of what neonbyte already provides |
| No per-component files | Component CSS piled into global scope, impossible to roll back one change without affecting others |

---

## The Rules for `20260418`

### Rule 1 — Tokens first, CSS last

Before writing any CSS rule, check what NeonByte already exposes:

1. Open the component in the SDC explorer (`/styleguide/explorer`)
2. Inspect the rendered HTML — which CSS custom properties (`--var`) are already on the element?
3. Can the change be made by overriding a token in `settings.yml`? If yes — do that, write no CSS.
4. Only write CSS if the token system cannot express the change.

**The goal:** `css/base.css` should be nearly empty. `settings.yml` should do the heavy lifting.

---

### Rule 2 — `base.css` is for globals only

`css/base.css` may only contain:

```css
/* Allowed in base.css */
:root { }                          /* Custom property overrides */
.canvas-page { }                   /* Page-level layout context */
.path-frontpage { }                /* Path-specific context */
@media (max-width: Npx) { }       /* Global responsive rules */
```

**Not allowed in `base.css`:**
- Any component class (`.accordion-*`, `.content-card`, `.hero__*`)
- Button variants (`.button--cta`) — these go in a `button-overrides` library
- Font declarations that duplicate what neonbyte already sets

---

### Rule 3 — One file per component, via `libraries-extend`

Every component override gets its own file and its own library entry. Never add component CSS to `base.css`.

**Step 1** — Add the library to `performant_labs_20260418.libraries.yml`:
```yaml
accordion-override:
  css:
    component:
      css/components/accordion.css: {}

content-card-override:
  css:
    component:
      css/components/content-card.css: {}
```

**Step 2** — Extend the component library in `performant_labs_20260418.info.yml`:
```yaml
libraries-extend:
  core/components.dripyard_base--accordion:
    - performant_labs_20260418/accordion-override
  core/components.dripyard_base--content-card:
    - performant_labs_20260418/content-card-override
```

**Step 3** — Write only the delta in the component file:
```css
/* css/components/accordion.css */
/* PL override: amber icon, thin border rows */

.accordion-item__icon {
  color: var(--color-amber-400, #F59E0B);  /* token → fallback */
}
```

Result: adding or removing a component override is one git revert.

---

### Rule 4 — Reference tokens, never hardcode hex

| Instead of | Use |
|---|---|
| `color: #F59E0B` | `color: var(--color-amber-400, #F59E0B)` |
| `color: #1B2638` | `color: var(--color-navy-900, #1B2638)` |
| `background-color: #F59E0B` | `background-color: var(--theme-setting-base-secondary-color)` |

The fallback value (`#F59E0B`) keeps it safe if a token ever changes name. But the token must be first.

**Before writing a new token reference**, check:
- `themes/dripyard_base/css/` — base token definitions
- `themes/neonbyte/css/` — neonbyte token layer
- The rendered HTML in browser devtools — look for `--` variables already on the element

---

### Rule 5 — CSS layer awareness

NeonByte uses CSS `@layer`. Overrides must land in the correct layer or they'll be silently ignored or incorrectly weighted.

```css
/* Wrong — no layer context, may lose to layered rules */
.accordion-item { border-radius: 0; }

/* Right — explicitly in the component layer */
@layer components {
  .accordion-item { border-radius: 0; }
}
```

Check `themes/dripyard_base/css/base.css` and `themes/neonbyte/css/` to confirm which layers are declared before writing any override.

---

### Rule 6 — The mandatory workflow for every change

Before writing CSS for any component, follow [`theme-change--workflow.md`](theme-change--workflow.md):

1. **Audit** — What does neonbyte already render for this component? (`theme-change--audit.md`)
2. **Identify the variable** — Is there a CSS custom property or `settings.yml` key that controls this?
3. **Prefer the token** — Change it there first.
4. **Write the minimum delta** — Only what cannot be achieved via the token.
5. **Verify in the SDC explorer** — T2 pass before committing.
6. **Commit** — One commit per component, never batched.

---

### Rule 7 — The audit document drives the order

Work from [`neonbyte-plan--component-audit.md`](neonbyte-plan--component-audit.md) top to bottom.
For each component, fill in the **Decision** field before writing any code:

- **Port** — the `20260411` approach was correct, copy and refactor to use tokens
- **Improve** — the approach was right but the CSS was wrong; rewrite using the rules above
- **Drop** — neonbyte already handles this; no override needed

A **Drop** decision is a win. Every line not written is a line that can't break.

---

### Rule 8 — Mobile is not optional; it is part of done

Every component CSS file must include responsive breakpoints **before the component is committed**. A component that looks correct on desktop but breaks on mobile is not done.

**Required mobile checks for every component:**
- Layout stacks correctly at 375px (single-column where applicable)
- Text is legible at base font size; no horizontal overflow
- Touch targets are ≥44px tall (WCAG 2.5.5 recommended)
- Hover animations use `@media (hover: hover)` guard — never fire on touch devices
- Images scale within their containers without unexpected cropping

**Pattern — touch-safe hover:**
```css
/* Wrong — fires on tap, leaves element lifted permanently on touch */
.content-card:hover { transform: translateY(-2px); }

/* Right — only on devices that can hover */
@media (hover: hover) {
  .content-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 16px 48px rgba(0, 0, 0, 0.16);
  }
}
```

**Pattern — responsive stacking:**
```css
@media (max-width: 640px) {
  .content-card {
    width: 100%;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08); /* lighter shadow on mobile */
  }
}
```

---


When Stage 2 is complete, `performant_labs_20260418/` should look like:

```
performant_labs_20260418/
├── css/
│   ├── base.css                      ← globals only (~50 lines max)
│   └── components/
│       ├── accordion.css             ← via libraries-extend
│       ├── content-card.css          ← via libraries-extend
│       ├── tabs.css                  ← via libraries-extend
│       ├── button-cta.css            ← via libraries-extend
│       └── hero.css                  ← via libraries-extend
├── config/
│   └── install/
│       └── performant_labs_20260418.settings.yml   ← brand tokens here first
└── performant_labs_20260418.libraries.yml           ← one entry per component
```

---

## Verification Before Any CSS Is Written

```bash
# See NeonByte's CSS custom properties available to override
grep -r "\-\-" themes/neonbyte/css/ | grep "^\s*--" | sort -u | head -40
grep -r "\-\-" themes/dripyard_base/css/ | grep "^\s*--" | sort -u | head -40
```

Run this before starting Stage 2. The output is the full token vocabulary available without writing a single line of CSS.

</details>

---

## Where the rules map in the current system

| Legacy rule (above) | Status under `theme-change.md` |
|---|---|
| Rule 1 — Tokens first, CSS last | Retained as the foundation of Q4 in the Trace Worksheet |
| Rule 2 — `base.css` is for globals only | Refined: `base.css` is for tokens + `html .theme--*` zone overrides; structural layout CSS lives in `layout/*.css` |
| Rule 3 — One file per component via `libraries-extend` | Retained and made authoritative (see `theme-change.md` §Rules) |
| Rule 4 — Reference tokens, never hardcode hex | Retained; the `var(--token, #hex)` fallback pattern is **dropped** — `@property` registration in `base.css` provides a stronger fallback that survives successful-but-invalid declarations, not just missing ones |
| Rule 5 — CSS layer awareness | Retained as context; `@layer` is for organising the subtheme's own rules, not for beating unlayered contrib CSS (see `theme-change.md` §Option C caveat) |
| Rule 6 — Mandatory workflow | Superseded by [`theme-change--workflow.md`](theme-change--workflow.md) |
| Rule 7 — Audit document drives the order | Retained via [`neonbyte-plan--component-audit.md`](neonbyte-plan--component-audit.md) |
| Rule 8 — Mobile is part of done | Retained verbatim; consumed by Step 5 T1/T2 verification |
