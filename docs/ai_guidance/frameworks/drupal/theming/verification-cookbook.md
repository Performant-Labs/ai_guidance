# Verification Cookbook

This document is the authoritative reference for the **Three-Tier Verification Hierarchy**. It defines the "Skeleton-First" workflow designed to maximize developer velocity by using accessibility (ARIA) data as a high-speed diagnostic lens.

---

## The Three-Tier Hierarchy

Always use the fastest tool that provides sufficient structural confirmation before escalating to slower, more resource-intensive tools.

| Tier | Method | Speed | Diagnostic Goal |
|---|---|---|---|
| **Tier 1** | **Headless (Instant)** | ⚡ 1–5s | Server-side state, HTTP status, DOM tag presence, CSS variables |
| **Tier 2** | **Structural Skeleton (Fast)** | 🚀 5–10s | Assembly verification, component presence, H1–H6 levels, buttons, and functional links |
| **Tier 3** | **Visual Fidelity (Slow)** | 🐢 60–90s | Final visual regression, pixel-level alignment, color-matching, and layout spacing |

---

## Tier 1 — The Pulsing Check (Headless)

Use `curl` for instant confirmation of non-visual state.

- **HTTP Status**: `ddev exec "curl -sk -o /dev/null -w '%{http_code}' [url]"`
- **Heading Tag**: `ddev exec "curl -sk [url] | grep -o '<h1>[^<]*</h1>'"`
- **CSS variable check**: `ddev exec "curl -sk [url] | grep -o 'theme-setting-base-primary-color:[^;]*'"`
- **Nav Link audit**: `ddev exec "curl -sk [url] | grep '/articles/my-page'"`

---

## Tier 2 — The High-Speed Structural Lens (ARIA)

Use the Accessibility (ARIA) Tree via the `read_browser_page` tool for all structural and JS-rendered content verification. This is the **authoritative developer loop** for construction testing.

### The "Skeleton-First" Workflow
1. **Assemble** the component or page using Drush/PHP.
2. **Audit Tier 2** immediately: Confirm the component exists in the A11y tree and has the correct roles/labels.
3. **Iterate** if the skeleton is broken (5s fix loop).
4. **Escalate to Tier 3** only when the skeleton is 100% correct.

### Common Tier 2 Audit Patterns

#### 1. Verifying a Hero Section
- [ ] Record has `main` or `banner` landmark.
- [ ] Contains `Heading Level 1` with the expected title.
- [ ] Contains a `button` or `link` with the CTA text (e.g., "Get Started").

#### 2. Verifying a Sidebar Navigation (Books/Docs)
- [ ] Contains a `navigation` region.
- [ ] The current page link has the `aria-current="page"` status.
- [ ] Child links exist in the correct hierarchy (depth indicated in the tree).

#### 3. Verifying a Logo Grid
- [ ] Contains a `list` or `region` dedicated to logos.
- [ ] Each logo has a functional `aria-label` or `alt` text and is a `link`.

#### 4. Backdrop Changes — Re-run Contrast, Don't Re-screenshot

**Rule:** Any layout change that moves an element's backdrop requires a fresh T2 contrast pass, not just a T3 screenshot.

A screenshot can *look* readable at thumbnail-resolution while the underlying contrast ratio is failing WCAG. T3 is a vision-token channel; accessibility is a numeric property. Measure it numerically.

**Trigger conditions — run this check if any of the following is true in the diff:**

- A layout token that affects vertical position of a region changes (e.g., `--space-for-fixed-header`, `--container-offset`, `padding-top` on a layout wrapper).
- A region's `position` changes (`static` ↔ `fixed`/`sticky`/`absolute`) or its `z-index` is altered such that it now overlays different content.
- A parent's `theme--*` class changes, or a descendant is relocated under a different theme zone.
- A background image or gradient is swapped on a region that contains text or interactive elements.
- An ancestor's `background-color` / `background-image` changes.

**T2 command pattern:**

