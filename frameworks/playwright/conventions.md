# Playwright Conventions

> Sources: [Playwright Docs](https://playwright.dev/), [Visual Comparisons](https://playwright.dev/docs/test-snapshots)

Playwright is the tool for **Tier 3 (Visual Fidelity)** verification in the Three-Tier Verification Hierarchy defined in [`testing/verification-cookbook.md`](../../testing/verification-cookbook.md). It launches headless browsers, navigates to pages, takes screenshots, and compares them against baselines.

> [!IMPORTANT]
> **Playwright is Tier 3 only.** Do not use Playwright for checks that `curl`, `grep`, or Vitest can handle. Read the pre-condition ladder in [`testing/visual-regression-strategy.md`](../../testing/visual-regression-strategy.md) — Tier 3 never runs before Tier 1 and Tier 2 are green.

---

## Role in the Three-Tier Hierarchy

| Tier | Tool | What it answers |
|------|------|----------------|
| T1 | `curl` + `grep` | Is the server up? Is the HTML correct? Are CSS variables present? |
| T2 | Vitest (unit + integration) | Do schemas validate? Do routes return correct shapes? Do cascades work? |
| T3 | **Playwright** | Does the rendered page look correct? Do interactions work? Do visual regressions exist? |

### When to use Playwright

- Layout verification at specific viewports
- Visual regression against baseline screenshots
- Interactive behavior (hover states, modals, dropdowns, form submissions)
- Accessibility audits that require a real DOM (axe-core via `@axe-core/playwright`)
- End-to-end flows (e.g., import CSV → verify table updates)

### When NOT to use Playwright

- Checking HTTP status codes → `curl`
- Checking if text exists on a page → `curl | grep`
- Checking CSS variable values → `curl | grep`
- Testing API response shapes → Vitest integration test
- Testing Zod validation → Vitest unit test
- Checking if the server starts → spawn process + `curl`

---

## Project Setup

### Installation

```bash
npm install -D @playwright/test
npx playwright install --with-deps chromium  # only Chromium for CI speed; add firefox/webkit if needed
```

### Config

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',

  use: {
    baseURL: process.env.BASE_URL ?? 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },

  projects: [
    {
      name: 'chromium-desktop',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'chromium-mobile',
      use: { ...devices['Pixel 5'] },
    },
  ],

  // Start the dev server before running tests
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 30_000,
  },
});
```

### Directory Structure

```
e2e/
  fixtures/              # Page objects, test helpers, shared setup
    base-page.ts         # Base page object with common navigation
    test-data.ts         # Seed data for E2E tests
  visual/                # Visual regression tests (T3)
    registry.spec.ts     # Registry page visual checks
    detail.spec.ts       # Detail page visual checks
  flows/                 # End-to-end user flows
    import-csv.spec.ts   # Full import workflow
    exploit-lifecycle.spec.ts
  screenshots/           # Baseline screenshots (committed to repo)
    registry-desktop.png
    registry-mobile.png
    detail-desktop.png
```

---

## Visual Regression Testing (T3)

### Taking baseline screenshots

```typescript
// e2e/visual/registry.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Registry page visual regression', () => {
  test.beforeEach(async ({ page }) => {
    // Seed known data state before visual tests
    await page.goto('/');
  });

  test('registry table renders correctly at desktop', async ({ page }) => {
    // Wait for data to load — never screenshot a loading spinner
    await page.waitForSelector('[data-testid="exploit-table"]');

    // Compare against baseline
    await expect(page).toHaveScreenshot('registry-desktop.png', {
      maxDiffPixelRatio: 0.01,  // 1% tolerance for anti-aliasing
      fullPage: false,          // viewport only — never full-page (see budget rules)
    });
  });

  test('registry table renders correctly at mobile', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await page.waitForSelector('[data-testid="exploit-table"]');

    await expect(page).toHaveScreenshot('registry-mobile.png', {
      maxDiffPixelRatio: 0.01,
    });
  });
});
```

### Focused component screenshots

Per the VR strategy budget rules: **one viewport per comparison, never full-page as analysis input.** Use element-scoped screenshots for component-level checks:

```typescript
test('status badges render with correct colors', async ({ page }) => {
  await page.goto('/');
  await page.waitForSelector('[data-testid="exploit-table"]');

  const statusBadge = page.locator('[data-testid="status-badge-active"]').first();
  await expect(statusBadge).toHaveScreenshot('status-badge-active.png', {
    maxDiffPixelRatio: 0.01,
  });
});
```

### Updating baselines

When a visual change is intentional:

```bash
npx playwright test --update-snapshots
```

Review the updated screenshots in `e2e/screenshots/` before committing. Every baseline update should be accompanied by a reason in the commit message.

---

## Interactive Testing (T3)

For behaviors that require a real browser — hover states, modals, keyboard navigation:

```typescript
test('clicking an exploit row opens the detail page', async ({ page }) => {
  await page.goto('/');
  await page.waitForSelector('[data-testid="exploit-table"]');

  // Click the first row
  await page.locator('[data-testid="exploit-row"]').first().click();

  // Verify navigation
  await expect(page).toHaveURL(/\/exploits\/\d+/);
  await expect(page.locator('h1')).toContainText('Exploit');
});

