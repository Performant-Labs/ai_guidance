#!/bin/bash

# AI Guidance Alignment Tool (Gemini-Powered)
# Follows the AI Guidance Alignment Protocol

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# --- Load Configuration ---
CONFIG_FILE="$(dirname "$0")/guidance-align.env"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    # Fallback defaults
    CANONICAL_SOURCE="$HOME/Sites/ai_guidance"
fi

SOURCE_DIR="$CANONICAL_SOURCE"
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

# --- Pre-flight Checks ---
if [ -z "$PROJECT_ROOT" ]; then
    echo -e "${RED}🚨 Error: Must be run inside a git repository.${NC}"
    exit 1
fi

TARGET_DIR="$PROJECT_ROOT/docs/ai_guidance"
PROTOCOL_FILE="$PROJECT_ROOT/docs/admin_tools/guidance-alignment-protocol.md"

if ! command -v gemini &> /dev/null; then
    echo -e "${RED}🚨 Error: 'gemini' CLI is not installed.${NC}"
    echo -e "${YELLOW}Setup Instructions: brew install geminicli && gemini login${NC}"
    exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}🚨 Error: Source repository not found at $SOURCE_DIR${NC}"
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}🚨 Error: Target directory $TARGET_DIR not found.${NC}"
    exit 1
fi

echo -e "${CYAN}🔍 Running AI Guidance Alignment Analysis...${NC}"

# Run deterministic comparison
DIFF_OUTPUT=$(diff -rq "$TARGET_DIR" "$SOURCE_DIR" --exclude='.git' 2>&1)

if [ -z "$DIFF_OUTPUT" ]; then
    echo -e "${GREEN}✅ Everything is in sync.${NC}"
    exit 0
fi

# --- Generate the Protocol-compliant Numbered List ---
echo -e "${YELLOW}Divergences Found (Relative to Project Root):${NC}"
REPORT=""
i=1
while read -r line; do
    [ -z "$line" ] && continue
    
    ACTION=""
    REL_PATH_IN_TARGET=""
    COLOR=$NC
    
    if [[ $line == Only\ in\ $TARGET_DIR* ]]; then
        DIR_PART=$(echo "$line" | cut -d: -f1 | sed "s|Only in ||")
        FILE_PART=$(echo "$line" | cut -d: -f2 | sed 's|^ ||')
        [ "$DIR_PART" == "$TARGET_DIR" ] && REL_PATH_IN_TARGET="$FILE_PART" || REL_PATH_IN_TARGET="${DIR_PART#$TARGET_DIR/}/$FILE_PART"
        ACTION="push"
        COLOR=$GREEN
    elif [[ $line == Only\ in\ $SOURCE_DIR* ]]; then
        DIR_PART=$(echo "$line" | cut -d: -f1 | sed "s|Only in ||")
        FILE_PART=$(echo "$line" | cut -d: -f2 | sed 's|^ ||')
        [ "$DIR_PART" == "$SOURCE_DIR" ] && REL_PATH_IN_TARGET="$FILE_PART" || REL_PATH_IN_TARGET="${DIR_PART#$SOURCE_DIR/}/$FILE_PART"
        ACTION="pull"
        COLOR=$YELLOW
    elif [[ $line == Files\ *differ ]]; then
        FILE1=$(echo "$line" | awk '{print $2}')
        REL_PATH_IN_TARGET=${FILE1#$TARGET_DIR/}
        ACTION="merge"
        COLOR=$MAGENTA
    fi
    
    DISPLAY_PATH="docs/ai_guidance/$REL_PATH_IN_TARGET"
    ITEM="$i. $DISPLAY_PATH — [Suggestion: $ACTION]"
    echo -e "  $i. $DISPLAY_PATH — [Suggestion: ${COLOR}${ACTION}${NC}]"
    REPORT+="$ITEM\n"
    ((i++))
done <<< "$DIFF_OUTPUT"

echo -e "${YELLOW}------------------------------------------------${NC}"

# Ask for decision BEFORE calling Gemini
echo -e "How should we proceed? (Apply all suggestions [all] / Select individual options [provide # then <pull|push|merge|skip>] / [quit])"
read -p "> " USER_INPUT

if [ -z "$USER_INPUT" ] || [[ "$USER_INPUT" == "quit" ]] || [[ "$USER_INPUT" == "q" ]]; then
    echo "Aborted."
    exit 0
fi

# Prepare the prompt using a heredoc to avoid syntax errors with special characters
read -r -d '' PROMPT <<EOF
I have performed a deterministic alignment check. 
Target: $TARGET_DIR
Source: $SOURCE_DIR

User Decision: $USER_INPUT

Here is the full Analysis Report:
$REPORT

Please execute the requested actions. 
- For 'pull': Copy from Source to Target.
- For 'push': Copy from Target to Source.
- For 'merge': Use your intelligence to merge the contents bidirectionally as appropriate.
- For 'skip': Do nothing for that item.

**Special Intelligence Rule**: If you detect 'Near-Matches' (e.g., the same file with different casing or separators), recommend standardizing on the Source filename and merging the content into that single file.

Do not perform any new analysis; just execute the plan based on the report provided.
EOF

# Construct gemini command
GEMINI_CMD="gemini -y --approval-mode yolo"
if [ -n "$GEMINI_MODEL" ]; then
    GEMINI_CMD="$GEMINI_CMD -m \"$GEMINI_MODEL\""
fi

# Invoke Gemini in non-interactive (headless) mode
eval "$GEMINI_CMD -p \"\$PROMPT\""
