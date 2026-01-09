# Changelog

All notable changes to ClaudeKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - Unreleased

### Added
- `update.sh` script for updating existing installations
- `/update-template` command for guided updates via Claude Code
- Version tracking with `VERSION` file
- Automatic backup before updates
- Interactive diff/merge for customized files
- Rollback capability

### Changed
- `install.sh` now copies VERSION file during installation

## [1.0.0] - 2025-01-09

### Added
- Initial release of ClaudeKit
- 8 slash commands: focus, investigate, deep-investigate, brainstorm-design, plan-as-group, sprint-plan, orchestrate-tasks, bootstrap-project
- 4 auto-triggered skills: project-builder, pain-point-manager, memory-consolidation, investigation-analysis
- Memory system with tiered storage (hot/warm/cool/cold)
- Pain points tracking system
- Guard rail specification system
- Comprehensive documentation

[Unreleased]: https://github.com/Nnnsightnnn/claudekit/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/Nnnsightnnn/claudekit/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Nnnsightnnn/claudekit/releases/tag/v1.0.0
