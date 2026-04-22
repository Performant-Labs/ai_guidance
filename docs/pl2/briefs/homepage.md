# Homepage Brief — `/`

*Phase 3 content brief. Approved 2026-04-21 by André Angelantoni.*

| Field | Value |
|---|---|
| Node ID | 38 |
| Current path | `/` (resolves via `system.site` config → `/node/38`) |
| Content type | `landing_page` |
| Phase 2 disposition | Rewrite (homepage) |
| Anchors | [Framework](../repositioning-framework.md) · [Phase 2 plan](../phase-2-page-plan.md) |

---

## Purpose

The homepage must carry the full repositioning in one scroll: a Drupal team arriving cold should understand — in under 30 seconds — that Performant Labs tests Drupal sites, authored the tooling the ecosystem runs on (ATK, Testor), extends it with AI that heals broken tests on its own, and will embed senior testing engineers alongside their team when asked. The primary conversion is **booking a testing review**.

## Audience

Primary ICP (common-denominator hero): organizations running business-critical Drupal sites who need release confidence without standing up their own testing org. Spans agency COOs, enterprise engineering directors, agency principals, and government/public-sector procurement. Page must read credibly to all four.

## Key messages (must land)

1. We test Drupal — specifically, not as a generalist.
2. We wrote the tools the Drupal community uses (ATK, Testor).
3. Our AI heals broken tests on its own, in CI, running right now on this site.
4. We embed senior testing engineers alongside your team when you need them.
5. This isn't a pitch — it's shipped.

## Tone

*Pragmatic.* No hype. No "revolutionary AI." Every sentence must pass the jaded-engineer eye-roll test. Specifics over adjectives.

## What NOT to say

- Nothing about building sites; we are **not** a Drupal build shop.
- Nothing implying "AI solves everything" or generic hype language.
- No mentions of cheap/offshore/body-shop framing, even when describing nearshore staff augmentation.
- No generic Drupal evangelism ("Why Drupal?") — the reader already chose Drupal.

## Editorial conventions

- **Playwright before Cypress** any time both are mentioned.
- **Frameworks explicit:** "Playwright" (not "our testing framework").
- **Attribution explicit:** "Claude agents" not "our AI" when referring to the healing workflow — anthropic is fine to name.

---

## Page structure — 6 sections

### 1. Hero

- **H1:** Ship Drupal releases with confidence.
- **Subhead:** *Performant Labs built the Drupal testing stack the ecosystem already uses (ATK, Testor), extended it with AI workflows that heal broken tests on their own, and — when you need it — embeds senior testing engineers alongside your team.*
- **Primary CTA:** `Book a testing review` → `/contact-us?intent=testing-review`
- **Secondary CTA:** `See how we test this site` → `/how-we-built-this-site`

**Layout notes:** Hero should be the full above-the-fold real estate on desktop. Keep the subhead intact — no cutting. Both CTAs visible without scrolling.

### 2. Trust bar

- **No copy change from current site.** Keep existing client logos: CBS Interactive, Orange, DocuSign, Robert Half, Tesla, Goldman Environmental Prize, Renesas.
- **Optional overline:** *Teams we've tested with* (small, caps, above the logo strip).

### 3. Three pillars

