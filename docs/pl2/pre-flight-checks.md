# Session Pre-Flight Checks

Before beginning any theming work session on `performant_labs_20260418` (or any child theme in the PL2 stack), engineers and AI agents must complete the following checks. This ensures the environment is stable, the correct context is loaded, and changes do not bleed unintentionally across config or themes.

---

## 1. Context & Environment Verification

### Active Branch
Verify you are operating on the correct feature branch for the current theme sprint. Do not work directly on `main` or another developer's isolated testbed branch unless bridging work.

```bash
git branch
# Ensure the actively checked out branch matches your session intent.
# Expected typical branch: `* aa/performant-labs-20260418-theme`
```

### Git State
Verify the working tree is clean. If uncommitted changes exist from a previous session, stash or commit them before starting new work.
```bash
git status
```

### Review the Knowledge Base
Check the `docs/pl2` directory briefly. Ensure you are familiar with the specific rules from the following central strategy documents:
- `neonbyte-plan.md`: Know exactly which stage/phase you are executing.
- `theme-change.md`: Know the 5-layer OKLCH color rules and specificity guidelines to avoid `!important` loops.

### Key Module Verification
The PL2 stack and Dripyard Canvas component pipeline rely on several critical modules being enabled. Before committing to component assembly or theme previews, verify they are active:
```bash
# Check the status of required modules:
ddev drush pm:list --status=enabled --no-core | grep -iE 'canvas|pl_theme_preview|metatag|sdc_styleguide|asset_injector'
```
> [!TIP]
> **Asset Injector** (`asset_injector`) is highly recommended for rapid prototyping. It allows you to inject CSS and JS directly through the Drupal admin UI without modifying files or clearing the cache, dramatically speeding up the visual verification process before committing to final SDC `.css` files.
*(Note: If you encounter an "Unrecognized component" error later on, ensure the overarching `sdc` core module architecture is functioning correctly, or any specifically required component-library module for the active base theme is enabled.)*

---

## 2. Using the Theme Preview Shim (Zero Config Modification)

If you need to verify or audit a theme’s visual integrity—such as the base Dripyard theme (`dripyard_base`), the child theme (`neonbyte`), or the specific project testbed (`performant_labs_20260418`)—you **do not** need to change the active theme via Drush or `system.theme`. 

The `pl_theme_preview` module allows an authenticated administrator to instantly preview any enabled theme by appending a query parameter.

**How to use:**
1. Log in as an administrator (must have the `administer themes` permission).
2. Append `?theme=[theme_machine_name]` to any URL.

**Examples:**
- `https://pl-performantlabs.com.ddev.site/?theme=dripyard_base`
- `https://pl-performantlabs.com.ddev.site/?theme=neonbyte`
- `https://pl-performantlabs.com.ddev.site/?theme=performant_labs_20260418`

> [!TIP]
> The preview acts at the request layer using the `ThemePreviewNegotiator`. No configuration (`drush config:export`) is mutated, meaning you can audit older layout architectures natively and compare them visually alongside your current work without disrupting the live configuration states.

---

## 3. Tool Verification (Tiered Hierarchy)

Recall the "Three-Tier Verification Hierarchy":
- **Tier 1 (Headless / Curl)**: Verify tokens in the DOM (`curl | grep`) without opening a browser layout.
- **Tier 2 (ARIA / Structural Skeleton)**: Confirm component accessibility and block structures.
- **Tier 3 (Visual / Subagent)**: Only proceed to a browser screenshot when structural and template hooks are 100% verified.

---

## 4. Run State Cleanliness Check

Before running any script or compilation:
- **Did `ddev` start correctly?** Run `ddev status`. If you see services listed as `exited`, run `ddev start` and wait for the containers to initialize. A stopped environment causes silent failures in tests and commands downstream.
- **Are there any leftover script traces?** Check the project root for temporary `.php` scripts used in previous runs and remove them.
- **Are there new Watchdog errors?** `ddev drush watchdog:show --count=10 --severity=3` or `4` to ensure you aren't inheriting silent exceptions.

---

## 5. Component Development Pre-Flights

If you are beginning work on SDC components in the subtheme (e.g., `performant_labs_20260418`), verify the following:

- **Component Directory Strategy**: The root `components/` directory is not provided by default in scaffolded themes. Creating a new component requires manually establishing `web/themes/custom/[theme]/components/[component_name]`. 
- **Component Discovery Check**: If you establish a new `.component.yml` or edit a component schema and it isn't rendering, run a discovery check to ensure Drupal actually sees it. A small YAML syntax error can drop a component entirely without throwing loud warnings on a page load.
  
  ```bash
  ddev drush php-eval "echo in_array('[theme_machine_name]:[component_name]', array_keys(\Drupal::service('plugin.manager.sdc')->getDefinitions())) ? 'YES' : 'NO';"
  ```
  *(Example: replacing `[theme_machine_name]:[component_name]` with `performant_labs_20260418:dry_run_test` will print `YES` if registered successfully.)*
