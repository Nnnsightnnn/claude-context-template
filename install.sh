#!/bin/bash
# Claude Context Template Installer
#
# Usage: curl -fsSL https://raw.githubusercontent.com/USERNAME/claude-context-template/main/install.sh | bash
#    or: ./install.sh [target_directory]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/Nnnsightnnn/claude-context-template"
TARGET_DIR="${1:-.}"

echo -e "${GREEN}Claude Context Template Installer${NC}"
echo "=================================="
echo ""

# Check if target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}Error: Target directory '$TARGET_DIR' does not exist${NC}"
    exit 1
fi

cd "$TARGET_DIR"
TARGET_DIR=$(pwd)

echo -e "Installing to: ${YELLOW}$TARGET_DIR${NC}"
echo ""

# Check for existing .claude directory
if [ -d ".claude" ]; then
    echo -e "${YELLOW}Warning: .claude/ directory already exists${NC}"
    read -p "Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    rm -rf .claude
fi

# Check for existing CLAUDE.md
if [ -f "CLAUDE.md" ]; then
    echo -e "${YELLOW}Warning: CLAUDE.md already exists${NC}"
    read -p "Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing CLAUDE.md"
        SKIP_CLAUDE_MD=true
    fi
fi

echo "Creating directory structure..."

# Create core directories
mkdir -p .claude/{commands,skills,memory/{active,structured/patterns,indexes,archives,maintenance},pain-points/archives,templates,specs}

# Create skill directories
mkdir -p .claude/skills/{project-builder,pain-point-manager,memory-consolidation,investigation-analysis}

echo "Downloading template files..."

# Function to download file
download_file() {
    local src="$1"
    local dest="$2"
    if command -v curl &> /dev/null; then
        curl -fsSL "$REPO_URL/raw/main/$src" -o "$dest" 2>/dev/null || echo "  Skipped: $dest"
    elif command -v wget &> /dev/null; then
        wget -q "$REPO_URL/raw/main/$src" -O "$dest" 2>/dev/null || echo "  Skipped: $dest"
    fi
}

# Download commands
echo "  Commands..."
for cmd in focus investigate deep-investigate brainstorm-design plan-as-group sprint-plan orchestrate-tasks bootstrap-project; do
    download_file ".claude/commands/$cmd.md" ".claude/commands/$cmd.md"
done

# Download skills
echo "  Skills..."
download_file ".claude/skills/project-builder/SKILL.md" ".claude/skills/project-builder/SKILL.md"
download_file ".claude/skills/pain-point-manager/SKILL.md" ".claude/skills/pain-point-manager/SKILL.md"
download_file ".claude/skills/memory-consolidation/prompt.md" ".claude/skills/memory-consolidation/prompt.md"
download_file ".claude/skills/investigation-analysis/SKILL.md" ".claude/skills/investigation-analysis/SKILL.md"

# Download memory files
echo "  Memory system..."
download_file ".claude/memory/active/quick-reference.md" ".claude/memory/active/quick-reference.md"
download_file ".claude/memory/active/procedural-memory.md" ".claude/memory/active/procedural-memory.md"
download_file ".claude/memory/CONTRIBUTION_GUIDELINES.md" ".claude/memory/CONTRIBUTION_GUIDELINES.md"

# Download pain points files
echo "  Pain points..."
download_file ".claude/pain-points/active-pain-points.md" ".claude/pain-points/active-pain-points.md"
download_file ".claude/pain-points/USAGE_GUIDE.md" ".claude/pain-points/USAGE_GUIDE.md"

# Download CLAUDE.md if not skipped
if [ "$SKIP_CLAUDE_MD" != "true" ]; then
    echo "  CLAUDE.md..."
    download_file "CLAUDE.md" "CLAUDE.md"
fi

# Download README
echo "  Documentation..."
download_file ".claude/README.md" ".claude/README.md"

# Create .gitkeep files
touch .claude/memory/archives/.gitkeep
touch .claude/memory/indexes/.gitkeep
touch .claude/memory/structured/patterns/.gitkeep
touch .claude/pain-points/archives/.gitkeep
touch .claude/templates/.gitkeep
touch .claude/specs/.gitkeep

# Set dates in files
TODAY=$(date +%Y-%m-%d)
NEXT_WEEK=$(date -v+7d +%Y-%m-%d 2>/dev/null || date -d "+7 days" +%Y-%m-%d 2>/dev/null || echo "[DATE + 7 days]")

# Update placeholder dates (macOS and Linux compatible)
if [[ "$OSTYPE" == "darwin"* ]]; then
    find .claude -name "*.md" -exec sed -i '' "s/\[DATE\]/$TODAY/g" {} \;
    find .claude -name "*.md" -exec sed -i '' "s/\[DATE + 7 days\]/$NEXT_WEEK/g" {} \;
    [ -f "CLAUDE.md" ] && sed -i '' "s/\[DATE\]/$TODAY/g" "CLAUDE.md"
else
    find .claude -name "*.md" -exec sed -i "s/\[DATE\]/$TODAY/g" {} \;
    find .claude -name "*.md" -exec sed -i "s/\[DATE + 7 days\]/$NEXT_WEEK/g" {} \;
    [ -f "CLAUDE.md" ] && sed -i "s/\[DATE\]/$TODAY/g" "CLAUDE.md"
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Directory structure created:"
echo ""
echo "  $TARGET_DIR/"
echo "  ├── CLAUDE.md                    # Main context file (customize this)"
echo "  └── .claude/"
echo "      ├── commands/                # Slash commands (/focus, /investigate, etc.)"
echo "      ├── skills/                  # Auto-triggered skills"
echo "      ├── memory/                  # Knowledge management"
echo "      │   ├── active/              # Hot & warm tier"
echo "      │   ├── structured/          # Domain patterns"
echo "      │   └── archives/            # Historical data"
echo "      ├── pain-points/             # Friction tracking"
echo "      ├── templates/               # Reusable templates"
echo "      └── specs/                   # Specifications"
echo ""
echo "Next steps:"
echo "  1. Edit CLAUDE.md with your project's tech stack and guard rails"
echo "  2. Run '/bootstrap-project' to analyze your codebase"
echo "  3. Start tracking pain points as you work"
echo ""
echo "Available commands:"
echo "  /focus [task]          - Deep dive into a specific task"
echo "  /investigate [topic]   - Analyze codebase areas"
echo "  /deep-investigate      - Multi-agent parallel investigation"
echo "  /sprint-plan           - Weekly sprint planning"
echo "  /orchestrate-tasks     - Parallel task execution"
echo "  /bootstrap-project     - Full codebase analysis"
echo ""
echo -e "For more info, see: ${YELLOW}.claude/README.md${NC}"
