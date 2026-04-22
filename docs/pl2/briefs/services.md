# Services Brief — `/services`

*Phase 3 content brief. **v0 draft — 2026-04-21.** Not yet approved; contains open decision points for André.*

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

## Page structure — 5 sections (proposed)

> **Open decision (D1): section count.** Homepage has 6 sections. I've proposed 5 for `/services` on the assumption that a trust bar isn't needed here (the reader clicked through from the homepage trust bar). If you want one anyway, we add it between §1 and §2 and the count becomes 6. **Decision needed before this brief is approved.**

### 1. Hero

- **H1 (TBD — two options):**
  - *Option A (engagement-first):* **Testing engagements for Drupal teams.**
  - *Option B (promise-first):* **Senior testing engineers, on your terms.**
- **Subhead (draft):** *Pick a shape: take over our open-source tools, embed a senior testing engineer alongside your team, or hand us the whole release pipeline. Every engagement is testing work — we don't build Drupal sites.*
- **Primary CTA:** `Book a testing review` → `/contact-us?intent=testing-review`
- **Secondary CTA:** `See how we test this site` → `/how-we-built-this-site`

**Layout notes:** Single `<h1>` only (the current page has 2 — accessibility smell flagged in audit). CTAs identical to homepage hero; consistency is deliberate.

> **Open decision (D2): H1 copy.** I don't have a strong preference between the two options. Option A is more concrete and matches the positioning statement; Option B is warmer but softens the Drupal-specific framing. **André to pick, or reject both.**

### 2. What we do (the offerings)

**Current state on the live page:** 4 "general" cards + 14+ sub-specialty cards in a grid (audited 2026-04-21). The grid reads as "we do every kind of Drupal development," which actively contradicts the Phase 1 framework.

**Proposed direction:** replace the grid entirely with **3 named engagement shapes**, each a card with a heading, a one-paragraph description, and a "Talk to us →" link to the contact form with an `?intent=` query param. No sub-specialty grid.

**Shape-only draft — copy to be finalized:**

> **Testing-suite takeover**
> Your Playwright or Cypress suite is broken, flaky, or abandoned. We take it over, fix it, and either hand it back green or keep running it for you. Ships with ATK where useful.
> *`Talk to us →` `/contact-us?intent=suite-takeover`*

> **Embedded testing engineer**
> A senior testing engineer joins your team for the duration of a project or release. Pairs with your developers, owns the test strategy, ships with your release cadence. North American project lead, nearshore delivery options (see §3).
> *`Talk to us →` `/contact-us?intent=embedded-engineer`*

> **Autonomous-healing pilot**
> We install the same Claude-agent workflow we run on this site, scoped to a slice of your existing test suite. You see how it behaves on real failures before committing to a broader rollout.
> *`Talk to us →` `/contact-us?intent=healing-pilot`*

> **Open decision (D3): fate of the 14+ sub-specialty cards.** The current page's long specialty grid (accessibility testing, load testing, API testing, module testing, theme testing, etc.) is the single biggest conflict with the new positioning. Three options:
>
> 1. **Delete the whole grid.** Cleanest. A few of those sub-specialties genuinely are what we sell — but they live naturally inside the three engagement shapes above, not as stand-alone menu items.
> 2. **Keep a condensed 4–6 card grid of testing-only specialties** (accessibility, load, API, visual regression, etc.) — explicitly excluding any "general Drupal development" items.
> 3. **Keep the grid but reframe every card.** Highest rework cost; I don't recommend it.
>
> **My recommendation: option 1.** **André to confirm or override.**

> **Open decision (D4): fate of the 4 top-level "what we do" cards.** On the live page these currently include items like "Drupal Development" and similar build-shop framings. These need to either be deleted (most likely) or rewritten to testing-only scope. **André to confirm delete.**

### 3. Nearshore testing staff augmentation (ONE block)

Per user directive 2026-04-21: nearshore is **one block** on this page, not a separate page or a sub-page of /services.

- **Heading (draft):** *Nearshore testing, senior-only.*
- **Body (draft — specifics are TBD):** *When a client needs ongoing embedded capacity, we extend the team with senior testing engineers working from [REGION TBD] during [HOURS TBD]. Every engineer is Drupal-literate and testing-specialist from day one — we don't route junior generalists through this channel. Project leadership stays in North America. Engagements are full-time or fractional, usually month-to-month after an initial scoping block.*
- **Inline credibility cue (optional):** a short sentence about how long we've run the nearshore model and/or how many engagements it's supported. Write only if the number is honest and specific.
- **CTA:** `Talk about capacity →` `/contact-us?intent=nearshore-capacity`

