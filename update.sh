#!/bin/bash
# ClaudeKit Update Script
# Updates an existing ClaudeKit installation to the latest version
#
# Usage: ./update.sh [OPTIONS] [TARGET_DIR]
#    or: curl -fsSL https://raw.githubusercontent.com/Nnnsightnnn/claudekit/main/update.sh | bash
#
# Options:
#   --check      Only check for updates, don't make changes
#   --auto       Auto-update without interactive prompts
#   --rollback   Restore from last backup
#   --help       Show this help message

set -e

# =============================================================================
# CONFIGURATION
# =============================================================================

REPO_URL="https://github.com/Nnnsightnnn/claudekit"
RAW_URL="https://raw.githubusercontent.com/Nnnsightnnn/claudekit/main"
TARGET_DIR="."
BACKUP_DIR=""
CHECK_ONLY=false
AUTO_MODE=false
ROLLBACK_MODE=false

# Colors (with fallback for non-color terminals)
if [[ -t 1 ]] && command -v tput &> /dev/null && [[ $(tput colors 2>/dev/null) -ge 8 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    BOLD=''
    NC=''
fi

# =============================================================================
# FILE CATEGORIES
# =============================================================================

# Files that are safe to auto-update (no user customization expected)
AUTO_UPDATE_FILES=(
    ".claude/commands/focus.md"
    ".claude/commands/investigate.md"
    ".claude/commands/deep-investigate.md"
    ".claude/commands/brainstorm-design.md"
    ".claude/commands/plan-as-group.md"
    ".claude/commands/sprint-plan.md"
    ".claude/commands/orchestrate-tasks.md"
    ".claude/commands/bootstrap-project.md"
    ".claude/commands/update-template.md"
    ".claude/skills/project-builder/SKILL.md"
    ".claude/skills/pain-point-manager/SKILL.md"
    ".claude/skills/memory-consolidation/prompt.md"
    ".claude/skills/investigation-analysis/SKILL.md"
    ".claude/README.md"
)

# Files that may have user customizations - show diff and ask
INTERACTIVE_FILES=(
    ".claude/memory/CONTRIBUTION_GUIDELINES.md"
    ".claude/pain-points/USAGE_GUIDE.md"
)

# Patterns for files that should NEVER be touched
# (user data - memory content, pain points, project config)
NEVER_TOUCH_PATTERNS=(
    ".claude/memory/active/"
    ".claude/memory/structured/"
    ".claude/memory/indexes/"
    ".claude/memory/archives/"
    ".claude/pain-points/active-pain-points.md"
    ".claude/pain-points/archives/"
    "CLAUDE.md"
)

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                     ClaudeKit Update                           ${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

print_info() {
    echo -e "${BLUE}$1${NC}"
}

# Download a file using curl or wget
download_file() {
    local url="$1"
    local dest="$2"

    if command -v curl &> /dev/null; then
        curl -fsSL "$url" -o "$dest" 2>/dev/null
        return $?
    elif command -v wget &> /dev/null; then
        wget -q "$url" -O "$dest" 2>/dev/null
        return $?
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
}

# Fetch content from URL to stdout
fetch_content() {
    local url="$1"

    if command -v curl &> /dev/null; then
        curl -fsSL "$url" 2>/dev/null
    elif command -v wget &> /dev/null; then
        wget -qO- "$url" 2>/dev/null
    fi
}

# Get local version
get_local_version() {
    if [ -f "$TARGET_DIR/.claude/VERSION" ]; then
        cat "$TARGET_DIR/.claude/VERSION" | tr -d '[:space:]'
    else
        echo "unknown"
    fi
}

# Get remote version
get_remote_version() {
    fetch_content "$RAW_URL/VERSION" | tr -d '[:space:]' || echo "unknown"
}

# Compare versions (returns 0 if update available, 1 if up-to-date, 2 if error)
compare_versions() {
    local local_ver="$1"
    local remote_ver="$2"

    if [ "$local_ver" = "unknown" ] || [ "$remote_ver" = "unknown" ]; then
        return 2
    fi

    if [ "$local_ver" = "$remote_ver" ]; then
        return 1
    fi

    # Simple version comparison (works for semver)
    if [ "$(printf '%s\n' "$local_ver" "$remote_ver" | sort -V | head -n1)" = "$local_ver" ]; then
        return 0  # Update available
    else
        return 1  # Local is newer or same
    fi
}

# =============================================================================
# BACKUP & ROLLBACK
# =============================================================================

create_backup() {
    local timestamp=$(date +%Y%m%d-%H%M%S)
    BACKUP_DIR="$TARGET_DIR/.claude-backup-$timestamp"

    print_info "Creating backup at: $BACKUP_DIR"
    cp -r "$TARGET_DIR/.claude" "$BACKUP_DIR"

    # Store backup path for easy rollback
    echo "$BACKUP_DIR" > "$TARGET_DIR/.claude/.last-backup-path"

    print_success "Backup created successfully"
}

do_rollback() {
    local backup_path=""

    # Try to read last backup path
    if [ -f "$TARGET_DIR/.claude/.last-backup-path" ]; then
        backup_path=$(cat "$TARGET_DIR/.claude/.last-backup-path")
    fi

    # If not found, look for most recent backup
    if [ -z "$backup_path" ] || [ ! -d "$backup_path" ]; then
        backup_path=$(ls -td "$TARGET_DIR"/.claude-backup-* 2>/dev/null | head -1)
    fi

    if [ -z "$backup_path" ] || [ ! -d "$backup_path" ]; then
        print_error "No backup found to rollback to"
        echo ""
        echo "Available backups:"
        ls -la "$TARGET_DIR"/.claude-backup-* 2>/dev/null || echo "  (none)"
        exit 1
    fi

    echo ""
    print_warning "This will restore from: $backup_path"
    echo ""

    if [ "$AUTO_MODE" = false ]; then
        read -p "Continue with rollback? [y/N]: " -n 1 -r confirm
        echo
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            echo "Rollback cancelled."
            exit 0
        fi
    fi

    # Perform rollback
    print_info "Rolling back..."
    rm -rf "$TARGET_DIR/.claude"
    cp -r "$backup_path" "$TARGET_DIR/.claude"

    print_success "Rollback complete!"
    echo "Restored from: $backup_path"
}

# =============================================================================
# UPDATE FUNCTIONS
# =============================================================================

# Show what's new in the changelog
show_changelog() {
    local from_version="$1"

    echo ""
    echo -e "${CYAN}What's New:${NC}"
    echo "─────────────────────────────────────────────────────────────────"

    # Fetch and display changelog (simplified - shows recent entries)
    local changelog=$(fetch_content "$RAW_URL/CHANGELOG.md")

    if [ -n "$changelog" ]; then
        # Extract content between [Unreleased] and the from_version
        echo "$changelog" | sed -n '/^## \[/,/^## \['"$from_version"'\]/p' | head -40
    else
        echo "  (Could not fetch changelog)"
    fi

    echo "─────────────────────────────────────────────────────────────────"
    echo ""
}

# Update files that are safe to auto-update
update_auto_files() {
    echo ""
    print_info "Updating template files..."
    echo ""

    local updated=0
    local skipped=0
    local failed=0

    for file in "${AUTO_UPDATE_FILES[@]}"; do
        local dest="$TARGET_DIR/$file"
        local dir=$(dirname "$dest")

        # Ensure directory exists
        mkdir -p "$dir"

        # Download file
        local temp_file=$(mktemp)
        if download_file "$RAW_URL/$file" "$temp_file"; then
            # Check if file has content
            if [ -s "$temp_file" ]; then
                cp "$temp_file" "$dest"
                echo -e "  ${GREEN}✓${NC} $file"
                ((updated++))
            else
                echo -e "  ${YELLOW}⚠${NC} $file (empty response)"
                ((skipped++))
            fi
        else
            echo -e "  ${YELLOW}⚠${NC} $file (not found in template)"
            ((skipped++))
        fi
        rm -f "$temp_file"
    done

    echo ""
    print_success "Updated $updated files"
    [ $skipped -gt 0 ] && print_warning "Skipped $skipped files"
}

# Show diff and prompt for interactive files
handle_interactive_file() {
    local file="$1"
    local local_file="$TARGET_DIR/$file"
    local temp_file=$(mktemp)

    # Download remote version
    if ! download_file "$RAW_URL/$file" "$temp_file"; then
        echo -e "  ${YELLOW}⚠${NC} $file (not found in template)"
        rm -f "$temp_file"
        return
    fi

    # Check if local file exists
    if [ ! -f "$local_file" ]; then
        # New file - just show and ask
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}New file: $file${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "This is a new file in the template. First 20 lines:"
        echo ""
        head -20 "$temp_file"
        echo ""

        if [ "$AUTO_MODE" = true ]; then
            mkdir -p "$(dirname "$local_file")"
            cp "$temp_file" "$local_file"
            echo -e "${GREEN}✓ Added (auto mode)${NC}"
        else
            read -p "Add this file? [Y/n]: " -n 1 -r choice
            echo
            if [[ ! $choice =~ ^[Nn]$ ]]; then
                mkdir -p "$(dirname "$local_file")"
                cp "$temp_file" "$local_file"
                echo -e "${GREEN}✓ Added${NC}"
            else
                echo -e "${YELLOW}⏭ Skipped${NC}"
            fi
        fi

        rm -f "$temp_file"
        return
    fi

    # Check if files differ
    if diff -q "$local_file" "$temp_file" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $file (no changes)"
        rm -f "$temp_file"
        return
    fi

    # Files differ - show diff and prompt
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}File: $file${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}Changes (your version → template version):${NC}"
    echo ""

    # Show diff
    diff -u "$local_file" "$temp_file" --label "Local (your version)" --label "Remote (template)" 2>/dev/null || true

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if [ "$AUTO_MODE" = true ]; then
        echo -e "${YELLOW}⏭ Skipped (auto mode preserves customizations)${NC}"
        rm -f "$temp_file"
        return
    fi

    echo "Options:"
    echo "  [y] Accept template version (replace your file)"
    echo "  [n] Keep your version (skip)"
    echo "  [d] Show full diff again"
    echo "  [m] Manual merge (opens in \$EDITOR)"
    echo ""

    while true; do
        read -p "Choice [y/n/d/m]: " -n 1 -r choice
        echo

        case $choice in
            y|Y)
                cp "$temp_file" "$local_file"
                echo -e "${GREEN}✓ Updated${NC}"
                break
                ;;
            n|N)
                echo -e "${YELLOW}⏭ Kept your version${NC}"
                break
                ;;
            d|D)
                diff -u "$local_file" "$temp_file" --label "Local" --label "Remote" 2>/dev/null | ${PAGER:-less}
                echo ""
                echo "Options: [y] Accept template  [n] Keep yours  [d] Diff  [m] Merge"
                ;;
            m|M)
                # Create merge file
                local merge_file="${local_file}.merge"
                {
                    echo "<<<<<<< YOUR VERSION (local)"
                    cat "$local_file"
                    echo "======="
                    cat "$temp_file"
                    echo ">>>>>>> TEMPLATE VERSION (remote)"
                } > "$merge_file"

                ${EDITOR:-${VISUAL:-vi}} "$merge_file"

                if [ -f "$merge_file" ]; then
                    if grep -q "<<<<<<< YOUR VERSION" "$merge_file"; then
                        print_warning "Conflict markers still present in file"
                        read -p "Save anyway? [y/N]: " -n 1 -r save
                        echo
                        if [[ $save =~ ^[Yy]$ ]]; then
                            cp "$merge_file" "$local_file"
                            rm -f "$merge_file"
                            echo -e "${GREEN}✓ Saved with markers${NC}"
                        else
                            rm -f "$merge_file"
                            echo "Merge cancelled, keeping original"
                        fi
                    else
                        cp "$merge_file" "$local_file"
                        rm -f "$merge_file"
                        echo -e "${GREEN}✓ Merged${NC}"
                    fi
                fi
                break
                ;;
            *)
                echo "Please enter y, n, d, or m"
                ;;
        esac
    done

    rm -f "$temp_file"
}

