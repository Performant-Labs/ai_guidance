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

REPO_ROOT="$(cd "$TARGET" && pwd)"
BRIDGE="$REPO_ROOT/.claude-bridge"
mkdir -p "$BRIDGE"

# Clean any stale results from a previous run so Claude doesn't read them.
stale_count=$(ls "$BRIDGE"/res-*.out "$BRIDGE"/res-*.exit 2>/dev/null | wc -l | tr -d ' ')
rm -f "$BRIDGE"/res-*.out "$BRIDGE"/res-*.exit 2>/dev/null

# --- Banner ---
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║  Claude bridge                                                   ║${NC}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo -e "${GRAY}Lets Claude's sandboxed agent run host commands (ddev, drush, git,${NC}"
echo -e "${GRAY}curl, headless Chrome) by dropping shell scripts in .claude-bridge/.${NC}"
echo -e "${GRAY}This watcher polls that directory once per second and executes any${NC}"
echo -e "${GRAY}request it finds, writing the combined output + exit code back for${NC}"
echo -e "${GRAY}the agent to read. Leave this terminal open while collaborating.${NC}"
echo
echo -e "  ${BOLD}watching:${NC}       $REPO_ROOT"
echo -e "  ${BOLD}spool:${NC}          $BRIDGE"
echo -e "  ${BOLD}command cwd:${NC}    $REPO_ROOT"
if [ "$stale_count" -gt 0 ]; then
  echo -e "  ${YELLOW}cleared $stale_count stale response file(s) from the last run${NC}"
fi
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