Three equal-weight cards. Order matters: tools → AI → people (matches the positioning statement's three elements).

**Pillar 1 — Tools the Drupal community uses**
ATK (Automated Testing Kit) and Testor are ours. Open source, actively maintained, adopted across the ecosystem. Download them, read the source, ask questions.
*Link:* `Explore the tools →` `/open-source-projects`

**Pillar 2 — Tests that heal themselves**
AI agents diagnose and fix broken Playwright tests in CI — nightly, on this very site. Not a demo. A shipped workflow, running right now.
*Link:* `See it in action →` `/how-we-built-this-site`

**Pillar 3 — Experts alongside your team**
When you need hands, we embed senior testing engineers. North American project leads, nearshore delivery options. Fully billable or fractional.
*Link:* `How we engage →` `/services`

### 4. Dogfooding proof block

- **Heading:** We heal our own tests nightly.
- **Body:** *Every night, Playwright tests run against this site in CI. When a test breaks, a Claude agent diagnoses the failure, classifies it (test issue or website issue), and — when appropriate — opens a pull request with the fix. No Monday-morning flake triage. No staging calls with a QA engineer. The workflow is in our public repo; you can read the code that decides what our AI is allowed to touch.*
- **Inline credibility link:** *See the workflow →* (link to `heal-tests-claude.yml` in the public GitHub repo).
- **Section CTA:** `Read the full story →` `/how-we-built-this-site`

**Layout notes:** Give this block real breathing room — this is where the positioning earns its keep. Consider a code-font card showing either the workflow filename or a one-liner from a recent autonomous-fix commit ("Fixed selector in `login.spec.ts`"). The snippet is the proof.

### 5. Selected engagements (case studies strip)

- **Heading:** Selected engagements.
- **Layout:** 3-card horizontal strip. Cards are **self-contained** (no per-card link-out; no `/case-studies` index page).
- **Card template:**
  - Client name (with or without logo mark)
  - One-sentence problem (what was broken before us)
  - One-sentence outcome **with a concrete number**

**Shape-only examples — not final copy. Copy to be written from André's raw notes.**

> **CBS Interactive · media**
> Flaky tests were blocking nightly deploys across a 40-repo monorepo.
> Autonomous healing resolved 80% of night-before failures without human intervention.

> **Tesla · automotive**
> A Drupal theme migration put the regression suite at 100% failure rate.
> Migrated to Playwright + ATK; suite green in 4 weeks.

> **Goldman Environmental Prize · nonprofit**
> Testing budget was zero; in-house team had no QA specialist.
> Zero-setup ATK install with 30-minute team onboarding.

**Dependency:** 2–3 real case studies must be written from André's raw notes before this section ships with real content. Homepage can launch with the trust bar (section 2) alone if this section isn't ready.

### 6. Final CTA

- **Heading:** Ready for a release you don't have to babysit?
- **Body:** *Book a 30-minute testing review with a senior engineer. We'll look at your current workflow, tell you honestly where autonomous healing would (and wouldn't) help, and leave you with a one-page writeup. No sales pitch. No obligation.*
- **Primary CTA:** `Book a testing review` → `/contact-us?intent=testing-review`
- **Optional micro-CTA (soft, below primary):** *Or start with the tools →* `/open-source-projects`

---

## Conversion path

| Goal | CTA | Target | Intent |
|---|---|---|---|
| Primary conversion | Book a testing review | `/contact-us?intent=testing-review` | Senior-engineer consult, 30 min, no obligation |
| Secondary conversion | See how we test this site | `/how-we-built-this-site` | Educate + self-qualify |
| Tertiary (lead magnet) | Explore the tools | `/open-source-projects` | ATK/Testor download → long-loop conversion |

## Success criteria

- A cold Drupal team engineer can read the hero + subhead and explain what Performant Labs does in their own words.
- The dogfooding proof block is credible without clicking the GitHub link (the prose alone convinces).
- A skeptical buyer hunting for a "we do everything" vendor finds our scope boundaries (Drupal-first, testing-specific, not a build shop) obvious by the end of the page.
- The "Book a testing review" CTA is visible without scrolling past the hero, AND repeated at the bottom.

## Dependencies

- **Case-study content** (2–3 write-ups from raw notes) — tracked as a sub-task. Section 5 ships thin without this.
- **CTA target `/contact-us?intent=testing-review`** needs either a contact form variant or a query-param handler that surfaces a "Book a testing review" lead type. Coordinate with `/contact-us` brief.
- **`/how-we-built-this-site` rewrite** is the landing page for two of the three CTAs (hero secondary + section 4). It has to be written in parallel with the homepage, not after.
- **Public `heal-tests-claude.yml` URL** — the homepage's inline credibility link goes directly to the workflow file on GitHub. The repo must remain public; if it goes private, this link and the surrounding dogfooding claim weaken.

## Out of scope

- **`/case-studies` index page** — explicitly dropped. Case-study content lives on the homepage strip, not in a separate section of the site.
- **"Recent Articles" strip** — removed. Blog is de-emphasized per Phase 2 decision C (articles become a curated `/insights` archive, not a homepage feed).
- **Detailed methodology / services breakdown** — lives on `/services` and `/how-we-do-it`, not the homepage.

---

## Approval

| Stage | Approved by | Date |
|---|---|---|
| Homepage brief (6 sections) | André Angelantoni | 2026-04-21 |

**Next brief suggestions, in dependency order:**
1. **`/how-we-built-this-site`** — linked from two homepage CTAs; ship these together.
2. **`/services`** — linked from Pillar 3; carries the nearshore sub-section folded in from retired `/nearshoring`.
3. **`/automated-testing`** — hero-status page; expansion of Pillar 2's autonomous-healing story.
