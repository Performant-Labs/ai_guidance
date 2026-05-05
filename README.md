# AI Guidance

A centralized **source-of-truth constraint system and runbook** for AI developer agents at Performant Labs. It defines standard operating procedures, browser constraints, troubleshooting solutions, and codebase rules that AI agents adhere to before taking execution actions across our ecosystem.

## Repository Structure

```
ai_guidance/
├── admin_tools/             # Subtree sync + alignment tooling (guidance:pull, guidance:push, guidance:align)
├── agent/                   # Generic AI agent rules & SOPs
│   ├── browser-constraints.md
│   ├── claude-bridge.md     # File-drop protocol for host-only command execution
│   ├── claude-bridge.sh
│   ├── minimax-m2.5-runpod-setup-plan.md
│   ├── naming.md            # Naming conventions
│   ├── pr-agent-setup.md
│   ├── qwen3-vllm-runpod-runbook.md
│   ├── technical-writing.md
│   └── troubleshooting.md
├── developer_setup/         # Workstation setup recipes
│   ├── vscode-family-ide.md # VS Code / Cursor / Windsurf / Antigravity settings
│   └── zsh-prompt.md
├── frameworks/
│   ├── better-auth/         # Better Auth setup, API tokens, route protection
│   ├── docker/              # Container conventions
│   ├── drupal/              # Drupal best practices, theming guides, agent rules
│   ├── fastify/             # Fastify + TypeScript + Zod conventions
│   ├── htmx/                # HTMX + Alpine.js + Eta conventions
│   ├── mikro-orm/           # MikroORM v7 dual-dialect (PostgreSQL + SQLite)
│   ├── tailwind/            # Tailwind CSS v4 + Flowbite conventions
│   ├── vitest/              # Vitest unit + integration testing patterns
│   └── vue/                 # Vue 3 + TypeScript + Composition API
├── languages/               # Language-level conventions (vs framework-level above)
│   ├── css/                 # CSS change workflow + design-token discipline
│   └── go/                  # Go testing conventions
├── projects/
│   └── opencloud/           # Project-specific planning docs
├── snippets/                # Reusable code snippets
├── testing/                 # Cross-stack testing strategy (3-tier verification, VR)
└── themes/                  # Shared Drupal themes (neonbyte, dripyard_base)
```

## How It Integrates with Host Projects

This repository is distributed into host projects (e.g. `pl-atk`, `opencloud-voting`) using **Git Subtrees** — not Git Submodules.

This ensures:
1. No `--recursive` clones required for external contributors.
2. Rules exist **physically** inside the host project (e.g. `docs/ai_guidance/`) — fully visible to AI agents at runtime.
3. Local edits discovered inside host projects can be pushed upstream cleanly without managing symlinks.

The standard mount point in host projects is:

```
docs/ai_guidance/
```

---

## Synchronizing Rules (Git Subtree)

### Pull the Latest (Sync Down)

Run from the **host project root**:

```bash
git subtree pull --prefix=docs/ai_guidance git@github.com:Performant-Labs/ai_guidance.git main --squash
```

### Publish Local Discoveries (Sync Up)

```bash
git subtree push --prefix=docs/ai_guidance git@github.com:Performant-Labs/ai_guidance.git main
```

> **Warning:** Always pull before pushing to avoid complex subtree merge-conflict histories.

---

## One-Touch CLI Automation (Recommended)

The [`admin_tools/`](admin_tools/) directory contains the canonical sync tooling: `guidance:pull`, `guidance:push`, and `guidance:align`. These are Python scripts with a custom shebang so `uv run` invokes them natively. See [`admin_tools/README.md`](admin_tools/README.md) for full setup.

### Quick Setup

Add `admin_tools/` to your `PATH` in `~/.zshrc`:

```bash
# --- AI Guidance Global Tools ---
export PATH="$HOME/Sites/ai_guidance/admin_tools:$PATH"
```

After modifying your `.zshrc`, run `source ~/.zshrc`. You can now run `guidance:pull` and `guidance:push` from any host project.

### Usage

