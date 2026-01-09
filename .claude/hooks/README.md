# Claude Code Hooks

Hooks are shell scripts that run automatically at specific points in Claude Code's execution. They enable automation, safety checks, and workflow customization.

---

## Quick Start

1. Run `/hooks-analyzer` to discover automation opportunities in your CLAUDE.md
2. Review suggested hooks and accept file creation
3. Hooks activate automatically on next Claude Code session

---

## Hook Types

| Hook Event | When It Fires | Common Use Cases |
|------------|---------------|------------------|
| **PreToolUse** | Before any tool executes | Block dangerous commands, validate inputs, redact secrets |
| **PostToolUse** | After tool completes successfully | Auto-format code, run linters, update timestamps |
| **Stop** | Before Claude finishes responding | Run tests, verify build, quality gates |
| **UserPromptSubmit** | When user submits a prompt | Filter sensitive prompts |
| **SessionStart** | When session begins | Set up environment variables |
| **SessionEnd** | When session ends | Cleanup, logging |

---

## Configuration

Hooks are configured in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/validate-bash.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/format.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/run-tests.sh"
          }
        ]
      }
    ]
  }
}
```

### Matcher Patterns

- Exact match: `"Write"` (matches Write tool only)
- Multiple tools: `"Write|Edit|MultiEdit"` (matches any listed)
- All tools: `"*"` (matches everything)

---

## Environment Variables

Hooks receive context via environment variables:

| Variable | Description | Available In |
|----------|-------------|--------------|
| `CLAUDE_PROJECT_DIR` | Project root directory | All hooks |
| `CLAUDE_FILE_PATHS` | File(s) being operated on | Write, Edit, Read |
| `CLAUDE_TOOL_INPUT` | Tool input/content | PreToolUse |
| `CLAUDE_TOOL_OUTPUT` | Tool output/result | PostToolUse |

---

## Exit Codes

| Code | Effect |
|------|--------|
| `0` | Success - continue normally |
| `2` | Block - prevent the tool/action from executing |
| Other | Warning - show to user but continue |

### Example: Blocking a Dangerous Command

```bash
#!/bin/bash
if [[ "$CLAUDE_TOOL_INPUT" == *"rm -rf /"* ]]; then
  echo "BLOCKED: Refusing to run destructive command" >&2
  exit 2  # This blocks the Bash tool from running
fi
exit 0
```

---

## Script Templates

### Auto-Format (PostToolUse)

```bash
#!/bin/bash
FILE="$CLAUDE_FILE_PATHS"
EXT="${FILE##*.}"

case "$EXT" in
  ts|tsx|js|jsx) npx prettier --write "$FILE" ;;
  py) black "$FILE" 2>/dev/null ;;
  go) gofmt -w "$FILE" ;;
esac
```

### Block Secrets (PreToolUse)

```bash
#!/bin/bash
FILE="$CLAUDE_FILE_PATHS"

if [[ "$FILE" == ".env"* ]]; then
  echo "BLOCKED: Cannot write to .env files" >&2
  exit 2
fi
```

### Run Tests (Stop)

```bash
#!/bin/bash
npm test
if [[ $? -ne 0 ]]; then
  echo "Tests failed - please fix before completing" >&2
  exit 2
fi
```

---

## Debugging Hooks

### Check if hooks are running

Add debug output to your hook:

```bash
#!/bin/bash
echo "[DEBUG] Hook triggered for: $CLAUDE_FILE_PATHS" >&2
# ... rest of hook
```

### Common issues

1. **Hook not running**: Check matcher pattern matches tool name exactly
2. **Permission denied**: Run `chmod +x .claude/hooks/*.sh`
3. **Script errors**: Test script manually: `./.claude/hooks/format.sh`

---

## Best Practices

### Performance

- Keep hooks fast (<1 second for PostToolUse)
- Reserve heavy operations (tests, builds) for Stop hooks
- Use matchers to limit which tools trigger hooks

### Security

- Always quote variables: `"$FILE"` not `$FILE`
- Validate inputs before using in commands
- Use exit code 2 to block dangerous operations
- Don't log sensitive content to stderr

### Reliability

- Handle missing files gracefully
- Use `|| true` for optional operations
- Test hooks in isolation before deploying

---

## See Also

- [Claude Code Hooks Documentation](https://code.claude.com/docs/en/hooks)
- `/hooks-analyzer` - Discover hook opportunities from CLAUDE.md
- `.claude/settings.json` - Hook configuration file
