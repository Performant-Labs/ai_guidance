# Keytail Component Mapping Plan

This document details the strategy for recreating the `keytail-desktop.webp` design using the `performant_labs_20260411` baseline theme, the underlying `dripyard_base` components, and specifically formatting the output for **Drupal Canvas pages**.

## Phase 1 & 2 Execution Status
- [x] Created the baseline backup `performant_labs_20260411`.
- [x] Sliced the continuous source image into 8 localized image bands stored in `/designs/`.

## Component Mapping Strategy

We will construct this layout block-by-block. All regions will utilize native Dripyard CSS modifier classes (e.g., `theme--light`, `theme--dark`) to enforce color inheritance, completely decoupled from Layout Builder blocks.

### 1. Global Navigation & Hero Region
- **Design Elements:** Transparent sticky header, centered massive typography ("Get found. Automatically."), search input, and a complex green-gradient background masking a dashboard mock.
- **Dripyard Components:** `header-logo`, `title-cta` (for text and input).
- **Customization Required:** The intricate green gradient masking the dashboard image is not a native component. We will write a custom CSS block using `clip-path` and gradients inside `base.css` to build this hero wrapper.

### 2. Feature Cards ("Search has changed")
- **Design Elements:** 3-column masonry/grid showing floating UI cards.
- **Dripyard Components:** `content-card`. 
- **Layout Construction:** Enclosed in a standard Canvas grid row array utilizing the white surface wrapper (`theme--white`).

### 3. Horizontal Scroll Cards ("Built different")
- **Design Elements:** 4 horizontal scrollable cards with inner images and pills.
- **Dripyard Components:** `carousel` wrapped around standard `card` components.
- **Customization Required:** Custom CSS for the inner black pill buttons with right-facing arrows.

### 4. Content Engine Dashboard View
- **Design Elements:** Title/subtitle above a prominent dark dashboard image with "Discover / Create / Publish" toggle buttons.
- **Dripyard Components:** `tabs` (for the toggle structure), `heading`.
- **Layout Construction:** Enclosed in a `theme--light` (grey) background wrapper.

### 5. Multi-Column Content ("Designed for teams")
- **Design Elements:** Standard 2-column layout (Text left, image right).
- **Dripyard Components:** `teaser` component mapped into a 2-column Canvas boundary.

### 6. Interactive Graph ("Just like stocks")
- **Design Elements:** Typography above a line graph with an interactive tab switcher.
- **Dripyard Components:** `tabs` structure to handle the UI layout of the switcher. 
- **Customization Required:** The graph itself is highly custom. We will build a static mock of the graph container using basic HTML/SVG and position it below the tabs.

### 7. FAQ 
- **Design Elements:** Centered "FAQ" title, expanding/collapsing question rows.
- **Dripyard Components:** `accordion`. We will style the accordion items to maintain the ultra-thin grey bordering from the design.

### 8. Custom Footer & Massive Logo
- **Design Elements:** Dark slate blue background featuring a massive 'K' watermark taking up the left column, with standard footer links on the right.
- **Dripyard Components:** `menu-footer`.
- **Customization Required:** The massive oversized 'K' background is highly bespoke. We will enforce this using standard wrapper classes (`theme--primary`) and absolutely position an SVG vector behind the primary footer content container.

## Canvas Output Strategy

Unlike static templates, we will generate the raw HTML payload conforming to Canvas component payload structures. I will write the HTML and corresponding CSS patches required for `performant_labs_20260411` incrementally so you can drop them into the Canvas editor.
