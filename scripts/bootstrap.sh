#!/bin/bash
# Claude Code Intelligence Kit — Bootstrap Script
#
# Run this from your project root to initialize the memory system.
# Usage: ../claude-code-intelligence/scripts/bootstrap.sh
#    or: /path/to/claude-code-intelligence/scripts/bootstrap.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KIT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

echo "Claude Code Intelligence Kit — Bootstrap"
echo "========================================="
echo ""
echo "Project: $PROJECT_NAME"
echo "Directory: $PROJECT_DIR"
echo ""

# --- Step 1: Create CLAUDE.md if it doesn't exist ---
if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
    echo "[skip] CLAUDE.md already exists"
else
    cp "$KIT_DIR/templates/CLAUDE.md" "$PROJECT_DIR/CLAUDE.md"
    # Replace placeholder with project name
    sed -i.bak "s/\[Project Name\]/$PROJECT_NAME/g" "$PROJECT_DIR/CLAUDE.md" 2>/dev/null || \
    sed -i '' "s/\[Project Name\]/$PROJECT_NAME/g" "$PROJECT_DIR/CLAUDE.md"
    rm -f "$PROJECT_DIR/CLAUDE.md.bak"
    echo "[created] CLAUDE.md — fill in your project's commands, patterns, and gotchas"
fi

# --- Step 2: Create PROJECT_STATE.md if it doesn't exist ---
if [ -f "$PROJECT_DIR/PROJECT_STATE.md" ]; then
    echo "[skip] PROJECT_STATE.md already exists"
else
    cp "$KIT_DIR/templates/PROJECT_STATE.md" "$PROJECT_DIR/PROJECT_STATE.md"
    sed -i.bak "s/\[Project Name\]/$PROJECT_NAME/g" "$PROJECT_DIR/PROJECT_STATE.md" 2>/dev/null || \
    sed -i '' "s/\[Project Name\]/$PROJECT_NAME/g" "$PROJECT_DIR/PROJECT_STATE.md"
    # Replace [date] with today's date
    TODAY=$(date +%Y-%m-%d)
    sed -i.bak "s/\[date\]/$TODAY/g" "$PROJECT_DIR/PROJECT_STATE.md" 2>/dev/null || \
    sed -i '' "s/\[date\]/$TODAY/g" "$PROJECT_DIR/PROJECT_STATE.md"
    rm -f "$PROJECT_DIR/PROJECT_STATE.md.bak"
    echo "[created] PROJECT_STATE.md — describe where the project stands"
fi

# --- Step 3: Determine memory directory ---
# Claude Code stores per-project memory at:
#   ~/.claude/projects/<encoded-project-path>/memory/
# We'll also create a local .claude/memory/ for reference

# Find the Claude projects directory
CLAUDE_DIR="$HOME/.claude"
if [ -d "$CLAUDE_DIR" ]; then
    # Encode project path (replace / with -)
    ENCODED_PATH=$(echo "$PROJECT_DIR" | sed 's|^/||' | sed 's|/|-|g')
    MEMORY_DIR="$CLAUDE_DIR/projects/-$ENCODED_PATH/memory"
else
    # Fallback: use local directory
    MEMORY_DIR="$PROJECT_DIR/.claude/memory"
fi

echo ""
echo "Memory directory: $MEMORY_DIR"

# --- Step 4: Create memory directory and files ---
mkdir -p "$MEMORY_DIR"

if [ -f "$MEMORY_DIR/MEMORY.md" ]; then
    echo "[skip] MEMORY.md already exists"
else
    cp "$KIT_DIR/templates/.claude/memory/MEMORY.md" "$MEMORY_DIR/MEMORY.md"
    sed -i.bak "s/\[Project Name\]/$PROJECT_NAME/g" "$MEMORY_DIR/MEMORY.md" 2>/dev/null || \
    sed -i '' "s/\[Project Name\]/$PROJECT_NAME/g" "$MEMORY_DIR/MEMORY.md"
    rm -f "$MEMORY_DIR/MEMORY.md.bak"
    echo "[created] MEMORY.md — memory index"
fi

if [ -f "$MEMORY_DIR/MEMENTO.md" ]; then
    echo "[skip] MEMENTO.md already exists"
else
    cp "$KIT_DIR/templates/.claude/memory/MEMENTO.md" "$MEMORY_DIR/MEMENTO.md"
    # Replace placeholder date with today
    TODAY_FULL=$(date +"%Y-%m-%d %I:%M%p")
    sed -i.bak "s/\[YYYY-MM-DD HH:MMam\/pm\]/$TODAY_FULL/g" "$MEMORY_DIR/MEMENTO.md" 2>/dev/null || \
    sed -i '' "s|\[YYYY-MM-DD HH:MMam/pm\]|$TODAY_FULL|g" "$MEMORY_DIR/MEMENTO.md"
    rm -f "$MEMORY_DIR/MEMENTO.md.bak"
    echo "[created] MEMENTO.md — session continuity"
fi

if [ -f "$MEMORY_DIR/user_profile.md" ]; then
    echo "[skip] user_profile.md already exists"
else
    cp "$KIT_DIR/templates/.claude/memory/user_profile.md" "$MEMORY_DIR/user_profile.md"
    echo "[created] user_profile.md — fill in your role and preferences"
fi

# Copy example files for reference (but don't overwrite)
for example in feedback_example.md project_example.md reference_example.md; do
    if [ ! -f "$MEMORY_DIR/$example" ]; then
        cp "$KIT_DIR/templates/.claude/memory/$example" "$MEMORY_DIR/$example"
        echo "[created] $example — template for reference"
    fi
done

# --- Step 5: Summary ---
echo ""
echo "========================================="
echo "Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. Fill in CLAUDE.md with your project's commands, patterns, and gotchas"
echo "  2. Write an initial PROJECT_STATE.md describing where the project stands"
echo "  3. Fill in $MEMORY_DIR/user_profile.md with your role and preferences"
echo "  4. Start a Claude Code session — the memory system will grow from here"
echo ""
echo "  Delete the *_example.md files in the memory directory after reviewing them."
echo ""
echo "For the full guide, see: $KIT_DIR/README.md"
echo "For memory tier details: $KIT_DIR/docs/memory-tiers.md"
echo "For automation patterns: $KIT_DIR/docs/cron-patterns.md"
