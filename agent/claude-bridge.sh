#!/usr/bin/env bash
# Claude command bridge — run on the host in a dedicated terminal.
#
# Canonical location: ~/Sites/ai_guidance/agent/claude-bridge.sh
#
# Watches the CURRENT repo (or an explicit target passed as $1) for request
# scripts dropped by a sandboxed Claude agent into .claude-bridge/req-<id>.sh.
# Each request is executed on the host (so ddev, drush, git, curl, headless
# Chrome all work), and the combined stdout+stderr + exit code are written
# back into the same directory for the agent to poll.
#
# Usage:
#   cd ~/Projects/<repo> && ~/Sites/ai_guidance/agent/claude-bridge.sh
#   # or, with an explicit target:
#   ~/Sites/ai_guidance/agent/claude-bridge.sh ~/Projects/<repo>
#
# Ctrl-C to stop at any time. Safe to re-start.
#
# Security: this executes ARBITRARY shell commands from Claude with your
# user's privileges. Only run while actively collaborating.

set -u

# --- Color definitions (match ~/Sites/ai_guidance/admin_tools/guidance-align.sh) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

# If stdout isn't a TTY (piped, captured to file), strip colors so logs stay clean.
if [ ! -t 1 ]; then
  RED=''; GREEN=''; YELLOW=''; CYAN=''; MAGENTA=''; GRAY=''; BOLD=''; NC=''
fi

# --- Target repo resolution ---
# 1) If a path is passed as $1, use it.
# 2) Otherwise, use the current working directory.
# NOT the script's own directory — this watcher lives in ai_guidance/agent/
# and must watch OTHER repos.
TARGET="${1:-$PWD}"

if [ ! -d "$TARGET" ]; then
  echo -e "${RED}✗ Error:${NC} target directory does not exist: $TARGET" >&2
  echo -e "  ${GRAY}Usage:${NC} cd <repo> && $(basename "$0")" >&2
  echo -e "  ${GRAY}   or:${NC} $(basename "$0") <path-to-repo>" >&2
  exit 1
fi

# Target must be a git repo. This catches the common footgun of invoking
# the watcher from the home directory without cd'ing first — the watcher
# would otherwise happily poll ~/.claude-bridge/ and miss every project
# request. If you genuinely need to run against a non-repo dir, create an
# empty .git/ first (not recommended) or bypass by editing this check.
if ! git -C "$TARGET" rev-parse --git-dir > /dev/null 2>&1; then
  echo -e "${RED}✗ Error:${NC} target is not a git repository: $TARGET" >&2
  echo -e "  ${GRAY}(no .git/ found; probably means you ran this from \$HOME${NC}" >&2
  echo -e "  ${GRAY} instead of cd'ing into your project first.)${NC}" >&2
  echo -e "  ${GRAY}Usage:${NC} cd <repo> && $(basename "$0")" >&2
  echo -e "  ${GRAY}   or:${NC} $(basename "$0") <path-to-repo>" >&2
  exit 1
fi

REPO_ROOT="$(cd "$TARGET" && pwd)"
BRIDGE="$REPO_ROOT/.claude-bridge"
mkdir -p "$BRIDGE"

# Clean any stale results from a previous run so Claude doesn't read them.
stale_count=$(ls "$BRIDGE"/res-*.out "$BRIDGE"/res-*.exit 2>/dev/null | wc -l | tr -d ' ')
rm -f "$BRIDGE"/res-*.out "$BRIDGE"/res-*.exit 2>/dev/null

# --- Status gathering for the launch banner ---
PROJECT_NAME="$(basename "$REPO_ROOT")"

# Git branch + dirty state (the watcher already validated this is a git repo)
GIT_BRANCH="$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null)"
[ -z "$GIT_BRANCH" ] && GIT_BRANCH="(detached HEAD)"
if git -C "$REPO_ROOT" diff --quiet 2>/dev/null && git -C "$REPO_ROOT" diff --cached --quiet 2>/dev/null; then
  GIT_STATE="${GREEN}clean${NC}"
else
  GIT_STATE="${YELLOW}dirty${NC}"
fi

# Origin sync state (if there's an upstream and a recent fetch)
GIT_SYNC=""
if git -C "$REPO_ROOT" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
  ahead_behind="$(git -C "$REPO_ROOT" rev-list --left-right --count '@{u}'...HEAD 2>/dev/null)"
  behind="$(echo "$ahead_behind" | awk '{print $1}')"
  ahead="$(echo "$ahead_behind" | awk '{print $2}')"
  if [ "${behind:-0}" = "0" ] && [ "${ahead:-0}" = "0" ]; then
    GIT_SYNC="${GREEN}in sync${NC}"
  elif [ "${behind:-0}" != "0" ] && [ "${ahead:-0}" = "0" ]; then
    GIT_SYNC="${YELLOW}behind by ${behind}${NC}"
  elif [ "${behind:-0}" = "0" ] && [ "${ahead:-0}" != "0" ]; then
    GIT_SYNC="${BLUE}ahead by ${ahead}${NC}"
  else
    GIT_SYNC="${YELLOW}diverged: -${behind} +${ahead}${NC}"
  fi
else
  GIT_SYNC="${GRAY}no upstream${NC}"
fi

# Pending request count (a watcher restart inherits whatever was queued)
PENDING_COUNT=$(ls "$BRIDGE"/req-*.sh 2>/dev/null | wc -l | tr -d ' ')
if [ "$PENDING_COUNT" -gt 0 ]; then
  PENDING_FMT="${YELLOW}${PENDING_COUNT}${NC} ${GRAY}queued from prior session — will run on next loop iteration${NC}"
