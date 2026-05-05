# Playwright Troubleshooting

Issues specific to writing or running Playwright E2E tests. For process
cleanup of orphaned `node`/`chromium` processes left behind by an aborted
Playwright run, see [`process/TROUBLESHOOTING.md`](../process/TROUBLESHOOTING.md) §5.1.

---

## 4.1 Playwright `networkidle` hang

### Symptom
Every test freezes immediately after the `beforeEach` login step. The test runner shows a test name but never progresses. Appears stuck indefinitely.

### Root Cause
The `beforeEach` hook calls:
```typescript
await page.waitForLoadState('networkidle');
```
`networkidle` waits until there are **zero network connections for 500ms**. Open Social has perpetual background AJAX requests (heartbeat polling, notification checks, etc.) that **never stop**. The condition never resolves.

### Detection
- Tests hang consistently on the first test.
- No timeout error appears (the wait is inside `beforeEach`, not subject to assertion timeouts).
- Killing the process and checking the test file reveals `networkidle`.

### Solution
Change `networkidle` to `load` in the test's `beforeEach` hook:
```typescript
// ❌ WRONG — hangs forever with Open Social
await page.waitForLoadState('networkidle');

// ✅ CORRECT — completes after page loads
await page.waitForLoadState('load');
```

### Prevention
- **Never use `networkidle`** with Open Social or any Drupal site that has background AJAX.
- Add a comment in the test file explaining why `load` is used.
- The BUILD_LOG includes a `[!CAUTION]` block about this.

### Files affected
- `tests/e2e/phase1-content-types.spec.ts` — line 12

---

## 4.2 Playwright long timeout hang

### Symptom
A test waits 2+ minutes before failing. It looks stuck but is actually waiting for a missing element with an excessively long timeout.

### Root Cause
Default Playwright timeouts are generous:
- Test timeout: `120000ms` (2 minutes)
- Assertion timeout: `30000ms` (30 seconds)

When a UI element is missing (e.g., due to a Drupal config gap), Playwright retries for the full timeout duration before reporting a failure.

### Detection
- Test eventually fails with "Test timeout of 120000ms exceeded".
- The error shows "waiting for locator..." with many retry attempts.
- The test itself is not stuck — it's just waiting too long.

### Solution
Set fail-fast timeouts in `playwright.config.ts`:
```typescript
export default defineConfig({
    timeout: 30000,       // 30s per test (was 120s)
    expect: {
        timeout: 5000     // 5s per assertion (was 30s)
    },
    // ...
});
```

### Prevention
- Always set these timeouts when configuring a new test environment.
- The BUILD_LOG Step 230 documents the correct values.

---

## 4.3 Test locator matching admin toolbar

### Symptom
A test assertion like `a:has-text("Enroll")` resolves to a hidden admin toolbar element instead of the visible page content. Test fails with "Expected: visible / Received: hidden".

### Root Cause
Open Social's admin toolbar contains links to configuration pages (e.g., "Event enrollment settings") that match broad locators. The toolbar elements are technically in the DOM but are hidden or positioned off-screen.

### Detection
The Playwright error log shows "locator resolved to" followed by an admin toolbar element:
```
locator resolved to <a href="/admin/config/opensocial/event" ...>Event enrollment settings</a>
```

### Solution
Scope all locators to the `main` element:
```typescript
// ❌ WRONG — matches admin toolbar
page.locator('a:has-text("Enroll")').first()

// ✅ CORRECT — scoped to page content
page.locator('main a:has-text("Enroll")').first()
```

### Prevention
- All test locators in `phase1-content-types.spec.ts` should be scoped to `main`.
- The BUILD_LOG includes an `[!IMPORTANT]` block about this.

---

## 4.4 Silent Playwright failures (zombie code)

### Symptom
Playwright E2E tests interact with UI elements and successfully run, but recent changes applied to the source code (e.g., `.ts`, `.vue`) seem perfectly invisible. Diagnostic `console.log` statements added to the code do not appear in the test output.

### Root Cause
The Playwright tests run against the production-like reverse proxy (e.g., `https://cloud.opencloud.test`), which serves pre-built, static bundles of the application from a mounted volume or server app directory. If the application is not actively rebuilt via `make build` / `pnpm build` and the resulting `dist/` directory is not physically copied over to the server's extension mount directory (e.g., `pl-opencloud-server/config/opencloud/apps/...`), the proxy permanently serves the old JavaScript bundle. The tests run against zombie code.

### Detection
- Code modifications (e.g., adding an obvious UI element or `data-testid`) do not show up during the test.
- The `make dev` watcher is active, but Playwright is targeting a non-localhost `baseURL` that is completely disconnected from Vite's Hot Module Replacement (HMR).

### Solution
1. Completely rebuild the frontend application: `pnpm build`
2. Copy the resulting static assets directly into the reverse proxy's application directory:
   ```bash
   cp -r dist/* ../../pl-opencloud-server/config/opencloud/apps/your-extension/
   ```
3. Clear the browser cache or start a new in-memory context (Playwright does this natively).

### Prevention
- Never assume Vite dev server (HMR) dictates what the E2E framework sees if `baseURL` points to the primary `.test` local domain.
- Create a `make build-and-deploy` command or incorporate the `cp` operation natively into the test pipeline's global setup.
