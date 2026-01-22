# CLAUDE.md - Claudio Project Instructions

## Overview

Claudio is a native macOS menu bar app for the [brabble](https://github.com/steipete/brabble) voice daemon. It provides live transcription display, processing indicators, and conversation history.

## Build Commands

```bash
# Build and run
./build.sh
open build/Claudio.app

# Or via Xcode
xcodebuild -project Claudio.xcodeproj -scheme Claudio -configuration Release build
```

## Architecture

```
Claudio/
├── App/           # @main entry point (ClaudioApp.swift)
├── Models/        # Data structures (ConversationTurn, ConversationSession, etc.)
├── ViewModels/    # @Observable state (ClaudioViewModel)
├── Services/      # File watching, parsing (FileWatcherService, *Parser)
└── Views/         # SwiftUI components (MenuBarView, ConversationHistoryView)
```

## Key Patterns

- **State Management**: `@Observable` pattern (macOS 14+)
- **File Watching**: `DispatchSource.makeFileSystemObjectSource`
- **Config Parsing**: Regex-based TOML parsing (no external deps)
- **Session Grouping**: 5-minute gap threshold for multi-turn conversations

## Adding New Files

When adding new Swift files, you must update `project.pbxproj`:
1. Add `PBXBuildFile` entry
2. Add `PBXFileReference` entry
3. Add to appropriate `PBXGroup`
4. Add to `PBXSourcesBuildPhase`

## Autonomous Development

### Ralph (Story-by-Story Implementation)

Ralph autonomously implements PRD stories one at a time:

```bash
# Run ralph with Claude Code (default 10 iterations)
./scripts/ralph/ralph.sh --tool claude

# Run with more iterations
./scripts/ralph/ralph.sh --tool claude 20

# Check story status
cat prd.json | jq '.stories[] | {id, title, passes}'
```

**How it works:**
1. Reads `prd.json` to find next incomplete story
2. Implements that single story
3. Runs quality checks (build)
4. Commits if checks pass
5. Updates `prd.json` to mark story complete
6. Appends learnings to `progress.txt`
7. Repeats

### Compound Product (Report-Driven Development)

Compound product analyzes reports to identify priorities and implements improvements:

```bash
# Full workflow (analyze reports → create PRD → implement)
./scripts/compound/auto-compound.sh

# Dry run (just analyze, don't implement)
./scripts/compound/auto-compound.sh --dry-run

# Run just the implementation loop (if prd.json exists)
./scripts/compound/loop.sh 10
```

**Workflow:**
1. Place daily reports in `reports/` directory
2. `auto-compound.sh` analyzes reports to find #1 priority
3. Creates PRD and breaks into tasks
4. Implements tasks iteratively
5. Creates PR for human review

## Files

| File | Purpose |
|------|---------|
| `prd.json` | Product requirements (stories with pass/fail status) |
| `progress.txt` | Learnings from previous iterations |
| `compound.config.json` | Compound product configuration |
| `reports/` | Daily reports for compound analysis |

## brabble Integration

- Logs: `~/Library/Application Support/brabble/`
- Config: `~/.config/brabble/config.toml`
- Wake word configured in config.toml `[wake]` section
