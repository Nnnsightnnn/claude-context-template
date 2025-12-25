# Claude Context System

A structured knowledge management system for Claude Code projects.

## Overview

This directory contains the context system that helps Claude understand your project, remember patterns, track pain points, and execute complex workflows efficiently.

## Directory Structure

```
.claude/
├── commands/           # User-invoked slash commands
│   ├── focus.md       # Deep dive into specific tasks
│   ├── investigate.md # Codebase exploration
│   ├── deep-investigate.md  # Multi-agent parallel investigation
│   ├── brainstorm-design.md # UI/UX design concepts
│   ├── plan-as-group.md     # 3-expert collaborative planning
│   ├── sprint-plan.md       # Weekly sprint automation
│   ├── orchestrate-tasks.md # Parallel task execution
│   └── bootstrap-project.md # Full codebase analysis
│
├── skills/            # Auto-triggered capabilities
│   ├── project-builder/       # Task breakdown automation
│   ├── pain-point-manager/    # Friction tracking
│   ├── memory-consolidation/  # Memory maintenance
│   └── investigation-analysis/ # ROI analysis
│
├── memory/            # Knowledge management
│   ├── active/        # Hot/warm tier (frequently accessed)
│   │   ├── quick-reference.md    # Top 20 patterns (check FIRST)
│   │   └── procedural-memory.md  # Active procedures
│   ├── structured/    # Cool tier (domain-specific)
│   │   └── patterns/  # By category
│   ├── indexes/       # Search indexes
│   ├── archives/      # Cold tier (historical)
│   ├── maintenance/   # Consolidation tools
│   └── CONTRIBUTION_GUIDELINES.md
│
├── pain-points/       # Development friction tracking
│   ├── active-pain-points.md  # Current tracking
│   ├── USAGE_GUIDE.md         # How to use
│   └── archives/              # Monthly archives
│
├── templates/         # Reusable document templates
├── specs/            # Specification documents
└── README.md         # This file
```

## Core Concepts

### Commands vs Skills

**Commands** (in `/commands/`) are explicitly invoked by users:
- Triggered by typing `/command-name`
- User decides when to run them
- Examples: `/focus`, `/investigate`, `/sprint-plan`

**Skills** (in `/skills/`) are auto-triggered by context:
- Activated by keywords or patterns in conversation
- No explicit invocation needed
- Examples: "build a feature" triggers project-builder

### Memory Tiers

The memory system uses a tiered approach inspired by human memory:

| Tier | Location | Access | Content |
|------|----------|--------|---------|
| Hot | `quick-reference.md` | Every task | Top 20 patterns |
| Warm | `procedural-memory.md` | Frequently | Active procedures |
| Cool | `structured/patterns/` | Occasionally | Domain-specific |
| Cold | `/docs/guides/patterns/` | Rarely | Full documentation |

### Pain Points

Track development friction to identify improvement opportunities:

1. **Capture**: Note friction as it happens
2. **Prioritize**: Weekly review and prioritization
3. **Resolve**: Create tasks for top priorities
4. **Archive**: Monthly archival of resolved items
5. **Learn**: Quarterly pattern extraction

## Quick Start

### 1. Customize CLAUDE.md

Edit the root `CLAUDE.md` file with:
- Your tech stack
- Project-specific guard rails
- Development constraints
- Custom triggers

### 2. Bootstrap Your Codebase

Run the bootstrap command to analyze your codebase:
```
/bootstrap-project
```

This will:
- Detect your tech stack
- Identify code patterns
- Build an architecture layer map
- Create initial guard rails

### 3. Start Tracking Patterns

As you work:
- Add patterns to `procedural-memory.md` when you solve problems
- Promote top patterns to `quick-reference.md`
- Track friction in `active-pain-points.md`

### 4. Weekly Maintenance

- **Monday**: `/sprint-plan` for weekly planning
- **Daily**: Check `quick-reference.md` before tasks
- **Friday**: Review and update pain points
- **Monthly**: Archive resolved pain points

## Available Commands

| Command | Purpose |
|---------|---------|
| `/focus [task]` | Deep dive into a specific task |
| `/investigate [topic]` | Explore codebase areas |
| `/deep-investigate [problem]` | Multi-agent parallel investigation |
| `/brainstorm-design [element]` | Generate UI/UX design concepts |
| `/plan-as-group [problem]` | 3-expert collaborative planning |
| `/sprint-plan [week]` | Automated weekly sprint planning |
| `/orchestrate-tasks` | Launch parallel task execution |
| `/bootstrap-project [dir]` | Analyze codebase and bootstrap context |

## Auto-Triggered Skills

| Skill | Triggers |
|-------|----------|
| Project Builder | "build a...", "implement...", "create project plan" |
| Pain Point Manager | "pain point", "friction", "blocker", "workaround" |
| Investigation Analysis | "should we build...", "is it worth...", "feasibility" |
| Memory Consolidation | (Manual via maintenance workflow) |

## Guard Rail System

Guard rails in `CLAUDE.md` follow the specification ID pattern:

```markdown
### Category [CATEGORY]
**[CATEGORY-NNNNN]** Description of the rule
> TRIGGER: When this rule applies
```

Categories:
- `[FILE]` - File organization
- `[DEV]` - Development practices
- `[PROD]` - Production deployment
- `[DATA]` - Data handling
- `[SEC]` - Security
- `[VERIFY]` - Verification protocols

## Best Practices

### 1. Check Memory First
Before any task, check `quick-reference.md` for relevant patterns.

### 2. Document as You Go
Add patterns to procedural memory when you solve problems.

### 3. Track Friction
Note pain points immediately when you encounter them.

### 4. Keep Files Small
- Patterns: 50-100 lines max
- Quick reference: 10-20KB
- Procedural memory: <150KB

### 5. Regular Maintenance
- Weekly: Update patterns and pain points
- Monthly: Archive and consolidate
- Quarterly: Deep review and optimization

## Customization

### Adding Commands

Create new commands in `.claude/commands/`:

```markdown
---
description: Brief description
allowed-tools: Read, Grep, Glob
---

# Command Name

**Usage**: `/command-name [args]`

## Steps
1. First step
2. Second step
...
```

### Adding Skills

Create new skills in `.claude/skills/skill-name/`:

```markdown
---
name: Skill Name
description: When to auto-trigger
allowed-tools: Read, Write, Edit
---

# Skill Name

## Auto-Activation Triggers
- Trigger phrase 1
- Trigger phrase 2

## Workflow
...
```

## Troubleshooting

### Memory Too Large
Run memory consolidation:
1. Check sizes: `ls -lh .claude/memory/active/`
2. Run consolidation skill
3. Archive old patterns

### Pattern Not Found
1. Check `quick-reference.md` first
2. Search `procedural-memory.md`
3. Check domain-specific files in `structured/patterns/`
4. Check full docs in `/docs/guides/patterns/`

### Command Not Working
1. Verify file exists in `.claude/commands/`
2. Check YAML frontmatter is valid
3. Verify allowed-tools includes needed tools

## Resources

- **Pattern Guidelines**: `.claude/memory/CONTRIBUTION_GUIDELINES.md`
- **Pain Point Guide**: `.claude/pain-points/USAGE_GUIDE.md`
- **Main Context**: `CLAUDE.md` in project root

---

**Version**: 1.0.0
**Template Source**: ClaudeKit
