# Mobile Single-Page Verification Plan

A runbook for verifying that a single page looks and works correctly in mobile view.

This plan follows the **Three-Tier Verification Hierarchy** — always start at Tier 1 and escalate only when needed.

---

## What Agents Can (and Cannot) Verify

| Check | Automatable? | Who judges |
|-------|-------------|------------|
| HTTP status, meta tags, DOM structure | ✅ Fully | Agent (Tier 1) |
| ARIA landmarks, heading order, button labels | ✅ Fully | Agent (Tier 2) |
| Obvious layout breaks (horizontal scroll, overflow) | ✅ Reliably | Agent (Tier 3) |
| Screenshot regression vs. a committed baseline | ✅ With baseline | Agent (Tier 3 pixel-diff) |
| **Spacing is aesthetically correct** | ❌ Not automatable | **Human** |
| **Visual rhythm and padding feel right** | ❌ Not automatable | **Human** |
| **Design matches intent / brand spec** | ❌ Not automatable | **Human** |

> [!WARNING]
> An agent can confirm that padding is *non-zero* and that content doesn't overflow. It **cannot** tell you whether 12 px of padding feels cramped, or whether section spacing looks balanced. That always requires a human eye — ideally compared against a design reference or the approved desktop layout.

---

## Target

| Field       | Value                                              |
|-------------|----------------------------------------------------|
| **Page URL** | `https://dev-performant-labs.pantheonsite.io/`    |
| **Viewport** | `390 × 844` (iPhone 14 / Mobile Safari equivalent) |

> [!NOTE]
> Swap the page URL for any path you want to verify. The viewport above is a sensible mobile default. For tablet, use `768 × 1024`.

---

## Tier 1 — Headless Checks (curl)

Run these first. They are fast (~1–5 s) and answer most structural questions without opening a browser.

```bash
# 1. HTTP 200 check
curl -sk -o /dev/null -w '%{http_code}' https://dev-performant-labs.pantheonsite.io/

# 2. Viewport meta tag is present (mobile rendering requires this)
curl -sk https://dev-performant-labs.pantheonsite.io/ \
  | grep -o '<meta name="viewport"[^>]*>'

# 3. H1 is present
curl -sk https://dev-performant-labs.pantheonsite.io/ \
  | grep -o '<h1[^>]*>[^<]*</h1>'

# 4. Primary navigation markup is in the DOM
curl -sk https://dev-performant-labs.pantheonsite.io/ \
  | grep -o '<nav[^>]*>'
```

**Pass criteria:**
- [ ] HTTP status is `200`
- [ ] `<meta name="viewport" content="width=device-width...">` is present
- [ ] At least one `<h1>` exists with readable text
- [ ] At least one `<nav>` element exists

> [!IMPORTANT]
> If the viewport meta tag is missing, the page **will not render correctly** in mobile view regardless of CSS. Stop here and fix before escalating.

---

## Tier 2 — ARIA Structural Skeleton

Open the page in a browser **resized to the mobile viewport** and read its accessibility tree. This confirms that JS-rendered content (hamburger menus, drawers, lazy-loaded sections) materialised correctly.

**How to run (agent):**

Use `read_browser_page` after navigating to the target URL with the viewport set to `390 × 844`.

**Checklist:**

### Navigation
- [ ] A `navigation` landmark is present
- [ ] The mobile menu trigger (hamburger button) has an accessible name — e.g. `button "Open menu"` or `button "Menu"`
- [ ] After activating the trigger, the nav links appear in the ARIA tree (drawer/menu is not just visually hidden via `display:none` when open)

### Page Structure
- [ ] `main` landmark is present
- [ ] `Heading Level 1` has the expected page title
- [ ] No heading levels are skipped (H1 → H2 → H3, not H1 → H3)

### Interactive Elements
- [ ] All CTA buttons and links have meaningful accessible names (no bare "click here" or empty labels)
- [ ] No interactive element is marked `aria-hidden="true"` while visually visible

### Images
- [ ] No `<img>` is missing an `alt` attribute
- [ ] Decorative images use `alt=""`

---

## Tier 3 — Visual Screenshot (Agent-verifiable only)

**Only escalate here once Tier 1 and Tier 2 both pass.**

Capture a full-page screenshot at `390 × 844` using `browser_subagent`. The agent checks for **objective, binary failures** — things that are clearly broken, not things that require aesthetic judgment.

> [!NOTE]
> Tier 3 can only detect *regressions* when a committed baseline screenshot exists. On a **first-time review** of a new page, there is no baseline — the agent can describe what it sees, but cannot judge whether spacing values are correct. That requires human review (Tier 4).

**Agent-verifiable checklist:**

### Layout (objective)
- [ ] No horizontal scrollbar is present at `390 px` width
- [ ] No element visibly bleeds outside the viewport
- [ ] No content is clipped behind a sticky header or footer

### Navigation (objective)
- [ ] Desktop-only nav elements are not visible at mobile width
- [ ] A hamburger or menu icon is present in the header
- [ ] Activating the menu reveals navigation links

