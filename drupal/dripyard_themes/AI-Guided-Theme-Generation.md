# AI-Guided Theme Generation

This runbook outlines the standard operating procedure for AI developer agents tasked with safely creating a new testbed theme and translating UI screenshots into functional Drupal pages using the `dripyard_base` ecosystem.

## Operating Principles
The primary objective is to ingest a UI screenshot, map its visual elements identically to Dripyard theme components, and implement the layout within Drupal. 

To ensure absolute safety and maintain a functional baseline for the host project, **AIs must first duplicate the existing stable theme into a new working directory before making any experimental layout or styling changes.**

---

## Phase 1: Establish the Baseline Backup
Before altering any structural CSS or Layout builder templates, preserve the current customized primary theme.

1. **Clone**: Duplicate the primary stable directory (`web/themes/custom/[primary_theme]`) to a new working directory appending a date/timestamp (e.g., `web/themes/custom/[primary_theme]_20260411`).
2. **Refactor**: Perform a comprehensive internal find-and-replace to rename all machine names, file prefixes, and YAML configurations (e.g. `.info.yml`, `.breakpoints.yml`, `.theme` files) to match the new timestamp suffix.
3. **Activate**: Enable the newly cloned layout theme and set it as the default theme via Drush:
   ```bash
   ddev drush theme:enable [primary_theme]_[timestamp]
   ddev drush config:set system.theme default [primary_theme]_[timestamp] -y
   ddev drush cr
   ```
4. **Result**: This preserves the original theme untouched. If the experimental implementations collapse the site layout, AIs can instantly revert the active system theme to the known-good configuration.

---

## Phase 2: Screenshot Ingestion & Component Mapping
Once the user provides the target design:

1. **Asset Storage**: Immediately save the provided screenshot into a `/designs` or `/reference` directory inside the newly created active theme (e.g., `web/themes/custom/[primary_theme]_[timestamp]/designs/screenshot.png`). This ensures the AI context and layout references are permanently shipped alongside the theme files.
2. **Visual Decomposition**: Analyze the screenshot to break down the UI into logical horizontal bands (e.g., Hero Banners, Feature Grids, Logo Arrays, Call-to-Action blocks).
3. **Component Cross-referencing**: Check these bands against `web/themes/contrib/dripyard_base/components/` to identify completely reusable Twig structures and native CSS class names.
4. **Gap Analysis**: Identify any bespoke elements in the screenshot that do not have a native Dripyard equivalent. These will require entirely custom CSS implementations.
5. **Implementation Plan Generation**: Before writing any execution markup, STOP and generate an `implementation_plan.md` artifact summarizing your findings from the component mapping and gap analysis. Wait for the user to explicitly approve your strategy.

---

## Phase 3: Implementation Execution
1. **Markup Generation**: Generate the HTML structure applying the proper `theme--primary` or relative theme constraint wrappers. Ensure these natively inherit the overarching color palette overrides defined in the Component Layer configuration (`css/base.css`).
2. **CSS Overrides**: If the screenshot dictates nuanced spacing or bespoke element styling, append custom CSS explicitly targeting the Component Layer inside the new canvas theme's `css/base.css` file. DO NOT attempt to override semantic variables directly.
3. **Integration Strategy**: Wait for user clarification on how to inject the markup (e.g., as a custom Twig template override like `page--front.html.twig`, a custom Drupal Block class, Paragraphs, or the Acquia Layout Builder grid).

---

## Phase 4: Verification 
1. Render the newly built Canvas page in the browser at the local DDEV URL.
2. Visually compare the rendered DOM output against the original screenshot.
3. Verify that the CSS cascade correctly limits your structural changes and does not accidentally poison the broader global typography or color matrices expected by the site. 