```js
// Run inside a Playwright page.evaluate() call, after the layout change ships.
const fg = document.querySelector('<selector of the text/icon>');
const bgEl = document.querySelector('<selector of the nearest painted backdrop>');

// Resolve CSS colors to sRGB via canvas so oklch(), color-mix(), rgba() all work.
const toRGBA = (cssColor) => {
  const c = document.createElement('canvas');
  const g = c.getContext('2d');
  g.fillStyle = cssColor;
  g.fillRect(0, 0, 1, 1);
  const [r, g_, b, a] = g.getImageData(0, 0, 1, 1).data;
  return { r, g: g_, b, a: a / 255 };
};
const composite = (f, b) => ({
  r: Math.round(f.r * f.a + b.r * (1 - f.a)),
  g: Math.round(f.g * f.a + b.g * (1 - f.a)),
  b: Math.round(f.b * f.a + b.b * (1 - f.a)),
});
const lum = ({ r, g, b }) => {
  const L = [r, g, b].map(c => {
    const v = c / 255;
    return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
  });
  return 0.2126 * L[0] + 0.7152 * L[1] + 0.0722 * L[2];
};

const fgColor = toRGBA(getComputedStyle(fg).color);
const bgColor = toRGBA(getComputedStyle(bgEl).backgroundColor);
const composited = composite(fgColor, bgColor);
const L1 = lum(composited), L2 = lum(bgColor);
const ratio = (Math.max(L1, L2) + 0.05) / (Math.min(L1, L2) + 0.05);
// WCAG AA: body ≥ 4.5, large ≥ 3.0. AAA: body ≥ 7.0, large ≥ 4.5.
```

**Gates:**
- [ ] Foreground selector identified and `color` computed.
- [ ] Actual backdrop selector identified (the element whose paint the text lands on — **not** always the text element's immediate parent; trace upward until you find a non-transparent `background-color` or a `background-image`).
- [ ] Contrast ratio ≥ 4.5:1 for body, ≥ 3.0:1 for large text (WCAG AA).
- [ ] If the ratio fails, fix direction of the color (light→dark or dark→light depends on the new backdrop) and re-check. Do **not** proceed to T3.

**Incident reference — 2026-04-20, PL2 canvas hero:** a layout change zeroed `--space-for-fixed-header` to let the hero bleed to the top of the viewport. The nav, previously sitting on a light `theme-surface` band, now sat on dark navy `theme--primary` hero. Nav color token (`--theme-text-color-soft`) was calibrated for light backgrounds; on the new dark backdrop the contrast ratio was **2.33:1 — failing AA body and AA large both**. The T3 screenshot at desktop viewport did not obviously flag this — it looked "appropriately muted". A T2 contrast pass at the point of backdrop-change would have caught it immediately. Retuning the token to `color-mix(in oklch, var(--white) 75%, transparent)` brought the ratio to **9.15:1 (AAA body pass)**. Documented in `visual-regression-report.md` under that date.

---

## Tier 3 — Visual Fidelity (Screenshots)

Reserve `browser_subagent` screenshots exclusively for visual sign-off.

- **Use Cases**: Correct padding/margins, color-matching against design references, z-index overlaps, and mobile menu animations.
- **Efficiency Rule**: Follow Section 10 of the Operational Guidance to batch all screenshots into a single subagent call across multiple viewport positions.
- **Gate before T3**: If the current change moved an element's backdrop (layout token change, position switch, theme-zone relocation, background swap), run the T2 **Backdrop Changes** contrast check before taking the screenshot. A visually-muted screenshot can still be a WCAG failure.

---

## Why this is 20x Faster
- **Payload Size**: An ARIA snapshot is typically 10–15KB, while a 4K screenshot context can exceed 5MB in vision-tokens.
- **Processing Speed**: LLMs can "see" a bug in text (e.g., a missing button in the list) much faster than they can find it in a complex image.
- **Zero Pixel Noise**: Structural testing ignores CSS "glitches" that don't affect function, allowing the developer to focus on assembly integrity first.
