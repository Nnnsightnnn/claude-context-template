#!/bin/bash
# Test script for update.sh
# Simulates the curl-based update workflow locally
#
# Usage: ./test-update.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="/tmp/claudekit-update-test"
SERVER_PORT=8765
SERVER_PID=""

# =============================================================================
# HELPERS
# =============================================================================

log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; }
log_test() { echo -e "${YELLOW}[TEST]${NC} $1"; }

cleanup() {
    log_info "Cleaning up..."

    # Kill HTTP server if running
    if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi

    # Also try to kill any orphaned servers on our port
    lsof -ti:$SERVER_PORT 2>/dev/null | xargs kill 2>/dev/null || true

    # Remove test directory
    rm -rf "$TEST_DIR"

    log_info "Cleanup complete"
}

# Ensure cleanup runs on exit
trap cleanup EXIT

start_server() {
    log_info "Starting local HTTP server on port $SERVER_PORT..."

    cd "$SCRIPT_DIR"
    python3 -m http.server $SERVER_PORT --bind 127.0.0.1 > /dev/null 2>&1 &
    SERVER_PID=$!

    # Wait for server to start
    sleep 1

    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        log_fail "Failed to start HTTP server"
        exit 1
    fi

    log_success "HTTP server started (PID: $SERVER_PID)"
}

create_test_installation() {
    log_info "Creating test installation at $TEST_DIR..."

    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR/.claude/commands"
    mkdir -p "$TEST_DIR/.claude/skills/project-builder"
    mkdir -p "$TEST_DIR/.claude/memory/active"
    mkdir -p "$TEST_DIR/.claude/pain-points"

    # Create a VERSION file (simulating older version)
    echo "0.9.0" > "$TEST_DIR/.claude/VERSION"

    # Create some "old" command files
    echo "# Old focus command" > "$TEST_DIR/.claude/commands/focus.md"
    echo "# Old investigate command" > "$TEST_DIR/.claude/commands/investigate.md"

    # Create user data that should be preserved
    echo "# My custom patterns - DO NOT OVERWRITE" > "$TEST_DIR/.claude/memory/active/quick-reference.md"
    echo "# My pain points - DO NOT OVERWRITE" > "$TEST_DIR/.claude/pain-points/active-pain-points.md"

    # Create CLAUDE.md (user config - should be preserved)
    echo "# My Project Config - DO NOT OVERWRITE" > "$TEST_DIR/CLAUDE.md"

    # Create a file that will be in interactive review
    echo "# Custom contribution guidelines" > "$TEST_DIR/.claude/memory/CONTRIBUTION_GUIDELINES.md"

    log_success "Test installation created"
}

# =============================================================================
# TESTS
# =============================================================================

test_check_mode() {
    log_test "Testing --check mode..."

    cd "$TEST_DIR"

    # Run update in check mode
    output=$(CLAUDEKIT_RAW_URL="http://127.0.0.1:$SERVER_PORT" \
        curl -fsSL "http://127.0.0.1:$SERVER_PORT/update.sh" 2>/dev/null | \
        bash -s -- --check 2>&1) || true

    # Should show version comparison
    if echo "$output" | grep -q "Current Version: 0.9.0"; then
        log_success "--check shows current version"
    else
        log_fail "--check should show current version"
        echo "$output"
        return 1
    fi

    if echo "$output" | grep -q "Latest Version:.*1.0.0"; then
        log_success "--check shows latest version"
    else
        log_fail "--check should show latest version"
        echo "$output"
        return 1
    fi

    # Should NOT have modified any files
    if [ "$(cat "$TEST_DIR/.claude/VERSION")" = "0.9.0" ]; then
        log_success "--check did not modify VERSION"
    else
        log_fail "--check should not modify files"
        return 1
    fi

    log_success "--check mode works correctly"
}

