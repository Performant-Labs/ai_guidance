# AI Guidance

This repository is a centralized "source of truth" constraint-system and
runbook for AI developer agents. It defines [browser constraints](browser/CONSTRAINTS.md),
standard operating procedures, [troubleshooting](TROUBLESHOOTING.md) for known
hang conditions, and codebase rules that AIs must adhere to before taking
execution actions in our ecosystem.

## How host projects consume it

Host projects (e.g. `opencloud-voting`, `pl-opensocial`, `AlmondTTS`) expose
this guidance to their AI agents by **symlinking** this repository into their
own `docs/ai_guidance/` directory:

```bash
# From the host project's root
ln -s ~/Projects/ai_guidance docs/ai_guidance
```

That's it. There is no copy, no fetch, no pull. Edits made in this repository
are visible **instantly** in every host project that links to it — there is
nothing to synchronize.

### Why symlinks?

Earlier versions of this project distributed the guidance via `git subtree`.
That worked but introduced a synchronization burden — every host project had
to remember to `subtree pull` to receive new rules, and uncommitted edits in
the source repo were invisible downstream until pushed. Symlinks remove the
problem entirely: the host project always sees the live state of the source.

The trade-off: each developer machine must have the source repo cloned at a
known path before the symlink resolves. The host project's `.gitignore` should
exclude the `docs/ai_guidance` path so the link itself isn't committed.

## Setting up a host project

The first time a host project gains AI-guidance access:

1. Clone this repository to a stable path (recommended: `~/Projects/ai_guidance`).
2. From the host project root: `ln -s ~/Projects/ai_guidance docs/ai_guidance`.
3. Add `docs/ai_guidance` to the host's `.gitignore`.
4. Verify: `ls -la docs/ai_guidance` should show a symlink (`l` first character).

See [`setup/README.md`](setup/README.md) for the full setup guide and the
optional helper script.

## Updating the rules

Because every host project sees the live source via symlink, updating is just:

```bash
cd ~/Projects/ai_guidance
# edit, commit, push
git push
```

All host projects on this machine see the change immediately. Other machines
pull it with `git pull` from inside the source repo.

## Repository layout

```
ai_guidance/
├── README.md                         ← this file
├── TROUBLESHOOTING.md                ← topic index for troubleshooting docs
├── NAMING.md                         ← contextual nomenclature standards
├── browser/CONSTRAINTS.md            ← headless-priority browser rule
├── ddev/TROUBLESHOOTING.md           ← DDEV-specific issues
├── drupal/TROUBLESHOOTING.md         ← Drupal-specific issues
├── git/TROUBLESHOOTING.md            ← Git pager / multi-repo / symlink issues
├── go/TESTING.md                     ← Go test conventions
├── ide/SETTINGS.md                   ← VS Code-based editor settings
├── playwright/TROUBLESHOOTING.md     ← Playwright E2E issues
├── process/TROUBLESHOOTING.md        ← Orphan processes, agent gates
├── projects/opencloud/PLAN_INSTRUCTIONS.md
├── setup/README.md                   ← Symlink setup helper
├── technical_writing/documentation_guidance.md
└── vue/CONVENTIONS.md                ← Vue 3 development conventions
```

When adding a new topic of guidance, create a new top-level directory named
after the technology and place the rule document inside it
(e.g. `python/CONVENTIONS.md`).
