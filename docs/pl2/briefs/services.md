# Services Brief — `/services`

*Phase 3 content brief. **v1 — 2026-04-22.** All open decisions (D1–D10) resolved and locked. Ready for overlay implementation.*

| Field | Value |
|---|---|
| Entity | `canvas_page` id 3 |
| UUID | `b2613e35-516b-4d7c-86b8-75eb8a5d5356` |
| Current path | `/services` |
| Phase 2 disposition | Rewrite |
| Phase 2 follow-on | Must fold in nearshore testing staff augmentation from retired `/nearshoring` |
| Anchors | [Framework](../repositioning-framework.md) · [Phase 2 plan](../phase-2-page-plan.md) · [Homepage brief](./homepage.md) |
| Links in from | Homepage Pillar 3 (*"How we engage →"*) |

---

## Purpose

`/services` is the page a visitor lands on when the homepage's third pillar — *Experts alongside your team* — earned a click. The reader has already been told Performant Labs is a Drupal testing specialist. This page answers *"what does engaging them actually look like?"* in concrete enough detail that a buyer can self-qualify and book the testing review without another hop.

The secondary job is to house the **nearshore testing staff-augmentation** story that used to live at the retired `/nearshoring` page (Phase 2 decision D). The nearshore block is **one section of this page, not a separate page**.

## Audience

Same ICP as the homepage: organizations running business-critical Drupal sites. But the /services reader is further down the funnel — they've already bought the positioning and are now scoping. Two specific postures to write toward:

1. **Buyer scoping a single engagement.** Needs to see a named offering that maps to their pain ("we need someone to take over our Playwright suite"). Wants shape, not a catalog.
2. **Buyer scoping ongoing capacity.** Needs to understand the nearshore block — region, seniority, engagement shape, how it differs from body-shop offshore.

The page must not read as a services catalog. It must read as *a short menu of testing-specific engagements plus one staff-aug option*.

## Key messages (must land)

1. Every offering on this page is testing work. We do not build Drupal sites.
2. The engagement defaults are senior, Drupal-literate, and testing-specific — no generalist Drupal devs, no offshore body-shop framing.
3. Nearshore is how we scale the people pillar when a client needs embedded capacity — it's additive to the tools and AI, not a replacement for them.
4. The default first step is always a testing review, not a statement of work.

## Tone

Same as homepage — pragmatic, specifics over adjectives, no hype. The /services page carries an additional burden: it must describe *people* work (nearshore) without sliding into staffing-firm tropes. When describing nearshore, write like an engineering manager describing their team, not like a vendor pitching heads.

## What NOT to say

- Nothing that positions us as a Drupal build shop. This includes phrases like "full-stack Drupal development," "site builds," "end-to-end delivery," "Drupal development services" as an umbrella.
- Nothing about nearshore cost advantages, rates, cost savings, or "affordable." The value prop is *senior Drupal testing engineers in a compatible time zone* — cost framing converts exactly the wrong audience.
- No "our developers" / "our team of X engineers" headcount framing. Say *engineers* when referring to the people, or name the role explicitly (e.g. "a senior testing engineer").
- No generic AI hype — same guardrail as homepage; we describe the Claude workflow in specifics, not as a bullet point under "services."
- No implication that we compete with general Drupal dev shops. We don't. We test what other shops build.

## Editorial conventions

- **Playwright before Cypress** any time both are mentioned.
- **"Testing engineer"** — not "QA engineer," not "tester." The distinction matters to the audience.
- **"Nearshore"** when describing the delivery model. Don't say "offshore." Don't say "LATAM" without naming which countries. If hours overlap with US business hours, say so; if they don't, don't imply they do.
- **"Claude agent(s)"** — same convention as homepage — when referencing the autonomous-healing workflow.

---

## Page structure — 6 sections

### 1. Hero

- **H1:** *Testing engagements for Drupal teams.* *(D2 locked: Option A — engagement-first, Drupal-specific.)*
- **Subhead:** *Take over a broken test suite. Embed a senior testing engineer. Pilot AI-driven test healing. Audit accessibility. Every engagement is testing work — we don't build Drupal sites.*
- **Primary CTA:** `Book a testing review` → `/contact-us?intent=testing-review`
- **Secondary CTA:** `See how we test this site` → `/how-we-built-this-site`

