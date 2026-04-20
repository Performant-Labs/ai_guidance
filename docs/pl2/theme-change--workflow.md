# CSS Change Workflow for `pl_neonbyte`

A human-initiated, AntiGravity-assisted process for making CSS changes at the correct layer in the Dripyard hierarchy. Prevents the per-page CSS anti-pattern and eliminates `!important` accumulation.

---

## Roles

| Actor | Responsibility |
|---|---|
| **Human** | Describe the desired change, approve the layer/scope, provide visual sign-off |
| **AntiGravity** | Trace the variable chain, identify the correct layer, make the change, verify, log |
| **Deterministic tools** (Stylelint, pre-commit) | Enforce the rules mechanically — flag `!important`, direct property overrides, and changed files not recorded in the change log |

---

## The Steps

### Step 1 — Human: Describe the desired change in plain English

Open AntiGravity and describe what looks wrong or what you want to achieve. No CSS, no file names, no variable names required.

> *"The footer link colour is too light."*
> *"I want the header to use our brand orange as the background."*
> *"The body text feels too small on mobile."*

This is the only required input to start the loop.

---

### Step 2 — AntiGravity: Runs the trace and checks every higher layer first

AntiGravity does **two passes** — bottom-up trace to find the origin, then a top-down eligibility check to find the highest layer where the fix is correct. Nothing is proposed until each higher layer has been explicitly ruled out.

**Pass 1 — Bottom-up trace (find the origin):**
```
Property:      color on <a> inside .footer
Current value: oklch(0.48 0.12 264)  [computed]
Declared by:   .theme--primary { --theme-link-color: var(--color-primary-text-color); }
Comes from:    Layer 3 (theme-primary.css)
Traces to:     --primary (Layer 2) → base_primary_color config (Layer 1)
```

---

**DOM-inspection gate — mandatory before Pass 2.**

Pass 2 cannot start until **one** of the following is true:

- **(a)** the relevant ancestor DOM chain has been inspected with live-page evidence — Tier 1 (curl + grep) is sufficient; Tier 2 (ARIA structural read) is used when JS renders into the chain — and the inspected wrappers and their applied width/padding/overflow constraints are recorded in the trace worksheet; **or**
- **(b)** the proposed change is unambiguously at **Layer 1** (Drupal config) or **Layer 3** (`--theme-*` token override in `html .theme--*`), where no DOM wrapper is involved.

Any Layer 4 or Layer 5 change that targets a structural wrapper (region, block, field, layout container, site-main, etc.) **requires (a)**. Writing defensive selectors for wrappers that have not been DOM-verified is the anti-pattern this gate exists to prevent — it was how the 2026-04-20 canvas.css release block accumulated selectors for `.region--content`, `.field--name-field-sections`, and `.field--type-entity-reference-revisions`, all three of which never rendered on the page they were trying to fix.

The verification protocol is defined in [`theming/verification-cookbook.md`](../ai_guidance/frameworks/drupal/theming/verification-cookbook.md) §Tier 1 and §Tier 2. Use the fastest tier that answers "does this wrapper render, and does it impose the constraint we're trying to defeat?"

**Worksheet addition — Pass 2 entry gate:**
```
DOM inspection evidence (required for Layer 4/5 structural fixes):
  [ ] Tier 1: wrapper exists in rendered HTML       (command run + match/no-match)
  [ ] Tier 1: wrapper has a width/padding/overflow
              cap imposed by contrib CSS            (file + line)
  [ ] Tier 2: (only if JS-rendered)                 (landmark path)
  [ ] N/A — change is Layer 1 or Layer 3            (explain)
```

If a row is checked but the evidence string is missing, the gate is closed. Pass 2 does not start.

---

**Pass 2 — Top-down eligibility (rule out higher layers first):**
```
Layer 1 check: Is base_primary_color in config wrong?
               → drush config:get shows #1B3A6B — correct brand colour. NOT the fix.

Layer 2 check: Is an OKLCH-derived shade (--primary-200…1000) already correct?
               → --color-primary-text-color resolves to white (correct for dark bg).
                  The problem is the link colour, not brightness detection. NOT the fix.

Layer 3 check: Can --theme-link-color in .theme--primary be set to brand value?
               → YES. This is a deliberate brand deviation from the OKLCH-derived colour.
                  Correct layer: Layer 3. Scope: all links in primary zones, every page.

→ Proposed fix: Layer 3
   html .theme--primary { --theme-link-color: #F4A942; }
   File: css/base.css
   Ruling: Layers 1 and 2 checked and ruled out.
```

Human sees the full two-pass report — nothing has been written yet.

---

### Step 3 — Human: Approves the layer and scope

AntiGravity presents options **ordered from highest to lowest layer**. The human chooses one — or overrides downward with a reason.

**Options presented in this order:**

1. **Layer 1 — Config fix** *(only shown if Layer 1 is the root cause)*
   → AntiGravity writes a `drush php-eval` config change. CSS is not touched.

