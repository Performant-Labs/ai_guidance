# AI-Guided Theme Generation

This runbook outlines the standard operating procedure for AI developer agents tasked with safely creating a new testbed theme and translating UI screenshots into functional Drupal pages. 

> [!IMPORTANT]
> **Theme-Specific Run-Time Instruction**: At run-time, you MUST ask the user to provide the documentation folder path for their underlying base theme framework (e.g., `drupal/dripyard_themes`). You must thoroughly review all theme-specific instructions (such as component inventories and color management rules) stored in that folder before making architectural layout assumptions.

## Operating Principles
The primary objective is to ingest a UI screenshot, map its visual elements to the components provided by the user's specified base theme framework, and implement the resulting layout within Drupal. 

To ensure absolute safety and maintain a functional baseline for the host project, **AIs must first duplicate the existing stable theme into a new working directory before making any experimental layout or styling changes.**

---

## Phase 1: Pre-Execution Discovery
Before cloning repositories or running commands, the AI must collect all foundational environment variables and display them to the user for explicit confirmation.

1. Gather the following run-time parameters:
   - **Primary Active Theme Name** (e.g., `performant_labs`)
   - **Target Local Project Path** (e.g., `~/Sites/pl-performantlabs.com`)
   - **Base Theme Documentation Namespace** (e.g., `drupal/dripyard_themes`)
   - **Location of Target Layout Screenshots**
   - **Legacy Audit Requirement** (Required/Skipped — whether the existing site architecture needs structural mapping)
   - **Local Runtime Environment**: Automatically test the target codebase to detect the active container wrapper (e.g., scan for `.ddev/` or `.lando.yml`). Report the detected runtime prefix (e.g., `ddev`, `lando`, or native) to the user rather than blindly assuming.
   - **Git Safety Check**: Run `git status` to verify the working tree is completely clean. If uncommitted changes exist, force the user to stash or commit them. Do not allow execution on a dirty tree.
2. Display these collected values back to the user in a formatted list or table.
3. Explicitly ask: *"Do these setup parameters look correct? Just give me the green light and we'll jump into Phase 2!"* DO NOT proceed until the user approves.

---

## Phase 2: Establish the Baseline Backup
Before altering any structural CSS or Layout builder templates, preserve the current customized primary theme.

1. **Clone**: Duplicate the primary stable directory (`web/themes/custom/[primary_theme]`) to a new working directory appending a date/timestamp (e.g., `web/themes/custom/[primary_theme]_20260411`).
2. **Refactor**: Perform a targeted find-and-replace to rename all machine names inside configuration files only. Scope this strictly to `.info.yml`, `.breakpoints.yml`, `.theme`, `.libraries.yml`, and `.yml` files. Do NOT run a broad replacement across all files — binary assets, images, and generic CSS class names must not be touched.
3. **Activate**: Enable the newly cloned layout theme and set it as the default theme via Drush, utilizing the runtime wrapper detected in Phase 1:
   ```bash
   [runtime_wrapper] drush theme:enable [primary_theme]_[timestamp]
   [runtime_wrapper] drush config:set system.theme default [primary_theme]_[timestamp] -y
   [runtime_wrapper] drush cr
   ```
4. **Result**: This preserves the original theme untouched. If the experimental implementations collapse the site layout, AIs can instantly revert the active system theme to the known-good configuration.
5. **Version Control Snapshot**: Add and commit only the cloned theme directory using its explicit path (e.g. `git add web/themes/custom/[primary_theme]_[timestamp] && git commit -m "chore: Branch new component testbed theme"`). Do NOT use `git add .` here — only stage the new theme directory to avoid accidentally committing unrelated working files.

---

## Phase 3: Screenshot Ingestion & Component Mapping
Once the user provides the target design:

1. **Asset Storage**: Immediately save the provided screenshot into a `/designs` or `/reference` directory inside the newly created active theme (e.g., `web/themes/custom/[primary_theme]_[timestamp]/designs/screenshot.png`). This ensures the AI context and layout references are permanently shipped alongside the theme files.
2. *(Optional)* **Legacy Architecture Audit**: If the objective is to migrate or upgrade an existing live website into the new Canvas architecture, perform a comprehensive structural audit of the legacy site before making assumptions about the new layout.
   - Target the local legacy codebase environment (e.g., navigating into `~/Sites/pl-performantlabs.com`).
   - Utilize native database introspection, Drush commands, or structural DOM analysis to dissect the existing content framework (tracking how legacy blocks, node fields, and taxonomies are routed).
   - Draft this architectural dissection into an explicit Markdown file and save it within an `/audits` directory positioned as a direct peer to the `/designs` directory inside the new active theme (e.g., `web/themes/custom/[primary_theme]_[timestamp]/audits/legacy_dissection.md`).
