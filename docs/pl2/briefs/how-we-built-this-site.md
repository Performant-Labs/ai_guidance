# /how-we-built-this-site Brief

*Phase 3 content brief. Approved 2026-04-21 by André Angelantoni.*

| Field | Value |
|---|---|
| Node ID | 76 |
| Current path | `/how-we-built-this-site` |
| Content type | `landing_page` |
| Phase 2 disposition | Rewrite (proof asset — load-bearing) |
| Anchors | [Framework](../repositioning-framework.md) · [Phase 2 plan](../phase-2-page-plan.md) · [Homepage brief](./homepage.md) |

---

## Purpose

This page is the dogfooding proof behind the homepage's "we heal our own tests nightly" claim. A skeptical Drupal engineer who clicks the homepage's *See how we test this site* CTA should arrive here and — within one scroll — conclude that the autonomous-healing story is real, specific, reviewable, and disciplined. Every claim must link to something a reader can verify in under 30 seconds.

The page is **not** marketing. It is a technical proof asset. It must read as if written by an engineer for an engineer.

## Audience

Pre-qualified technical reader. Arrived here from the homepage (either the hero secondary CTA or the Section 4 proof block). Likely a Drupal tech lead, engineering manager, SRE, or agency senior engineer. They are not asking "what does this company do"; they are asking "is this real?"

## Key messages (must land)

1. The workflow is public, committed, and auditable — not a demo.
2. The guardrails are written down in a committed file (`CLAUDE.md`), not a hidden prompt.
3. The architecture is disciplined: two workflows, explicit classification, human reviews every PR.
4. The pragmatic tone is earned — we name the limits up front.
5. If you want to see it running on your own site, a senior engineer will do a 30-minute review. No sales pitch.

## Tone

*Pragmatic, technical, exacting.* This is the most technically forward-leaning page on the site. A jaded SRE should read it and think "yeah, that tracks." Specifics, file names, SHAs, quoted rules. No hand-waving. If a claim can be linked to code, link it.

## What NOT to say

- Nothing about "AI magic," "revolutionary," "the future of testing."
- No claims the workflow authors new tests or catches semantically-wrong-but-passing tests. (It doesn't; don't overreach.)
- No metric claims ("80% reduction in X") unless backed by a named case study.
- No mention of proprietary / black-box model behavior. We name the model version and what it's allowed to do.
- No branding of the workflow as a product we sell. It's a workflow we run, in the open, for one specific purpose.

## Editorial conventions

- **Playwright before Cypress** any time both are mentioned (per [project editorial rule](../../../.auto-memory/project_pl2_playwright_first.md)).
- **Claude agents** (not "our AI") when attributing the healing work. Anthropic + Claude Sonnet are named explicitly.
- **File paths in backticks.** Links to GitHub where linkable.
- **Quote rules verbatim** from `CLAUDE.md` rather than paraphrasing.

---

## Page structure — 6 sections

Target total length: 800–1200 words.

### 1. Hero

- **H1:** How we test this site.
- **Subhead:** *Every night, Playwright tests run against performantlabs.com. When a test breaks, a Claude agent diagnoses the failure, classifies it, and — when appropriate — opens a pull request with the fix. This page links to the code that decides what it's allowed to touch.*

**Layout notes:** No imagery. A code-font subhead works if the theme supports it; otherwise standard serif/sans subhead. No CTA in the hero — the reader is already committed by virtue of being here.

### 2. The stack

Heading: **The stack.**

Intro line: *Nothing exotic. Every choice is justified by something concrete.*

| Layer | Choice | Why |
|---|---|---|
| CMS | Drupal 11 (Canvas module v1.3.2) | Recent migration from D10; Canvas is our Layout Builder / theming stack. |
| Hosting | Pantheon (dev → test → live) | Multidev branches map 1:1 to PR branches. |
| E2E tests | Playwright (primary), Cypress (legacy support) | Playwright is where autonomous healing lives; Cypress suites still run. |
| Test toolkit | ATK (our own open-source Drupal testing kit) | We maintain it; using it here is dogfooding. |
| CI | GitHub Actions, nightly cron | `heal-tests-claude.yml` orchestrates the healer; `test-against-pantheon.yml` orchestrates the run. |
| Reporting | CTRF JSON + Playwright HTML report | Structured failure data is what Claude reads. |
| AI | Claude (Sonnet) via Anthropic API | Operating under a `CLAUDE.md` ruleset committed to the repo. |

### 3. The nightly workflow

Heading: **The nightly workflow.**

Body:

> It's two workflows, not one. The first runs the tests; the second heals them.
>
> **Workflow 1 — the tester** (`test-against-pantheon.yml`). Every night at 23:57 UTC:
>
> 1. Playwright runs the full suite against `https://live-performant-labs.pantheonsite.io`, sharded across parallel runners for speed.
> 2. Results merge into `ctrf/ctrf-report.json` — structured JSON describing every pass, fail, and flake.
> 3. If anything failed, `ai-ctrf claude` enriches the CTRF with per-failure summaries (model: `claude-sonnet-4-20250514`).
> 4. A GitHub issue is opened — or reused if one is already open — with the label `auto-heal`.
>
> **Workflow 2 — the healer** (`heal-tests-claude.yml`). On each new `auto-heal` issue:
>
> 5. Claude checks out the repo, reads `CLAUDE.md`, and identifies the failing test file(s) from the issue body.
> 6. It classifies each failure: **test issue** or **website issue**.
> 7. **Test issue** → Claude fixes the test on a branch named `claude/issue-N`; a subsequent step opens a PR automatically.
> 8. **Website issue** → Claude posts its analysis as an issue comment. No code changes.
>
> A small detail that matters: the healer fires on `issues: [opened]`, *not* `[labeled]`. Multiple labels would otherwise trigger multiple duplicate runs.

Inline links:
- `test-against-pantheon.yml` → `https://github.com/Performant-Labs/performantlabs.com/blob/main/.github/workflows/test-against-pantheon.yml`
- `heal-tests-claude.yml` → `https://github.com/Performant-Labs/performantlabs.com/blob/main/.github/workflows/heal-tests-claude.yml`

### 4. Where Claude is allowed to touch

Heading: **Where Claude is allowed to touch.**

Body:

> The guardrails live in a committed file: [`CLAUDE.md`]. It's not a prompt buried in a secret. It's in the repo, reviewable like any other code.
>
> The load-bearing rule is the **two-mode split**:
>
> > **CI mode** (default in GitHub Actions) — conservative. Only fix test code. Never modify website source.
> >
> > **Local mode** (when running `claude` on a developer's machine) — aggressive. Fix whatever is broken, test *or* website.
>
> The reasoning is in the file itself: the CI runner cannot deploy code changes to Pantheon, so fixing website code from CI would be pointless. Test-only PRs are safe to review and merge.
>
> A few other guardrails worth naming:
>
> - **Tool allowlist** in the workflow: Claude can run `npx`, `npm`, `git`, and a handful of read-only shell commands. It cannot `curl`, `wget`, or touch arbitrary binaries.
> - **25-turn cap.** No runaway sessions.
> - **10-minute hard timeout.** If a fix isn't obvious in 10 minutes, the run dies and a human picks it up.
> - **Classification framework** in `CLAUDE.md` tells Claude how to decide "test issue vs website issue" — selector mismatches and stale assertions go in the test-fix bucket; missing elements, broken forms, and 500s go in the website-fix bucket and get a comment, not a PR.
>
> None of this is clever. All of it is written down.

Inline links:
- `CLAUDE.md` → `https://github.com/Performant-Labs/performantlabs.com/blob/main/CLAUDE.md`

### 5. A real healing session

Heading: **A real healing session.**

Body:

> Here's one from this February. Issue #231 landed overnight: Playwright had failed on the Contact Us smoke test. The error: timeout waiting for a link with accessible name `"COTACT US"`.
>
> Claude read `CLAUDE.md`, opened the failing test file, and made the classification:
>
> > **TEST issue** — The selector text is "COTACT US" (missing the second 'N'). The site's navigation correctly says "CONTACT US". The test's selector is a typo.
>
> It fixed the one-line typo and committed to a `claude/issue-231` branch:
>
> ```diff
> -    await page.getByRole('link', { name: 'COTACT US' }).first().click()
> +    await page.getByRole('link', { name: 'CONTACT US' }).first().click()
> ```
>
> (From `tests/atk_contact_us/atk_contact_us.spec.js`.)
>
> A human reviewed the PR, confirmed the diff matched the classification, and merged. Commit [`1d0741170f`]. No calls. No flake dashboards. No "investigate this next sprint." The whole loop — failure → issue → classification → PR → merge — closed before Monday's standup.
>
> If the typo had been on the *website* side instead of the test side (say, the navigation itself said "COTACT US"), the classification would have been **website issue**: Claude would have posted its analysis as a comment on the issue and declined to touch any code. That's not a limitation to work around. That's the contract.

Inline links:
- Issue #231 → `https://github.com/Performant-Labs/performantlabs.com/issues/231`
- Commit `1d0741170f` → `https://github.com/Performant-Labs/performantlabs.com/commit/1d0741170f5cbc71090dfaa331f0e2f85e4a511b`

### 6. Honest limits + CTA

Heading: **Honest limits.**

Body:

> A few things to know:
>
> - **The workflow heals; it doesn't author.** Claude doesn't write new tests. It fixes ones that already exist.
> - **It can't find what's not broken.** A test that passes while checking the wrong thing will never trigger a heal.
> - **Truly flaky tests don't reproduce reliably.** If a failure doesn't recur on re-run, Claude documents that and moves on.
> - **Every PR is reviewed by a human.** The classification is Claude's. The merge is not.
>
> This isn't magic. It's a workflow, a ruleset, and a human in the loop. The things we've gotten back are Monday mornings, and the calendar time of a senior engineer we no longer spend on flake triage.

Second heading: **Want this running on your site?**

Body:

> If you have a Drupal site with a Playwright suite and nightly CI — or want to get there — we run a 30-minute review. We'll look at your current workflow, tell you honestly where autonomous healing would (and wouldn't) help, and leave you with a one-page writeup.
>
> No sales pitch. No obligation.