**Layout notes:** Single `<h1>` (confirmed correct on live page — the earlier audit that flagged 2 h1s was wrong). **Hero image retired in this overlay pass:** the current `thinker_1600.png` is generic stock that conflicts with the tone guardrail (*"no hype, specifics over adjectives"*). A Drupal-specific replacement — code snippet, test-run screenshot, or workflow diagram — is tracked as a follow-on (task #59). Interim layout is centered text-only, matching homepage §1 shape. The existing section + flex-wrapper structure is replaced with a simpler heading + text + button-row arrangement.

### 2. Four ways we engage

Replaces the current "What we do generally" section. The 4-card grid structure is preserved (D4 locked: keep + reframe); all four card titles and bodies are rewritten to strictly testing scope. The "What we do specifically" 18-card sub-specialty grid beneath it retires entirely (D3 locked: delete — confirmed 18 cards, not 14+, in the 2026-04-22 audit).

- **Section heading:** *Four ways we engage.* (replaces *"What we do generally"*)
- **Subhead:** *Every engagement is testing work. We don't build Drupal sites — we test the ones you already have.* (replaces the live build-shop framing: *"Modern websites can have lots of moving parts so it's best to pick a web site building partner who specializes in building and testing Drupal sites."*)

**4 cards, all testing-specific:**

| # | Title | Body |
|---|---|---|
| 1 | **Testing-suite takeover** | *Your Playwright or Cypress suite is broken, flaky, or abandoned. We take it over, fix it, and either hand it back green or keep running it for you. Ships with ATK where useful.* |
| 2 | **Embedded testing engineer** | *A senior testing engineer joins your team for the duration of a project or release. Pairs with your developers, owns the test strategy, ships with your release cadence.* |
| 3 | **Autonomous-healing pilot** | *We install the same Claude-agent workflow we run on this site, scoped to a slice of your existing test suite. You see how it behaves on real failures before committing to a broader rollout.* |
| 4 | **Accessibility testing** | *WCAG audits integrated into your CI pipeline. Not a one-time report — a continuous automated check that catches regressions before deploy.* |

**Layout notes:** Cards preserve their existing `sdc.dripyard_base.card-canvas` component shape — only `title` and `body` inputs change via `component_inputs`. No new component types added. Cards do not carry individual CTAs in the initial pass; readers scroll to §3–§6 or use the final-CTA at §6. **Per-card `?intent=…` CTA params deferred to `/contact-us` brief (D7 locked: defer).**

**Sub-specialty grid retirement:** the current section `e014edc3-0694-4d76-9b61-772d35e613c0` (heading *"What we do specifically"*) and all 18 child cards (uuids `3cd00424…` through `8be90fdd…`) are `remove_components` targets. Descendant cascade handles cleanup.

### 3. Nearshore testing staff augmentation (ONE block)

Per user directive 2026-04-21, and D5 locked 2026-04-22: nearshore is **one block** on this page, written **deliberately vague** — no region, hours, engagement-shape, or named-client specifics. The block exists because Phase 2 decision D requires folding retired `/nearshoring` content into `/services`; with specifics pending, the block's copy stays general.

> **Tone-guardrail trade-off (accepted 2026-04-22):** a vague nearshore block risks reading as *"we also have nearshore partners"* hand-wave, which tensions against the brief's pragmatic-tone guardrail (*"specifics over adjectives"*). André accepted this trade-off — the block exists as a Phase-2-compliance placeholder until nearshore specifics land. When they do, this section should be rewritten with region / hours / engagement shape / scope limits baked in.

- **Heading:** *Senior testing capacity, when you need more hands.*
- **Body:** *When a project needs ongoing embedded capacity beyond a single senior engineer, we extend the team with additional senior testing engineers through our nearshore delivery channel. Project leadership stays in North America. Engagements are sized to the work, not to a headcount target. Every engineer on this channel is Drupal-literate and testing-specialist — we don't route junior generalists through it.*
- **CTA:** `Talk about capacity →` `/contact-us?intent=nearshore-capacity`

### 4. Proof / dogfooding pointer

Single short paragraph, not a repeat of homepage §4. Covers readers arriving at `/services` directly (search, share link) without having seen the homepage proof block. (D6 locked: include.)

- **Heading:** *These aren't services we're spinning up. They're how we already work.*
- **Body:** *Every engagement ships with the tooling we built and maintain (ATK, Testor) and, where appropriate, the same autonomous-healing workflow we run against this site in CI. If you want to see it before you buy it, start with the how-we-built-this-site walkthrough.*
- **CTA:** `See how we test this site →` `/how-we-built-this-site`

### 5. We Speak — client trust bar

Preserved from current `/services` (D1 locked: 6 sections, trust bar retained per André's override of my default). Logo grid is unchanged: client logos mids 15, 13, 16, 17, 22, 23 (same media entities as homepage trust bar, so any future logo refresh propagates to both pages).

- **Heading:** *We Speak.* (current copy retained; no change required for v1.)
- **Content:** unchanged — 6-logo `logo-grid` component at uuid `dfb7f393-1f76-4e05-8c08-3fd33aff45da`.

**Layout notes:** This section retains its current position (between the dogfooding pointer and the final CTA), matching the live page's existing persuasion flow: *offerings → capacity model → capability proof → client trust → CTA*. Not zero-effort — §4 dogfooding is new and gets inserted immediately before this section.

### 6. Final CTA

- **Heading:** *Not sure which shape fits? Start with a testing review.*
- **Body:** *A 30-minute call with a senior engineer. We'll look at your current workflow, tell you honestly which of the engagement shapes above (if any) makes sense, and leave you with a one-page writeup. No sales pitch. No obligation.*
- **Primary CTA:** `Book a testing review` → `/contact-us?intent=testing-review`
- **Optional micro-CTA:** *Or start with the tools →* `/open-source-projects`

**Deliberately identical to homepage §6.** The same reader leaves via the same door. The existing `title-cta` composite at uuid `509fc6e0-19f4-4339-b284-0c3d602a2fd8` (currently *"Ready to take your web presence to the next level?"* / *"Contact us today"* → `/contact-us`) gets `component_inputs`-patched to the new title, button text, and `?intent=testing-review` href — no component replacement required.

---

## Conversion path

| Goal | CTA | Target | Intent |
|---|---|---|---|
| Primary conversion | Book a testing review | `/contact-us?intent=testing-review` | Senior-engineer consult, 30 min, no obligation |
| Scoped conversion — suite takeover | Talk to us | `/contact-us?intent=suite-takeover` | Reader self-identified a broken/abandoned suite |
| Scoped conversion — embedded engineer | Talk to us | `/contact-us?intent=embedded-engineer` | Reader scoping a named engagement |
| Scoped conversion — healing pilot | Talk to us | `/contact-us?intent=healing-pilot` | Reader scoping an autonomous-healing trial |
| Scoped conversion — nearshore capacity | Talk about capacity | `/contact-us?intent=nearshore-capacity` | Reader scoping ongoing embedded capacity |
| Secondary | See how we test this site | `/how-we-built-this-site` | Self-qualify / educate |

**D7 locked: defer to `/contact-us` brief.** This page emits scoped `?intent=…` params on every CTA; the form is free to branch on them later or ignore them for now (all CTAs still land on a working contact page in the meantime).

## Success criteria

- A buyer who scoped their problem *before* landing on /services can point to the offering card that fits (or honestly conclude none does) without talking to us.
- The nearshore block reads as senior-engineering-capacity, not as offshore cost arbitrage. A reader who came looking for cheap heads leaves.
- No reader finishes the page believing we do Drupal builds. The Phase 1 boundary must feel obvious.
- Every offering card terminates in a contact-form CTA. No dead-end reads.

## Dependencies

- **Nearshore specifics (future iteration)** — when region, hours-overlap, engagement shape, and any scope limits are nailed down, §3 gets rewritten from vague → concrete. Not a blocker for the current overlay pass; D5 is locked as the interim state.
- **Hero image follow-on** — `thinker_1600.png` retires in this pass; the text-only interim matches homepage §1 shape. A Drupal-specific replacement (code snippet / test-run screenshot / workflow diagram) is tracked as task #59.
- **Contact form intent handling** — coordinate with the `/contact-us` brief. If the contact form can't yet branch on `?intent=…`, the CTAs on this page still work but all land on the same generic form.
- **`/how-we-built-this-site` rewrite** — this page's §4 points to it; if that page hasn't been rewritten yet the link will land on a stale page. Same dependency as homepage §4.
- **Homepage Pillar 3 wording** — currently *"Experts alongside your team"* with link text *"How we engage →"*. This brief's §2 uses the framing "four ways we engage." If the wording should match between the two pages, that's a follow-on sync decision.

## Out of scope

- **A standalone `/nearshoring` or `/nearshore-testing` page.** Confirmed 2026-04-21: nearshore lives as ONE block inside /services.
- **The 18 sub-specialty cards** from the current page — retired in this overlay pass (D3 locked: delete).
- **Hero image swap** — tracked as follow-on task #59; `thinker_1600.png` retires in this pass, replacement asset to be sourced separately.
- **Case studies on /services.** The homepage §5 strip is the canonical case-study surface. Don't duplicate here.
- **Pricing.** No rate cards, no engagement pricing, no "starting at." Pricing conversations happen on the call.
- **Per-card CTA intent params beyond the five listed in the Conversion path table.** If the four engagement shapes need finer-grained routing later, add them to `/contact-us` then expose in a follow-on overlay.

---

## Locked decisions log

| ID | Decision | Locked value | Date |
|---|---|---|---|
| D1 | Section count | **6** sections (trust bar retained) | 2026-04-22 |
| D2 | Hero H1 copy | Option A: *"Testing engagements for Drupal teams."* | 2026-04-22 |
| D3 | 18 sub-specialty cards | **Delete entirely** | 2026-04-22 |
| D4 | 4 top-level *"What we do"* cards | **Keep** the 4-card slot, **reframe** all four to testing-only scope | 2026-04-22 |
| D5 | Nearshore specifics | Keep the block, write **deliberately vague** (no region / hours / shape / proof) — tone-guardrail trade-off accepted | 2026-04-22 |
| D6 | §4 dogfooding pointer | **Include** | 2026-04-22 |
| D7 | `?intent=…` query params | Defer to `/contact-us` brief; pages emit params now | 2026-04-22 |
| D8 | Length target | Homepage-parity (~30s read) | 2026-04-22 |
| D9 | Tone check | During overlay T3 review (screenshots + read-aloud) | 2026-04-22 |
| D10 | Hero image | Retire `thinker_1600.png` in this overlay; Drupal-specific replacement tracked as follow-on task #59 | 2026-04-22 |

## Approval

| Stage | Status | Date |
|---|---|---|
| v0 draft | Superseded by v1 | 2026-04-21 |
| v1 — all D1–D10 resolved | Approved by André Angelantoni | 2026-04-22 |