else
  PENDING_FMT="${GRAY}none${NC}"
fi

# gh CLI auth status (one-line, doesn't block on slow network beyond ~1s)
if command -v gh >/dev/null 2>&1; then
  GH_USER=$(timeout 3 gh api user --jq .login 2>/dev/null)
  if [ -n "$GH_USER" ]; then
    GH_STATUS="${GREEN}✓${NC} ${BOLD}${GH_USER}${NC}"
  else
    GH_STATUS="${RED}✗ not authenticated${NC} ${GRAY}(some bridged commands will fail)${NC}"
  fi
else
  GH_STATUS="${GRAY}gh CLI not installed${NC}"
fi

# Watcher process metadata
WATCHER_PID=$$
WATCHER_START="$(date '+%Y-%m-%d %H:%M:%S')"

# --- Banner ---
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║  Claude bridge                                                   ║${NC}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "  ${BOLD}Project${NC}        ${MAGENTA}${BOLD}${PROJECT_NAME}${NC}"
echo
echo -e "  ${BOLD}watching${NC}       ${CYAN}${REPO_ROOT}${NC}"
echo -e "  ${BOLD}spool${NC}          ${CYAN}${BRIDGE}${NC}"
echo -e "  ${BOLD}branch${NC}         ${BOLD}${GIT_BRANCH}${NC} (${GIT_STATE})"
echo -e "  ${BOLD}origin${NC}         ${GIT_SYNC}"
echo -e "  ${BOLD}gh auth${NC}        ${GH_STATUS}"
echo -e "  ${BOLD}pending${NC}        ${PENDING_FMT}"
if [ "$stale_count" -gt 0 ]; then
  echo -e "  ${BOLD}stale res${NC}      ${YELLOW}cleared ${stale_count} response file(s) from prior run${NC}"
fi
echo -e "  ${BOLD}watcher${NC}        ${GRAY}PID ${WATCHER_PID}, started ${WATCHER_START}${NC}"
echo
echo -e "${GRAY}Drops scripts in ${BRIDGE} get executed on the host with full user${NC}"
echo -e "${GRAY}privileges (gh, ddev, drush, git, curl, etc.). Output streams back as${NC}"
echo -e "${GRAY}res-<id>.out + res-<id>.exit for the sandboxed agent to poll. Leave this${NC}"
echo -e "${GRAY}terminal open while collaborating.${NC}"
echo
echo -e "${YELLOW}⚠  Security:${NC} this runs arbitrary shell commands as your user."
echo -e "   Only run while actively collaborating. ${BOLD}Ctrl-C${NC} to stop."
echo
echo -e "${GRAY}Waiting for requests...${NC}"
echo

cd "$REPO_ROOT"

while true; do
  # Glob may expand to the literal pattern if nothing matches — guard with nullglob.
  shopt -s nullglob
  for req in "$BRIDGE"/req-*.sh; do
    id="${req##*/req-}"; id="${id%.sh}"

    # Request metadata for the log
    req_lines=$(wc -l < "$req" | tr -d ' ')
    req_bytes=$(wc -c < "$req" | tr -d ' ')
    # First non-empty, non-shebang, non-comment line — more useful than `head -1`
    hint="$(grep -v -E '^\s*(#|$)' "$req" | head -n 1 | tr -d '\r' | cut -c1-76)"
    [ -z "$hint" ] && hint="$(head -n 1 "$req" | tr -d '\r' | cut -c1-76)"

    ts_start="$(date +%H:%M:%S)"
    epoch_start=$(date +%s)

    echo -e "${CYAN}┌─ [$ts_start] ▶ req-$id${NC}  ${GRAY}($req_lines lines, $req_bytes bytes)${NC}"
    echo -e "${CYAN}│${NC}  ${GRAY}hint:${NC} $hint"
    echo -e "${CYAN}│${NC}  ${GRAY}running...${NC}"

    # Run in the repo root. Use bash to honor shebang-less scripts.
    bash "$req" > "$BRIDGE/res-$id.out" 2>&1
    exit_code=$?
    echo "$exit_code" > "$BRIDGE/res-$id.exit"
    rm -f "$req"

    # Result metadata
    res_bytes=$(wc -c < "$BRIDGE/res-$id.out" | tr -d ' ')
    res_lines=$(wc -l < "$BRIDGE/res-$id.out" | tr -d ' ')
    ts_end="$(date +%H:%M:%S)"
    epoch_end=$(date +%s)
    elapsed=$((epoch_end - epoch_start))

    if [ "$exit_code" -eq 0 ]; then
      echo -e "${CYAN}└─ [$ts_end] ${GREEN}✓ res-$id${NC}  ${GRAY}exit=$exit_code  ${res_bytes}b / ${res_lines} lines  ${elapsed}s${NC}"
    else
      echo -e "${CYAN}└─ [$ts_end] ${RED}✗ res-$id${NC}  ${RED}exit=$exit_code${NC}  ${GRAY}${res_bytes}b / ${res_lines} lines  ${elapsed}s${NC}"
      # On failure, show the last few lines of output so the operator sees why
      echo -e "${GRAY}   last output:${NC}"
      tail -n 4 "$BRIDGE/res-$id.out" | sed "s/^/   │ /"
    fi
    echo
  done
  shopt -u nullglob
  sleep 1
done