test('quick filter tabs filter the registry', async ({ page }) => {
  await page.goto('/');
  await page.waitForSelector('[data-testid="exploit-table"]');

  // Click "Blocked" filter tab
  await page.locator('[data-testid="filter-blocked"]').click();

  // Wait for filtered results
  await page.waitForSelector('[data-testid="exploit-table"]');

  // All visible status badges should show "Blocked"
  const badges = page.locator('[data-testid^="status-badge-"]');
  const count = await badges.count();
  for (let i = 0; i < count; i++) {
    await expect(badges.nth(i)).toHaveAttribute('data-testid', 'status-badge-blocked');
  }
});
```

---

## Accessibility Audits

Use `@axe-core/playwright` for automated accessibility checks:

```bash
npm install -D @axe-core/playwright
```

```typescript
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('registry page passes WCAG AA', async ({ page }) => {
  await page.goto('/');
  await page.waitForSelector('[data-testid="exploit-table"]');

  const results = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa'])
    .analyze();

  expect(results.violations).toEqual([]);
});
```

---

## Page Objects

Keep test logic clean with page objects:

```typescript
// e2e/fixtures/registry-page.ts
import { Page, Locator, expect } from '@playwright/test';

export class RegistryPage {
  readonly table: Locator;
  readonly searchInput: Locator;
  readonly filterTabs: Locator;

  constructor(private page: Page) {
    this.table = page.locator('[data-testid="exploit-table"]');
    this.searchInput = page.locator('[data-testid="search-input"]');
    this.filterTabs = page.locator('[data-testid="filter-tabs"]');
  }

  async goto() {
    await this.page.goto('/');
    await this.table.waitFor();
  }

  async search(query: string) {
    await this.searchInput.fill(query);
    await this.table.waitFor();
  }

  async selectFilter(name: string) {
    await this.filterTabs.locator(`[data-testid="filter-${name}"]`).click();
    await this.table.waitFor();
  }

  async getRowCount(): Promise<number> {
    return this.page.locator('[data-testid="exploit-row"]').count();
  }

  async clickRow(index: number) {
    await this.page.locator('[data-testid="exploit-row"]').nth(index).click();
  }
}
```

---

## Integration with the O-F-T-S Pipeline

### Who runs what

| Agent | Playwright role |
|-------|----------------|
| **F (Feature Implementor)** | Writes Playwright tests alongside features. Does NOT run T3 visual checks — only writes the test code. |
| **T (Tester)** | Runs `npx playwright test` as part of T2 structural checks (test suite passes/fails). Does NOT interpret visual results. |
| **S (Spec Auditor)** | Owns T3. Runs Playwright visual regression tests, interprets results, compares against spec. Updates baselines when changes are intentional. |

### CI integration

```yaml
# .github/workflows/playwright.yml (example)
- name: Run Playwright tests
  run: npx playwright test
  env:
    CI: true
```

### Test data management

E2E tests need a known database state. Options:

1. **Seed script** — run before each test suite via `globalSetup`:
   ```typescript
   // playwright.config.ts
   export default defineConfig({
     globalSetup: './e2e/fixtures/global-setup.ts',
   });

   // e2e/fixtures/global-setup.ts
   export default async function globalSetup() {
     // Reset database to known state
     // Run seed script
   }
   ```

2. **API-driven setup** — each test hits the API to create its own data:
   ```typescript
   test.beforeEach(async ({ request }) => {
     await request.post('/api/projects', { data: { name: 'Test Project' } });
     await request.post('/api/exploits', { data: { title: 'Test Exploit', projectId: 1 } });
   });
   ```

   Prefer option 2 for isolation — each test creates and tears down its own state.

---

## Budget Rules (from VR Strategy)

These rules from `testing/visual-regression-strategy.md` apply directly to Playwright usage:

1. **One viewport per comparison** — don't take 6 screenshots and analyze them all in one pass.
2. **No full-page screenshots as analysis inputs** — use element-scoped screenshots or viewport-only captures.
3. **Write findings incrementally** — don't accumulate results in memory.
4. **`curl` first, browser last** — if `curl | grep` can answer the question, don't launch Playwright.
5. **Every visual check compares against something concrete** — a baseline image, a design spec, or a numeric claim. "Looks right" is not a check.

---

## Common Gotchas

| Symptom | Cause | Fix |
|---------|-------|-----|
| Screenshots differ on every run | Animations, timestamps, or loading spinners in the capture | Disable animations: `page.emulateMedia({ reducedMotion: 'reduce' })`. Mask dynamic content: `mask: [page.locator('.timestamp')]` |
| Tests fail in CI but pass locally | Different font rendering, missing system fonts | Use Docker with consistent fonts, or increase `maxDiffPixelRatio` |
| Tests are slow (>60s each) | Full-page screenshots, waiting for network idle unnecessarily | Use `waitForSelector` on the specific element, not `waitForLoadState('networkidle')` |
| `toHaveScreenshot` fails with "missing baseline" | First run, or baseline not committed | Run `--update-snapshots` once, commit the baseline |
| Flaky click/navigation tests | Element not ready, animation in progress | Use `await locator.waitFor()` before interacting, or `expect(locator).toBeVisible()` |
| Baseline screenshots are huge | Full-page captures committed | Use viewport-only or element-scoped screenshots |

---

## References

- [`testing/verification-cookbook.md`](../../testing/verification-cookbook.md) — Three-Tier Verification Hierarchy (authoritative)
- [`testing/visual-regression-strategy.md`](../../testing/visual-regression-strategy.md) — VR gate structure, budget rules, pre-condition ladder
- [`agent/browser-constraints.md`](../../agent/browser-constraints.md) — headless-first rule
- [Playwright Visual Comparisons](https://playwright.dev/docs/test-snapshots) — official screenshot comparison docs
- [axe-core/playwright](https://github.com/dequelabs/axe-core-npm/tree/develop/packages/playwright) — accessibility testing integration
