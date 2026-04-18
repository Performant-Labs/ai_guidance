# `performant_labs_20260418` — Stage 2: Component Work

> **Parent:** [`neonbyte-plan.md`](neonbyte-plan.md)
> **Previous:** [`neonbyte-plan--theme.md`](neonbyte-plan--theme.md)
> **Next:** [`neonbyte-plan--pages.md`](neonbyte-plan--pages.md)

---

## Entry Condition

Before starting this stage:
- [ ] Stage 1 complete — `performant_labs_20260418` is active and passes T1 + T2 verification
- [ ] SDC Styleguide module is installed and enabled (`ddev drush pm:list --type=module | grep sdc_styleguide`)
- [ ] Explorer is accessible at `https://pl-performantlabs.com.2.ddev.site:8493/styleguide/explorer` (requires admin login)

---

## Purpose

Work on NeonByte SDC components **in isolation** — before they are placed into any page. The SDC Styleguide explorer renders each component with editable prop/slot values, allowing visual and structural verification without creating content.

All CSS decisions defer to the `theme-change` document family. No component CSS is written directly — it must be traced through the workflow.

---

## Tooling

| Tool | URL | Purpose |
|---|---|---|
| SDC Styleguide explorer | `/styleguide/explorer` | Browse and preview all registered components |
| Theme preview | `?theme=performant_labs_20260418` | Compare rendering under the new theme without switching the site default |
| Component cookbook | [`component-cookbook.md`](../ai_guidance/frameworks/drupal/theming/component-cookbook.md) | Authoritative prop/slot names for every NeonByte component |
| Component schema | `themes/dripyard_base/components/[name]/[name].component.yml` | Source of truth for component structure |

---

## Execution Phases

### Phase 1 — Component Audit
- [ ] Open `/styleguide/explorer` and enumerate all available components
- [ ] For each component, record: name, renders correctly (Y/N), visual issues (description)
- [ ] Identify components that require a brand override vs. those that inherit correctly from the OKLCH palette
- [ ] Prioritise: highest-visibility components first (hero, button, card, navigation, footer)

> **Output:** A prioritised list of components needing overrides. Used as the input to Phase 2.

---

### Phase 2 — Per-Component Override Loop

Repeat for each component identified in Phase 1. The loop is:

1. **Read** the component schema at `themes/dripyard_base/components/[name]/[name].component.yml`
2. **Check** `component-cookbook.md` for known prop/slot names
3. **Determine override type** — CSS-only, Twig, or structural (see §Override Patterns below)
4. **Follow** [`theme-change--workflow.md`](theme-change--workflow.md) — mandatory trace before any edit
5. **Apply** the override to `themes/custom/performant_labs_20260418/`
6. **Verify** in the SDC explorer — T1 structure check, then visual pass in explorer
7. **Commit**

> **Commit point:** One commit per component.
> ```bash
> git add themes/custom/performant_labs_20260418/components/[component-name]/
> git commit -m "feat(components): override [component-name] for performant_labs_20260418 brand"
> ```
> *Rollback: `git revert <commit>` removes one component override — all others unaffected.*

---

### Phase 3 — Cross-Component Verification
- [ ] View all overridden components together in the explorer
- [ ] Confirm visual consistency across components (colour, radius, spacing)
- [ ] Run T1 + T2 on the home page to confirm no regressions at page level

> **Commit point:** Only if a cross-component adjustment was needed.
> ```bash
> git add themes/custom/performant_labs_20260418/css/base.css
> git commit -m "fix(components): correct cross-component consistency issue"
> ```

---

## Override Patterns

### CSS-only tweak — use `libraries-extend` (preferred)
Adds a supplementary CSS file to the component's existing library without duplicating the bundle:

```yaml
# performant_labs_20260418.libraries.yml — add the override library definition
hero-override:
  css:
    component:
      css/components/hero.css: {}
```

```yaml
# performant_labs_20260418.info.yml — extend the component library
libraries-extend:
  core/components.neonbyte--hero:
    - performant_labs_20260418/hero-override
```

### Twig or structural override — copy the component bundle
Required when markup, slots, or schema must change:

```
themes/custom/performant_labs_20260418/
  components/
    [component-name]/
      [component-name].component.yml   ← always copy — omitting breaks schema validation
      [component-name].twig            ← only if markup changes are needed
      css/[component-name].css         ← only if CSS changes are needed
```

> ⚠️ Always copy `.component.yml` even for Twig-only overrides. Omitting it breaks schema validation silently.

---

## Verification (per component)

| Tier | Method | Pass condition |
|---|---|---|
| T1 — Route | `curl -sk https://..../styleguide/explorer` | HTTP `200` or `403` (auth-gated) |
| T2 — Explorer | Load component in explorer with props filled | Component renders without PHP/Twig errors |
| T3 — Visual | Screenshot or visual inspection in explorer | Brand colours, radius, spacing match intent |

---

## Stage Complete → Proceed to Stage 3

When all priority components pass T2 + T3 in the explorer, proceed to:

**[`neonbyte-plan--pages.md`](neonbyte-plan--pages.md)** — Page composition
