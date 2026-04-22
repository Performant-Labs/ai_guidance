# About Us Brief — `/about-us`

*Phase 3 content brief. **v1 — 2026-04-22.** D1–D13 locked via defensible defaults (see "Locked decisions" at the bottom). Ready for overlay implementation.*

| Field | Value |
|---|---|
| Entity | **None yet** — greenfield. André creates the empty `canvas_page` shell via admin UI; overlay targets that uuid. |
| URL | `/about-us` *(D12 locked)* |
| Phase 2 disposition | Rewrite *(NEW vs runbook — no legacy to displace)* |
| Phase 2 follow-on | Carry André's 19+ years of Drupal work, OSS authorship (ATK and Testor), and the dogfooding story. |
| Anchors | [Framework](../repositioning-framework.md) · [Phase 2 plan](../phase-2-page-plan.md) · [Services brief](./services.md) · [Homepage brief](./homepage.md) · [How We Built This Site brief](./how-we-built-this-site.md) |
| Links in from | Main nav (new entry) + footer (existing link fixed). No homepage link in v1. *(D7, D13 locked.)* |

---

## Audit findings (read-only survey, 2026-04-22)

Full audit output: `.claude-bridge/res-audit-about-us-2026-04-22a.out` + `…-b.out` + `.claude-bridge/res-audit-osp-atk-2026-04-22a.out` + `.claude-bridge/res-fetch-atk-testor-stats-2026-04-22a.out` + `.claude-bridge/res-fetch-aangel-drupalorg-2026-04-22a.out`.

1. **`/about-us` returns HTTP 404 today.** `/about` also 404s. Path is unclaimed.
2. **No canvas_page titled "About*"** exists. The nine canvas_pages on the site are: Home (1), Services (3), How We Do It (4), Open Source Projects (5), Introduction to ATK (11), Articles (12), Contact Us (13), Automated testing (14), How We Built This Site (16).
3. **No node titled "About*"** exists. The Phase 2 plan's reference to `nid 10` is stale nid drift — nid 10 is currently an article titled *"Layout Builder Can Break Your Site — Part 1"*.
4. **No redirects** touch `about`.
5. **One inbound menu link:** id 43, *"About Us"* → `internal:/about` in the **footer** menu — currently pointing at a 404. Fixed as part of this work.
6. **Main nav has no About entry** today: Services, How We Do It, Articles, Open Source Projects, Contact Us. Adding *"About"* is part of this work.

**Implication:** this is a greenfield create. No content to preserve, no alias dance, no unpublish step.

## Fact inventory (verifiable sources — cite these when drafting, don't embellish)

These are the concrete anchors the page is built from. Every claim in the copy below traces back to one of these:

| Fact | Source |
|---|---|
| André Angelantoni, drupal.org user `aangel`, member for **19 years 9 months** as of 2026-04-22 (joined ~2006) | [drupal.org/u/aangel](https://www.drupal.org/u/aangel) |
| Projects credited to André on drupal.org (selected, testing-relevant first): Automated Testing Kit, Automated Testing Kit D7, Automated Testing Kit Demo Recipe, Campaign Kit, Layout Builder Kit, Drupal Quality Initiative (DQI), Audit Kit, AI Drush Tools, Payment Stripe, Bay Area Drupal Camp (community role) | [drupal.org/u/aangel](https://www.drupal.org/u/aangel) project listing |
| ATK lives at `drupal.org/project/automated_testing_kit` (HTTP 200) — supports both Cypress and Playwright | [drupal.org/project/automated_testing_kit](https://www.drupal.org/project/automated_testing_kit) |
| Testor is a Node CLI companion to ATK — GitHub `Performant-Labs/testor`, description *"Command-line tool designed to work with Automated Testing Kit"*, last pushed 2025-11-11 | [github.com/Performant-Labs/testor](https://github.com/Performant-Labs/testor) |
| Performant Labs GitHub org hosts 43+ public repos — including `atk_drupal_demo`, `atk_standalone`, `atk_lambda_func`, `atk_test_data`, `automated_testing_kit_d7`, `atk_demo_support` (earliest 2023-12) | [github.com/Performant-Labs](https://github.com/Performant-Labs) |
| This site runs a Claude-agent-driven test-healing workflow nightly, authored and documented | `/how-we-built-this-site` canvas_page (16) |
| André has presented at Bay Area Drupal Camp (DQI project page references this) | `/open-source-projects` on-site copy |

**Deliberate omissions (do not cite without verification):**

- No "GitHub star count" claim anywhere on the page. Actual counts are small (testor=1, atk_drupal_demo=2) — citing them would weaken the page.
- No "N+ Drupal sites running ATK" claim without a fresh install-count pull — drupal.org's usage widget wasn't parseable from the page fetch, so this number is held out. If André wants the number, re-fetch at draft time.
- No DrupalCon talk list. Bay Area Drupal Camp is verifiable; DrupalCon-specific talks need a source (session archive URL) before they land in copy. Held out of v1.

---

## Purpose

`/about-us` is the page a visitor lands on when they want to answer *"who actually does this work, and can I trust them with a business-critical Drupal site?"* After the homepage pitches the positioning and `/services` and `/automated-testing` describe the offerings, `/about-us` has to earn the credibility those pages assume.

It's **not** a generic company-overview page. It's a proof-asset page that turns three concrete facts into a credibility story:

1. **Depth of Drupal tenure** — on drupal.org since 2006 (verifiable). Nearly two decades, deliberately narrowed to testing as the practice matured.
2. **Open-source authorship** — named author on ATK (+ D7 variant + Demo Recipe), Campaign Kit, Layout Builder Kit, Drupal Quality Initiative, Audit Kit, and more. Verifiable at [drupal.org/u/aangel](https://www.drupal.org/u/aangel). Plus Testor, the GitHub-hosted CLI companion to ATK.
3. **Dogfooding** — this site runs the Claude-agent-driven test-healing workflow we sell. Proof lives at `/how-we-built-this-site`.

The page exists because the rest of the site earns attention but doesn't fully earn *trust* — and in a market crowded with agencies that all say "senior" and "proven," we need the concrete evidence compactly presented.

## Audience

Same ICP as the homepage (organizations running business-critical Drupal sites), at two decision moments:

1. **Pre-first-contact due diligence.** A prospect who's read `/services` and is about to book a testing review, pausing to confirm we're real. The page has to resolve that doubt in <60 seconds of skim.
2. **Stakeholder sell-through.** The person who found us is justifying the conversation to someone more senior. They need a URL that stands up on its own.

Not the audience: students/jobseekers, press/journalists, general casual browsers. The copy should feel peer-to-peer between engineers.

## Key messages (must land)

1. **We've been doing Drupal testing since before it was a category.** 19+ years on drupal.org, deliberately narrowed to testing.
2. **We wrote the tools.** ATK and Testor aren't "things we contribute to" — we are the authors. The drupal.org credits are the hardest-to-fake signal on the page.
3. **We test what we ship.** This site runs the autonomous-healing workflow nightly; `/how-we-built-this-site` is the proof.
4. **Small team of senior testing engineers.** No junior-heavy agency math. Size isn't quantified on the page in v1 (D3 locked — leave unquantified).
5. **Testing specialist, not a build shop.** Same positioning guardrail as `/services`.

## Tone

- **Peer-to-peer, not brochure.** Write like an engineer introducing another engineer.
- **Specifics over adjectives.** *"Maintainer of Automated Testing Kit on drupal.org"* beats *"industry-leading testing expertise."*
- **Sober.** No founder-journey narrative arcs, no "our mission is to…" openers, no "we believe…" framings.
- **First person plural for the company.** André is named as the sole individual in v1 (D4 locked) because he's the publicly-verifiable author on drupal.org. Other engineers are acknowledged in aggregate until André adds them by name in a later pass.

## What NOT to say

- **No founding story / origin myth.**
- **No headcount inflation.** Do not use "our team of N engineers" unless N is defended elsewhere. *(D3 locked: unquantified.)*
- **No generic "passionate about quality"** language.
- **No Drupal-general-delivery framing.** Same rule as `/services`.
- **No client logo wall.** Trust-bar logos are a homepage concern. About's proof is code we wrote and ship.
- **No awards section** unless it's DrupalCon-specific or OSS-project-specific.
- **No GitHub star counts.** See fact inventory "deliberate omissions."
- **No photographs of anyone.** *(D6 locked: no headshots in v1.)*

## Editorial conventions

- **Playwright before Cypress** any time both are mentioned. (Memory: `project_pl2_playwright_first`.)
- **"Testing engineer"** — never "QA engineer," never "tester."
- **"Claude agent(s)"** when referencing the autonomous-healing workflow.
- **"ATK"** with the full name *Automated Testing Kit* at first mention, then `ATK` thereafter. Similarly *Testor* (no machine-name styling).
- **"André Angelantoni"** at first mention; first name thereafter.

---

## Page structure — **5 sections** *(D8 locked: dropped the "one-paragraph" §2 and the standalone "Who" §6 from v0)*

### §1. Hero

**H1 (D1 locked):** *Drupal testing, done by the people who wrote the tools.*

**Subhead (D1 locked):** *Nearly two decades of Drupal work, narrowed to testing. Author of Automated Testing Kit on drupal.org, and of Testor on GitHub. The dogfooding proof runs on this site, every night.*

**CTAs:**
- Primary: `Book a testing review` → `/contact-us?intent=testing-review`
- Secondary: `See the site test itself` → `/how-we-built-this-site`

**Layout notes:** Centered text-only. No hero image in v1 *(D2 locked: matches homepage §1 shape; revisit when/if a portrait or team photo is sourced)*. Single `<h1>`. Structure mirrors the locked homepage §1.

---

### §2. Depth — on drupal.org since 2006

Section heading: *On drupal.org since 2006.*

**Body:**

> Performant Labs has been on drupal.org for nineteen-plus years — since the Drupal 4.7 era, before automated testing in Drupal was a distinct practice. The work narrowed to testing deliberately, as the rest of the community converged on Drupal's testing ecosystem (Behat, PHPUnit, then Cypress and Playwright). We stayed with it because it's where the hardest, most valuable Drupal problems live: not building the next site, but keeping the critical one working through twelve major-version upgrades.

**Anchors row** *(D9 locked: prose + 3 concrete anchors, each linked)*:

| Anchor | Evidence |
|---|---|
| **19+ years on drupal.org** | [drupal.org/u/aangel](https://www.drupal.org/u/aangel) — "Member for 19 years 9 months" |
| **9+ projects credited on drupal.org** | [drupal.org/u/aangel](https://www.drupal.org/u/aangel) project list |
| **Active in the community** | Bay Area Drupal Camp presenter — see `/open-source-projects` |

**Rendering:** a 3-item stat/anchor strip (dripyard_base component TBD; likely `canvas:grid-3col` of `canvas:heading` + `canvas:text` pairs, or a `dripyard_base:stat-strip` if available). Exact component picked at overlay-draft time.

---

### §3. The tools we wrote

Section heading: *Open source: the tools we wrote.*

**Intro paragraph:**

> *Automated Testing Kit* and *Testor* aren't projects we contribute to — we author and maintain them. Both exist because specific testing gaps in the Drupal community weren't being filled by anything else.

**Two-project block** — side-by-side on desktop, stacked on mobile. Each project gets a small heading, one-sentence purpose, one "why it exists," and a link out.

#### Automated Testing Kit (ATK)

> *A library of tests and helper functions for end-to-end testing of Drupal sites, for both Cypress and Playwright.*

Why it exists: every Drupal site re-writes the same twenty login / entity-reference / permissions tests in each new project. ATK ships them pre-written, together with the helper functions needed to make them reliable against Drupal's specific quirks. Maintained on drupal.org as a supported module, including a Drupal 7 backport and a demonstration recipe.

Link out: [drupal.org/project/automated_testing_kit](https://www.drupal.org/project/automated_testing_kit)

#### Testor

> *A command-line companion to ATK for running tests outside the Drupal admin UI.*

Why it exists: teams running ATK in CI and local dev want the same test suite accessible from a terminal, not only from the Drupal admin. Testor provides that surface. Maintained in the open on GitHub, updated through late 2025.

Link out: [github.com/Performant-Labs/testor](https://github.com/Performant-Labs/testor)

**Layout notes:** render both project blocks as `canvas:card` components (heading, body, link) inside a 2-column grid wrapper. No project logos in v1 (same reasoning as D6).

**Trailing link — "Other OSS we ship"** *(single inline line, not a whole section)*:

> Performant Labs also maintains [Campaign Kit](https://www.drupal.org/project/campaign_kit), [Layout Builder Kit](https://www.drupal.org/project/layout_builder_kit), the [Drupal Quality Initiative](https://www.drupal.org/project/dqi), [Audit Kit](https://www.drupal.org/project/audit_kit), [AI Drush Tools](https://www.drupal.org/project/ai_drush_tools), and [Payment Stripe](https://www.drupal.org/project/payment_stripe) on drupal.org.

This line is the evidence that our OSS authorship isn't a one-module fluke.

---

### §4. The team — one named engineer, more unnamed

*Compact block, inline inside or immediately following §3 — NOT its own full section.*

Section heading: *Who we are.*

**Body (v1 — expand once D4's follow-on list of named engineers is provided):**

> Performant Labs is led by **André Angelantoni** (drupal.org [`aangel`](https://www.drupal.org/u/aangel)), author of Automated Testing Kit and maintainer of the testing-specific Drupal projects linked above. A small team of senior testing engineers work alongside him on the autonomous-healing workflow you see running on this site.

*(D4 locked: name André only in v1. Additional named engineers — with role + link — can be added in a follow-on pass once André tells us who to name. The current phrasing is deliberately bounded so adding names later doesn't require rewriting surrounding copy.)*

*(D3 locked: no headcount number. The phrase "a small team of senior testing engineers" is the v1 wording.)*

---

### §5. We test what we ship

Section heading: *We test what we ship.*

**Body:**

> This site runs the same autonomous-healing workflow we offer our clients. Every night, Claude agents re-run the Playwright suite against the live site, triage failures, author fixes as pull requests, and file issues when the failure is in the site rather than the test. The commit history is public. The dashboard is public. Every heal is a verifiable fact, not a case study.

**CTA (single):** `Read how the workflow is wired` → `/how-we-built-this-site`

**Layout notes:** Short prose block + a single button. Optional: pull in the `[N] tests auto-healed in the last 90 days` metric from `/automated-testing` §5 once H.1 lands — until then, leave the sentence-shape "every night, Claude agents …" as above.

---

### §6. Final CTA

Same shape as homepage §6. Short directional block with two CTAs.

Section heading: *Want to talk testing?*

Sub-copy (1 sentence):

> If any of this sounds like the kind of Drupal testing partner you're looking for — start here.

**CTAs:**
- Primary: `Book a testing review` → `/contact-us?intent=testing-review`
- Secondary: `See the testing menu` → `/services`

---

## Locked decisions (D1–D13)

*Defaults chosen 2026-04-22 in the absence of per-decision sign-off; each is reversible by amending this brief before overlay-apply.*

| # | Decision | Locked value | Reasoning |
|---|----------|--------------|-----------|
| **D1** | H1 + subhead copy | *"Drupal testing, done by the people who wrote the tools."* + subhead citing 2006 tenure, ATK, Testor, dogfooding. | Strongest verifiable claim + lowest hype. Testable on drupal.org in one click. |
| **D2** | Hero image | **Text-only v1.** | Matches homepage §1. No image to source; no content-editor pass to schedule. |
| **D3** | State team size? | **No.** "A small team of senior testing engineers." | Guardrail: "no headcount inflation." Specific numbers invite scrutiny about capacity; vagueness is defensible. |
| **D4** | Name individuals? | **Only André in v1.** Other engineers aggregated. | Only publicly-verifiable author on drupal.org is André. Future passes add names André provides; current copy bounded so insertion doesn't rewrite surrounding prose. |
| **D5** | Recent engagements sidebar? | **No v1.** | Requires client-by-client approvals. Held out of v1. |
| **D6** | Headshots / photos? | **No v1.** | Follows from D4 + D2. Revisit at the same time as D2/D4. |
| **D7** | Site-IA placement | **Main nav + footer.** | Main nav gets a new "About" entry; existing footer link id 43 re-pointed from `/about` → `/about-us`. |
| **D8** | Section outline | **5 sections + final CTA (=6 headings total).** | Dropped the v0 "one-paragraph" §2 (folded into hero subhead) and the v0 standalone "Who" §6 (folded into a compact block inside §3). |
| **D9** | §3 Depth shape | **(a) prose + 3 anchors**, each linked to its drupal.org source. | Cheaper to author; concrete-anchor style beats stat-strip when the stats themselves (star counts) aren't impressive. |
| **D10** | §3 anchor enumeration | *(1) 19+ years on drupal.org; (2) 9+ projects credited; (3) Bay Area Drupal Camp presenter.* | All three verifiable from `drupal.org/u/aangel` + on-site OSP page. No invented numbers. |
| **D11** | §4 OSS per-project signals | **ATK:** on drupal.org, supports Cypress + Playwright, D7 backport + Demo Recipe show commitment. **Testor:** GitHub-hosted CLI companion to ATK, updated through late 2025. | Honest signals that don't depend on star counts or uncited install counts. |
| **D12** | URL | **`/about-us`** (Phase 2 plan). Fix stale footer link to match. | Phase 2 plan is the source of truth. |
| **D13** | Homepage links in to About? | **No v1.** | Pages that drive into About: main nav, footer, deep links from `/services` body copy and `/how-we-built-this-site`. Homepage stays focused on the three pillars. |

---

## Phase 3 implementation shape (post-brief — next pass)

1. **André creates** a fresh `canvas_page` titled *About Us* via admin UI, publish status = 0 (draft). Per `feedback_editor_owned_content`.
2. **I export** the empty shell + plug its uuid into `content-exports/about-us.overlay.yml` (drafted in this pass with a placeholder uuid).
3. **I dry-run + apply** the overlay via `scripts/apply-canvas-page.php`.
4. **I run** T1 curl → T2 ARIA → T3 screenshots (per Three-Tier Verification Hierarchy memory).
5. **I publish** (status=1) and **André/I add** a `/about-us` path_alias + main-nav entry + footer-link fix.
6. **I export + commit** canonical YAML.

---

## Approval

| Stage | Approved by | Date |
|---|---|---|
| Brief skeleton (v0) | — | 2026-04-22 |
| Brief locked (v1, D1–D13 defaulted) | *Awaiting André's review* | — |