2. **Layer 3 — Theme token override** *(the proposed default if Layer 1 is ruled out)*
   *"Set `--theme-link-color` in all primary/dark zones — affects every page."*
   → AntiGravity proceeds to Step 4 at Layer 3.

3. **Layer 5 — Component-scoped override** *(targeted; only if Layer 3 is intentionally too broad)*
   *"Scope this to `.footer` only via `libraries-extend`."*
   → AntiGravity revises to a Layer 5 override and notes in the change log that Layer 3 was available but deliberately not used.

> If the human chooses a lower layer than AntiGravity proposed, they must provide a reason. AntiGravity records that reason in the change log entry so future sessions understand the scope was intentionally limited.

This is the only judgment call requiring a human.

---

### Step 4 — AntiGravity: Makes the change

AntiGravity writes the CSS (or config change) directly to the permanent subtheme file at the approved layer. No staging through Drupal config entities.

**Iteration speed**: keep a local watch task running during visual work so file saves surface in the browser within ~1s. Two acceptable setups:

1. **Vite / browsersync watch** pointed at `themes/custom/[subtheme]/css/**/*.css`, injecting CSS on change. No Drupal cache clear needed for CSS-only edits because Drupal serves the physical file directly when aggregation is off.
2. **Aggregation off + targeted cache-tag invalidation**:
   ```bash
   ddev drush config:set system.performance css.preprocess 0 -y   # once
   # then on each save:
   ddev drush cache:rebuild --tags=library_info
   ```

Either way, the edit lives in the permanent file from the first keystroke. The previous "write to Asset Injector first, migrate later" loop is explicitly **not** used — it creates orphan-entity risk and a manual cleanup step that is reliably forgotten.

AntiGravity drafts the CSS (or config change) at the approved layer, with a comment that records the layer and the ruling from Pass 2:

```css
/* [Layer 3] --theme-link-color: brand override (L1+L2 ruled out — intentional deviation
   from OKLCH-derived colour). See css-change-log.md:L42 */
html .theme--primary {
  --theme-link-color: #F4A942;
}
```

AntiGravity appends an entry to the change log. The entry differs based on the ruling:

**If the approved layer is the highest eligible layer (structural fix):**
```
[Layer 3] --theme-link-color in .theme--primary → #F4A942  css/base.css:L47  2026-04-18
  Ruling: L1 correct, L2 auto-derived, L3 is correct layer.
```

**If the human chose a lower layer than proposed (intentional deviation):**
```
[Layer 5] --theme-link-color scoped to .footer → #F4A942  css/footer-override.css:L3  2026-04-18
  Ruling: L3 was available but scoped down by human — footer-only brand treatment intended.
```

This distinction matters for the loop: a structural fix at Layer 3 should not be revisited. A deliberate scope-down to Layer 5 should be reviewed if a global change is later requested.

---

### Step 5 — AntiGravity: Runs T1 + T2 verification

AntiGravity follows the Three-Tier Verification Hierarchy defined in [`theming/verification-cookbook.md`](../ai_guidance/frameworks/drupal/theming/verification-cookbook.md). That document is the authoritative reference — this section names which tiers are mandatory at Step 5 and what counts as passing.

1. **T1 — Headless (curl + grep), 1–5s.** Clear cache (`ddev drush cr`), curl the target page, and grep for the variable value or selector in the rendered HTML. Mandatory. T1 confirms the CSS file is being served and the token/property is present.
   ```bash
   ddev drush cr
   curl -sk "$URL" | grep -oE '--theme-link-color:[^;]+;' | head -1
   ```
2. **T2 — ARIA structural tree, 5–10s.** Read the rendered structure and confirm the computed value of the changed property matches what was written. T2 is required when the change affects structural behaviour (layout, visibility, focus order) or when T1 alone cannot confirm the fix landed (e.g., the property is set by JS at runtime). If the computed value does not match what was written, something downstream is overriding it — AntiGravity re-runs Step 2 (trace) on the conflicting rule; the human is not involved unless the conflict requires a scope decision.

Never skip T1 in favour of a screenshot. Never skip T2 when the change is structural.

The human sees nothing unless T1 or T2 fails.

---

### Step 6 — Human: Visual sign-off (T3 — only when needed)

T3 (browser screenshot, 60–90s) is the last tier and is **blocking** when the change involves brand colour, typography, spacing, or any decision that cannot be judged from curl or ARIA output. Follow the protocol in [`theming/visual-regression-strategy.md`](../ai_guidance/frameworks/drupal/theming/visual-regression-strategy.md): one screenshot = one design slice vs. one live viewport; pass pre-sliced `designs/NN_*.webp` files (never the full composite); write findings incrementally to the visual regression report before returning.

If the change is purely mechanical (a variable value that was demonstrably wrong, verified at T1/T2), T3 may be skipped. If it involves brand intent, the human is the judge.

> *"Yes, that's the right shade"* → done.
> *"Still not right"* → back to Step 1 with the new description.

