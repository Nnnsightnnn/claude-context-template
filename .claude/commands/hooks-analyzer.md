---
description: Analyze CLAUDE.md for hook automation opportunities
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, AskUserQuestion
---

# Hooks Analyzer Command

**Usage**: `/hooks-analyzer [path-to-claude-md]`

Analyze a CLAUDE.md file to discover rules that can be automated with Claude Code hooks.

---

## Step 1: Locate and Read CLAUDE.md

Parse the target file from: `$ARGUMENTS`

If no path provided, search in order:
1. `./CLAUDE.md`
2. `~/CLAUDE.md`
3. `./.claude/CLAUDE.md`

Read the file and extract all text content.

---

## Step 2: Detect Tech Stack

Check for project configuration files to determine tech stack:

```bash
# Check for package managers and languages
ls package.json 2>/dev/null      # Node.js (npm/yarn/pnpm)
ls yarn.lock 2>/dev/null         # Yarn
ls pnpm-lock.yaml 2>/dev/null    # pnpm
ls pyproject.toml 2>/dev/null    # Python (poetry/pip)
ls requirements.txt 2>/dev/null  # Python (pip)
ls go.mod 2>/dev/null            # Go
ls Cargo.toml 2>/dev/null        # Rust
ls Gemfile 2>/dev/null           # Ruby
```

Record detected stack for script customization.

---

## Step 3: Pattern Detection

Scan the CLAUDE.md content for these pattern categories:

### 3.1 Test/Verification Patterns → Stop Hook
**Keywords**: `test`, `spec`, `verify`, `validate`, `check`, `before completing`, `before done`
**Commands**: `npm test`, `pytest`, `jest`, `go test`, `cargo test`, `make test`

### 3.2 Formatting Patterns → PostToolUse Hook
**Keywords**: `format`, `prettier`, `black`, `gofmt`, `rustfmt`, `lint`, `eslint`
**Tools to match**: `Write|Edit`

### 3.3 Security/Secret Patterns → PreToolUse(Write) Hook
**Keywords**: `secret`, `credential`, `password`, `API key`, `.env`, `token`, `private key`, `never write`
**Action**: Block writes to sensitive files

### 3.4 Dangerous Command Patterns → PreToolUse(Bash) Hook
**Keywords**: `rm -rf`, `drop table`, `delete`, `force push`, `--force`, `dangerous`, `destructive`
**Action**: Block risky bash commands

### 3.5 Commit Format Patterns → PreToolUse(Bash) Hook
**Keywords**: `commit format`, `conventional commit`, `commit message`, `git commit`
**Action**: Validate commit message format

### 3.6 Build Verification Patterns → Stop Hook
**Keywords**: `build`, `compile`, `bundle`, `build must pass`, `before merge`
**Commands**: `npm run build`, `go build`, `cargo build`, `make`

For each detected pattern, record:
- The source line number
- The matched text
- The suggested hook type
- The value score (High/Medium/Low)

---

## Step 4: Generate Recommendations

Present findings in this format:

```markdown
## Hooks Analysis: [Project Name]

**Tech Stack Detected**: [Node.js/Python/Go/Rust/etc.]
**Package Manager**: [npm/yarn/pnpm/pip/etc.]

### Detected Rules (X automatable)

| Rule | Line | Hook Type | Value |
|------|------|-----------|-------|
| [description] | [line#] | [type] | [High/Med/Low] |

### Recommended Hooks

#### 1. [Hook Name] ([Value] Value)
**Detected Rule**: "[original text from CLAUDE.md]"
**Hook Type**: [PreToolUse/PostToolUse/Stop]
**Matcher**: [tool pattern]
**Value**: [why this saves time]

**Configuration:**
```json
{
  "matcher": "[pattern]",
  "hooks": [{ "type": "command", "command": ".claude/hooks/[script].sh" }]
}
```

**Script (.claude/hooks/[script].sh):**
```bash
[customized script based on tech stack]
```

[Repeat for each hook...]

### Complete settings.json

```json
{
  "hooks": {
    [all hooks combined]
  }
}
```

### Files to Create

1. `.claude/settings.json` - Hook configuration
2. `.claude/hooks/[script1].sh` - [description]
3. `.claude/hooks/[script2].sh` - [description]
[etc.]

---

Would you like me to create these files?
```

---

## Step 5: Interactive Creation

After presenting recommendations, ask the user:

```
Would you like me to create these hook files?
- Yes, create all files
- Yes, but let me choose which ones
- No, just show me the suggestions
```

If user approves:
1. Create `.claude/hooks/` directory if needed
2. Create each script file with executable permissions
3. Create or update `.claude/settings.json`
4. Verify scripts are executable: `chmod +x .claude/hooks/*.sh`

---

## Hook Script Templates

Use these templates, customized for detected tech stack:

### format.sh (PostToolUse)
```bash
#!/bin/bash
# Auto-format files after Write/Edit
# Tech stack: {{TECH_STACK}}

FILE="$CLAUDE_FILE_PATHS"
[[ -z "$FILE" ]] && exit 0

EXT="${FILE##*.}"

case "$EXT" in
  {{#if nodejs}}
  ts|tsx|js|jsx|json|md)
    {{PACKAGE_MANAGER}} prettier --write "$FILE" 2>/dev/null || true
    ;;
  {{/if}}
  {{#if python}}
  py)
    black "$FILE" 2>/dev/null || ruff format "$FILE" 2>/dev/null || true
    ;;
  {{/if}}
  {{#if go}}
  go)
    gofmt -w "$FILE"
    ;;
  {{/if}}
  {{#if rust}}
  rs)
    rustfmt "$FILE" 2>/dev/null || true
    ;;
  {{/if}}
esac
```

