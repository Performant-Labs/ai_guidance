# Automated Testing Brief — `/automated-testing`

*Phase 3 content brief. **v1 — 2026-04-22.** All open decisions (D0–D9) resolved and locked. Ready for canvas_page creation + overlay implementation.*

| Field | Value |
|---|---|
| Current entity | `node` id 7, type `page` — legacy title-only placeholder (no body, no image, no tags) |
| Target entity | New `canvas_page` (uuid assigned at creation) |
| Current path | `/automated-testing` (served by node/7) |
| Alias migration | Node/7 gets unpublished; `/automated-testing` alias is swapped to the new canvas_page |
| Phase 2 disposition | Rewrite — overridden 2026-04-22 to *"Drupal + AI specialization"* framing per user directive |
| Anchors | [Framework](../repositioning-framework.md) · [Phase 2 plan](../phase-2-page-plan.md) · [Homepage brief](./homepage.md) · [Services brief](./services.md) · [How we built this site brief](./how-we-built-this-site.md) · [Parking lot](../GET-BACK-TO-THESE.md) |
| Links in from | Primary nav (top-level item — requires IA change) · Homepage Pillar 2 (secondary link — requires homepage brief revision) · /services §2 *"Autonomous-healing pilot"* card body (future overlay once CTA-per-card lands) |

---

## Purpose

`/automated-testing` is the page a visitor lands on when the homepage's second pillar — *AI that heals your tests* — earned a click, or when the primary nav surfaced it directly. The reader arrives with exactly one question: *"what does it actually mean that their tests heal themselves, and how much of this is marketing?"*

This page answers that question in concrete enough detail that a buyer can decide whether the autonomous-healing pilot is a fit for their suite before scheduling a call. It is the **technical credibility page** for the AI pillar of Performant Labs' positioning. Everything else (the homepage Pillar 2 block, the /services *"Autonomous-healing pilot"* card, any future sales collateral) points here for the full story.

**What this page is NOT:** it is not the narrative walkthrough of how the site itself was built. That job stays with `/how-we-built-this-site` (D0 locked: Option B — two pages, not one).

## Audience

Same ICP as the homepage: organizations running business-critical Drupal sites. But the /automated-testing reader is either:

1. **Technical evaluator.** Often a lead engineer or test architect. Wants to see the actual workflow mechanics — what the agent reads, what it decides, what it's allowed to do, what it's *not* allowed to do. Will close the tab if the page reads as hand-wave.
2. **Technical buyer still scoping.** Got here from a homepage CTA. Needs enough concrete detail to either (a) proceed to a pilot conversation or (b) honestly rule it out for their suite before wasting a call.

Both read on the assumption that autonomous-healing is an unfamiliar-enough concept that they need to see it before they trust it. The page's job is to *show* it, not argue for it.

## Key messages (must land)

1. When a Drupal test breaks overnight, a Claude agent diagnoses the failure, classifies it as test-issue vs. website-issue, and takes a bounded action. No flake-triage backlog.
2. The workflow has **operating modes** — conservative in CI (test-only PRs, no site-code changes), aggressive locally (the engineer can let the agent fix site code too). The guardrail is explicit and in the repo.
3. The frameworks (Playwright, Cypress, ATK, Testor) are the substrate the AI runs on top of — not separate offerings. Every card on the toolkit section is in service of the autonomous-healing story.
4. This site is the first dogfooding target. The workflow file (`heal-tests-claude.yml`) is in a public repo. Anyone skeptical can read the code that decides what the AI is allowed to touch.

## Tone

Pragmatic-technical — homepage tone, dial +1 on concrete-code density. Think "engineering blog post that happens to sell a pilot." Specifics over adjectives; no AI-hype vocabulary ("revolutionary," "next-generation," "intelligent automation" as a noun). Where possible, show rather than tell: a workflow YAML excerpt, a one-line PR diff from a real healed test, a classification decision as quoted prose.

Affirmative framing only (D8 locked: no *"what this isn't"* block in the page copy). Guardrails live in the brief, not on the page.

## What NOT to say