| Command | What it does |
|---------|-------------|
| `guidance:pull` | Pulls latest from `Performant-Labs/ai_guidance` into `docs/ai_guidance/` (squash merge); summarizes the diff via Claude/OpenRouter |
| `guidance:push` | Pushes local changes back upstream |
| `guidance:align` | Syncs project-specific `ai_guidance` docs against the canonical Performant Labs standards (see [`admin_tools/guidance-alignment-protocol.md`](admin_tools/guidance-alignment-protocol.md)) |

### Prerequisites

| Tool | Required | Install |
|------|----------|---------|
| **git** | ✅ | Xcode CLT or [git-scm.com](https://git-scm.com/) |
| **uv** | ✅ | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| **Claude CLI** | Optional | `npm install -g @anthropic-ai/claude-code` → `claude` → `/login` |

---

## Key Documentation

### Cross-stack agent rules
| File | Purpose |
|------|---------|
| [`agent/troubleshooting.md`](agent/troubleshooting.md) | Master catalog of known issues, hangs, and gotchas |
| [`agent/browser-constraints.md`](agent/browser-constraints.md) | Headless browser priority rules |
| [`agent/claude-bridge.md`](agent/claude-bridge.md) | File-drop protocol for running host-only commands (ddev, drush, curl, Chrome) from a sandboxed agent |
| [`agent/naming.md`](agent/naming.md) | Naming conventions (kebab-case, file taxonomy) |
| [`agent/pr-agent-setup.md`](agent/pr-agent-setup.md) | Guide to setting up Qodo PR-Agent as a Spec-enforcer |
| [`agent/technical-writing.md`](agent/technical-writing.md) | Documentation style guide |

### Cross-stack testing strategy
| File | Purpose |
|------|---------|
| [`testing/verification-cookbook.md`](testing/verification-cookbook.md) | The Three-Tier Verification Hierarchy (Tier 1 headless → Tier 2 ARIA → Tier 3 visual) |
| [`testing/visual-regression-strategy.md`](testing/visual-regression-strategy.md) | Tier 3 budget rules, pre-condition ladder, gate cadence |
| [`testing/agent-failure-log.md`](testing/agent-failure-log.md) | Running log of agent-side test failures and root causes |

### Language-level guidance
| File | Purpose |
|------|---------|
| [`languages/css/css-change-workflow.md`](languages/css/css-change-workflow.md) | 7-step workflow for making CSS changes at the correct layer (5-layer token hierarchy + DOM-inspection gate) |
| [`languages/go/testing.md`](languages/go/testing.md) | Go testing conventions (file placement, naming, build tags) |

### Framework conventions
| File | Purpose |
|------|---------|
| [`frameworks/vue/conventions.md`](frameworks/vue/conventions.md) | Vue 3 + TypeScript + Composition API |
| [`frameworks/vitest/conventions.md`](frameworks/vitest/conventions.md) | Vitest unit + integration patterns; in-memory test doubles |
| [`frameworks/tailwind/conventions.md`](frameworks/tailwind/conventions.md) | Tailwind CSS v4 (CSS-first `@theme` + `@layer components`) + Flowbite |
| [`frameworks/fastify/conventions.md`](frameworks/fastify/conventions.md) | Fastify + TypeScript + Zod conventions |
| [`frameworks/mikro-orm/conventions.md`](frameworks/mikro-orm/conventions.md) | MikroORM v7 dual-dialect (PostgreSQL + SQLite) |
| [`frameworks/better-auth/conventions.md`](frameworks/better-auth/conventions.md) | Better Auth setup, API tokens, route protection |
| [`frameworks/htmx/conventions.md`](frameworks/htmx/conventions.md) | HTMX + Alpine.js + Eta conventions |
| [`frameworks/docker/conventions.md`](frameworks/docker/conventions.md) | Docker container conventions |
| [`frameworks/drupal/best-practices.md`](frameworks/drupal/best-practices.md) | Drupal development best practices |
| [`frameworks/drupal/agents.md`](frameworks/drupal/agents.md) | Drupal-specific agent runbook (DDEV, Drush, config workflow) |

### Workstation setup
| File | Purpose |
|------|---------|
| [`developer_setup/vscode-family-ide.md`](developer_setup/vscode-family-ide.md) | VS Code / Cursor / Windsurf / Antigravity settings + keybindings |
| [`developer_setup/zsh-prompt.md`](developer_setup/zsh-prompt.md) | Zsh prompt recipes |

---

## License

Content in this repository is proprietary to Performant Labs unless otherwise noted.
