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

---

## Tier 3 — Visual Fidelity (Screenshots)

Reserve `browser_subagent` screenshots exclusively for visual sign-off.

- **Use Cases**: Correct padding/margins, color-matching against design references, z-index overlaps, and mobile menu animations.
- **Efficiency Rule**: Follow Section 10 of the Operational Guidance to batch all screenshots into a single subagent call across multiple viewport positions.

---

## Why this is 20x Faster
- **Payload Size**: An ARIA snapshot is typically 10–15KB, while a 4K screenshot context can exceed 5MB in vision-tokens.
- **Processing Speed**: LLMs can "see" a bug in text (e.g., a missing button in the list) much faster than they can find it in a complex image.
- **Zero Pixel Noise**: Structural testing ignores CSS "glitches" that don't affect function, allowing the developer to focus on assembly integrity first.