> **Open decisions (D5) — nearshore specifics.** I need at least:
>
> - **Region(s).** Which countries / which time zones? Brief must name them; vague "LATAM" or "nearshore partners" will fail the pragmatic-tone guardrail.
> - **Hours overlap.** How much of the US business day do these engineers work? If <6 hours, say so honestly — it's still a legitimate model, just a different one.
> - **Engagement minimum / shape.** Is the default FTE or part-time? Month-to-month or quarterly? Is there a minimum?
> - **Named clients / volume proof (optional).** Do we have a client willing to be named for this specifically, or a believable volume statistic?
> - **Any hard scope limits.** Anything a nearshore engineer *won't* do on our engagements (e.g. "they don't run production deploys" / "they don't interface with non-engineering stakeholders directly"). These limits are reassuring to scoping buyers.

### 4. Proof / dogfooding (brief inline pointer)

**Not a repeat of the homepage's §4.** Just a single paragraph anchoring *why* these offerings are credible: we run the same workflow on our own site nightly.

- **Heading (draft):** *These aren't services we're spinning up. They're how we already work.*
- **Body (draft):** *Every engagement ships with the tooling we built and maintain (ATK, Testor) and, where appropriate, the same autonomous-healing workflow we run against this site in CI. If you want to see it before you buy it, start with the how-we-built-this-site walkthrough.*
- **CTA:** `See how we test this site →` `/how-we-built-this-site`

> **Open decision (D6): include or skip this section?** If the homepage §4 already lands the dogfooding proof, repeating it here may be noise. Counter-argument: a /services reader who hit the page via search (not via homepage) hasn't seen the homepage proof yet. **Lean: include.** **André to confirm.**

### 5. Final CTA

- **Heading:** *Not sure which shape fits? Start with a testing review.*
- **Body:** *A 30-minute call with a senior engineer. We'll look at your current workflow, tell you honestly which of the engagement shapes above (if any) makes sense, and leave you with a one-page writeup. No sales pitch. No obligation.*
- **Primary CTA:** `Book a testing review` → `/contact-us?intent=testing-review`
- **Optional micro-CTA:** *Or start with the tools →* `/open-source-projects`

**Deliberately identical to homepage §6.** The same reader leaves via the same door. Don't force a different CTA here just for variety.

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

> **Open decision (D7): intent query params.** `/contact-us` today has a single CTA and (as of the homepage brief) needs at least a `testing-review` intent handler. Do we want the page to also disambiguate between suite-takeover / embedded / healing-pilot / nearshore as separate intents, or is that over-engineering the contact form? **Depends on André's contact-form preference.** Defer decision to the `/contact-us` brief; pages link with intent params now, and the form can choose to branch on them later.

## Success criteria

- A buyer who scoped their problem *before* landing on /services can point to the offering card that fits (or honestly conclude none does) without talking to us.
- The nearshore block reads as senior-engineering-capacity, not as offshore cost arbitrage. A reader who came looking for cheap heads leaves.
- No reader finishes the page believing we do Drupal builds. The Phase 1 boundary must feel obvious.
- Every offering card terminates in a contact-form CTA. No dead-end reads.

## Dependencies

- **Nearshore specifics** (D5 above) — brief cannot go to apply without these. Can ship an approved brief *with* TBDs if André prefers to fill them during implementation.
- **Contact form intent handling** — coordinate with the `/contact-us` brief. If the contact form can't yet branch on `?intent=…`, the CTAs on this page still work but all land on the same generic form.
- **`/how-we-built-this-site` rewrite** — this page's §4 points to it; if that page hasn't been rewritten yet the link will land on a stale page. Same dependency as homepage §4.
- **Homepage Pillar 3 wording** — currently *"Experts alongside your team"* with link text *"How we engage →"*. This brief's §2 uses the framing "engagement shapes" rather than "engagement models." If André prefers the homepage wording to change, or this page's, they should match.

## Out of scope

- **A standalone `/nearshoring` or `/nearshore-testing` page.** Confirmed 2026-04-21: nearshore lives as ONE block inside /services.
- **The 14+ sub-specialty cards** from the current page (pending D3 confirmation). Case made above.
- **Case studies on /services.** The homepage §5 strip is the canonical case-study surface. Don't duplicate here.
- **Pricing.** No rate cards, no engagement pricing, no "starting at." Pricing conversations happen on the call.

---

## Open decisions summary (for André)

| ID | Decision | Default / recommendation |
|---|---|---|
| D1 | Section count — 5 or 6? | 5 (skip trust bar) |
| D2 | Hero H1 — Option A or B or new? | Lean Option A |
| D3 | Fate of the 14+ sub-specialty grid | Delete (option 1) |
| D4 | Fate of the 4 top-level "what we do" cards | Delete |
| D5 | Nearshore specifics (region / hours / shape / proof / scope limits) | Need from André |
| D6 | Include §4 dogfooding pointer? | Lean yes |
| D7 | `?intent=…` query params | Defer to `/contact-us` brief |
| D8 | Overall length target | TBD — homepage is ~30s read; I'd aim similar |
| D9 | Tone check — too engineering-manager, not enough sales? | For André to read-aloud |

## Approval

| Stage | Status | Date |
|---|---|---|
| v0 draft (this document) | Pending André's review | 2026-04-21 |
| Brief approved (all D1–D9 resolved) | — | — |
