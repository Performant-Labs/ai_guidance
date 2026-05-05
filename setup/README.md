# Symlink Setup for `ai_guidance`

When `ai_guidance` is consumed by another project, the host project exposes
the rules to its AI agents by **symlinking** the source repo into
`docs/ai_guidance/`.

This page documents the one-line setup, how to verify it, and how to recover
if the symlink breaks.

## One-line setup

From the **root of the host project** (the repo whose AI agents need access
to these rules):

```bash
ln -s ~/Projects/ai_guidance docs/ai_guidance
```

Then add the path to `.gitignore` so the link itself isn't committed:

```bash
echo "docs/ai_guidance" >> .gitignore
```

## Verify it worked

```bash
ls -la docs/ai_guidance
# Expected: starts with `lrwxr-xr-x` and shows `-> /Users/<you>/Projects/ai_guidance`

ls docs/ai_guidance/TROUBLESHOOTING.md
# Should show the file (proves the target is reachable through the symlink)
```

## Helper script

`setup/install.sh` automates the same two steps and adds an idempotent check
(it skips if a symlink already exists at the target path):

```bash
# From the host project root
~/Projects/ai_guidance/setup/install.sh
```

The script will:
1. Verify `~/Projects/ai_guidance` exists and looks like a valid clone.
2. Create the `docs/ai_guidance` symlink (or skip if already correct).
3. Add `docs/ai_guidance` to `.gitignore` if not already present.
4. Print the verification commands so you can confirm it worked.

Override the source path with the `AI_GUIDANCE_SRC` environment variable if
you keep this repo somewhere other than `~/Projects/ai_guidance`:

```bash
AI_GUIDANCE_SRC=~/code/ai_guidance ~/Projects/ai_guidance/setup/install.sh
```

## Updating the rules

There is nothing to "update." Because the host project's `docs/ai_guidance/`
is a live link to the source repo, any change you make in the source is
visible immediately in every linked host project.

To pull in changes from collaborators:

```bash
cd ~/Projects/ai_guidance
git pull
```

All host projects on this machine see the result instantly.

## Recovering from a broken symlink

If files appear missing or stale, see [`git/TROUBLESHOOTING.md`](../git/TROUBLESHOOTING.md) §3.1
("Symlink synchronization") for diagnosis and the recovery commands.

## Why not `git subtree`?

Earlier versions of this project distributed the guidance using `git subtree`.
That required every host project to remember to run `ai:pull` periodically,
and uncommitted edits in the source repo were invisible downstream until
pushed. The current symlink approach is simpler and always live.

## Prerequisites

| Tool | Required | Notes |
|------|----------|-------|
| **git** | ✅ | To clone this repo to its canonical local path |
| Symlink-capable filesystem | ✅ | Default on macOS and Linux. Windows requires Developer Mode or admin shell |