**Do not open a browser/screenshot loop until T1 and T2 have both passed.** A screenshot that looks right while T2 is failing is masking a structural defect that will surface on another page.

---

### Step 7 — Human/AntiGravity: Finalize and Commit

Re-enable CSS aggregation if it was turned off for iteration (`ddev drush config:set system.performance css.preprocess 1 -y`) and run `ddev drush cr` so the committed version matches the production-like path.

The change log entry written during the process travels with the commit. Git history plus the log gives a complete record of what was changed, at what layer, and when.

---

## The Loop

Before Step 2 of any new change request, AntiGravity reads the change log first. If the property being requested has already been overridden in a previous session, AntiGravity flags it:

> *"`--theme-link-color` in `.theme--primary` was already set at Layer 3 on 2026-04-18 (css/base.css:L47). A second override here would mean the first fix was at the wrong layer. Should we revise that instead?"*

This prevents the accumulation of fighting overrides across sessions.

---

## Change Log

`docs/pl2/css-change-log.md` — tracked in git, updated by AntiGravity at Step 4, read by AntiGravity at the start of every new session.

Format:
```
[Layer N] --variable-name  in  .selector  →  value  file:line  YYYY-MM-DD  [note]
```

Example entries:
```
[Layer 1] base_primary_color → #1B3A6B  config (drush)  2026-04-17
[Layer 3] --theme-surface in .theme--white → #F5F5F2  css/base.css:L12  2026-04-18
[Layer 3] --theme-link-color in .theme--primary → #F4A942  css/base.css:L47  2026-04-18
[Layer 5] --button-background-color in .button--primary → #F4A942  css/button-override.css:L3  2026-04-19
```

---

## Human Touchpoints: Summary

| Step | Human action | Why human, not AntiGravity |
|---|---|---|
| 1 | Describe the change | You know what's wrong |
| 3 | Approve layer + scope | Judgment call — site-wide vs targeted |
| 6 | Visual sign-off | Brand intent cannot be evaluated by AI |
| 7 | Commit | Code ownership |

All other steps — trace, file edit, cache clear, verification, log update — are AntiGravity.

---

## References

AntiGravity reads the following documents at the indicated steps. A human initiating a new session should ensure these are available to the agent.

### Architecture & Layer System

| Document | Read at | Purpose |
|---|---|---|
| [`themes/dripyard-guidance.md`](../ai_guidance/themes/dripyard-guidance.md) | Step 2 | Complete 5-layer hierarchy reference — used to identify which layer a variable belongs to and what the correct override mechanism is |
| [`theme-planning/color-management.md`](../ai_guidance/frameworks/drupal/theme-planning/color-management.md) | Step 2 | The `html .theme--*` selector pattern and its specificity rationale |
| [`docs/pl2/theme-change.md`](theme-change.md) | Step 2 | Full options and rules for this specific subtheme — the working reference for the trace |
| [`docs/pl2/theme-change--audit.md`](theme-change--audit.md) | Step 2 | Audit of the strategy against actual Dripyard source — clarifies the 5-layer reality and the `libraries-extend` library name format |

### Verification Protocol

| Document | Read at | Purpose |
|---|---|---|
| [`theming/verification-cookbook.md`](../ai_guidance/frameworks/drupal/theming/verification-cookbook.md) | Step 5–6 | Authoritative T1/T2/T3 hierarchy — AntiGravity must follow this exactly, never skipping T1 or T2 |
| [`theming/visual-regression-strategy.md`](../ai_guidance/frameworks/drupal/theming/visual-regression-strategy.md) | Step 6 | T3 visual sign-off protocol — used when appearance judgment is needed |

### Agent Behaviour

| Document | Read at | Purpose |
|---|---|---|
| [`theming/ai-guided-theme-generation.md`](../ai_guidance/frameworks/drupal/theming/ai-guided-theme-generation.md) | Before Step 1 (agent onboarding) | Master SOP for AI agents doing Drupal theme work — mandatory reading before any action |
| [`theming/operational-guidance.md`](../ai_guidance/frameworks/drupal/theming/operational-guidance.md) | Step 4–5 | Known failure patterns: drush hangs, logo config dual-location, cache timing — avoids re-discovering gotchas |
| [`agent/naming.md`](../ai_guidance/agent/naming.md) | Step 4 | Applies if change log entries or new CSS class names are being created |

### Component Work (Layer 5 only)

| Document | Read at | Purpose |
|---|---|---|
| [`theming/component-cookbook.md`](../ai_guidance/frameworks/drupal/theming/component-cookbook.md) | Step 3–4 (if scope is Layer 5) | Authoritative prop/slot names — required if the approved change resolves to a `libraries-extend` component override |
| [`theme-planning/theme-component-mapping-plan.md`](../ai_guidance/frameworks/drupal/theme-planning/theme-component-mapping-plan.md) | Step 3–4 (if scope is Layer 5) | Maps design intent to specific SDC components — used when the change affects a component that needs a Twig override, not just CSS |
