# Changelog

All notable changes to Claudio will be documented in this file.

## [1.0.0] - 2026-01-22

### Added
- Native macOS menu bar app for brabble voice daemon
- Live transcription display from brabble
- Processing indicator when Claude is thinking
- Wake word display parsed from brabble config (`~/.config/brabble/config.toml`)
- Multi-turn conversation sessions grouped by 5-minute time gaps
- Conversation history window with search and filter (Cmd+Shift+H)
- Daemon status monitoring with color-coded menu bar icon
- Settings with launch at login option (Cmd+,)

### Menu Bar Status Colors
- Green: brabble running
- Blue (pulsing): Claude processing
- Gray: brabble stopped
- Orange: Unknown status
- Red: Error