- No "AI-powered testing" or "AI-driven QA" as a standalone claim. We sell *autonomous healing of a Drupal test suite*, which is specific and narrow.
- No general autonomous-coding framing. The agent is authorized to modify tests in CI and, locally, site code — it is NOT presented as a general-purpose Drupal development agent.
- No "intelligent" as an adjective for the agent. The agent is either right or wrong on a given classification; the reader should see the decision logic, not the marketing adjective.
- No benchmarks against other tools we don't own. We don't compare the agent to GitHub Copilot / Codex / Cursor / other commercial AI offerings. Lane stays *"autonomous healing of a Drupal test suite, wired to the frameworks our clients actually run."*
- No implication that the agent replaces a testing engineer. It replaces **flake triage**. The senior engineer is still the one who designs the test strategy, reviews the agent's PRs, and signs off on complex failures.
- No pricing.

## Editorial conventions

- **Playwright before Cypress** any time both are mentioned (memory: `project_pl2_playwright_first`).
- **"Claude agent(s)"** when referring to the autonomous worker — same convention as homepage and /services.
- **"Testing engineer"** — not "QA engineer," not "tester." Matches /services.
- **"Autonomous healing"** (the work the agent does) vs. **"the healing pilot"** (the engagement shape). Don't mix.
- **"heal-tests-claude.yml"** — always typeset inline with `<code>…</code>` when named.
- **"This site"** when referring to performantlabs.com as the dogfooding target. Never "our website" (too possessive, undercuts the dogfooding-proof framing).

---

## Page structure — 6 sections

### 1. Hero

- **H1:** *Autonomous test-healing for Drupal teams.* *(D0 locked: Option B — AI-healing hero; /how-we-built-this-site remains the narrative walkthrough.)*
- **Subhead:** *When a Playwright test breaks overnight, a Claude agent diagnoses the failure, classifies it as test-issue or website-issue, and — if it's a fix the agent is allowed to make — opens a pull request before anyone gets to their desk. The workflow is in our public repo.*
- **Primary CTA:** `Pilot autonomous healing on your suite` → `/contact-us?intent=healing-pilot`
- **Secondary CTA:** `Book a testing review` → `/contact-us?intent=testing-review`

