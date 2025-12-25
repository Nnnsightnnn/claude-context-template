# ClaudeKit

A production-ready context system for Claude Code projects. Provides memory management, pain point tracking, and reusable commands.

## Quick Start

### Option 1: Use as GitHub Template
1. Click "Use this template" on GitHub
2. Clone your new repository
3. Open with Claude Code - context system is ready!

### Option 2: Install Script
```bash
# From your existing project
curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/claudekit/main/install.sh | bash
```

### Option 3: Manual Copy
```bash
# Clone and copy
git clone https://github.com/YOUR_USERNAME/claudekit.git /tmp/claudekit
cp -r /tmp/claudekit/.claude /path/to/your/project/
cp /tmp/claudekit/CLAUDE.md /path/to/your/project/
rm -rf /tmp/claudekit
```

## What's Included

### Commands (`.claude/commands/`)
| Command | Purpose |
|---------|---------|
| `/focus [task]` | Load context and concentrate on a task |
| `/investigate [question]` | Search and analyze codebase |
| `/deep-investigate [problem]` | Multi-agent parallel investigation |
| `/brainstorm-design [element]` | Generate design concepts with research |
| `/plan-as-group [problem]` | 3-expert collaborative planning |
| `/sprint-plan [week]` | Weekly sprint planning |
| `/orchestrate-tasks` | Parallel task execution |
| `/bootstrap-project [dir]` | Full codebase analysis and setup |

### Skills (`.claude/skills/`)
Auto-invoked capabilities that activate based on context:
- **project-builder** - Break down projects into tasks
- **pain-point-manager** - Track development friction
- **investigation-analysis** - ROI and feasibility analysis
- **memory-consolidation** - Maintain memory system health

### Memory System (`.claude/memory/`)
```
memory/
├── active/
│   ├── quick-reference.md    # Top 20 patterns (check FIRST)
│   ├── procedural-memory.md  # Active patterns
│   └── episodic-memory.md    # Sprint summaries
├── structured/patterns/      # Domain-specific patterns
└── CONTRIBUTION_GUIDELINES.md
```

### Pain Point Tracking (`.claude/pain-points/`)
Track development friction with priority-based management.

## Customization

### 1. Update CLAUDE.md
Edit the root `CLAUDE.md` to match your project:
- Tech stack
- Project structure
- Custom guard rails

### 2. Configure Task System (Optional)
Commands support multiple task systems. Edit the `allowed-tools` in commands:

| System | Tools |
|--------|-------|
| Dart.ai | `mcp__dart__*` |
| GitHub Issues | `gh issue *` |
| TodoWrite | `TodoWrite` (built-in) |

### 3. Add Your Patterns
As you work, add patterns to:
- `.claude/memory/active/quick-reference.md` - Most-used patterns
- `.claude/memory/active/procedural-memory.md` - All active patterns

## File Structure

```
your-project/
├── CLAUDE.md                    # Main context file
└── .claude/
    ├── commands/               # /command files
    ├── skills/                 # Auto-invoked capabilities
    ├── memory/
    │   ├── active/            # Hot memory
    │   ├── structured/        # Domain patterns
    │   └── CONTRIBUTION_GUIDELINES.md
    ├── pain-points/
    │   ├── active-pain-points.md
    │   └── USAGE_GUIDE.md
    ├── specs/                  # Detailed specifications
    └── templates/              # Reusable templates
```

## Maintenance

| Frequency | Task |
|-----------|------|
| Daily | Check for stale tasks |
| Weekly | Pain point review |
| Monthly | Memory consolidation |
| Quarterly | Full audit |

## Contributing

1. Fork this repository
2. Add your improvements
3. Submit a pull request

## License

MIT License - Use freely in any project.

---

*Based on patterns from production Claude Code usage.*