### validate-bash.sh (PreToolUse)
```bash
#!/bin/bash
# Block dangerous bash commands
# Exit 2 = block the tool

COMMAND="$CLAUDE_TOOL_INPUT"

# Dangerous patterns to block
DANGEROUS=(
  "rm -rf /"
  "rm -rf ~"
  "rm -rf *"
  "rm -rf ."
  ":(){ :|:& };:"
  "dd if=/dev"
  "mkfs"
  "> /dev/sda"
  "chmod -R 777 /"
  "chown -R"
  "--force"
  "git push.*--force"
  "drop database"
  "drop table"
)

for pattern in "${DANGEROUS[@]}"; do
  if [[ "$COMMAND" == *"$pattern"* ]]; then
    echo "BLOCKED: Dangerous command pattern detected: $pattern" >&2
    echo "If this is intentional, run the command manually." >&2
    exit 2
  fi
done

exit 0
```

### block-secrets.sh (PreToolUse)
```bash
#!/bin/bash
# Prevent writing to sensitive files or content with secrets
# Exit 2 = block the tool

FILE="$CLAUDE_FILE_PATHS"
CONTENT="$CLAUDE_TOOL_INPUT"

# Block sensitive file patterns
BLOCKED_FILES=(
  ".env"
  ".env.local"
  ".env.production"
  "credentials.json"
  "secrets.yaml"
  "secrets.json"
  "*.pem"
  "*.key"
  "*_rsa"
  "id_rsa"
  "id_ed25519"
)

for pattern in "${BLOCKED_FILES[@]}"; do
  if [[ "$FILE" == $pattern ]] || [[ "$FILE" == *"/$pattern" ]]; then
    echo "BLOCKED: Cannot write to sensitive file: $FILE" >&2
    echo "Manually create or edit this file if needed." >&2
    exit 2
  fi
done

# Scan content for secret patterns
if echo "$CONTENT" | grep -qE '(API_KEY|SECRET_KEY|PASSWORD|PRIVATE_KEY|ACCESS_TOKEN)\s*[=:]'; then
  echo "WARNING: Content may contain secrets. Review carefully." >&2
  # Note: This is a warning, not a block. Change to exit 2 to block.
fi

exit 0
```

### run-tests.sh (Stop)
```bash
#!/bin/bash
# Run tests before Claude finishes responding
# Exit 2 = block completion if tests fail

{{#if nodejs}}
# Node.js project
if [[ -f "package.json" ]]; then
  if grep -q '"test"' package.json; then
    echo "Running tests..."
    {{PACKAGE_MANAGER}} test
    if [[ $? -ne 0 ]]; then
      echo "Tests failed! Fix before completing." >&2
      exit 2
    fi
  fi
fi
{{/if}}

{{#if python}}
# Python project
if [[ -f "pyproject.toml" ]] || [[ -f "pytest.ini" ]] || [[ -d "tests" ]]; then
  echo "Running tests..."
  pytest
  if [[ $? -ne 0 ]]; then
    echo "Tests failed! Fix before completing." >&2
    exit 2
  fi
fi
{{/if}}

{{#if go}}
# Go project
if [[ -f "go.mod" ]]; then
  echo "Running tests..."
  go test ./...
  if [[ $? -ne 0 ]]; then
    echo "Tests failed! Fix before completing." >&2
    exit 2
  fi
fi
{{/if}}

{{#if rust}}
# Rust project
if [[ -f "Cargo.toml" ]]; then
  echo "Running tests..."
  cargo test
  if [[ $? -ne 0 ]]; then
    echo "Tests failed! Fix before completing." >&2
    exit 2
  fi
fi
{{/if}}

exit 0
```

---

## Value Scoring

Score each hook opportunity:

| Factor | High | Medium | Low |
|--------|------|--------|-----|
| Frequency | Every task | Most tasks | Some tasks |
| Time saved | >1 min | 30s-1min | <30s |
| Risk prevented | Data loss | Inconsistency | Annoyance |

**High Value**: Test runners, secret blockers, dangerous command blockers
**Medium Value**: Auto-formatters, build checkers
**Low Value**: Commit validators, style checkers

---

## Edge Cases

### No Automatable Rules Found
```markdown
## Hooks Analysis: [Project Name]

No automatable rules detected in CLAUDE.md.

Your CLAUDE.md doesn't contain patterns that map to hooks. Consider adding:
- "Always run tests before completing"
- "Format code with prettier/black"
- "Never write to .env files"
- "Block dangerous rm -rf commands"

See `.claude/hooks/README.md` for hook documentation.
```

### No CLAUDE.md Found
```markdown
## Hooks Analysis

No CLAUDE.md found at:
- ./CLAUDE.md
- ~/CLAUDE.md
- ./.claude/CLAUDE.md

Create a CLAUDE.md with project rules, then run `/hooks-analyzer` again.
```

---

## Options

| Option | Effect |
|--------|--------|
| `--dry-run` | Show suggestions without offering to create files |
| `--all` | Include low-value hooks in recommendations |
| `--security-only` | Only show security-related hooks |

---

## Examples

```bash
# Analyze current project
/hooks-analyzer

# Analyze specific file
/hooks-analyzer ~/projects/myapp/CLAUDE.md

# Preview only, no file creation
/hooks-analyzer --dry-run

# Focus on security hooks
/hooks-analyzer --security-only
```

---

*Command Version: 1.0.0*