**Layout notes:** Single `<h1>`. Text-only, centered, matching homepage §1 and /services §1 shape. No hero image in v1 — a Drupal-specific asset (workflow diagram or rendered agent-decision screenshot) is a follow-on (tracked as a sibling task to /services #59). Interim keeps the page tone technical-minimal.

### 2. What autonomous test-healing actually does

Four Drupal-specific vignettes showing the full decision tree: *test-side fix (auto-PR), test-side fix (coordinated config rename), site-side (human-escalated), transient (no action)*. Rendered as a 4-card grid (`sdc.dripyard_base.card-canvas`, same component used on /services §2 for structural parity).

- **Section heading:** *Four things that happen when a test fails.*
- **Subhead:** *The agent doesn't "fix your tests." It reads the failure, decides what kind of failure it is, and takes the action its operating mode allows. Sometimes that's a PR. Sometimes it's an issue with a diagnosis. Sometimes it's nothing.*

**4 cards:**

| # | Title | Body |
|---|---|---|
| 1 | **A contrib module renames a class.** | *A module update ships a CSS-class rename. Your ATK smoke test fails overnight on a `.field-name-field-foo` selector that's now `.field-foo`. The agent reads the stack trace, checks the rendered DOM, classifies as test-fix, opens a PR updating the selector, labels it `test-fix`. Green by morning.* |
| 2 | **A Views block label changes.** | *Someone renames "Latest articles" to "Recent articles" in the Views UI and commits the config export. Your Playwright assertion on `getByRole('heading', { name: 'Latest articles' })` fails. The agent reads the config diff, sees the coordinated rename, updates the assertion, opens a PR. Not a site bug — a config update the test hadn't caught up to.* |
| 3 | **The site is actually broken.** | *A recent commit to a custom module nulls out a form field on edit. The test correctly fails. The agent diagnoses it as a website-side issue, files an issue with the stack trace + hypothesis + suggested fix, and tags the last commit's author. No PR. No auto-merge. A human decides.* |
| 4 | **It's just flake.** | *One nightly run, a test fails on a transient network blip against Pantheon. The agent retries, the test passes, the agent classifies as transient, closes the investigation. No PR. No issue. No noise. One line in the run log.* |

**Layout notes:** Cards preserve `card-canvas` shape; no per-card CTAs. Per-card `?intent=…` routing deferred — same call as /services §2 (D7 of services brief).

### 3. How the Claude agents workflow fits in CI

The "show the code" section. Mixed prose + an inline excerpt from `heal-tests-claude.yml`. Establishes that the guardrails are explicit, in the repo, and readable. (D6 locked: include code snippets.)

- **Heading:** *The guardrails are in the repo.*
- **Opening prose:** *Every night, Playwright tests run against this site in CI. When one fails, a GitHub Action invokes a Claude agent with the failure artifacts and the constraints it's allowed to operate under. Here's the top of `heal-tests-claude.yml` — the file that decides what the AI is permitted to touch:*
- **Code block (inline, styled `<pre><code>…</code></pre>`):**
  ```yaml
  # Only fix test code in CI. Site-code changes require a human.
  operating_mode: ci
  permissions:
    modify_test_code: true       # selectors, assertions, waits
    modify_site_code: false      # PHP, Twig, JS, CSS — never in CI
    open_pull_request: true
    auto_merge: false            # a human reviews every PR
  classification:
    test_issue:   [selector_outdated, assertion_outdated, timing, url_change]
    website_issue:[element_missing, server_error, broken_form, empty_content]
  ```
- **Follow-on prose:** *Locally, the same agent runs with `operating_mode: local` — the engineer at the terminal can let it fix site code too, because changes can be verified against a running DDEV instance before commit. The mode is explicit. The permission flags are explicit. Nothing is implicit.*
- **CTA:** `Read the full workflow on GitHub →` (bare-style button) → `https://github.com/Performant-Labs/pl-performantlabs.com/blob/main/.github/workflows/heal-tests-claude.yml`

**Layout notes:** Code block uses `sdc.dripyard_base.text` with rich HTML (the `<code>` tag allow-list landed in commit `37` on this repo — memory `project_pl2_canvas_content_flow`-adjacent; verify before overlay that `<pre><code>` survives the canvas_html_block filter). If it doesn't, fall back to an image of the code (screenshot) + a prose paraphrase.

### 4. The toolkit we run AI on top of

Framework/tool inventory — subordinate to the AI story (D5 locked). Each tool's card reads as "and here's where the agent wires in." Not a features catalogue.

- **Section heading:** *The toolkit we run AI on top of.*
- **Subhead:** *The agent isn't a testing framework. It's a layer that sits on top of the frameworks your team already runs — or should be running.*

**4 cards:**

| # | Title | Body |
|---|---|---|
| 1 | **Playwright.** | *The primary framework we write and maintain tests in. Every healing vignette above plays out against a Playwright suite. If you're already on Playwright, the agent wires in on day one.* |
| 2 | **Cypress.** | *Legacy-supported. If your suite is Cypress, the agent reads failure output and opens PRs the same way — fewer success cases than Playwright today, but the classification logic is framework-agnostic.* |
| 3 | **ATK — Automated Testing Kit.** | *Our open-source Drupal-specific test toolkit (Playwright-first, Cypress-supported). The selector patterns in the vignettes above come from ATK. It's on the site's `/open-source-projects` page and in the public repo.* |
| 4 | **Testor.** | *The Drupal module that wires test-run reporting into the site's admin UI — because "the tests are green" is more useful when a content editor can see it without opening GitHub Actions.* |

**Layout notes:** Same `card-canvas` shape as §2. No per-card CTAs (the `/open-source-projects` page is where ATK/Testor link to); page-level secondary CTA in §6 covers it if a reader wants to dive.

### 5. See it running on this site

Pointer to `/how-we-built-this-site`, a healed-test diff snippet, and the dogfooding metric (TBD placeholder — see H.1 in the parking lot).

- **Heading:** *This site is the first dogfood.*
- **Body paragraph 1:** *Every night, Playwright tests run against the very site you're reading. When a test breaks, the workflow above fires. For the full narrative — architecture choices, rasterization strategy, mobile-spacing reconciliation, and every other decision that shaped this site — read <a href="/how-we-built-this-site">how we built this site</a>.*
- **Body paragraph 2 (healed-test diff, styled `<pre><code>`):**
  ```diff
  -  await expect(page.getByRole('heading', { name: 'Latest articles' })).toBeVisible();
  +  await expect(page.getByRole('heading', { name: 'Recent articles' })).toBeVisible();
  ```
  *One of the commits the agent opened on this repo. A config-rename ripple — Views UI changed the block label; the Playwright assertion had to catch up. The agent read the failure output, read the `views.view.*.yml` diff, decided it was a coordinated rename, and shipped the PR. Closed the loop in about eleven minutes, start to merge.*
- **Body paragraph 3 (metric sentence — placeholder):** *Over the last 90 days, **[N]** tests have been auto-healed on this site without human intervention.* *(**§5 metric is TBD** — see section H.1 in [GET-BACK-TO-THESE.md](../GET-BACK-TO-THESE.md) for sourcing options. The brief ships the sentence-shape; only the number is pending.)*
- **CTA:** `Read the full story →` (bare-style button) → `/how-we-built-this-site`

**Layout notes:** `<pre><code>` allow-list verification same as §3. If it doesn't survive the filter, substitute a PNG screenshot + `<figcaption>`. The metric placeholder renders as `<strong>[N]</strong>` literal — overlay emits the token; a future editorial pass swaps in the number when the parking-lot item lands.

### 6. Final CTA

- **Heading:** *Ready to let your tests heal themselves?*
- **Body:** *A pilot on a slice of your existing suite is the fastest way to see whether this approach fits your team. We scope to about ten tests, run the workflow against your fixtures for two weeks, and leave you with a written read on how it behaved — including every PR it opened and every issue it escalated.*
- **Primary CTA:** `Start a healing pilot` → `/contact-us?intent=healing-pilot`
- **Optional micro-CTA:** *Or start with a testing review →* `/contact-us?intent=testing-review`

**Layout notes:** `title-cta` composite component, same pattern as homepage §6 and /services §6 — structural parity across all three terminal CTAs.

---

## Conversion path

| Goal | CTA | Target | Intent |
|---|---|---|---|
| Primary conversion | Start a healing pilot | `/contact-us?intent=healing-pilot` | Scoped pilot on ~10 tests, two weeks, written readout |
| Secondary conversion | Book a testing review | `/contact-us?intent=testing-review` | 30-min senior-engineer consult, no obligation |
| Read-more (dogfooding) | See how we built this site | `/how-we-built-this-site` | Self-qualify / educate |
| Read-more (workflow source) | Read the full workflow on GitHub | public repo link | Technical evaluator verifying guardrails |

`?intent=…` query params follow services brief D7 — pages emit them now, `/contact-us` form handles them in a future brief.

## Success criteria

- A technical evaluator who read the homepage's AI pillar leaves /automated-testing with a clear enough mental model of the agent's operating modes, classification logic, and guardrails that they can defend or object to the approach on technical merit in their next internal meeting.
- A buyer arriving from the homepage CTA can decide between *"yes, scope a pilot"* and *"no, not for us"* without a call. Both are fair outcomes; wasting a call is worse than losing a prospect.
- The workflow YAML excerpt + the healed-test diff + the `/how-we-built-this-site` link collectively function as proof-by-artifact. A reader who didn't believe autonomous-healing was real should leave the page less skeptical.
- Zero hype phrases render on the page.

## Dependencies

- **IA change: primary nav addition.** /automated-testing needs to be a top-level item in the primary nav (D3 locked). Coordinate with the Phase 3 IA decision — not yet made. The brief is authored on the assumption that this lands; if it doesn't, /automated-testing is discoverable only from the homepage, which would weaken Pillar 2's reach.
- **Homepage brief revision: Pillar 2 secondary link.** The homepage Pillar 2 block (currently links to `/how-we-built-this-site`) needs a secondary link added to `/automated-testing`. Handled in a minor revision to the homepage brief + a follow-on overlay against the homepage canvas_page.
- **/cypress-on-drupal retirement.** Phase 2 disposition for `/cypress-on-drupal` is reversed per user directive 2026-04-22 (*"Ignore /cypress-on-drupal; we aren't going to publish that"*). Default 301 target: `/automated-testing`. Coordinate with the redirect pass when /cypress-on-drupal is formally retired.
- **`<code>` / `<pre>` filter allow-list.** §3 and §5 render inline code via `canvas_html_block`. Verify the allow-list lets `<pre>` and `<code>` through before overlay; fall back to screenshot images if not. (Commit `37` on this repo enabled `<code>` — verify `<pre>` is also permitted, add to the allow-list if not.)
- **`/how-we-built-this-site` content status.** §5's body points at this page. If it's still mid-rewrite when /automated-testing lands, the link will go to a stale page. Same dependency shape as homepage §4 and /services §4.
- **§5 metric TBD.** Tracked as [H.1 in the parking lot](../GET-BACK-TO-THESE.md). The page is shippable with `[N]` literal; going live externally requires the metric to land or the sentence to be rewritten.

## Out of scope

- **Rewriting `/how-we-built-this-site`** — D0 locked as two pages, not one. That page has its own brief and lifecycle.
- **Case studies.** D7 locked: skip. The metric sentence in §5 is the only quantitative proof on the page.
- **A standalone `/cypress-on-drupal` page.** Not publishing (user directive 2026-04-22).
- **General-purpose Drupal-dev-agent positioning.** The agent sold on this page is scoped to *autonomous healing of a test suite*. Any broader agent work is a separate page, not a section on this one.
- **Pricing.**
- **Benchmark comparisons** against GitHub Copilot, Cursor, Codex, or any other commercial AI-coding tool.
- **Per-card CTA intent params** beyond the three listed in the Conversion path table — deferred, same call as /services brief D7.

---

## Locked decisions log

| ID | Decision | Locked value | Date |
|---|---|---|---|
| D0 | One page or two (vs. /how-we-built-this-site) | **Option B — two pages.** /automated-testing is the technical credibility page; /how-we-built-this-site remains the narrative walkthrough | 2026-04-22 |
| D1 | Target entity | **New canvas_page** + alias swap from node/7 (node/7 unpublished, not deleted) | 2026-04-22 |
| D2 | Hero CTAs | Primary *"Pilot autonomous healing on your suite"* → `/contact-us?intent=healing-pilot`; Secondary *"Book a testing review"* → `/contact-us?intent=testing-review` | 2026-04-22 |
| D3 | Inbound links | Primary nav top-level + homepage Pillar 2 secondary link | 2026-04-22 |
| D4 | Section count | **6** sections | 2026-04-22 |
| D5 | Framework/tool block framing | **Subordinate to AI** — Playwright / Cypress / ATK / Testor positioned as *"the toolkit we run AI on top of"*, not a separate offerings list | 2026-04-22 |
| D6 | Code snippets | **Include** — inline workflow YAML excerpt (§3) + healed-test diff (§5) | 2026-04-22 |
| D7 | Case studies | **Skip** — include one dogfooding metric if available, otherwise ship with TBD placeholder (see D10) | 2026-04-22 |
| D8 | *"What we're not"* block in page copy | **Omit** — affirmative positioning only; guardrails live in this brief, not on the page | 2026-04-22 |
| D9 | Technical dial relative to homepage | **+1** — more inline code, more concrete tool names, more specifics | 2026-04-22 |
| D10 | §5 autonomous-healing metric | **TBD placeholder** — brief ships `[N]` literal; tracked as H.1 in [GET-BACK-TO-THESE.md](../GET-BACK-TO-THESE.md). Page is shippable internally with placeholder; external launch requires metric or sentence rewrite | 2026-04-22 |

## Approval

| Stage | Status | Date |
|---|---|---|
| v1 — all D0–D10 resolved | Pending André Angelantoni review | 2026-04-22 |