# Handle all interactive files
handle_interactive_files() {
    echo ""
    print_info "Reviewing files that may have customizations..."

    for file in "${INTERACTIVE_FILES[@]}"; do
        handle_interactive_file "$file"
    done
}

# Update the version file
update_version_file() {
    local new_version="$1"
    echo "$new_version" > "$TARGET_DIR/.claude/VERSION"
    print_success "Version updated to $new_version"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

show_help() {
    echo "ClaudeKit Update Script"
    echo ""
    echo "Usage: ./update.sh [OPTIONS] [TARGET_DIR]"
    echo ""
    echo "Options:"
    echo "  --check      Only check for updates, don't make changes"
    echo "  --auto       Auto-update without interactive prompts"
    echo "  --rollback   Restore from last backup"
    echo "  --help       Show this help message"
    echo ""
    echo "TARGET_DIR defaults to current directory"
    echo ""
    echo "Examples:"
    echo "  ./update.sh                    # Interactive update in current dir"
    echo "  ./update.sh --check            # Just check for updates"
    echo "  ./update.sh --auto /my/project # Auto-update specific directory"
    echo "  ./update.sh --rollback         # Restore from last backup"
}

main() {
    print_header

    # Change to target directory
    cd "$TARGET_DIR" || { print_error "Cannot access $TARGET_DIR"; exit 1; }
    TARGET_DIR=$(pwd)

    # Handle rollback mode
    if [ "$ROLLBACK_MODE" = true ]; then
        do_rollback
        exit 0
    fi

    # Check for .claude directory
    if [ ! -d ".claude" ]; then
        print_error "No .claude directory found in $TARGET_DIR"
        echo ""
        echo "It looks like ClaudeKit isn't installed here."
        echo "Run install.sh first or specify the correct directory."
        exit 1
    fi

    # Get versions
    local_version=$(get_local_version)
    remote_version=$(get_remote_version)

    echo -e "  Current Version: ${YELLOW}$local_version${NC}"
    echo -e "  Latest Version:  ${GREEN}$remote_version${NC}"
    echo ""

    # Check if versions could be retrieved
    if [ "$remote_version" = "unknown" ]; then
        print_error "Could not fetch remote version. Check your internet connection."
        exit 1
    fi

    # Compare versions
    if [ "$local_version" = "$remote_version" ]; then
        print_success "You're already on the latest version!"
        exit 0
    fi

    if [ "$local_version" != "unknown" ]; then
        compare_versions "$local_version" "$remote_version"
        case $? in
            1)
                print_success "You're already on the latest version!"
                exit 0
                ;;
            2)
                print_warning "Could not compare versions"
                ;;
        esac
    fi

    # Check-only mode
    if [ "$CHECK_ONLY" = true ]; then
        echo ""
        print_info "Update available: $local_version → $remote_version"
        echo ""
        echo "Run without --check to update:"
        echo "  ./update.sh"
        echo ""
        exit 0
    fi

    # Show what's new
    if [ "$local_version" != "unknown" ]; then
        show_changelog "$local_version"
    fi

    # Show summary
    echo -e "${CYAN}This update will:${NC}"
    echo -e "  ${GREEN}✓${NC} Update ${#AUTO_UPDATE_FILES[@]} template files (commands, skills, docs)"
    echo -e "  ${YELLOW}?${NC} Review ${#INTERACTIVE_FILES[@]} files for changes (interactive)"
    echo -e "  ${RED}✗${NC} Preserve user data (memory, pain-points, CLAUDE.md)"
    echo ""

    # Confirm unless auto mode
    if [ "$AUTO_MODE" = false ]; then
        read -p "Continue with update? [Y/n]: " -n 1 -r confirm
        echo
        if [[ $confirm =~ ^[Nn]$ ]]; then
            echo "Update cancelled."
            exit 0
        fi
    fi

    # Create backup
    create_backup

    # Set trap for cleanup on error
    trap 'print_error "Update failed. Your backup is at: $BACKUP_DIR"; exit 1' ERR

    # Perform updates
    update_auto_files
    handle_interactive_files
    update_version_file "$remote_version"

    # Success!
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    Update Complete!                            ${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Version: ${YELLOW}$local_version${NC} → ${GREEN}$remote_version${NC}"
    echo -e "  Backup:  ${BLUE}$BACKUP_DIR${NC}"
    echo ""
    echo "Your user data (memory, pain-points, CLAUDE.md) was preserved."
    echo ""
    echo -e "To rollback: ${YELLOW}./update.sh --rollback${NC}"
    echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --check)
            CHECK_ONLY=true
            shift
            ;;
        --auto)
            AUTO_MODE=true
            shift
            ;;
        --rollback)
            ROLLBACK_MODE=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        -*)
            print_error "Unknown option: $1"
            echo "Run './update.sh --help' for usage"
            exit 1
            ;;
        *)
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

main
