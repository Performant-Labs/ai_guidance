# Troubleshooting Index

When something hangs, breaks silently, or behaves unexpectedly, start here.
The full catalog is split by topic. Pick the one that matches your symptom.

| Topic | When to look here |
|---|---|
| [DDEV](ddev/TROUBLESHOOTING.md) | DDEV container hangs, port conflicts, nested projects, CLI flag confusion |
| [Drupal](drupal/TROUBLESHOOTING.md) | Config import, taxonomies, form display, opcache, custom modules, WSOD, libraries |
| [Git](git/TROUBLESHOOTING.md) | `ai_guidance` symlink issues, agent pager hangs, multi-repo loop duration |
| [Playwright](playwright/TROUBLESHOOTING.md) | E2E test hangs, locator collisions, zombie code in built bundles |
| [Process](process/TROUBLESHOOTING.md) | Orphan `node`/`chromium`, `pkill` self-kill, agent approval gates |

> [!NOTE]
> Items are numbered by section: §1.x = DDEV, §2.x = Drupal, §3.x = Git,
> §4.x = Playwright, §5.x = Process. Cross-references between docs use the
> form "see §2.5".

---

## Diagnostic checklist

When something appears stuck, check in this order:

### Environment
1. Is DDEV running? → `ddev describe` (see §1.1)
2. Are there zombie processes? → `bash scripts/kill-zombies.sh` (see §5.1)
3. Is another DDEV project interfering? → `ddev list` and stop unused projects (§1.2)
4. Is there a nested `.ddev` in a parent directory? → `ls ~/Sites/.ddev` (§1.3)
5. Is the DDEV port correct? → `ddev describe` and compare with `playwright.config.ts` (§1.5)

### Playwright / Testing
6. Is the test using `networkidle`? → check `beforeEach` in the test file (§4.1)
7. Are timeouts set to fail-fast? → check `playwright.config.ts` for 30s/5s (§4.2)
8. Are locators scoped to `main`? → check for admin toolbar collisions (§4.3)
9. Is the test running against stale built bundles? → rebuild and redeploy (§4.4)
10. Did `pkill` kill itself? → use `pkill -f "node.*playwright"` not `pkill -f "playwright"` (§5.2)

### Drupal configuration
11. Is PHP opcache stale? → `ddev restart` (not just `ddev drush cr`) (§2.5)
12. Are taxonomy terms in the right vocabulary? → check `vid` matches actual name (§2.2)
13. Are form display configs imported? → check `entity_form_display` components (§2.4)
14. Are `taxonomy_access_fix` permissions granted? → check `select terms in {vocab}` (§2.3)
15. Is the markdown filter escaping HTML? → disable markdown in `full_html` (§2.8)
16. Are enrollment sub-modules enabled? → check for `social_event_an_enroll` (§2.9)
17. Did a config import cause WSOD? → check `ddev logs -s web` for SQL errors (§2.7)

### Module / library issues
18. Is the custom module in a proper subdirectory? → check `web/modules/custom/<module>/` (§2.6)
19. Are frontend libraries present? → check `web/libraries/` for `node-waves`, `autosize` (§2.10)

### DDEV CLI
20. Using wrong DDEV flags? → `ddev stop` has no `-y`; use `ddev delete --omit-snapshot -y` (§1.4)

### Git / agent environment
21. `ai_guidance` symlink broken or missing files? → recreate the symlink (§3.1)
22. Agent hung on `git log`? → cancel and use `git --no-pager log` (§3.2)
23. Multi-repo loop appears hung? → wait 60s before intervening (§3.3)
24. Command queued silently with no output? → agent approval gate (§5.3)

---

## Migration note (2026-05-04)

This file used to be a single ~950-line catalog with flat numbering 1–25.
On 2026-05-04 it was split into five topic-specific files using legal
numbering (1.1, 1.2, …, 5.3).

Mapping from the old numbers, for anyone hunting an external reference:

| Old # | New § | Topic |
|---|---|---|
| 1 | §4.1 | networkidle hang |
| 2 | §4.2 | long timeout hang |
| 3 | §5.1 | orphan playwright procs |
| 4 | §1.1 | DDEV command hangs |
| 5 | §2.1 | config import hangs |
| 6 | §2.2 | event_type vs event_types |
| 7 | §2.3 | taxonomy_access_fix |
| 8 | §4.3 | admin toolbar locator |
| 9 | §2.4 | missing form display |
| 10 | §2.5 | PHP opcache |
| 11 | §1.2 | duplicate DDEV ports |
| 12 | §5.2 | pkill self-kill |
| 13 | §1.3 | nested DDEV project |
| 14 | §2.6 | custom module flat copy |
| 15 | §2.7 | WSOD missing field storage |
| 16 | §2.8 | markdown filter escaping |
| 17 | §2.9 | enrollment sub-modules |
| 18 | §2.10 | missing frontend libs |
| 19 | §1.4 | DDEV stop flags |
| 20 | §1.5 | DDEV port variability |
| 21 | §5.3 | agent approval gate |
| 22 | §4.4 | zombie code in bundles |
| 23 | §3.1 | symlink sync (was: subtree fetch) |
| 24 | §3.2 | git pager hang |
| 25 | §3.3 | multi-repo loop duration |

Old item #23 ("subtree synchronization failures") was rewritten for the
current symlink-based sharing model — see §3.1 for the updated guidance.