test_auto_update() {
    log_test "Testing --auto update mode..."

    cd "$TEST_DIR"

    # Capture original user data
    original_memory=$(cat "$TEST_DIR/.claude/memory/active/quick-reference.md")
    original_pain=$(cat "$TEST_DIR/.claude/pain-points/active-pain-points.md")
    original_claude=$(cat "$TEST_DIR/CLAUDE.md")

    # Run update in auto mode
    output=$(CLAUDEKIT_RAW_URL="http://127.0.0.1:$SERVER_PORT" \
        curl -fsSL "http://127.0.0.1:$SERVER_PORT/update.sh" 2>/dev/null | \
        bash -s -- --auto 2>&1) || true

    echo "$output"

    # Check VERSION was updated
    if [ "$(cat "$TEST_DIR/.claude/VERSION")" = "1.0.0" ]; then
        log_success "VERSION updated to 1.0.0"
    else
        log_fail "VERSION should be updated to 1.0.0"
        return 1
    fi

    # Check backup was created
    if ls "$TEST_DIR"/.claude-backup-* >/dev/null 2>&1; then
        log_success "Backup directory created"
    else
        log_fail "Backup should be created"
        return 1
    fi

    # Check user data was preserved
    if [ "$(cat "$TEST_DIR/.claude/memory/active/quick-reference.md")" = "$original_memory" ]; then
        log_success "Memory files preserved"
    else
        log_fail "Memory files should be preserved"
        return 1
    fi

    if [ "$(cat "$TEST_DIR/.claude/pain-points/active-pain-points.md")" = "$original_pain" ]; then
        log_success "Pain points preserved"
    else
        log_fail "Pain points should be preserved"
        return 1
    fi

    if [ "$(cat "$TEST_DIR/CLAUDE.md")" = "$original_claude" ]; then
        log_success "CLAUDE.md preserved"
    else
        log_fail "CLAUDE.md should be preserved"
        return 1
    fi

    # Check commands were updated (should have real content now, not "# Old")
    if grep -q "description:" "$TEST_DIR/.claude/commands/focus.md" 2>/dev/null; then
        log_success "Commands were updated"
    else
        log_fail "Commands should be updated with real content"
        return 1
    fi

    # Check update-template command was added
    if [ -f "$TEST_DIR/.claude/commands/update-template.md" ]; then
        log_success "update-template command installed"
    else
        log_fail "update-template command should be installed"
        return 1
    fi

    log_success "--auto update works correctly"
}

test_rollback() {
    log_test "Testing --rollback mode..."

    cd "$TEST_DIR"

    # Modify the VERSION to simulate we want to rollback
    echo "1.0.0-modified" > "$TEST_DIR/.claude/VERSION"

    # Run rollback
    output=$(CLAUDEKIT_RAW_URL="http://127.0.0.1:$SERVER_PORT" \
        bash "$SCRIPT_DIR/update.sh" --rollback --auto 2>&1) || true

    echo "$output"

    # Check VERSION was restored to backup version (0.9.0)
    if [ "$(cat "$TEST_DIR/.claude/VERSION")" = "0.9.0" ]; then
        log_success "Rollback restored VERSION to 0.9.0"
    else
        log_fail "Rollback should restore VERSION to 0.9.0, got: $(cat "$TEST_DIR/.claude/VERSION")"
        return 1
    fi

    log_success "--rollback works correctly"
}

test_curl_pipe_syntax() {
    log_test "Testing curl pipe to bash syntax..."

    cd "$TEST_DIR"

    # Reset test dir
    create_test_installation

    # This is the exact syntax users will use
    output=$(CLAUDEKIT_RAW_URL="http://127.0.0.1:$SERVER_PORT" \
        curl -fsSL "http://127.0.0.1:$SERVER_PORT/update.sh" | bash -s -- --check 2>&1) || true

    if echo "$output" | grep -q "ClaudeKit Update"; then
        log_success "curl | bash syntax works"
    else
        log_fail "curl | bash syntax should work"
        echo "$output"
        return 1
    fi

    log_success "curl pipe syntax works correctly"
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                ClaudeKit Update Script Tests                   ${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Setup
    start_server
    create_test_installation

    echo ""

    # Run tests
    local failed=0

    test_curl_pipe_syntax || ((failed++))
    echo ""

    # Reset for next test
    create_test_installation

    test_check_mode || ((failed++))
    echo ""

    test_auto_update || ((failed++))
    echo ""

    test_rollback || ((failed++))
    echo ""

    # Summary
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}                    All tests passed!                          ${NC}"
    else
        echo -e "${RED}                    $failed test(s) failed                      ${NC}"
    fi
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""

    return $failed
}

main "$@"
