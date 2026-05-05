#!/usr/bin/env bash
#
# install.sh — Symlink the ai_guidance source repo into docs/ai_guidance/
#              of the current host project.
#
# Run from the root of the host project (the repo whose AI agents need
# access to these rules). Idempotent — safe to re-run.
#
# Override the source path with AI_GUIDANCE_SRC if you keep the source repo
# somewhere other than ~/Projects/ai_guidance.
#
#   ~/Projects/ai_guidance/setup/install.sh
#   AI_GUIDANCE_SRC=~/code/ai_guidance ~/Projects/ai_guidance/setup/install.sh

set -euo pipefail

SRC="${AI_GUIDANCE_SRC:-$HOME/Projects/ai_guidance}"
DEST="docs/ai_guidance"
GITIGNORE_LINE="docs/ai_guidance"

# ─── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; DIM='\033[2m'; RESET='\033[0m'

err()  { printf "${RED}error:${RESET} %s\n" "$*" >&2; }
ok()   { printf "${GREEN}ok:${RESET}    %s\n" "$*"; }
info() { printf "${CYAN}info:${RESET}  %s\n" "$*"; }
dim()  { printf "${DIM}%s${RESET}\n"     "$*"; }

# ─── Sanity checks ───────────────────────────────────────────────────────────
if [[ ! -d "$SRC" ]]; then
  err "source repo not found at: $SRC"
  err "clone it first, or set AI_GUIDANCE_SRC to its actual path"
  exit 1
fi

if [[ ! -f "$SRC/TROUBLESHOOTING.md" || ! -f "$SRC/README.md" ]]; then
  err "$SRC does not look like an ai_guidance checkout"
  err "expected to find TROUBLESHOOTING.md and README.md inside it"
  exit 1
fi

if [[ ! -d ".git" ]]; then
  err "not in a git repository (no .git directory here)"
  err "run this from the host project's root"
  exit 1
fi

# ─── Create the parent docs/ if needed ───────────────────────────────────────
mkdir -p "$(dirname "$DEST")"

# ─── Create or repair the symlink ────────────────────────────────────────────
if [[ -L "$DEST" ]]; then
  current_target="$(readlink "$DEST")"
  if [[ "$current_target" == "$SRC" ]]; then
    ok "symlink already correct: $DEST -> $SRC"
  else
    info "replacing existing symlink (was: $current_target)"
    rm "$DEST"
    ln -s "$SRC" "$DEST"
    ok "symlink: $DEST -> $SRC"
  fi
elif [[ -e "$DEST" ]]; then
  err "$DEST exists but is not a symlink"
  err "back up or remove the existing path manually, then re-run"
  exit 1
else
  ln -s "$SRC" "$DEST"
  ok "symlink: $DEST -> $SRC"
fi

# ─── Add to .gitignore (idempotent) ──────────────────────────────────────────
if [[ -f .gitignore ]] && grep -qxF "$GITIGNORE_LINE" .gitignore; then
  dim ".gitignore already excludes $GITIGNORE_LINE"
else
  echo "$GITIGNORE_LINE" >> .gitignore
  ok "added $GITIGNORE_LINE to .gitignore"
fi

# ─── Verify ──────────────────────────────────────────────────────────────────
echo ""
info "verify with:"
dim "  ls -la $DEST"
dim "  cat $DEST/TROUBLESHOOTING.md | head -20"