### Images & Media (objective)
- [ ] No image is distorted (stretched or squished)
- [ ] No image overflows its container

### Footer (objective)
- [ ] Multi-column footer has collapsed to a single column (links do not overflow horizontally)

---

## Tier 4 — Human Review (Required for Spacing & Visual Quality)

**This tier cannot be skipped or delegated to an agent.**

A human reviewer opens the page in a real browser (or browser DevTools device emulation at `390 × 844`) and judges the following. Compare against the approved design spec or the desktop layout as a reference.

### Spacing & Rhythm
- [ ] Section padding feels generous enough — content doesn't feel cramped against screen edges
- [ ] Vertical spacing between sections creates a comfortable reading rhythm
- [ ] The hero area uses the viewport height intentionally (not too tall, not cut off)
- [ ] Cards, list items, and repeated components have consistent gaps between them

### Typography
- [ ] Line lengths are comfortable — long paragraphs don't span the full 390 px (consider `max-width` or side padding)
- [ ] Font sizes feel appropriate for mobile (body ≥ 16 px, headings proportional)
- [ ] Hero headline wraps at a natural break point (no awkward orphans)

### Touch Targets
- [ ] Buttons and links feel easy to tap (minimum 44 × 44 px — verify by feel, not just computed size)
- [ ] Form inputs are large enough to tap without mis-tapping adjacent fields

### Overall Impression
- [ ] The page looks intentionally designed for mobile, not just "shrunk down"
- [ ] Nothing feels broken, crowded, or confusing at first glance
- [ ] Color contrast holds up at mobile size (small text on colored backgrounds)

> [!TIP]
> The fastest human review method: load the page on an actual phone. DevTools emulation is good for catching bugs but doesn't replicate real touch feel or font rendering. Spend 2 minutes scrolling the real device before signing off.

---

## Pass / Fail Decision

| Tier | All checks pass? | Action |
|------|-----------------|--------|
| Tier 1 | ✅ | Proceed to Tier 2 |
| Tier 1 | ❌ | Fix blocking issues first, re-run Tier 1 |
| Tier 2 | ✅ | Proceed to Tier 3 |
| Tier 2 | ❌ | Fix ARIA/DOM issues, re-run Tier 2 |
| Tier 3 | ✅ | Proceed to Tier 4 (human review) |
| Tier 3 | ❌ | File CSS/layout bug, fix, re-run Tier 3 |
| Tier 4 | ✅ | **Page passes mobile verification** ✓ |
| Tier 4 | ❌ | File design/spacing bug, fix, re-run Tier 4 |

---

## Recommended Tools for Tier 4

These tools go beyond regression testing and provide actual **visual quality feedback** on a live URL. They are the best available aids for the human review step — they don't replace judgment, but they surface issues faster.

| Tool | What it does | Best for | Cost |
|------|-------------|----------|------|
| **[Attention Insight](https://attentioninsight.com)** | AI-generated attention heatmaps predicting where users look. Has an explicit **Mobile analysis mode** — paste a URL or screenshot and it shows whether hierarchy and CTAs are registering. | Pre-launch visual hierarchy check | Free tier available |
| **[Roast My Web](https://roastmyweb.com)** | Submits your URL, AI critiques design and UX against best practices — spacing, clarity, visual weight. Opinionated and fast. | Quick first-pass design critique | Free |
| **[WebScore.ai](https://webscore.ai)** | Scans a live URL and scores it across mobile usability, visual hierarchy, performance, and CRO. No signup required for initial audit. | Structured scored report across multiple dimensions | Free for basic audit |
| **[Microsoft Clarity](https://clarity.microsoft.com)** | Free session recordings and heatmaps from real mobile users — shows rage clicks, scroll depth, and where people actually struggle. | Post-launch with real traffic | Free |
| **[Hotjar](https://hotjar.com)** | Same category as Clarity but with richer survey/feedback tools. Good for collecting qualitative mobile feedback alongside behavioral data. | Post-launch with real traffic | Free tier available |

> [!NOTE]
> **Attention Insight** and **Roast My Web** work pre-launch on a staging URL. **Clarity** and **Hotjar** require real user traffic and are best for ongoing monitoring after launch.

> [!TIP]
> The recommended Tier 4 workflow: run **Roast My Web** for a quick opinionated critique, then **Attention Insight** in Mobile mode to validate that your primary CTA is in the predicted top-attention zone. Then do the manual phone check from the checklist above.

---

## Notes

- Use `browser_subagent` with `RecordingName` set to `mobile_verification` to capture a video of the mobile interaction (hamburger open/close, scroll).
- For Playwright automation, enable the `Mobile Safari` project in `playwright.config.js`:
  ```js
  {
    name: 'Mobile Safari',
    use: { ...devices['iPhone 14'] },
  }
  ```
- If testing a DDEV local environment, prefix all `curl` commands with `ddev exec`.