3. **Visual Decomposition**: Analyze the screenshot to break down the UI into logical horizontal bands (e.g., Hero Banners, Feature Grids, Logo Arrays, Call-to-Action blocks).
4. **Component Cross-referencing**: Check these visual bands against your base theme's component library (identified via the documentation folder provided by the user) to identify completely reusable Twig structures and native CSS modifier classes.
5. **Gap Analysis**: Identify any bespoke elements in the screenshot that do not have a native equivalent in the base theme. These will require entirely custom CSS implementations.
6. **Implementation Plan Generation**: Synthesize your structural component findings and draft your `theme_component_mapping_plan.md` strategy directly into the specific theme documentation folder that the user provided natively at run-time (e.g., `drupal/dripyard_themes/`).
7. **Version Control Snapshot**: Immediately commit the raw target assets, the legacy audit framework (if generated), and your drafted component plan to Git (e.g., `git add . && git commit -m "docs: Scaffold layout target assets and implementation mapping"`). 
8. **Approval Checkpoint**: With the plan safely tracked in version control, you must explicitly STOP execution. Display your mapped strategy to the user and wait for their explicit manual approval before advancing into Phase 4 layout executions.

---

## Phase 4: Implementation Execution
1. **Markup Generation**: Generate the HTML structure applying the proper `theme--primary` or relative theme constraint wrappers. Ensure these natively inherit the overarching color palette overrides defined in the Component Layer configuration (`css/base.css`).
2. **Global CSS Overrides (Native Components)**: If the design dictates nuanced spacing or styling modifications for existing native components, append custom CSS explicitly targeting the Component Layer inside the new canvas theme's `css/base.css` file. DO NOT attempt to override semantic variables directly.
3. **Integration Strategy (Bespoke SDCs Enforced)**: When generating custom layout elements that do not exist natively, you MUST exclusively output standard **Single Directory Components (SDCs)** formatted within the active theme's `components/` directory (e.g., creating the `.component.yml`, `.twig`, and `.css` bundle). The styling for these bespoke components must be encapsulated entirely inside their local `.css` file, NOT in `base.css`. Do NOT output raw disconnected HTML payloads, and do NOT architect the output using custom Drupal Blocks, Layout Builder, or root Twig templates.
4. **AI Autonomous Content Population**: When structural components (like the "Product, Pricing, Blog" header navigation or dynamic card grids) require functional Drupal content to render, DO NOT manually construct UI configurations or write raw database queries. Instead, map out the required menu items or nodes in a natural language prompt and execute it securely through standard input using the native Drupal `ai_agents` service. **Do not write temporary PHP files to the disk.** Pipe the execution logic directly in memory via Heredoc:
   ```bash
   cat << 'EOF' | [runtime_wrapper] drush scr -
   <?php
   // ... script invoking \Drupal::service('ai_agents') ...
   EOF
   ```
5. **Version Control Snapshot**: Commit the newly generated SDCs, CSS wrappers, and payload scripts before handing off to the verification stage (e.g. `git commit -m "feat: Implement Canvas SDCs and dynamic payload generators"`).

---

## Phase 5: Verification 
1. **Manual Canvas Assembly Hold**: Because you just scaffolded structural SDC bundles into the `components/` directory, these elements are not inherently attached to a live route. You must STOP execution and explicitly instruct the user to:
   - Clear the Drupal cache (e.g., `[runtime_wrapper] drush cr`) so the theme registry discovers your new SDCs.
   - Assemble the layout inside the Drupal Canvas UI using your generated components.
   - Provide you with the URL of the finalized page.
2. **Browser Verification**: Once the user provides the rendered URL, load the Canvas page in the headless browser.
3. **Visual Regression**: Visually compare the rendered DOM output against the original target screenshot.
4. **Cascade Safety Check**: Verify that your custom CSS overrides remained perfectly encapsulated within the Canvas components and did not accidentally poison the broader global typography or color matrices expected natively by the host site.