- **Primary CTA:** `Book a testing review` → `/contact-us?intent=testing-review`

*Or, if you'd rather start with the code:*

- [ATK on GitHub] → `https://github.com/Performant-Labs/automated_testing_kit` *(verify canonical URL in Phase 3 asset-check)*
- [`heal-tests-claude.yml`] → (same GitHub link as Section 3)
- [`CLAUDE.md`] → (same GitHub link as Section 4)

---

## Conversion path

| Goal | CTA | Target | Intent |
|---|---|---|---|
| Primary conversion | Book a testing review | `/contact-us?intent=testing-review` | Senior-engineer consult, 30 min, no obligation |
| Secondary (self-serve) | ATK on GitHub | ATK repo on GitHub | Download, fork, try it yourself |
| Tertiary (inspect) | `heal-tests-claude.yml` / `CLAUDE.md` | Public repo files | Read the actual code; long-loop trust building |

## Success criteria

- A skeptical engineer can read the page end-to-end and explain to a colleague what the workflow does and what its limits are.
- Every concrete claim on the page resolves to something the reader can verify by clicking (workflow file, `CLAUDE.md`, issue #231, commit SHA).
- The "Honest limits" block leaves the reader feeling the page *under*-promised rather than over-promised.
- A reader who reaches the CTA and doesn't click it can still cite the page as evidence of our technical discipline.
- Total length stays in the 800–1200 word band. If the page exceeds 1300 words in draft, cut; don't paginate.

## Dependencies

- **Public repo.** `Performant-Labs/performantlabs.com` must remain public. If it goes private, the page collapses — nearly every load-bearing link is to a file in that repo.
- **`heal-tests-claude.yml`, `test-against-pantheon.yml`, `CLAUDE.md`** must remain at their current paths. Moving or renaming any of them breaks this page's hyperlinks.
- **Issue #231 and commit `1d0741170f`** must remain accessible. If the repo is ever re-inited or these refs are force-pushed out, Section 5's named example is broken. If this happens, pick a different real healing session and rewrite Section 5 accordingly. (Alternative sessions are plentiful — see `git log --author=claude[bot]`.)
- **Model-version drift.** The page names `claude-sonnet-4-20250514`. If the workflow is updated to a newer model, update Section 3 to match. Review trigger: any PR touching `.github/workflows/heal-tests-claude.yml` or `test-against-pantheon.yml`.
- **`/contact-us?intent=testing-review`** — shared dependency with the homepage brief. Needs either a contact form variant or a query-param handler that surfaces a "Book a testing review" lead type.
- **ATK canonical GitHub URL** — verify the `Performant-Labs/automated_testing_kit` slug is correct before going live (the current placeholder is a best guess; `/open-source-projects` brief will carry the authoritative value).

## Out of scope

- **Full tutorial on setting up the workflow yourself.** The page points to the code; it does not teach. A "how to set this up on your site" walkthrough, if written, lives in a separate `/insights` post, not here.
- **Vendor comparison tables** against Mabl, Testim, Autify, etc. The framework positions us against those in sales, not on this page.
- **Unbacked metric claims** ("X% reduction in flake triage time"). If and when a case study quantifies this, it goes on the homepage strip or a `/case-studies` asset, not interpolated into this page.
- **Architecture diagram.** Explicitly considered and dropped — the two-workflow prose narrative in Section 3 is tight enough that a diagram would add length without adding clarity.

---

## Approval

| Stage | Approved by | Date |
|---|---|---|
| /how-we-built-this-site brief (6 sections) | André Angelantoni | 2026-04-21 |

**Section-level approvals (all 2026-04-21):** hero + H1 / stack table / nightly-workflow narrative / guardrails / real healing session / honest limits + CTA.

**Next brief suggestions, in dependency order:**
1. **`/services`** — carries the nearshore testing staff-augmentation sub-section folded in from retired `/nearshoring`. Referenced by homepage Pillar 3.
2. **`/automated-testing`** — hero-status page; expansion of the autonomous-healing story this page introduces. Should link back here for the full proof.
3. **`/open-source-projects`** — Keep/reframe; needs the ATK canonical URL verified before this brief ships (shared dependency).
