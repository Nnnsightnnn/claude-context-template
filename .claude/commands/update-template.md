---
description: Check for and apply ClaudeKit template updates
allowed-tools: Read, Bash, WebFetch
---

# Update Template Command

Guide the user through updating their ClaudeKit installation to the latest version.

## Arguments

- `--check` - Only check for updates, don't make changes
- `--auto` - Auto-update without interactive prompts (use with caution)
- `--rollback` - Restore from the last backup
- (default) - Interactive guided update

---

## Step 1: Check Current State

First, determine the current and available versions.

### Read Local Version

```bash
cat .claude/VERSION 2>/dev/null || echo "unknown"
```

### Fetch Remote Version

```bash
curl -fsSL https://raw.githubusercontent.com/Nnnsightnnn/claudekit/main/VERSION 2>/dev/null || echo "unknown"
```

### Report Status

Present the findings to the user:

```
## ClaudeKit Update Check

**Current Version**: [local version]
**Latest Version**: [remote version]

**Status**: [Up to date ✓ | Update available ↑]
```

If `--check` was specified, stop here after reporting status.

---

## Step 2: Show What's New

If an update is available, fetch and display the changelog:

```bash
curl -fsSL https://raw.githubusercontent.com/Nnnsightnnn/claudekit/main/CHANGELOG.md
```

Extract and present the relevant entries between the current version and latest:

```
### What's New in [version]

**Added:**
- [list new features]

**Changed:**
- [list changes]

**Fixed:**
- [list fixes]
```

---

## Step 3: Explain Update Categories

Before updating, explain what will happen:

```
### Update Plan

**Will be updated automatically:**
- All commands in `.claude/commands/`
- All skills in `.claude/skills/`
- `.claude/README.md`

**Will be preserved (your data):**
- `.claude/memory/active/*` - Your patterns and knowledge
- `.claude/pain-points/active-pain-points.md` - Your tracked issues
- `CLAUDE.md` - Your project configuration

**Will be reviewed interactively:**
- `.claude/memory/CONTRIBUTION_GUIDELINES.md`
- `.claude/pain-points/USAGE_GUIDE.md`
```

---

## Step 4: Run the Update

If the user wants to proceed, execute the update script:

### For Interactive Mode (default):

```bash
curl -fsSL https://raw.githubusercontent.com/Nnnsightnnn/claudekit/main/update.sh | bash
```

Or if update.sh exists locally:

```bash
./update.sh
```

### For Auto Mode (`--auto`):

```bash
./update.sh --auto
```

### For Rollback (`--rollback`):

```bash
./update.sh --rollback
```

---

## Step 5: Post-Update Summary

After the update completes, provide a summary:

```
## Update Complete

**Version**: [old] → [new]
**Backup Location**: .claude-backup-[timestamp]

### What Was Updated
- ✓ Commands: focus, investigate, deep-investigate, etc.
- ✓ Skills: project-builder, pain-point-manager, etc.
- ✓ Documentation: .claude/README.md

### What Was Preserved
- ✓ Your memory patterns
- ✓ Your pain points
- ✓ Your CLAUDE.md configuration

### Next Steps
1. Review the changelog for new features
2. Test a command: try `/focus` or `/investigate`
3. If issues arise: `./update.sh --rollback`
```

---

## Error Handling

### Cannot Connect to GitHub

If fetching remote version fails:
1. Check internet connection
2. Verify GitHub is accessible: `curl -I https://github.com`
3. Try again in a few minutes

### No .claude Directory Found

If ClaudeKit isn't installed:
1. Run the install script first
2. Or point to the correct directory

### Update Failed Mid-Way

The update script creates a backup before making changes:
1. Backup is at `.claude-backup-[timestamp]`
2. Run `./update.sh --rollback` to restore
3. Report issues at https://github.com/Nnnsightnnn/claudekit/issues

---

## Examples

```bash
# Just check if updates are available
/update-template --check

# Interactive update (recommended)
/update-template

# Auto-update without prompts
/update-template --auto

# Restore from backup if something went wrong
/update-template --rollback
```
